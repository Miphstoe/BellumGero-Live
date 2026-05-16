hot_pirate_heavy_raider = Creature:new {
	objectName = "",
	customName = "Heavy Raider",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 78,
	chanceHit = 0.62,
	damageMin = 420,
	damageMax = 620,
	baseXp = 6200,
	baseHAM = 18000,
	baseHAMmax = 24000,
	armor = 0,
	resists = {45,45,35,25,25,20,20,10,-1},
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
		"object/mobile/dressed_blood_razor_pirate_strong_hum_m.iff",
		"object/mobile/dressed_blood_razor_pirate_guard_hum_m.iff",
		"object/mobile/dressed_corsair_pirate_strong_hum_m.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(riflemanmid, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_heavy_raider, "hot_pirate_heavy_raider")
