-- Ender Project Manager: Corellian reptilian meat harvester (meat_reptilian_corellia).
-- General mission terminal destroy targets; mid-high band for Corellia.

ender_projectmanager_corellian_scale_tabage = Creature:new {
	objectName = "@mob/creature_names:tabage",
	customName = "Corellian Scale Tabage",
	socialGroup = "tabage",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 23,
	chanceHit = 0.34,
	damageMin = 200,
	damageMax = 240,
	baseXp = 2100,
	baseHAM = 5200,
	baseHAMmax = 6400,
	armor = 0,
	resists = {20,20,20,110,20,20,20,-1,-1},
	meatType = "meat_reptilian_corellia",
	meatAmount = 950,
	hideType = "hide_bristley",
	hideAmount = 120,
	boneType = "bone_mammal",
	boneAmount = 85,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 6,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/langlatch_hue.iff"},
	hues = { 8, 9, 10, 11, 12, 13, 14, 15 },
	controlDeviceTemplate = "object/intangible/pet/langlatch_hue.iff",
	scale = 1.08,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_corellian_scale_tabage, "ender_projectmanager_corellian_scale_tabage")
