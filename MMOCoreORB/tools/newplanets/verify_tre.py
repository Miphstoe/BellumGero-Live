#!/usr/bin/env python3
"""verify_tre.py — check that dist/bg_custom1.tre and dist/devbg/bg_custom1.tre contain every file of the
build/hoth and build/hoth_loot overlays (same size) and that every object/*.iff inside each TRE has an entry
in that TRE's misc/object_template_crc_string_table.iff."""
import os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import cstb_tool

TRES = {'live': os.path.join(HERE, 'dist', 'bg_custom1.tre'), 'devbg': os.path.join(HERE, 'dist', 'devbg', 'bg_custom1.tre')}
OVERLAYS = [os.path.join(HERE, 'build', 'hoth'), os.path.join(HERE, 'build', 'hoth_loot')]
PROBES = ['object/tangible/furniture/hoth/shared_frn_hoth_snowglobe.iff',
          'object/draft_schematic/clothing/shared_clothing_armor_rebel_snow_backpack.iff',
          'object/tangible/wearables/armor/snowtrooper/shared_armor_snowtrooper_helmet.iff',
          'object/intangible/vehicle/shared_snowspeeder.iff',
          'object/tangible/painting/shared_hothbattle_01_f00_000000000000.iff',
          'datatables/resource/resource_tree.iff', 'string/en/art_n.stf', 'string/en/dt_n.stf']

tables = {name: {e['name'].lower(): e for e in read_tre(path)} for name, path in TRES.items()}
for name, t in tables.items():
    print(f'{name}: {len(t)} entries')

missing, sizediff, total = [], [], 0
for d in OVERLAYS:
    for root, _, files in os.walk(d):
        for f in files:
            total += 1
            rel = os.path.relpath(os.path.join(root, f), d).replace(os.sep, '/').lower()
            sz = os.path.getsize(os.path.join(root, f))
            for name, t in tables.items():
                if rel not in t:
                    missing.append((name, rel))
                elif t[rel]['size'] != sz:
                    sizediff.append((name, rel, t[rel]['size'], sz))
print(f'overlay files: {total}; missing from a TRE: {len(missing)}; size mismatches: {len(sizediff)}')
for m in (missing + sizediff)[:10]:
    print('   ', m)

tmp = tempfile.mkdtemp()
for name, path in TRES.items():
    t = tables[name]
    p = extract_entry(path, t['misc/object_template_crc_string_table.iff'], os.path.join(tmp, name))
    crc = {k.lower() for k in cstb_tool.read(p)}
    objs = [k for k in t if k.startswith('object/') and k.endswith('.iff')]
    not_in = [k for k in objs if k not in crc]
    print(f'{name}: CRC table {len(crc)} entries; object iffs in TRE {len(objs)}; without CRC entry: {len(not_in)}')
    for k in not_in[:10]:
        print('   ', k)
    for probe in PROBES:
        assert probe in t, (name, probe)
        if probe.startswith('object/'):
            assert probe in crc, (name, probe)
print('all probe files present (and in the CRC tables) in both TREs')
