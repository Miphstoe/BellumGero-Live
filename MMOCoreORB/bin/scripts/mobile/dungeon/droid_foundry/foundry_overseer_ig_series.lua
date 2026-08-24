foundry_overseer_ig_series = Creature:new {
	objectName = "@mob/creature_names:ig_assassin_droid",
	customName = "Foundry Overseer",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_ANDROID,

	level = 175,
	chanceHit = 0.95,
	damageMin = 475,
	damageMax = 600,
	baseXp = 18000,
	baseHAM = 90000,
	baseHAMmax = 110000,
	armor = 2,
	resists = {50,50,50,50,50,50,50,-1,-1},

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
	diet = NONE,
	scale = 1.75,

	templates = {"object/mobile/ig_assassin_droid.iff"},
	lootGroups = {},

	conversationTemplate = "",
	reactionStf = "",
	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack"
}

CreatureTemplates:addCreatureTemplate(foundry_overseer_ig_series, "foundry_overseer_ig_series")
