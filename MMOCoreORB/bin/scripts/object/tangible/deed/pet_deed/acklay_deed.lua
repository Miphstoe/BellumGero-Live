object_tangible_deed_pet_deed_acklay_deed = object_tangible_deed_pet_deed_shared_acklay_deed:new {

	templateType = PETDEED,
	numberExperimentalProperties = {1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "OQ", "PE", "OQ", "PE", "OQ", "PE", "OQ", "PE"},
	experimentalWeights = {1, 1, 13, 7, 7, 13, 7, 13, 7, 13},
	experimentalGroupTitles = {"null", "null", "exp_hitpointsmax", "expdamage", "expdamage", "expdamage"},
	experimentalSubGroupTitles = {"null", "null", "hp", "mindamage", "maxdamage", "accuracy"},
	experimentalMin = {0, 0, 0, 0, 0, 0},
	experimentalMax = {0, 0, 1, 1, 1, 1},
	experimentalPrecision = {0, 0, 0, 0, 0, 2},
	experimentalCombineType = {0, 0, 4, 4, 4, 4},

	generatedObjectTemplate = "mobile/pet/acklay_be.iff",
	controlDeviceObjectTemplate = "object/intangible/pet/acklay_hue.iff",
	mobileTemplate = "acklay_be",

	objectMenuComponent = "CityDecorationMenuComponent",
}

ObjectTemplates:addTemplate(object_tangible_deed_pet_deed_acklay_deed, "object/tangible/deed/pet_deed/acklay_deed.iff")
