#!/usr/bin/env python3
"""fix_xp38.py — XP-38 crashed the client on /mount (2026-10-12, Plane LIVE-29). Infinity keys logical_saddle_name_map and
valid_scale_range by the vehicle's real skeletal appearance (appearance/pv_speeder_xp_38.sat), but our cloned mobile
template pointed at the static saddle appearance (speeder_xp_38.apt), so gen_hoth_vehicles.py never copied those two rows
and the client's mount lookup found nothing. Fix (overlay build/hoth_xp38_fix, applied after build/hoth_loot):
  * mobile template -> pv_speeder_xp_38.sat (chain staged by stage_missing.py: sat, skeleton, mgn)
  * the two missing mount rows
  * gen_hoth_vehicles.py entry corrected so a regen does the same"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import iff_clone, dt_tool
SAT = 'appearance/pv_speeder_xp_38.sat'
LOOT = os.path.join(HERE, 'build', 'hoth_loot'); OUT = os.path.join(HERE, 'build', 'hoth_xp38_fix')
# 1. mobile template
rel = os.path.join('object', 'mobile', 'vehicle', 'shared_landspeeder_xp38.iff')
iff_clone.clone(os.path.join(LOOT, rel), os.path.join(OUT, rel), {'appearanceFilename': SAT})
d = open(os.path.join(OUT, rel), 'rb').read()
print('template appearance now:', [s.decode() for s in re.findall(rb'appearance/[a-z0-9_]+\.(?:sat|apt)', d)])
# 2. mount rows
added = []
for tn, row in (('logical_saddle_name_map', [SAT, 'lookup/speeder_xp_38']), ('valid_scale_range', [SAT, 1, 0.5, 2.5])):
    src = os.path.join(LOOT, 'datatables', 'mount', tn + '.iff'); dst = os.path.join(OUT, 'datatables', 'mount', tn + '.iff')
    t = dt_tool.read(src)
    if not any(r[0] == SAT for r in t['rows']):
        t['rows'].append(row); added.append(tn)
    os.makedirs(os.path.dirname(dst), exist_ok=True); dt_tool.write(t, dst)
    chk = dt_tool.read(dst); print(tn, 'rows', len(chk['rows']), 'xp38:', [r for r in chk['rows'] if 'xp_38' in str(r)])
print('rows added:', added)
# 3. generator entry
g = os.path.join(HERE, 'gen_hoth_vehicles.py'); s = open(g, encoding='utf-8', newline='').read()
old = "('clone', 'shared_landspeeder_ab1.iff', 'appearance/speeder_xp_38.apt')"
new = "('clone', 'shared_landspeeder_ab1.iff', 'appearance/pv_speeder_xp_38.sat')  # real appearance: the mount tables are keyed by it (LIVE-29)"
if old in s:
    open(g, 'w', encoding='utf-8', newline='').write(s.replace(old, new)); print('generator entry fixed')
else:
    print('generator entry already fixed' if 'pv_speeder_xp_38.sat' in s else 'generator entry NOT FOUND')
