acklay_be = Creature:new {
	-- Reuses the existing client Acklay name string; no new STF entry is required.
	objectName = "@monster_name:acklay",
	socialGroup = "acklay",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 50,
	chanceHit = 0.2,
	damageMin = 30,
	damageMax = 40,
	baseXp = 45,
	baseHAM = 45,
	baseHAMmax = 55,
	armor = 0,
	resists = {0,0,0,0,0,0,0,0,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/acklay_hue.iff"},
	lootGroups = {},

	-- Crafted specials are supplied by the Genetic DNA Template.
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(acklay_be, "acklay_be")
