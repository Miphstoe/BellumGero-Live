foundry_battle_droid = Creature:new {
	objectName = "@mob/creature_names:rebel_battle_droid",
	customName = "Foundry Battle Droid",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 140,
	chanceHit = 0.55,
	damageMin = 260,
	damageMax = 320,
	baseXp = 8000,
	baseHAM = 26000,
	baseHAMmax = 32000,
	armor = 1,
	resists = {20,20,20,20,20,20,20,-1,-1},

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

	lootGroups = {},

	primaryWeapon = "battle_droid_weapons",
	secondaryWeapon = "unarmed",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "",

	primaryAttacks = merge(pistoleermaster, carbineermaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_battle_droid, "foundry_battle_droid")
