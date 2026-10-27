#!/usr/bin/env python3
"""stage_taanab.py — fill build/taanab with the Taanab client files.

Infinity/MTG files: every 'port' row of audit/taanab_closure.tsv, the Taanab-specific rows Infinity
replaces (terrain, environment, map) and the shuttle voice lines. BG files: travel.iff, planet_n.stf,
planet_crc_string_table.iff, waypoint_planets.iff and both UI includes, taken from the base TRE with
Taanab added. Then: python tre_pack.py --merge <base> build/taanab <out>.
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); os.chdir(HERE); sys.path.insert(0, HERE)
exec(open('tre_inventory.py').read().split('if __name__')[0])
import cstb_tool, stf_tool, dt_tool

INF = r'C:\SWG Infinity\Live'
BASE = sys.argv[1] if len(sys.argv) > 1 else r'C:\BellumGero\bg_custom1.tre'
OUT = 'build/taanab'
TAKE_INFINITY = {'terrain/taanab.trn', 'terrain/environment/taanab.iff', 'datatables/environment/taanab.iff',
                 'texture/ui_map_taanab.dds'}
VOICE = ['voice/sound/voice_trnspt_%s_taanab.snd' % k for k in ('arriving', 'nextstop', 'welcome')]
FARE_CORE, FARE_HOTH = 1250, 4000

def winners(root):
    w = {}
    for tre in walk_tres(root):
        for e in read_tre(tre):
            w[e['name'].lower()] = (tre, e)
    return w

# --- Infinity files
src = winners(INF)
want = set(TAKE_INFINITY) | set(VOICE)
for line in open('audit/taanab_closure.tsv'):
    p, tre, st = line.rstrip('\r\n').split('\t')
    if st == 'port':
        want.add(p)
for p in sorted(want):
    if p not in src:
        print('NOT IN INFINITY:', p); continue
    extract_entry(*src[p], OUT)
print('infinity files:', len(want))

# --- BG tables from the base TRE
BGX = 'extract/bg_taanab'
bgt = ['datatables/travel/travel.iff', 'string/en/planet_n.stf', 'misc/planet_crc_string_table.iff',
       'datatables/player/waypoint_planets.iff', 'ui/ui_ticketpurchase.inc', 'ui/ui_planet_map.inc',
       'misc/object_template_crc_string_table.iff']
got = set()
for e in read_tre(BASE):
    if e['name'].lower() in bgt:
        extract_entry(BASE, e, BGX); got.add(e['name'].lower())
assert got == set(bgt), set(bgt) - got
def bg(p): return os.path.join(BGX, *p.split('/'))
def out(p):
    q = os.path.join(OUT, *p.split('/')); os.makedirs(os.path.dirname(q), exist_ok=True); return q

t = dt_tool.read(bg('datatables/travel/travel.iff'))
assert 'taanab' not in t['names']
t['names'].append('taanab'); t['types'].append('i')
for r in t['rows']:
    r.append(FARE_HOTH if r[0] == 'hoth' else FARE_CORE)
t['rows'].append(['taanab'] + [FARE_HOTH if n == 'hoth' else FARE_CORE for n in t['names'][1:-1]] + [100])
dt_tool.write(t, out('datatables/travel/travel.iff'))

s = stf_tool.read(bg('string/en/planet_n.stf')); stf_tool.set(s, 'taanab', 'Taanab')
stf_tool.write(s, out('string/en/planet_n.stf'))

c = cstb_tool.read(bg('misc/planet_crc_string_table.iff')); cstb_tool.add(c, 'taanab')
cstb_tool.write(c, out('misc/planet_crc_string_table.iff'))

w = dt_tool.read(bg('datatables/player/waypoint_planets.iff'))
if not any(r[0] == 'taanab' for r in w['rows']):
    w['rows'].append(['taanab', 'ui_planet_sel_taanab.apt'])
dt_tool.write(w, out('datatables/player/waypoint_planets.iff'))

# planet map: BG already has a 'taanab' page that points at Talus' map
m = open(bg('ui/ui_planet_map.inc'), 'rb').read().decode('latin-1')
i = m.index("Name='taanab'")
j = m.index('</Page>', i)
blk = m[i:j].replace("SourceResource='ui_map_talus'", "SourceResource='ui_map_taanab'")  # map dds is 1024x1024
assert 'ui_map_taanab' in blk
m = m[:i] + blk + m[j:]
open(out('ui/ui_planet_map.inc'), 'wb').write(m.encode('latin-1'))

# ticket purchase: clone each Hoth element as Taanab at a free spot on the galaxy map (east side)
u = open(bg('ui/ui_ticketpurchase.inc'), 'rb').read().decode('latin-1')
nl = '\r\n' if '\r\n' in u else '\n'
L = u.split(nl)
import merge_ticket_ui as mt
def clone(name, tag, subs):
    s, e = mt.find_block(L, name, tag)
    blk = [x.replace('Hoth', 'Taanab').replace('hoth', 'taanab') for x in L[s:e + 1]]
    for k, v in subs.items():
        blk = [re.sub(r"(\b%s=)'[^']*'" % k, r"\1'%s'" % v, x) for x in blk]
    L[e + 1:e + 1] = blk
BX, BY = 420, 228   # button; Hoth's viewer sits 4px inside its 41x39 button
clone('Hoth', 'DataSource', {})
clone('buttonHoth', 'Button', {'Location': '%d,%d' % (BX, BY)})
clone('vHoth', 'CuiWidget3dObjectListViewer', {'Location': '%d,%d' % (BX + 4, BY + 4)})
clone('Hoth', 'Page', {'SourceRect': '0,0,1024,1024'})
clone('Hoth', 'Text', {'Location': '%d,%d' % (BX - 17, BY + 40)})
i = next(i for i, l in enumerate(L) if l.strip().startswith("buttonHoth='"))
L.insert(i + 1, L[i].replace('Hoth', 'Taanab'))
# the Hoth viewer precedes its button, so the cloned button landed right after buttonHoth; move the viewer before it
vs, ve = mt.find_block(L, 'vTaanab', 'CuiWidget3dObjectListViewer')
viewer = L[vs:ve + 1]; del L[vs:ve + 1]
bs, be = mt.find_block(L, 'buttonTaanab', 'Button')
L[bs:bs] = viewer
open(out('ui/ui_ticketpurchase.inc'), 'wb').write(nl.join(L).encode('latin-1'))

# --- checks: snapshot templates in the object CRC table; snapshot object ids must not collide with any other
# BG snapshot (the server would treat the Taanab node as the existing object and move it), so renumber clashes.
import struct
import move_outposts as mo
from iff_clone import serialize
WS = out('snapshot/taanab.ws')
ot = cstb_tool.read(bg('misc/object_template_crc_string_table.iff'))
buf = open(WS, 'rb').read()
root, nodes = mo.ws_nodes(buf)
assert serialize(root) == buf, 'snapshot round-trip mismatch'
miss = sorted({n['tmpl'] for n in nodes if n['tmpl'].lower() not in {k.lower() for k in ot}})
print('snapshot nodes', len(nodes), 'templates missing from CRC table:', miss)
bgw = winners(r'C:\BellumGero')
other = set()
for p, (tre, e) in sorted(bgw.items()):
    if p.startswith('snapshot/') and p.endswith('.ws') and 'taanab' not in p:
        d = os.path.join('extract', 'bg_ws'); extract_entry(tre, e, d)
        other |= {n['oid'] for n in mo.ws_nodes(open(os.path.join(d, *p.split('/')), 'rb').read())[1]}
ids = {n['oid'] for n in nodes}
assert len(ids) == len(nodes), 'duplicate ids inside taanab.ws'
clash = sorted(ids & other)
# new ids: the first free ids above Taanab's own block (the World Builder band 0x60000000+ is in use too)
used, nxt, remap = ids | other, max(ids) + 1, {}
for o in clash:
    while nxt in used: nxt += 1
    remap[o] = nxt; used.add(nxt)
for n in nodes:
    lst, j = n['ref']
    d = bytearray(lst[j][4])
    oid, pid = struct.unpack_from('<ii', d)
    if oid in remap or pid in remap:
        struct.pack_into('<ii', d, 0, remap.get(oid, oid), remap.get(pid, pid))
        mo.set_chunk(n['ref'], bytes(d))
# Snapshot installations would load as ownerless player harvesters (no other BG snapshot has any): use the static mockup.
SWAP = {'object/installation/mining_liquid/shared_mining_liquid_moisture_harvester_heavy.iff':
        'object/static/installation/shared_mockup_mining_liquid_moisture_harvester.iff'}
def find_chunk(kids, tag):
    for i, k in enumerate(kids):
        if k[0] == tag: return kids, i
        if k[0] == 'FORM':
            r = find_chunk(k[4], tag)
            if r: return r
otl, oti = find_chunk(root, 'OTNL')
otnl = otl[oti][4]
cnt = struct.unpack_from('<I', otnl)[0]
names = [x.decode('latin-1') for x in otnl[4:].split(b'\0')[:cnt]]
swapped = 0
for old, new in SWAP.items():
    if new not in names: names.append(new)
    for n in nodes:
        if n['tmpl'] == old:
            lst, j = n['ref']; d = bytearray(lst[j][4])
            struct.pack_into('<i', d, 8, names.index(new)); mo.set_chunk(n['ref'], bytes(d)); swapped += 1
mo.set_chunk((otl, oti), struct.pack('<I', len(names)) + b''.join(x.encode('latin-1') + b'\0' for x in names))
print('swapped', swapped, 'snapshot installations to static mockups')
open(WS, 'wb').write(serialize(root))
print('renumbered', remap)
_, chk = mo.ws_nodes(open(WS, 'rb').read())
ids = {n['oid'] for n in chk}
assert not ids & other and len(ids) == len(nodes)
assert not [n for n in chk if n['tmpl'].startswith('object/installation/')]
miss = sorted({n['tmpl'] for n in chk if n['tmpl'].lower() not in {k.lower() for k in ot}}); assert not miss, miss
print('taanab ids', min(ids), '-', max(ids), '; no clashes with', len(other), 'ids in other BG snapshots')
