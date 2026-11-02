#!/usr/bin/env python3
"""stage_missing.py <out_dir> <root path>... — follow every asset reference from the given roots through the BG client
(plus our overlays); for every file that exists nowhere there but exists in the Infinity client, extract it (and what it
references, recursively) into out_dir. Written for the Hoth snow globes, whose component lods/meshes/shaders/textures were
never staged (the old chain_check lookbehind hid them, 2026-10-12)."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import gen_hoth_vehicles as V

out = sys.argv[1]
roots = [r.lower() for r in sys.argv[2:]]
OVERLAYS = [os.path.join(HERE, 'build', 'hoth'), os.path.join(HERE, 'build', 'hoth_loot'), out]
BG = r'C:\Dev-BG'
INF = r'C:\SWG Infinity\Live'


def winners(root, skip_custom=False):
    w = {}
    for tre in walk_tres(root):
        if skip_custom and os.path.basename(tre).lower() == 'bg_custom1.tre':
            continue
        for e in read_tre(tre):
            w[e['name'].lower()] = (tre, e)
    return w


bg = winners(BG, skip_custom=True)
inf = winners(INF)


def overlay_file(rel):
    for o in OVERLAYS:
        p = os.path.join(o, *rel.split('/'))
        if os.path.exists(p):
            return p
    return None


def read_rel(rel):
    p = overlay_file(rel)
    if p:
        return open(p, 'rb').read()
    if rel in bg:
        tre, e = bg[rel]
    elif rel in inf:
        tre, e = inf[rel]
    else:
        return None
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])


def refs(rel, d):
    found = []
    for m in V.PATH_RE.findall(d):
        found.append(m.decode('latin-1').lower().replace(chr(92), '/'))
    if rel.endswith(('.lmg', '.lod', '.apt', '.sat', '.cmp')):
        for m in re.findall(rb'(?:mesh|lod|skeleton|collision|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|skt|cmp|apt|flr)', d, re.I):
            found.append('appearance/' + m.decode('latin-1').lower())
    return found


seen, queue, staged, absent = set(), list(roots), [], []
while queue:
    rel = queue.pop()
    if rel in seen:
        continue
    seen.add(rel)
    have_bg = overlay_file(rel) or rel in bg
    if not have_bg:
        if rel in inf:
            tre, e = inf[rel]
            extract_entry(tre, e, out); staged.append(rel)
        else:
            absent.append(rel); continue
    if rel.endswith(('.dds', '.wav', '.tga')):
        continue
    d = read_rel(rel)
    if d is None:
        continue
    queue.extend(refs(rel, d))

print(len(seen), 'files walked;', len(staged), 'staged from Infinity into', out)
for s in sorted(staged):
    print('  +', s)
print(len(absent), 'referenced but in neither client:')
for s in sorted(absent):
    print('  -', s)
