xalgorath = Creature:new {
	objectName = "",
	customName = "Xal'gorath",
	socialGroup = "mauler",
	faction = "",
	mobType = MOB_NPC,
	level = 350,
	chanceHit = 1.25,
	damageMin = 1200,
	damageMax = 2000,
	baseXp = 19000,
	baseHAM = 275000,
	baseHAMmax = 315000,
	armor = 3,
	resists = {175,175,100,100,150,100,100,100,25},
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

	templates = {"object/mobile/dressed_mauler_master.iff"},
	lootGroups = {
		{
			groups = {
				{group = "acklay", chance = 10000000}
			},
			lootChance = 9000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = {
		{"intimidationattack", ""},
		{"strongpoison", ""},
		{"strongdisease", ""},
		{"creatureareapoison", ""},
		{"creatureareadisease", ""},
		{"posturedownattack", ""},
		{"creatureareacombo", "stateAccuracyBonus=50"}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(xalgorath, "xalgorath")
