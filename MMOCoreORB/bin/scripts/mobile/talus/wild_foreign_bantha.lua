-- Wild Foreign Bantha: Talus resource creature. Harvest yields Talus wild meat,
-- Talus wooly hide, Talus animal bone, and milk.
-- Tuned to mission-terminal / Azure-Stripe-Peko band (killable, level ~18).
-- Uses bantha_hue.iff with high hue band so Talus bantha look different from Rori.
-- See .cursor/context/ and bellum-gero.mdc for project context.

wild_foreign_bantha = Creature:new {
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
	meatType = "meat_wild_talus",
	meatAmount = 450,
	hideType = "hide_wooly_talus",
	hideAmount = 825,
	boneType = "bone_mammal_talus",
	boneAmount = 250,
	milkType = "milk_wild",
	milk = 850,
	tamingChance = 0.25,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = HERD,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/bantha_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	controlDeviceTemplate = "object/intangible/pet/bantha_hue.iff",
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(wild_foreign_bantha, "wild_foreign_bantha")
