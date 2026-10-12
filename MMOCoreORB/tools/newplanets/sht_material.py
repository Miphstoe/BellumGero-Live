#!/usr/bin/env python3
"""sht_material.py <client dir> <shader path>... — decode the MATL block (ambient/diffuse/emissive/specular RGBA + power) of each .sht."""
import os, re, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

root = sys.argv[1]; want = [w.lower().replace('\\', '/') for w in sys.argv[2:]]
winner = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        if e['name'].lower() in want:
            winner[e['name'].lower()] = (tre, e)
for w in want:
    if w not in winner:
        print(f'{w}: MISSING'); continue
    tre, e = winner[w]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    d = _inflate(blob, e['comp'], e['size'])
    i = d.find(b'MATL')
    if i < 0:
        print(f'{w}: no MATL'); continue
    size = struct.unpack_from('>I', d, i + 4)[0]
    v = struct.unpack_from('<%df' % (size // 4), d, i + 8)
    eff = re.findall(rb'effect[/\\][a-z0-9_\-\.]+\.eft', d, re.I)
    print(f'{w} [{os.path.basename(tre)}] effect={eff[0].decode() if eff else None}')
    print('   MATL', ' '.join(f'{x:.3f}' for x in v))
