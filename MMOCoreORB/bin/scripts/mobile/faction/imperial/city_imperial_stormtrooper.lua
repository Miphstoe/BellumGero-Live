city_imperial_stormtrooper = Creature:new {
	objectName = "@mob/creature_names:fbase_stormtrooper",
	randomNameType = NAME_STORMTROOPER,
	socialGroup = "imperial",
	mobType = MOB_NPC,
	faction = "imperial",
	level = 100,
	chanceHit = 0.38,
	damageMin = 250,
	damageMax = 400,
	baseXp = 3300,
	baseHAM = 25000,
	baseHAMmax = 30000,
	armor = 0,
	resists = {20,20,20,20,-1,20,-1,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.05,

	templates = {"object/mobile/dressed_stormtrooper_m.iff"},
	lootGroups = {},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "imperial_carbine",
	secondaryWeapon = "imperial_pistol",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(marksmanmaster,carbineermaster),
	secondaryAttacks = merge(marksmanmaster,pistoleermaster),
}

CreatureTemplates:addCreatureTemplate(city_imperial_stormtrooper, "city_imperial_stormtrooper")