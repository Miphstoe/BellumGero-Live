arctic_peko_peko = Creature:new {
	objectName = "",
	customName = "an Arctic Peko Peko",
	socialGroup = "peko",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 23,
	chanceHit = 0.35,
	damageMin = 210,
	damageMax = 220,
	baseXp = 2219,
	baseHAM = 5900,
	baseHAMmax = 7200,
	armor = 0,
	resists = {10,125,150,-1,-1,150,-1,-1,-1},
	meatType = "meat_avian",
	meatAmount = 155,
	hideType = "hide_wooly",
	hideAmount = 70,
	boneType = "bone_avian",
	boneAmount = 45,
	milk = 0,
	tamingChance = 0,
	ferocity = 8,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + HERD,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/giant_peko_peko.iff"},
	-- creature_bird_giant.pal: 24-31 blue ramp, 39 pale ice grey-blue (Naboo giant uses 0-7 red)
	hues = { 29, 30, 31, 39 },
	scale = 1.5,
	lootGroups = {},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	
	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"dizzyattack",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(arctic_peko_peko, "arctic_peko_peko")
