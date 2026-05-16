-- Ender Project Manager: Dathomir reptilian meat (destroy mission lair).

dathomir_ender_projectmanager_reptilian_hunter_pack_neutral_none = Lair:new {
	mobiles = {{"ender_projectmanager_dathomir_reptilian_hunter",1}},
	spawnLimit = 15,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	buildingType = "none",
	missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff",
	customName = "Dathomir Reptilian Hunter",
}

addLairTemplate("dathomir_ender_projectmanager_reptilian_hunter_pack_neutral_none", dathomir_ender_projectmanager_reptilian_hunter_pack_neutral_none)
