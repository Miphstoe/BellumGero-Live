#!/usr/bin/env python3
"""trn_holes.py [trn] — every layer with an AffectorExclude (terrain hole, used for cave entrances): its boundaries and
the nearest top-level snapshot building. A hole with no building over it is a tear you can see/walk out of the world."""
import math, os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])
import cave_points
from move_outposts import layers_with_circle, direct

path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'build', 'hoth', 'terrain', 'hoth.trn')
root = parse(open(path, 'rb').read())
buildings = [n for n in cave_points.snapshot_nodes() if n[1] == 0 and '/building/' in n[2]]


def shapes(kids):
    out = []
    for lst, j in direct(kids, 'BCIR'):
        cx, cz, r, _, _ = struct.unpack_from('<3fif', lst[j][4])
        out.append(('circle', cx, cz, r))
    for lst, j in direct(kids, 'BPOL'):
        d = lst[j][4]
        n = struct.unpack_from('<i', d)[0]
        pts = [struct.unpack_from('<2f', d, 4 + 8 * i) for i in range(n)]
        cx, cz = sum(p[0] for p in pts) / n, sum(p[1] for p in pts) / n
        r = max(math.hypot(p[0] - cx, p[1] - cz) for p in pts)
        out.append(('polygon', cx, cz, r))
    return out


def has_exclude(kids):
    k = kids[0][4] if len(kids) == 1 and kids[0][0] == 'FORM' and kids[0][1].isdigit() else kids
    return any(t == 'FORM' and f == 'AEXC' for t, f, o, s, kk in k)


for parent, i, kids in layers_with_circle(root):
    if not has_exclude(kids):
        continue
    for kind, cx, cz, r in shapes(kids):
        near = min(buildings, key=lambda b: math.hypot(b[4] - cx, b[6] - cz))
        d = math.hypot(near[4] - cx, near[6] - cz)
        flag = 'ok' if d < r + 25 else 'ORPHAN HOLE'
        print(f'{flag:12s} {kind:7s} centre=({cx:.0f}, {cz:.0f}) r={r:.0f}  nearest building {near[2].split("/")[-1]} at {d:.0f} m')
