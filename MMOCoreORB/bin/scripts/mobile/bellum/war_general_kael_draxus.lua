war_general_kael_draxus = Creature:new {
	objectName = "",
	customName = "War General Kael Draxus",
	--randomNameType = NAME_GENERIC,
	randomNameTag = true,
	socialGroup = "imperial",
	faction = "",
	mobType = MOB_NPC,
	level = 185,
	chanceHit = 1.2,
	damageMin = 1100,
	damageMax = 1750,
	baseXp = 17650,
	baseHAM = 135000,
	baseHAMmax = 165000,
	armor = 2,
	resists = {150,160,165,165,160,50,50,50,-1},
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
		"object/mobile/dressed_imperial_major_m.iff",
		"object/mobile/dressed_imperial_colonel_m.iff",
		"object/mobile/dressed_stormtrooper_commando1_m.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "fire_breathing_spider", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = {
		{"strongpoison", ""},
		{"strongdisease", ""},
		{"mediumpoison", ""},
		{"intimidationattack", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(war_general_kael_draxus, "war_general_kael_draxus")
