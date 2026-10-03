#!/usr/bin/env python3
"""
tre_inventory.py — list, search, and extract from Star Wars Galaxies .tre archives.

Usage (Windows, from any folder):
  python tre_inventory.py list   "C:\\SWG Infinity"                 > infinity_files.txt
  python tre_inventory.py list   "C:\\SWG-Dev\\BellumGero-TRE-Force" > bg_files.txt
  python tre_inventory.py find   "C:\\SWG Infinity" hoth taanab kashyyyk
  python tre_inventory.py extract "C:\\SWG Infinity" terrain/taanab.trn  out_dir
  python tre_inventory.py diff   infinity_files.txt bg_files.txt

'list' walks every .tre in the folder (recursively) and prints:
  <tre file> <tab> <internal path> <tab> <uncompressed size>
Later .tre files override earlier ones in the real client load order, so the
'find' command also tells you WHICH .tre wins for each path.

Requires only the Python standard library (zlib, struct).
"""
import os
import struct
import sys
import zlib

HEADER_FMT = "<4s4sIIIIIII"  # magic, version, recCount, recOffset, recComp, recSize, nameComp, nameSize, nameUncompSize
HEADER_LEN = struct.calcsize(HEADER_FMT)
RECORD_FMT = "<IIIIII"       # checksum, dataSize(uncomp), dataOffset, dataComp, dataCompSize, nameOffset
RECORD_LEN = struct.calcsize(RECORD_FMT)


def _inflate(blob, comp, uncompressed_size):
    if comp == 0:
        return blob
    if comp == 2:
        return zlib.decompress(blob, bufsize=max(uncompressed_size, 1))
    raise ValueError(f"unknown compression type {comp}")


def read_tre(path):
    """Return list of dicts: name, size, offset, comp, comp_size — for one .tre."""
    with open(path, "rb") as f:
        head = f.read(HEADER_LEN)
        if len(head) < HEADER_LEN:
            raise ValueError("file too small")
        (magic, version, rec_count, rec_offset, rec_comp, rec_size,
         name_comp, name_size, name_uncomp_size) = struct.unpack(HEADER_FMT, head)
        if magic != b"EERT":
            raise ValueError(f"bad magic {magic!r} (not a .tre)")

        f.seek(rec_offset)
        rec_blob = _inflate(f.read(rec_size), rec_comp, rec_count * RECORD_LEN)
        # name block sits immediately after the record block
        name_blob = _inflate(f.read(name_size), name_comp, name_uncomp_size)

    entries = []
    for i in range(rec_count):
        checksum, data_size, data_offset, data_comp, data_comp_size, name_offset = \
            struct.unpack_from(RECORD_FMT, rec_blob, i * RECORD_LEN)
        end = name_blob.index(b"\x00", name_offset)
        name = name_blob[name_offset:end].decode("ascii", "replace")
        entries.append(dict(name=name, size=data_size, offset=data_offset,
                            comp=data_comp, comp_size=data_comp_size))
    return entries


def extract_entry(tre_path, entry, out_root):
    with open(tre_path, "rb") as f:
        f.seek(entry["offset"])
        blob = f.read(entry["comp_size"] if entry["comp"] else entry["size"])
    data = _inflate(blob, entry["comp"], entry["size"])
    out_path = os.path.join(out_root, *entry["name"].split("/"))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as o:
        o.write(data)
    return out_path


def cfg_priorities(root):
    """Parse searchTree_XX_NN=<file> from *.cfg in root -> {basename.lower(): NN}."""
    import re
    pri = {}
    try:
        cfgs = [f for f in os.listdir(root) if f.lower().endswith(".cfg")]
    except OSError:
        return pri
    pat = re.compile(r"^\s*searchTree_\d+_(\d+)\s*=\s*(\S+)", re.I)
    for cfg in cfgs:
        with open(os.path.join(root, cfg), encoding="latin-1") as f:
            for line in f:
                m = pat.match(line)
                if m:
                    pri[os.path.basename(m.group(2)).lower()] = int(m.group(1))
    return pri


def walk_tres(root):
    found = []
    for dirpath, _, files in os.walk(root):
        for fn in files:
            if fn.lower().endswith(".tre"):
                found.append(os.path.join(dirpath, fn))
    # Real load order comes from searchTree_XX_NN in the client's *.cfg
    # (higher NN wins). TREs not in the cfg are not loaded by the client;
    # they sort first (lowest) and alphabetically as a fallback.
    pri = cfg_priorities(root)
    top = os.path.normcase(os.path.abspath(root))

    def rank(p):
        # only TREs in the client folder itself are loaded; backups in
        # subfolders sharing a name must not inherit that priority
        if os.path.normcase(os.path.dirname(os.path.abspath(p))) != top:
            return -1
        return pri.get(os.path.basename(p).lower(), -1)
    return sorted(found, key=lambda p: (rank(p),
                                    os.path.basename(p).lower()))


def cmd_list(root):
    for tre in walk_tres(root):
        try:
            for e in read_tre(tre):
                print(f"{os.path.basename(tre)}\t{e['name']}\t{e['size']}")
        except Exception as ex:  # keep going on odd files
            print(f"# ERROR {tre}: {ex}", file=sys.stderr)


def cmd_find(root, terms):
    terms = [t.lower() for t in terms]
    winner = {}  # internal path -> (tre, size); later tre overrides
    for tre in walk_tres(root):
        try:
            for e in read_tre(tre):
                n = e["name"].lower()
                if any(t in n for t in terms):
                    winner[e["name"]] = (os.path.basename(tre), e["size"])
        except Exception as ex:
            print(f"# ERROR {tre}: {ex}", file=sys.stderr)
    for name in sorted(winner):
        tre, size = winner[name]
        print(f"{tre}\t{name}\t{size}")
    print(f"# {len(winner)} matching paths", file=sys.stderr)


def cmd_extract(root, internal_path, out_dir):
    target = internal_path.replace("\\", "/").lower()
    hit = None
    for tre in walk_tres(root):
        try:
            for e in read_tre(tre):
                if e["name"].lower() == target:
                    hit = (tre, e)  # keep last = highest-priority override
        except Exception:
            pass
    if not hit:
        sys.exit(f"not found: {internal_path}")
    tre, e = hit
    out = extract_entry(tre, e, out_dir)
    print(f"extracted {e['name']} from {os.path.basename(tre)} -> {out}")


def cmd_diff(list_a, list_b):
    def load(p):
        d = {}
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#"):
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) == 3:
                    d[parts[1]] = (parts[0], int(parts[2]))
        return d
    a, b = load(list_a), load(list_b)
    only_a = sorted(set(a) - set(b))
    only_b = sorted(set(b) - set(a))
    diff_size = sorted(k for k in set(a) & set(b) if a[k][1] != b[k][1])
    print(f"# only in {list_a}: {len(only_a)}")
    for k in only_a:
        print(f"A\t{k}")
    print(f"# only in {list_b}: {len(only_b)}")
    for k in only_b:
        print(f"B\t{k}")
    print(f"# same path, different size: {len(diff_size)}")
    for k in diff_size:
        print(f"~\t{k}\t{a[k][1]}\t{b[k][1]}")


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    cmd = args[0]
    if cmd == "list" and len(args) == 2:
        cmd_list(args[1])
    elif cmd == "find" and len(args) >= 3:
        cmd_find(args[1], args[2:])
    elif cmd == "extract" and len(args) == 4:
        cmd_extract(args[1], args[2], args[3])
    elif cmd == "diff" and len(args) == 3:
        cmd_diff(args[1], args[2])
    else:
        sys.exit(__doc__)
