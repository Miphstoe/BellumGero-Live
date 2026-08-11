#!/usr/bin/env python3
"""Extract a small Bellum Gero World Builder structure-reference package.

This tool scans a directory tree of TRE archives without loading the archive
payloads into memory, finds a focused set of structure/snapshot references,
walks only structural IFF dependencies, and writes one ZIP plus a manifest.

It is intentionally conservative: interior-layout and snapshot files are
extracted but are NOT recursively expanded into every prop/object they name.
That keeps the reference package small enough to inspect and share.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
import zlib
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

MAGIC = b"EERT5000"
HEADER_SIZE = 36
RECORD_SIZE = 24

DEFAULT_SEEDS = (
    "snapshot/dantooine.ws",
    "snapshot/lok.ws",
    "object/building/general/shared_dantooine_force_crystal_hunter_sd_cave.iff",
    "object/building/general/shared_lok_evil_droid_engineer_cave.iff",
    "object/building/tatooine/shared_cave_tatooine_droid_01.iff",
    "object/building/tatooine/shared_cave_tatooine_style_01.iff",
    "interiorlayout/force_crystal_cave_v1.ilf",
)

DISCOVERY_KEYWORDS = (
    "force_crystal",
    "evil_droid_engineer_cave",
    "cave_tatooine_droid_01",
    "cave_tatooine_style_01",
)

# Structural references only. Do not follow texture/shader/mesh chains.
REFERENCE_RE = re.compile(
    rb"([A-Za-z0-9_./-]{3,}\.(?:iff|pob|apt|flr|ilf))",
    re.IGNORECASE,
)

SCANNABLE_PREFIXES = (
    "object/building/",
    "appearance/",
)


class ExtractError(RuntimeError):
    pass


@dataclass(frozen=True)
class TreRecord:
    hash_or_crc: int
    uncompressed_size: int
    data_offset: int
    compression: int
    compressed_size: int
    name_offset: int
    name: str


@dataclass
class TreIndex:
    path: Path
    records: List[TreRecord]
    by_name: Dict[str, TreRecord]


def _decompress(blob: bytes, mode: int, expected: Optional[int] = None) -> bytes:
    if mode == 0:
        data = blob
    elif mode == 2:
        data = zlib.decompress(blob)
    else:
        raise ExtractError(f"Unsupported TRE compression mode {mode}")

    if expected is not None and len(data) != expected:
        raise ExtractError(f"Decompressed size mismatch: got {len(data)}, expected {expected}")
    return data


def open_tre_index(path: Path) -> TreIndex:
    with path.open("rb") as f:
        header = f.read(HEADER_SIZE)
        if len(header) != HEADER_SIZE or header[:8] != MAGIC:
            raise ExtractError(f"{path}: not a supported TRE v5 archive")

        (
            record_count,
            metadata_offset,
            info_compression,
            info_compressed_size,
            names_compression,
            names_compressed_size,
            names_uncompressed_size,
        ) = struct.unpack_from("<7I", header, 8)

        f.seek(metadata_offset)
        info_blob = f.read(info_compressed_size)
        names_blob = f.read(names_compressed_size)

    info = _decompress(info_blob, info_compression, record_count * RECORD_SIZE)
    names = _decompress(names_blob, names_compression, names_uncompressed_size)

    records: List[TreRecord] = []
    by_name: Dict[str, TreRecord] = {}

    for i in range(record_count):
        base = i * RECORD_SIZE
        values = struct.unpack_from("<6I", info, base)
        name_offset = values[5]
        if name_offset >= len(names):
            raise ExtractError(f"{path}: invalid name offset {name_offset}")
        end = names.find(b"\0", name_offset)
        if end < 0:
            raise ExtractError(f"{path}: unterminated record name at offset {name_offset}")
        name = names[name_offset:end].decode("utf-8", errors="replace").replace("\\", "/")
        rec = TreRecord(*values, name=name)
        records.append(rec)
        by_name[name.lower()] = rec

    return TreIndex(path=path, records=records, by_name=by_name)


def extract_record(index: TreIndex, record: TreRecord) -> bytes:
    with index.path.open("rb") as f:
        f.seek(record.data_offset)
        blob = f.read(record.compressed_size)
    return _decompress(blob, record.compression, record.uncompressed_size)


def find_tres(root: Path) -> List[Path]:
    if root.is_file() and root.suffix.lower() == ".tre":
        return [root.resolve()]
    if not root.exists():
        raise ExtractError(f"TRE root does not exist: {root}")
    return sorted(p.resolve() for p in root.rglob("*.tre") if p.is_file())


def build_global_index(tre_paths: Sequence[Path]) -> Tuple[Dict[str, List[Tuple[Path, TreRecord]]], Dict[Path, TreIndex]]:
    global_index: Dict[str, List[Tuple[Path, TreRecord]]] = {}
    archive_indexes: Dict[Path, TreIndex] = {}

    for n, tre_path in enumerate(tre_paths, 1):
        print(f"[{n}/{len(tre_paths)}] Indexing {tre_path.name} ...")
        try:
            idx = open_tre_index(tre_path)
        except Exception as exc:
            print(f"  WARNING: skipped {tre_path}: {exc}", file=sys.stderr)
            continue

        archive_indexes[tre_path] = idx
        for rec in idx.records:
            global_index.setdefault(rec.name.lower(), []).append((tre_path, rec))

    return global_index, archive_indexes


def choose_candidate(
    candidates: Sequence[Tuple[Path, TreRecord]],
    prefer_patterns: Sequence[str],
) -> Tuple[Path, TreRecord, bool]:
    if not candidates:
        raise ExtractError("No candidates supplied")

    lowered_patterns = [p.lower() for p in prefer_patterns if p]
    for pattern in lowered_patterns:
        matches = [item for item in candidates if pattern in item[0].name.lower()]
        if matches:
            return sorted(matches, key=lambda x: str(x[0]).lower())[0][0], sorted(matches, key=lambda x: str(x[0]).lower())[0][1], len(candidates) > 1

    # If no explicit preference resolved an override, choose deterministically
    # and record the ambiguity in the manifest instead of hiding it.
    ordered = sorted(candidates, key=lambda x: str(x[0]).lower())
    return ordered[0][0], ordered[0][1], len(candidates) > 1


def should_scan_dependencies(internal_path: str) -> bool:
    lower = internal_path.lower()
    return any(lower.startswith(prefix) for prefix in SCANNABLE_PREFIXES)


def discover_references(raw: bytes) -> List[str]:
    found = set()
    for match in REFERENCE_RE.finditer(raw):
        value = match.group(1).decode("utf-8", errors="ignore").replace("\\", "/")
        if "/" not in value:
            continue
        found.add(value)
    return sorted(found)


def safe_zip_name(path: str) -> str:
    return path.lstrip("/").replace("..", "__")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--tre-root",
        required=True,
        help="Directory containing the local server TRE stack, or one TRE file",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output ZIP path, e.g. /mnt/c/Users/<you>/Downloads/WorldBuilderStructureRefs.zip",
    )
    parser.add_argument(
        "--seed",
        action="append",
        default=[],
        help="Additional TRE internal path to extract (repeatable)",
    )
    parser.add_argument(
        "--prefer-tre",
        action="append",
        default=["bg_custom1.tre"],
        help="Filename substring preferred when the same path occurs in multiple TREs (repeatable)",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=4,
        help="Maximum structural dependency depth (default: 4)",
    )
    args = parser.parse_args()

    tre_root = Path(args.tre_root).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    tre_paths = find_tres(tre_root)
    if not tre_paths:
        raise ExtractError(f"No .tre files found under {tre_root}")

    print(f"Found {len(tre_paths)} TRE archive(s).")
    global_index, archive_indexes = build_global_index(tre_paths)
    if not archive_indexes:
        raise ExtractError("No readable TRE v5 archives were indexed")

    seeds = list(DEFAULT_SEEDS)
    for seed in args.seed:
        normalized = seed.replace("\\", "/")
        if normalized not in seeds:
            seeds.append(normalized)

    queue: List[Tuple[str, int, str]] = [(seed, 0, "seed") for seed in seeds]
    queued = {seed.lower() for seed in seeds}
    extracted: Dict[str, bytes] = {}
    manifest_entries: List[dict] = []
    missing: List[str] = []

    while queue:
        internal, depth, reason = queue.pop(0)
        key = internal.lower()
        candidates = global_index.get(key, [])
        if not candidates:
            if reason == "seed":
                missing.append(internal)
            continue

        source_path, record, ambiguous = choose_candidate(candidates, args.prefer_tre)
        idx = archive_indexes[source_path]
        raw = extract_record(idx, record)
        canonical_name = record.name

        if canonical_name.lower() in extracted:
            continue
        extracted[canonical_name.lower()] = raw

        manifest_entries.append(
            {
                "path": canonical_name,
                "source_tre": str(source_path),
                "size": len(raw),
                "reason": reason,
                "depth": depth,
                "ambiguous_source": ambiguous,
                "all_sources": [str(item[0]) for item in sorted(candidates, key=lambda x: str(x[0]).lower())],
            }
        )

        if depth >= args.max_depth or not should_scan_dependencies(canonical_name):
            continue

        for ref in discover_references(raw):
            ref_key = ref.lower()
            if ref_key in queued or ref_key in extracted:
                continue
            if ref_key not in global_index:
                continue
            queued.add(ref_key)
            queue.append((ref, depth + 1, f"referenced by {canonical_name}"))

    discovery = {}
    for keyword in DISCOVERY_KEYWORDS:
        hits = sorted(
            name for name in global_index.keys()
            if keyword.lower() in name
        )
        discovery[keyword] = hits

    manifest = {
        "generated": datetime.now().isoformat(timespec="seconds"),
        "tre_root": str(tre_root),
        "tre_archives_indexed": [str(p) for p in sorted(archive_indexes)],
        "preferred_tre_patterns": args.prefer_tre,
        "seed_paths": seeds,
        "missing_seed_paths": missing,
        "files": sorted(manifest_entries, key=lambda x: x["path"].lower()),
        "discovery_matches": discovery,
        "notes": [
            "Snapshot and interiorlayout files are extracted but not recursively expanded into every prop they reference.",
            "Only structural object/building and appearance dependency chains are followed.",
            "If ambiguous_source is true, review all_sources; --prefer-tre controls override selection.",
        ],
    }

    text_lines = [
        "BELLUM GERO WORLD BUILDER - STRUCTURE REFERENCE EXTRACT",
        "",
        f"Generated: {manifest['generated']}",
        f"TRE root: {tre_root}",
        f"Archives indexed: {len(archive_indexes)}",
        f"Files extracted: {len(manifest_entries)}",
        "",
    ]
    if missing:
        text_lines.append("MISSING SEEDS:")
        text_lines.extend(f"  - {item}" for item in missing)
        text_lines.append("")

    text_lines.append("EXTRACTED FILES:")
    for item in manifest["files"]:
        marker = " [AMBIGUOUS SOURCE]" if item["ambiguous_source"] else ""
        text_lines.append(f"  - {item['path']}  <-  {Path(item['source_tre']).name}{marker}")

    text_lines.append("")
    text_lines.append("DISCOVERY MATCHES:")
    for keyword, hits in discovery.items():
        text_lines.append(f"  {keyword}:")
        if hits:
            text_lines.extend(f"    - {hit}" for hit in hits)
        else:
            text_lines.append("    - <none>")

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for item in manifest["files"]:
            data = extracted[item["path"].lower()]
            zf.writestr(safe_zip_name(item["path"]), data)
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
        zf.writestr("manifest.txt", "\n".join(text_lines) + "\n")

    print()
    print(f"Wrote: {output}")
    print(f"Extracted {len(manifest_entries)} file(s).")
    if missing:
        print("Missing seed path(s):")
        for item in missing:
            print(f"  - {item}")
        print("The ZIP was still created; manifest discovery matches can help resolve naming differences.")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ExtractError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
