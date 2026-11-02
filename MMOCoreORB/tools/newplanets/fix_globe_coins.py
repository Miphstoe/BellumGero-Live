#!/usr/bin/env python3
"""fix_globe_coins.py [factor] — the Battle of Hoth snow globe effect (pt_snow_globe_gcw.prt) spawns the stock glowing
Imperial/Rebel coin meshes as particles at scale 0.15, but the BG client ignores the mesh-particle scale and draws the
0.7 m coins full size (2026-10-12). Make pre-scaled copies of the coins (pt_glowing_*_coin_sm) and point the effect at
them with its scale set to 1.0. Writes into build/hoth_snowglobe_fix."""
import os, re, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])
from iff_clone import serialize
from wke_robes_lib import rewrite_strings

FACTOR = float(sys.argv[1]) if len(sys.argv) > 1 else 0.15
OUT = os.path.join(HERE, 'build', 'hoth_snowglobe_fix')
bg = {}
for tre in walk_tres(r'C:\Dev-BG'):
    if os.path.basename(tre).lower() == 'bg_custom1.tre':
        continue
    for e in read_tre(tre):
        bg[e['name'].lower()] = (tre, e)
inf = {}
for tre in walk_tres(r'C:\SWG Infinity\Live'):
    for e in read_tre(tre):
        inf[e['name'].lower()] = (tre, e)


def get(w, n):
    tre, e = w[n]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); b = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(b, e['comp'], e['size'])


def put(rel, data):
    p = os.path.join(OUT, *rel.split('/')); os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'wb').write(data)


def scale_floats(data, n, k):
    return struct.pack('<%df' % n, *[v * k for v in struct.unpack_from('<%df' % n, data, 0)]) + data[4 * n:]


def scale_tree(nodes, k):
    """scale SPHR (centre+radius), BOX (6 floats) and VTXA vertex positions in place"""
    out = []
    for t, ft, off, size, kids in nodes:
        if t == 'FORM':
            if ft == '0003' and any(c[0] == 'INFO' for c in kids) and any(c[0] == 'DATA' for c in kids) and len(kids) == 2:
                info = next(c for c in kids if c[0] == 'INFO'); data = next(c for c in kids if c[0] == 'DATA')
                flags, count = struct.unpack_from('<II', info[4], 0)
                stride = len(data[4]) // count
                assert stride * count == len(data[4]) and stride >= 12, (stride, count)
                buf = bytearray(data[4])
                for i in range(count):
                    x, y, z = struct.unpack_from('<3f', buf, i * stride)
                    struct.pack_into('<3f', buf, i * stride, x * k, y * k, z * k)
                kids = [(c[0], c[1], c[2], c[3], bytes(buf) if c[0] == 'DATA' else c[4]) for c in kids]
                out.append((t, ft, off, size, kids))
            else:
                out.append((t, ft, off, size, scale_tree(kids, k)))
        elif t == 'SPHR':
            out.append((t, ft, off, size, scale_floats(kids, 4, k)))
        elif t == 'BOX ':
            out.append((t, ft, off, size, scale_floats(kids, 6, k)))
        else:
            out.append((t, ft, off, size, kids))
    return out


made = []
for side in ('imperial', 'rebel'):
    base = f'pt_glowing_{side}_coin'; new = base + '_sm'
    subs = [(f'{base}_l'.encode(), f'{new}_l'.encode()), (f'{base}.lod'.encode(), f'{new}.lod'.encode())]
    for lod in range(4):
        rel = f'appearance/mesh/{base}_l{lod}.msh'
        if rel not in bg:
            continue
        put(f'appearance/mesh/{new}_l{lod}.msh', serialize(scale_tree(parse(get(bg, rel)), FACTOR))); made.append(f'{new}_l{lod}.msh')
    put(f'appearance/lod/{new}.lod', rewrite_strings(serialize(scale_tree(parse(get(bg, f'appearance/lod/{base}.lod')), FACTOR)), subs)); made.append(f'{new}.lod')
    put(f'appearance/{new}.apt', rewrite_strings(get(bg, f'appearance/{base}.apt'), subs)); made.append(f'{new}.apt')

# the effect: small coins, scale 1.0
prt = get(inf, 'appearance/pt_snow_globe_gcw.prt')
prt = rewrite_strings(prt, [(b'appearance/pt_glowing_imperial_coin.apt', b'appearance/pt_glowing_imperial_coin_sm.apt'),
                            (b'appearance/pt_glowing_rebel_coin.apt', b'appearance/pt_glowing_rebel_coin_sm.apt')])
fixed = [0]


# the scale waveform is the first WVFM/0002 leaf after each PTMH mesh reference; set its 0.15 keys to 1.0
def walk_prt(nodes, in_ptmh=False, state=None):
    state = state if state is not None else {'armed': False}
    out = []
    for t, ft, off, size, kids in nodes:
        if t == 'FORM':
            out.append((t, ft, off, size, walk_prt(kids, in_ptmh or ft == 'PTMH', state)))
        elif t == '0000' and in_ptmh and b'_coin_sm.apt' in kids:
            state['armed'] = True; out.append((t, ft, off, size, kids))
        elif t == '0002' and in_ptmh and state['armed'] and len(kids) == 52:
            raw = struct.unpack_from('<13f', kids, 0)
            fixed[0] += sum(1 for v in raw if abs(v - 0.15) < 1e-6)
            out.append((t, ft, off, size, struct.pack('<13f', *[1.0 if abs(v - 0.15) < 1e-6 else v for v in raw]))); state['armed'] = False
        else:
            out.append((t, ft, off, size, kids))
    return out


prt = serialize(walk_prt(parse(prt)))
put('appearance/pt_snow_globe_gcw.prt', prt); made.append('pt_snow_globe_gcw.prt')
print('factor', FACTOR, '| wrote', len(made), 'files:', made)
print('scale values changed 0.15 -> 1.0:', fixed[0])
print('prt refs:', [s.decode() for s in re.findall(rb'appearance/[a-z0-9_]+\.apt', prt)])
for side in ('imperial', 'rebel'):
    d = open(os.path.join(OUT, 'appearance', 'mesh', f'pt_glowing_{side}_coin_sm_l0.msh'), 'rb').read()
    i = d.find(b'BOX '); print(side, 'coin_sm box:', [round(v, 3) for v in struct.unpack_from('<6f', d, i + 8)])
