#!/usr/bin/env python3
"""shader_check.py <tre> <appearance root>... — list every shader reached from the roots, its effect and textures, and
flag anything the client cannot resolve (file missing) or that uses an effect the stock client does not ship."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
from iff_tool import parse

tre_path = sys.argv[1]; roots = [r.lower() for r in sys.argv[2:]]
client = {}
stock = set()
for tre in walk_tres(r'C:\Dev-BG'):
    if os.path.basename(tre).lower() == 'bg_custom1.tre':
        continue
    for e in read_tre(tre):
        client[e['name'].lower()] = (tre, e); stock.add(e['name'].lower())
for e in read_tre(tre_path):
    client[e['name'].lower()] = (tre_path, e)


def data(rel):
    tre, e = client[rel]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])


PATH = re.compile(rb'(?:appearance|shader|texture|effect)/[a-z0-9_/\-\.]+\.(?:apt|sat|lmg|mgn|msh|lod|skt|sht|dds|eft|cmp)', re.I)
REL = re.compile(rb'(?<![a-z0-9_/])(?:mesh|lod|skeleton|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|skt|cmp|apt)', re.I)
seen, queue, shaders = set(), list(roots), []
while queue:
    rel = queue.pop()
    if rel in seen or rel not in client:
        continue
    seen.add(rel)
    if rel.endswith(('.dds', '.eft')):
        continue
    d = data(rel)
    if rel.endswith('.sht'):
        shaders.append(rel)
        continue
    for m in PATH.findall(d):
        queue.append(m.decode('latin-1').lower())
    for m in REL.findall(d):
        queue.append('appearance/' + m.decode('latin-1').lower())


def shader_info(rel):
    d = data(rel)
    effect = [m.decode('latin-1') for m in re.findall(rb'effect/[a-z0-9_\-\.]+\.eft', d, re.I)]
    # TXM chunks: tag (4 chars) + texture name
    texs = []
    def walk(n):
        for tag, ft, off, size, kids in n:
            if tag == 'FORM':
                walk(kids)
            elif tag == 'NAME' and b'texture/' in kids:
                texs.append(kids.split(b'\x00')[0].decode('latin-1'))
    walk(parse(d))
    tags = [m.decode('latin-1') for m in re.findall(rb'TAG\s\x00\x00\x00\x04([A-Z0-9 ]{4})', d)]
    return effect, texs, tags


for s in sorted(shaders):
    effect, texs, tags = shader_info(s)
    problems = []
    for e in effect:
        if e.lower() not in client:
            problems.append(f'effect missing: {e}')
        elif e.lower() not in stock:
            problems.append(f'effect not stock (ported): {e}')
    for t in texs:
        if t.lower() not in client:
            problems.append(f'texture missing: {t}')
    print(f'{s}\n    effect={effect} tags={tags}\n    textures={texs}' + (('\n    !! ' + '; '.join(problems)) if problems else ''))
