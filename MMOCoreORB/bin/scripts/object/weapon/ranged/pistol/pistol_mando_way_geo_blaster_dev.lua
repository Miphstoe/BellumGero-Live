-- Dev override: overpowered Mandalorian Geonosian Blaster Pistol for local testing.
-- Shares the same client appearance as the normal version (no TRE changes needed).
object_weapon_ranged_pistol_pistol_mando_way_geo_blaster_dev = object_weapon_ranged_pistol_shared_pistol_mando_way_geo_blaster:new {
	customObjectName = "Mandalorian Geonosian Blaster Pistol (DEV)",

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

	certificationsRequired = { },
	creatureAccuracyModifiers = { "pistol_accuracy" },
	creatureAimModifiers = { "pistol_aim", "aim" },
	defenderDefenseModifiers = { "ranged_defense" },
	defenderSecondaryDefenseModifiers = { "dodge" },
	speedModifiers = { "pistol_speed" },
	damageModifiers = {},

	healthAttackCost = 5,
	actionAttackCost = 5,
	mindAttackCost = 5,
	forceCost = 0,

	pointBlankAccuracy = 50,
	pointBlankRange = 0,
	idealRange = 35,
	idealAccuracy = 100,
	maxRange = 64,
	maxRangeAccuracy = 80,

	minDamage = 500,
	maxDamage = 1200,
	attackSpeed = 1.2,
	woundsRatio = 50,
}

ObjectTemplates:addTemplate(object_weapon_ranged_pistol_pistol_mando_way_geo_blaster_dev, "object/weapon/ranged/pistol/pistol_mando_way_geo_blaster_dev.iff")
