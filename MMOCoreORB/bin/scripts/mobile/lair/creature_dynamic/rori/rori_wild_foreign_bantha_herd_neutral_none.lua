-- Lair for Wild Foreign Bantha (Rori). Harvest: Rori wild meat, wooly hide, animal bone, Rori wild milk.
-- See .cursor/context/ and bellum-gero.mdc for project context.

rori_wild_foreign_bantha_herd_neutral_none = Lair:new {
	mobiles = {{"wild_foreign_bantha_rori",1}},
	spawnLimit = 15,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	buildingType = "none",
	missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff",
	customName = "Wild Foreign Bantha Rori",
}

addLairTemplate("rori_wild_foreign_bantha_herd_neutral_none", rori_wild_foreign_bantha_herd_neutral_none)
