hot_pirate_kragg_siegebreaker = Creature:new {
	objectName = "",
	customName = "Kragg the Siegebreaker",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 104,
	chanceHit = 0.85,
	damageMin = 700,
	damageMax = 980,
	baseXp = 16000,
	baseHAM = 85000,
	baseHAMmax = 110000,
	armor = 1,
	resists = {80,85,85,35,35,30,30,20,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_blood_razor_pirate_captain_hum_m.iff",
		"object/mobile/dressed_marooned_pirate_captain_hum_m.iff",
		"object/mobile/dressed_scarab_pirate_general_human_male_01.iff"
	},
	lootGroups = {},
	primaryWeapon = "commando_ranged",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(commandomaster, brawlermaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_kragg_siegebreaker, "hot_pirate_kragg_siegebreaker")
