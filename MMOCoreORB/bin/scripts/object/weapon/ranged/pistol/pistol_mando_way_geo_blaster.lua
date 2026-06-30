-- Bellum: clan armory pistol (Initiate chapter). Client localized name/description:
-- `shared_pistol_mando_way_geo_blaster.iff` in bg_custom1.tre →
-- @weapon_name:pistol_mando_way_geo_blaster, @weapon_detail:..., @weapon_lookat:...
-- See docs/mando_way_armory_client_names.md. Until TRE ships, customObjectName overrides on server.
object_weapon_ranged_pistol_pistol_mando_way_geo_blaster = object_weapon_ranged_pistol_shared_pistol_mando_way_geo_blaster:new {
	customObjectName = "Mandalorian Geonosian Blaster Pistol",

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

	attackType = RANGEDATTACK,
	damageType = STUN,
	armorPiercing = LIGHT,
	xpType = "combat_rangedspecialize_pistol",

	certificationsRequired = { "cert_mando_way_geo_blaster" },
	creatureAccuracyModifiers = { "pistol_accuracy" },
	creatureAimModifiers = { "pistol_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "dodge" },
	speedModifiers = { "pistol_speed" },
	damageModifiers = {},

	healthAttackCost = 16,
	actionAttackCost = 38,
	mindAttackCost = 15,
	forceCost = 0,

	pointBlankAccuracy = 5,
	pointBlankRange = 0,
	idealRange = 18,
	idealAccuracy = 22,
	maxRange = 50,
	maxRangeAccuracy = 12,

	minDamage = 80,
	maxDamage = 180,
	attackSpeed = 2.8,
	woundsRatio = 14,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "expRange", "null", "null", "null", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 100, 200, 4.2, 10, 18, 600, 5, -70, 18, 12, 28, 38, 16},
	experimentalMax = {0, 0, 160, 280, 2.6, 20, 55, 1300, 5, -70, 18, 32, 12, 18, 6},
	experimentalPrecision = {0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_pistol_pistol_mando_way_geo_blaster, "object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.iff")