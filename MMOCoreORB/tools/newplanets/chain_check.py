#!/usr/bin/env python3
"""chain_check.py <tre> <root path>... — walk every asset reference starting at the roots inside one TRE (plus the stock
client TREs in C:\\Dev-BG for the base game) and report references that resolve nowhere. Follows IFF string refs,
appearance/-relative LOD children, .snd -> sample .wav, .sat -> .lat -> .ans."""
import os, re, sys, zlib
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import gen_hoth_vehicles as V

tre_path = sys.argv[1]
roots = sys.argv[2:]
client = {}
for tre in walk_tres(r'C:\Dev-BG'):
    if os.path.basename(tre).lower() == 'bg_custom1.tre':
        continue
    for e in read_tre(tre):
        client[e['name'].lower()] = (tre, e)
for e in read_tre(tre_path):  # the TRE under test wins
    client[e['name'].lower()] = (tre_path, e)


def data(rel):
    tre, e = client[rel]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])


seen, queue, missing = set(), [r.lower() for r in roots], {}
while queue:
    rel = queue.pop()
    if rel in seen:
        continue
    seen.add(rel)
    if rel not in client:
        missing.setdefault(rel, 0); missing[rel] += 1
        continue
    if rel.endswith(('.dds', '.wav', '.tga')):
        continue
    d = data(rel)
    for m in V.PATH_RE.findall(d):
        queue.append(m.decode('latin-1').lower())
    if rel.endswith('.snd'):
        for w in re.findall(rb'[a-z0-9_\-\.]+\.wav', d, re.I):
            queue.append('sample/' + w.decode('latin-1').lower())
    if rel.endswith(('.lmg', '.lod', '.apt', '.sat', '.cmp')):
        for m in re.findall(rb'(?<![a-z0-9_/])(?:mesh|lod|skeleton|collision|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|skt|cmp|apt|flr)', d, re.I):
            queue.append('appearance/' + m.decode('latin-1').lower())
print(f'{len(seen)} files reached from {len(roots)} roots; {len(missing)} missing')
for m in sorted(missing):
    print('  MISSING', m)
