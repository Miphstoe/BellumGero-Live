--Copyright (C) 2010 <SWGEmu>
-- Bellum: Foundling kit. CDEF certification, Beskar naming, recruiter grant on arc start.

object_weapon_ranged_pistol_pistol_foundling_cdef_beskar = object_weapon_ranged_pistol_shared_pistol_cdef:new {
	customName = "Foundling Beskar Polished Pistol",

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

	certificationsRequired = { "cert_pistol_cdef" },
	creatureAccuracyModifiers = { "pistol_accuracy" },
	creatureAimModifiers = { "pistol_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "dodge" },
	speedModifiers = { "pistol_speed" },
	damageModifiers = {},

	healthAttackCost = 10,
	actionAttackCost = 15,
	mindAttackCost = 10,
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = 20,
	idealRange = 15,
	idealAccuracy = 50,
	maxRange = 64,
	maxRangeAccuracy = -80,

	minDamage = 333,
	maxDamage = 333,
	attackSpeed = 2,
	woundsRatio = 13,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 333, 333, 2, 9, 30, 750, 0, -80, 15, 35, 10, 22, 10},
	experimentalMax = {0, 0, 333, 333, 2, 17, 65, 1500, 0, -80, 15, 65, 7, 15, 7},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_pistol_pistol_foundling_cdef_beskar, "object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.iff")
