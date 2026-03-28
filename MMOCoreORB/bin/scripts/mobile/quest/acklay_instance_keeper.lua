acklay_instance_keeper = Creature:new {
	objectName = "",
	customName = "Acklay Instance Keeper",
	socialGroup = "townsperson",
	faction = "",
	mobType = MOB_NPC,
	level = 100,
	chanceHit = 1,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 50000,
	baseHAMmax = 50000,
	armor = 0,
	resists = {0, 0, 0, 0, 0, 0, 0, 0, -1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_imperial_officer_m.iff",
		"object/mobile/dressed_imperial_officer_f.iff",
		"object/mobile/dressed_imperial_general_m.iff"
	},

	lootGroups = {},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "acklay_instance_keeper_conv",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(acklay_instance_keeper, "acklay_instance_keeper")
