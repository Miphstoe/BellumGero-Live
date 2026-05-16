hot_pirate_berserker_bruiser = Creature:new {
	objectName = "",
	customName = "Berserker Bruiser",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 82,
	chanceHit = 0.68,
	damageMin = 520,
	damageMax = 760,
	baseXp = 7200,
	baseHAM = 26000,
	baseHAMmax = 34000,
	armor = 0,
	resists = {55,45,45,15,15,10,10,10,-1},
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
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_blood_razor_pirate_berzerker_hum_m.iff",
		"object/mobile/dressed_blood_razor_pirate_berzerker_rod_m.iff",
		"object/mobile/dressed_blood_razor_pirate_berzerker_tran_m.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(brawlermaster, swordsmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_berserker_bruiser, "hot_pirate_berserker_bruiser")
