city_imperial_dark_trooper = Creature:new {
	objectName = "@mob/creature_names:dark_trooper",
	randomNameType = NAME_DARKTROOPER,
	randomNameTag = false,
	mobType = MOB_ANDROID,
	socialGroup = "imperial",
	faction = "imperial",
	level = 135,
	chanceHit = 0.38,
	damageMin = 350,
	damageMax = 500,
	baseXp = 4300,
	baseHAM = 50000,
	baseHAMmax = 60000,
	armor = 1,
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
	pvpBitmask = ATTACKABLE + OVERT,
	creatureBitmask = PACK + KILLER + NOINTIMIDATE + NODOT,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.5,

	templates = {"object/mobile/dark_trooper.iff"},
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

CreatureTemplates:addCreatureTemplate(city_imperial_dark_trooper, "city_imperial_dark_trooper")