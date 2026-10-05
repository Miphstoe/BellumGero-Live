#!/usr/bin/env python3
"""effect_users.py <client dir> <effect name> — every winning .sht that references the effect, with its TRE."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

root, eff = sys.argv[1], sys.argv[2].lower().encode()
win = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        if e['name'].lower().startswith('shader/') and e['name'].lower().endswith('.sht'):
            win[e['name'].lower()] = (tre, e)
for n, (tre, e) in sorted(win.items()):
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    if eff in _inflate(blob, e['comp'], e['size']).lower():
        print(f'{os.path.basename(tre)}\t{n}')
