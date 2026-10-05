#!/usr/bin/env python3
"""gen_hoth_pois.py — named Hoth points of interest: server regions + client strings/radar regions. Idempotent.

Owns the '-- Points of interest' block of hoth_regions.lua (rewritten on every run). MAPPOI (0x020000, Bellum Gero
PlanetManager change) puts a region on the planetary map under "Points of Interest"; outposts are on the map as
cities, shuttleports register themselves."""
import os
import dt_tool
import stf_tool
import gen_hoth_mobiles as g

MAP = ' + MAPPOI'
POIS = [  # key, display name, x, y, radius, server flags
    ('ice_caves', 'Wampa Ice Caves', -400, 2600, 450, 'NAMEDREGION + NOBUILDZONEAREA'),
    # one map entry per cave (snapshot cave buildings; bosses from hoth_ice_caves.lua)
    ('frostfang_hollow', "Frostfang's Hollow", -623, 2292, 40, 'NAMEDREGION' + MAP),
    ('icemaw_den', "Icemaw's Den", -385, 2436, 40, 'NAMEDREGION' + MAP),
    ('snowblind_lair', "Snowblind's Lair", -543, 2674, 40, 'NAMEDREGION' + MAP),
    ('great_wampa_cavern', 'Great Wampa Cavern', -75, 2969, 60, 'NAMEDREGION' + MAP),
    ('northern_ice_cavern', 'Northern Ice Cavern', -5819, 6093, 150, 'NAMEDREGION + NOBUILDZONEAREA' + MAP),
    ('shield_generator_battlefield', 'Shield Generator Battlefield', 5420, 780, 450, 'NAMEDREGION + NOBUILDZONEAREA' + MAP),
    ('raider_camp', 'Generator Raider Camp', 5068, 1300, 80, 'NAMEDREGION + NOSPAWNAREA + NOBUILDZONEAREA' + MAP),
    ('lucky_despot_wreck', 'Lucky Despot Wreck', -4130, -2128, 60, 'NAMEDREGION' + MAP),  # moved with the Scavenger Outpost
    ('glacial_rancor_grounds', 'Glacial Rancor Hunting Grounds', 600, -4600, 200, 'NAMEDREGION + NOBUILDZONEAREA' + MAP),  # world boss
]
EXTRA = [  # server-only regions kept in the same block
    '\t{"hoth_eastern_ice_fields_shuttleport_nobuild", 5928, -406, {CIRCLE, 100}, NOBUILDZONEAREA + NOSPAWNAREA},',
    '\t{"hoth_generator_ridge_shuttleport_nobuild", 4525, 1164, {CIRCLE, 100}, NOBUILDZONEAREA + NOSPAWNAREA},',
]


def server_regions():
    p = os.path.join(g.ROOT, 'managers', 'planet', 'hoth_regions.lua')
    s = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    start, end = s.index('\t-- Points of interest'), s.index('\t-- World spawner')
    lines = ['\t-- Points of interest'] + \
            [f'\t{{"@hoth_region_names:{k}", {x}, {y}, {{CIRCLE, {r}}}, {flags}}},' for k, _, x, y, r, flags in POIS] + \
            [''] + ['\t-- Shuttleports on the old Imperial / Rebel outpost sites'] + EXTRA
    s = s[:start] + nl.join(lines) + nl + nl + s[end:]
    open(p, 'w', encoding='utf-8', newline='').write(s)
    print('server POI regions:', len(POIS), 'on map:', sum('MAPPOI' in f for *_, f in POIS))

    rp = os.path.join(g.ROOT, 'managers', 'planet', 'regions.lua')
    r = open(rp, encoding='utf-8', newline='').read()
    if 'MAPPOI' not in r:
        rnl = '\r\n' if '\r\n' in r else '\n'
        anchor = 'NOPETAREA           = 0x010000'
        assert r.count(anchor) == 1
        r = r.replace(anchor, anchor + rnl + 'MAPPOI              = 0x020000 -- Bellum Gero: show on the planetary map (PlanetManager)')
        open(rp, 'w', encoding='utf-8', newline='').write(r)
        print('regions.lua: MAPPOI added')


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
    rows = {row[0]: row for row in r['rows']}
    for k, _, x, y, rad, _f in POIS:
        key = f'@hoth_region_names:{k}'
        if key in rows:
            rows[key][1:4] = [float(x), float(y), float(rad)]
        else:
            r['rows'].append([key, float(x), float(y), float(rad)])
    dt_tool.write(r, cp)
    print('strings:', len(stf_tool.as_dict(stf_tool.read(sp))), 'radar regions:', len(dt_tool.read(cp)['rows']))


if __name__ == '__main__':
    server_regions()
    client_files()
