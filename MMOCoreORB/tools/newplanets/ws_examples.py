#!/usr/bin/env python3
"""ws_examples.py [filter...] — for every snapshot template matching a filter: count, node DATA layout (all fields),
yaw of a few examples and the typical spacing to the nearest node of the same template (≈ wall segment length)."""
import math, os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import move_outposts as mo

flt = sys.argv[1:] or ['wall', 'column', 'turret']
_, nodes = mo.ws_nodes(open(mo.SRC_WS, 'rb').read())
by = {}
for n in nodes:
    if n['pid'] == 0 and any(f in n['tmpl'] for f in flt):
        by.setdefault(n['tmpl'], []).append(n)
for t, ns in sorted(by.items()):
    d = ns[0]['ref'][0][ns[0]['ref'][1]][4]
    f = struct.unpack_from('<4i7f', d)
    rest = d[44:]
    print(f'{t}  x{len(ns)}  DATA {len(d)} bytes  tail={rest.hex(" ", 4)}')
    gaps = []
    for a in ns:
        others = [math.hypot(a['x'] - b['x'], a['y'] - b['y']) for b in ns if b is not a]
        if others:
            gaps.append(min(others))
    gaps.sort()
    if gaps:
        print(f'    nearest same-template spacing: median {gaps[len(gaps)//2]:.1f} m, min {gaps[0]:.1f}')
    for a in ns[:3]:
        dd = a['ref'][0][a['ref'][1]][4]
        qw, qx, qy, qz = struct.unpack_from('<4f', dd, 16)
        yaw = math.degrees(2 * math.atan2(qy, qw))
        print(f'    ({a["x"]:.1f}, {a["h"]:.1f}, {a["y"]:.1f}) quat=({qw:.3f},{qx:.3f},{qy:.3f},{qz:.3f}) yaw={yaw:.0f}')
