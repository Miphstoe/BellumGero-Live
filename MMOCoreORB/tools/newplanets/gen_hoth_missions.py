#!/usr/bin/env python3
"""gen_hoth_missions.py — deliver missions on Hoth. Idempotent.

Deliver missions start at a mission NPC spawn point within 300 m of the player inside a mission city and end at a
spawn point in another city of the same planet (MissionManager::randomGenericDeliverMission). This adds the three
outposts to managers/mission/mission_cities.lua and a planet_hoth block to mission_npc_spawn_points.lua.

Spawn points: rings around each starport, on the outpost's flattened ground, kept clear of every snapshot object
(buildings 32 m, props 5 m). spawnType is a bitmask (NpcSpawnPoint.h): 2 neutral, 4 imperial, 8 rebel. The Scavenger
Outpost serves everyone, so imperial/rebel deliveries always have a second city to go to."""
import math, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import move_outposts as mo

MISSION = os.path.join(mo.WT, 'managers', 'mission')
CITIES = [  # name, centre, radius, spawnType
    ('Scavenger Outpost', mo.MOVES['scavenger']['new'], 200, 2 | 4 | 8),
    ('Imperial Forward Base', mo.MOVES['imperial']['new'], 200, 2 | 4),
    ('Rebel Forward Base', mo.MOVES['rebel']['new'], 200, 2 | 8),
]
PER_CITY = 12


def blockers():
    _, nodes = mo.ws_nodes(open(mo.OUT_WS, 'rb').read())  # moved snapshot
    out = []
    for n in nodes:
        if n['pid'] != 0:
            continue
        out.append((n['x'], n['y'], 32.0 if '/building/' in n['tmpl'] else 5.0))
    return out


def points(centre, blk):
    cx, cy = centre
    pts = []
    for radius in (35, 50, 65, 80, 95):
        for k in range(16):
            a = math.radians(k * 22.5 + radius)
            x, y = cx + radius * math.sin(a), cy + radius * math.cos(a)
            if all(math.hypot(x - bx, y - by) > r for bx, by, r in blk) and \
               all(math.hypot(x - px, y - py) > 12 for px, py, _ in pts):
                pts.append((round(x, 1), round(y, 1), round(math.atan2(cx - x, cy - y) % (2 * math.pi), 3)))
            if len(pts) >= PER_CITY:
                return pts
    return pts


def main():
    p = os.path.join(MISSION, 'mission_cities.lua')
    s = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = re.sub(r'[ \t]*\{ "hoth",[^\n]*\n', '', s)
    rows = ''.join(f'\t{{ "hoth", "{name}", {int(c[0])}, {int(c[1])}, {r} }},{nl}' for name, c, r, _ in CITIES)
    anchor = '\t{ "lok",'
    assert anchor in s
    s = s.replace(anchor, rows + anchor, 1)
    open(p, 'w', encoding='utf-8', newline='').write(s)

    blk = blockers()
    npcs = []
    for name, c, r, st in CITIES:
        pts = points(c, blk)
        print(f'{name}: {len(pts)} spawn points (type {st})')
        npcs += [f'\t\t{{ {x}, {y}, {d}, {st} }}' for x, y, d in pts]
    block = 'planet_hoth = PlanetSpawnMap:new {\n\tname = "hoth",\n\tnpcs = {\n' + ',\n'.join(npcs) + \
            '\n\t}\n}\n\nuniverse:addPlanet(planet_hoth);\n'
    sp = os.path.join(MISSION, 'mission_npc_spawn_points.lua')
    s = open(sp, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = re.sub(r'planet_hoth = PlanetSpawnMap:new \{.*?universe:addPlanet\(planet_hoth\);\r?\n', '', s, flags=re.S)
    s = s.rstrip('\r\n') + nl + nl + block.replace('\n', nl)
    open(sp, 'w', encoding='utf-8', newline='').write(s)


if __name__ == '__main__':
    main()
