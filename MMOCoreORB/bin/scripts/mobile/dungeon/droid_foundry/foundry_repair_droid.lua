foundry_repair_droid = Creature:new {
	objectName = "@mob/creature_names:le_repair_droid",
	customName = "Foundry Repair Droid",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 145,
	chanceHit = 0.45,
	damageMin = 140,
	damageMax = 200,
	baseXp = 7000,
	baseHAM = 28000,
	baseHAMmax = 34000,
	armor = 1,
	resists = {25,25,25,25,25,25,25,-1,-1},

	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,

	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/le_repair_droid.iff"},
	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_generic", chance = 10000000}},
			lootChance = 3000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_generic", chance = 10000000}},
			lootChance = 2000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 5000, -- 0.05% jackpot
		},
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_repair_droid, "foundry_repair_droid")
