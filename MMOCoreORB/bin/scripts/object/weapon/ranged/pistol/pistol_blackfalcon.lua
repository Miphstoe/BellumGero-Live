object_weapon_ranged_pistol_pistol_blackfalcon = object_weapon_ranged_pistol_shared_pistol_blackfalcon:new {
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

	xpType = "combat_rangedspecialize_pistol",

	certificationsRequired = { "cert_pistol_republic_blaster" },

	creatureAccuracyModifiers = { "pistol_accuracy" },
	creatureAimModifiers = { "pistol_aim", "aim" },

	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "dodge" },

	speedModifiers = { "pistol_speed" },

	damageModifiers = { },


	-- Blue Frog defaults (DC-15 stats; pistol close-range accuracy profile)
	healthAttackCost = 39,
	actionAttackCost = 34,
	mindAttackCost = 62,
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = 15,

	idealRange = 12,
	idealAccuracy = 5,

	maxRange = 64,
	maxRangeAccuracy = -45,

	minDamage = 162,
	maxDamage = 480,

	attackSpeed = 5.6,

	woundsRatio = 34,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "exp_durability", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "hitpoints", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 96, 240, 8.4, 18, 900, 5, 37, 31, 66},
	experimentalMax = {0, 0, 138, 450, 5.2, 35, 1800, 5, 20, 17, 36},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_pistol_pistol_blackfalcon, "object/weapon/ranged/pistol/pistol_blackfalcon.iff")
