ancient_paralope = Creature:new {
	objectName = "@mob/creature_names:paralope",
	customName = "Ancient Paralope",
	socialGroup = "paralope",
	faction = "",
	mobType = MOB_HERBIVORE,
	level = 38,
	chanceHit = 0.42,
	damageMin = 345,
	damageMax = 400,
	baseXp = 3824,
	baseHAM = 10000,
	baseHAMmax = 12200,
	armor = 0,
	resists = {20,15,0,0,0,0,0,-1,-1},
	meatType = "meat_herbivore",
	meatAmount = 65,
	hideType = "hide_wooly",
	hideAmount = 75,
	boneType = "bone_mammal",
	boneAmount = 60,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + HERD + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/paralope.iff"},
	hues = { 24, 25, 26, 27, 28, 29, 30, 31 },
	scale = 1.75,
	lootGroups = {},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"intimidationattack",""}, {"knockdownattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ancient_paralope, "ancient_paralope")
