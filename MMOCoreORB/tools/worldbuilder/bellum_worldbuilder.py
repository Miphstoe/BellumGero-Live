#!/usr/bin/env python3
"""
Bellum Gero World Builder companion tool.

Purpose
-------
The in-game World Builder is the live 3D editor. It autosaves a small .wbp
manifest. This tool turns that manifest into production-friendly output:

  * validate       - validate a .wbp project
  * export-lua     - generate a Lua placement screenplay
  * inspect-tre    - inspect/validate a TRE archive and a planet snapshot
  * bake-tre       - inject WORLD/TOP-LEVEL .wbp objects into snapshot/<planet>.ws
  * deploy         - copy a built TRE to configured client/server locations with backups
  * build-deploy   - bake then deploy in one command

TRE baking is intentionally conservative:
  * It requires a CLEAN/KNOWN base TRE each time.
  * It refuses cell-parented objects (use Lua export for those in V1).
  * It infers WorldSnapshot gameObjectType from an existing instance of the same
    snapshot template in the base TRE. If inference is impossible, it fails unless
    the .wbp object has an explicit snapshot type override or --default-game-type
    is supplied.
  * It never mutates the base TRE in place.

The TRE v5 and WSNP handling here is deliberately narrow and validated against
Bellum Gero's current bg_custom1 workflow. Keep a backup of production assets.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as _dt
import json
import os
import shutil
import struct
import sys
import tempfile
import zlib
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


MAGIC = b"EERT5000"
TRE_HEADER_SIZE = 36
WBP_MAGIC = "BELLUM_GERO_WORLD_BUILDER"
WBP_VERSION = 1


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
class Project:
    name: str = ""
    planet: str = ""
    move_step: float = 0.10
    rotate_step: float = 5.0
    selected: int = 0
    next_id: int = 1
    last_template: str = ""
    objects: List[ProjectObject] = dataclasses.field(default_factory=list)
    group_ids: List[int] = dataclasses.field(default_factory=list)


@dataclasses.dataclass
class TreRecord:
    hash_or_crc: int
    uncompressed_size: int
    data_offset: int
    compression: int
    compressed_size: int
    name_offset: int
    name: str = ""


@dataclasses.dataclass
class TreArchive:
    path: Path
    raw: bytes
    records: List[TreRecord]
    names_blob: bytes
    names_compression: int
    names_compressed_blob: bytes
    names_uncompressed_size: int

    def record_by_name(self, name: str) -> TreRecord:
        normalized = name.replace("\\", "/").lower()
        for rec in self.records:
            if rec.name.lower() == normalized:
                return rec
        raise WorldBuilderError(f"TRE does not contain {name!r}")

    def extract_record(self, rec: TreRecord) -> bytes:
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
                if len(parts) != 2 or int(parts[1]) != WBP_VERSION:
                    raise WorldBuilderError(
                        f"{path}:{line_number}: unsupported project version"
                    )
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
            else:
                raise WorldBuilderError(f"{path}:{line_number}: unknown record {key!r}")
        except (IndexError, ValueError) as exc:
            raise WorldBuilderError(f"{path}:{line_number}: malformed {key} record") from exc

    if not valid_header:
        raise WorldBuilderError(f"{path}: missing {WBP_MAGIC} {WBP_VERSION} header")
    validate_project(project, source=path)
    return project


def validate_project(project: Project, source: Optional[Path] = None) -> None:
    where = f"{source}: " if source else ""
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
        if obj.local_id <= 0:
            raise WorldBuilderError(where + f"object local ID must be > 0: {obj.local_id}")
        if obj.local_id in seen:
            raise WorldBuilderError(where + f"duplicate local ID {obj.local_id}")
        seen.add(obj.local_id)
        if not obj.object_template.endswith(".iff"):
            raise WorldBuilderError(where + f"WB #{obj.local_id}: object template is not .iff")
        if not obj.snapshot_template.endswith(".iff"):
            raise WorldBuilderError(where + f"WB #{obj.local_id}: snapshot template is not .iff")
        # Allow some tolerance for floating point drift, but catch corrupted quaternions.
        qnorm = (obj.qw**2 + obj.qx**2 + obj.qy**2 + obj.qz**2) ** 0.5
        if not (0.5 <= qnorm <= 1.5):
            raise WorldBuilderError(
                where + f"WB #{obj.local_id}: quaternion norm {qnorm:.4f} looks invalid"
            )
        if obj.parent_id < 0:
            raise WorldBuilderError(where + f"WB #{obj.local_id}: parent ID cannot be negative")

    missing_group = [gid for gid in project.group_ids if gid not in seen]
    if missing_group:
        raise WorldBuilderError(where + f"group references missing object IDs: {missing_group}")


# ---------------------------------------------------------------------------
# Lua export
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


def fmt(value: float) -> str:
    text = f"{value:.9f}".rstrip("0").rstrip(".")
    return text if text not in {"", "-0"} else "0"


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

    # Validate all data ranges now instead of discovering corruption during a build.
    for rec in records:
        if rec.data_offset < TRE_HEADER_SIZE or rec.data_offset + rec.compressed_size > metadata_offset:
            raise WorldBuilderError(f"Invalid data range for TRE record {rec.name}")

    return TreArchive(
        path=path,
        raw=raw,
        records=records,
        names_blob=names_blob,
        names_compression=names_compression,
        names_compressed_blob=names_c,
        names_uncompressed_size=names_uncompressed_size,
    )


def repack_tre(archive: TreArchive, replacements: Dict[str, bytes], output_path: Path) -> None:
    normalized_replacements = {k.replace("\\", "/").lower(): v for k, v in replacements.items()}
    unseen = set(normalized_replacements)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False, dir=str(output_path.parent), prefix=output_path.name + ".tmp.") as temp:
        temp_path = Path(temp.name)
        temp.write(b"\0" * TRE_HEADER_SIZE)
        new_records: List[TreRecord] = []

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
        # File names are unchanged, so preserve the original compressed names block exactly.
        temp.write(archive.names_compressed_blob)

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
        # Validate the full temporary archive before replacing the requested output path.
        reopened = open_tre(temp_path)
        for key, expected in normalized_replacements.items():
            actual = reopened.extract(key)
            if actual != expected:
                raise WorldBuilderError(f"Post-build validation failed for {key}")
        os.replace(temp_path, output_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


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

    # Find NODS and OTNL structurally within the 0001 form.
    cursor = version_form_start + 12  # FORM size type
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
        # The NODS form is normally the first child and may contain hundreds of NODE forms.
        # Search only for the form signature if a future snapshot has an unusual sibling order.
        marker = raw.find(b"NODS", version_form_start + 12, version_end)
        if marker >= 8 and raw[marker - 8:marker - 4] == b"FORM":
            nods_start = marker - 8
            nods_size = be_u32(raw, nods_start + 4)

    if nods_start < 0:
        raise WorldBuilderError("Could not locate NODS form in snapshot")

    nods_end = nods_start + 8 + nods_size
    if nods_size & 1:
        nods_end += 1

    # In Bellum Gero's world snapshots OTNL follows NODS. Prefer exact adjacency.
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
    if len(names) != count:
        raise WorldBuilderError("OTNL name count mismatch")

    nodes: List[SnapshotNodeInfo] = []
    cursor = nods_start + 12  # FORM size NODS
    # Parse only top-level NODEs. This is exactly what the world-level baker needs.
    while cursor + 12 <= nods_end:
        if raw[cursor:cursor + 4] != b"FORM":
            break
        node_size = be_u32(raw, cursor + 4)
        node_end = cursor + 8 + node_size
        if raw[cursor + 8:cursor + 12] != b"NODE" or node_end > nods_end:
            break

        # Find the first DATA chunk inside this NODE's version form.
        search_start = cursor + 12
        data_marker = raw.find(b"DATA", search_start, node_end)
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


def build_snapshot_node(
    object_id: int,
    name_id: int,
    obj: ProjectObject,
    game_object_type: float,
    unknown2: int = 0,
) -> bytes:
    if not (0 <= object_id <= 0xFFFFFFFF):
        raise WorldBuilderError(f"Snapshot object ID {object_id} does not fit uint32")
    if not (0 <= name_id <= 0xFFFFFFFF):
        raise WorldBuilderError(f"Snapshot name ID {name_id} does not fit uint32")

    data = struct.pack(
        "<IIII4f3ffI",
        object_id,
        0,  # world parent
        name_id,
        0,  # cell id for world-level nodes
        obj.qw,
        obj.qx,
        obj.qy,
        obj.qz,
        obj.x,
        obj.z,
        obj.y,
        game_object_type,
        unknown2,
    )
    assert len(data) == 52
    data_chunk = b"DATA" + struct.pack(">I", len(data)) + data
    version_form_body = b"0000" + data_chunk
    version_form = b"FORM" + struct.pack(">I", len(version_form_body)) + version_form_body
    node_body = b"NODE" + version_form
    node = b"FORM" + struct.pack(">I", len(node_body)) + node_body
    assert len(node) == 84
    return node


def build_otnl(names: Sequence[str]) -> bytes:
    encoded = b"".join(name.encode("utf-8") + b"\0" for name in names)
    payload = struct.pack("<I", len(names)) + encoded
    result = b"OTNL" + struct.pack(">I", len(payload)) + payload
    if len(payload) & 1:
        result += b"\0"
    return result


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

    # Replace OTNL and insert nodes immediately before it.
    rebuilt = bytearray()
    rebuilt += raw[:info.nods_end]
    rebuilt += node_blob
    rebuilt += new_otnl
    rebuilt += raw[info.otnl_end:]

    # Sizes are big-endian IFF form sizes (bytes following the size field).
    set_be_u32(rebuilt, info.nods_form_start + 4, info.nods_form_size + len(node_blob))
    top_old = be_u32(raw, info.top_form_start + 4)
    version_old = be_u32(raw, info.version_form_start + 4)
    set_be_u32(rebuilt, info.top_form_start + 4, top_old + delta_total)
    set_be_u32(rebuilt, info.version_form_start + 4, version_old + delta_total)

    # Validate structural invariants after the edit.
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
# Build/deploy
# ---------------------------------------------------------------------------

def bake_tre(
    project: Project,
    base_tre: Path,
    output_tre: Path,
    default_game_type: Optional[float] = None,
) -> Dict[int, int]:
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

    # Final end-to-end checks.
    finished = open_tre(output_tre)
    final_snapshot = parse_snapshot(finished.extract(snapshot_path))
    original_info = parse_snapshot(original_snapshot)
    if len(final_snapshot.nodes) != len(original_info.nodes) + len(project.objects):
        raise WorldBuilderError("Final TRE snapshot node count validation failed")
    return id_map


def timestamp() -> str:
    return _dt.datetime.now().strftime("%Y%m%d-%H%M%S")


def backup_then_copy(source: Path, destination: Path) -> Optional[Path]:
    destination.parent.mkdir(parents=True, exist_ok=True)
    backup: Optional[Path] = None
    if destination.exists():
        backup = destination.with_name(destination.name + f".bak-{timestamp()}")
        shutil.copy2(destination, backup)
    shutil.copy2(source, destination)
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
        "generated": _dt.datetime.now().isoformat(timespec="seconds"),
        "world_snapshot_ids": {str(k): v for k, v in sorted(id_map.items())},
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def cmd_validate(args: argparse.Namespace) -> int:
    project = read_project(Path(args.project))
    print(f"OK: {project.name} [{project.planet}] - {len(project.objects)} object(s), group={len(project.group_ids)}")
    cell_count = sum(1 for o in project.objects if o.parent_id != 0)
    if cell_count:
        print(f"NOTE: {cell_count} object(s) are cell-parented; Lua export supports them, TRE bake V1 does not.")
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
    if args.planet:
        snapshot_name = f"snapshot/{args.planet.lower()}.ws"
        snapshot = parse_snapshot(archive.extract(snapshot_name))
        print(f"{snapshot_name}: {len(snapshot.nodes)} top-level NODE(s), {len(snapshot.names)} OTNL template(s)")
        print(f"Max top-level object ID: {max((n.object_id for n in snapshot.nodes), default=0)}")
    return 0


def _resolve_build_paths(args: argparse.Namespace) -> Tuple[Project, Path, Path, Optional[dict]]:
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
    return project, base, output, config


def cmd_bake_tre(args: argparse.Namespace) -> int:
    project, base, output, _ = _resolve_build_paths(args)
    print(f"Baking project {project.name} into {output}")
    print(f"Base TRE: {base}")
    id_map = bake_tre(project, base, output, args.default_game_type)
    map_path = output.with_suffix(output.suffix + ".worldbuilder_ids.json")
    write_id_map(map_path, project, id_map)
    print(f"OK: {len(project.objects)} object(s) baked into snapshot/{project.planet}.ws")
    print(f"ID map: {map_path}")
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
    project, base, output, config = _resolve_build_paths(args)
    if config is None:
        raise WorldBuilderError("build-deploy requires --config")
    print(f"Baking project {project.name} into {output}")
    id_map = bake_tre(project, base, output, args.default_game_type)
    map_path = output.with_suffix(output.suffix + ".worldbuilder_ids.json")
    write_id_map(map_path, project, id_map)
    results = deploy_tre(output, config, args.name)
    print(f"OK: baked {len(project.objects)} object(s)")
    for destination, backup in results:
        print(f"Deployed: {destination}")
        if backup:
            print(f"  Backup: {backup}")
    return 0


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Bellum Gero World Builder companion tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python bellum_worldbuilder.py validate droid_cave.wbp
  python bellum_worldbuilder.py export-lua droid_cave.wbp
  python bellum_worldbuilder.py inspect-tre bg_custom1.tre --planet lok
  python bellum_worldbuilder.py bake-tre droid_cave.wbp --base bg_custom1.tre --output bg_custom1_droid_cave.tre
  python bellum_worldbuilder.py build-deploy droid_cave.wbp --config worldbuilder_config.json
""",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("validate", help="validate a .wbp project")
    p.add_argument("project")
    p.set_defaults(func=cmd_validate)

    p = sub.add_parser("export-lua", help="generate a Lua placement screenplay")
    p.add_argument("project")
    p.add_argument("--output", "-o")
    p.set_defaults(func=cmd_export_lua)

    p = sub.add_parser("inspect-tre", help="validate/inspect a TRE and optional planet snapshot")
    p.add_argument("tre")
    p.add_argument("--planet")
    p.set_defaults(func=cmd_inspect_tre)

    p = sub.add_parser("bake-tre", help="bake world-level project objects into snapshot/<planet>.ws")
    p.add_argument("project")
    p.add_argument("--base", help="clean/known base TRE")
    p.add_argument("--output", "-o")
    p.add_argument("--config", help="optional config providing base_tre/output_tre_name")
    p.add_argument("--default-game-type", type=float, help="explicit fallback only when type inference fails")
    p.set_defaults(func=cmd_bake_tre)

    p = sub.add_parser("deploy", help="copy an already-built TRE to configured client/server dirs with backups")
    p.add_argument("tre")
    p.add_argument("--config", required=True)
    p.add_argument("--name", help="destination TRE filename override")
    p.set_defaults(func=cmd_deploy)

    p = sub.add_parser("build-deploy", help="bake from clean base then deploy to configured locations")
    p.add_argument("project")
    p.add_argument("--config", required=True)
    p.add_argument("--base", help="override config.base_tre")
    p.add_argument("--output", "-o", help="build output before deploy")
    p.add_argument("--name", help="destination TRE filename override")
    p.add_argument("--default-game-type", type=float, help="explicit fallback only when type inference fails")
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


if __name__ == "__main__":
    raise SystemExit(main())
