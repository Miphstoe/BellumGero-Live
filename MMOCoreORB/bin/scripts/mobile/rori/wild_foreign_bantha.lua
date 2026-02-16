-- Wild Foreign Bantha: Rori resource creature. Harvest yields Rori wild meat,
-- Rori wooly hide, Rori animal bone, and Rori wild milk.
-- Tuned to mission-terminal / Azure-Stripe-Peko band (killable, level ~18).
-- Uses bantha_hue.iff with mid-range hues. Spawn on Rori only.
-- See .cursor/context/ and bellum-gero.mdc for project context.

wild_foreign_bantha_rori = Creature:new {
	objectName = "@mob/creature_names:bantha",
	customName = "Wild Foreign Bantha",
	socialGroup = "bantha",
	faction = "",
	mobType = MOB_HERBIVORE,
	level = 18,
	chanceHit = 0.3,
	damageMin = 120,
	damageMax = 180,
	baseXp = 1100,
	baseHAM = 3800,
	baseHAMmax = 4600,
	armor = 0,
	resists = {15,15,15,15,15,15,15,-1,-1},
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
	hues = { 8, 9, 10, 11, 12, 13, 14, 15 },
	controlDeviceTemplate = "object/intangible/pet/bantha_hue.iff",
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(wild_foreign_bantha_rori, "wild_foreign_bantha_rori")
