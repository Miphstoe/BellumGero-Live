#!/usr/bin/env python3
"""poi_audit.py — compare Hoth's POI table (gen_hoth_pois.POIS) with what is actually on the planet: snapshot objects
outside the outposts, outposts/shuttleports, cave buildings, static spawn sites, the world boss. Prints every special
spot and whether a POI covers it."""
import math, os, sys, collections
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import move_outposts as mo
import gen_hoth_pois as gp

pois = [(k, name, x, y, r, 'MAPPOI' in f) for k, name, x, y, r, f in gp.POIS]


def covered(x, y):
    hits = [(name, on_map) for k, name, px, py, r, on_map in pois if math.hypot(x - px, y - py) <= r]
    return hits


_, nodes = mo.ws_nodes(open(mo.OUT_WS, 'rb').read())
top = [n for n in nodes if n['pid'] == 0 and n['oid'] < mo.DEFENSE_OID_BASE]
outposts = {k: m['new'] for k, m in mo.MOVES.items()}
clusters = collections.defaultdict(list)
for n in top:
    near = min(outposts.items(), key=lambda kv: math.hypot(n['x'] - kv[1][0], n['y'] - kv[1][1]))
    if math.hypot(n['x'] - near[1][0], n['y'] - near[1][1]) < 400:
        continue  # part of an outpost
    clusters[(round(n['x'] / 150), round(n['y'] / 150))].append(n)

print('== snapshot objects outside the outposts')
for key, ns in sorted(clusters.items(), key=lambda kv: (kv[1][0]['x'], kv[1][0]['y'])):
    x = sum(n['x'] for n in ns) / len(ns); y = sum(n['y'] for n in ns) / len(ns)
    kinds = collections.Counter(n['tmpl'].split('/')[-1].replace('shared_', '').replace('.iff', '') for n in ns)
    c = covered(x, y)
    print(f'  ({x:7.0f}, {y:6.0f})  {dict(kinds)}  -> {c or "NO POI"}')

print('\n== outposts / shuttleports / boss')
spots = [('Scavenger Outpost', *outposts['scavenger']), ('Imperial Forward Base', *outposts['imperial']),
         ('Rebel Forward Base', *outposts['rebel'])] + \
        [(sp['name'], sp['x'], sp['y']) for sp in mo.SHUTTLEPORTS] + [('Glacial Rancor', 600, -4600)]
for name, x, y in spots:
    print(f'  {name:32s} ({x:7.0f}, {y:6.0f}) -> {covered(x, y) or "NO POI"}')

print('\n== static spawn sites (gen_hoth_mobiles.static_lua)')
import gen_hoth_mobiles as g
for label, (x, y) in [('battlefield squad A', (5654, 1029)), ('battlefield squad B', (5190, 534)),
                      ('raider camp', (5068, 1300)), ('scavenger camp', (-4125, -2127))]:
    print(f'  {label:32s} ({x:7.0f}, {y:6.0f}) -> {covered(x, y) or "NO POI"}')

print('\n== current POI table')
for k, name, x, y, r, on_map in pois:
    print(f'  {k:30s} {name:32s} ({x:6}, {y:6}) r={r:<4} map={"yes" if on_map else "no"}')
