#!/usr/bin/env python3
"""trn_layers.py [trn] — print the terrain layer tree: layer names, circle/rectangle boundaries (centre, radius/extent,
feather) and constant-height affectors (height). Default: build/hoth/terrain/hoth.trn."""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])

path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'build', 'hoth', 'terrain', 'hoth.trn')
root = parse(open(path, 'rb').read())


def header(kids):
    """IHDR -> (enabled, name)"""
    for tag, ft, off, size, k in kids:
        if tag == 'FORM' and ft == 'IHDR':
            d = find(k, ['0001', 'DATA'])
            if d:
                return struct.unpack_from('<i', d)[0], d[4:].split(b'\0')[0].decode('latin-1')
    return None, '?'


def data_of(kids):
    for tag, ft, off, size, k in kids:
        if tag == 'FORM' and ft.isdigit():
            for t2, f2, o2, s2, k2 in k:
                if t2 == 'DATA':
                    return k2
    return b''


def walk(nodes, depth):
    for tag, ft, off, size, kids in nodes:
        if tag != 'FORM':
            continue
        if ft == 'LAYR':
            en, name = header(kids)
            print('  ' * depth + f'LAYR "{name}"' + ('' if en else ' (disabled)'))
            walk(kids, depth + 1)
        elif ft in ('BCIR', 'BREC', 'BPOL', 'AHCN', 'FHGT', 'FSLP', 'AHFR', 'AFSC', 'AFSN', 'ACCN', 'AENV', 'AEXC', 'ACRF'):
            en, name = header(kids)
            d = data_of([k for k in kids if not (k[0] == 'FORM' and k[1] == 'IHDR')])
            info = ''
            if ft == 'BCIR' and len(d) >= 20:
                cx, cz, r, ftype, famt = struct.unpack_from('<3fif', d)
                info = f'centre=({cx:.0f}, {cz:.0f}) r={r:.0f} feather={famt:.2f}'
            elif ft == 'BREC' and len(d) >= 16:
                x0, z0, x1, z1 = struct.unpack_from('<4f', d)
                info = f'x {x0:.0f}..{x1:.0f}  z {z0:.0f}..{z1:.0f}'
            elif ft == 'AHCN' and len(d) >= 8:
                op, h = struct.unpack_from('<if', d)
                info = f'height={h:.1f} op={op}'
            print('  ' * depth + f'{ft} "{name}" {info}' + ('' if en or en is None else ' (disabled)'))
            if ft in ('BCIR', 'BREC', 'BPOL'):
                continue
            walk(kids, depth + 1)
        else:
            walk(kids, depth)


walk(root, 0)
