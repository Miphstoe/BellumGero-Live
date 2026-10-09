#!/usr/bin/env python3
"""vehicle_inventory.py — print, for every Infinity mount BG lacks, the matching pcd/mobile/deed client templates and
the vehicle's objectName string id (from its mobile template). Used to fill VEHICLES in gen_hoth_vehicles.py."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import dt_tool
import gen_hoth_loot_client as c
import iff_names  # noqa (for its helpers we re-implement below)

inf_paths = {}
for l in open(os.path.join(HERE, 'infinity_all.txt'), encoding='utf-8', errors='replace'):
    p = l.rstrip('\n').split('\t')
    if len(p) >= 2:
        inf_paths[p[1].lower()] = p[0]
bg_paths = {l.split('\t')[1].lower() for l in open(os.path.join(HERE, 'bg_all.txt'), encoding='utf-8', errors='replace') if '\t' in l}

tmp = os.path.join(HERE, 'extract', 'inf')
sad = dt_tool.read(c.inf_file('datatables/mount/saddle_appearance_map.iff', tmp))
poses = {r[0]: r[2] for r in dt_tool.read(c.inf_file('datatables/mount/rider_pose_map.iff', tmp))['rows']}
bgsad = {r[0] for r in dt_tool.read(c.bg_file('datatables/mount/saddle_appearance_map.iff'))['rows']}


def stem(p):
    s = p.rsplit('/', 1)[1][:-4]
    s = re.sub(r'^shared_', '', s)
    s = re.sub(r'^vehicle_deed_', '', s)
    s = re.sub(r'_(pcd|deed)$', '', s)
    return s


mob = {stem(p): p for p in inf_paths if p.startswith('object/mobile/vehicle/') and p.endswith('.iff') and p not in bg_paths}
pcd = {stem(p): p for p in inf_paths if p.startswith('object/intangible/vehicle/') and p.endswith('.iff') and p not in bg_paths}
deed = {stem(p): p for p in inf_paths if p.startswith('object/tangible/deed/vehicle_deed/') and p.endswith('.iff') and p not in bg_paths}
ALIAS = {  # saddle key -> template stem when they differ
    'speeder_xp_38': 'landspeeder_xp38', 'bail_organa_speeder': 'landspeeder_organa', 'stap_speeder': 'stap_speeder',
    'hk47_jetpack': 'tcg_hk47_jetpack', 'ipg_podracer': 'pod_racer_ipg_longtail', 'balta_podracer': 'pod_racer_balta_podracer',
    'panning_droid': 'mustafar_panning_droid', 'speeder_ab1': 'landspeeder_ab1', 'geonosian_speeder': 'geonosian_speeder',
}
DEED_ALIAS = {'bail_organa_speeder': 'organa_speeder', 'sith_speeder': 'sith_speeder', 'mechno_chair': 'mechno_chair',
              'stap_speeder': 'speeder_stap', 'geonosian_speeder': 'geo_speeder', 'tcg_military_transport': 'military_transport',
              'tcg_8_single_pod_airspeeder': 'tcg_8_air_speeder', 'hoverlifter_speeder': 'hoverlifter_speeder'}


def name_of(path):
    """objectName stf:key of a client template."""
    local = c.inf_file(path, tmp)
    s = [m.decode('latin-1') for m in re.findall(rb'[\x20-\x7e]{3,}', open(local, 'rb').read())]
    for i, x in enumerate(s):
        if x.endswith('objectName') and i + 2 < len(s):
            return f'{s[i+1]}:{s[i+2]}'
    return '?'


seen = set()
print('KEY | saddle | pose | pcd | mobile | deed | objectName')
for r in sad['rows']:
    key = r[0]
    if key in bgsad or key in seen:
        continue
    seen.add(key)
    k = key.split('/', 1)[1]
    st = ALIAS.get(k, k)
    m = mob.get(st) or mob.get(k)
    p = pcd.get(st) or pcd.get(k) or pcd.get('gift_stap' if k == 'stap_speeder' else '')
    d = deed.get(DEED_ALIAS.get(k, st)) or deed.get(k) or deed.get(st)
    print(f"{k} | {r[2]} | {poses.get(r[2], '?')} | {p or '-'} | {m or '-'} | {d or '-'} | {name_of(m) if m else '?'}")
