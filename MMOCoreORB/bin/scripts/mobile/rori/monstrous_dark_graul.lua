-- Monstrous Dark Graul: Rori resource creature. Harvest yields Rori wild meat.
-- Based on graul (Dantooine); uses graul_hue.iff. Spawn on Rori only.
-- See .cursor/context/ and bellum-gero.mdc for project context.

monstrous_dark_graul = Creature:new {
	objectName = "@mob/creature_names:graul",
	customName = "Monstrous Dark Graul",
	socialGroup = "graul",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 105,
	chanceHit = 0.39,
	damageMin = 290,
	damageMax = 920,
	baseXp = 33005,
	baseHAM = 58400,
	baseHAMmax = 102200,
	armor = 30,
	resists = {150,20,-1,20,20,-1,-1,-1,-1},
	meatType = "meat_wild_rori",
	meatAmount = 950,
	hideType = "hide_leathery",
	hideAmount = 350,
	boneType = "bone_mammal",
	boneAmount = 400,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 10,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/graul_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	controlDeviceTemplate = "object/intangible/pet/graul_hue.iff",
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"intimidationattack",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(monstrous_dark_graul, "monstrous_dark_graul")
