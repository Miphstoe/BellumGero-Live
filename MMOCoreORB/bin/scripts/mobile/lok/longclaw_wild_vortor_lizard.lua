-- LongClaw Wild Vortor Lizard: Lok resource creature. Harvest yields Lok wild meat,
-- Lok animal bone, and Lok scaley hide. Uses langlatch (lizard) appearance.
-- Tuned to mission-terminal / Azure-Stripe-Peko band (killable, level ~19).
-- Uses langlatch_hue.iff with low hue band for a different look from default.
-- See .cursor/context/ and bellum-gero.mdc for project context.

longclaw_wild_vortor_lizard = Creature:new {
	objectName = "@mob/creature_names:langlatch_hunter",
	customName = "LongClaw Wild Vortor Lizard",
	socialGroup = "langlatch",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 19,
	chanceHit = 0.32,
	damageMin = 170,
	damageMax = 190,
	baseXp = 1150,
	baseHAM = 3600,
	baseHAMmax = 4400,
	armor = 0,
	resists = {20,20,20,20,20,20,20,-1,-1},
	meatType = "meat_wild_lok",
	meatAmount = 120,
	hideType = "hide_scaley_lok",
	hideAmount = 95,
	boneType = "bone_mammal_lok",
	boneAmount = 85,
	milk = 0,
	tamingChance = 0.25,
	ferocity = 5,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/langlatch_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	controlDeviceTemplate = "object/intangible/pet/langlatch_hue.iff",
	scale = 1.05,
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(longclaw_wild_vortor_lizard, "longclaw_wild_vortor_lizard")
