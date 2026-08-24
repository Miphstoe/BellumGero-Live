foundry_elite_b2_enforcer = Creature:new {
	objectName = "@mob/creature_names:rebel_super_battle_droid",
	customName = "Elite B2 Enforcer",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 158,
	chanceHit = 0.7,
	damageMin = 340,
	damageMax = 410,
	baseXp = 10800,
	baseHAM = 39000,
	baseHAMmax = 48000,
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
	scale = 1.35,

	templates = {
		"object/mobile/super_battle_droid.iff"
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

CreatureTemplates:addCreatureTemplate(foundry_elite_b2_enforcer, "foundry_elite_b2_enforcer")
