
object_tangible_deed_pet_deed_deed_droideka_foundry = object_tangible_deed_pet_deed_shared_deed_droideka_foundry:new {
	templateType = DROIDDEED,
	customObjectName = "Deed for: Droideka",
	controlDeviceObjectTemplate = "object/intangible/pet/droideka_foundry.iff",
	generatedObjectTemplate = "object/mobile/droideka_crafted_foundry.iff",
	mobileTemplate = "droideka_crafted_foundry",
	species = 210,
	numberExperimentalProperties = {1, 1, 1, 1},
	experimentalProperties = {"XX", "XX", "OQ", "XX"},
	experimentalWeights = {1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "exp_effectiveness", "null"},
	experimentalSubGroupTitles = {"null", "null", "power_level", "cmbt_module"},
	experimentalMin = {0, 0, 50, 0},
	experimentalMax = {0, 0, 100, 0},
	experimentalPrecision = {0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1},
	objectMenuComponent = "CityDecorationMenuComponent",
}

ObjectTemplates:addTemplate(object_tangible_deed_pet_deed_deed_droideka_foundry, "object/tangible/deed/pet_deed/deed_droideka_foundry.iff")
