supreme_warlord_darth_malvek = Creature:new {
	objectName = "",
	customName = "Supreme Warlord Darth Malvek",
	socialGroup = "dark_jedi",
	faction = "dark_jedi",
	mobType = MOB_NPC,
	level = 360,
	chanceHit = 6.5,
	damageMin = 2400,
	damageMax = 3800,
	baseXp = 42000,
	baseHAM = 900000,
	baseHAMmax = 1050000,
	armor = 3,
	resists = {185,185,185,185,180,185,185,185,95},
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
	creatureBitmask = PACK + KILLER + STALKER + HEALER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.2,

	templates = {"object/mobile/darth_vader.iff"},
	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 1500000},
				{group = "krayt_dragon_common", chance = 5000000},
				{group = "krayt_pearls", chance = 1500000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},
				{group = "krayt_dragon_common", chance = 3500000},
				{group = "krayt_pearls", chance = 2000000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},
				{group = "krayt_dragon_common", chance = 3500000},
				{group = "krayt_pearls", chance = 2000000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},
				{group = "krayt_dragon_common", chance = 3500000},
				{group = "krayt_pearls", chance = 2000000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 1000000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 500000
		}

		
	},

	primaryWeapon = "darth_vader_weapons",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = {
		{"creatureareaattack", "stateAccuracyBonus=75"},
		{"creatureareacombo", "stateAccuracyBonus=75"},
		{"creatureareaknockdown", "stateAccuracyBonus=75"},
		{"forcelightningcone2", ""},
		{"forcechoke", ""},
		{"saberthrow2", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(supreme_warlord_darth_malvek, "supreme_warlord_darth_malvek")
