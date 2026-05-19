hot_pirate_shield_technician = Creature:new {
	objectName = "",
	customName = "Shield Technician",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 76,
	chanceHit = 0.58,
	damageMin = 380,
	damageMax = 560,
	baseXp = 5800,
	baseHAM = 16000,
	baseHAMmax = 22000,
	armor = 0,
	resists = {35,40,30,20,20,20,15,10,-1},
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
	creatureBitmask = PACK,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_marooned_pirate_engr_hum_m.iff",
		"object/mobile/dressed_marooned_pirate_engr1_hum_m.iff",
		"object/mobile/dressed_marooned_pirate_engr_sull_m.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_medium",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(marksmanmid, brawlermid),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_shield_technician, "hot_pirate_shield_technician")
