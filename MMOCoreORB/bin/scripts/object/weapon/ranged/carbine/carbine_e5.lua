object_weapon_ranged_carbine_carbine_e5 = object_weapon_ranged_carbine_shared_carbine_e5:new {
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

	armorPiercing = HEAVY,

	xpType = "combat_rangedspecialize_carbine",

	certificationsRequired = { "cert_carbine_nym_slugthrower" },

	creatureAccuracyModifiers = { "carbine_accuracy" },
	creatureAimModifiers = { "carbine_aim", "aim" },

	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "counterattack" },

	speedModifiers = { "carbine_speed" },

	damageModifiers = { },


	-- Blue Frog defaults (DC-15 stats; carbine mid-range accuracy profile)
	healthAttackCost = 39,
	actionAttackCost = 34,
	mindAttackCost = 62,
	forceCost = 0,

	pointBlankAccuracy = -20,
	pointBlankRange = 0,

	idealRange = 28,
	idealAccuracy = 10,

	maxRange = 64,
	maxRangeAccuracy = -35,

	minDamage = 162,
	maxDamage = 480,

	woundsRatio = 34,

	attackSpeed = 5.6,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 96, 240, 8.4, 18, 24, 900, -20, -35, 28, 10, 37, 31, 66},
	experimentalMax = {0, 0, 138, 450, 5.2, 35, 52, 1800, -20, -35, 28, 10, 20, 17, 36},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_carbine_carbine_e5, "object/weapon/ranged/carbine/carbine_e5.iff")
