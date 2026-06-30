-- Bellum: clan armory carbine (Hunter chapter). Client STF keys: carbine_mando_way_slugthrower
-- (docs/mando_way_armory_client_names.md). customObjectName until bg_custom1 IFF+STF live.
object_weapon_ranged_carbine_carbine_mando_way_slugthrower = object_weapon_ranged_carbine_shared_carbine_mando_way_slugthrower:new {
	customObjectName = "Mandalorian Nym Slugthrower Carbine",

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
	damageType = ACID,
	armorPiercing = MEDIUM,
	xpType = "combat_rangedspecialize_carbine",

	certificationsRequired = { "cert_mando_way_slugthrower_carbine" },
	creatureAccuracyModifiers = { "carbine_accuracy" },
	creatureAimModifiers = { "carbine_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "counterattack" },
	speedModifiers = { "carbine_speed" },
	damageModifiers = {},

	healthAttackCost = 32,
	actionAttackCost = 58,
	mindAttackCost = 28,
	forceCost = 0,

	pointBlankAccuracy = -5,
	pointBlankRange = 0,
	idealRange = 30,
	idealAccuracy = 8,
	maxRange = 64,
	maxRangeAccuracy = -45,

	minDamage = 666,
	maxDamage = 999,
	woundsRatio = 18,
	attackSpeed = 1.5,

	numberExperimentalProperties = {1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2},
	experimentalProperties = {"XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ", "XX", "XX", "XX", "CD", "OQ", "CD", "OQ", "CD", "OQ", "CD", "OQ"},
	experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "expDamage", "expDamage", "expDamage", "expDamage", "expEffeciency", "exp_durability", "null", "null", "null", "expRange", "expEffeciency", "expEffeciency", "expEffeciency"},
	experimentalSubGroupTitles = {"null", "null", "mindamage", "maxdamage", "attackspeed", "woundchance", "roundsused", "hitpoints", "zerorangemod", "maxrangemod", "midrange", "midrangemod", "attackhealthcost", "attackactioncost", "attackmindcost"},
	experimentalMin = {0, 0, 800, 1100, 4.4, 10, 32, 850, -25, -40, 40, 8, 28, 45, 22},
	experimentalMax = {0, 0, 1200, 1700, 3.0, 20, 68, 1650, -25, -40, 40, 18, 15, 24, 12},
	experimentalPrecision = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	experimentalCombineType = {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

ObjectTemplates:addTemplate(object_weapon_ranged_carbine_carbine_mando_way_slugthrower, "object/weapon/ranged/carbine/carbine_mando_way_slugthrower.iff")