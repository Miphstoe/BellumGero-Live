-- Lair for Wild Foreign Bantha (Talus). Harvest: Talus wild meat, wooly hide, animal bone.
-- See .cursor/context/ and bellum-gero.mdc for project context.

talus_wild_foreign_bantha_herd_neutral_none = Lair:new {
	mobiles = {{"wild_foreign_bantha",1}},
	spawnLimit = 15,
	buildingsVeryEasy = {},
	buildingsEasy = {},
	buildingsMedium = {},
	buildingsHard = {},
	buildingsVeryHard = {},
	buildingType = "none"
}

addLairTemplate("talus_wild_foreign_bantha_herd_neutral_none", talus_wild_foreign_bantha_herd_neutral_none)
