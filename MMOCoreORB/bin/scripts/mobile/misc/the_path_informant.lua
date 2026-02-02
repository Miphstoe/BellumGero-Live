the_path_informant = Creature:new {
	customName = "Hidden Path Contact",
    randomNameType = NAME_GENERIC,
    randomNameTag = true,
	socialGroup = "",
	faction = "",
	mobType = MOB_NPC,
	level = 50,
	chanceHit = 0.39,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 10000,
	baseHAMmax = 10000,
	armor = 0,
	resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
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
		"object/mobile/dressed_eisley_officer_bothan_female_01.iff",
		"object/mobile/dressed_eisley_officer_bothan_male_01.iff"
	},

	lootGroups = {},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "the_path_conv_template",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(the_path_informant, "the_path_informant")
