-- Bellum: clan armory lightning rifle (Verd'ika chapter). Client STF keys: rifle_mando_way_lightning
-- (docs/mando_way_armory_client_names.md). customObjectName until bg_custom1 IFF+STF live.
object_weapon_ranged_rifle_rifle_mando_way_lightning = object_weapon_ranged_rifle_shared_rifle_mando_way_lightning:new {
	customObjectName = "Mandalorian Light Lightning Cannon",

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
	weaponType = SPECIALHEAVYWEAPON,
	damageType = ELECTRICITY,
	armorPiercing = MEDIUM,
	xpType = "combat_rangedspecialize_heavy",

	certificationsRequired = { "cert_mando_way_lightning_cannon" },
	creatureAccuracyModifiers = { "heavy_rifle_lightning_accuracy" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "block" },
	speedModifiers = { "heavy_rifle_lightning_speed" },
	damageModifiers = {},

	healthAttackCost = 48,
	actionAttackCost = 64,
	mindAttackCost = 48,
	forceCost = 0,

	pointBlankRange = 0,
	pointBlankAccuracy = -5,
	idealRange = 32,
	idealAccuracy = 28,
	maxRange = 64,
	maxRangeAccuracy = 8,

	minDamage = 666,
	maxDamage = 999,
	attackSpeed = 1.5,
	woundsRatio = 28,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 1, 2, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "CD", "OQ", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "expRange", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 315, 640, 6.3, 10, 32, 850, -5, 32, 0, 36, 54, 30},
	experimentalMax = {0, 0, 450, 775, 4.7, 20, 68, 1650, 22, 32, 18, 24, 34, 20},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_rifle_rifle_mando_way_lightning, "object/weapon/ranged/rifle/rifle_mando_way_lightning.iff")
