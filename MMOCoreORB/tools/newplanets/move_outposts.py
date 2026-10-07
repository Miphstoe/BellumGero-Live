#!/usr/bin/env python3
"""move_outposts.py — move the three Hoth outposts (Scavenger, Imperial, Rebel) to new sites.

Always starts from the pristine Infinity terrain/snapshot (extract/infinity), so it can be re-run.

  python move_outposts.py client [ground.json]
      build/hoth/terrain/hoth.trn   flatten layers moved (Scavenger, Imperial) / cloned (Rebel), flat height = median
                                    ground of the new site (from server_prep/hoth_heights.json, the first probe)
      build/hoth/snapshot/hoth.ws   top-level objects of each outpost shifted; height = ground at the new spot + the
                                    object's original height above ground. ground.json = probe of the new positions on
                                    the moved terrain (pass 2); without it the flat height is assumed (pass 1).
      build/hoth/datatables/clientregion/hoth.iff   outpost + Lucky Despot radar regions
  python move_outposts.py probe     server_prep/hoth_height_probe.lua for every moved object / server point (pass 2)
  python move_outposts.py server    server worktree: hoth_regions.lua, planet_manager.lua (travel points, nav areas,
                                    terminals); prints the constants for gen_hoth_mobiles.py / gen_hoth_pois.py
Writes server_prep/outpost_moves.json (offsets, flatten centres, flat heights)."""
import copy, json, math, os, statistics, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])
from iff_clone import serialize
import dt_tool

SRC_TRN = os.path.join(HERE, 'extract', 'infinity', 'terrain', 'hoth.trn')
SRC_WS = os.path.join(HERE, 'extract', 'infinity', 'snapshot', 'hoth.ws')
OUT_TRN = os.path.join(HERE, 'build', 'hoth', 'terrain', 'hoth.trn')
OUT_WS = os.path.join(HERE, 'build', 'hoth', 'snapshot', 'hoth.ws')
REGIONS = os.path.join(HERE, 'build', 'hoth', 'datatables', 'clientregion', 'hoth.iff')
PROBE1 = os.path.join(HERE, 'server_prep', 'hoth_heights.json')
STATE = os.path.join(HERE, 'server_prep', 'outpost_moves.json')
WT = r'\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth\MMOCoreORB\bin\scripts'

# old = starport centre in the Infinity snapshot; new = where it goes (picked on the planet map 2026-10-04;
# Rebel moved to the foot of the ice-cave mountains instead of into them). radius = objects that belong to the outpost.
MOVES = {
    'scavenger': dict(old=(0.0, -2000.0), new=(-4030.0, -2080.0), radius=200),
    'imperial': dict(old=(5927.6, -406.5), new=(3820.0, -3080.0), radius=400),
    'rebel': dict(old=(4525.0, 1164.0), new=(-420.0, 600.0), radius=300),
}
REBEL_FLAT = dict(radius=240.0, feather=0.2)  # new flatten layer around the Rebel plateau (it had none: mountain shelf)
# Shuttleports on the vacated Imperial and Rebel sites (requested 2026-10-04). Corellia style, unrotated: shuttle at the
# centre, arrival point 19 m west (stock convention, cf. Naboo "Village"). height: Imperial = the original flatten
# height there; Rebel = probed ground under the old starport. Each gets a small flatten circle.
SHUTTLEPORTS = [
    dict(key='eastern_ice_fields', name='Eastern Ice Fields Shuttleport', x=5927.6, y=-406.5, height=3.0, radius=80.0,
         style='imperial'),
    dict(key='generator_ridge', name='Generator Ridge Shuttleport', x=4525.0, y=1164.0, height=None, radius=80.0,
         style='rebel'),
]
# Walls + corner columns + decorative turrets around each shuttleport (snapshot statics cloned from the outposts'
# own nodes, so template/radius data match). A wall model's length runs along its local x axis: yaw 180 = east-west.
# Gap on the west side, where the arrival point is. New snapshot OIDs live in a band no other snapshot uses.
DEFENSE = {
    'imperial': dict(wall='object/static/structure/military/shared_military_wall_strong_imperial_style_01.iff', seg=8.0,
                     column='object/static/structure/military/shared_military_column_strong_imperial_style_01.iff',
                     half=36.0, gap=2),
    'rebel': dict(wall='object/static/structure/military/shared_military_wall_strong_rebl_16_style_01.iff', seg=16.0,
                  column='object/static/structure/military/shared_military_column_strong_rebel_style_01.iff',
                  half=40.0, gap=1),
}
TURRET = 'object/static/item/shared_item_hoth_turret_round.iff'
TURRET_SINK = 2.0  # the outposts bury these turrets' bases ~2 m
DEFENSE_OID_BASE = 0x5E480000
SHUTTLEPORT_TEMPLATE = 'object/building/corellia/shuttleport_corellia.iff'


def shuttleport_height(sp):
    if sp['height'] is not None:
        return sp['height']
    best = min(json.load(open(PROBE1)), key=lambda r: math.hypot(r[1] - sp['x'], r[2] - sp['y']) if r[0].startswith('obj_') else 1e9)
    return round(best[3], 1)
POIS_WITH = {'lucky_despot_wreck': 'scavenger'}  # named regions that travel with an outpost


def offset(site):
    m = MOVES[site]
    return m['new'][0] - m['old'][0], m['new'][1] - m['old'][1]


# ---------------------------------------------------------------- snapshot
def ws_nodes(buf):
    """[(objId, parentId, template, x, h, y, data_chunk_ref)] for every node; data ref = (list, index) for patching."""
    root = parse(buf)
    body = root[0][4][0][4]
    otnl = find(body, ['OTNL'])
    n = struct.unpack_from('<I', otnl)[0]
    names = [x.decode('latin-1') for x in otnl[4:].split(b'\0')[:n]]
    out = []

    def walk(nodes):
        for idx, (tag, ft, off, size, kids) in enumerate(nodes):
            if tag == 'FORM' and ft == 'NODE':
                for form in kids:
                    if form[0] == 'FORM' and form[1] == '0000':
                        for j, ch in enumerate(form[4]):
                            if ch[0] == 'DATA' and len(ch[4]) >= 52:
                                oid, pid, ni = struct.unpack_from('<iii', ch[4])
                                x, h, y = struct.unpack_from('<3f', ch[4], 32)
                                out.append(dict(oid=oid, pid=pid, tmpl=names[ni], x=x, h=h, y=y, ref=(form[4], j)))
                walk(kids)
            elif tag == 'FORM':
                walk(kids)
    walk(root)
    return root, out


def site_of(n):
    if n['pid'] != 0:
        return None
    for s, m in MOVES.items():
        if math.hypot(n['x'] - m['old'][0], n['y'] - m['old'][1]) < m['radius']:
            return s
    return None


def old_ground():
    """objId -> ground height under the object at its original spot (first probe)."""
    return {int(t.rsplit('_', 1)[1]): g for t, x, y, g in json.load(open(PROBE1)) if t.startswith('obj_')}


# ---------------------------------------------------------------- terrain
def layers_with_circle(nodes, parent=None, acc=None):
    """[(parent kids list, index of LAYR, LAYR kids)] for every LAYR, depth first."""
    acc = [] if acc is None else acc
    for i, (tag, ft, off, size, kids) in enumerate(nodes):
        if tag == 'FORM' and ft == 'LAYR':
            acc.append((nodes, i, kids))
        if tag == 'FORM':
            layers_with_circle(kids, nodes, acc)
    return acc


def direct(kids, ftype):
    """Data chunks (list, index) of the direct child affector/boundary forms of a layer: FORM ftype > FORM ver > DATA."""
    res = []
    if len(kids) == 1 and kids[0][0] == 'FORM' and kids[0][1].isdigit():  # LAYR > FORM 0003 > children
        kids = kids[0][4]
    for t, f, o, s, k in kids:
        if t == 'FORM' and f == ftype:
            for t2, f2, o2, s2, k2 in k:
                if t2 == 'FORM' and f2.isdigit():
                    for j, ch in enumerate(k2):
                        if ch[0] == 'DATA':
                            res.append((k2, j))
    return res


def set_chunk(ref, data):
    lst, j = ref
    tag, ft, off, size, _ = lst[j]
    lst[j] = (tag, ft, off, size, data)


def site_ground_median(site, centre, radius):
    pts = [(x, y, g) for t, x, y, g in json.load(open(PROBE1)) if t == f'grid_{site}']
    inside = [g for x, y, g in pts if math.hypot(x - centre[0], y - centre[1]) <= radius]
    return round(statistics.median(inside), 1)


def build_terrain(state):
    buf = open(SRC_TRN, 'rb').read()
    root = parse(buf)
    assert serialize(root) == buf, 'terrain round-trip mismatch'
    moved = {'scavenger': 0, 'imperial': 0}
    imperial_layer = None
    for parent, i, kids in layers_with_circle(root):
        circles = direct(kids, 'BCIR')
        if not circles:
            continue
        for site in ('scavenger', 'imperial'):
            m = MOVES[site]
            vals = [struct.unpack_from('<3fif', r[0][r[1]][4]) for r in circles]
            if not all(math.hypot(v[0] - m['old'][0], v[1] - m['old'][1]) < 300 for v in vals):
                continue
            dx, dy = offset(site)
            for r, (cx, cz, rad, ftype, famt) in zip(circles, vals):
                set_chunk(r, struct.pack('<3fif', cx + dx, cz + dy, rad, ftype, famt))
            for r in direct(kids, 'AHCN'):
                op, h = struct.unpack_from('<if', r[0][r[1]][4])
                set_chunk(r, struct.pack('<if', op, state[site]['flat']))
            moved[site] += 1
            if site == 'imperial' and direct(kids, 'AHCN'):
                imperial_layer = (parent, i)
    assert moved['scavenger'] >= 1 and moved['imperial'] == 1, moved
    # Rebel: clone the Imperial flatten layer (circle + height constant + snow shader) right after it.
    parent, i = imperial_layer
    clone = copy.deepcopy(parent[i])
    ck = clone[4]
    (c_ref,) = direct(ck, 'BCIR')
    cx, cz = state['rebel']['flat_centre']
    ftype = struct.unpack_from('<3fif', c_ref[0][c_ref[1]][4])[3]
    set_chunk(c_ref, struct.pack('<3fif', cx, cz, REBEL_FLAT['radius'], ftype, REBEL_FLAT['feather']))
    for r in direct(ck, 'AHCN'):
        op, h = struct.unpack_from('<if', r[0][r[1]][4])
        set_chunk(r, struct.pack('<if', op, state['rebel']['flat']))
    parent.insert(i + 1, clone)
    # Shuttleports on the old sites: one more clone of the Imperial flatten layer each.
    for n, sp in enumerate(SHUTTLEPORTS):
        c2 = copy.deepcopy(parent[i])
        (r2,) = direct(c2[4], 'BCIR')
        set_chunk(r2, struct.pack('<3fif', sp['x'], sp['y'], sp['radius'], ftype, 0.15))  # flat core ~68 m: walls + turrets
        for r in direct(c2[4], 'AHCN'):
            op, h = struct.unpack_from('<if', r[0][r[1]][4])
            set_chunk(r, struct.pack('<if', op, shuttleport_height(sp)))
        parent.insert(i + 2 + n, c2)
    closed = close_orphan_holes(root)
    open(OUT_TRN, 'wb').write(serialize(root))
    print(f'terrain: {closed} orphan terrain holes closed')
    print(f'terrain: scavenger layers {moved["scavenger"]}, imperial 1, rebel flatten layer added, '
          f'{len(SHUTTLEPORTS)} shuttleport flatten layers -> {OUT_TRN}')


def close_orphan_holes(root):
    """Infinity's terrain cuts cave-entrance holes (AffectorExclude) at three NW mountain spots that have no cave in
    the snapshot (-5307,5692 / -5050,5410 / -5036,5106): you can see and walk out of the world there (reported by Miph
    at -5270,5707). Drop the AEXC affector of every exclude layer whose polygon has no building within 25 m."""
    buf_nodes = ws_nodes(open(SRC_WS, 'rb').read())[1]
    blds = [(n['x'], n['y']) for n in buf_nodes if n['pid'] == 0 and '/building/' in n['tmpl']]
    closed = 0
    for parent, i, kids in layers_with_circle(root):
        k = kids[0][4] if len(kids) == 1 and kids[0][0] == 'FORM' and kids[0][1].isdigit() else kids
        if not any(t == 'FORM' and f == 'AEXC' for t, f, o, s, kk in k):
            continue
        polys = direct(kids, 'BPOL')
        if not polys:
            continue  # cave-entrance circles: all have their cave
        for lst, j in polys:
            d = lst[j][4]
            n = struct.unpack_from('<i', d)[0]
            pts = [struct.unpack_from('<2f', d, 4 + 8 * q) for q in range(n)]
            cx, cz = sum(p[0] for p in pts) / n, sum(p[1] for p in pts) / n
            if all(math.hypot(bx - cx, by - cz) > 60 for bx, by in blds):
                k[:] = [c for c in k if not (c[0] == 'FORM' and c[1] == 'AEXC')]
                closed += 1
                break
    return closed


# ---------------------------------------------------------------- state
def compute_state():
    buf = open(SRC_WS, 'rb').read()
    _, nodes = ws_nodes(buf)
    state = {}
    for site, m in MOVES.items():
        dx, dy = offset(site)
        state[site] = dict(offset=[dx, dy], new=list(m['new']))
    # Rebel flatten centre: centre of the plateau's bounding box, moved.
    reb = [n for n in nodes if site_of(n) == 'rebel']
    bx = (min(n['x'] for n in reb) + max(n['x'] for n in reb)) / 2 + state['rebel']['offset'][0]
    by = (min(n['y'] for n in reb) + max(n['y'] for n in reb)) / 2 + state['rebel']['offset'][1]
    state['rebel']['flat_centre'] = [round(bx, 1), round(by, 1)]
    state['scavenger']['flat'] = site_ground_median('scavenger', MOVES['scavenger']['new'], 250)
    state['imperial']['flat'] = site_ground_median('imperial', MOVES['imperial']['new'], 168)
    state['rebel']['flat'] = site_ground_median('rebel', state['rebel']['flat_centre'], REBEL_FLAT['radius'])
    json.dump(state, open(STATE, 'w'), indent=1)
    return state


def build_snapshot(state, ground_file=None):
    buf = open(SRC_WS, 'rb').read()
    root, nodes = ws_nodes(buf)
    assert serialize(root) == buf, 'snapshot round-trip mismatch'
    g_old = old_ground()
    g_new = {}
    if ground_file:
        g_new = {int(t.rsplit('_', 1)[1]): g for t, x, y, g in json.load(open(ground_file)) if t.startswith('new_')}
    count = {}
    for n in nodes:
        site = site_of(n)
        if not site:
            continue
        dx, dy = state[site]['offset']
        above = n['h'] - g_old[n['oid']]
        ground = g_new.get(n['oid'], state[site]['flat'])
        lst, j = n['ref']
        d = bytearray(lst[j][4])
        struct.pack_into('<3f', d, 32, n['x'] + dx, ground + above, n['y'] + dy)
        set_chunk(n['ref'], bytes(d))
        count[site] = count.get(site, 0) + 1
    added = add_defenses(root, nodes)
    open(OUT_WS, 'wb').write(serialize(root))
    print(f'snapshot: moved {count} ({"probed ground" if g_new else "flat-height estimate"}), '
          f'{added} shuttleport defense pieces added -> {OUT_WS}')


def defense_layout(sp):
    """[(template, x, y, height offset, yaw degrees)] for one shuttleport."""
    d = DEFENSE[sp['style']]
    cx, cy, half, seg = sp['x'], sp['y'], d['half'], d['seg']
    n = int(round(2 * half / seg))
    gap = set(range((n - d['gap']) // 2, (n - d['gap']) // 2 + d['gap']))
    out = []
    for i in range(n):
        t = -half + seg * (i + 0.5)
        out.append((d['wall'], cx + t, cy + half, 0.0, 180))   # north side, east-west
        out.append((d['wall'], cx + t, cy - half, 0.0, 180))   # south side
        out.append((d['wall'], cx + half, cy + t, 0.0, 90))    # east side, north-south
        if i not in gap:
            out.append((d['wall'], cx - half, cy + t, 0.0, 90))  # west side, gap = entrance
    for sx, sy, yaw in ((1, 1, 45), (1, -1, 135), (-1, -1, 225), (-1, 1, 315)):
        out.append((d['column'], cx + sx * half, cy + sy * half, 0.0, yaw))
        # corner turrets are real faction turrets now (turret_spots / turret_screenplay), not snapshot statics
    return out


def turret_spots(sp):
    """[(x, y, yaw degrees)] for the 4 faction turrets outside the wall corners of one shuttleport."""
    d = DEFENSE[sp['style']]
    half = d['half']
    return [(round(sp['x'] + sx * (half + 7), 1), round(sp['y'] + sy * (half + 7), 1), yaw)
            for sx, sy, yaw in ((1, 1, 45), (1, -1, 135), (-1, -1, 225), (-1, 1, 315))]


TURRET_TEMPLATE = 'object/installation/turret/turret_tower_sm.iff'
TURRET_RESPAWN = 1800  # seconds
TURRET_SCREENPLAY = 'screenplays/static_spawns/hoth_shuttleport_turrets.lua'


def turret_screenplay():
    """Server screenplay: working faction turrets (small towers) at both fortified shuttleports. Imperial turrets at
    Eastern Ice Fields attack overt Rebels, Rebel turrets at Generator Ridge attack overt Imperials (pvp bitmask
    ATTACKABLE + OVERT: an overt turret only targets overt enemies). Destroyed turrets respawn after TURRET_RESPAWN."""
    rows = []
    for sp in SHUTTLEPORTS:
        fac = 'FACTIONIMPERIAL' if sp['style'] == 'imperial' else 'FACTIONREBEL'
        h = shuttleport_height(sp)
        for x, y, yaw in turret_spots(sp):
            r = math.radians(yaw)
            rows.append(f'\t\t{{ x = {x}, z = {h}, y = {y}, qw = {math.cos(r / 2):.6f}, qy = {math.sin(r / 2):.6f}, '
                        f'faction = {fac} }}, -- {sp["name"]}')
    lua = f'''-- Generated by NewPlanets/move_outposts.py (turret_screenplay).
-- Faction turrets (small towers) at the fortified Hoth shuttleports: Imperial turrets at Eastern Ice Fields attack
-- overt Rebels, Rebel turrets at Generator Ridge attack overt Imperials. Destroyed turrets respawn after {TURRET_RESPAWN // 60} min.
HothShuttleportTurrets = ScreenPlay:new {{
	numberOfActs = 1,
	screenplayName = "HothShuttleportTurrets",
	planet = "hoth",
	template = "{TURRET_TEMPLATE}",
	respawnMs = {TURRET_RESPAWN * 1000},
	pvpBitmask = 5, -- ObjectFlag::ATTACKABLE (0x01) + ObjectFlag::OVERT (0x04); the Lua global OVERT is the faction status, not this flag
	turrets = {{
''' + '\n'.join(rows) + f'''
	}}
}}

registerScreenPlay("HothShuttleportTurrets", true)

function HothShuttleportTurrets:start()
	if (isZoneEnabled(self.planet)) then
		for i = 1, #self.turrets do
			self:spawnTurret(i)
		end
	end
end

function HothShuttleportTurrets:spawnTurret(i)
	local t = self.turrets[i]
	local pTurret = spawnSceneObject(self.planet, self.template, t.x, t.z, t.y, 0, t.qw, 0, t.qy, 0)

	if (pTurret == nil) then
		return
	end

	local turret = TangibleObject(pTurret)
	turret:setFaction(t.faction)
	turret:setPvpStatusBitmask(self.pvpBitmask)

	writeData(SceneObject(pTurret):getObjectID() .. ":hoth_shuttleport_turret", i)
	createObserver(OBJECTDESTRUCTION, "HothShuttleportTurrets", "onTurretDestroyed", pTurret)
end

function HothShuttleportTurrets:onTurretDestroyed(pTurret, pKiller)
	if (pTurret == nil) then
		return 1
	end

	local oid = SceneObject(pTurret):getObjectID()
	local i = readData(oid .. ":hoth_shuttleport_turret")
	deleteData(oid .. ":hoth_shuttleport_turret")

	if (pKiller ~= nil and SceneObject(pKiller):isCreatureObject()) then
		CreatureObject(pKiller):clearCombatState(1)
	end

	SceneObject(pTurret):destroyObjectFromWorld()

	if (i ~= nil and i > 0) then
		createEvent(self.respawnMs, "HothShuttleportTurrets", "respawnTurret", nil, tostring(i))
	end

	return 1
end

function HothShuttleportTurrets:respawnTurret(pObject, args)
	local i = tonumber(args)

	if (i ~= nil and self.turrets[i] ~= nil) then
		self:spawnTurret(i)
	end
end
'''
    p = os.path.join(WT, *TURRET_SCREENPLAY.split('/'))
    open(p, 'w', encoding='utf-8', newline='\n').write(lua)
    sp_list = os.path.join(WT, 'screenplays', 'screenplays.lua')
    s = open(sp_list, encoding='utf-8', newline='').read()
    inc = 'includeFile("static_spawns/hoth_shuttleport_turrets.lua")'
    if inc not in s:
        nl = '\r\n' if '\r\n' in s else '\n'
        anchor = 'includeFile("static_spawns/hoth_static_spawns.lua")'
        assert s.count(anchor) == 1
        s = s.replace(anchor, anchor + nl + inc)
        open(sp_list, 'w', encoding='utf-8', newline='').write(s)
    print(f'turrets: {len(rows)} -> {TURRET_SCREENPLAY}')


def add_defenses(root, nodes):
    """Append cloned top-level snapshot nodes for every SHUTTLEPORTS defense piece."""
    exemplar = {}
    for n in nodes:
        if n['pid'] == 0 and n['tmpl'] not in exemplar:
            exemplar[n['tmpl']] = n
    # the NODS list that holds the top-level NODE forms
    holder = None

    def find(ns):
        nonlocal holder
        for tag, ft, off, size, kids in ns:
            if tag == 'FORM' and ft == 'NODS':
                holder = kids
                return
            if tag == 'FORM':
                find(kids)
                if holder is not None:
                    return
    find(root)
    assert holder is not None
    top = {n['oid'] for n in nodes}
    oid = DEFENSE_OID_BASE
    added = 0
    for sp in SHUTTLEPORTS:
        h0 = shuttleport_height(sp)
        for tmpl, x, y, dh, yaw in defense_layout(sp):
            ex = exemplar[tmpl]
            # the exemplar's NODE form = the form whose 0000/DATA chunk list is ex['ref'][0]
            node = next(f for f in holder if f[0] == 'FORM' and f[1] == 'NODE' and
                        any(c[0] == 'FORM' and c[1] == '0000' and c[4] is ex['ref'][0] for c in f[4]))
            clone = copy.deepcopy(node)
            ver = next(c for c in clone[4] if c[0] == 'FORM' and c[1] == '0000')
            j = next(k for k, ch in enumerate(ver[4]) if ch[0] == 'DATA')
            d = bytearray(ver[4][j][4])
            while oid in top:
                oid += 1
            r = math.radians(yaw)
            struct.pack_into('<ii', d, 0, oid, 0)
            struct.pack_into('<4f', d, 16, math.cos(r / 2), 0.0, math.sin(r / 2), 0.0)
            struct.pack_into('<3f', d, 32, x, h0 + dh, y)
            ver[4][j] = (ver[4][j][0], ver[4][j][1], ver[4][j][2], ver[4][j][3], bytes(d))
            # drop any child nodes (statics have none; cells must not be cloned)
            clone[4][:] = [c for c in clone[4] if not (c[0] == 'FORM' and c[1] == 'NODS')]
            holder.append(clone)
            oid += 1
            added += 1
    return added


def build_regions(state):
    r = dt_tool.read(REGIONS)
    for row in r['rows']:
        key = row[0].split(':')[-1]
        site = key.replace('_outpost', '') if key.endswith('_outpost') else POIS_WITH.get(key)
        if site in MOVES:
            orig = {'scavenger': (0.0, -2000.0), 'imperial': (5927.0, -406.0), 'rebel': (4525.0, 1164.0),
                    'lucky_despot_wreck': (-100.0, -2048.0)}[key if key in POIS_WITH else site]
            dx, dy = state[site]['offset']
            row[1], row[2] = float(round(orig[0] + dx)), float(round(orig[1] + dy))
    dt_tool.write(r, REGIONS)
    print('radar regions:', [(row[0].split(':')[-1], row[1], row[2]) for row in r['rows']])


# ---------------------------------------------------------------- pass-2 probe
def write_probe(state):
    _, nodes = ws_nodes(open(SRC_WS, 'rb').read())
    pts = []
    for n in nodes:
        site = site_of(n)
        if site:
            dx, dy = state[site]['offset']
            pts.append((f'new_{site}_{n["oid"]}', n['x'] + dx, n['y'] + dy))
    for site, m in MOVES.items():
        pts.append((f'centre_{site}', m['new'][0], m['new'][1]))
    rows = ',\n'.join(f'\t{{"{t}", {x:.1f}, {y:.1f}}}' for t, x, y in pts)
    lua = open(os.path.join(HERE, 'server_prep', 'hoth_height_probe.lua')).read()
    head, rest = lua.split('local PTS = {', 1)
    tail = rest.split('\n}\n', 1)[1]
    open(os.path.join(HERE, 'server_prep', 'hoth_height_probe.lua'), 'w', newline='\n').write(
        head + 'local PTS = {\n' + rows + '\n}\n' + tail)
    print(f'probe: {len(pts)} points')


# ---------------------------------------------------------------- server worktree
def r1(v):
    return round(v, 1)


def server(state):
    def sub(path, pairs):
        p = os.path.join(WT, *path.split('/'))
        s = open(p, encoding='utf-8', newline='').read()
        for old, new in pairs:
            assert s.count(old) == 1, (path, old, s.count(old))
            s = s.replace(old, new)
        open(p, 'w', encoding='utf-8', newline='').write(s)
        print('patched', path, len(pairs))

    o = {k: state[k]['offset'] for k in MOVES}
    H = {k: state[k]['flat'] for k in MOVES}
    n = {k: (round(MOVES[k]['new'][0]), round(MOVES[k]['new'][1])) for k in MOVES}
    lucky = (round(-100 + o['scavenger'][0]), round(-2048 + o['scavenger'][1]))
    sub('managers/planet/hoth_regions.lua', [
        ('"@hoth_region_names:scavenger_outpost", 0, -2000,', f'"@hoth_region_names:scavenger_outpost", {n["scavenger"][0]}, {n["scavenger"][1]},'),
        ('"@hoth_region_names:imperial_outpost", 5927, -406,', f'"@hoth_region_names:imperial_outpost", {n["imperial"][0]}, {n["imperial"][1]},'),
        ('"@hoth_region_names:rebel_outpost", 4525, 1164,', f'"@hoth_region_names:rebel_outpost", {n["rebel"][0]}, {n["rebel"][1]},'),
        ('"hoth_scavenger_outpost_nobuild", 0, -2000,', f'"hoth_scavenger_outpost_nobuild", {n["scavenger"][0]}, {n["scavenger"][1]},'),
        ('"hoth_imperial_outpost_nobuild", 5927, -406,', f'"hoth_imperial_outpost_nobuild", {n["imperial"][0]}, {n["imperial"][1]},'),
        ('"hoth_rebel_outpost_nobuild", 4525, 1164,', f'"hoth_rebel_outpost_nobuild", {n["rebel"][0]}, {n["rebel"][1]},'),
        ('"@hoth_region_names:lucky_despot_wreck", -100, -2048,', f'"@hoth_region_names:lucky_despot_wreck", {lucky[0]}, {lucky[1]},'),
    ])
    tp = {'scavenger': (20.34, -1982.24), 'imperial': (5947.9, -388.71), 'rebel': (4528.65, 1190.75)}
    tpz = {'scavenger': '0', 'imperial': '3', 'rebel': '87.8'}
    label = {'scavenger': 'Scavenger Outpost', 'imperial': 'Imperial Outpost', 'rebel': 'Rebel Outpost'}  # pre-rename
    # (travel points were renamed to Imperial / Rebel Forward Base afterwards: rename_travel_points())
    pairs = []
    for k in MOVES:
        x, y = tp[k]
        pairs.append((f'{{name = "{label[k]}", x = {x}, z = {tpz[k]}, y = {y},',
                      f'{{name = "{label[k]}", x = {r1(x + o[k][0])}, z = {H[k]}, y = {r1(y + o[k][1])},'))
    nav_old = {'scavenger': '0, -2000', 'imperial': '5927, -406', 'rebel': '4525, 1164'}
    for k in MOVES:
        pairs.append((f'{{"hoth_{k}_outpost", {nav_old[k]}, 150}}', f'{{"hoth_{k}_outpost", {n[k][0]}, {n[k][1]}, 150}}'))
    sub('managers/planet/planet_manager.lua', pairs)
    # terminals: rewrite every hoth planetObjects terminal row (old rows ring the old starports)
    p = os.path.join(WT, 'managers', 'planet', 'planet_manager.lua')
    s = open(p, encoding='utf-8', newline='').read()
    start = s.index('planetObjects = {', s.index('\nhoth = {'))
    end = s.index('\n\t}', start)
    kinds = {'scavenger': ['terminal_mission', 'terminal_bank', 'terminal_bazaar'],
             'imperial': ['terminal_mission_imperial', 'terminal_bank', 'terminal_bazaar'],
             'rebel': ['terminal_mission_rebel', 'terminal_bank', 'terminal_bazaar']}
    centre = {'scavenger': (0.0, -2000.0), 'imperial': (5927.6, -406.5), 'rebel': (4525.0, 1164.0)}
    rows = []
    for k in MOVES:
        cx, cy = centre[k][0] + o[k][0], centre[k][1] + o[k][1]
        for i, t in enumerate(kinds[k]):
            rows.append(f'\t\t{{templateFile = "object/tangible/terminal/{t}.iff", ox = 0, oy = 0, oz = 0, ow = 1, '
                        f'x = {r1(cx - 16.0 + i * 3.0)}, z = {H[k]}, y = {r1(cy - 14.0)}, parentid = 0}},')
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s[:start] + 'planetObjects = {' + nl + nl.join(rows) + s[end:]
    open(p, 'w', encoding='utf-8', newline='').write(s)
    print('patched planet_manager.lua terminals', len(rows))
    print('\n# gen_hoth_mobiles.py OUTPOSTS / constants:')
    for k in MOVES:
        print(f"    '{k}': ({r1(centre[k][0] + o[k][0])}, {H[k]}, {r1(centre[k][1] + o[k][1])}),")
    print(f"    camp = ({r1(-95.0 + o['scavenger'][0])}, {H['scavenger']}, {r1(-2047.0 + o['scavenger'][1])})")
    print(f"    salvage = ({r1(5893.5 + o['imperial'][0])}, {H['imperial']}, {r1(-401.0 + o['imperial'][1])})")
    print(f"# gen_hoth_pois.py lucky_despot_wreck: {lucky}")


def shuttleports():
    """planet_manager.lua hoth block: travel point + shuttleport building per SHUTTLEPORTS entry (idempotent: rows are
    matched by name / position and rewritten)."""
    p = os.path.join(WT, 'managers', 'planet', 'planet_manager.lua')
    s = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    hoth = s.index('\nhoth = {')
    for sp in SHUTTLEPORTS:
        h = shuttleport_height(sp)
        tp = (f'\t\t{{name = "{sp["name"]}", x = {r1(sp["x"] - 19.0)}, z = {h}, y = {r1(sp["y"])}, '
              f'interplanetaryTravelAllowed = 0, incomingTravelAllowed = 1, landingRange = 3}},')
        bld = (f'\t\t{{templateFile = "{SHUTTLEPORT_TEMPLATE}", ox = 0, oy = 0, oz = 0, ow = 1, '
               f'x = {r1(sp["x"])}, z = {h}, y = {r1(sp["y"])}, parentid = 0}},')
        for row, anchor, needle in ((tp, 'planetTravelPoints = {', f'name = "{sp["name"]}"'),
                                    (bld, 'planetObjects = {', f'x = {r1(sp["x"])}, z = ')):
            a = s.index(anchor, hoth)
            end = s.index(nl + '\t}', a)
            block = s[a:end]
            lines = [l for l in block.split(nl) if not (needle in l and (SHUTTLEPORT_TEMPLATE in l or 'name =' in l))]
            block = nl.join(lines)
            if not block.rstrip().endswith(','):
                block = block.rstrip()
                if not block.endswith('{'):
                    block += ','
            s = s[:a] + block + nl + row + s[end:]
        print(f'{sp["name"]}: building ({sp["x"]}, {h}, {sp["y"]}), arrival ({r1(sp["x"] - 19.0)}, {sp["y"]})')
    open(p, 'w', encoding='utf-8', newline='').write(s)


TRAVEL_RENAMES = {'Imperial Outpost': 'Imperial Forward Base', 'Rebel Outpost': 'Rebel Forward Base'}


def rename_travel_points():
    p = os.path.join(WT, 'managers', 'planet', 'planet_manager.lua')
    s = open(p, encoding='utf-8', newline='').read()
    a = s.index('\nhoth = {')
    b = s.index('\n}', a)
    block = s[a:b]
    for old, new in TRAVEL_RENAMES.items():
        block = block.replace(f'name = "{old}"', f'name = "{new}"')
    open(p, 'w', encoding='utf-8', newline='').write(s[:a] + block + s[b:])
    print('travel points:', [l.strip()[:60] for l in block.splitlines() if 'name = "' in l])


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'shuttleports':
        shuttleports()
        rename_travel_points()
        turret_screenplay()
        sys.exit(0)
    if cmd == 'client':
        st = compute_state()
        print(json.dumps(st))
        build_terrain(st)
        build_snapshot(st, sys.argv[2] if len(sys.argv) > 2 else None)
        build_regions(st)
    elif cmd == 'probe':
        write_probe(json.load(open(STATE)))
    elif cmd == 'server':
        server(json.load(open(STATE)))
    else:
        print(__doc__)
