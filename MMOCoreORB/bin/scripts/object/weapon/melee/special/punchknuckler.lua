object_weapon_melee_special_punchknuckler = object_weapon_melee_special_shared_punchknuckler:new {
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

	attackType = MELEEATTACK,
	weaponType = UNARMEDWEAPON,

	-- ENERGY, KINETIC, ELECTRICITY, STUN, BLAST, HEAT, COLD, ACID, LIGHTSABER
	damageType = KINETIC,

	-- NONE, LIGHT, MEDIUM, HEAVY
	armorPiercing = MEDIUM,

	-- combat_rangedspecialize_bactarifle, combat_rangedspecialize_rifle, combat_rangedspecialize_pistol, combat_rangedspecialize_heavy, combat_rangedspecialize_carbine
	-- combat_meleespecialize_unarmed, combat_meleespecialize_twohand, combat_meleespecialize_polearm, combat_meleespecialize_onehand, combat_general,
	-- combat_meleespecialize_twohandlightsaber, combat_meleespecialize_polearmlightsaber, combat_meleespecialize_onehandlightsaber
	xpType = "combat_meleespecialize_unarmed",

	certificationsRequired = { "cert_vibroknuckler" }, -- reuse cert so it equips like vibroknuckler
	creatureAccuracyModifiers = { "unarmed_accuracy" },

	defenderDefenseModifiers = { "melee_defense" },

	-- unarmed uses the passive defense style
	defenderSecondaryDefenseModifiers = { "unarmed_passive_defense" },

	defenderToughnessModifiers = { "unarmed_toughness" },

	speedModifiers = { "unarmed_speed" },

	-- Keep unarmed damage mod to preserve profession scaling
	damageModifiers = { "unarmed_damage" },


    -- The values below are the default values.  To be used for blue frog objects primarily
	healthAttackCost = 26,   
	actionAttackCost = 38,   
	mindAttackCost = 26,     
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = 12, 

	idealRange = 1,
	idealAccuracy = 12,      

	maxRange = 5,
	maxRangeAccuracy = 12,   

	minDamage = 60,          
	maxDamage = 168,         

	attackSpeed = 1.8,       

	woundsRatio = 30,        


	numberExperimentalProperties = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalProperties = {"XX", "XX", "SR", "SR", "SR", "SR", "SR", "SR", "SR", "XX", "SR", "XX", "SR", "SR", "SR"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "exp_durability", "expRange", "expRange", "null", "expRange", "null", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "maxrange", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 8, 72, 2.9, 17, 900, 6, 6, 1, 6, 5, 29, 43, 29},
	experimentalMax = {0, 0, 16, 133, 2.0, 31, 1800, 18, 18, 1, 18, 5, 14, 24, 14},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_melee_special_punchknuckler, "object/weapon/melee/special/punchknuckler.iff")
