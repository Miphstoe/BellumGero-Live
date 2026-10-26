#!/usr/bin/env python3
"""dep_closure.py — recursive asset dependency closure for a planet.

  python dep_closure.py <planet> <seed file>...     (seed = internal paths)

Resolves every referenced path against the SOURCE client (Infinity) load
order, recursing through object templates, appearances, meshes, shaders.
Writes audit/<planet>_closure.tsv:  path  source_tre  status
  status = in_bg          (target client already has it — skip)
           in_bg_differs  (BG has it but a different size — review!)
           port           (only in source — must go in our TRE)
           missing        (referenced, found nowhere)
"""
import os, sys
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split('if __name__')[0])

OVERRIDE = ('terrain/', 'snapshot/', 'texture/ui_map_')  # always take source version
SRC, DST = r'C:\SWG Infinity\Live', r'C:\BellumGero'

def winners(root):
    w = {}
    for tre in walk_tres(root):
        try:
            for e in read_tre(tre):
                w[e['name'].lower()] = (tre, e)
        except Exception:
            pass
    return w

def read(tre, e):
    with open(tre, 'rb') as f:
        f.seek(e['offset'])
        blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])

def main(planet, seeds):
    src, dst = winners(SRC), winners(DST)
    seen, queue, rows = set(), [s.lower() for s in seeds], []
    while queue:
        p = queue.pop()
        if p in seen:
            continue
        seen.add(p)
        s = src.get(p)
        d = dst.get(p)
        if s is None:
            rows.append((p, '-', 'in_bg' if d else 'missing'))
            data = read(*d) if d else b''
        else:
            if d is None:
                st = 'port'
            elif d[1]['size'] != s[1]['size']:
                st = 'in_bg_differs'
            else:
                st = 'in_bg'
            rows.append((p, os.path.basename(s[0]), st))
            # follow the copy the target client will really load: BG's own
            # version unless this file is one we are porting/overriding
            data = read(*s) if st == 'port' or p.startswith(OVERRIDE) else read(*d)
        if p.endswith(('.dds', '.tga', '.wav', '.mp3', '.snd')):
            continue  # leaves
        for r in refs(data):
            if r not in seen:
                queue.append(r)
    rows.sort()
    os.makedirs(os.path.join(HERE, 'audit'), exist_ok=True)
    with open(os.path.join(HERE, 'audit', f'{planet}_closure.tsv'), 'w') as o:
        o.write('path\tsource_tre\tstatus\n')
        for r in rows:
            o.write('\t'.join(r) + '\n')
    c = Counter(r[2] for r in rows)
    print(f'{planet}: {len(rows)} files  ' + '  '.join(f'{k}={v}' for k, v in sorted(c.items())))
    for r in rows:
        if r[2] == 'missing':
            print('  MISSING', r[0])

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2:])
