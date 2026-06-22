object_tangible_deed_player_house_deed_diner_house_deed = object_tangible_deed_player_house_deed_shared_diner_house_deed:new {
	templateType = STRUCTUREDEED,
	placeStructureComponent = "PlaceStructureComponent",
	generatedObjectTemplate = "object/building/player/diner_house.iff",
	numberExperimentalProperties = {1, 1, 1, 1, 1},
	experimentalProperties = {"XX", "XX", "XX", "OQ", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "null", "expEffeciency", "expStorage"},
	experimentalSubGroupTitles = {"null", "null", "null", "maintenancereduction", "storagebonus"},
	experimentalMin = {0, 0, 0, 0, 0},
	experimentalMax = {0, 0, 0, 25, 100},
	experimentalPrecision = {0, 0, 0, 1, 0},
	experimentalCombineType = {0, 0, 0, 1, 1},

}

ObjectTemplates:addTemplate(object_tangible_deed_player_house_deed_diner_house_deed, "object/tangible/deed/player_house_deed/diner_house_deed.iff")