#!/usr/bin/env python3
"""tre_compare.py <tre A> <tre B> <path>... — size and md5 of each path in two TREs (A vs B), to show what an overlay changed."""
import hashlib, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

def load(path, want):
    out = {}
    for e in read_tre(path):
        n = e['name'].lower()
        if n in want:
            with open(path, 'rb') as f:
                f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
            d = _inflate(blob, e['comp'], e['size'])
            out[n] = (len(d), hashlib.md5(d).hexdigest()[:10])
    return out

want = {w.lower().replace('\\', '/') for w in sys.argv[3:]}
a, b = load(sys.argv[1], want), load(sys.argv[2], want)
for w in sorted(want):
    ra, rb = a.get(w), b.get(w)
    flag = 'same' if ra == rb else 'DIFF'
    print(f'{flag}\t{w}\tA={ra}\tB={rb}')
