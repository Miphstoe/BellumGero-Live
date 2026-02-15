-- LongClaw Wild Vortor Lizard: Lok resource creature. Harvest yields Lok wild meat,
-- Lok animal bone, and Lok scaley hide. Uses langlatch (lizard) appearance.
-- See .cursor/context/ and bellum-gero.mdc for project context.

longclaw_wild_vortor_lizard = Creature:new {
	objectName = "@mob/creature_names:langlatch_hunter",
	customName = "LongClaw Wild Vortor Lizard",
	socialGroup = "langlatch",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 48,
	chanceHit = 0.31,
	damageMin = 170,
	damageMax = 180,
	baseXp = 11100,
	baseHAM =22800,
	baseHAMmax = 32400,
	armor = 10,
	resists = {10,10,10,10,10,10,10,-1,-1},
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
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	controlDeviceTemplate = "object/intangible/pet/langlatch_hue.iff",
	scale = 1.15,  -- 1.0 = default; >1 = larger, <1 = smaller (e.g. 0.8 = 80% size)
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(longclaw_wild_vortor_lizard, "longclaw_wild_vortor_lizard")
