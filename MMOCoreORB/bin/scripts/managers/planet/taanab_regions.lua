require("scripts.managers.planet.regions")

taanab_regions = {
	-- No Build Zones
	{"northedge_taanab_nobuild", -8000, 7640, {RECTANGLE, 8000, 8000}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"westedge_taanab_nobuild", -8000, -7640, {RECTANGLE, -7640, 7640}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"southedge_taanab_nobuild", -8000, -8000, {RECTANGLE, 8000, -7640}, NOSPAWNAREA + NOBUILDZONEAREA},
	{"eastedge_taanab_nobuild", 7640, -7640, {RECTANGLE, 7999, 7640}, NOSPAWNAREA + NOBUILDZONEAREA},

	-- Cities (starports from snapshot/taanab.ws; names from datatables/clientregion/taanab.iff)
	{"@taanab_region_names:pandath", 2011, 5400, {CIRCLE, 350}, CITY + NOSPAWNAREA},
	{"@taanab_region_names:starhunterstation", 3648, -5431, {CIRCLE, 200}, CITY + NOSPAWNAREA},

	{"taanab_pandath_nobuild", 2011, 5400, {CIRCLE, 550}, NOBUILDZONEAREA},
	{"taanab_starhunter_station_nobuild", 3648, -5431, {CIRCLE, 350}, NOBUILDZONEAREA},

	-- Points of interest (sites in the snapshot)
	{"@taanab_region_names:taanabmine", -2559, -1270, {CIRCLE, 250}, NAMEDREGION + NOBUILDZONEAREA + MAPPOI},
	{"@taanab_region_names:taanabhexfarms", -2970, -150, {CIRCLE, 350}, NAMEDREGION + NOBUILDZONEAREA + MAPPOI},
	{"@taanab_region_names:downedship", 3318, -1306, {CIRCLE, 100}, NAMEDREGION + NOBUILDZONEAREA + MAPPOI},
	{"@taanab_region_names:taanabcave", -861, 7206, {CIRCLE, 100}, NAMEDREGION + NOBUILDZONEAREA + MAPPOI},
	{"taanab_herder_camp_nobuild", 5536, -4957, {CIRCLE, 75}, NOBUILDZONEAREA},
}
