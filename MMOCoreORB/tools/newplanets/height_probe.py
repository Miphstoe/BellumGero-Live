#!/usr/bin/env python3
"""height_probe.py — write a temporary server screenplay that logs Core3 terrain heights ("HPROBE tag x y h") for
every snapshot object around the Hoth outposts and for grids around the new outpost sites.
  python height_probe.py            -> server_prep/hoth_height_probe.lua (install into the worktree, restart, grep log)
  python height_probe.py parse LOG  -> server_prep/hoth_heights.json
Not committed to the server repo; remove the screenplay + include after use."""
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)

OUT_LUA = os.path.join(HERE, 'server_prep', 'hoth_height_probe.lua')
OUT_JSON = os.path.join(HERE, 'server_prep', 'hoth_heights.json')
OLD = {'scavenger': (0.0, -2000.0), 'imperial': (5927.6, -406.5), 'rebel': (4525.0, 1164.0)}
NEW = {'scavenger': (-4030.0, -2080.0), 'imperial': (3820.0, -3080.0), 'rebel': (-420.0, 600.0)}
GRID = {'scavenger': (350, 50), 'imperial': (400, 50), 'rebel': (650, 50)}  # half-size, step


def points():
    import cave_points
    pts = []
    for n in cave_points.snapshot_nodes():
        if n[1] != 0:
            continue
        for name, (ox, oy) in OLD.items():
            if math.hypot(n[4] - ox, n[6] - oy) < 600:
                pts.append((f'obj_{name}_{n[0]}', n[4], n[6]))
    for name, (cx, cy) in NEW.items():
        half, step = GRID[name]
        r = int(half // step)
        for i in range(-r, r + 1):
            for j in range(-r, r + 1):
                pts.append((f'grid_{name}', cx + i * step, cy + j * step))
    return pts


def write():
    pts = points()
    rows = ',\n'.join(f'\t{{"{t}", {x:.1f}, {y:.1f}}}' for t, x, y in pts)
    lua = f'''-- TEMPORARY terrain height probe (NewPlanets/height_probe.py). Do not commit.
HothHeightProbe = ScreenPlay:new {{ screenplayName = "HothHeightProbe" }}
registerScreenPlay("HothHeightProbe", true)
local PTS = {{
{rows}
}}
function HothHeightProbe:start()
	if not isZoneEnabled("hoth") then return end
	local pMob = spawnMobile("hoth", "hoth_tauntaun", 0, 0, 0, 0, 0, 0)
	if pMob == nil then print("HPROBE failed to spawn probe mobile") return end
	for i = 1, #PTS do
		local p = PTS[i]
		print("HPROBE " .. p[1] .. " " .. p[2] .. " " .. p[3] .. " " .. getTerrainHeight(pMob, p[2], p[3]))
	end
	print("HPROBE done " .. #PTS)
	SceneObject(pMob):destroyObjectFromWorld()
end
'''
    os.makedirs(os.path.dirname(OUT_LUA), exist_ok=True)
    open(OUT_LUA, 'w', newline='\n').write(lua)
    print(f'{len(pts)} points -> {OUT_LUA}')


def parse(log):
    res = []
    for line in open(log, encoding='latin-1'):
        if 'HPROBE ' in line and ' done ' not in line:
            parts = line.split('HPROBE ', 1)[1].split()
            if len(parts) == 4:
                res.append((parts[0], float(parts[1]), float(parts[2]), float(parts[3])))
    json.dump(res, open(OUT_JSON, 'w'), indent=0)
    print(f'{len(res)} heights -> {OUT_JSON}')


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == 'parse':
        parse(sys.argv[2])
    else:
        write()
