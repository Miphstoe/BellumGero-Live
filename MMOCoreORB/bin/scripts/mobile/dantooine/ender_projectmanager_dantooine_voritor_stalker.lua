-- Ender Project Manager: Dantooine reptilian meat harvester (meat_reptilian_dantooine).
-- General mission terminal destroy targets; mid-high band for Dantooine.

ender_projectmanager_dantooine_voritor_stalker = Creature:new {
	objectName = "@mob/creature_names:voritor_lizard",
	customName = "Dantooine Voritor Stalker",
	socialGroup = "voritor",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 34,
	chanceHit = 0.38,
	damageMin = 320,
	damageMax = 410,
	baseXp = 3200,
	baseHAM = 9200,
	baseHAMmax = 11200,
	armor = 1,
	resists = {25,25,25,25,25,25,25,-1,-1},
	meatType = "meat_reptilian_dantooine",
	meatAmount = 950,
	hideType = "hide_leathery",
	hideAmount = 140,
	boneType = "bone_avian",
	boneAmount = 95,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 8,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/voritor_lizard_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	controlDeviceTemplate = "object/intangible/pet/voritor_lizard_hue.iff",
	scale = 1.12,
	lootGroups = {},

	primaryWeapon = "object/weapon/ranged/creature/creature_spit_small_green.iff",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",

	primaryAttacks = { {"poisonattack",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_dantooine_voritor_stalker, "ender_projectmanager_dantooine_voritor_stalker")
