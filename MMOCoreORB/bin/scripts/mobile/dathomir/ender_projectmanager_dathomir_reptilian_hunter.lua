-- Ender Project Manager: Dathomir reptilian meat harvester (meat_reptilian_dathomir).
-- General mission terminal destroy targets; mid-high band for Dathomir.

ender_projectmanager_dathomir_reptilian_hunter = Creature:new {
	objectName = "@mob/creature_names:mature_reptilian_flier",
	customName = "Dathomir Reptilian Hunter",
	socialGroup = "reptilian_flier",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 32,
	chanceHit = 0.37,
	damageMin = 300,
	damageMax = 390,
	baseXp = 3000,
	baseHAM = 8800,
	baseHAMmax = 10800,
	armor = 0,
	resists = {15,120,15,140,140,15,15,-1,-1},
	meatType = "meat_reptilian_dathomir",
	meatAmount = 950,
	hideType = "hide_leathery",
	hideAmount = 130,
	boneType = "bone_avian",
	boneAmount = 90,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 7,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/reptilian_flier_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	controlDeviceTemplate = "object/intangible/pet/pet_control.iff",
	scale = 1.1,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"blindattack",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_dathomir_reptilian_hunter, "ender_projectmanager_dathomir_reptilian_hunter")
