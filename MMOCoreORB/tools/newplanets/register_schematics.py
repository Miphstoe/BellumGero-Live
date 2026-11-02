#!/usr/bin/env python3
"""register_schematics.py <server bin/scripts dir> [overlay_dir ...] — make sure every Hoth draft schematic is listed in
managers/crafting/schematics.lua (SchematicMap only knows drafts from that list; an unlisted draft can be neither learned
from a loot schematic nor crafted). Idempotent: appends only what is missing, as one "Bellum Gero Hoth" block before the
closing `};`. Drafts are discovered from the client overlays (object/draft_schematic/**/shared_*.iff -> the server path).
Found 2026-10-12: all 64 Hoth drafts were missing, so no Hoth schematic worked."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))

scripts = sys.argv[1]
overlays = sys.argv[2:] or [os.path.join(HERE, 'build', 'hoth'), os.path.join(HERE, 'build', 'hoth_loot')]
lua = os.path.join(scripts, 'managers', 'crafting', 'schematics.lua')

drafts = set()
for ov in overlays:
    for dp, dn, fn in os.walk(ov):
        for f in fn:
            rel = os.path.relpath(os.path.join(dp, f), ov).replace(chr(92), '/').lower()
            if rel.startswith('object/draft_schematic/') and rel.endswith('.iff') and '/shared_' in rel:
                d, b = rel.rsplit('/', 1)
                drafts.add(d + '/' + b.replace('shared_', '', 1))

# only register drafts that have a server template, so the map never points at nothing
server = set()
for dp, dn, fn in os.walk(os.path.join(scripts, 'object', 'draft_schematic')):
    for f in fn:
        if f.endswith('.lua'):
            s = open(os.path.join(dp, f), encoding='utf-8', errors='replace').read()
            server.update(m.group(1).lower() for m in re.finditer(r'addTemplate\([^,]+,\s*"(object/draft_schematic/[^"]+\.iff)"', s))
no_server = sorted(d for d in drafts if d not in server)
drafts = sorted(d for d in drafts if d in server)

s = open(lua, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
listed = set(m.group(1).lower() for m in re.finditer(r'\{path="([^"]+)"\}', s))
missing = [d for d in drafts if d not in listed]
print(f'{len(drafts)} Hoth drafts, {len(missing)} missing from schematics.lua, {len(no_server)} skipped (no server template)')
for d in no_server:
    print('  skipped', d)
if not missing:
    sys.exit(0)

groups = [('armor', lambda p: '/clothing/' in p), ('paintings', lambda p: '/furniture/' in p), ('vehicles', lambda p: '/vehicle/' in p), ('other', lambda p: True)]
block = [nl, '\t-- Bellum Gero Hoth schematics (register_schematics.py): learned from Hoth loot schematics']
done = set()
for name, test in groups:
    items = [d for d in missing if test(d) and d not in done]
    if not items:
        continue
    done.update(items)
    block.append(f'\t-- Hoth {name}')
    block.extend(f'\t{{path="{d}"}},' for d in items)
end = s.rstrip().rfind('};')
assert end > 0, 'no closing }; in schematics.lua'
s = s[:end].rstrip() + nl + nl.join(block) + nl + s[end:]
open(lua, 'w', encoding='utf-8', newline='').write(s)
for d in missing:
    print('  +', d)
