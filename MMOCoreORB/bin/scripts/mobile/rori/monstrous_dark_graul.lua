-- Monstrous Dark Graul: Rori resource creature. Harvest yields Rori wild meat.
-- Tuned to mission-terminal / Azure-Stripe-Peko band (killable, level ~20).
-- Uses graul_hue.iff with mid-range hues for a darker look. Spawn on Rori only.
-- See .cursor/context/ and bellum-gero.mdc for project context.

monstrous_dark_graul = Creature:new {
	objectName = "@mob/creature_names:graul",
	customName = "Monstrous Dark Graul",
	socialGroup = "graul",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 20,
	chanceHit = 0.32,
	damageMin = 180,
	damageMax = 220,
	baseXp = 1200,
	baseHAM = 4000,
	baseHAMmax = 5000,
	armor = 0,
	resists = {25,25,25,25,25,25,25,-1,-1},
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
	hues = { 8, 9, 10, 11, 12, 13, 14, 15 },
	controlDeviceTemplate = "object/intangible/pet/graul_hue.iff",
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"intimidationattack",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(monstrous_dark_graul, "monstrous_dark_graul")
