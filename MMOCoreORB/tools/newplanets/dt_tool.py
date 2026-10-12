#!/usr/bin/env python3
"""dt_tool.py — read/modify/write SWG DTII datatables (int/float/string columns)."""
import struct
import sys

def _chunk(tag, data):
    return tag.encode() + struct.pack('>I', len(data)) + data

def _form(ftype, body):
    return _chunk('FORM', ftype.encode() + body)

def read(path):
    exec(open(__file__.replace('dt_tool.py', 'iff_tool.py')).read().split("if __name__")[0], g := {})
    buf = open(path, 'rb').read()
    root = g['parse'](buf)
    ver = root[0][4][0][1]
    body = root[0][4][0][4]
    get = lambda t: next(k for tag, ft, o, s, k in body if tag == t)
    cols, typ, rows = get('COLS'), get('TYPE'), get('ROWS')
    n = struct.unpack_from('<I', cols)[0]
    names = [x.decode('latin-1') for x in cols[4:].split(b'\0')[:n]]
    types = [x.decode('latin-1') for x in typ.split(b'\0')[:n]]
    nrow = struct.unpack_from('<I', rows)[0]
    p, data = 4, []
    for _ in range(nrow):
        r = []
        for t in types:
            c = t[0].lower()
            if c in 'ibhez':
                r.append(struct.unpack_from('<i', rows, p)[0]); p += 4
            elif c == 'f':
                r.append(struct.unpack_from('<f', rows, p)[0]); p += 4
            else:
                e = rows.index(b'\0', p); r.append(rows[p:e].decode('latin-1')); p = e + 1
        data.append(r)
    return {'version': ver, 'names': names, 'types': types, 'rows': data}

def write(t, path):
    cols = struct.pack('<I', len(t['names'])) + b''.join(n.encode('latin-1') + b'\0' for n in t['names'])
    typ = b''.join(x.encode('latin-1') + b'\0' for x in t['types'])
    rows = struct.pack('<I', len(t['rows']))
    for r in t['rows']:
        for v, ty in zip(r, t['types']):
            c = ty[0].lower()
            if c in 'ibhez':
                rows += struct.pack('<i', v)
            elif c == 'f':
                rows += struct.pack('<f', v)
            else:
                rows += v.encode('latin-1') + b'\0'
    body = _chunk('COLS', cols) + _chunk('TYPE', typ) + _chunk('ROWS', rows)
    open(path, 'wb').write(_form('DTII', _form(t['version'], body)))

if __name__ == '__main__':
    t = read(sys.argv[1]); write(t, sys.argv[2])
