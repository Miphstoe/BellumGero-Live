foundry_elite_droideka_guardian = Creature:new {
	objectName = "@mob/creature_names:droideka",
	customName = "Elite Droideka Guardian",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_DROID,

	level = 165,
	chanceHit = 0.8,
	damageMin = 390,
	damageMax = 475,
	baseXp = 12200,
	baseHAM = 42000,
	baseHAMmax = 52000,
	armor = 2,
	resists = {42,42,42,42,42,42,42,-1,-1},

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

	lootGroups = {},

	conversationTemplate = "",
	reactionStf = "",

	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack"
}

CreatureTemplates:addCreatureTemplate(foundry_elite_droideka_guardian, "foundry_elite_droideka_guardian")
