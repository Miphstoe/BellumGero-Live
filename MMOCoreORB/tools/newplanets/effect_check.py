#!/usr/bin/env python3
"""effect_check.py [--stage] — list the effects (effect\\x.eft, note the backslash) referenced by every staged shader and
whether the Dev-BG stock client has them; with --stage, copy missing effects from Infinity into build/hoth_loot."""
import os, re, glob, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)


def listing(name, skip_custom=False):
    out = set()
    for l in open(os.path.join(HERE, name), encoding='utf-8', errors='replace'):
        p = l.rstrip('\n').split('\t')
        if len(p) >= 2 and not (skip_custom and 'bg_custom1' in p[0].lower()):
            out.add(p[1].lower())
    return out


stock = listing('devbg_all.txt', skip_custom=True)
livebg = listing('bg_all.txt')
inf = listing('infinity_all.txt')
EFF = re.compile(rb'effect[\\/][a-z0-9_\-\.]+\.eft', re.I)
eff = {}
for d in ('build/hoth_loot/shader', 'build/hoth/shader'):
    for f in glob.glob(os.path.join(HERE, d, '*.sht')):
        for m in EFF.findall(open(f, 'rb').read()):
            eff.setdefault(m.decode('latin-1').replace('\\', '/').lower(), set()).add(os.path.basename(f))
print(f'{len(eff)} distinct effects referenced by staged shaders')
missing = []
for e, users in sorted(eff.items()):
    present = os.path.exists(os.path.join(HERE, 'build', 'hoth_loot', *e.split('/'))) or os.path.exists(os.path.join(HERE, 'build', 'hoth', *e.split('/')))
    st = 'stock' if e in stock else ('liveBG-only' if e in livebg else 'MISSING')
    if st != 'stock' and not present:
        missing.append(e)
    print(f"{e:50s} {st:12s} infinity={'y' if e in inf else 'n'} overlay={'y' if present else 'n'}  {len(users)} shaders e.g. {sorted(users)[0]}")
if '--stage' in sys.argv and missing:
    import gen_hoth_loot_client as c
    for e in missing:
        if e in inf:
            c.inf_file(e, c.OUT); print('staged', e)
        else:
            print('cannot stage (not in Infinity):', e)
