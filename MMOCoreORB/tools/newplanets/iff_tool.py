#!/usr/bin/env python3
"""iff_tool.py — inspect SWG IFF files (.trn, .ws, .iff datatables).

  python iff_tool.py tree  <file> [maxdepth]   chunk tree with sizes
  python iff_tool.py refs  <file>              asset paths referenced (shader/, appearance/, ...)
  python iff_tool.py trn   <file>              terrain header (map width, chunk width, ...)
  python iff_tool.py table <file>              dump a DTII datatable as TSV
"""
import re
import struct
import sys

def parse(buf, off=0, end=None):
    end = len(buf) if end is None else end
    out = []
    while off + 8 <= end:
        tag = buf[off:off+4].decode('latin-1')
        size = struct.unpack('>I', buf[off+4:off+8])[0]
        if tag == 'FORM':
            ftype = buf[off+8:off+12].decode('latin-1')
            out.append(('FORM', ftype, off, size, parse(buf, off+12, off+8+size)))
        else:
            out.append((tag, None, off, size, buf[off+8:off+8+size]))
        off += 8 + size
    return out

def tree(nodes, depth=0, maxd=99):
    for tag, ft, off, size, kids in nodes:
        if tag == 'FORM':
            print('  '*depth + f'FORM {ft} ({size})')
            if depth < maxd:
                tree(kids, depth+1, maxd)
        else:
            print('  '*depth + f'{tag} ({size})')

REF = re.compile(rb'(?:appearance|shader|texture|terrain|object|sound|clientdata|effect|creation|datatables|snapshot|misc|footprint|interiorlayout|string)/[a-z0-9_/\-\.]+\.(?:sht|apt|msh|mgn|sat|lmg|lod|pob|cmp|dds|tga|iff|prt|eft|trn|ws|snd|flr|lsb|cdf|ans|skt)', re.I)

# LOD/appearance children are stored relative to appearance/ ("mesh/x_l0.msh")
REL = re.compile(rb'(?<![a-z0-9_/])(?:mesh|lod|skeleton|collision|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|skt|cmp|apt|pob|flr)', re.I)

def trn_refs(buf):
    """Terrain shader families list bare shader names (shader/<name>.sht); flora and
    radial families list bare appearance names (appearance/<name>.apt|.prt|.msh)."""
    out = set()
    if not buf.startswith(b'FORM') or buf[8:12] != b'PTAT':
        return out
    def walk(nodes):
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM':
                walk(kids)
            elif tag == 'SFAM' or tag == 'DATA' and False:
                pass
    root = parse(buf)
    def sfams(nodes, inside=False):
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM':
                sfams(kids, inside or ft == 'SGRP')
            elif tag == 'SFAM' and inside:
                strs = re.findall(rb'[a-z0-9_]{3,}', kids)
                # first is the family name, then surface iff (skipped), then shader names
                for s in strs[1:]:
                    s = s.decode().lower()
                    if s not in ('abstract', 'terrain_surface', 'iff'):
                        out.add('shader/%s.sht' % s)
    sfams(root)
    for m in re.finditer(rb'(?<![a-z0-9_/])[a-z0-9_]+\.(?:apt|prt|msh|sat)', buf, re.I):
        out.add('appearance/' + m.group(0).decode('latin-1').lower())
    return out

def refs(buf):
    buf = buf.replace(b'\x5c', b'/')  # shaders may use backslash paths; the client treats them as /
    out = {m.group(0).decode('latin-1').lower() for m in REF.finditer(buf)}
    out |= trn_refs(buf)
    out |= {'appearance/' + m.group(0).decode('latin-1').lower() for m in REL.finditer(buf)}
    return sorted(out)

def find(nodes, path):
    for tag, ft, off, size, kids in nodes:
        key = ft if tag == 'FORM' else tag
        if key == path[0]:
            if len(path) == 1:
                return kids
            if tag == 'FORM':
                r = find(kids, path[1:])
                if r is not None:
                    return r
    return None

def trn(buf):
    root = parse(buf)
    ptat = root[0][4]
    ver = ptat[0][1]
    data = find(ptat[0][4], ['DATA'])
    name_end = data.index(b'\0')
    name = data[:name_end].decode('latin-1')
    f = struct.unpack_from('<ffIIff', data, name_end+1)
    print(f'version {ver}  name "{name}"')
    print(f'mapWidth {f[0]:.0f}m  chunkWidth {f[1]}  numberOfTilesPerChunk {f[2]}  useGlobalWaterTable {f[3]}  globalWaterHeight {f[4]}  tileWidth {f[5]}')

def table(buf):
    root = parse(buf)
    dtii = root[0][4][0][4]
    cols = find(dtii, ['COLS']); typ = find(dtii, ['TYPE']); rows = find(dtii, ['ROWS'])
    ncol = struct.unpack_from('<I', cols)[0]
    names = cols[4:].split(b'\0')[:ncol]
    types = typ.split(b'\0')[:ncol]
    print('\t'.join(n.decode() for n in names))
    nrow = struct.unpack_from('<I', rows)[0]; p = 4
    for _ in range(nrow):
        vals = []
        for t in types:
            c = chr(t[0]).lower()
            if c in 'ibhe' or c == 'z':
                vals.append(str(struct.unpack_from('<i', rows, p)[0])); p += 4
            elif c == 'f':
                vals.append(f'{struct.unpack_from("<f", rows, p)[0]:g}'); p += 4
            else:
                e = rows.index(b'\0', p); vals.append(rows[p:e].decode('latin-1')); p = e+1
        print('\t'.join(vals))

if __name__ == '__main__':
    cmd, fn = sys.argv[1], sys.argv[2]
    buf = open(fn, 'rb').read()
    if cmd == 'tree':
        tree(parse(buf), maxd=int(sys.argv[3]) if len(sys.argv) > 3 else 99)
    elif cmd == 'refs':
        print('\n'.join(refs(buf)))
    elif cmd == 'trn':
        trn(buf)
    elif cmd == 'table':
        table(buf)


def ws_objects(buf):
    """Yield (objId, parentId, template, x, y(height), z) from a .ws snapshot."""
    root = parse(buf)
    body = root[0][4][0][4]              # FORM WSNP / FORM 0001
    otnl = find(body, ['OTNL'])
    n = struct.unpack_from('<I', otnl)[0]
    names = otnl[4:].split(b'\0')[:n]
    names = [x.decode('latin-1') for x in names]
    out = []

    def walk(nodes):
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM' and ft == 'NODE':
                data = find(kids, ['0000', 'DATA'])
                if data and len(data) >= 52:
                    oid, pid, ni, cell, qw, qx, qy, qz, x, y, z = struct.unpack_from('<iiii7f', data)
                    out.append((oid, pid, names[ni] if 0 <= ni < len(names) else '?', x, y, z))
                walk(kids)
            elif tag == 'FORM':
                walk(kids)
    walk(body)
    return out
