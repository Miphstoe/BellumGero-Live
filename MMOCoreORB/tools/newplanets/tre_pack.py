#!/usr/bin/env python3
"""tre_pack.py — build a SWG .tre (EERT v5) from a folder tree.

  python tre_pack.py <src_dir> <out.tre>
  python tre_pack.py --merge <base.tre> <overlay_dir> <out.tre>

--merge keeps every file of base.tre (raw compressed bytes copied as-is) and
adds or replaces the files found under overlay_dir. base.tre is never modified.

Every file under src_dir is stored at its relative path (lowercased, '/').
Layout (matches SOE/BG archives): 36-byte header, zlib file data, zlib record
table sorted by SOE CRC-32 of the path, zlib name block, MD5 per record.
"""
import hashlib
import os
import struct
import sys
import zlib

_T = []
for _i in range(256):
    _c = _i << 24
    for _ in range(8):
        _c = ((_c << 1) ^ 0x04C11DB7) & 0xFFFFFFFF if _c & 0x80000000 else (_c << 1) & 0xFFFFFFFF
    _T.append(_c)

def soe_crc(s):
    c = 0xFFFFFFFF
    for ch in s.encode('ascii'):
        c = (_T[((c >> 24) ^ ch) & 0xFF] ^ (c << 8)) & 0xFFFFFFFF
    return c ^ 0xFFFFFFFF

def _overlay(src):
    files = {}
    for dp, _, fns in os.walk(src):
        for fn in fns:
            full = os.path.join(dp, fn)
            files[os.path.relpath(full, src).replace(os.sep, '/').lower()] = full
    return files

def _base_entries(base):
    """name -> (size, comp, raw_blob, md5) for every record of an existing TRE."""
    with open(base, 'rb') as f:
        h = struct.unpack('<4s4sIIIIIII', f.read(36))
        if h[0] != b'EERT':
            sys.exit('not a tre: ' + base)
        n, rec_off = h[2], h[3]
        f.seek(rec_off)
        rec = f.read(h[5])
        rec = zlib.decompress(rec) if h[4] else rec
        nb = f.read(h[7])
        nb = zlib.decompress(nb) if h[6] else nb
        md5 = f.read(16 * n)
        out = {}
        for i in range(n):
            crc, size, off, comp, csize, noff = struct.unpack_from('<IIIIII', rec, i * 24)
            name = nb[noff:nb.index(b'\x00', noff)].decode('ascii')
            f.seek(off)
            blob = f.read(csize if comp else size)
            digest = md5[16 * i:16 * i + 16] if len(md5) == 16 * n else None
            out[name] = (size, comp, blob, digest)
    return out

def pack(src, out, base=None):
    entries = _base_entries(base) if base else {}
    added = replaced = 0
    for name, full in _overlay(src).items():
        data = open(full, 'rb').read()
        comp = zlib.compress(data, 9)
        ctype, blob = (2, comp) if len(comp) < len(data) else (0, data)
        if name in entries:
            replaced += 1
        else:
            added += 1
        entries[name] = (len(data), ctype, blob, hashlib.md5(data).digest())
    files = sorted((soe_crc(n), n) for n in entries)
    if len({f[0] for f in files}) != len(files):
        sys.exit('CRC collision between paths')
    with open(out, 'wb') as o:
        o.write(b'\x00' * 36)
        recs, names, md5s = [], b'', b''
        for crc, name in files:
            size, ctype, blob, digest = entries[name]
            if digest is None:
                digest = hashlib.md5(zlib.decompress(blob) if ctype else blob).digest()
            off = o.tell()
            o.write(blob)
            recs.append(struct.pack('<IIIIII', crc, size, off, ctype, len(blob) if ctype else 0, len(names)))
            names += name.encode('ascii') + b'\x00'
            md5s += digest
        rec_c, name_c = zlib.compress(b''.join(recs), 9), zlib.compress(names, 9)
        rec_off = o.tell()
        o.write(rec_c)
        o.write(name_c)
        o.write(md5s)
        o.seek(0)
        o.write(struct.pack('<4s4sIIIIIII', b'EERT', b'5000', len(files), rec_off,
                            2, len(rec_c), 2, len(name_c), len(names)))
    print(f'packed {len(files)} files ({added} added, {replaced} replaced) -> {out} ({os.path.getsize(out):,} bytes)')

if __name__ == '__main__':
    if len(sys.argv) == 5 and sys.argv[1] == '--merge':
        base, src, out = sys.argv[2:5]
        if os.path.abspath(base) == os.path.abspath(out):
            sys.exit('refusing to overwrite the base TRE')
        pack(src, out, base)
    elif len(sys.argv) == 3:
        pack(sys.argv[1], sys.argv[2])
    else:
        sys.exit(__doc__)
