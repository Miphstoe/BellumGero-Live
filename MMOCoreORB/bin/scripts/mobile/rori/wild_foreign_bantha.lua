-- Wild Foreign Bantha: Rori resource creature. Harvest yields Rori wild meat,
-- Rori wooly hide, Rori animal bone, and Rori wild milk.
-- Based on bantha; uses bantha_hue.iff. Spawn on Rori only.
-- See .cursor/context/ and bellum-gero.mdc for project context.

wild_foreign_bantha_rori = Creature:new {
	objectName = "@mob/creature_names:bantha",
	customName = "Wild Foreign Bantha",
	socialGroup = "bantha",
	faction = "",
	mobType = MOB_HERBIVORE,
	level = 65,
	chanceHit = 0.3,
	damageMin = 150,
	damageMax = 460,
	baseXp = 3714,
	baseHAM = 32000,
	baseHAMmax = 42400,
	armor = 15,
	resists = {0,120,0,120,0,0,0,-1,-1},
	meatType = "meat_wild_rori",
	meatAmount = 450,
	hideType = "hide_wooly_rori",
	hideAmount = 825,
	boneType = "bone_mammal_rori",
	boneAmount = 250,
	milkType = "milk_wild_rori",
	milk = 850,
	tamingChance = 0.25,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = HERD,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/bantha_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	controlDeviceTemplate = "object/intangible/pet/bantha_hue.iff",
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(wild_foreign_bantha_rori, "wild_foreign_bantha_rori")
