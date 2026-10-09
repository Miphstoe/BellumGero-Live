#!/usr/bin/env python3
"""cnrm_effects.py <client dir> — which effects use the CNRM (normal map) texture slot, and which TRE supplies them.
Separates stock effects from the ones bg_custom1 added, to show whether the stock client ever renders CNRM."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

root = sys.argv[1]
winner = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        n = e['name'].lower()
        if n.startswith('effect/') and n.endswith('.eft'):
            winner[n] = (tre, e)

def data(tre, e):
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])

rows = []
for n, (tre, e) in sorted(winner.items()):
    d = data(tre, e)
    if b'MRNC' in d:
        ps = sorted(set(m.decode() for m in re.findall(rb'pixel_program/[a-z0-9_]+\.psh', d)))
        rows.append((os.path.basename(tre), n, ps))
for tre, n, ps in rows:
    print(f'{tre}\t{n}\t{" ".join(ps)}')
print(f'# {len(rows)} effects use CNRM', file=sys.stderr)
