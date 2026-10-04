#!/usr/bin/env python3
"""crc_compare.py — compare object_template_crc_string_table.iff across the base TREs and our overlays."""
import os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import cstb_tool

CRC = 'misc/object_template_crc_string_table.iff'
tmp = tempfile.mkdtemp()


def table_from_tre(path, tag):
    ents = {e['name'].lower(): e for e in read_tre(path)}
    if CRC not in ents:
        return None, ents
    p = extract_entry(path, ents[CRC], os.path.join(tmp, tag))
    return {k.lower() for k in cstb_tool.read(p)}, ents


live_base, live_ents = table_from_tre(r'C:\BellumGero\Backup\bg_custom1.tre.bak-20260927-prehoth', 'livebase')
dev_base, dev_ents = table_from_tre(r'C:\Dev-BG\archive\bg_custom1.tre.bak-20260927-prehoth', 'devbase')
hoth = {k.lower() for k in cstb_tool.read(os.path.join(HERE, 'build', 'hoth', CRC))}
loot = {k.lower() for k in cstb_tool.read(os.path.join(HERE, 'build', 'hoth_loot', CRC))}
dist_live, _ = table_from_tre(os.path.join(HERE, 'dist', 'bg_custom1.tre'), 'distlive')
dist_dev, _ = table_from_tre(os.path.join(HERE, 'dist', 'devbg', 'bg_custom1.tre'), 'distdev')

print('live Sep12 base table:', None if live_base is None else len(live_base))
print('devbg Aug5 base table:', None if dev_base is None else len(dev_base))
print('build/hoth table:', len(hoth), ' build/hoth_loot table:', len(loot), ' dist live:', len(dist_live), ' dist devbg:', len(dist_dev))
if live_base:
    lost = sorted(live_base - hoth)
    print(f'entries in the live base table that build/hoth DROPS: {len(lost)}')
    for k in lost[:60]:
        print('   ', k)
    print('entries in build/hoth not in live base (expected: Hoth adds):', len(hoth - live_base))
if dev_base:
    print('entries in devbg base table that build/hoth drops:', len(dev_base - hoth))
print('hoth_loot minus dist live table:', sorted(loot - dist_live)[:5], ' dist live minus hoth_loot:', sorted(dist_live - loot)[:5])
objs_live = {k for k in live_ents if k.startswith('object/') and k.endswith('.iff')}
print('live base object iffs without entry in the live base table itself:', len(objs_live - live_base))
