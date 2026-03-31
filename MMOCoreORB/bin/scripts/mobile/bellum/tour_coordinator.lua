tour_coordinator = Creature:new {
	objectName = "Tour Coordinator",
	randomNameType = NAME_GENERIC,
	randomNameTag = false,
	mobType = MOB_NPC,
	socialGroup = "townsperson",
	faction = "townsperson",
	level = 10,
	chanceHit = 0.28,
	damageMin = 90,
	damageMax = 110,
	baseXp = 292,
	baseHAM = 810,
	baseHAMmax = 990,
	armor = 0,
	resists = {0, 0, 0, 0, 0, 0, 0, -1, -1},
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
	optionsBitmask = AIENABLED + CONVERSABLE + INVULNERABLE,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_entertainer_trainer_human_female_01.iff",
		"object/mobile/dressed_entertainer_trainer_twk_female_01.iff",
		"object/mobile/dressed_entertainer_trainer_twk_male_01.iff"
	},
	lootGroups = {},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "galacticTourConvoTemplate",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(tour_coordinator, "tour_coordinator")
