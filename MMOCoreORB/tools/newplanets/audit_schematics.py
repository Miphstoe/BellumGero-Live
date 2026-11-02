#!/usr/bin/env python3
"""audit_schematics.py [tre] — cross-check the Hoth client/server pieces that make crafting work.

1. every object/**/*.iff in the TRE has a CRC table entry
2. every client draft schematic (object/draft_schematic/**/shared_*.iff) has a server template lua
3. every server draft schematic template is listed in managers/crafting/schematics.lua
4. every loot schematic item (object/tangible/loot/loot_schematic) points at a draft schematic that exists server-side
5. every draft schematic referenced from loot items / schematics.lua exists in the TRE (so the client can show it)
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import cstb_tool

tre = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'dist', 'bg_custom1_snowglobe_fix.tre')
WT = r'\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth\MMOCoreORB\bin\scripts'
CRC = 'misc/object_template_crc_string_table.iff'

ents = {e['name'].lower(): e for e in read_tre(tre)}
def data(rel):
    e = ents[rel]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])

# 1. CRC coverage
crc_names = set(n.lower() for n in cstb_tool.read_bytes(data(CRC))) if hasattr(cstb_tool, 'read_bytes') else None
if crc_names is None:
    import tempfile
    tmp = os.path.join(tempfile.mkdtemp(), 'crc.iff'); open(tmp, 'wb').write(data(CRC))
    t = cstb_tool.read(tmp)  # name -> crc
    crc_names = set(k.lower() for k in t)
objs = [n for n in ents if n.startswith('object/') and n.endswith('.iff')]
no_crc = [n for n in objs if n not in crc_names]
print(f'1. CRC: {len(objs)} object iffs in TRE, {len(no_crc)} without a CRC entry')
for n in no_crc: print('   ', n)

# server-side files
def walk_lua(sub):
    out = {}
    base = os.path.join(WT, *sub.split('/'))
    for dp, dn, fn in os.walk(base):
        for f in fn:
            if f.endswith('.lua') and f not in ('objects.lua', 'serverobjects.lua'):
                p = os.path.join(dp, f)
                out[p] = open(p, encoding='utf-8', errors='replace').read()
    return out

draft_lua = walk_lua('object/draft_schematic')
server_drafts = set()
for p, s in draft_lua.items():
    for m in re.finditer(r'addTemplate\([^,]+,\s*"(object/draft_schematic/[^"]+\.iff)"', s):
        server_drafts.add(m.group(1).lower())
client_drafts = set(n for n in objs if n.startswith('object/draft_schematic/') and '/shared_' in n)
hoth_client_drafts = set()
for ov in ('build/hoth', 'build/hoth_loot', 'build/hoth_snowglobe_fix'):
    b = os.path.join(HERE, *ov.split('/'))
    for dp, dn, fn in os.walk(b):
        for f in fn:
            rel = os.path.relpath(os.path.join(dp, f), b).replace(chr(92), '/').lower()
            if rel.startswith('object/draft_schematic/') and rel.endswith('.iff'):
                hoth_client_drafts.add(rel)
def unshared(n):  # client shared_x.iff -> server x.iff
    d, f = n.rsplit('/', 1); return d + '/' + f.replace('shared_', '', 1)
missing_server = [n for n in hoth_client_drafts if unshared(n) not in server_drafts]
print(f'\n2. Hoth client draft schematics: {len(hoth_client_drafts)}; without a server template: {len(missing_server)}')
for n in sorted(missing_server): print('   ', n)

# 3. schematics.lua registration
sch = open(os.path.join(WT, 'managers', 'crafting', 'schematics.lua'), encoding='utf-8', errors='replace').read()
listed = set(m.group(1).lower() for m in re.finditer(r'"(object/draft_schematic/[^"]+\.iff)"', sch))
hoth_server_drafts = set(unshared(n) for n in hoth_client_drafts)
not_listed = [n for n in hoth_server_drafts if n not in listed]
print(f'\n3. Hoth server draft schematics: {len(hoth_server_drafts)}; not listed in schematics.lua: {len(not_listed)}')
for n in sorted(not_listed): print('   ', n)

# 4. loot schematic items -> draft
loot_lua = walk_lua('object/tangible/loot/loot_schematic')
bad_targets = []; loot_count = 0
for p, s in loot_lua.items():
    if 'hoth' not in p.lower() and 'snow' not in p.lower() and 'vehicle' not in p.lower():
        pass
    for m in re.finditer(r'targetDraftSchematic\s*=\s*"([^"]+)"', s):
        loot_count += 1
        t = m.group(1).lower()
        if t not in server_drafts:
            bad_targets.append((os.path.relpath(p, WT), t))
print(f'\n4. loot schematic items: {loot_count}; pointing at a draft that has no server template: {len(bad_targets)}')
for p, t in bad_targets: print('   ', p, '->', t)

# 5. every draft schematic the server knows must exist somewhere in the client (stock TREs or this TRE)
client_all = set(ents)
for t2 in walk_tres(r'C:\Dev-BG'):
    if os.path.basename(t2).lower() == 'bg_custom1.tre':
        continue
    for e in read_tre(t2):
        client_all.add(e['name'].lower())
def shared(n):
    d, f = n.rsplit('/', 1); return d + '/shared_' + f
missing_client = sorted(n for n in listed | server_drafts if shared(n) not in client_all)
print(f'\n5. drafts known server-side: {len(listed | server_drafts)}; with no client shared iff anywhere: {len(missing_client)}')
for n in missing_client: print('   ', n)
