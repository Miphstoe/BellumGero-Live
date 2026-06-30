--Copyright (C) 2010 <SWGEmu>
-- Bellum: Kashyyyk Tribal Master Bowcaster.
-- Lore: Crafted with honor and intricately designed by the greatest of
-- Wookiee weaponsmiths for brethren protectors who have mastered the art
-- of riflery. Generic galaxy-wide rare drop (see loot/groups/weapon/rifles.lua).
-- Client appearance + localized name / description / look-at: `shared_rifle_kashyyyk_tribal_master_bowcaster.iff`
-- in the patch TRE. Set IFF strings to `@weapon_name:rifle_kashyyyk_tribal_master_bowcaster`,
-- `@weapon_detail:rifle_kashyyyk_tribal_master_bowcaster`, `@weapon_lookat:rifle_kashyyyk_tribal_master_bowcaster`
-- (rows in `string/en/weapon_name.stf`, `weapon_detail.stf`, `weapon_lookat.stf`). Stock playerRaces (wookiee-only)
-- on the stock bowcaster shared template is overridden here so any species can equip; cert_rifle_bowcaster
-- is retained so only Riflemen with bowcaster training can wield it.

object_weapon_ranged_rifle_rifle_kashyyyk_tribal_master_bowcaster = object_weapon_ranged_rifle_shared_rifle_kashyyyk_tribal_master_bowcaster:new {

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
	armorPiercing = LIGHT,
	xpType = "combat_rangedspecialize_rifle",

	certificationsRequired = { "cert_rifle_bowcaster" },
	creatureAccuracyModifiers = { "rifle_accuracy" },
	creatureAimModifiers = { "rifle_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "block" },
	speedModifiers = { "rifle_speed" },
	damageModifiers = {},

	healthAttackCost = 30,
	actionAttackCost = 30,
	mindAttackCost = 38,
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = -30,

	idealRange = 45,
	idealAccuracy = 0,

	maxRange = 64,
	maxRangeAccuracy = -80,

	minDamage = 900,
	maxDamage = 1350,
	attackSpeed = 1.4,
	woundsRatio = 18,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 315, 640, 6.3, 10, 30, 750, -30, -80, 45, -5, 28, 28, 34},
	experimentalMax = {0, 0, 450, 775, 4.7, 20, 65, 1500, -30, -80, 45, 5, 16, 16, 22},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_rifle_rifle_kashyyyk_tribal_master_bowcaster, "object/weapon/ranged/rifle/rifle_kashyyyk_tribal_master_bowcaster.iff")
