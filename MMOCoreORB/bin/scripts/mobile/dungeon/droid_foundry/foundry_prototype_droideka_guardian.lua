foundry_prototype_droideka_guardian = Creature:new {
	objectName = "@mob/creature_names:droideka",
	customName = "Prototype Droideka Guardian",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 250,
	chanceHit = 0.99,
	damageMin = 550,
	damageMax = 660,
	baseXp = 16000,
	baseHAM = 99000,
	baseHAMmax = 121000,
	armor = 2,
	resists = {53,53,53,53,53,53,53,-1,-1},

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
	scale = 1.50,
	templates = {
		"object/mobile/droideka.iff"
	},

-- DROID_FOUNDRY_PROTOTYPE_ELITE_V1
	lootGroups = {
		{
			groups = {
				{group = "droid_foundry_kill_loot_droideka", chance = 10000000},
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "droid_foundry_kill_loot_generic", chance = 10000000},
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "droid_foundry_kill_loot_generic", chance = 10000000},
			},
			lootChance = 2500000,
		},
		{
			groups = {
				{group = "droid_foundry_schematics", chance = 10000000},
			},
			lootChance = 35000,
		},
	},

	conversationTemplate = "",
	reactionStf = "",

	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack"
}

CreatureTemplates:addCreatureTemplate(foundry_prototype_droideka_guardian, "foundry_prototype_droideka_guardian")
