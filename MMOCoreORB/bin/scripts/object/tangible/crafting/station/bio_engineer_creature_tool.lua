-- Dedicated Bio-Engineer creature crafting tool.
-- Uses the normal Food and Chemical Crafting Tool client appearance,
-- and exposes the Bio-Engineered creature and Genetics schematic tabs.

object_tangible_crafting_station_bio_engineer_creature_tool = object_tangible_crafting_station_shared_bio_engineer_creature_tool:new {
	templateType = CRAFTINGTOOL,

	playerRaces = {
		"object/creature/player/bothan_male.iff",
		"object/creature/player/bothan_female.iff",
		"object/creature/player/human_male.iff",
		"object/creature/player/human_female.iff",
		"object/creature/player/ithorian_male.iff",
		"object/creature/player/ithorian_female.iff",
		"object/creature/player/moncal_male.iff",
		"object/creature/player/moncal_female.iff",
		"object/creature/player/rodian_male.iff",
		"object/creature/player/rodian_female.iff",
		"object/creature/player/sullustan_male.iff",
		"object/creature/player/sullustan_female.iff",
		"object/creature/player/trandoshan_male.iff",
		"object/creature/player/trandoshan_female.iff",
		"object/creature/player/twilek_male.iff",
		"object/creature/player/twilek_female.iff",
		"object/creature/player/wookiee_male.iff",
		"object/creature/player/wookiee_female.iff",
		"object/creature/player/zabrak_male.iff",
		"object/creature/player/zabrak_female.iff"
	},

	customizationOptions = {},
	customizationDefaults = {},

	toolType = 2,
	complexityLevel = 20,
	enabledTabs = {256, 8192},

	numberExperimentalProperties = {1, 1, 1, 1},
	experimentalProperties = {"XX", "XX", "XX", "CD"},
	experimentalWeights = {1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "null", "exp_effectiveness"},
	experimentalSubGroupTitles = {"null", "null", "hitpoints", "usemodifier"},
	experimentalMin = {0, 0, 1000, -15},
	experimentalMax = {0, 0, 1000, 15},
	experimentalCombineType = {0, 0, 4, 1},
	experimentalPrecision = {0, 0, 0, 0},
}

ObjectTemplates:addTemplate(object_tangible_crafting_station_bio_engineer_creature_tool,
	"object/tangible/crafting/station/bio_engineer_creature_tool.iff")
