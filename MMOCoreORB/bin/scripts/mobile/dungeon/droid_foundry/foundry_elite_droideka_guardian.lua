foundry_elite_droideka_guardian = Creature:new {
	objectName = "@mob/creature_names:droideka",
	customName = "Elite Droideka Guardian",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 165,
	chanceHit = 0.90,
	damageMin = 500,
	damageMax = 600,
	baseXp = 16000,
	baseHAM = 90000,
	baseHAMmax = 110000,
	armor = 2,
	resists = {48,48,48,48,48,48,48,-1,-1},

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
	scale = 1.2,

	templates = {
		"object/mobile/droideka.iff"
	},

	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_droideka", chance = 10000000}},
			lootChance = 4000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_droideka", chance = 10000000}},
			lootChance = 3000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 25000, -- 0.25% jackpot
		},
	},

	conversationTemplate = "",
	reactionStf = "",

	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack"
}

CreatureTemplates:addCreatureTemplate(foundry_elite_droideka_guardian, "foundry_elite_droideka_guardian")
