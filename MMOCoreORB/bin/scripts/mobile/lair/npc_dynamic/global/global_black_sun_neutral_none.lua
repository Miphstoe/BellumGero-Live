global_black_sun_neutral_none = Lair:new {
	mobiles = {
		{"black_sun_assassin",2},
		{"black_sun_guard",4},
		{"black_sun_henchman",4},
		{"black_sun_thug",6}
	},
	spawnLimit = 18,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	mobType = "npc",
	missionBuilding = "object/tangible/lair/base/objective_banner_generic_2.iff",
	buildingType = "none"
}

addLairTemplate("global_black_sun_neutral_none", global_black_sun_neutral_none)
