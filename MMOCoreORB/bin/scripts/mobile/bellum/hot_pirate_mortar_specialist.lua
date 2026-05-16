hot_pirate_mortar_specialist = Creature:new {
	objectName = "",
	customName = "Mortar Specialist",
	socialGroup = "pirate",
	faction = "",
	mobType = MOB_NPC,
	level = 84,
	chanceHit = 0.7,
	damageMin = 500,
	damageMax = 740,
	baseXp = 7600,
	baseHAM = 22000,
	baseHAMmax = 30000,
	armor = 0,
	resists = {40,45,50,20,20,20,15,10,-1},
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
		"object/mobile/dressed_blood_razor_pirate_officer_hum_m.iff",
		"object/mobile/dressed_blood_razor_pirate_officer_rod_m.iff",
		"object/mobile/dressed_blood_razor_pirate_officer_nikto_m.iff"
	},
	lootGroups = {},
	primaryWeapon = "commando_ranged",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",

	primaryAttacks = merge(commandomaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(hot_pirate_mortar_specialist, "hot_pirate_mortar_specialist")
