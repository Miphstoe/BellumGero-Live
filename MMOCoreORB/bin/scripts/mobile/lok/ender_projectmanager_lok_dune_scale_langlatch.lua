-- Ender Project Manager: Lok reptilian meat harvester (meat_reptilian_lok).
-- General mission terminal destroy targets; mid-high band for Lok (above Longclaw Vortor).

ender_projectmanager_lok_dune_scale_langlatch = Creature:new {
	objectName = "@mob/creature_names:langlatch_hunter",
	customName = "Lok Dune Scale Langlatch",
	socialGroup = "langlatch",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 26,
	chanceHit = 0.35,
	damageMin = 240,
	damageMax = 290,
	baseXp = 2400,
	baseHAM = 5800,
	baseHAMmax = 7200,
	armor = 0,
	resists = {24,24,24,24,24,24,24,-1,-1},
	meatType = "meat_reptilian_lok",
	meatAmount = 950,
	hideType = "hide_scaley_lok",
	hideAmount = 120,
	boneType = "bone_mammal_lok",
	boneAmount = 90,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 7,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/langlatch_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	controlDeviceTemplate = "object/intangible/pet/langlatch_hue.iff",
	scale = 1.1,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"dizzyattack",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_lok_dune_scale_langlatch, "ender_projectmanager_lok_dune_scale_langlatch")
