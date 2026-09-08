foundry_elite_b2_enforcer = Creature:new {
	objectName = "@mob/creature_names:rebel_super_battle_droid",
	customName = "Elite B2 Enforcer",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 158,
	chanceHit = 0.85,
	damageMin = 450,
	damageMax = 550,
	baseXp = 14000,
	baseHAM = 78000,
	baseHAMmax = 95000,
	armor = 2,
	resists = {40,40,40,40,40,40,40,-1,-1},

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
	scale = 1.35,

	templates = {
		"object/mobile/super_battle_droid.iff"
	},

	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_b2", chance = 10000000}},
			lootChance = 4000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_b2", chance = 10000000}},
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

CreatureTemplates:addCreatureTemplate(foundry_elite_b2_enforcer, "foundry_elite_b2_enforcer")
