foundry_elite_b1_command_droid = Creature:new {
	objectName = "@mob/creature_names:rebel_battle_droid",
	customName = "Elite B1 Command Droid",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 148,
	chanceHit = 0.7,
	damageMin = 300,
	damageMax = 370,
	baseXp = 9500,
	baseHAM = 32000,
	baseHAMmax = 39000,
	armor = 1,
	resists = {28,28,28,28,28,28,28,-1,-1},

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

	lootGroups = {},

	primaryWeapon = "battle_droid_weapons",
	secondaryWeapon = "unarmed",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "",

	primaryAttacks = merge(pistoleermaster, carbineermaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_elite_b1_command_droid, "foundry_elite_b1_command_droid")
