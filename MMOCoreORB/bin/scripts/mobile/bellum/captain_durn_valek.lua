captain_durn_valek = Creature:new {
	customName = "Captain Durn Valek",
	socialGroup = "townsperson",
	faction = "townsperson",
	mobType = MOB_NPC,
	level = 100,
	chanceHit = 0.5,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 120000,
	baseHAMmax = 120000,
	armor = 2,
	resists = {175,175,175,175,175,175,175,175,-1},
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
		"object/mobile/dressed_stormtrooper_commando1_m.iff",
		"object/mobile/dressed_stormtrooper_commando_m.iff"
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "heavyOrdinanceTrialConvoTemplate",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(captain_durn_valek, "captain_durn_valek")
