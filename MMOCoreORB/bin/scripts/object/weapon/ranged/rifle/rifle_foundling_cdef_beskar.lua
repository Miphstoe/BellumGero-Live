--Copyright (C) 2010 <SWGEmu>
-- Bellum: Foundling kit. CDEF certification, Beskar naming, recruiter grant on arc start.

object_weapon_ranged_rifle_rifle_foundling_cdef_beskar = object_weapon_ranged_rifle_shared_rifle_cdef:new {
	customObjectName = "Foundling Beskar CDEF Rifle",

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
	xpType = "combat_rangedspecialize_rifle",

	certificationsRequired = { "cert_rifle_cdef" },
	creatureAccuracyModifiers = { "rifle_accuracy" },
	creatureAimModifiers = { "rifle_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "block" },
	speedModifiers = { "rifle_speed" },
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

	minDamage = 666,
	maxDamage = 666,
	attackSpeed = 0.6,
	woundsRatio = 13,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 666, 666, 0.6, 9, 30, 750, 0, -80, 35, 35, 10, 22, 10},
	experimentalMax = {0, 0, 666, 666, 0.6, 17, 65, 1500, 0, -80, 35, 65, 7, 15, 7},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_rifle_rifle_foundling_cdef_beskar, "object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.iff")
