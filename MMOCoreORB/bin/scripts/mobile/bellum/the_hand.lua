the_hand = Creature:new {
	objectName = "",
	customName = "The Hand",
	socialGroup = "dark_jedi",
	faction = "dark_jedi",
	mobType = MOB_NPC,
	level = 250,
	chanceHit = 12.5,
	damageMin = 2800,
	damageMax = 5200,
	baseXp = 28000,
	baseHAM = 220000,
	baseHAMmax = 270000,
	armor = 2,
	resists = {95,95,95,95,95,95,95,95,40},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + KILLER + HEALER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_dark_jedi_human_female_01.iff"},
	lootGroups = {},

	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = merge(lightsabermaster, forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(the_hand, "the_hand")
