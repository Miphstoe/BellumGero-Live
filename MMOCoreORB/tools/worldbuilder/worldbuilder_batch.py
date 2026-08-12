#!/usr/bin/env python3
"""
Bellum Gero World Builder multi-project structural publishing support.

This module is intentionally a thin orchestration layer over bellum_worldbuilder.py.
It does not reimplement TRE/IFF/WSNP parsing. The existing V2 structural publisher
remains the source of truth for building snapshot nodes, project-specific shared
IFFs, ILFs, validation, and TRE-v5 repacking.

The batch workflow is desired-state based:
  normal bg_custom1.tre + approved publish set + persistent OID registry
      -> minimal bg_worldbuilder.tre overlay + generated_templates.lua + manifests

The active OID registry and deployed-state files are changed only by deploy-set,
never by bake-set. This keeps candidate generation non-destructive.
"""

from __future__ import annotations

import dataclasses
import datetime as _dt
import hashlib
import json
import os
import re
import shutil
import struct
import tempfile
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

_main_module = sys.modules.get("__main__")
if _main_module is not None and hasattr(_main_module, "bake_snapshot_v2") and hasattr(_main_module, "open_tre"):
    wb = _main_module
else:
    import bellum_worldbuilder as wb


BATCH_SCHEMA_VERSION = 2
PUBLISH_SET_SCHEMA_VERSION = 1
OID_REGISTRY_SCHEMA_VERSION = 1
DEPLOYED_STATE_SCHEMA_VERSION = 1

CANDIDATE_TRE_NAME_FALLBACK = "bg_worldbuilder.tre"
CANDIDATE_LUA_NAME = "generated_templates.lua"
CANDIDATE_MANIFEST_NAME = "worldbuilder_publish.json"
CANDIDATE_ID_MAP_NAME = "worldbuilder_ids.json"
CANDIDATE_REGISTRY_NAME = "worldbuilder_oid_registry.json"

WB_ARCHIVE_PREFIXES = (
    "object/building/worldbuilder/",
    "interiorlayout/worldbuilder/",
)


@dataclass
class ApprovedProject:
    publish_id: str
    source_path: Path
    project: wb.Project
    wbp_sha256: str


@dataclass
class BatchProjectResult:
    approved: ApprovedProject
    bake_result: wb.StructuralBakeResult
    asset_replacements: Dict[str, bytes]
    oid_assignments: Dict[str, int]
    fingerprint: str = ""


class StructuralOIDRegistry:
    """Persistent logical-key -> OID mapping for the reserved WB structural band.

    Assignments are never transferred to another logical key. Keys omitted from
    the current publish set become retired, but their historical assignment is
    retained forever. If the exact same logical key later returns, it resumes its
    original identity rather than allocating a different OID.
    """

    def __init__(self, assignments: Optional[Dict[str, int]] = None) -> None:
        self.assignments: Dict[str, int] = dict(assignments or {})
        self.active_keys: Set[str] = set()
        self._validate_assignments()

    @classmethod
    def load(cls, path: Path, deployed_state_path: Optional[Path] = None) -> "StructuralOIDRegistry":
        if not path.exists():
            if deployed_state_path is not None and deployed_state_path.exists():
                state = _load_json(deployed_state_path, "deployed state")
                if state.get("projects"):
                    raise wb.WorldBuilderError(
                        f"OID registry is missing at {path}, but deployed World Builder projects exist. "
                        "Restore the registry from source control/backup before building another candidate."
                    )
            return cls()

        payload = _load_json(path, "OID registry")
        if payload.get("version") != OID_REGISTRY_SCHEMA_VERSION:
            raise wb.WorldBuilderError(
                f"Unsupported World Builder OID registry version in {path}: {payload.get('version')!r}"
            )
        strategy = payload.get("strategy")
        if strategy != wb.WB_STRUCTURAL_OID_STRATEGY:
            raise wb.WorldBuilderError(
                f"OID registry strategy {strategy!r} does not match publisher strategy "
                f"{wb.WB_STRUCTURAL_OID_STRATEGY!r}"
            )
        raw_assignments = payload.get("assignments", {})
        if not isinstance(raw_assignments, dict):
            raise wb.WorldBuilderError(f"OID registry assignments in {path} must be an object")
        assignments: Dict[str, int] = {}
        for key, value in raw_assignments.items():
            try:
                oid = int(value)
            except (TypeError, ValueError) as exc:
                raise wb.WorldBuilderError(f"OID registry key {key!r} has invalid OID {value!r}") from exc
            assignments[str(key)] = oid
        return cls(assignments)

    def clone(self) -> "StructuralOIDRegistry":
        return StructuralOIDRegistry(self.assignments)

    def _validate_assignments(self) -> None:
        seen: Dict[int, str] = {}
        for key, oid in self.assignments.items():
            if not key or key.strip() != key:
                raise wb.WorldBuilderError(f"OID registry contains an invalid logical key: {key!r}")
            if not (wb.WB_STRUCTURAL_OID_MIN <= oid <= wb.WB_STRUCTURAL_OID_MAX):
                raise wb.WorldBuilderError(
                    f"OID registry key {key!r} uses 0x{oid:08X}, outside the reserved World Builder range"
                )
            prior = seen.get(oid)
            if prior is not None and prior != key:
                raise wb.WorldBuilderError(
                    f"OID registry collision: {key!r} and {prior!r} both map to 0x{oid:08X}"
                )
            seen[oid] = key

    def allocate(self, key: str) -> int:
        key = str(key)
        if key in self.assignments:
            oid = self.assignments[key]
            self.active_keys.add(key)
            return oid

        used = set(self.assignments.values())
        candidate = (min(used) - 1) if used else wb.WB_STRUCTURAL_OID_MAX
        while candidate in used and candidate >= wb.WB_STRUCTURAL_OID_MIN:
            candidate -= 1
        if candidate < wb.WB_STRUCTURAL_OID_MIN:
            raise wb.WorldBuilderError("Bellum Gero World Builder structural snapshot ID band exhausted")

        self.assignments[key] = candidate
        self.active_keys.add(key)
        return candidate

    def mark_active(self, keys: Iterable[str]) -> None:
        for key in keys:
            if key not in self.assignments:
                raise wb.WorldBuilderError(f"Cannot mark unknown OID registry key active: {key}")
            self.active_keys.add(key)

    def active_assignments(self) -> Dict[str, int]:
        return {key: self.assignments[key] for key in sorted(self.active_keys)}

    def retired_assignments(self) -> Dict[str, int]:
        return {
            key: oid
            for key, oid in sorted(self.assignments.items())
            if key not in self.active_keys
        }

    def to_payload(self) -> dict:
        used = list(self.assignments.values())
        next_oid = (min(used) - 1) if used else wb.WB_STRUCTURAL_OID_MAX
        return {
            "version": OID_REGISTRY_SCHEMA_VERSION,
            "strategy": wb.WB_STRUCTURAL_OID_STRATEGY,
            "reserved_min": wb.WB_STRUCTURAL_OID_MIN,
            "reserved_max": wb.WB_STRUCTURAL_OID_MAX,
            "reserved_min_hex": f"0x{wb.WB_STRUCTURAL_OID_MIN:08X}",
            "reserved_max_hex": f"0x{wb.WB_STRUCTURAL_OID_MAX:08X}",
            "next_unassigned_oid": next_oid,
            "assignments": {key: self.assignments[key] for key in sorted(self.assignments)},
            "active_keys": sorted(self.active_keys),
            "retired_keys": sorted(set(self.assignments) - self.active_keys),
        }


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------


def _now_iso() -> str:
    return _dt.datetime.now().isoformat(timespec="seconds")


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _load_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise wb.WorldBuilderError(f"{label.capitalize()} not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise wb.WorldBuilderError(f"Invalid JSON in {label} {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise wb.WorldBuilderError(f"{label.capitalize()} {path} must contain a JSON object")
    return value


def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False, dir=str(path.parent), prefix=path.name + ".tmp.") as handle:
        temp_path = Path(handle.name)
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    try:
        os.replace(temp_path, path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def _atomic_write_json(path: Path, payload: dict) -> None:
    _atomic_write_bytes(path, (json.dumps(payload, indent=2, sort_keys=False) + "\n").encode("utf-8"))


def _resolve_path(config_path: Path, value: Optional[str]) -> Optional[Path]:
    if not value:
        return None
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = config_path.parent / path
    return path.resolve()


def _config_required_path(config: dict, config_path: Path, key: str) -> Path:
    path = _resolve_path(config_path, config.get(key))
    if path is None:
        raise wb.WorldBuilderError(f"Batch World Builder config requires {key!r}")
    return path


def _config_list_paths(config: dict, config_path: Path, key: str) -> List[Path]:
    value = config.get(key, [])
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, list):
        raise wb.WorldBuilderError(f"Config key {key!r} must be a string or list of strings")
    result: List[Path] = []
    for item in value:
        if not isinstance(item, str):
            raise wb.WorldBuilderError(f"Config key {key!r} contains a non-string path")
        resolved = _resolve_path(config_path, item)
        if resolved is not None:
            result.append(resolved)
    return result


@dataclass
class EffectiveTreStack:
    config_lua: Path
    tre_dir: Path
    tre_names: List[str]
    tre_paths: List[Path]


class EffectiveTreResolver:
    """Resolve assets in the same lower-TRE priority order used by Core3.

    The generated bg_worldbuilder.tre is intentionally excluded. Canonical
    server TREs are searched first, followed by any explicitly configured
    supplemental TREs, with extracted reference roots used only as a final
    development fallback.
    """

    def __init__(
        self,
        tre_paths: Sequence[Path],
        asset_roots: Sequence[Path] = (),
        asset_tres: Sequence[Path] = (),
        preopened: Optional[Dict[Path, wb.TreArchive]] = None,
    ) -> None:
        self.tre_paths = [Path(path).resolve() for path in tre_paths]
        self.asset_roots = [Path(path).resolve() for path in asset_roots]
        self.asset_tres = []
        canonical = set(self.tre_paths)
        for path in asset_tres:
            resolved = Path(path).resolve()
            if resolved not in canonical and resolved not in self.asset_tres:
                self.asset_tres.append(resolved)

        self._tre_cache: Dict[Path, wb.TreArchive] = {}
        for path, archive in (preopened or {}).items():
            self._tre_cache[Path(path).resolve()] = archive

    def _open(self, path: Path) -> wb.TreArchive:
        resolved = path.resolve()
        if resolved not in self._tre_cache:
            self._tre_cache[resolved] = wb.open_tre(resolved)
        return self._tre_cache[resolved]

    def canonical_archives(self) -> Iterable[wb.TreArchive]:
        for path in self.tre_paths:
            yield self._open(path)

    def read(self, archive_path: str) -> bytes:
        key = wb.normalize_archive_path(archive_path)
        searched: List[str] = []

        for path in self.tre_paths:
            searched.append(str(path))
            archive = self._open(path)
            record = archive.record_by_name_optional(key)
            if record is not None:
                if wb.is_tre_tombstone(record):
                    raise wb.WorldBuilderError(
                        f"Required structural asset {archive_path!r} is masked/deleted "
                        f"by higher-priority TRE {path}"
                    )
                return archive.extract_record(record)

        for path in self.asset_tres:
            searched.append(str(path))
            archive = self._open(path)
            record = archive.record_by_name_optional(key)
            if record is not None:
                if wb.is_tre_tombstone(record):
                    raise wb.WorldBuilderError(
                        f"Required structural asset {archive_path!r} is masked/deleted "
                        f"by supplemental TRE {path}"
                    )
                return archive.extract_record(record)

        for root in self.asset_roots:
            searched.append(str(root))
            candidate = root / Path(key)
            if candidate.is_file():
                return candidate.read_bytes()

        raise wb.WorldBuilderError(
            f"Required structural asset {archive_path!r} was not found. Searched: "
            + ", ".join(searched)
        )


def _server_config_lua_path(config: dict, config_path: Path) -> Path:
    explicit = _resolve_path(config_path, config.get("server_config_lua"))
    if explicit is not None:
        if not explicit.is_file():
            raise wb.WorldBuilderError(f"Configured server_config_lua does not exist: {explicit}")
        return explicit

    candidates: List[Path] = []

    for parent in (config_path.parent, *config_path.parents):
        if parent.name == "MMOCoreORB":
            candidates.append(parent / "bin/conf/config.lua")
            break

    server_lua_value = config.get("server_template_lua_target")
    if server_lua_value:
        server_lua = _resolve_path(config_path, str(server_lua_value))
        if server_lua is not None:
            for parent in server_lua.parents:
                if parent.name == "MMOCoreORB":
                    candidate = parent / "bin/conf/config.lua"
                    if candidate not in candidates:
                        candidates.append(candidate)
                    break

    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()

    raise wb.WorldBuilderError(
        "Could not locate MMOCoreORB/bin/conf/config.lua for canonical TRE ordering. "
        "Keep worldbuilder_config.json in MMOCoreORB/tools/worldbuilder or set "
        "the optional 'server_config_lua' path explicitly."
    )


def _strip_lua_line_comments(text: str) -> str:
    """Remove -- comments without treating dashes inside quoted strings as comments."""
    output: List[str] = []
    for line in text.splitlines():
        quote: Optional[str] = None
        escaped = False
        kept: List[str] = []
        index = 0
        while index < len(line):
            char = line[index]
            if quote is not None:
                kept.append(char)
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                index += 1
                continue

            if char in ('"', "'"):
                quote = char
                kept.append(char)
                index += 1
                continue

            if char == "-" and index + 1 < len(line) and line[index + 1] == "-":
                break

            kept.append(char)
            index += 1

        output.append("".join(kept))
    return "\n".join(output)


def _read_server_tre_order(config_lua: Path) -> List[str]:
    try:
        text = config_lua.read_text(encoding="utf-8")
    except OSError as exc:
        raise wb.WorldBuilderError(f"Could not read server TRE config {config_lua}: {exc}") from exc

    clean = _strip_lua_line_comments(text)
    match = re.search(r"\bTreFiles\s*=\s*\{", clean)
    if match is None:
        raise wb.WorldBuilderError(f"Could not find TreFiles table in {config_lua}")

    start = match.end()
    depth = 1
    quote: Optional[str] = None
    escaped = False
    index = start
    while index < len(clean):
        char = clean[index]
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                break
        index += 1

    if depth != 0:
        raise wb.WorldBuilderError(f"TreFiles table in {config_lua} is not balanced")

    block = clean[start:index]
    names = re.findall(r"[\"']([^\"']+\.tre)[\"']", block, flags=re.IGNORECASE)
    if not names:
        raise wb.WorldBuilderError(f"TreFiles table in {config_lua} contains no TRE filenames")

    seen: Set[str] = set()
    duplicates: List[str] = []
    for name in names:
        key = name.lower()
        if key in seen:
            duplicates.append(name)
        seen.add(key)
    if duplicates:
        raise wb.WorldBuilderError(
            f"TreFiles table in {config_lua} contains duplicate TRE entries: "
            + ", ".join(duplicates)
        )

    return names


def _effective_tre_stack(
    config: dict,
    config_path: Path,
    source_tre: Path,
    output_name: str,
) -> EffectiveTreStack:
    config_lua = _server_config_lua_path(config, config_path)
    tre_names = _read_server_tre_order(config_lua)
    lower_names = [name.lower() for name in tre_names]

    output_key = output_name.lower()
    source_key = source_tre.name.lower()
    if output_key not in lower_names:
        raise wb.WorldBuilderError(
            f"{config_lua} does not list {output_name}. Add the World Builder overlay to TreFiles "
            "before publishing production content."
        )
    if source_key not in lower_names:
        raise wb.WorldBuilderError(
            f"{config_lua} does not list the configured base TRE {source_tre.name}."
        )

    output_index = lower_names.index(output_key)
    source_index = lower_names.index(source_key)
    if source_index <= output_index:
        raise wb.WorldBuilderError(
            f"{source_tre.name} must be lower priority than {output_name} in {config_lua}."
        )

    effective_names = tre_names[output_index + 1 :]
    tre_dir = _config_required_path(config, config_path, "server_tre_dir")
    paths: List[Path] = []
    missing: List[Path] = []

    source_resolved = source_tre.resolve()
    for name in effective_names:
        if name.lower() == source_key:
            path = source_resolved
        else:
            path = (tre_dir / name).resolve()
        paths.append(path)
        if not path.is_file():
            missing.append(path)

    if missing:
        preview = "\n".join(f"  {path}" for path in missing[:12])
        extra = "" if len(missing) <= 12 else f"\n  ... and {len(missing) - 12} more"
        raise wb.WorldBuilderError(
            "The canonical server TRE stack is incomplete. World Builder will not guess at a "
            "different source order. Missing:\n" + preview + extra
        )

    return EffectiveTreStack(
        config_lua=config_lua,
        tre_dir=tre_dir,
        tre_names=effective_names,
        tre_paths=paths,
    )


def _make_effective_resolver(
    config: dict,
    config_path: Path,
    source_tre: Path,
    output_name: str,
    source_archive: Optional[wb.TreArchive] = None,
) -> Tuple[EffectiveTreStack, EffectiveTreResolver]:
    stack = _effective_tre_stack(config, config_path, source_tre, output_name)
    preopened: Dict[Path, wb.TreArchive] = {}
    if source_archive is not None:
        preopened[source_tre.resolve()] = source_archive
    resolver = EffectiveTreResolver(
        stack.tre_paths,
        asset_roots=_config_list_paths(config, config_path, "asset_roots"),
        asset_tres=_config_list_paths(config, config_path, "asset_tres"),
        preopened=preopened,
    )
    return stack, resolver


def _infer_snapshot_types_from_effective_stack(
    resolver: EffectiveTreResolver,
) -> Dict[str, Tuple[float, int]]:
    inferred: Dict[str, Tuple[float, int]] = {}
    seen_snapshot_paths: Set[str] = set()

    for archive in resolver.canonical_archives():
        for record in archive.records:
            path = wb.normalize_archive_path(record.name)
            if not (path.startswith("snapshot/") and path.endswith(".ws")):
                continue
            if path in seen_snapshot_paths:
                continue
            seen_snapshot_paths.add(path)
            try:
                info = wb.parse_snapshot(archive.extract_record(record))
            except wb.WorldBuilderError:
                continue
            for node in info.nodes:
                if 0 <= node.name_id < len(info.names):
                    template = info.names[node.name_id]
                    inferred.setdefault(template, (node.game_object_type, node.unknown2))

    return inferred


def _canonical_publish_id(value: str) -> str:
    slug = wb.project_slug(value)
    if value != slug:
        raise wb.WorldBuilderError(
            f"Publish ID {value!r} is not canonical. Use lowercase letters/numbers/underscores only; "
            f"the canonical form would be {slug!r}."
        )
    return slug


def _project_oid_prefix(publish_id: str) -> str:
    return publish_id + "/"


def _all_result_oids(result: wb.StructuralBakeResult) -> Set[int]:
    values = set(result.id_map.values())
    for structure in result.structures:
        values.update(structure.cell_object_ids)
    return values


def _result_oid_assignments(registry: StructuralOIDRegistry, publish_id: str) -> Dict[str, int]:
    prefix = _project_oid_prefix(publish_id)
    return {
        key: registry.assignments[key]
        for key in sorted(registry.active_keys)
        if key.startswith(prefix)
    }


def _snapshot_node_signature(node: wb.SnapshotTreeNode) -> tuple:
    info = node.info
    return (
        info.object_id,
        info.parent_id,
        info.name_id,
        info.cell_id,
        info.qw,
        info.qx,
        info.qy,
        info.qz,
        info.x,
        info.z,
        info.y,
        info.game_object_type,
        info.unknown2,
        tuple(child.info.object_id for child in node.children),
    )


# ---------------------------------------------------------------------------
# Publish-set and deployed-state loading
# ---------------------------------------------------------------------------


def load_publish_set(path: Path) -> List[ApprovedProject]:
    payload = _load_json(path, "publish set")
    if payload.get("version") != PUBLISH_SET_SCHEMA_VERSION:
        raise wb.WorldBuilderError(
            f"Unsupported publish-set version in {path}: {payload.get('version')!r}"
        )
    rows = payload.get("projects", [])
    if not isinstance(rows, list):
        raise wb.WorldBuilderError(f"Publish set {path} projects must be an array")

    approved: List[ApprovedProject] = []
    seen_ids: Set[str] = set()
    seen_files: Set[Path] = set()

    for index, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            raise wb.WorldBuilderError(f"Publish set entry #{index} must be an object")
        if row.get("enabled", True) is False:
            continue

        raw_id = row.get("id")
        raw_file = row.get("file")
        if not isinstance(raw_id, str) or not raw_id:
            raise wb.WorldBuilderError(f"Publish set entry #{index} has no valid 'id'")
        if not isinstance(raw_file, str) or not raw_file:
            raise wb.WorldBuilderError(f"Publish set entry {raw_id!r} has no valid 'file'")
        publish_id = _canonical_publish_id(raw_id)
        if publish_id in seen_ids:
            raise wb.WorldBuilderError(f"Duplicate enabled World Builder publish ID: {publish_id}")

        source = Path(raw_file).expanduser()
        if not source.is_absolute():
            source = path.parent / source
        source = source.resolve()
        if source in seen_files:
            raise wb.WorldBuilderError(f"The same WBP file is enabled more than once: {source}")

        project = wb.read_project(source)
        if project.version == wb.WBP_VERSION:
            bad_parents = [obj.local_id for obj in project.objects if obj.parent_id != 0]
            if bad_parents:
                raise wb.WorldBuilderError(
                    f"Batch publishing supports WBP V1 static world objects only. {source} contains "
                    f"cell-parented OBJECT records {bad_parents}; preserve the existing Lua-export workflow for those records."
                )
        elif project.version < wb.WBP_STRUCTURAL_VERSION:
            raise wb.WorldBuilderError(f"Unsupported WBP version for batch publishing: {project.version}")

        approved.append(
            ApprovedProject(
                publish_id=publish_id,
                source_path=source,
                project=project,
                wbp_sha256=_sha256_file(source),
            )
        )
        seen_ids.add(publish_id)
        seen_files.add(source)

    approved.sort(key=lambda item: item.publish_id)
    return approved


def load_deployed_state(path: Path) -> dict:
    if not path.exists():
        return {
            "version": DEPLOYED_STATE_SCHEMA_VERSION,
            "projects": [],
        }
    payload = _load_json(path, "deployed state")
    if payload.get("version") != DEPLOYED_STATE_SCHEMA_VERSION:
        raise wb.WorldBuilderError(
            f"Unsupported deployed-state version in {path}: {payload.get('version')!r}"
        )
    if not isinstance(payload.get("projects", []), list):
        raise wb.WorldBuilderError(f"Deployed state {path} projects must be an array")
    return payload


# ---------------------------------------------------------------------------
# Base/candidate safety validation
# ---------------------------------------------------------------------------


def validate_clean_structural_base(archive: wb.TreArchive) -> None:
    wb.validate_tre_v5_metadata(archive, require_md5=False)

    bad_paths = [
        rec.name
        for rec in archive.records
        if any(wb.normalize_archive_path(rec.name).startswith(prefix) for prefix in WB_ARCHIVE_PREFIXES)
    ]
    if bad_paths:
        preview = ", ".join(sorted(bad_paths)[:5])
        raise wb.WorldBuilderError(
            "Configured batch base TRE already contains World Builder structural archive paths. "
            f"First match(es): {preview}. Use the canonical non-World-Builder Bellum Gero base TRE."
        )

    collisions: List[Tuple[str, int]] = []
    for rec in archive.records:
        name = wb.normalize_archive_path(rec.name)
        if not (name.startswith("snapshot/") and name.endswith(".ws")):
            continue
        tree = wb.parse_snapshot_tree(archive.extract_record(rec))
        for node in tree.flatten():
            oid = node.info.object_id
            if wb.WB_STRUCTURAL_OID_MIN <= oid <= wb.WB_STRUCTURAL_OID_MAX:
                collisions.append((name, oid))

    if collisions:
        first_path, first_oid = sorted(collisions)[0]
        raise wb.WorldBuilderError(
            "Configured batch base TRE is not clean: a snapshot already uses the World Builder reserved "
            f"OID band. First collision: {first_path} -> 0x{first_oid:08X}."
        )



def write_overlay_tre_v5(files: Dict[str, bytes], output_path: Path, names_compression: int = 2) -> None:
    """Write a minimal TRE-v5 containing exactly the supplied archive files."""
    normalized: Dict[str, bytes] = {}
    for raw_name, data in files.items():
        name = wb.normalize_archive_path(raw_name)
        prior = normalized.get(name)
        if prior is not None and prior != data:
            raise wb.WorldBuilderError(f"Conflicting overlay data supplied for {name}")
        normalized[name] = data

    ordered_names = sorted(normalized, key=lambda name: (wb.soe_tre_crc(name), name))
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile(
        delete=False,
        dir=str(output_path.parent),
        prefix=output_path.name + ".tmp.",
    ) as temp:
        temp_path = Path(temp.name)
        temp.write(b"\0" * wb.TRE_HEADER_SIZE)
        records: List[wb.TreRecord] = []
        payload_md5: List[bytes] = []

        for name in ordered_names:
            raw = normalized[name]
            compressed = zlib.compress(raw, 9)
            data_offset = temp.tell()
            temp.write(compressed)
            payload_md5.append(hashlib.md5(compressed).digest())
            records.append(
                wb.TreRecord(
                    hash_or_crc=wb.soe_tre_crc(name),
                    uncompressed_size=len(raw),
                    data_offset=data_offset,
                    compression=2,
                    compressed_size=len(compressed),
                    name_offset=0,
                    name=name,
                )
            )

        names_blob = bytearray()
        for rec in records:
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
            for rec in records
        )
        info_c = zlib.compress(info, 9)

        if names_compression == 0:
            names_c = bytes(names_blob)
        elif names_compression == 2:
            names_c = zlib.compress(bytes(names_blob), 9)
        else:
            raise wb.WorldBuilderError(
                f"Unsupported TRE names compression for overlay output: {names_compression}"
            )

        temp.write(info_c)
        temp.write(names_c)
        for digest in payload_md5:
            temp.write(digest)

        header = wb.MAGIC + struct.pack(
            "<7I",
            len(records),
            metadata_offset,
            2,
            len(info_c),
            names_compression,
            len(names_c),
            len(names_blob),
        )
        temp.seek(0)
        temp.write(header)

    try:
        reopened = wb.open_tre(temp_path)
        wb.validate_tre_v5_metadata(reopened, require_md5=True)
        actual_names = sorted(wb.normalize_archive_path(rec.name) for rec in reopened.records)
        if actual_names != sorted(normalized):
            raise wb.WorldBuilderError("Overlay TRE path set changed during write")
        for name, expected in normalized.items():
            if reopened.extract(name) != expected:
                raise wb.WorldBuilderError(f"Overlay TRE post-build validation failed for {name}")
        os.replace(temp_path, output_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def validate_overlay_snapshot_preservation(
    finished: wb.TreArchive,
    original_snapshots: Dict[str, bytes],
) -> None:
    """Ensure patched overlay snapshots preserve every pre-existing source node."""
    for snapshot_path, original_raw in original_snapshots.items():
        original_tree = wb.parse_snapshot_tree(original_raw)
        final_tree = wb.parse_snapshot_tree(finished.extract(snapshot_path))
        final_by_id = {node.info.object_id: node for node in final_tree.flatten()}

        for node in original_tree.flatten():
            final_node = final_by_id.get(node.info.object_id)
            if final_node is None:
                raise wb.WorldBuilderError(
                    f"Overlay {snapshot_path} lost pre-existing snapshot OID {node.info.object_id}"
                )
            if _snapshot_node_signature(final_node) != _snapshot_node_signature(node):
                raise wb.WorldBuilderError(
                    f"Overlay {snapshot_path} modified pre-existing snapshot OID {node.info.object_id}"
                )


def _collect_dependency_records(
    resolver: wb.AssetResolver,
    original_snapshots: Dict[str, bytes],
    results: Sequence[BatchProjectResult],
) -> dict:
    records: Dict[str, dict] = {}

    def add(path: str, data: bytes, kind: str) -> None:
        normalized = wb.normalize_archive_path(path)
        digest = _sha256_bytes(data)
        existing = records.get(normalized)
        if existing is None:
            records[normalized] = {
                "sha256": digest,
                "kinds": [kind],
            }
            return
        if existing["sha256"] != digest:
            raise wb.WorldBuilderError(
                f"Dependency {normalized} resolved to conflicting data during one batch build"
            )
        if kind not in existing["kinds"]:
            existing["kinds"].append(kind)
            existing["kinds"].sort()

    for path, data in sorted(original_snapshots.items()):
        add(path, data, "snapshot")

    for result in results:
        for structure in result.bake_result.structures:
            dependencies = (
                ("shared_building_iff", structure.source_shared_template),
                ("portal_layout", structure.source_portal_layout),
                ("interior_layout", structure.source_interior_layout),
            )
            for kind, path in dependencies:
                if not path or path == "<empty>":
                    continue
                add(path, resolver.read(path), kind)

    return {
        "records": {path: records[path] for path in sorted(records)},
    }

def validate_global_reserved_oids(
    archive: wb.TreArchive,
    expected_active: Dict[str, int],
) -> None:
    found: Dict[int, str] = {}
    for rec in archive.records:
        name = wb.normalize_archive_path(rec.name)
        if not (name.startswith("snapshot/") and name.endswith(".ws")):
            continue
        tree = wb.parse_snapshot_tree(archive.extract_record(rec))
        for node in tree.flatten():
            oid = node.info.object_id
            if not (wb.WB_STRUCTURAL_OID_MIN <= oid <= wb.WB_STRUCTURAL_OID_MAX):
                continue
            if oid in found:
                raise wb.WorldBuilderError(
                    f"Candidate contains duplicate reserved OID 0x{oid:08X} in {found[oid]} and {name}"
                )
            found[oid] = name

    expected_values = set(expected_active.values())
    found_values = set(found)
    if found_values != expected_values:
        missing = sorted(expected_values - found_values)
        unexpected = sorted(found_values - expected_values)
        detail = []
        if missing:
            detail.append("missing=" + ",".join(f"0x{x:08X}" for x in missing[:8]))
        if unexpected:
            detail.append("unexpected=" + ",".join(f"0x{x:08X}" for x in unexpected[:8]))
        raise wb.WorldBuilderError(
            "Candidate reserved OID set does not match the active registry (" + "; ".join(detail) + ")"
        )


def validate_project_assets(
    finished: wb.TreArchive,
    resolver: wb.AssetResolver,
    result: BatchProjectResult,
) -> None:
    for structure in result.bake_result.structures:
        root_template = structure.custom_shared_template
        custom_iff = finished.extract(root_template)
        if wb.normalize_archive_path(wb.read_string_param(custom_iff, "interiorLayoutFileName")) != wb.normalize_archive_path(structure.custom_interior_layout):
            raise wb.WorldBuilderError(
                f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} shared IFF does not point at its custom ILF"
            )
        if wb.normalize_archive_path(wb.read_string_param(custom_iff, "portalLayoutFilename")) != wb.normalize_archive_path(structure.source_portal_layout):
            raise wb.WorldBuilderError(
                f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} portal layout changed"
            )

        final_nodes = wb.parse_ilf(finished.extract(structure.custom_interior_layout), structure.custom_interior_layout)
        source_count = 0
        if structure.source_interior_layout != "<empty>":
            try:
                source_count = len(wb.parse_ilf(resolver.read(structure.source_interior_layout), structure.source_interior_layout))
            except wb.WorldBuilderError:
                source_count = 0
        expected_count = source_count + len(structure.interior_local_ids)
        if len(final_nodes) != expected_count:
            raise wb.WorldBuilderError(
                f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} ILF node count mismatch: "
                f"{len(final_nodes)} != {expected_count}"
            )


def validate_project_snapshot_roots(
    finished: wb.TreArchive,
    result: BatchProjectResult,
) -> None:
    snapshot_path = f"snapshot/{result.approved.project.planet}.ws"
    tree = wb.parse_snapshot_tree(finished.extract(snapshot_path))
    by_id = {node.info.object_id: node for node in tree.flatten()}
    for structure in result.bake_result.structures:
        root = by_id.get(structure.root_object_id)
        if root is None:
            raise wb.WorldBuilderError(
                f"Candidate lost {result.approved.publish_id} STRUCTURE #{structure.local_id} root"
            )
        if not (0 <= root.info.name_id < len(tree.base.names)):
            raise wb.WorldBuilderError(
                f"Candidate {result.approved.publish_id} STRUCTURE #{structure.local_id} has invalid OTNL name ID"
            )
        actual_template = wb.normalize_archive_path(tree.base.names[root.info.name_id])
        if actual_template != wb.normalize_archive_path(structure.custom_shared_template):
            raise wb.WorldBuilderError(
                f"Candidate {result.approved.publish_id} STRUCTURE #{structure.local_id} OTNL template mismatch"
            )
        if len(root.children) != structure.cell_count:
            raise wb.WorldBuilderError(
                f"Candidate {result.approved.publish_id} STRUCTURE #{structure.local_id} cell hierarchy mismatch"
            )


# ---------------------------------------------------------------------------
# Candidate metadata
# ---------------------------------------------------------------------------


def _project_fingerprint(result: BatchProjectResult) -> str:
    project = result.approved.project
    payload = {
        "publish_id": result.approved.publish_id,
        "planet": project.planet,
        "objects": [dataclasses.asdict(value) for value in sorted(project.objects, key=lambda x: x.local_id)],
        "structures_source": [dataclasses.asdict(value) for value in sorted(project.structures, key=lambda x: x.local_id)],
        "interiors": [dataclasses.asdict(value) for value in sorted(project.interiors, key=lambda x: x.local_id)],
        "oid_assignments": result.oid_assignments,
        "published_structures": [dataclasses.asdict(value) for value in result.bake_result.structures],
        "asset_sha256": {
            wb.normalize_archive_path(path): _sha256_bytes(data)
            for path, data in sorted(result.asset_replacements.items())
        },
    }
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return _sha256_bytes(canonical)


def _project_manifest_entry(result: BatchProjectResult) -> dict:
    project = result.approved.project
    return {
        "id": result.approved.publish_id,
        "project_name": project.name,
        "source_wbp": str(result.approved.source_path),
        "wbp_sha256": result.approved.wbp_sha256,
        "publish_fingerprint": result.fingerprint,
        "planet": project.planet,
        "wbp_version": project.version,
        "counts": {
            "objects": len(project.objects),
            "structures": len(project.structures),
            "interiors": len(project.interiors),
        },
        "world_snapshot_ids": {str(k): v for k, v in sorted(result.bake_result.id_map.items())},
        "oid_assignments": result.oid_assignments,
        "archive_paths": sorted(wb.normalize_archive_path(path) for path in result.asset_replacements),
        "structures": [dataclasses.asdict(value) for value in result.bake_result.structures],
        "safe_refresh": {
            "dry_run_command": f"/wb refreshpublished {result.approved.publish_id}",
            "confirm_command": f"/wb refreshpublished {result.approved.publish_id} confirm",
        },
    }


def _diff_projects(current: Sequence[dict], previous_state: dict) -> dict:
    current_by_id = {entry["id"]: entry for entry in current}
    previous_by_id = {entry["id"]: entry for entry in previous_state.get("projects", [])}

    added: List[str] = []
    updated: List[str] = []
    removed: List[str] = []
    unchanged: List[str] = []
    refresh_required: List[dict] = []

    for publish_id in sorted(current_by_id):
        current_entry = current_by_id[publish_id]
        previous = previous_by_id.get(publish_id)
        if previous is None:
            added.append(publish_id)
            continue
        if previous.get("publish_fingerprint") == current_entry.get("publish_fingerprint"):
            unchanged.append(publish_id)
            continue
        updated.append(publish_id)
        # refreshpublished exists to clear persistent BuildingObject/CellObject
        # records. Pure WBP V1/static projects retain their legacy no-refresh
        # behavior even when included in the desired-state batch.
        previous_structures = int(previous.get("counts", {}).get("structures", len(previous.get("structures", []))))
        if previous_structures > 0:
            old_planet = previous.get("planet") or current_entry.get("planet")
            refresh_required.append(
                {
                    "id": publish_id,
                    "reason": "updated",
                    "planet": old_planet,
                    "dry_run_command": f"/wb refreshpublished {publish_id}",
                    "confirm_command": f"/wb refreshpublished {publish_id} confirm",
                }
            )

    for publish_id in sorted(set(previous_by_id) - set(current_by_id)):
        previous = previous_by_id[publish_id]
        removed.append(publish_id)
        previous_structures = int(previous.get("counts", {}).get("structures", len(previous.get("structures", []))))
        if previous_structures > 0:
            refresh_required.append(
                {
                    "id": publish_id,
                    "reason": "removed",
                    "planet": previous.get("planet", "<unknown>"),
                    "dry_run_command": f"/wb refreshpublished {publish_id}",
                    "confirm_command": f"/wb refreshpublished {publish_id} confirm",
                }
            )

    return {
        "added": added,
        "updated": updated,
        "removed": removed,
        "unchanged": unchanged,
        "refresh_required": refresh_required,
    }


def _combined_server_lua(results: Sequence[BatchProjectResult]) -> str:
    lines = [
        "-- AUTO-GENERATED by Bellum Gero World Builder Batch Structural Publisher",
        "-- This file contains every approved structural World Builder project in the matching TRE.",
        "-- Regenerate from the publish set; do not hand-edit generated registrations.",
        "-- Deploy this exact file together with the candidate TRE.",
        "",
    ]
    if not results:
        lines.append("-- No structural World Builder projects are currently approved.")
        lines.append("")
        return "\n".join(lines)

    structural_results = [result for result in results if result.bake_result.structures]
    if not structural_results:
        lines.append("-- Approved batch projects currently require no structural server-template registrations.")
        lines.append("")
        return "\n".join(lines)

    for result in sorted(structural_results, key=lambda item: item.approved.publish_id):
        lines += [
            "-- ========================================================================",
            f"-- BEGIN WORLD BUILDER PROJECT: {result.approved.publish_id}",
            f"-- Source project name: {result.approved.project.name} | Planet: {result.approved.project.planet}",
            "-- ========================================================================",
            "",
        ]
        project_lines = result.bake_result.server_lua.splitlines()
        start = 0
        for index, line in enumerate(project_lines):
            if line.startswith("-- WB STRUCTURE #"):
                start = index
                break
        lines.extend(project_lines[start:])
        lines += [
            "",
            f"-- END WORLD BUILDER PROJECT: {result.approved.publish_id}",
            "",
        ]
    return "\n".join(lines).rstrip() + "\n"


# ---------------------------------------------------------------------------
# Batch bake
# ---------------------------------------------------------------------------


def build_candidate(config_path: Path, default_game_type: Optional[float] = None) -> dict:
    config_path = config_path.resolve()
    config = wb.load_config(config_path)

    source_tre = _config_required_path(config, config_path, "base_tre")
    publish_set_path = _config_required_path(config, config_path, "publish_set")
    oid_registry_path = _config_required_path(config, config_path, "oid_registry")
    deployed_state_path = _config_required_path(config, config_path, "deployed_state")
    candidate_dir = _config_required_path(config, config_path, "candidate_dir")
    output_name = str(config.get("output_tre_name") or CANDIDATE_TRE_NAME_FALLBACK)
    if Path(output_name).name != output_name:
        raise wb.WorldBuilderError("output_tre_name must be a filename, not a path")
    if output_name.lower() == source_tre.name.lower():
        raise wb.WorldBuilderError(
            "Dedicated World Builder overlay output must use a different filename than base_tre"
        )

    candidate_tre = candidate_dir / output_name
    candidate_lua = candidate_dir / CANDIDATE_LUA_NAME
    candidate_manifest = candidate_dir / CANDIDATE_MANIFEST_NAME
    candidate_id_map = candidate_dir / CANDIDATE_ID_MAP_NAME
    candidate_registry = candidate_dir / CANDIDATE_REGISTRY_NAME

    if not source_tre.exists():
        raise wb.WorldBuilderError(f"Normal Bellum Gero source TRE not found: {source_tre}")
    if candidate_tre.resolve() == source_tre.resolve():
        raise wb.WorldBuilderError("Refusing to bake the World Builder overlay over bg_custom1.tre")

    approved = load_publish_set(publish_set_path)
    previous_state = load_deployed_state(deployed_state_path)
    if previous_state.get("projects") and previous_state.get("mode") not in (
        None,
        "desired-state-multi-project-worldbuilder-overlay-v2",
    ):
        raise wb.WorldBuilderError(
            "The deployed-state file describes the older combined-bg_custom1 publishing mode. "
            "Migrate/clear that state before using the dedicated World Builder TRE publisher."
        )

    active_registry = StructuralOIDRegistry.load(oid_registry_path, deployed_state_path)
    registry = active_registry.clone()

    source_archive = wb.open_tre(source_tre)
    validate_clean_structural_base(source_archive)

    source_stack, resolver = _make_effective_resolver(
        config,
        config_path,
        source_tre,
        output_name,
        source_archive=source_archive,
    )
    inferred_types = (
        _infer_snapshot_types_from_effective_stack(resolver)
        if approved
        else {}
    )

    projects_by_planet: Dict[str, List[ApprovedProject]] = {}
    for entry in approved:
        projects_by_planet.setdefault(entry.project.planet, []).append(entry)

    overlay_files: Dict[str, bytes] = {}
    original_snapshots: Dict[str, bytes] = {}
    results: List[BatchProjectResult] = []

    for planet in sorted(projects_by_planet):
        snapshot_path = f"snapshot/{planet}.ws"
        snapshot_raw = resolver.read(snapshot_path)

        original_snapshots[snapshot_path] = snapshot_raw
        allowed_reserved: Set[int] = set()

        for approved_project in sorted(projects_by_planet[planet], key=lambda item: item.publish_id):
            baked_snapshot, project_assets, bake_result = wb.bake_snapshot_v2(
                snapshot_raw,
                approved_project.project,
                resolver,
                inferred_types,
                default_game_type,
                publish_id=approved_project.publish_id,
                oid_allocator=registry.allocate,
                allowed_reserved_oids=allowed_reserved,
            )

            for path, data in project_assets.items():
                normalized = wb.normalize_archive_path(path)
                prior = overlay_files.get(normalized)
                if prior is not None and prior != data:
                    raise wb.WorldBuilderError(
                        f"Two approved World Builder projects generated conflicting archive path {normalized}"
                    )
                overlay_files[normalized] = data

            result = BatchProjectResult(
                approved=approved_project,
                bake_result=bake_result,
                asset_replacements={
                    wb.normalize_archive_path(k): v
                    for k, v in project_assets.items()
                },
                oid_assignments=_result_oid_assignments(
                    registry, approved_project.publish_id
                ),
            )
            result.fingerprint = _project_fingerprint(result)
            results.append(result)

            allowed_reserved.update(_all_result_oids(bake_result))
            snapshot_raw = baked_snapshot

        overlay_files[snapshot_path] = snapshot_raw

    current_prefixes = tuple(_project_oid_prefix(entry.publish_id) for entry in approved)
    stray_active = [
        key
        for key in registry.active_keys
        if not current_prefixes or not key.startswith(current_prefixes)
    ]
    if stray_active:
        raise wb.WorldBuilderError(
            "Internal OID registry active-key mismatch: " + ", ".join(stray_active[:5])
        )

    candidate_dir.mkdir(parents=True, exist_ok=True)

    write_overlay_tre_v5(
        overlay_files,
        candidate_tre,
        names_compression=source_archive.names_compression,
    )

    finished = wb.open_tre(candidate_tre)
    wb.validate_tre_v5_metadata(finished, require_md5=True)

    final_paths = sorted(
        wb.normalize_archive_path(rec.name)
        for rec in finished.records
    )
    expected_paths = sorted(overlay_files)
    if final_paths != expected_paths:
        raise wb.WorldBuilderError(
            "Dedicated World Builder TRE contains paths outside the generated overlay set"
        )

    validate_overlay_snapshot_preservation(finished, original_snapshots)
    validate_global_reserved_oids(finished, registry.active_assignments())

    for result in results:
        validate_project_snapshot_roots(finished, result)
        validate_project_assets(finished, resolver, result)

    expected_wb_paths = sorted(
        path
        for path in overlay_files
        if any(path.startswith(prefix) for prefix in WB_ARCHIVE_PREFIXES)
    )
    final_wb_paths = sorted(
        path
        for path in final_paths
        if any(path.startswith(prefix) for prefix in WB_ARCHIVE_PREFIXES)
    )
    if final_wb_paths != expected_wb_paths:
        raise wb.WorldBuilderError(
            "Candidate World Builder archive namespace does not exactly match the approved project set"
        )

    dependencies = _collect_dependency_records(
        resolver,
        original_snapshots,
        results,
    )

    combined_lua = _combined_server_lua(results)
    _atomic_write_bytes(candidate_lua, combined_lua.encode("utf-8"))

    registry_payload = registry.to_payload()
    _atomic_write_json(candidate_registry, registry_payload)

    project_entries = [
        _project_manifest_entry(result)
        for result in sorted(results, key=lambda item: item.approved.publish_id)
    ]
    changes = _diff_projects(project_entries, previous_state)

    id_map_payload = {
        "version": BATCH_SCHEMA_VERSION,
        "generated": _now_iso(),
        "snapshot_id_policy": {
            "strategy": wb.WB_STRUCTURAL_OID_STRATEGY,
            "reserved_min": wb.WB_STRUCTURAL_OID_MIN,
            "reserved_max": wb.WB_STRUCTURAL_OID_MAX,
            "stable_logical_registry": True,
            "retired_ids_reassigned_to_other_keys": False,
        },
        "projects": {
            entry["id"]: {
                "planet": entry["planet"],
                "world_snapshot_ids": entry["world_snapshot_ids"],
                "oid_assignments": entry["oid_assignments"],
            }
            for entry in project_entries
        },
    }
    _atomic_write_json(candidate_id_map, id_map_payload)

    manifest_payload = {
        "version": BATCH_SCHEMA_VERSION,
        "generated": _now_iso(),
        "mode": "desired-state-multi-project-worldbuilder-overlay-v2",
        "base_tre": str(source_tre),
        "base_tre_sha256": _sha256_file(source_tre),
        "source_role": "normal-bellum-gero-custom-tre",
        "output_role": "dedicated-worldbuilder-overlay",
        "effective_source_stack": {
            "server_config_lua": str(source_stack.config_lua),
            "tre_dir": str(source_stack.tre_dir),
            "tre_files": source_stack.tre_names,
        },
        "publish_set": str(publish_set_path),
        "active_oid_registry": str(oid_registry_path),
        "active_deployed_state": str(deployed_state_path),
        "candidate_dir": str(candidate_dir),
        "artifacts": {
            "tre": candidate_tre.name,
            "server_template_lua": candidate_lua.name,
            "oid_registry": candidate_registry.name,
            "id_map": candidate_id_map.name,
        },
        "hashes": {
            "tre_sha256": _sha256_file(candidate_tre),
            "server_template_lua_sha256": _sha256_file(candidate_lua),
            "oid_registry_sha256": _sha256_file(candidate_registry),
            "id_map_sha256": _sha256_file(candidate_id_map),
        },
        "dependencies": dependencies,
        "snapshot_id_policy": {
            "strategy": wb.WB_STRUCTURAL_OID_STRATEGY,
            "reserved_min": wb.WB_STRUCTURAL_OID_MIN,
            "reserved_max": wb.WB_STRUCTURAL_OID_MAX,
            "stable_logical_registry": True,
            "historical_assignments_retained": True,
            "retired_oids_are_never_assigned_to_another_logical_key": True,
        },
        "registry_counts": {
            "active": len(registry.active_keys),
            "retired": len(registry.assignments) - len(registry.active_keys),
            "historical_total": len(registry.assignments),
        },
        "projects": project_entries,
        "changes_from_last_deploy": changes,
        "overlay_archive_paths": final_paths,
        "worldbuilder_archive_paths": final_wb_paths,
        "validation": {
            "source_tre_no_worldbuilder_namespace": True,
            "source_tre_reserved_oid_band_unused": True,
            "canonical_server_tre_order_used": True,
            "generated_overlay_excluded_from_source_stack": True,
            "tre_v5_checksum_ordering": True,
            "tre_v5_stored_payload_md5": True,
            "overlay_contains_only_generated_paths": True,
            "preexisting_nodes_preserved_in_affected_snapshots": True,
            "global_reserved_oid_set_matches_registry": True,
            "worldbuilder_namespace_matches_approved_set": True,
            "project_structure_roots_cells_assets": True,
            "dependency_hashes_recorded": True,
        },
    }
    _atomic_write_json(candidate_manifest, manifest_payload)
    return manifest_payload

# ---------------------------------------------------------------------------
# Transactional deployment
# ---------------------------------------------------------------------------


def _destination_paths(config: dict, config_path: Path, output_name: str) -> Tuple[Path, Path, Path, Path, Path]:
    client_dir = _config_required_path(config, config_path, "client_tre_dir")
    server_dir = _config_required_path(config, config_path, "server_tre_dir")
    server_lua = _config_required_path(config, config_path, "server_template_lua_target")
    registry = _config_required_path(config, config_path, "oid_registry")
    state = _config_required_path(config, config_path, "deployed_state")
    return client_dir / output_name, server_dir / output_name, server_lua, registry, state


def _prepare_deployed_state(manifest: dict) -> dict:
    return {
        "version": DEPLOYED_STATE_SCHEMA_VERSION,
        "deployed": _now_iso(),
        "mode": manifest.get("mode"),
        "base_tre_sha256": manifest.get("base_tre_sha256"),
        "dependencies": manifest.get("dependencies", {"records": {}}),
        "tre_sha256": manifest["hashes"]["tre_sha256"],
        "server_template_lua_sha256": manifest["hashes"]["server_template_lua_sha256"],
        "oid_registry_sha256": manifest["hashes"]["oid_registry_sha256"],
        "projects": manifest.get("projects", []),
    }



def _dependency_comparison(config_path: Path, config: dict, expected: dict) -> dict:
    records = expected.get("records", {}) if isinstance(expected, dict) else {}
    if not isinstance(records, dict):
        raise wb.WorldBuilderError("World Builder dependency records are malformed")

    if not records:
        return {"stale": False, "checked": 0, "changed": []}

    source_tre = _config_required_path(config, config_path, "base_tre")
    if not source_tre.is_file():
        return {
            "stale": True,
            "checked": 0,
            "changed": [
                {
                    "path": str(source_tre),
                    "reason": "normal Bellum Gero source TRE is missing",
                }
            ],
        }

    source_archive = wb.open_tre(source_tre)
    validate_clean_structural_base(source_archive)
    output_name = str(config.get("output_tre_name") or CANDIDATE_TRE_NAME_FALLBACK)
    _, resolver = _make_effective_resolver(
        config,
        config_path,
        source_tre,
        output_name,
        source_archive=source_archive,
    )

    changed: List[dict] = []
    checked = 0

    for path, meta in sorted(records.items()):
        checked += 1
        expected_sha = meta.get("sha256") if isinstance(meta, dict) else None
        try:
            current = resolver.read(path)
        except Exception as exc:
            changed.append(
                {
                    "path": path,
                    "reason": f"dependency can no longer be resolved: {exc}",
                }
            )
            continue

        current_sha = _sha256_bytes(current)
        if not expected_sha or current_sha != expected_sha:
            changed.append(
                {
                    "path": path,
                    "reason": "source record changed",
                    "expected_sha256": expected_sha,
                    "current_sha256": current_sha,
                }
            )

    return {
        "stale": bool(changed),
        "checked": checked,
        "changed": changed,
    }


def dependency_status(config_path: Path) -> dict:
    config_path = config_path.resolve()
    config = wb.load_config(config_path)
    state_path = _config_required_path(config, config_path, "deployed_state")
    state = load_deployed_state(state_path)
    return _dependency_comparison(
        config_path,
        config,
        state.get("dependencies", {}),
    )


def _verify_manifest_dependencies_current(
    config_path: Path,
    config: dict,
    manifest: dict,
) -> None:
    status = _dependency_comparison(
        config_path,
        config,
        manifest.get("dependencies", {}),
    )
    if not status["stale"]:
        return

    lines = [
        "The validated bg_worldbuilder.tre candidate is stale because one or more "
        "source records changed after it was baked."
    ]
    for item in status["changed"]:
        lines.append(f"  {item['path']}: {item['reason']}")
    lines.append("Run 'wb bake' again before deployment.")
    raise wb.WorldBuilderError("\n".join(lines))

def _verify_previous_deployment_not_drifted(
    state_path: Path,
    client_tre: Path,
    server_tre: Path,
    server_lua: Path,
) -> None:
    if not state_path.exists():
        return
    state = load_deployed_state(state_path)
    expected_tre = state.get("tre_sha256")
    expected_lua = state.get("server_template_lua_sha256")
    if expected_tre:
        for label, path in (("client TRE", client_tre), ("server TRE", server_tre)):
            if not path.exists():
                raise wb.WorldBuilderError(f"Previously deployed {label} is missing: {path}")
            actual = _sha256_file(path)
            if actual != expected_tre:
                raise wb.WorldBuilderError(
                    f"Previously deployed {label} has drifted from worldbuilder_deployed_state.json: {path}. "
                    "Resolve the mismatch before deploying another batch."
                )
    if expected_lua:
        if not server_lua.exists() or _sha256_file(server_lua) != expected_lua:
            raise wb.WorldBuilderError(
                "Active generated_templates.lua has drifted from worldbuilder_deployed_state.json. "
                "Resolve the mismatch before deploying another batch."
            )


def _transactional_promote(items: Sequence[Tuple[bytes, Path]], stamp: str) -> List[Tuple[Path, Optional[Path]]]:
    staged: List[Tuple[Path, Path]] = []
    backups: Dict[Path, Optional[Path]] = {}
    promoted: List[Path] = []

    try:
        # Stage every destination first. Nothing active changes until all copies
        # are present and checksum-verified beside their destination.
        for data, destination in items:
            destination.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(delete=False, dir=str(destination.parent), prefix=destination.name + ".candidate.") as handle:
                temp_path = Path(handle.name)
                handle.write(data)
                handle.flush()
                os.fsync(handle.fileno())
            if _sha256_file(temp_path) != _sha256_bytes(data):
                temp_path.unlink(missing_ok=True)
                raise wb.WorldBuilderError(f"Staged deployment checksum mismatch for {destination}")
            staged.append((temp_path, destination))

        for _, destination in staged:
            backup: Optional[Path] = None
            if destination.exists():
                backup_root = (
                    Path.home()
                    / "worldbuilder_deploy_backups"
                    / stamp
                )
                resolved_destination = destination.resolve()
                backup = backup_root.joinpath(
                    *resolved_destination.parts[1:]
                )
                backup.parent.mkdir(
                    parents=True,
                    exist_ok=True,
                )
                shutil.copy2(destination, backup)
            backups[destination] = backup

        for temp_path, destination in staged:
            os.replace(temp_path, destination)
            promoted.append(destination)

        for data, destination in items:
            if _sha256_file(destination) != _sha256_bytes(data):
                raise wb.WorldBuilderError(f"Post-deploy checksum mismatch at {destination}")

        return [(destination, backups[destination]) for _, destination in staged]

    except Exception:
        # Restore destinations already promoted if possible. Destinations with no
        # prior file are removed. Staged temporaries are cleaned up below.
        for destination in reversed(promoted):
            backup = backups.get(destination)
            try:
                if backup is not None and backup.exists():
                    shutil.copy2(backup, destination)
                else:
                    destination.unlink(missing_ok=True)
            except Exception:
                pass
        raise
    finally:
        for temp_path, _ in staged:
            temp_path.unlink(missing_ok=True)


def deploy_candidate(config_path: Path, manifest_path: Optional[Path], confirm_refreshed: bool) -> dict:
    config_path = config_path.resolve()
    config = wb.load_config(config_path)
    candidate_dir = _config_required_path(config, config_path, "candidate_dir")
    if manifest_path is None:
        manifest_path = candidate_dir / CANDIDATE_MANIFEST_NAME
    else:
        manifest_path = manifest_path.resolve()
    manifest = _load_json(manifest_path, "candidate publish manifest")
    if manifest.get("version") != BATCH_SCHEMA_VERSION:
        raise wb.WorldBuilderError(f"Unsupported candidate publish manifest version: {manifest.get('version')!r}")

    artifacts = manifest.get("artifacts", {})
    hashes = manifest.get("hashes", {})
    candidate_tre = manifest_path.parent / artifacts.get("tre", "")
    candidate_lua = manifest_path.parent / artifacts.get("server_template_lua", "")
    candidate_registry = manifest_path.parent / artifacts.get("oid_registry", "")
    for label, path, expected in (
        ("candidate TRE", candidate_tre, hashes.get("tre_sha256")),
        ("candidate generated_templates.lua", candidate_lua, hashes.get("server_template_lua_sha256")),
        ("candidate OID registry", candidate_registry, hashes.get("oid_registry_sha256")),
    ):
        if not path.is_file():
            raise wb.WorldBuilderError(f"{label} is missing: {path}")
        if not expected or _sha256_file(path) != expected:
            raise wb.WorldBuilderError(f"{label} no longer matches the validated candidate manifest")

    candidate_archive = wb.open_tre(candidate_tre)
    wb.validate_tre_v5_metadata(candidate_archive, require_md5=True)
    _verify_manifest_dependencies_current(config_path, config, manifest)

    refresh_required = manifest.get("changes_from_last_deploy", {}).get("refresh_required", [])
    if refresh_required and not confirm_refreshed:
        lines = [
            "This candidate updates/removes previously deployed structural World Builder projects.",
            "While the OLD TRE is still active, run each required refresh on the listed planet:",
        ]
        for item in refresh_required:
            lines += [
                f"  [{item.get('reason')}] {item.get('id')} on {item.get('planet')}",
                f"    {item.get('dry_run_command')}",
                f"    {item.get('confirm_command')}",
            ]
        lines.append("After all confirms pass, shut Core3 down and rerun deploy-set with --confirm-refreshed.")
        raise wb.WorldBuilderError("\n".join(lines))

    output_name = candidate_tre.name
    client_tre, server_tre, server_lua, registry_path, state_path = _destination_paths(config, config_path, output_name)
    _verify_previous_deployment_not_drifted(state_path, client_tre, server_tre, server_lua)

    tre_bytes = candidate_tre.read_bytes()
    lua_bytes = candidate_lua.read_bytes()
    registry_bytes = candidate_registry.read_bytes()
    state_bytes = (json.dumps(_prepare_deployed_state(manifest), indent=2) + "\n").encode("utf-8")

    stamp = wb.timestamp()
    promoted = _transactional_promote(
        [
            (tre_bytes, client_tre),
            (tre_bytes, server_tre),
            (lua_bytes, server_lua),
            (registry_bytes, registry_path),
            (state_bytes, state_path),
        ],
        stamp,
    )

    expected_tre = hashes["tre_sha256"]
    if _sha256_file(client_tre) != expected_tre or _sha256_file(server_tre) != expected_tre:
        raise wb.WorldBuilderError("Client/server TRE hashes differ after transactional deployment")

    return {
        "client_tre": str(client_tre),
        "server_tre": str(server_tre),
        "server_template_lua": str(server_lua),
        "oid_registry": str(registry_path),
        "deployed_state": str(state_path),
        "tre_sha256": expected_tre,
        "backups": [
            {"destination": str(destination), "backup": str(backup) if backup else None}
            for destination, backup in promoted
        ],
    }


# ---------------------------------------------------------------------------
# CLI wrappers used by bellum_worldbuilder.py
# ---------------------------------------------------------------------------


def cmd_bake_set(args) -> int:
    manifest = build_candidate(Path(args.config), getattr(args, "default_game_type", None))
    changes = manifest["changes_from_last_deploy"]
    print("World Builder batch candidate validated.")
    print(f"Source TRE: {manifest['base_tre']}")
    print(f"Candidate TRE: {Path(manifest['candidate_dir']) / manifest['artifacts']['tre']}")
    print(f"Projects: {len(manifest['projects'])}")
    print(
        "Changes: "
        f"added={len(changes['added'])}, updated={len(changes['updated'])}, "
        f"removed={len(changes['removed'])}, unchanged={len(changes['unchanged'])}"
    )
    print(
        "OID registry: "
        f"active={manifest['registry_counts']['active']}, "
        f"retired={manifest['registry_counts']['retired']}, "
        f"historical={manifest['registry_counts']['historical_total']}"
    )
    print(f"TRE SHA256: {manifest['hashes']['tre_sha256']}")
    if changes["refresh_required"]:
        print("Refresh required before deployment:")
        for item in changes["refresh_required"]:
            print(f"  {item['id']} [{item['reason']}] on {item['planet']}")
            print(f"    {item['dry_run_command']}")
            print(f"    {item['confirm_command']}")
    else:
        print("Refresh required before deployment: none")
    print("No active TRE or generated_templates.lua was modified.")
    return 0


def cmd_deploy_set(args) -> int:
    manifest_path = Path(args.manifest).expanduser() if getattr(args, "manifest", None) else None
    result = deploy_candidate(Path(args.config), manifest_path, bool(getattr(args, "confirm_refreshed", False)))
    print("World Builder batch deployment complete.")
    print(f"Client TRE: {result['client_tre']}")
    print(f"Server TRE: {result['server_tre']}")
    print(f"Server Lua: {result['server_template_lua']}")
    print(f"TRE SHA256: {result['tre_sha256']}")
    print("The client and server received byte-identical candidate TREs.")
    return 0

# Bellum Gero World Builder V1.9.8 - desired-state WBP V3 extension composer.
# Install after the proven batch implementation is defined so wrappers preserve V1/V2 behavior.
import worldbuilder_batch_extensions as _wb_batch_extensions
_wb_batch_extensions.install(sys.modules[__name__])
