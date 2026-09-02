foundry_droideka_sentinel = Creature:new {
	objectName = "@mob/creature_names:droideka",
	customName = "Droideka Sentinel",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 155,
	chanceHit = 0.65,
	damageMin = 340,
	damageMax = 400,
	baseXp = 10000,
	baseHAM = 34000,
	baseHAMmax = 42000,
	armor = 2,
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

	templates = {
		"object/mobile/droideka.iff"
	},

	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_droideka", chance = 10000000}},
			lootChance = 3500000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_droideka", chance = 10000000}},
			lootChance = 2000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 5000, -- 0.05% jackpot
		},
	},

	conversationTemplate = "",
	reactionStf = "",

	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack"
}

CreatureTemplates:addCreatureTemplate(foundry_droideka_sentinel, "foundry_droideka_sentinel")
