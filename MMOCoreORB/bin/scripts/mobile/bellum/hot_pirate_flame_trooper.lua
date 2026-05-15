hot_pirate_flame_trooper = Creature:new {
	objectName = "",
	customName = "Flame Trooper",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 80,
	chanceHit = 0.64,
	damageMin = 440,
	damageMax = 650,
	baseXp = 6500,
	baseHAM = 19000,
	baseHAMmax = 25000,
	armor = 0,
	resists = {45,45,35,10,20,20,15,10,-1},
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
		"object/mobile/dressed_blood_razor_pirate_hum_m.iff",
		"object/mobile/dressed_blood_razor_pirate_hum_f.iff"
	},
	lootGroups = {},
	primaryWeapon = "commando_ranged",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(commandomaster, brawlermaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_flame_trooper, "hot_pirate_flame_trooper")
