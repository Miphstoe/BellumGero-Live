#!/usr/bin/env python3
"""psh_audit.py <client dir> [filter] — for every pixel program (optionally containing filter): which TRE wins, whether a
lower-priority TRE also has it (override), the HLSL compiler that built it, and whether it uses hemispheric lighting."""
import os, re, sys, hashlib
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

root = sys.argv[1]; flt = sys.argv[2].lower() if len(sys.argv) > 2 else ''
copies = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        n = e['name'].lower()
        if n.startswith('pixel_program/') and n.endswith('.psh') and flt in n:
            copies.setdefault(n, []).append((tre, e))

def data(tre, e):
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])

def info(tre, e):
    d = data(tre, e)
    comp = re.search(rb'Shader Compiler ([0-9.]+)', d)
    return (comp.group(1).decode() if comp else '?', b'HemisphericLighting' in d, hashlib.md5(d).hexdigest()[:8])

for n in sorted(copies):
    tre, e = copies[n][-1]
    c, hemi, md5 = info(tre, e)
    under = [(os.path.basename(t), info(t, x)) for t, x in copies[n][:-1]]
    under = [f'{t}:{i[0]}{"/hemi" if i[1] else ""}:{i[2]}' for t, i in under if i[2] != md5]
    print(f'{os.path.basename(tre)}\t{n}\tcompiler={c}{"\tHEMI" if hemi else ""}' + (f'\toverrides {" ".join(under)}' if under else ''))
