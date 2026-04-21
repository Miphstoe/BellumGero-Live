object_tangible_deed_vehicle_deed_doctor_buff_droid_deed = object_tangible_deed_vehicle_deed_shared_jetpack_deed:new {
	templateType = VEHICLEDEED,
	customName = "Doctor Buff Droid",
	controlDeviceObjectTemplate = "object/intangible/vehicle/doctor_buff_droid_pcd.iff",
	generatedObjectTemplate = "object/tangible/vendor/doctor_buff_droid_vendor.iff",

	numberExperimentalProperties = {1, 1, 1},
	experimentalProperties = {"XX", "XX", "SR"},
	experimentalWeights = {1, 1, 1},
	experimentalGroupTitles = {"null", "null", "exp_durability"},
	experimentalSubGroupTitles = {"null", "null", "hit_points"},
	experimentalMin = {0, 0, 1000},
	experimentalMax = {0, 0, 2500},
	experimentalPrecision = {0, 0, 0},
	experimentalCombineType = {0, 0, 1},
}

ObjectTemplates:addTemplate(object_tangible_deed_vehicle_deed_doctor_buff_droid_deed, "object/tangible/deed/vehicle_deed/doctor_buff_droid_deed.iff")
