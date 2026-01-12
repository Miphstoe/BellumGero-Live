-- Jedi NPC modeled after krayt_dragon_ancient for Sunday event
humdinger_jedi = Creature:new {
	customName = "Humdinger",
	socialGroup = "dark_jedi",
	faction = "",
	mobType = MOB_NPC,
	level = 350,
	chanceHit = 30.0,
	damageMin = 2951,
	damageMax = 5525,
	baseXp = 42824,
	baseHAM = 1000000,
	baseHAMmax = 1200000,
	armor = 3,
	resists = {195,195,195,195,195,195,195,195,140},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.0,

	templates = { "dark_jedi" },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 3000000},         -- 30.00% of group, 30.00% total
			{group = "krayt_dragon_common", chance = 3000000},       -- 30.00% of group, 30.00% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 20.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 17.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 24.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 14.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 7.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 7.00% total
		},
		lootChance = 7000000, -- 70.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 12.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 17.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 10.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 5.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 5.00% total
		},
		lootChance = 5000000, -- 50.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 6.25% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 8.75% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 5.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 2.50% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 2.50% total
		},
		lootChance = 2500000, -- 25.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},             -- 100.00% of group, 15.00% total
		},
		lootChance = 1500000, -- 15.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},             -- 100.00% of group, 10.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
	{
        groups = {
		    {group = "endgame_weapon_schematics", chance = 10000000}
	    },
	    lootChance = 1500000, -- 15.00% total chance
	},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 350000
		}
},

	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "dark_jedi_weapons_ranged",
	conversationTemplate = "",

	primaryAttacks = merge(lightsabermaster,forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(humdinger_jedi, "humdinger_jedi")
