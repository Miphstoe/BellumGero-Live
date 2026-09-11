-- Bellum Gero Ubese Armor Full-Suit Crafting

object_tangible_wearables_armor_ubese_armor_ubese_suit_package =
	object_tangible_wearables_armor_ubese_shared_armor_ubese_suit_package:new {

	templateType = ARMOROBJECT,
	objectMenuComponent = "ArmorSuitPackageMenuComponent",
	customObjectName = "Ubese Armor Suit Package",

	vulnerability = STUN + LIGHTSABER,
	specialResists = KINETIC,
	healthEncumbrance = 450,
	actionEncumbrance = 373,
	mindEncumbrance = 450,
	maxCondition = 30000,
	rating = LIGHT,

	kinetic = 45,
	energy = 30,
	electricity = 30,
	stun = 0,
	blast = 30,
	heat = 30,
	cold = 30,
	acid = 30,
	lightSaber = 0,

	numberExperimentalProperties = {1,1,1,1,2,2,2,2,2,1,1,2,1},
	experimentalProperties = {"XX","XX","XX","XX","OQ","SR","OQ","UT","MA","OQ","MA","OQ","MA","OQ","XX","XX","OQ","SR","XX"},
	experimentalWeights = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	experimentalGroupTitles = {"null","null","null","exp_durability","exp_quality","exp_resistance","exp_durability","exp_durability","exp_durability","null","null","exp_resistance","null"},
	experimentalSubGroupTitles = {"null","null","sockets","hit_points","armor_effectiveness","armor_integrity","armor_health_encumbrance","armor_action_encumbrance","armor_mind_encumbrance","armor_rating","armor_special_type","armor_special_effectiveness","armor_special_integrity"},
	experimentalMin = {0,0,0,1000,1,30000,450,373,450,1,0,0,0},
	experimentalMax = {0,0,0,1000,40,50000,270,222,270,1,0,0,0},
	experimentalPrecision = {0,0,0,0,10,0,0,0,0,0,0,0,0},
	experimentalCombineType = {0,0,4,1,1,1,1,1,1,4,4,4,1},
}

ObjectTemplates:addTemplate(
	object_tangible_wearables_armor_ubese_armor_ubese_suit_package,
	"object/tangible/wearables/armor/ubese/armor_ubese_suit_package.iff")
