#!/usr/bin/env python3
"""
Bellum Gero World Builder companion tool.

Purpose
-------
The in-game World Builder is the live 3D editor. It autosaves a small .wbp
manifest. This tool turns that manifest into production-friendly output:

  * validate       - validate a .wbp project
  * export-lua     - generate a Lua placement screenplay for static/V1 projects
  * inspect-tre    - inspect/validate a TRE archive and a planet snapshot
  * bake-tre       - bake a finalized project into a separate output TRE
  * deploy         - copy a validated TRE to configured client/server locations with backups
  * build-deploy   - V1 convenience path; V2 intentionally requires staged bake/deploy

WBP V1 static baking is intentionally retained as the proven legacy path.
WBP V2 adds persistent STRUCTURE + INTERIOR publishing:

  * STRUCTURE records become permanent WorldSnapshot building roots with fresh
    permanent root/cell IDs and nested cell NODEs.
  * INTERIOR records become project-specific ILF NODEs using portal-room names
    and the already-captured cell-local transform.
  * Stock shared building IFF/ILF assets are never modified globally. Each
    structure receives a project-specific shared building IFF that points at a
    project-specific ILF.
  * A server-template Lua companion is generated because Core3 snapshot loading
    strips "shared_" from the snapshot path and requires that non-shared server
    template to be registered.
  * V2 TRE repacking supports new archive paths and regenerates the TRE-v5
    checksum/name/MD5 metadata for those records.

Safety philosophy
-----------------
Edit .wbp while developing. Bake only when the project is final. Always bake to
an output TRE separate from the clean/known base. Validate the output before
copying the exact same TRE to client and server. Keep backups of production
assets and generated server-template Lua files.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as _dt
import hashlib
import json
import os
import re
import shutil
import struct
import sys
import tempfile
import zlib
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Sequence, Set, Tuple


MAGIC = b"EERT5000"
TRE_HEADER_SIZE = 36
WBP_MAGIC = "BELLUM_GERO_WORLD_BUILDER"
WBP_VERSION = 1
WBP_STRUCTURAL_VERSION = 2
CELL_SHARED_TEMPLATE = "object/cell/shared_cell.iff"
BUILDING_GAME_OBJECT_TYPE = 512.0

# WBP V2 structural snapshot objects use a dedicated high, signed-31-bit-safe
# ID band and allocate DOWNWARD from its ceiling.  This intentionally keeps
# published structures/cells far away from Core3's ordinary low-ID startup
# allocation stream.  The first published object occupies the ceiling, so
# after it is persisted in clientobjects Core3's monotonically increasing
# allocator advances above the whole World Builder band rather than filling
# unused structural IDs.
#
# V1 static baking is deliberately unchanged and continues using its proven
# legacy max(snapshot)+1 behavior.
WB_STRUCTURAL_OID_MIN = 0x60000000
WB_STRUCTURAL_OID_MAX = 0x6FFFFFFF
WB_STRUCTURAL_OID_STRATEGY = "reserved-high-band-descending-v1"


class WorldBuilderError(RuntimeError):
    pass


@dataclasses.dataclass
class ProjectObject:
    local_id: int
    object_template: str
    snapshot_template: str
    x: float
    z: float  # SWG vertical/height coordinate; serialized second
    y: float
    qw: float
    qx: float
    qy: float
    qz: float
    snapshot_game_object_type: float = -1.0
    parent_id: int = 0


@dataclasses.dataclass
class ProjectStructure:
    local_id: int
    object_template: str
    snapshot_template: str
    x: float
    z: float
    y: float
    qw: float
    qx: float
    qy: float
    qz: float
    snapshot_game_object_type: float = -1.0


@dataclasses.dataclass
class ProjectInterior:
    local_id: int
    object_template: str
    snapshot_template: str
    x: float
    z: float
    y: float
    qw: float
    qx: float
    qy: float
    qz: float
    snapshot_game_object_type: float
    structure_local_id: int
    cell_number: int
    room_name: str


@dataclasses.dataclass
class Project:
    version: int = WBP_VERSION
    name: str = ""
    planet: str = ""
    move_step: float = 0.10
    rotate_step: float = 5.0
    selected: int = 0
    next_id: int = 1
    last_template: str = ""
    objects: List[ProjectObject] = dataclasses.field(default_factory=list)
    structures: List[ProjectStructure] = dataclasses.field(default_factory=list)
    interiors: List[ProjectInterior] = dataclasses.field(default_factory=list)
    group_ids: List[int] = dataclasses.field(default_factory=list)

    @property
    def is_structural(self) -> bool:
        return self.version >= WBP_STRUCTURAL_VERSION or bool(self.structures or self.interiors)

    @property
    def total_records(self) -> int:
        return len(self.objects) + len(self.structures) + len(self.interiors)


@dataclasses.dataclass
class TreRecord:
    hash_or_crc: int
    uncompressed_size: int
    data_offset: int
    compression: int
    compressed_size: int
    name_offset: int
    name: str = ""


def is_tre_tombstone(rec: TreRecord) -> bool:
    """Return True for the zero-length deletion/masking records used by patch TREs."""
    return (
        rec.uncompressed_size == 0
        and rec.data_offset == 0
        and rec.compression == 0
        and rec.compressed_size == 0
    )


@dataclasses.dataclass
class TreArchive:
    path: Path
    raw: bytes
    records: List[TreRecord]
    names_blob: bytes
    names_compression: int
    names_compressed_blob: bytes
    names_uncompressed_size: int
    metadata_offset: int = 0
    md5_blob: bytes = b""

    def record_by_name(self, name: str) -> TreRecord:
        rec = self.record_by_name_optional(name)
        if rec is None:
            raise WorldBuilderError(f"TRE does not contain {name!r}")
        return rec

    def record_by_name_optional(self, name: str) -> Optional[TreRecord]:
        normalized = normalize_archive_path(name)
        for rec in self.records:
            if rec.name.lower() == normalized:
                return rec
        return None

    def extract_record(self, rec: TreRecord) -> bytes:
        if is_tre_tombstone(rec):
            raise WorldBuilderError(
                f"TRE record {rec.name!r} is a deletion/masking record"
            )

        start = rec.data_offset
        end = start + rec.compressed_size
        if start < TRE_HEADER_SIZE or end > len(self.raw) or end < start:
            raise WorldBuilderError(f"Invalid TRE data range for {rec.name}")
        payload = self.raw[start:end]
        if rec.compression == 0:
            data = payload
        elif rec.compression == 2:
            try:
                data = zlib.decompress(payload)
            except zlib.error as exc:
                raise WorldBuilderError(f"Could not decompress {rec.name}: {exc}") from exc
        else:
            raise WorldBuilderError(
                f"Unsupported TRE compression {rec.compression} for {rec.name}; "
                "World Builder currently supports 0 and zlib/2."
            )
        if len(data) != rec.uncompressed_size:
            raise WorldBuilderError(
                f"Size mismatch extracting {rec.name}: expected {rec.uncompressed_size}, got {len(data)}"
            )
        return data

    def extract(self, name: str) -> bytes:
        return self.extract_record(self.record_by_name(name))


@dataclasses.dataclass
class SnapshotNodeInfo:
    object_id: int
    parent_id: int
    name_id: int
    cell_id: int
    qw: float
    qx: float
    qy: float
    qz: float
    x: float
    z: float
    y: float
    game_object_type: float
    unknown2: int


@dataclasses.dataclass
class SnapshotInfo:
    raw: bytes
    names: List[str]
    nodes: List[SnapshotNodeInfo]
    nods_form_start: int
    nods_form_size: int
    nods_end: int
    otnl_start: int
    otnl_size: int
    otnl_end: int
    top_form_start: int
    version_form_start: int


@dataclasses.dataclass
class SnapshotTreeNode:
    info: SnapshotNodeInfo
    children: List["SnapshotTreeNode"] = dataclasses.field(default_factory=list)


@dataclasses.dataclass
class SnapshotTree:
    base: SnapshotInfo
    roots: List[SnapshotTreeNode]

    def flatten(self) -> List[SnapshotTreeNode]:
        result: List[SnapshotTreeNode] = []

        def visit(node: SnapshotTreeNode) -> None:
            result.append(node)
            for child in node.children:
                visit(child)

        for root in self.roots:
            visit(root)
        return result


@dataclasses.dataclass
class PortalInfo:
    path: str
    crc: int
    rooms: List[str]  # portal CELL index; index 0 is exterior

    @property
    def cell_count(self) -> int:
        return max(0, len(self.rooms) - 1)


@dataclasses.dataclass
class InteriorNode:
    template: str
    room: str
    values: Tuple[float, ...]


@dataclasses.dataclass
class PublishedStructure:
    local_id: int
    root_object_id: int
    cell_object_ids: List[int]
    game_object_type: int
    source_server_template: str
    source_shared_template: str
    source_portal_layout: str
    source_interior_layout: str
    custom_server_template: str
    custom_shared_template: str
    custom_interior_layout: str
    portal_crc: int
    cell_count: int
    interior_local_ids: List[int]


@dataclasses.dataclass
class StructuralBakeResult:
    id_map: Dict[int, int]
    server_lua: str
    structures: List[PublishedStructure]
    archive_paths: List[str]


# ---------------------------------------------------------------------------
# General helpers
# ---------------------------------------------------------------------------

def normalize_archive_path(value: str) -> str:
    return value.replace("\\", "/").strip("/").lower()


def fmt(value: float) -> str:
    text = f"{value:.9f}".rstrip("0").rstrip(".")
    return text if text not in {"", "-0"} else "0"


def project_slug(project_name: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "_", project_name.lower()).strip("_")
    if not cleaned:
        cleaned = "project"
    return cleaned[:48]


def lua_var_for_template(path: str) -> str:
    stem = normalize_archive_path(path)
    if stem.endswith(".iff"):
        stem = stem[:-4]
    value = re.sub(r"[^a-zA-Z0-9_]", "_", stem)
    if value and value[0].isdigit():
        value = "p_" + value
    return value


def cstring(data: bytes, offset: int, end: int) -> Tuple[str, int]:
    pos = data.find(b"\0", offset, end)
    if pos < 0:
        raise WorldBuilderError("Truncated NUL-terminated string in IFF data")
    return data[offset:pos].decode("utf-8", errors="replace"), pos + 1


# ---------------------------------------------------------------------------
# WBP
# ---------------------------------------------------------------------------

def read_project(path: Path) -> Project:
    if not path.exists():
        raise WorldBuilderError(f"Project file not found: {path}")

    project = Project()
    valid_header = False

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        key = parts[0]

        try:
            if key == WBP_MAGIC:
                if len(parts) != 2:
                    raise WorldBuilderError(f"{path}:{line_number}: malformed project header")
                version = int(parts[1])
                if version not in (WBP_VERSION, WBP_STRUCTURAL_VERSION):
                    raise WorldBuilderError(
                        f"{path}:{line_number}: unsupported project version {version}"
                    )
                project.version = version
                valid_header = True
            elif key == "PROJECT":
                project.name = parts[1]
            elif key == "PLANET":
                project.planet = parts[1].lower()
            elif key == "MOVE_STEP":
                project.move_step = float(parts[1])
            elif key == "ROTATE_STEP":
                project.rotate_step = float(parts[1])
            elif key == "SELECTED":
                project.selected = int(parts[1])
            elif key == "NEXT_ID":
                project.next_id = int(parts[1])
            elif key == "LAST_TEMPLATE":
                project.last_template = "" if parts[1] == "-" else parts[1]
            elif key == "GROUP":
                project.group_ids = [int(v) for v in parts[1:]]
            elif key == "OBJECT":
                if len(parts) != 13:
                    raise WorldBuilderError(
                        f"{path}:{line_number}: OBJECT requires 12 values after OBJECT; got {len(parts)-1}"
                    )
                project.objects.append(
                    ProjectObject(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                        parent_id=int(parts[12]),
                    )
                )
            elif key == "STRUCTURE":
                if project.version < WBP_STRUCTURAL_VERSION:
                    raise WorldBuilderError(f"{path}:{line_number}: STRUCTURE requires WBP V2")
                if len(parts) != 12:
                    raise WorldBuilderError(
                        f"{path}:{line_number}: STRUCTURE requires 11 values after STRUCTURE; got {len(parts)-1}"
                    )
                project.structures.append(
                    ProjectStructure(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                    )
                )
            elif key == "INTERIOR":
                if project.version < WBP_STRUCTURAL_VERSION:
                    raise WorldBuilderError(f"{path}:{line_number}: INTERIOR requires WBP V2")
                if len(parts) != 15:
                    raise WorldBuilderError(
                        f"{path}:{line_number}: INTERIOR requires 14 values after INTERIOR; got {len(parts)-1}"
                    )
                project.interiors.append(
                    ProjectInterior(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                        structure_local_id=int(parts[12]),
                        cell_number=int(parts[13]),
                        room_name="" if parts[14] == "-" else parts[14],
                    )
                )
            else:
                raise WorldBuilderError(f"{path}:{line_number}: unknown record {key!r}")
        except (IndexError, ValueError) as exc:
            raise WorldBuilderError(f"{path}:{line_number}: malformed {key} record") from exc

    if not valid_header:
        raise WorldBuilderError(f"{path}: missing {WBP_MAGIC} header")
    validate_project(project, source=path)
    return project


def _validate_transform_record(record, where: str, label: str) -> None:
    if record.local_id <= 0:
        raise WorldBuilderError(where + f"{label} local ID must be > 0: {record.local_id}")
    if not record.object_template.endswith(".iff"):
        raise WorldBuilderError(where + f"{label} #{record.local_id}: object template is not .iff")
    if not record.snapshot_template.endswith(".iff"):
        raise WorldBuilderError(where + f"{label} #{record.local_id}: snapshot template is not .iff")
    qnorm = (record.qw**2 + record.qx**2 + record.qy**2 + record.qz**2) ** 0.5
    if not (0.5 <= qnorm <= 1.5):
        raise WorldBuilderError(
            where + f"{label} #{record.local_id}: quaternion norm {qnorm:.4f} looks invalid"
        )


def validate_project(project: Project, source: Optional[Path] = None) -> None:
    where = f"{source}: " if source else ""
    if project.version not in (WBP_VERSION, WBP_STRUCTURAL_VERSION):
        raise WorldBuilderError(where + f"unsupported project version {project.version}")
    if not project.name:
        raise WorldBuilderError(where + "project name is empty")
    if not project.planet:
        raise WorldBuilderError(where + "planet is empty")
    if not (0.01 <= project.move_step <= 25.0):
        raise WorldBuilderError(where + f"move_step {project.move_step} outside 0.01..25")
    if not (0.1 <= project.rotate_step <= 90.0):
        raise WorldBuilderError(where + f"rotate_step {project.rotate_step} outside 0.1..90")

    seen: set[int] = set()
    for obj in project.objects:
        _validate_transform_record(obj, where, "WB")
        if obj.local_id in seen:
            raise WorldBuilderError(where + f"duplicate local ID {obj.local_id}")
        seen.add(obj.local_id)
        if obj.parent_id < 0:
            raise WorldBuilderError(where + f"WB #{obj.local_id}: parent ID cannot be negative")

    for structure in project.structures:
        _validate_transform_record(structure, where, "STRUCTURE")
        if structure.local_id in seen:
            raise WorldBuilderError(where + f"duplicate local ID {structure.local_id}")
        seen.add(structure.local_id)

    structure_ids = {s.local_id for s in project.structures}
    for interior in project.interiors:
        _validate_transform_record(interior, where, "INTERIOR")
        if interior.local_id in seen:
            raise WorldBuilderError(where + f"duplicate local ID {interior.local_id}")
        seen.add(interior.local_id)
        if interior.structure_local_id not in structure_ids:
            raise WorldBuilderError(
                where + f"INTERIOR #{interior.local_id}: missing STRUCTURE #{interior.structure_local_id}"
            )
        if interior.cell_number <= 0:
            raise WorldBuilderError(
                where + f"INTERIOR #{interior.local_id}: cell number must be > 0"
            )

    if project.version == WBP_VERSION and (project.structures or project.interiors):
        raise WorldBuilderError(where + "WBP V1 cannot contain STRUCTURE/INTERIOR records")

    missing_group = [gid for gid in project.group_ids if gid not in seen]
    if missing_group:
        raise WorldBuilderError(where + f"group references missing object IDs: {missing_group}")


# ---------------------------------------------------------------------------
# Lua export (proven V1/static behavior)
# ---------------------------------------------------------------------------

def lua_class_name(project_name: str) -> str:
    cleaned = "".join(c if c.isalnum() else "_" for c in project_name)
    if not cleaned:
        cleaned = "project"
    if cleaned[0].isdigit():
        cleaned = "p_" + cleaned
    return "WorldBuilder_" + cleaned


def generate_lua(project: Project) -> str:
    validate_project(project)
    if project.structures or project.interiors:
        raise WorldBuilderError(
            "Lua export is intentionally static-only. Structural WBP V2 projects must use bake-tre."
        )
    cls = lua_class_name(project.name)
    lines = [
        "-- Generated by Bellum Gero World Builder companion tool",
        f"-- Project: {project.name} | Planet: {project.planet}",
        "-- Regenerate from the .wbp project rather than hand-editing whenever possible.",
        "",
        f"{cls} = ScreenPlay:new {{",
        "\tnumberOfActs = 1,",
        f'\tscreenplayName = "{cls}",',
        "}",
        "",
        f'registerScreenPlay("{cls}", true)',
        "",
        f"function {cls}:start()",
        f'\tif not isZoneEnabled("{project.planet}") then',
        "\t\treturn",
        "\tend",
        "",
    ]
    for obj in project.objects:
        lines.append(
            '\tspawnSceneObject('
            f'"{project.planet}", "{obj.object_template}", '
            f"{fmt(obj.x)}, {fmt(obj.z)}, {fmt(obj.y)}, {obj.parent_id}, "
            f"{fmt(obj.qw)}, {fmt(obj.qx)}, {fmt(obj.qy)}, {fmt(obj.qz)}) "
            f"-- WB #{obj.local_id}"
        )
    lines.append("end")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# TRE v5
# ---------------------------------------------------------------------------

def _read_names(blob: bytes) -> Dict[int, str]:
    result: Dict[int, str] = {}
    offset = 0
    while offset < len(blob):
        end = blob.find(b"\0", offset)
        if end < 0:
            break
        result[offset] = blob[offset:end].decode("utf-8", errors="replace")
        offset = end + 1
    return result


def open_tre(path: Path) -> TreArchive:
    raw = path.read_bytes()
    if len(raw) < TRE_HEADER_SIZE or raw[:8] != MAGIC:
        raise WorldBuilderError(f"{path} is not a supported TRE v5 archive")

    (
        file_count,
        metadata_offset,
        info_compression,
        info_compressed_size,
        names_compression,
        names_compressed_size,
        names_uncompressed_size,
    ) = struct.unpack_from("<7I", raw, 8)

    info_start = metadata_offset
    info_end = info_start + info_compressed_size
    names_start = info_end
    names_end = names_start + names_compressed_size
    if names_end > len(raw):
        raise WorldBuilderError("TRE metadata points beyond end of file")

    info_c = raw[info_start:info_end]
    names_c = raw[names_start:names_end]
    if info_compression == 0:
        info = info_c
    elif info_compression == 2:
        info = zlib.decompress(info_c)
    else:
        raise WorldBuilderError(f"Unsupported TRE record-table compression: {info_compression}")

    if names_compression == 0:
        names_blob = names_c
    elif names_compression == 2:
        names_blob = zlib.decompress(names_c)
    else:
        raise WorldBuilderError(f"Unsupported TRE names compression: {names_compression}")

    if len(info) != file_count * 24:
        raise WorldBuilderError(
            f"TRE record table size mismatch: {len(info)} != {file_count}*24"
        )
    if len(names_blob) != names_uncompressed_size:
        raise WorldBuilderError(
            f"TRE names size mismatch: {len(names_blob)} != {names_uncompressed_size}"
        )

    name_map = _read_names(names_blob)
    records: List[TreRecord] = []
    for i in range(file_count):
        values = struct.unpack_from("<6I", info, i * 24)
        rec = TreRecord(*values)
        rec.name = name_map.get(rec.name_offset, "")
        if not rec.name:
            raise WorldBuilderError(f"TRE record {i} has invalid name offset {rec.name_offset}")
        records.append(rec)

    for rec in records:
        if is_tre_tombstone(rec):
            continue
        if rec.data_offset < TRE_HEADER_SIZE or rec.data_offset + rec.compressed_size > metadata_offset:
            raise WorldBuilderError(f"Invalid data range for TRE record {rec.name}")

    md5_size = file_count * 16
    md5_blob = raw[names_end:names_end + md5_size] if names_end + md5_size <= len(raw) else b""

    return TreArchive(
        path=path,
        raw=raw,
        records=records,
        names_blob=names_blob,
        names_compression=names_compression,
        names_compressed_blob=names_c,
        names_uncompressed_size=names_uncompressed_size,
        metadata_offset=metadata_offset,
        md5_blob=md5_blob,
    )


# This is the proven V1 repacker. Keep its snapshot/path behavior intentionally narrow.
# V1.9.1 metadata fix: always emit the TRE-v5 stored-payload MD5 table so a
# V1 static bake remains a fully valid source archive for later V1/V2 publishes.
def repack_tre(archive: TreArchive, replacements: Dict[str, bytes], output_path: Path) -> None:
    validate_tre_v5_metadata(archive, require_md5=False)
    normalized_replacements = {k.replace("\\", "/").lower(): v for k, v in replacements.items()}
    unseen = set(normalized_replacements)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False, dir=str(output_path.parent), prefix=output_path.name + ".tmp.") as temp:
        temp_path = Path(temp.name)
        temp.write(b"\0" * TRE_HEADER_SIZE)
        new_records: List[TreRecord] = []
        payload_md5: List[bytes] = []

        for rec in archive.records:
            key = rec.name.lower()
            data_offset = temp.tell()
            if key in normalized_replacements:
                uncompressed = normalized_replacements[key]
                compressed = zlib.compress(uncompressed, 9)
                compression = 2
                unseen.discard(key)
            else:
                start = rec.data_offset
                end = start + rec.compressed_size
                compressed = archive.raw[start:end]
                compression = rec.compression
                uncompressed = None

            temp.write(compressed)
            payload_md5.append(hashlib.md5(compressed).digest())
            new_records.append(
                TreRecord(
                    hash_or_crc=rec.hash_or_crc,
                    uncompressed_size=len(uncompressed) if uncompressed is not None else rec.uncompressed_size,
                    data_offset=data_offset,
                    compression=compression,
                    compressed_size=len(compressed),
                    name_offset=rec.name_offset,
                    name=rec.name,
                )
            )

        if unseen:
            temp.close()
            temp_path.unlink(missing_ok=True)
            raise WorldBuilderError(
                "Cannot add entirely new TRE paths in V1; replacements were not present: " + ", ".join(sorted(unseen))
            )

        metadata_offset = temp.tell()
        info = b"".join(
            struct.pack(
                "<6I",
                r.hash_or_crc,
                r.uncompressed_size,
                r.data_offset,
                r.compression,
                r.compressed_size,
                r.name_offset,
            )
            for r in new_records
        )
        info_c = zlib.compress(info, 9)
        temp.write(info_c)
        temp.write(archive.names_compressed_blob)
        for digest in payload_md5:
            temp.write(digest)

        header = MAGIC + struct.pack(
            "<7I",
            len(new_records),
            metadata_offset,
            2,
            len(info_c),
            archive.names_compression,
            len(archive.names_compressed_blob),
            archive.names_uncompressed_size,
        )
        temp.seek(0)
        temp.write(header)

    try:
        reopened = open_tre(temp_path)
        validate_tre_v5_metadata(reopened, require_md5=True)
        for key, expected in normalized_replacements.items():
            actual = reopened.extract(key)
            if actual != expected:
                raise WorldBuilderError(f"Post-build validation failed for {key}")
        os.replace(temp_path, output_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def soe_tre_crc(path: str) -> int:
    """SOE/TRE filename CRC: non-reflected CRC-32, poly 0x04C11DB7."""
    crc = 0xFFFFFFFF
    for value in normalize_archive_path(path).encode("utf-8"):
        crc ^= value << 24
        for _ in range(8):
            if crc & 0x80000000:
                crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            else:
                crc = (crc << 1) & 0xFFFFFFFF
    return crc ^ 0xFFFFFFFF


def validate_tre_v5_metadata(archive: TreArchive, require_md5: bool = False) -> None:
    previous = -1
    for rec in archive.records:
        expected = soe_tre_crc(rec.name)
        if rec.hash_or_crc != expected:
            raise WorldBuilderError(
                f"TRE checksum mismatch for {rec.name}: 0x{rec.hash_or_crc:08x} != 0x{expected:08x}"
            )
        if rec.hash_or_crc < previous:
            raise WorldBuilderError("TRE record table is not sorted by SOE path checksum")
        previous = rec.hash_or_crc

    if require_md5 and len(archive.md5_blob) != len(archive.records) * 16:
        raise WorldBuilderError("TRE v5 MD5 table is missing or truncated")
    if archive.md5_blob:
        for index, rec in enumerate(archive.records):
            payload = archive.raw[rec.data_offset:rec.data_offset + rec.compressed_size]
            expected = hashlib.md5(payload).digest()
            actual = archive.md5_blob[index * 16:(index + 1) * 16]
            if expected != actual:
                raise WorldBuilderError(f"TRE stored-payload MD5 mismatch for {rec.name}")


def repack_tre_v2(archive: TreArchive, replacements: Dict[str, bytes], output_path: Path) -> None:
    """TRE-v5 repacker that may replace existing paths and add new paths.

    Legacy V1 World Builder TREs may not have a trailing MD5 table.  They are
    accepted as input after checksum/order validation; every V2 output always
    receives and post-validates a complete stored-payload MD5 table.
    """
    validate_tre_v5_metadata(archive, require_md5=False)
    normalized = {normalize_archive_path(k): v for k, v in replacements.items()}

    existing = {normalize_archive_path(rec.name): rec for rec in archive.records}
    all_names = set(existing) | set(normalized)
    ordered_names = sorted(all_names, key=lambda n: (soe_tre_crc(n), n))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False, dir=str(output_path.parent), prefix=output_path.name + ".tmp.") as temp:
        temp_path = Path(temp.name)
        temp.write(b"\0" * TRE_HEADER_SIZE)
        new_records: List[TreRecord] = []
        payload_md5: List[bytes] = []

        for name in ordered_names:
            data_offset = temp.tell()
            if name in normalized:
                uncompressed = normalized[name]
                compressed = zlib.compress(uncompressed, 9)
                compression = 2
                usize = len(uncompressed)
            else:
                old = existing[name]
                compressed = archive.raw[old.data_offset:old.data_offset + old.compressed_size]
                compression = old.compression
                usize = old.uncompressed_size

            temp.write(compressed)
            payload_md5.append(hashlib.md5(compressed).digest())
            new_records.append(
                TreRecord(
                    hash_or_crc=soe_tre_crc(name),
                    uncompressed_size=usize,
                    data_offset=data_offset,
                    compression=compression,
                    compressed_size=len(compressed),
                    name_offset=0,
                    name=name,
                )
            )

        names_blob = bytearray()
        for rec in new_records:
            rec.name_offset = len(names_blob)
            names_blob += rec.name.encode("utf-8") + b"\0"

        metadata_offset = temp.tell()
        info = b"".join(
            struct.pack(
                "<6I",
                rec.hash_or_crc,
                rec.uncompressed_size,
                rec.data_offset,
                rec.compression,
                rec.compressed_size,
                rec.name_offset,
            )
            for rec in new_records
        )
        info_c = zlib.compress(info, 9)
        if archive.names_compression == 0:
            names_c = bytes(names_blob)
        elif archive.names_compression == 2:
            names_c = zlib.compress(bytes(names_blob), 9)
        else:
            raise WorldBuilderError(f"Unsupported TRE names compression: {archive.names_compression}")

        temp.write(info_c)
        temp.write(names_c)
        for digest in payload_md5:
            temp.write(digest)

        header = MAGIC + struct.pack(
            "<7I",
            len(new_records),
            metadata_offset,
            2,
            len(info_c),
            archive.names_compression,
            len(names_c),
            len(names_blob),
        )
        temp.seek(0)
        temp.write(header)

    try:
        reopened = open_tre(temp_path)
        validate_tre_v5_metadata(reopened, require_md5=True)
        if len(reopened.records) != len(new_records):
            raise WorldBuilderError("V2 TRE post-build record count mismatch")
        for key, expected in normalized.items():
            actual = reopened.extract(key)
            if actual != expected:
                raise WorldBuilderError(f"V2 TRE post-build validation failed for {key}")
        os.replace(temp_path, output_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


class AssetResolver:
    """Read source assets from the output base, extracted roots, or explicit TREs."""

    def __init__(
        self,
        base_archive: TreArchive,
        asset_roots: Sequence[Path] = (),
        asset_tres: Sequence[Path] = (),
    ) -> None:
        self.base_archive = base_archive
        self.asset_roots = [Path(p) for p in asset_roots]
        self.asset_tre_paths = [Path(p) for p in asset_tres]
        self._tre_cache: Dict[Path, TreArchive] = {}

    def _open_asset_tre(self, path: Path) -> TreArchive:
        if path.resolve() == self.base_archive.path.resolve():
            return self.base_archive
        if path not in self._tre_cache:
            self._tre_cache[path] = open_tre(path)
        return self._tre_cache[path]

    def read(self, archive_path: str) -> bytes:
        key = normalize_archive_path(archive_path)
        rec = self.base_archive.record_by_name_optional(key)
        if rec is not None:
            return self.base_archive.extract_record(rec)

        for root in self.asset_roots:
            candidate = root / Path(key)
            if candidate.is_file():
                return candidate.read_bytes()

        for tre_path in self.asset_tre_paths:
            archive = self._open_asset_tre(tre_path)
            rec = archive.record_by_name_optional(key)
            if rec is not None:
                return archive.extract_record(rec)

        searched = [str(self.base_archive.path)] + [str(p) for p in self.asset_roots] + [str(p) for p in self.asset_tre_paths]
        raise WorldBuilderError(
            f"Required structural asset {archive_path!r} was not found. Searched: " + ", ".join(searched)
        )


# ---------------------------------------------------------------------------
# WSNP / snapshot handling
# ---------------------------------------------------------------------------

def be_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def set_be_u32(buf: bytearray, offset: int, value: int) -> None:
    struct.pack_into(">I", buf, offset, value)


def _iff_chunk_end(start: int, size: int) -> int:
    end = start + 8 + size
    if size & 1:
        end += 1
    return end


def parse_snapshot(raw: bytes) -> SnapshotInfo:
    if len(raw) < 40 or raw[:4] != b"FORM" or raw[8:12] != b"WSNP":
        raise WorldBuilderError("Snapshot is not FORM/WSNP")

    top_form_start = 0
    top_size = be_u32(raw, 4)
    if top_size + 8 != len(raw):
        raise WorldBuilderError(f"WSNP outer FORM size mismatch ({top_size}+8 != {len(raw)})")

    version_form_start = 12
    if raw[version_form_start:version_form_start + 4] != b"FORM":
        raise WorldBuilderError("WSNP version FORM missing")
    version_size = be_u32(raw, version_form_start + 4)
    version_end = version_form_start + 8 + version_size
    if version_end > len(raw):
        raise WorldBuilderError("WSNP version FORM extends beyond file")

    cursor = version_form_start + 12
    nods_start = -1
    nods_size = -1
    otnl_start = -1
    otnl_size = -1

    while cursor + 8 <= version_end:
        tag = raw[cursor:cursor + 4]
        if tag == b"FORM":
            size = be_u32(raw, cursor + 4)
            form_type = raw[cursor + 8:cursor + 12]
            if form_type == b"NODS":
                nods_start = cursor
                nods_size = size
            cursor = cursor + 8 + size
            if size & 1:
                cursor += 1
        else:
            size = be_u32(raw, cursor + 4)
            if tag == b"OTNL":
                otnl_start = cursor
                otnl_size = size
                break
            cursor = _iff_chunk_end(cursor, size)

    if nods_start < 0:
        marker = raw.find(b"NODS", version_form_start + 12, version_end)
        if marker >= 8 and raw[marker - 8:marker - 4] == b"FORM":
            nods_start = marker - 8
            nods_size = be_u32(raw, nods_start + 4)
    if nods_start < 0:
        raise WorldBuilderError("Could not locate NODS form in snapshot")

    nods_end = nods_start + 8 + nods_size
    if nods_size & 1:
        nods_end += 1

    if raw[nods_end:nods_end + 4] == b"OTNL":
        otnl_start = nods_end
        otnl_size = be_u32(raw, otnl_start + 4)
    elif otnl_start < 0:
        marker = raw.find(b"OTNL", nods_end, version_end)
        if marker < 0:
            raise WorldBuilderError("Could not locate OTNL chunk in snapshot")
        otnl_start = marker
        otnl_size = be_u32(raw, otnl_start + 4)

    otnl_end = _iff_chunk_end(otnl_start, otnl_size)
    if otnl_start + 12 > len(raw):
        raise WorldBuilderError("OTNL chunk is truncated")

    count = struct.unpack_from("<I", raw, otnl_start + 8)[0]
    names_blob = raw[otnl_start + 12:otnl_start + 8 + otnl_size]
    names: List[str] = []
    pos = 0
    for _ in range(count):
        end = names_blob.find(b"\0", pos)
        if end < 0:
            raise WorldBuilderError("OTNL string table is truncated")
        names.append(names_blob[pos:end].decode("utf-8", errors="replace"))
        pos = end + 1

    nodes: List[SnapshotNodeInfo] = []
    cursor = nods_start + 12
    while cursor + 12 <= nods_end:
        if raw[cursor:cursor + 4] != b"FORM":
            break
        node_size = be_u32(raw, cursor + 4)
        node_end = cursor + 8 + node_size
        if raw[cursor + 8:cursor + 12] != b"NODE" or node_end > nods_end:
            break
        data_marker = raw.find(b"DATA", cursor + 12, node_end)
        if data_marker >= 0 and data_marker + 8 <= node_end:
            data_size = be_u32(raw, data_marker + 4)
            if data_size >= 52 and data_marker + 8 + 52 <= node_end:
                values = struct.unpack_from("<IIII4f3ffI", raw, data_marker + 8)
                nodes.append(SnapshotNodeInfo(*values))
        cursor = node_end + (node_size & 1)

    return SnapshotInfo(
        raw=raw,
        names=names,
        nodes=nodes,
        nods_form_start=nods_start,
        nods_form_size=nods_size,
        nods_end=nods_end,
        otnl_start=otnl_start,
        otnl_size=otnl_size,
        otnl_end=otnl_end,
        top_form_start=top_form_start,
        version_form_start=version_form_start,
    )


def _parse_snapshot_tree_node(raw: bytes, start: int, limit: int) -> Tuple[SnapshotTreeNode, int]:
    if start + 24 > limit or raw[start:start + 4] != b"FORM" or raw[start + 8:start + 12] != b"NODE":
        raise WorldBuilderError(f"Malformed snapshot NODE at offset {start}")
    node_size = be_u32(raw, start + 4)
    node_end = start + 8 + node_size
    if node_end > limit:
        raise WorldBuilderError("Snapshot NODE extends beyond containing form")

    version_start = start + 12
    if raw[version_start:version_start + 4] != b"FORM":
        raise WorldBuilderError("Snapshot NODE version FORM missing")
    version_end = version_start + 8 + be_u32(raw, version_start + 4)
    if version_end != node_end:
        raise WorldBuilderError("Snapshot NODE version FORM size mismatch")

    data_start = version_start + 12
    if raw[data_start:data_start + 4] != b"DATA" or be_u32(raw, data_start + 4) < 52:
        raise WorldBuilderError("Snapshot NODE DATA chunk missing or too small")
    values = struct.unpack_from("<IIII4f3ffI", raw, data_start + 8)
    node = SnapshotTreeNode(SnapshotNodeInfo(*values))

    cursor = data_start + 8 + be_u32(raw, data_start + 4)
    while cursor < version_end:
        child, child_end = _parse_snapshot_tree_node(raw, cursor, version_end)
        node.children.append(child)
        cursor = child_end
    if cursor != version_end:
        raise WorldBuilderError("Snapshot NODE children do not fill version FORM")
    return node, node_end


def parse_snapshot_tree(raw: bytes) -> SnapshotTree:
    base = parse_snapshot(raw)
    roots: List[SnapshotTreeNode] = []
    cursor = base.nods_form_start + 12
    limit = base.nods_form_start + 8 + base.nods_form_size
    while cursor < limit:
        root, cursor = _parse_snapshot_tree_node(raw, cursor, limit)
        roots.append(root)
    return SnapshotTree(base=base, roots=roots)


def _build_snapshot_node_raw(
    object_id: int,
    parent_id: int,
    name_id: int,
    cell_id: int,
    qw: float,
    qx: float,
    qy: float,
    qz: float,
    x: float,
    z: float,
    y: float,
    game_object_type: float,
    unknown2: int,
    children: Sequence[bytes] = (),
) -> bytes:
    for value, label in ((object_id, "object"), (parent_id, "parent"), (name_id, "name"), (cell_id, "cell")):
        if not (0 <= value <= 0xFFFFFFFF):
            raise WorldBuilderError(f"Snapshot {label} ID {value} does not fit uint32")
    data = struct.pack(
        "<IIII4f3ffI",
        object_id,
        parent_id,
        name_id,
        cell_id,
        qw,
        qx,
        qy,
        qz,
        x,
        z,
        y,
        game_object_type,
        unknown2,
    )
    data_chunk = b"DATA" + struct.pack(">I", len(data)) + data
    version_form_body = b"0000" + data_chunk + b"".join(children)
    version_form = b"FORM" + struct.pack(">I", len(version_form_body)) + version_form_body
    node_body = b"NODE" + version_form
    return b"FORM" + struct.pack(">I", len(node_body)) + node_body


def build_snapshot_node(
    object_id: int,
    name_id: int,
    obj: ProjectObject,
    game_object_type: float,
    unknown2: int = 0,
) -> bytes:
    node = _build_snapshot_node_raw(
        object_id, 0, name_id, 0,
        obj.qw, obj.qx, obj.qy, obj.qz,
        obj.x, obj.z, obj.y,
        game_object_type, unknown2,
    )
    assert len(node) == 84
    return node


def build_otnl(names: Sequence[str]) -> bytes:
    encoded = b"".join(name.encode("utf-8") + b"\0" for name in names)
    payload = struct.pack("<I", len(names)) + encoded
    result = b"OTNL" + struct.pack(">I", len(payload)) + payload
    if len(payload) & 1:
        result += b"\0"
    return result


def build_otnl_v2(names: Sequence[str]) -> bytes:
    # SWG world snapshots in Bellum Gero store OTNL without an IFF even-byte pad.
    # V1 keeps its proven historical helper above unchanged; V2 uses the exact
    # on-disk form observed in current Lok/Naboo snapshots.
    encoded = b"".join(name.encode("utf-8") + b"\0" for name in names)
    payload = struct.pack("<I", len(names)) + encoded
    return b"OTNL" + struct.pack(">I", len(payload)) + payload


def infer_snapshot_types(archive: TreArchive) -> Dict[str, Tuple[float, int]]:
    inferred: Dict[str, Tuple[float, int]] = {}
    snapshot_records = [r for r in archive.records if r.name.startswith("snapshot/") and r.name.endswith(".ws")]
    for rec in snapshot_records:
        try:
            info = parse_snapshot(archive.extract_record(rec))
        except WorldBuilderError:
            continue
        for node in info.nodes:
            if 0 <= node.name_id < len(info.names):
                template = info.names[node.name_id]
                inferred.setdefault(template, (node.game_object_type, node.unknown2))
    return inferred


def bake_snapshot(
    raw: bytes,
    objects: Sequence[ProjectObject],
    inferred_types: Dict[str, Tuple[float, int]],
    default_game_type: Optional[float],
) -> Tuple[bytes, Dict[int, int]]:
    """Proven V1 world/top-level snapshot baker."""
    info = parse_snapshot(raw)
    if any(obj.parent_id != 0 for obj in objects):
        bad = [obj.local_id for obj in objects if obj.parent_id != 0]
        raise WorldBuilderError(
            "TRE bake V1 supports world/top-level objects only. "
            f"Cell-parented WB IDs {bad} should use Lua export."
        )

    names = list(info.names)
    name_to_id = {name: idx for idx, name in enumerate(names)}
    next_oid = max((n.object_id for n in info.nodes), default=0) + 1
    nodes_to_add: List[bytes] = []
    id_map: Dict[int, int] = {}

    for obj in objects:
        snapshot_template = obj.snapshot_template
        if snapshot_template not in name_to_id:
            name_to_id[snapshot_template] = len(names)
            names.append(snapshot_template)
        name_id = name_to_id[snapshot_template]

        inferred = inferred_types.get(snapshot_template)
        if obj.snapshot_game_object_type >= 0.0:
            game_type = obj.snapshot_game_object_type
            unknown2 = inferred[1] if inferred else 0
        elif inferred is not None:
            game_type, unknown2 = inferred
        elif default_game_type is not None:
            game_type = default_game_type
            unknown2 = 0
        else:
            raise WorldBuilderError(
                f"WB #{obj.local_id}: could not infer snapshot gameObjectType for "
                f"{snapshot_template}. Place one known instance in the base TRE, set "
                "/wb snaptype <value>, or pass --default-game-type explicitly."
            )

        oid = next_oid
        next_oid += 1
        if oid > 0xFFFFFFFF:
            raise WorldBuilderError("Snapshot object ID space exhausted")
        id_map[obj.local_id] = oid
        nodes_to_add.append(build_snapshot_node(oid, name_id, obj, game_type, unknown2))

    node_blob = b"".join(nodes_to_add)
    new_otnl = build_otnl(names)
    old_otnl_total = info.otnl_end - info.otnl_start
    delta_otnl = len(new_otnl) - old_otnl_total
    delta_total = len(node_blob) + delta_otnl

    rebuilt = bytearray()
    rebuilt += raw[:info.nods_end]
    rebuilt += node_blob
    rebuilt += new_otnl
    rebuilt += raw[info.otnl_end:]

    set_be_u32(rebuilt, info.nods_form_start + 4, info.nods_form_size + len(node_blob))
    top_old = be_u32(raw, info.top_form_start + 4)
    version_old = be_u32(raw, info.version_form_start + 4)
    set_be_u32(rebuilt, info.top_form_start + 4, top_old + delta_total)
    set_be_u32(rebuilt, info.version_form_start + 4, version_old + delta_total)

    parsed = parse_snapshot(bytes(rebuilt))
    if len(parsed.nodes) != len(info.nodes) + len(objects):
        raise WorldBuilderError(
            f"Snapshot validation failed: node count {len(parsed.nodes)} != {len(info.nodes)}+{len(objects)}"
        )
    for obj in objects:
        if obj.snapshot_template not in parsed.names:
            raise WorldBuilderError(f"Snapshot validation lost OTNL template {obj.snapshot_template}")

    return bytes(rebuilt), id_map


# ---------------------------------------------------------------------------
# Structural IFF / POB / ILF helpers
# ---------------------------------------------------------------------------

def read_string_param(raw: bytes, field: str) -> str:
    marker = field.encode("utf-8") + b"\0"
    index = raw.find(marker)
    if index < 0:
        raise WorldBuilderError(f"Shared template does not contain {field}")
    pos = index + len(marker)
    if pos >= len(raw):
        raise WorldBuilderError(f"Truncated StringParam for {field}")
    mode = raw[pos]
    if mode == 0:
        return ""
    if mode != 1:
        raise WorldBuilderError(f"Unsupported StringParam mode {mode} for {field}")
    value, _ = cstring(raw, pos + 1, len(raw))
    return value


def patch_string_param(raw: bytes, field: str, new_value: str) -> bytes:
    marker = field.encode("utf-8") + b"\0"
    marker_index = raw.find(marker)
    if marker_index < 0:
        raise WorldBuilderError(f"Shared template does not contain {field}")

    # Locate the containing XXXX parameter chunk.
    chunk_start = -1
    search = 0
    while True:
        candidate = raw.find(b"XXXX", search)
        if candidate < 0:
            break
        if candidate + 8 <= len(raw):
            size = be_u32(raw, candidate + 4)
            if candidate + 8 <= marker_index < candidate + 8 + size <= len(raw):
                chunk_start = candidate
                break
        search = candidate + 1
    if chunk_start < 0:
        raise WorldBuilderError(f"Could not locate XXXX chunk for {field}")

    old_chunk_size = be_u32(raw, chunk_start + 4)
    param_start = marker_index + len(marker)
    mode = raw[param_start]
    if mode == 0:
        param_end = param_start + 1
    elif mode == 1:
        nul = raw.find(b"\0", param_start + 1, chunk_start + 8 + old_chunk_size)
        if nul < 0:
            raise WorldBuilderError(f"Truncated StringParam value for {field}")
        param_end = nul + 1
    else:
        raise WorldBuilderError(f"Unsupported StringParam mode {mode} for {field}")

    replacement = b"\x01" + new_value.encode("utf-8") + b"\0"
    delta = len(replacement) - (param_end - param_start)

    # Identify enclosing FORM sizes in the original before offsets move.
    ancestors: List[int] = []
    scan = 0
    while True:
        form = raw.find(b"FORM", scan)
        if form < 0 or form + 12 > len(raw):
            break
        size = be_u32(raw, form + 4)
        form_end = form + 8 + size
        if form < chunk_start < form_end <= len(raw):
            ancestors.append(form)
        scan = form + 1

    rebuilt = bytearray(raw[:param_start] + replacement + raw[param_end:])
    set_be_u32(rebuilt, chunk_start + 4, old_chunk_size + delta)
    for form in ancestors:
        set_be_u32(rebuilt, form + 4, be_u32(raw, form + 4) + delta)

    if read_string_param(bytes(rebuilt), field) != new_value:
        raise WorldBuilderError(f"Failed to patch {field} in project-specific shared IFF")
    return bytes(rebuilt)


def parse_portal_layout(raw: bytes, path: str) -> PortalInfo:
    if len(raw) < 32 or raw[:4] != b"FORM" or raw[8:12] != b"PRTO":
        raise WorldBuilderError(f"Portal layout {path} is not FORM/PRTO")

    cels_type = raw.find(b"CELS")
    if cels_type < 8 or raw[cels_type - 8:cels_type - 4] != b"FORM":
        raise WorldBuilderError(f"Portal layout {path} has no CELS form")
    cels_start = cels_type - 8
    cels_end = cels_start + 8 + be_u32(raw, cels_start + 4)
    if cels_end > len(raw):
        raise WorldBuilderError(f"Portal layout {path} CELS form is truncated")

    rooms: List[str] = []
    cursor = cels_start + 12
    while cursor < cels_end:
        if raw[cursor:cursor + 4] != b"FORM" or raw[cursor + 8:cursor + 12] != b"CELL":
            raise WorldBuilderError(f"Portal layout {path} malformed CELL at {cursor}")
        cell_end = cursor + 8 + be_u32(raw, cursor + 4)
        version_start = cursor + 12
        if raw[version_start:version_start + 4] != b"FORM":
            raise WorldBuilderError(f"Portal layout {path} CELL version form missing")
        data_start = version_start + 12
        if raw[data_start:data_start + 4] != b"DATA":
            raise WorldBuilderError(f"Portal layout {path} CELL DATA missing")
        data_end = data_start + 8 + be_u32(raw, data_start + 4)
        pos = data_start + 8
        if pos + 5 > data_end:
            raise WorldBuilderError(f"Portal layout {path} CELL DATA truncated")
        pos += 4  # numberOfPortals
        pos += 1  # unknown byte
        room, pos = cstring(raw, pos, data_end)
        rooms.append(room)
        cursor = cell_end

    crc_marker = raw.find(b"CRC ")
    if crc_marker < 0 or crc_marker + 12 > len(raw) or be_u32(raw, crc_marker + 4) < 4:
        raise WorldBuilderError(f"Portal layout {path} is missing CRC chunk")
    crc = struct.unpack_from("<I", raw, crc_marker + 8)[0]

    if len(rooms) < 2:
        raise WorldBuilderError(f"Portal layout {path} has no interior cells")
    return PortalInfo(path=path, crc=crc, rooms=rooms)


def parse_ilf(raw: bytes, path: str = "<memory>") -> List[InteriorNode]:
    if len(raw) < 24 or raw[:4] != b"FORM" or raw[8:12] != b"INLY":
        raise WorldBuilderError(f"Interior layout {path} is not FORM/INLY")
    version_start = 12
    if raw[version_start:version_start + 4] != b"FORM" or raw[version_start + 8:version_start + 12] != b"0000":
        raise WorldBuilderError(f"Interior layout {path} is not supported INLY/0000")
    version_end = version_start + 8 + be_u32(raw, version_start + 4)
    if version_end != len(raw):
        raise WorldBuilderError(f"Interior layout {path} form size mismatch")

    nodes: List[InteriorNode] = []
    cursor = version_start + 12
    while cursor < version_end:
        if raw[cursor:cursor + 4] != b"NODE":
            raise WorldBuilderError(f"Interior layout {path} malformed NODE at {cursor}")
        size = be_u32(raw, cursor + 4)
        end = cursor + 8 + size
        if end > version_end:
            raise WorldBuilderError(f"Interior layout {path} NODE extends beyond form")
        pos = cursor + 8
        template, pos = cstring(raw, pos, end)
        room, pos = cstring(raw, pos, end)
        if pos + 48 != end:
            raise WorldBuilderError(f"Interior layout {path} NODE transform size mismatch")
        values = struct.unpack_from("<12f", raw, pos)
        nodes.append(InteriorNode(template, room, values))
        cursor = end
    return nodes


def empty_ilf() -> bytes:
    version_body = b"0000"
    version = b"FORM" + struct.pack(">I", len(version_body)) + version_body
    outer_body = b"INLY" + version
    return b"FORM" + struct.pack(">I", len(outer_body)) + outer_body


def normalized_quaternion(w: float, x: float, y: float, z: float) -> Tuple[float, float, float, float]:
    norm = (w * w + x * x + y * y + z * z) ** 0.5
    if norm <= 1e-8:
        raise WorldBuilderError("Cannot publish zero-length quaternion")
    return w / norm, x / norm, y / norm, z / norm


def quaternion_matrix_3x3(w: float, x: float, y: float, z: float) -> Tuple[float, ...]:
    w, x, y, z = normalized_quaternion(w, x, y, z)
    return (
        1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y - z * w), 2.0 * (x * z + y * w),
        2.0 * (x * y + z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z - x * w),
        2.0 * (x * z - y * w), 2.0 * (y * z + x * w), 1.0 - 2.0 * (x * x + y * y),
    )


def build_ilf_node(interior: ProjectInterior, room_name: str) -> bytes:
    r = quaternion_matrix_3x3(interior.qw, interior.qx, interior.qy, interior.qz)
    # InteriorLayoutTemplate serializes Matrix4 row values as:
    # [0][0],[1][0],[2][0],Tx, [0][1],[1][1],[2][1],Tz,
    # [0][2],[1][2],[2][2],Ty. WBP x/z/y are already cell-local.
    values = (
        r[0], r[1], r[2], interior.x,
        r[3], r[4], r[5], interior.z,
        r[6], r[7], r[8], interior.y,
    )
    payload = (
        normalize_archive_path(interior.snapshot_template).encode("utf-8") + b"\0" +
        room_name.encode("utf-8") + b"\0" +
        struct.pack("<12f", *values)
    )
    return b"NODE" + struct.pack(">I", len(payload)) + payload


def append_ilf_nodes(source: bytes, nodes: Sequence[bytes], source_name: str) -> bytes:
    parse_ilf(source, source_name)
    if not nodes:
        return source
    version_start = 12
    version_end = version_start + 8 + be_u32(source, version_start + 4)
    blob = b"".join(nodes)
    rebuilt = bytearray(source[:version_end] + blob + source[version_end:])
    set_be_u32(rebuilt, version_start + 4, be_u32(source, version_start + 4) + len(blob))
    set_be_u32(rebuilt, 4, be_u32(source, 4) + len(blob))
    parse_ilf(bytes(rebuilt), source_name + " [published]")
    return bytes(rebuilt)


# ---------------------------------------------------------------------------
# Structural V2 publisher
# ---------------------------------------------------------------------------

def _add_name(names: List[str], name_to_id: Dict[str, int], value: str) -> int:
    value = normalize_archive_path(value)
    if value not in name_to_id:
        name_to_id[value] = len(names)
        names.append(value)
    return name_to_id[value]


def _resolve_static_game_type(
    obj: ProjectObject,
    inferred_types: Dict[str, Tuple[float, int]],
    default_game_type: Optional[float],
) -> Tuple[float, int]:
    inferred = inferred_types.get(obj.snapshot_template)
    if obj.snapshot_game_object_type >= 0.0:
        return obj.snapshot_game_object_type, inferred[1] if inferred else 0
    if inferred is not None:
        return inferred
    if default_game_type is not None:
        return default_game_type, 0
    raise WorldBuilderError(
        f"WB #{obj.local_id}: could not infer snapshot gameObjectType for {obj.snapshot_template}"
    )


def generate_server_template_lua(project: Project, published: Sequence[PublishedStructure]) -> str:
    lines = [
        "-- AUTO-GENERATED by Bellum Gero World Builder Structural Publisher",
        f"-- Project: {project.name} | Planet: {project.planet} | WBP V{project.version}",
        "-- Install this on the server before starting with the matching published TRE.",
        "-- Regenerate from the .wbp; do not hand-edit generated registrations.",
        "",
    ]
    for entry in published:
        source_shared_var = lua_var_for_template(entry.source_shared_template)
        source_server_var = lua_var_for_template(entry.source_server_template)
        custom_shared_var = lua_var_for_template(entry.custom_shared_template)
        custom_server_var = lua_var_for_template(entry.custom_server_template)
        lines += [
            f"-- WB STRUCTURE #{entry.local_id}",
            f"{custom_shared_var} = {source_shared_var}:new {{",
            f'\tclientTemplateFileName = "{entry.custom_shared_template}"',
            "}",
            f'ObjectTemplates:addClientTemplate({custom_shared_var}, "{entry.custom_shared_template}")',
            "",
            f"{custom_server_var} = {source_server_var}:new {{",
            f'\tclientTemplateFileName = "{entry.custom_shared_template}",',
            # Snapshot-authored structures are instantiated by ObjectManager from
            # the SERVER template gameObjectType. Keep these structural values
            # explicit so a project-specific shared-IFF clone can never degrade
            # to STATICOBJECT if an inherited IFF/Lua value is not materialized.
            f"\tgameObjectType = {entry.game_object_type},",
            f"\ttotalCellNumber = {entry.cell_count}",
            "}",
            f'ObjectTemplates:addTemplate({custom_server_var}, "{entry.custom_server_template}")',
            "",
        ]
    return "\n".join(lines).rstrip() + "\n"


def bake_snapshot_v2(
    raw: bytes,
    project: Project,
    resolver: AssetResolver,
    inferred_types: Dict[str, Tuple[float, int]],
    default_game_type: Optional[float],
    publish_id: Optional[str] = None,
    oid_allocator: Optional[Callable[[str], int]] = None,
    allowed_reserved_oids: Optional[Set[int]] = None,
) -> Tuple[bytes, Dict[str, bytes], StructuralBakeResult]:
    tree = parse_snapshot_tree(raw)
    info = tree.base
    all_existing = tree.flatten()

    # V1.9.7 batch hook: the clean-base safety rule remains the default.
    # During one desired-state batch build, later projects may receive the
    # in-memory snapshot produced by earlier projects on the same planet. The
    # caller must explicitly provide the exact reserved OIDs that are allowed
    # to already exist. Anything else is still treated as a contaminated base.
    reserved_existing = {
        node.info.object_id
        for node in all_existing
        if WB_STRUCTURAL_OID_MIN <= node.info.object_id <= WB_STRUCTURAL_OID_MAX
    }
    allowed_reserved = set(allowed_reserved_oids or ())
    missing_allowed = allowed_reserved - reserved_existing
    if missing_allowed:
        raise WorldBuilderError(
            "Batch structural publisher allowed-reserved set does not match the in-memory snapshot; "
            f"first missing OID: 0x{min(missing_allowed):08X}"
        )
    unexpected_reserved = reserved_existing - allowed_reserved
    if unexpected_reserved:
        raise WorldBuilderError(
            "V2 base snapshot already uses the Bellum Gero World Builder reserved structural ID band "
            f"0x{WB_STRUCTURAL_OID_MIN:08X}-0x{WB_STRUCTURAL_OID_MAX:08X} "
            f"(first unexpected collision: 0x{min(unexpected_reserved):08X}). "
            "Use the canonical clean base TRE; generated World Builder TREs must never become batch inputs."
        )

    next_oid = WB_STRUCTURAL_OID_MAX
    allocated_this_call: Set[int] = set()

    def allocate_structural_oid(logical_key: str) -> int:
        nonlocal next_oid
        if oid_allocator is not None:
            oid = int(oid_allocator(logical_key))
        else:
            if next_oid < WB_STRUCTURAL_OID_MIN:
                raise WorldBuilderError(
                    "Bellum Gero World Builder structural snapshot ID band exhausted"
                )
            oid = next_oid
            next_oid -= 1

        if not (WB_STRUCTURAL_OID_MIN <= oid <= WB_STRUCTURAL_OID_MAX):
            raise WorldBuilderError(
                f"Structural OID allocator returned 0x{oid:08X} outside the reserved World Builder range"
            )
        if oid in reserved_existing:
            raise WorldBuilderError(
                f"Structural OID allocator attempted to reuse existing in-memory snapshot OID 0x{oid:08X}"
            )
        if oid in allocated_this_call:
            raise WorldBuilderError(
                f"Structural OID allocator returned duplicate OID 0x{oid:08X} within one project bake"
            )
        allocated_this_call.add(oid)
        return oid

    names = list(info.names)
    name_to_id = {normalize_archive_path(name): idx for idx, name in enumerate(names)}
    nodes_to_add: List[bytes] = []
    replacements: Dict[str, bytes] = {}
    id_map: Dict[int, int] = {}
    published: List[PublishedStructure] = []
    slug = project_slug(publish_id if publish_id is not None else project.name)

    # WBP V2 may still contain ordinary static/world OBJECT records. Bake them
    # with the same rules as V1, while using the recursive max-ID allocator.
    for obj in project.objects:
        if obj.parent_id != 0:
            raise WorldBuilderError(
                f"WB #{obj.local_id}: V2 snapshot publishing requires OBJECT parent_id=0; "
                "persistent cell content must be an INTERIOR record."
            )
        name_id = _add_name(names, name_to_id, obj.snapshot_template)
        game_type, unknown2 = _resolve_static_game_type(obj, inferred_types, default_game_type)
        oid = allocate_structural_oid(f"{slug}/object/{obj.local_id}")
        id_map[obj.local_id] = oid
        nodes_to_add.append(build_snapshot_node(oid, name_id, obj, game_type, unknown2))

    interiors_by_structure: Dict[int, List[ProjectInterior]] = {}
    for interior in project.interiors:
        interiors_by_structure.setdefault(interior.structure_local_id, []).append(interior)

    cell_name_id = _add_name(names, name_to_id, CELL_SHARED_TEMPLATE)

    for structure in project.structures:
        source_shared = normalize_archive_path(structure.snapshot_template)
        source_server = normalize_archive_path(structure.object_template)
        source_iff = resolver.read(source_shared)
        if len(source_iff) < 12 or source_iff[:4] != b"FORM" or source_iff[8:12] != b"SBOT":
            raise WorldBuilderError(
                f"STRUCTURE #{structure.local_id}: {source_shared} is not a SharedBuildingObjectTemplate/SBOT"
            )

        portal_path = normalize_archive_path(read_string_param(source_iff, "portalLayoutFilename"))
        if not portal_path:
            raise WorldBuilderError(f"STRUCTURE #{structure.local_id}: shared template has no portalLayoutFilename")
        portal = parse_portal_layout(resolver.read(portal_path), portal_path)

        source_ilf_path = normalize_archive_path(read_string_param(source_iff, "interiorLayoutFileName"))
        if source_ilf_path:
            source_ilf = resolver.read(source_ilf_path)
        else:
            source_ilf = empty_ilf()
            source_ilf_path = "<empty>"

        custom_ilf = f"interiorlayout/worldbuilder/{slug}/structure_{structure.local_id}.ilf"
        custom_shared = f"object/building/worldbuilder/{slug}/shared_structure_{structure.local_id}.iff"
        custom_server = f"object/building/worldbuilder/{slug}/structure_{structure.local_id}.iff"

        custom_iff_bytes = patch_string_param(source_iff, "interiorLayoutFileName", custom_ilf)
        if normalize_archive_path(read_string_param(custom_iff_bytes, "portalLayoutFilename")) != portal_path:
            raise WorldBuilderError(
                f"STRUCTURE #{structure.local_id}: portal layout changed while cloning shared IFF"
            )

        ilf_nodes: List[bytes] = []
        interior_ids: List[int] = []
        for interior in interiors_by_structure.get(structure.local_id, []):
            if interior.cell_number > portal.cell_count:
                raise WorldBuilderError(
                    f"INTERIOR #{interior.local_id}: Cell {interior.cell_number} exceeds "
                    f"STRUCTURE #{structure.local_id} portal cell count {portal.cell_count}"
                )
            portal_room = portal.rooms[interior.cell_number]
            if interior.room_name and interior.room_name != portal_room:
                raise WorldBuilderError(
                    f"INTERIOR #{interior.local_id}: WBP room {interior.room_name!r} does not match "
                    f"portal Cell {interior.cell_number} room {portal_room!r}"
                )
            ilf_nodes.append(build_ilf_node(interior, portal_room))
            interior_ids.append(interior.local_id)

        custom_ilf_bytes = append_ilf_nodes(source_ilf, ilf_nodes, source_ilf_path)
        replacements[custom_ilf] = custom_ilf_bytes
        replacements[custom_shared] = custom_iff_bytes

        custom_name_id = _add_name(names, name_to_id, custom_shared)
        root_oid = allocate_structural_oid(f"{slug}/structure/{structure.local_id}")
        id_map[structure.local_id] = root_oid

        child_blobs: List[bytes] = []
        cell_oids: List[int] = []
        for cell_number in range(1, portal.cell_count + 1):
            cell_oid = allocate_structural_oid(f"{slug}/structure/{structure.local_id}/cell/{cell_number}")
            cell_oids.append(cell_oid)
            child_blobs.append(
                _build_snapshot_node_raw(
                    cell_oid,
                    root_oid,
                    cell_name_id,
                    cell_number,
                    1.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.0,
                    0,
                )
            )

        inferred = inferred_types.get(source_shared)
        if structure.snapshot_game_object_type >= 0.0:
            game_type = structure.snapshot_game_object_type
        elif inferred is not None:
            game_type = inferred[0]
        else:
            game_type = BUILDING_GAME_OBJECT_TYPE

        nodes_to_add.append(
            _build_snapshot_node_raw(
                root_oid,
                0,
                custom_name_id,
                0,
                structure.qw, structure.qx, structure.qy, structure.qz,
                structure.x, structure.z, structure.y,
                game_type,
                portal.crc,
                child_blobs,
            )
        )
        published.append(
            PublishedStructure(
                local_id=structure.local_id,
                root_object_id=root_oid,
                cell_object_ids=cell_oids,
                game_object_type=int(round(game_type)),
                source_server_template=source_server,
                source_shared_template=source_shared,
                source_portal_layout=portal_path,
                source_interior_layout=source_ilf_path,
                custom_server_template=custom_server,
                custom_shared_template=custom_shared,
                custom_interior_layout=custom_ilf,
                portal_crc=portal.crc,
                cell_count=portal.cell_count,
                interior_local_ids=interior_ids,
            )
        )

    node_blob = b"".join(nodes_to_add)
    new_otnl = build_otnl_v2(names)
    actual_otnl_end = info.otnl_start + 8 + info.otnl_size
    old_otnl_total = actual_otnl_end - info.otnl_start
    delta_otnl = len(new_otnl) - old_otnl_total
    delta_total = len(node_blob) + delta_otnl

    rebuilt = bytearray()
    rebuilt += raw[:info.nods_end]
    rebuilt += node_blob
    rebuilt += new_otnl
    rebuilt += raw[actual_otnl_end:]

    set_be_u32(rebuilt, info.nods_form_start + 4, info.nods_form_size + len(node_blob))
    set_be_u32(rebuilt, info.top_form_start + 4, be_u32(raw, info.top_form_start + 4) + delta_total)
    set_be_u32(rebuilt, info.version_form_start + 4, be_u32(raw, info.version_form_start + 4) + delta_total)

    baked = bytes(rebuilt)
    final_tree = parse_snapshot_tree(baked)
    final_nodes = {node.info.object_id: node for node in final_tree.flatten()}
    for entry in published:
        root = final_nodes.get(entry.root_object_id)
        if root is None:
            raise WorldBuilderError(f"STRUCTURE #{entry.local_id}: generated root missing after snapshot validation")
        if root.info.parent_id != 0 or root.info.cell_id != 0:
            raise WorldBuilderError(f"STRUCTURE #{entry.local_id}: generated root hierarchy invalid")
        if root.info.unknown2 != entry.portal_crc:
            raise WorldBuilderError(f"STRUCTURE #{entry.local_id}: portal CRC was not preserved in snapshot root")
        if len(root.children) != entry.cell_count:
            raise WorldBuilderError(
                f"STRUCTURE #{entry.local_id}: generated {len(root.children)} cell nodes; expected {entry.cell_count}"
            )
        for expected_cell, child in enumerate(root.children, start=1):
            if child.info.parent_id != entry.root_object_id or child.info.cell_id != expected_cell:
                raise WorldBuilderError(
                    f"STRUCTURE #{entry.local_id}: generated Cell {expected_cell} hierarchy invalid"
                )

    server_lua = generate_server_template_lua(project, published)
    result = StructuralBakeResult(
        id_map=id_map,
        server_lua=server_lua,
        structures=published,
        archive_paths=sorted(replacements),
    )
    return baked, replacements, result


# ---------------------------------------------------------------------------
# Build / validation / deploy
# ---------------------------------------------------------------------------

def bake_tre_v1(
    project: Project,
    base_tre: Path,
    output_tre: Path,
    default_game_type: Optional[float] = None,
) -> Dict[int, int]:
    """Exact V1/static production path retained from the validated baker."""
    validate_project(project)
    archive = open_tre(base_tre)
    snapshot_path = f"snapshot/{project.planet}.ws"
    original_snapshot = archive.extract(snapshot_path)
    inferred_types = infer_snapshot_types(archive)
    baked_snapshot, id_map = bake_snapshot(
        original_snapshot, project.objects, inferred_types, default_game_type
    )
    if output_tre.resolve() == base_tre.resolve():
        raise WorldBuilderError("Refusing to overwrite the base TRE in place")
    repack_tre(archive, {snapshot_path: baked_snapshot}, output_tre)

    finished = open_tre(output_tre)
    final_snapshot = parse_snapshot(finished.extract(snapshot_path))
    original_info = parse_snapshot(original_snapshot)
    if len(final_snapshot.nodes) != len(original_info.nodes) + len(project.objects):
        raise WorldBuilderError("Final TRE snapshot node count validation failed")
    return id_map


def bake_tre_v2(
    project: Project,
    base_tre: Path,
    output_tre: Path,
    default_game_type: Optional[float] = None,
    asset_roots: Sequence[Path] = (),
    asset_tres: Sequence[Path] = (),
) -> StructuralBakeResult:
    validate_project(project)
    if output_tre.resolve() == base_tre.resolve():
        raise WorldBuilderError("Refusing to overwrite the base TRE in place")
    if not project.structures:
        raise WorldBuilderError(
            "WBP V2 structural publisher was selected but the project contains no STRUCTURE records"
        )

    archive = open_tre(base_tre)
    validate_tre_v5_metadata(archive, require_md5=False)
    if not archive.md5_blob:
        print(
            "WARNING: Base TRE has no trailing MD5 table (legacy World Builder V1 archive). "
            "V2 compatibility mode is enabled; the output TRE will contain and validate a complete MD5 table."
        )
    resolver = AssetResolver(archive, asset_roots, asset_tres)
    snapshot_path = f"snapshot/{project.planet}.ws"
    original_snapshot = archive.extract(snapshot_path)
    inferred_types = infer_snapshot_types(archive)
    baked_snapshot, asset_replacements, result = bake_snapshot_v2(
        original_snapshot, project, resolver, inferred_types, default_game_type
    )

    replacements = dict(asset_replacements)
    replacements[snapshot_path] = baked_snapshot
    result.archive_paths = sorted(normalize_archive_path(path) for path in replacements)
    repack_tre_v2(archive, replacements, output_tre)

    finished = open_tre(output_tre)
    validate_tre_v5_metadata(finished, require_md5=True)
    final_tree = parse_snapshot_tree(finished.extract(snapshot_path))
    final_by_id = {node.info.object_id: node for node in final_tree.flatten()}

    for entry in result.structures:
        root = final_by_id.get(entry.root_object_id)
        if root is None:
            raise WorldBuilderError(f"Final TRE lost STRUCTURE #{entry.local_id} root")
        expected_name = normalize_archive_path(entry.custom_shared_template)
        if not (0 <= root.info.name_id < len(final_tree.base.names)):
            raise WorldBuilderError(f"Final TRE STRUCTURE #{entry.local_id} has invalid OTNL name ID")
        if normalize_archive_path(final_tree.base.names[root.info.name_id]) != expected_name:
            raise WorldBuilderError(f"Final TRE STRUCTURE #{entry.local_id} OTNL template mismatch")
        if len(root.children) != entry.cell_count:
            raise WorldBuilderError(f"Final TRE STRUCTURE #{entry.local_id} cell hierarchy mismatch")

        custom_iff = finished.extract(entry.custom_shared_template)
        if normalize_archive_path(read_string_param(custom_iff, "interiorLayoutFileName")) != normalize_archive_path(entry.custom_interior_layout):
            raise WorldBuilderError(f"Final TRE STRUCTURE #{entry.local_id} shared IFF does not point at custom ILF")
        if normalize_archive_path(read_string_param(custom_iff, "portalLayoutFilename")) != normalize_archive_path(entry.source_portal_layout):
            raise WorldBuilderError(f"Final TRE STRUCTURE #{entry.local_id} shared IFF portal layout changed")

        ilf_nodes = parse_ilf(finished.extract(entry.custom_interior_layout), entry.custom_interior_layout)
        source_count = 0
        if entry.source_interior_layout != "<empty>":
            try:
                source_count = len(parse_ilf(resolver.read(entry.source_interior_layout), entry.source_interior_layout))
            except WorldBuilderError:
                source_count = 0
        if len(ilf_nodes) != source_count + len(entry.interior_local_ids):
            raise WorldBuilderError(
                f"Final TRE STRUCTURE #{entry.local_id} ILF node count mismatch: "
                f"{len(ilf_nodes)} != {source_count}+{len(entry.interior_local_ids)}"
            )

    return result


def timestamp() -> str:
    return _dt.datetime.now().strftime("%Y%m%d-%H%M%S")


def backup_then_copy(source: Path, destination: Path) -> Optional[Path]:
    destination.parent.mkdir(parents=True, exist_ok=True)
    backup: Optional[Path] = None
    if destination.exists():
        backup = destination.with_name(destination.name + f".bak-{timestamp()}")
        shutil.copy2(destination, backup)
    shutil.copy2(source, destination)
    if hashlib.sha256(source.read_bytes()).digest() != hashlib.sha256(destination.read_bytes()).digest():
        raise WorldBuilderError(f"Post-deploy checksum mismatch at {destination}")
    return backup


def backup_then_write_text(path: Path, text: str) -> Optional[Path]:
    path.parent.mkdir(parents=True, exist_ok=True)
    backup: Optional[Path] = None
    encoded = text.encode("utf-8")
    if path.exists():
        existing = path.read_bytes()
        if existing == encoded:
            return None
        backup = path.with_name(path.name + f".bak-{timestamp()}")
        shutil.copy2(path, backup)
    path.write_bytes(encoded)
    return backup


def load_config(path: Path) -> dict:
    if not path.exists():
        raise WorldBuilderError(f"Config file not found: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise WorldBuilderError(f"Invalid JSON config {path}: {exc}") from exc


def deploy_tre(source: Path, config: dict, output_name: Optional[str] = None) -> List[Tuple[Path, Optional[Path]]]:
    if not source.exists():
        raise WorldBuilderError(f"Built TRE not found: {source}")
    name = output_name or config.get("output_tre_name") or source.name
    destinations: List[Path] = []
    for key in ("client_tre_dir", "server_tre_dir"):
        value = config.get(key)
        if value:
            destinations.append(Path(value).expanduser() / name)
    if not destinations:
        raise WorldBuilderError("Config has no client_tre_dir or server_tre_dir")

    results = []
    for destination in destinations:
        backup = backup_then_copy(source, destination)
        results.append((destination, backup))
    return results


def write_id_map(path: Path, project: Project, id_map: Dict[int, int]) -> None:
    payload = {
        "project": project.name,
        "planet": project.planet,
        "wbp_version": project.version,
        "generated": _dt.datetime.now().isoformat(timespec="seconds"),
        "world_snapshot_ids": {str(k): v for k, v in sorted(id_map.items())},
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_publish_manifest(path: Path, project: Project, output_tre: Path, result: StructuralBakeResult, server_lua_path: Path) -> None:
    payload = {
        "project": project.name,
        "planet": project.planet,
        "wbp_version": project.version,
        "generated": _dt.datetime.now().isoformat(timespec="seconds"),
        "output_tre": str(output_tre),
        "output_tre_sha256": hashlib.sha256(output_tre.read_bytes()).hexdigest(),
        "server_template_lua": str(server_lua_path),
        "server_loader_include_line": 'includeFile("building/worldbuilder/serverobjects.lua")',
        "server_generated_target": "MMOCoreORB/bin/scripts/object/building/worldbuilder/generated_templates.lua",
        "world_snapshot_ids": {str(k): v for k, v in sorted(result.id_map.items())},
        "snapshot_id_policy": {
            "strategy": WB_STRUCTURAL_OID_STRATEGY,
            "reserved_min": WB_STRUCTURAL_OID_MIN,
            "reserved_max": WB_STRUCTURAL_OID_MAX,
            "reserved_min_hex": f"0x{WB_STRUCTURAL_OID_MIN:08X}",
            "reserved_max_hex": f"0x{WB_STRUCTURAL_OID_MAX:08X}",
            "allocated_ids_descending": True,
            "note": (
                "V2 structural IDs are intentionally isolated from Core3's ordinary "
                "low-ID startup allocator. Bake from the canonical clean base TRE."
            ),
        },
        "safe_republish": {
            "project_slug": project_slug(project.name),
            "dry_run_command": f"/wb refreshpublished {project_slug(project.name)}",
            "confirm_command": f"/wb refreshpublished {project_slug(project.name)} confirm",
            "required_before_replacing_existing_publish": True,
            "workflow": (
                "While the OLD published TRE is still active, run the dry-run command on the "
                "project planet. If all checks pass and the structure is empty, run the confirm "
                "command. Then shut Core3 down normally, deploy this validated TRE plus its "
                "matching generated_templates.lua, and cold-start the server."
            ),
        },
        "added_or_replaced_archive_paths": result.archive_paths,
        "structures": [dataclasses.asdict(entry) for entry in result.structures],
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def cmd_validate(args: argparse.Namespace) -> int:
    project = read_project(Path(args.project))
    print(
        f"OK: {project.name} [{project.planet}] WBP V{project.version} - "
        f"OBJECT={len(project.objects)}, STRUCTURE={len(project.structures)}, "
        f"INTERIOR={len(project.interiors)}, group={len(project.group_ids)}"
    )
    cell_count = sum(1 for o in project.objects if o.parent_id != 0)
    if cell_count:
        print(f"NOTE: {cell_count} OBJECT record(s) are cell-parented; the static V1 TRE path does not support them.")
    if project.is_structural:
        print("Structural publish mode: snapshot hierarchy + project-specific shared IFF/ILF + server-template Lua companion.")
    return 0


def cmd_export_lua(args: argparse.Namespace) -> int:
    project_path = Path(args.project)
    project = read_project(project_path)
    output = Path(args.output) if args.output else project_path.with_name(project_path.stem + "_export.lua")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_lua(project), encoding="utf-8")
    print(f"Wrote {output}")
    return 0


def cmd_inspect_tre(args: argparse.Namespace) -> int:
    archive = open_tre(Path(args.tre))
    print(f"TRE: {archive.path}")
    print(f"Records: {len(archive.records)}")
    if archive.md5_blob:
        validate_tre_v5_metadata(archive, require_md5=True)
        print("TRE-v5 metadata: checksum ordering + stored-payload MD5 OK")
    else:
        print(
            "TRE-v5 metadata: no trailing MD5 table (legacy World Builder V1 archive). "
            "V1.9.2 can use this as a bake input and will repair the metadata in the output; "
            "do not treat this file itself as a fully normalized TRE-v5 archive."
        )
    if args.planet:
        snapshot_name = f"snapshot/{args.planet.lower()}.ws"
        tree = parse_snapshot_tree(archive.extract(snapshot_name))
        flat = tree.flatten()
        print(
            f"{snapshot_name}: {len(tree.roots)} top-level NODE(s), "
            f"{len(flat)} recursive NODE(s), {len(tree.base.names)} OTNL template(s)"
        )
        print(f"Max recursive object ID: {max((n.info.object_id for n in flat), default=0)}")
    return 0


def _paths_from_config(config: Optional[dict], key: str) -> List[Path]:
    if not config:
        return []
    value = config.get(key, [])
    if isinstance(value, str):
        value = [value]
    return [Path(v).expanduser() for v in value]


def _resolve_build_paths(args: argparse.Namespace) -> Tuple[Project, Path, Path, Optional[dict], List[Path], List[Path]]:
    project_path = Path(args.project)
    project = read_project(project_path)
    config = load_config(Path(args.config)) if getattr(args, "config", None) else None

    base = Path(args.base) if getattr(args, "base", None) else None
    if base is None and config and config.get("base_tre"):
        base = Path(config["base_tre"]).expanduser()
    if base is None:
        raise WorldBuilderError("A clean base TRE is required (--base or config.base_tre)")

    output = Path(args.output) if getattr(args, "output", None) else None
    if output is None:
        name = config.get("output_tre_name", "bg_custom1_worldbuilder.tre") if config else "bg_custom1_worldbuilder.tre"
        output = project_path.parent / name

    asset_roots = [Path(p) for p in (getattr(args, "asset_root", None) or [])]
    asset_roots += _paths_from_config(config, "asset_roots")
    asset_tres = [Path(p) for p in (getattr(args, "asset_tre", None) or [])]
    asset_tres += _paths_from_config(config, "asset_tres")
    return project, base, output, config, asset_roots, asset_tres


def _server_lua_output(args: argparse.Namespace, config: Optional[dict], output_tre: Path) -> Path:
    explicit = getattr(args, "server_lua_output", None)
    if explicit:
        return Path(explicit).expanduser()
    if config and config.get("server_template_lua"):
        return Path(config["server_template_lua"]).expanduser()
    return output_tre.with_suffix(output_tre.suffix + ".worldbuilder_templates.lua")


def cmd_bake_set(args: argparse.Namespace) -> int:
    from worldbuilder_batch import cmd_bake_set as batch_impl
    return int(batch_impl(args))


def cmd_deploy_set(args: argparse.Namespace) -> int:
    from worldbuilder_batch import cmd_deploy_set as batch_impl
    return int(batch_impl(args))


def cmd_bake_tre(args: argparse.Namespace) -> int:
    project, base, output, config, asset_roots, asset_tres = _resolve_build_paths(args)
    print(f"Baking project {project.name} (WBP V{project.version}) into {output}")
    print(f"Base TRE: {base}")

    if project.version == WBP_VERSION:
        id_map = bake_tre_v1(project, base, output, args.default_game_type)
        map_path = output.with_suffix(output.suffix + ".worldbuilder_ids.json")
        write_id_map(map_path, project, id_map)
        print(f"OK: {len(project.objects)} static object(s) baked into snapshot/{project.planet}.ws")
        print(f"ID map: {map_path}")
        return 0

    result = bake_tre_v2(
        project,
        base,
        output,
        args.default_game_type,
        asset_roots=asset_roots,
        asset_tres=asset_tres,
    )
    map_path = output.with_suffix(output.suffix + ".worldbuilder_ids.json")
    write_id_map(map_path, project, result.id_map)

    lua_path = _server_lua_output(args, config, output)
    lua_backup = backup_then_write_text(lua_path, result.server_lua)

    manifest_path = output.with_suffix(output.suffix + ".worldbuilder_publish.json")
    write_publish_manifest(manifest_path, project, output, result, lua_path)

    print(
        f"OK: structural publish validated - OBJECT={len(project.objects)}, "
        f"STRUCTURE={len(project.structures)}, INTERIOR={len(project.interiors)}"
    )
    print(f"ID map: {map_path}")
    print(f"Server template Lua: {lua_path}")
    if lua_backup:
        print(f"  Lua backup: {lua_backup}")
    print(f"Publish manifest: {manifest_path}")
    allocated_ids = list(result.id_map.values())
    for entry in result.structures:
        allocated_ids.extend(entry.cell_object_ids)
    if allocated_ids:
        print(
            "Structural snapshot ID policy: "
            f"{WB_STRUCTURAL_OID_STRATEGY} "
            f"(reserved 0x{WB_STRUCTURAL_OID_MIN:08X}-0x{WB_STRUCTURAL_OID_MAX:08X}; "
            f"allocated 0x{min(allocated_ids):08X}-0x{max(allocated_ids):08X})"
        )
    print("IMPORTANT: the matching generated Lua must be installed as:")
    print("  MMOCoreORB/bin/scripts/object/building/worldbuilder/generated_templates.lua")
    print("The supplied one-time building/worldbuilder loader includes that file after stock building templates.")
    print("Safe republish workflow for an EXISTING published structural project:")
    print(f"  Dry run: /wb refreshpublished {project_slug(project.name)}")
    print(f"  Confirm: /wb refreshpublished {project_slug(project.name)} confirm")
    print("  Run these while the OLD TRE is still active, then shut down, deploy the validated new TRE + matching Lua, and cold-start.")
    print("V2 build complete. Validate locally before using the separate deploy command.")
    return 0


def cmd_deploy(args: argparse.Namespace) -> int:
    config = load_config(Path(args.config))
    results = deploy_tre(Path(args.tre), config, args.name)
    for destination, backup in results:
        print(f"Deployed: {destination}")
        if backup:
            print(f"  Backup: {backup}")
    return 0


def cmd_build_deploy(args: argparse.Namespace) -> int:
    project, base, output, config, asset_roots, asset_tres = _resolve_build_paths(args)
    if config is None:
        raise WorldBuilderError("build-deploy requires --config")
    if project.version >= WBP_STRUCTURAL_VERSION:
        raise WorldBuilderError(
            "WBP V2 structural projects intentionally do not use one-step build-deploy. "
            "Run bake-tre, install/include the generated server-template Lua, validate the separate output TRE, "
            "then run deploy explicitly."
        )
    print(f"Baking project {project.name} into {output}")
    id_map = bake_tre_v1(project, base, output, args.default_game_type)
    map_path = output.with_suffix(output.suffix + ".worldbuilder_ids.json")
    write_id_map(map_path, project, id_map)
    results = deploy_tre(output, config, args.name)
    print(f"OK: baked {len(project.objects)} object(s)")
    for destination, backup in results:
        print(f"Deployed: {destination}")
        if backup:
            print(f"  Backup: {backup}")
    return 0


def _add_structural_asset_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--asset-root",
        action="append",
        default=[],
        help="read-only extracted TRE root containing source IFF/POB/ILF assets; repeatable",
    )
    parser.add_argument(
        "--asset-tre",
        action="append",
        default=[],
        help="read-only TRE to search for structural source assets not present in the base; repeatable",
    )
    parser.add_argument(
        "--server-lua-output",
        help="WBP V2 generated server-template Lua destination (default: beside output TRE)",
    )


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Bellum Gero World Builder companion tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python bellum_worldbuilder.py validate droid_cave.wbp
  python bellum_worldbuilder.py export-lua static_project.wbp
  python bellum_worldbuilder.py inspect-tre bg_custom1.tre --planet lok
  python bellum_worldbuilder.py bake-tre static_project.wbp --base bg_custom1.tre --output bg_custom1_static.tre
  python bellum_worldbuilder.py bake-tre droid_cave.wbp --base bg_custom1.tre --asset-root WorldBuilderStructureRefs --output bg_custom1_droid_cave.tre
  python bellum_worldbuilder.py deploy bg_custom1_droid_cave.tre --config worldbuilder_config.json
""",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("validate", help="validate a .wbp project")
    p.add_argument("project")
    p.set_defaults(func=cmd_validate)

    p = sub.add_parser("export-lua", help="generate a Lua placement screenplay for a static project")
    p.add_argument("project")
    p.add_argument("--output", "-o")
    p.set_defaults(func=cmd_export_lua)

    p = sub.add_parser("inspect-tre", help="validate/inspect a TRE and optional planet snapshot")
    p.add_argument("tre")
    p.add_argument("--planet")
    p.set_defaults(func=cmd_inspect_tre)

    p = sub.add_parser("bake-tre", help="bake a finalized WBP project into a separate TRE")
    p.add_argument("project")
    p.add_argument("--base", help="clean/known base TRE")
    p.add_argument("--output", "-o")
    p.add_argument("--config", help="optional config providing base/output/assets")
    p.add_argument("--default-game-type", type=float, help="explicit fallback only when static type inference fails")
    _add_structural_asset_args(p)
    p.set_defaults(func=cmd_bake_tre)

    p = sub.add_parser("bake-set", help="build one validated structural candidate TRE from the approved WBP publish set")
    p.add_argument("--config", required=True, help="batch World Builder config")
    p.add_argument("--default-game-type", type=float, help="explicit fallback only when static type inference fails")
    p.set_defaults(func=cmd_bake_set)

    p = sub.add_parser("deploy-set", help="transactionally deploy a validated batch candidate TRE + generated Lua")
    p.add_argument("--config", required=True, help="batch World Builder config")
    p.add_argument("--manifest", help="candidate worldbuilder_publish.json override")
    p.add_argument(
        "--confirm-refreshed",
        action="store_true",
        help="confirm required /wb refreshpublished commands were completed against the old live TRE before shutdown",
    )
    p.set_defaults(func=cmd_deploy_set)

    p = sub.add_parser("deploy", help="copy an already-built TRE to configured client/server dirs with backups")
    p.add_argument("tre")
    p.add_argument("--config", required=True)
    p.add_argument("--name", help="destination TRE filename override")
    p.set_defaults(func=cmd_deploy)

    p = sub.add_parser("build-deploy", help="V1 static convenience path; V2 requires staged bake/deploy")
    p.add_argument("project")
    p.add_argument("--config", required=True)
    p.add_argument("--base", help="override config.base_tre")
    p.add_argument("--output", "-o", help="build output before deploy")
    p.add_argument("--name", help="destination TRE filename override")
    p.add_argument("--default-game-type", type=float, help="explicit fallback only when static type inference fails")
    _add_structural_asset_args(p)
    p.set_defaults(func=cmd_build_deploy)

    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = make_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except WorldBuilderError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("Cancelled.", file=sys.stderr)
        return 130


# Bellum Gero World Builder V1.9.8 - WBP V3 project-extension layer.
# Imported late so the proven V1/V2 implementation is defined first, then extended.
import worldbuilder_project_extensions as _wb_project_extensions
_wb_project_extensions.install(sys.modules[__name__])

if __name__ == "__main__":
    raise SystemExit(main())
