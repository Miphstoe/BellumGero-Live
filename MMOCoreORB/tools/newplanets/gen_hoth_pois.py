#!/usr/bin/env python3
"""gen_hoth_pois.py — named Hoth points of interest: server regions + client strings/radar regions. Idempotent."""
import os
import dt_tool
import stf_tool
import gen_hoth_mobiles as g

POIS = [  # key, display name, x, y, radius, server flags
    ('ice_caves', 'Wampa Ice Caves', -400, 2600, 450, 'NAMEDREGION + NOBUILDZONEAREA'),
    ('northern_ice_cavern', 'Northern Ice Cavern', -5819, 6093, 150, 'NAMEDREGION + NOBUILDZONEAREA'),
    ('shield_generator_battlefield', 'Shield Generator Battlefield', 5420, 780, 450, 'NAMEDREGION + NOBUILDZONEAREA'),
    ('raider_camp', 'Generator Raider Camp', 5068, 1300, 80, 'NAMEDREGION + NOSPAWNAREA + NOBUILDZONEAREA'),
    ('lucky_despot_wreck', 'Lucky Despot Wreck', -100, -2048, 60, 'NAMEDREGION'),
]


def server_regions():
    p = os.path.join(g.ROOT, 'managers', 'planet', 'hoth_regions.lua')
    s = open(p, encoding='utf-8', newline='').read()
    marker = '\t-- World spawner'
    lines = [f'\t{{"@hoth_region_names:{k}", {x}, {y}, {{CIRCLE, {r}}}, {flags}}},' for k, _, x, y, r, flags in POIS
             if f'@hoth_region_names:{k}"' not in s]
    if lines:
        s = s.replace(marker, '\t-- Points of interest\n' + '\n'.join(lines) + '\n\n' + marker, 1)
        open(p, 'w', encoding='utf-8', newline='').write(s)
    print('server regions added:', len(lines))


def client_files():
    sp = 'build/hoth/string/en/hoth_region_names.stf'
    t = stf_tool.read(sp)
    have = stf_tool.as_dict(t)
    for k, name, *_ in POIS:
        if k not in have:
            stf_tool.add(t, k, name)
    stf_tool.write(t, sp)
    cp = 'build/hoth/datatables/clientregion/hoth.iff'
    r = dt_tool.read(cp)
    keys = {row[0] for row in r['rows']}
    for k, _, x, y, rad, _f in POIS:
        if f'@hoth_region_names:{k}' not in keys:
            r['rows'].append([f'@hoth_region_names:{k}', float(x), float(y), float(rad)])
    dt_tool.write(r, cp)
    print('strings:', stf_tool.as_dict(stf_tool.read(sp)))
    print('radar regions:', len(dt_tool.read(cp)['rows']))


if __name__ == '__main__':
    server_regions()
    client_files()
