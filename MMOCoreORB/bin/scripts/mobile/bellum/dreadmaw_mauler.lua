dreadmaw_mauler = Creature:new {
	objectName = "",
	customName = "Dreadmaw Mauler",
	socialGroup = "mauler",
	faction = "",
	mobType = MOB_NPC,
	level = 250,
	chanceHit = 1.00,
	damageMin = 920,
	damageMax = 1500,
	baseXp = 14250,
	baseHAM = 185000,
	baseHAMmax = 205000,
	armor = 2,
	resists = {165,165,75,75,130,75,75,75,-1},
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
				{group = "fire_breathing_spider", chance = 10000000}
			},
			lootChance = 9000000
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
		{"creatureareadisease", ""},
		{"posturedownattack", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(dreadmaw_mauler, "dreadmaw_mauler")
