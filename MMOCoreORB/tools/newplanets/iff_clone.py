#!/usr/bin/env python3
"""iff_clone.py — re-serialize SWG IFF object templates with patched string properties.

  python iff_clone.py <src.iff> <dst.iff> [prop=value ...]

Properties live in XXXX chunks as  <name>\0 <flag> <payload>.  Supported patches:
  path properties   (craftedSharedTemplate, appearanceFilename, ...):  payload = \x01 + value + \0
  stringId properties (objectName, detailedDescription, lookAtText): value "stf:key" -> \x01\x01 stf \0 \x01 key \0
Patching a property that is present but empty (\0 flag) is supported; FORM sizes are recomputed.
"""
import struct, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from iff_tool import parse

STRING_ID = {'objectName', 'detailedDescription', 'lookAtText'}

def serialize(nodes):
    out = b''
    for tag, ft, off, size, kids in nodes:
        if tag == 'FORM':
            body = ft.encode() + serialize(kids)
        else:
            body = kids
        out += tag.encode() + struct.pack('>I', len(body)) + body
    return out

def encode(name, value):
    if name in STRING_ID:
        stf, key = value.split(':', 1)
        payload = b'\x01\x01' + stf.encode() + b'\x00\x01' + key.encode() + b'\x00'
    else:
        payload = b'\x01' + value.encode() + b'\x00'
    return name.encode() + b'\x00' + payload

def patch(nodes, patches, hits):
    res = []
    for tag, ft, off, size, kids in nodes:
        if tag == 'FORM':
            res.append((tag, ft, off, size, patch(kids, patches, hits)))
        elif tag == 'XXXX' and b'\x00' in kids:
            name = kids.split(b'\x00', 1)[0].decode('latin-1')
            if name in patches:
                kids = encode(name, patches[name]); hits.add(name)
            res.append((tag, ft, off, size, kids))
        else:
            res.append((tag, ft, off, size, kids))
    return res

def clone(src, dst, patches):
    buf = open(src, 'rb').read()
    nodes = parse(buf)
    assert serialize(nodes) == buf, f'round-trip mismatch for {src}'
    hits = set()
    nodes = patch(nodes, patches, hits)
    missing = set(patches) - hits
    if missing:
        raise SystemExit(f'{src}: properties not found: {sorted(missing)}')
    os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
    open(dst, 'wb').write(serialize(nodes))
    return dst

if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    p = dict(a.split('=', 1) for a in sys.argv[3:])
    print(clone(src, dst, p))
