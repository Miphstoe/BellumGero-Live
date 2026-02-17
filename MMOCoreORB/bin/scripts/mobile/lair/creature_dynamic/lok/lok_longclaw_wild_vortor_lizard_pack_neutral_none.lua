-- Lair for LongClaw Wild Vortor Lizard (Lok). Harvest: Lok wild meat, animal bone, scaley hide.
-- See .cursor/context/ and bellum-gero.mdc for project context.

lok_longclaw_wild_vortor_lizard_pack_neutral_none = Lair:new {
	mobiles = {{"longclaw_wild_vortor_lizard",1}},
	spawnLimit = 15,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	buildingType = "none",
	missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff",
	customName = "Longclaw Wild Vortor Lizard",
}

addLairTemplate("lok_longclaw_wild_vortor_lizard_pack_neutral_none", lok_longclaw_wild_vortor_lizard_pack_neutral_none)
