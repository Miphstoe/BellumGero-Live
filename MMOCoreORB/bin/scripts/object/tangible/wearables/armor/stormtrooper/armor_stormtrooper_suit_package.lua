-- Bellum Gero Stormtrooper Armor Full-Suit Crafting
object_tangible_wearables_armor_stormtrooper_armor_stormtrooper_suit_package = object_tangible_wearables_armor_stormtrooper_shared_armor_stormtrooper_suit_package:new {
	templateType = ARMOROBJECT,
	objectMenuComponent = "ArmorSuitPackageMenuComponent",
	customObjectName = "Stormtrooper Armor Suit Package",
	vulnerability = STUN + LIGHTSABER,
	specialResists = 0,
	healthEncumbrance = 500, actionEncumbrance = 417, mindEncumbrance = 500,
	maxCondition = 30000, rating = LIGHT,
	kinetic = 30, energy = 30, electricity = 30, stun = 0, blast = 30, heat = 0, cold = 30, acid = 0, lightSaber = 0,
	numberExperimentalProperties = {1,1,1,1,2,2,2,2,2,1,1,2,1},
	experimentalProperties = {"XX","XX","XX","XX","OQ","SR","OQ","UT","MA","OQ","MA","OQ","MA","OQ","XX","XX","OQ","SR","XX"},
	experimentalWeights = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	experimentalGroupTitles = {"null","null","null","exp_durability","exp_quality","exp_resistance","exp_durability","exp_durability","exp_durability","null","null","exp_resistance","null"},
	experimentalSubGroupTitles = {"null","null","sockets","hit_points","armor_effectiveness","armor_integrity","armor_health_encumbrance","armor_action_encumbrance","armor_mind_encumbrance","armor_rating","armor_special_type","armor_special_effectiveness","armor_special_integrity"},
	experimentalMin = {0,0,0,1000,1,30000,500,417,500,1,0,0,0},
	experimentalMax = {0,0,0,1000,40,50000,300,248,300,1,0,0,0},
	experimentalPrecision = {0,0,0,0,10,0,0,0,0,0,0,0,0},
	experimentalCombineType = {0,0,4,1,1,1,1,1,1,4,4,4,1},
}
ObjectTemplates:addTemplate(object_tangible_wearables_armor_stormtrooper_armor_stormtrooper_suit_package, "object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_suit_package.iff")
