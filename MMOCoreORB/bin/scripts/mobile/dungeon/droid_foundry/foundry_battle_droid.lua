foundry_battle_droid = Creature:new {
	objectName = "@mob/creature_names:rebel_battle_droid",
	customName = "Foundry Battle Droid",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 140,
	chanceHit = 0.70,
	damageMin = 330,
	damageMax = 400,
	baseXp = 8000,
	baseHAM = 30000,
	baseHAMmax = 36000,
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

	templates = {
		"object/mobile/battle_droid.iff"
	},

	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_b1", chance = 10000000}},
			lootChance = 3000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_b1", chance = 10000000}},
			lootChance = 2000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 5000, -- 0.05% jackpot
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

CreatureTemplates:addCreatureTemplate(foundry_battle_droid, "foundry_battle_droid")
