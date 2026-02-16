-- Lair for Monstrous Dark Graul (Rori). Harvest: Rori wild meat.
-- See .cursor/context/ and bellum-gero.mdc for project context.

rori_monstrous_dark_graul_pack_neutral_none = Lair:new {
	mobiles = {{"monstrous_dark_graul",1}},
	spawnLimit = 15,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	buildingType = "none",
	missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff",
}

addLairTemplate("rori_monstrous_dark_graul_pack_neutral_none", rori_monstrous_dark_graul_pack_neutral_none)
