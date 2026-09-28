require("scripts.managers.planet.regions")

hoth_regions = {
	-- No Build Zones
	{"northedge_hoth_nobuild", -8000, 7640, {RECTANGLE, 8000, 8000}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"westedge_hoth_nobuild", -8000, -7640, {RECTANGLE, -7640, 7640}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"southedge_hoth_nobuild", -8000, -8000, {RECTANGLE, 8000, -7640}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"eastedge_hoth_nobuild", 7640, -7640, {RECTANGLE, 7999, 7640}, NOSPAWNAREA + NOBUILDZONEAREA},

	-- Cities (starports from snapshot/hoth.ws)
	{"@hoth_region_names:scavenger_outpost", 0, -2000, {CIRCLE, 200}, CITY + NOSPAWNAREA},
	{"@hoth_region_names:imperial_outpost", 5927, -406, {CIRCLE, 200}, CITY + NOSPAWNAREA},
	{"@hoth_region_names:rebel_outpost", 4525, 1164, {CIRCLE, 200}, CITY + NOSPAWNAREA},

	{"hoth_scavenger_outpost_nobuild", 0, -2000, {CIRCLE, 300}, NOBUILDZONEAREA},
	{"hoth_imperial_outpost_nobuild", 5927, -406, {CIRCLE, 300}, NOBUILDZONEAREA},
	{"hoth_rebel_outpost_nobuild", 4525, 1164, {CIRCLE, 300}, NOBUILDZONEAREA},

	-- TODO: SPAWNAREA + WORLDSPAWNAREA world spawner once scripts/mobile/hoth exists
}
