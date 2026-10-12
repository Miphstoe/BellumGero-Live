#!/usr/bin/env python3
"""vehicle_materials.py — for each vehicle, list the effects its shaders use (from the staged mesh/shader chain)."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import gen_hoth_vehicles as V

OUT = os.path.join(HERE, 'build', 'hoth_loot')
BG = os.path.join(HERE, 'build', 'hoth')
PATH = re.compile(rb'(?:appearance|shader)/[a-z0-9_/\-\.]+\.(?:apt|sat|lmg|mgn|msh|lod|sht|cmp)', re.I)
REL = re.compile(rb'(?<![a-z0-9_/])(?:mesh|lod|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|cmp|apt)', re.I)
EFF = re.compile(rb'effect[\\/]([a-z0-9_\-\.]+)\.eft', re.I)


def local(rel):
    for root in (OUT, BG):
        p = os.path.join(root, *rel.split('/'))
        if os.path.exists(p):
            return p
    return None


def effects_for(roots):
    seen, queue, effs = set(), list(roots), {}
    while queue:
        rel = queue.pop().lower()
        if rel in seen:
            continue
        seen.add(rel)
        p = local(rel)
        if p is None:
            continue
        d = open(p, 'rb').read()
        if rel.endswith('.sht'):
            for m in EFF.findall(d):
                effs.setdefault(m.decode('latin-1').lower(), []).append(rel.rsplit('/', 1)[1])
            continue
        for m in PATH.findall(d):
            queue.append(m.decode('latin-1'))
        for m in REL.findall(d):
            queue.append('appearance/' + m.decode('latin-1'))
    return effs


for v in V.VEHICLES:
    mob = local(V.mob_client(v))
    app = V.appearance_of(mob) if mob else None
    effs = effects_for([app, v[6]] if app else [v[6]])
    flags = []
    if any('bloom' in e for e in effs): flags.append('BLOOM')
    if any('envmask' in e for e in effs): flags.append('ENVMAP')
    if any('emis' in e for e in effs): flags.append('EMISSIVE')
    print(f"{v[1]:30s} {' '.join(flags):22s} {sorted(effs)}")
