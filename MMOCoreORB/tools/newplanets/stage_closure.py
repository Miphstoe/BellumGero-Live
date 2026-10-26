#!/usr/bin/env python3
"""stage_closure.py <closure.tsv> <out_dir> [already_dir] — extract every 'port' path from the Infinity client into out_dir,
skipping paths that already exist byte-identical under already_dir (e.g. build/hoth)."""
import os, sys, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
SRC = r'C:\SWG Infinity\Live'
def winners(root):
    w = {}
    for tre in walk_tres(root):
        for e in read_tre(tre):
            w[e['name'].lower()] = (tre, e)
    return w
tsv, out = sys.argv[1], sys.argv[2]
already = sys.argv[3] if len(sys.argv) > 3 else None
src = winners(SRC)
n = skipped = 0
for line in open(tsv):
    p, tre, st = line.rstrip('\n').split('\t')
    if st != 'port': continue
    tre, e = src[p]
    if already and os.path.exists(os.path.join(already, *p.split('/'))):
        skipped += 1; continue
    extract_entry(tre, e, out); n += 1
print(f'staged {n} files into {out}, skipped {skipped} already in {already}')
