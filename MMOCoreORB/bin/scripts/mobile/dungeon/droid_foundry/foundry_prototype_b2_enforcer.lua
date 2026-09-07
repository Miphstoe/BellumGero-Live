foundry_prototype_b2_enforcer = Creature:new {
	objectName = "@mob/creature_names:rebel_super_battle_droid",
	customName = "Prototype B2 Enforcer",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 250,
	chanceHit = 0.94,
	damageMin = 495,
	damageMax = 605,
	baseXp = 14000,
	baseHAM = 85800,
	baseHAMmax = 104500,
	armor = 2,
	resists = {44,44,44,44,44,44,44,-1,-1},

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
	scale = 1.60,
	templates = {
		"object/mobile/super_battle_droid.iff"
	},

-- DROID_FOUNDRY_PROTOTYPE_ELITE_V1
	lootGroups = {
		{
			groups = {
				{group = "droid_foundry_kill_loot_b2", chance = 10000000},
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

	primaryWeapon = "battle_droid_weapons",
	secondaryWeapon = "unarmed",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "",

	primaryAttacks = merge(pistoleermaster, carbineermaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_prototype_b2_enforcer, "foundry_prototype_b2_enforcer")
