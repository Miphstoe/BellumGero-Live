--Copyright (C) 2010 <SWGEmu>
-- Bellum: DL-44 appearance with rifle_bowcaster combat stats (all species).

object_weapon_ranged_pistol_pistol_bellum_bowcaster_stats = object_weapon_ranged_pistol_shared_pistol_dl44:new {
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
	damageType = ENERGY,
	armorPiercing = NONE,

	xpType = "combat_rangedspecialize_pistol",

	certificationsRequired = { "cert_pistol_dl44" },
	creatureAccuracyModifiers = { "pistol_accuracy" },

	creatureAimModifiers = { "pistol_aim", "aim" },

	defenderDefenseModifiers = { "ranged_defense" },

	defenderSecondaryDefenseModifiers = { "dodge" },

	speedModifiers = { "pistol_speed" },

	damageModifiers = { },

	healthAttackCost = 26,
	actionAttackCost = 26,
	mindAttackCost = 37,
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = -30,

	idealRange = 45,
	idealAccuracy = 0,

	maxRange = 64,
	maxRangeAccuracy = -80,

	minDamage = 1100,
	maxDamage = 1800,

	attackSpeed = 1.3,

	woundsRatio = 13,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 77, 131, 8, 9, 30, 750, -30, -80, 45, -5, 34, 34, 48},
	experimentalMax = {0, 0, 130, 234, 5, 17, 65, 1500, -30, -80, 45, 5, 18, 18, 26},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_pistol_pistol_bellum_bowcaster_stats, "object/weapon/ranged/pistol/pistol_bellum_bowcaster_stats.iff")
