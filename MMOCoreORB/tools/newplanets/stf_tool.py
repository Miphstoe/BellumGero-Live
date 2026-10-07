#!/usr/bin/env python3
"""stf_tool.py — read/write SWG .stf string tables (ordered key -> text)."""
import struct

def read(path):
    b = open(path, 'rb').read()
    magic, flag, next_id, n = struct.unpack_from('<IBII', b, 0)
    o, vals = 13, {}
    for _ in range(n):
        i, crc, l = struct.unpack_from('<III', b, o); o += 12
        vals[i] = (crc, b[o:o + l * 2].decode('utf-16le')); o += l * 2
    keys = []  # key section reuses the value count (no second count)
    for _ in range(n):
        i, l = struct.unpack_from('<II', b, o); o += 8
        keys.append((i, b[o:o + l].decode('latin-1'))); o += l
    return {'magic': magic, 'flag': flag, 'next': next_id, 'vals': vals, 'keys': keys}

def write(t, path):
    out = struct.pack('<IBII', t['magic'], t['flag'], t['next'], len(t['vals']))
    for i, (crc, s) in t['vals'].items():
        out += struct.pack('<III', i, crc, len(s)) + s.encode('utf-16le')
    for i, k in t['keys']:
        out += struct.pack('<II', i, len(k)) + k.encode('latin-1')
    open(path, 'wb').write(out)

def add(t, key, text):
    if any(k == key for _, k in t['keys']):
        raise KeyError('exists: ' + key)
    # Some shipped tables carry a stale 'next' counter (BG's frn_n.stf: next=293 but ids up to 310); never reuse an id.
    i = max([t['next']] + [j + 1 for j, _ in t['keys']])
    t['next'] = i + 1
    t['vals'][i] = (0xFFFFFFFF, text); t['keys'].append((i, key))

def set(t, key, text):
    """Add key, or replace its text if it exists."""
    for i, k in t['keys']:
        if k == key:
            crc, _ = t['vals'][i]
            t['vals'][i] = (crc, text)
            return
    add(t, key, text)

def as_dict(t):
    return {k: t['vals'][i][1] for i, k in t['keys']}
