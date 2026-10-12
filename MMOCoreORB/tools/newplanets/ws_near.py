#!/usr/bin/env python3
"""ws_near.py [ws file] — top-level snapshot objects grouped by the nearest outpost (within 600 m), with template counts and
extent. Default ws: build/hoth/snapshot/hoth.ws."""
import os, sys, math, collections
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import cave_points

OUTPOSTS = {'scavenger': (0.0, -2000.0), 'imperial': (5927.6, -406.5), 'rebel': (4525.0, 1164.0)}
nodes = cave_points.snapshot_nodes()
top = [n for n in nodes if n[1] == 0]
print(f'{len(nodes)} nodes, {len(top)} top-level')
for name, (ox, oy) in OUTPOSTS.items():
    near = [n for n in top if math.hypot(n[4] - ox, n[6] - oy) < 600]
    if not near:
        print(f'\n{name}: nothing'); continue
    far = max(math.hypot(n[4] - ox, n[6] - oy) for n in near)
    hs = [n[5] for n in near]
    print(f'\n{name}: {len(near)} objects, max dist {far:.0f} m, height {min(hs):.1f}..{max(hs):.1f}')
    for t, c in collections.Counter(n[2] for n in near).most_common(12):
        print(f'   {c:3d}  {t}')
others = [n for n in top if all(math.hypot(n[4] - ox, n[6] - oy) >= 600 for ox, oy in OUTPOSTS.values())]
print(f'\nelsewhere: {len(others)} objects')
for t, c in collections.Counter(n[2] for n in others).most_common(15):
    print(f'   {c:3d}  {t}')
