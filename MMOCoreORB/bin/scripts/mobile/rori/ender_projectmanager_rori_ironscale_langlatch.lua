-- Ender Project Manager: Rori reptilian meat harvester (meat_reptilian_rori).
-- General mission terminal destroy targets; mid-high band for Rori.

ender_projectmanager_rori_ironscale_langlatch = Creature:new {
	objectName = "@mob/creature_names:langlatch_hunter",
	customName = "Rori Ironscale Langlatch",
	socialGroup = "langlatch",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 21,
	chanceHit = 0.33,
	damageMin = 185,
	damageMax = 225,
	baseXp = 1800,
	baseHAM = 4200,
	baseHAMmax = 5200,
	armor = 0,
	resists = {22,22,22,22,22,22,22,-1,-1},
	meatType = "meat_reptilian_rori",
	meatAmount = 950,
	hideType = "hide_leathery",
	hideAmount = 110,
	boneType = "bone_mammal",
	boneAmount = 80,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 6,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/langlatch_hue.iff"},
	hues = { 24, 25, 26, 27, 28, 29, 30, 31 },
	controlDeviceTemplate = "object/intangible/pet/langlatch_hue.iff",
	scale = 1.06,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"intimidationattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ender_projectmanager_rori_ironscale_langlatch, "ender_projectmanager_rori_ironscale_langlatch")
