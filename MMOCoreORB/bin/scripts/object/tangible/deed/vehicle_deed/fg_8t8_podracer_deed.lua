object_tangible_deed_vehicle_deed_fg_8t8_podracer_deed = object_tangible_deed_vehicle_deed_shared_fg_8t8_podracer_deed:new {

	templateType = VEHICLEDEED,

	controlDeviceObjectTemplate = "object/intangible/vehicle/fg_8t8_podracer_pcd.iff",
	generatedObjectTemplate = "object/mobile/vehicle/fg_8t8_podracer.iff",

	numberExperimentalProperties = {1, 1, 1},
	experimentalProperties = {"XX", "XX", "SR"},
	experimentalWeights = {1, 1, 1},
	experimentalGroupTitles = {"null", "null", "exp_durability"},
	experimentalSubGroupTitles = {"null", "null", "hit_points"},
	experimentalMin = {0, 0, 1500},
	experimentalMax = {0, 0, 3000},
	experimentalPrecision = {0, 0, 0},
	experimentalCombineType = {0, 0, 1},
}

ObjectTemplates:addTemplate(object_tangible_deed_vehicle_deed_fg_8t8_podracer_deed, "object/tangible/deed/vehicle_deed/fg_8t8_podracer_deed.iff")
