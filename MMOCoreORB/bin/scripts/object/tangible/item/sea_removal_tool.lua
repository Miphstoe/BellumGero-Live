object_tangible_item_sea_removal_tool = object_tangible_item_shared_droid_customization:new {
    customName = "SEA Removal Tool",
    templateType = DROIDCUSTOMKIT,
    objectMenuComponent = "DroidCustomKitObjectMenuComponent",
    numberExperimentalProperties = {1, 1, 1, 1, 2},
    experimentalProperties = {"XX", "XX", "XX", "XX", "CD", "OQ"},
    experimentalWeights = {1, 1, 1, 1, 1, 1},
    experimentalGroupTitles = {"null", "null", "exp_durability", "null", "exp_quality"},
    experimentalSubGroupTitles = {"null", "null", "decayrate", "hitpoints", "charges"},
    experimentalMin = {0, 0, 5, 1000, 1},
    experimentalMax = {0, 0, 15, 1000, 10},
    experimentalPrecision = {0, 0, 0, 0, 0},
    experimentalCombineType = {0, 0, 1, 4, 1},
}

ObjectTemplates:addTemplate(object_tangible_item_sea_removal_tool, "object/tangible/item/sea_removal_tool.iff")