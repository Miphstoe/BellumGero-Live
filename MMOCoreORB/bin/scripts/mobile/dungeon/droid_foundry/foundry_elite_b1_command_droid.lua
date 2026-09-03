foundry_elite_b1_command_droid = Creature:new {
	objectName = "@mob/creature_names:rebel_battle_droid",
	customName = "Elite B1 Command Droid",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 148,
	chanceHit = 0.85,
	damageMin = 430,
	damageMax = 520,
	baseXp = 12000,
	baseHAM = 65000,
	baseHAMmax = 82000,
	armor = 1,
	resists = {35,35,35,35,35,35,35,-1,-1},

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
	scale = 1.25,

	templates = {
		"object/mobile/battle_droid.iff"
	},

	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_b1", chance = 10000000}},
			lootChance = 4000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_b1", chance = 10000000}},
			lootChance = 3000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 25000, -- 0.25% jackpot
		},
	},

	primaryWeapon = "battle_droid_weapons",
	secondaryWeapon = "unarmed",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "",

	primaryAttacks = merge(pistoleermaster, carbineermaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_elite_b1_command_droid, "foundry_elite_b1_command_droid")
