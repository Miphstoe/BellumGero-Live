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

	-- Points of interest
	{"@hoth_region_names:ice_caves", -400, 2600, {CIRCLE, 450}, NAMEDREGION + NOBUILDZONEAREA},
	{"@hoth_region_names:northern_ice_cavern", -5819, 6093, {CIRCLE, 150}, NAMEDREGION + NOBUILDZONEAREA},
	{"@hoth_region_names:shield_generator_battlefield", 5420, 780, {CIRCLE, 450}, NAMEDREGION + NOBUILDZONEAREA},
	{"@hoth_region_names:raider_camp", 5068, 1300, {CIRCLE, 80}, NAMEDREGION + NOSPAWNAREA + NOBUILDZONEAREA},
	{"@hoth_region_names:lucky_despot_wreck", -100, -2048, {CIRCLE, 60}, NAMEDREGION},

	-- World spawner (lairs, herds and patrols from mobile/spawn/hoth/hoth_world.lua)
	{"@hoth_region_names:world_spawner", 0, 0, {RECTANGLE, 0, 0}, SPAWNAREA + WORLDSPAWNAREA, {"hoth_world"}, 1024},
}
