#!/usr/bin/env python3
"""Add Mandalorian Way title skills to client skills.iff and bg_custom1.tre.

The Community title dropdown is built on the client from datatables/skill/skills.iff
(IS_TITLE=1 rows) intersected with skills the player owns. Server-only Lua skills are
not enough; the client TRE must list mando_title_* as title skills.

Patches:
  - datatables/skill/skills.iff (adds six rows if missing)
  - bg_custom1.tre in place (replaces the skills.iff record payload)

Default paths target the Bellum Dev-BG layout on WSL (/mnt/c/...).
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import struct
import sys
import zlib
from pathlib import Path

MANDO_TITLE_SKILLS = [
    "mando_title_foundling",
    "mando_title_initiate",
    "mando_title_hunter",
    "mando_title_verdika",
    "mando_title_clanbound",
    "mando_title_mandalorian",
]


def u32be(data: bytes, offset: int) -> tuple[int, int]:
    return struct.unpack(">I", data[offset : offset + 4])[0], offset + 4


def u32le(data: bytes, offset: int) -> tuple[int, int]:
    return struct.unpack("<I", data[offset : offset + 4])[0], offset + 4


def i32le(data: bytes, offset: int) -> tuple[int, int]:
    return struct.unpack("<i", data[offset : offset + 4])[0], offset + 4


def f32le(data: bytes, offset: int) -> tuple[float, int]:
    return struct.unpack("<f", data[offset : offset + 4])[0], offset + 4


def read_cstring(data: bytes, offset: int) -> tuple[str, int]:
    end = data.index(b"\x00", offset)
    return data[offset:end].decode("ascii", "replace"), end + 1


def write_cstring(value: str) -> bytes:
    return value.encode("ascii", "replace") + b"\x00"


def type_kind(type_name: str) -> str:
    if type_name.startswith("s"):
        return "s"
    if type_name.startswith("e("):
        return "e"
    if type_name.startswith("b"):
        return "b"
    if type_name.startswith("f"):
        return "f"
    if type_name.startswith("i"):
        return "i"
    return "i"


def parse_datatable(path: Path) -> tuple[list[str], list[str], list[list]]:
    data = path.read_bytes()
    offset = 24  # inner FORM header consumed; first chunk is COLS
    columns: list[str] = []
    types: list[str] = []
    rows: list[list] = []

    while offset < len(data) - 8:
        chunk_id, offset = u32be(data, offset)
        chunk_size, offset = u32be(data, offset)
        body = data[offset : offset + chunk_size]
        offset += chunk_size

        if chunk_id == 0x434F4C53:  # COLS
            body_offset = 0
            count, body_offset = u32le(body, body_offset)
            for _ in range(count):
                value, body_offset = read_cstring(body, body_offset)
                columns.append(value)
        elif chunk_id == 0x54595045:  # TYPE
            body_offset = 0
            for _ in range(len(columns)):
                value, body_offset = read_cstring(body, body_offset)
                types.append(value)
        elif chunk_id == 0x524F5753:  # ROWS
            body_offset = 0
            count, body_offset = u32le(body, body_offset)
            for _ in range(count):
                row: list = []
                for type_name in types:
                    kind = type_kind(type_name)
                    if kind == "s":
                        value, body_offset = read_cstring(body, body_offset)
                        row.append(value)
                    elif kind == "f":
                        value, body_offset = f32le(body, body_offset)
                        row.append(value)
                    else:
                        value, body_offset = i32le(body, body_offset)
                        row.append(value)
                rows.append(row)

    if not columns or not types:
        raise RuntimeError(f"failed to parse datatable columns/types from {path}")
    return columns, types, rows


def make_mando_title_row(columns: list[str]) -> list:
    """Minimal grant-only title skill row (matches server mando_titles.lua)."""
    idx = {name: i for i, name in enumerate(columns)}
    row = [0] * len(columns)
    row[idx["NAME"]] = ""
    row[idx["PARENT"]] = ""
    row[idx["GRAPH_TYPE"]] = 4  # fourByFour
    row[idx["GOD_ONLY"]] = 0
    row[idx["IS_TITLE"]] = 1
    row[idx["IS_PROFESSION"]] = 0
    row[idx["IS_HIDDEN"]] = 0
    row[idx["MONEY_REQUIRED"]] = 0
    row[idx["POINTS_REQUIRED"]] = 0
    row[idx["SKILLS_REQUIRED_COUNT"]] = 0
    row[idx["SKILLS_REQUIRED"]] = ""
    row[idx["PRECLUSION_SKILLS"]] = ""
    row[idx["XP_TYPE"]] = ""
    row[idx["XP_COST"]] = 0
    row[idx["XP_CAP"]] = 0
    row[idx["MISSIONS_REQUIRED"]] = ""
    row[idx["APPRENTICESHIPS_REQUIRED"]] = 0
    row[idx["STATS_REQUIRED"]] = ""
    row[idx["SPECIES_REQUIRED"]] = ""
    row[idx["JEDI_STATE_REQUIRED"]] = 0
    row[idx["SKILL_ABILITY"]] = ""
    row[idx["COMMANDS"]] = ""
    row[idx["SKILL_MODS"]] = ""
    row[idx["SCHEMATICS_GRANTED"]] = ""
    row[idx["SCHEMATICS_REVOKED"]] = ""
    row[idx["SEARCHABLE"]] = 0
    row[idx["ENDER"]] = 0
    return row


def add_mando_rows(columns: list[str], rows: list[list]) -> tuple[list[list], list[str]]:
    idx = {name: i for i, name in enumerate(columns)}
    existing = {row[idx["NAME"]] for row in rows}
    added: list[str] = []
    for skill_name in MANDO_TITLE_SKILLS:
        if skill_name in existing:
            continue
        row = make_mando_title_row(columns)
        row[idx["NAME"]] = skill_name
        rows.append(row)
        added.append(skill_name)
    return rows, added


def serialize_rows_body(types: list[str], rows: list[list]) -> bytes:
    out = bytearray()
    out += struct.pack("<I", len(rows))
    for row in rows:
        for type_name, value in zip(types, row):
            kind = type_kind(type_name)
            if kind == "s":
                out += write_cstring(str(value))
            elif kind == "f":
                out += struct.pack("<f", float(value))
            else:
                out += struct.pack("<i", int(value))
    return bytes(out)


def write_datatable(path: Path, columns: list[str], types: list[str], rows: list[list]) -> None:
    original = path.read_bytes()
    if original[:4] != b"FORM":
        raise RuntimeError(f"unexpected datatable header in {path}")

    # Preserve everything before the ROWS chunk; rebuild ROWS only.
    offset = 24
    prefix = bytearray(original[:offset])
    rows_chunk_offset = None
    rows_chunk_size = None

    while offset < len(original) - 8:
        chunk_id, offset = u32be(original, offset)
        chunk_size, offset = u32be(original, offset)
        chunk_start = offset
        offset += chunk_size
        if chunk_id == 0x524F5753:
            rows_chunk_offset = chunk_start - 8
            rows_chunk_size = chunk_size
            break
        prefix.extend(original[chunk_start - 8 : chunk_start + chunk_size])

    if rows_chunk_offset is None:
        raise RuntimeError(f"ROWS chunk not found in {path}")

    rows_body = serialize_rows_body(types, rows)
    rows_chunk = b"ROWS" + struct.pack(">I", len(rows_body)) + rows_body
    prefix.extend(rows_chunk)

    suffix_start = rows_chunk_offset + 8 + rows_chunk_size
    prefix.extend(original[suffix_start:])
    path.write_bytes(prefix)


def read_tre_index(tre_path: Path):
    data = tre_path.read_bytes()
    if struct.unpack("<I", data[:4])[0] != 0x54524545:
        raise RuntimeError(f"{tre_path} is not a TREE archive")
    total_records = struct.unpack("<I", data[8:12])[0]
    data_offset = struct.unpack("<I", data[12:16])[0]
    file_ct, file_cs = struct.unpack("<II", data[16:24])
    name_ct, name_cs, _name_us = struct.unpack("<III", data[24:36])

    records_blob = zlib.decompress(data[data_offset : data_offset + file_cs]) if file_ct == 2 else data[data_offset : data_offset + file_cs]
    names_blob = zlib.decompress(data[data_offset + file_cs : data_offset + file_cs + name_cs]) if name_ct == 2 else data[data_offset + file_cs : data_offset + file_cs + name_cs]

    records = []
    for i in range(total_records):
        off = i * 24
        checksum, uus, file_offset, comp_type, comp_size, name_offset = struct.unpack("<IIIIII", records_blob[off : off + 24])
        name = names_blob[name_offset : names_blob.find(b"\x00", name_offset)].decode("ascii", "replace")
        records.append(
            {
                "index": i,
                "name": name,
                "checksum": checksum,
                "uus": uus,
                "file_offset": file_offset,
                "comp_type": comp_type,
                "comp_size": comp_size,
                "name_offset": name_offset,
            }
        )

    md5_start = data_offset + file_cs + name_cs
    md5_blob = data[md5_start : md5_start + total_records * 16]
    return data, records, records_blob, names_blob, md5_blob, data_offset, file_ct, file_cs, name_ct, name_cs


def replace_tre_file(tre_path: Path, inner_path: str, payload: bytes, compress: bool = True) -> None:
    data, records, records_blob, names_blob, md5_blob, data_offset, file_ct, file_cs, name_ct, name_cs = read_tre_index(tre_path)
    target = None
    for record in records:
        if record["name"] == inner_path:
            target = record
            break
    if target is None:
        raise RuntimeError(f"{inner_path} not found in {tre_path}")

    if compress:
        comp_type = 2
        compressed = zlib.compress(payload, 9)
        new_bytes = compressed
        new_size = len(compressed)
    else:
        comp_type = 0
        new_bytes = payload
        new_size = len(payload)

    old_size = target["comp_size"]
    old_offset = target["file_offset"]
    size_delta = new_size - old_size

    # Shift file payloads that come after the replaced record.
    mutable = bytearray(data)
    tail_start = old_offset + old_size
    tail = mutable[tail_start:]
    mutable[old_offset : old_offset + new_size] = new_bytes
    mutable[old_offset + new_size : old_offset + new_size + len(tail)] = tail

    # Update record table entries (offsets for records after target).
    updated_records_blob = bytearray(records_blob)
    target_index = target["index"]
    for i, record in enumerate(records):
        off = i * 24
        checksum, uus, file_offset, comp_type_old, comp_size, name_offset = struct.unpack("<IIIIII", records_blob[off : off + 24])
        if i == target_index:
            file_offset = old_offset
            comp_type_old = comp_type
            comp_size = new_size
            uus = len(payload)
            checksum = zlib.crc32(payload) & 0xFFFFFFFF
        elif file_offset > old_offset:
            file_offset += size_delta
        updated_records_blob[off : off + 24] = struct.pack("<IIIIII", checksum, uus, file_offset, comp_type_old, comp_size, name_offset)

    # Recompress index blocks.
    new_file_blob = zlib.compress(bytes(updated_records_blob), 9) if file_ct == 2 else bytes(updated_records_blob)
    new_name_blob = zlib.compress(names_blob, 9) if name_ct == 2 else names_blob

    # Rewrite header sizes and index at data_offset.
    mutable[16:24] = struct.pack("<II", file_ct, len(new_file_blob))
    mutable[24:36] = struct.pack("<III", name_ct, len(new_name_blob), len(names_blob))

    # If file grew/shrank before data_offset, adjust data_offset (only when payload crosses boundary).
    # Payload lives before index; index starts at data_offset. Changing payload size does not move index.
    mutable[data_offset : data_offset + len(new_file_blob)] = new_file_blob
    mutable[data_offset + len(new_file_blob) : data_offset + len(new_file_blob) + len(new_name_blob)] = new_name_blob

    # MD5 sums: recompute only for replaced record; keep others.
    md5_list = bytearray(md5_blob)
    md5_list[target_index * 16 : (target_index + 1) * 16] = hashlib.md5(payload).digest()
    md5_start = data_offset + len(new_file_blob) + len(new_name_blob)
    mutable[md5_start : md5_start + len(md5_list)] = md5_list

    tre_path.write_bytes(mutable)


def patch_skills_iff(skills_path: Path) -> list[str]:
    columns, types, rows = parse_datatable(skills_path)
    rows, added = add_mando_rows(columns, rows)
    if added:
        write_datatable(skills_path, columns, types, rows)
    return added


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skills-iff",
        type=Path,
        default=Path("/mnt/c/bg_custom1/datatables/skill/skills.iff"),
        help="Unpacked skills.iff to patch",
    )
    parser.add_argument(
        "--tre",
        type=Path,
        default=Path("/mnt/c/Dev-BG/bg_custom1.tre"),
        help="bg_custom1.tre to patch in place",
    )
    parser.add_argument(
        "--deploy-trefiles",
        type=Path,
        default=Path("/trefiles/bg_custom1.tre"),
        help="Optional server TRE copy target",
    )
    parser.add_argument(
        "--deploy-client",
        type=Path,
        default=Path("/mnt/c/BellumGero/bg_custom1.tre"),
        help="Optional client TRE copy target",
    )
    parser.add_argument("--no-tre", action="store_true", help="Only patch unpacked skills.iff")
    args = parser.parse_args(argv)

    if not args.skills_iff.is_file():
        print(f"ERROR: skills.iff not found: {args.skills_iff}", file=sys.stderr)
        return 1

    added = patch_skills_iff(args.skills_iff)
    if added:
        print(f"Patched {args.skills_iff}; added rows: {', '.join(added)}")
    else:
        print(f"No changes needed; all mando_title_* rows already present in {args.skills_iff}")

    payload = args.skills_iff.read_bytes()

    if not args.no_tre:
        if not args.tre.is_file():
            print(f"ERROR: TRE not found: {args.tre}", file=sys.stderr)
            return 1
        replace_tre_file(args.tre, "datatables/skill/skills.iff", payload)
        print(f"Updated {args.tre}")

        for label, dest in (("server /trefiles", args.deploy_trefiles), ("client", args.deploy_client)):
            if dest is None:
                continue
            try:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(args.tre.read_bytes())
                print(f"Deployed TRE to {label}: {dest}")
            except OSError as exc:
                print(f"WARN: could not deploy to {label} ({dest}): {exc}", file=sys.stderr)

    print("Done. Restart core3 and have players relog so the client reloads skills.iff.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
