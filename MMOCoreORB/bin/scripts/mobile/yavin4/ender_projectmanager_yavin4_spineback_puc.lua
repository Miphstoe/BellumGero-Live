-- Ender Project Manager: Yavin reptilian meat harvester (meat_reptilian_yavin4).
-- General mission terminal destroy targets; mid-high band for Yavin4.

ender_projectmanager_yavin4_spineback_puc = Creature:new {
	objectName = "@mob/creature_names:giant_spined_puc",
	customName = "Yavin Spineback Puc",
	socialGroup = "spined_puc",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 38,
	chanceHit = 0.39,
	damageMin = 360,
	damageMax = 450,
	baseXp = 3800,
	baseHAM = 10200,
	baseHAMmax = 12600,
	armor = 1,
	resists = {120,20,20,20,20,20,20,-1,-1},
	meatType = "meat_reptilian_yavin4",
	meatAmount = 950,
	hideType = "hide_leathery",
	hideAmount = 130,
	boneType = "bone_avian",
	boneAmount = 85,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 8,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/giant_spined_puc.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	controlDeviceTemplate = "object/intangible/pet/spined_puc_hue.iff",
	scale = 1.35,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"poisonattack",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_yavin4_spineback_puc, "ender_projectmanager_yavin4_spineback_puc")
