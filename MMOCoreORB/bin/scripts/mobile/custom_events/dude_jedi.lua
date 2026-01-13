-- Jedi NPC modeled after krayt_dragon_grand for Sunday event
dude_jedi = Creature:new {
	customName = "Dude",
	socialGroup = "dark_jedi",
	faction = "",
	mobType = MOB_NPC,
	level = 330,
	chanceHit = 27.0,
	damageMin = 2270,
	damageMax = 4250,
	baseXp = 32549,
	baseHAM = 510000,
	baseHAMmax = 601000,
	armor = 3,
	resists = {185,185,185,185,165,185,185,185,125},
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
			{group = "krayt_tissue_rare", chance = 1500000},         -- 15.00% of group, 15.00% total
			{group = "krayt_dragon_common", chance = 5000000},       -- 50.00% of group, 50.00% total
			{group = "krayt_pearls", chance = 1500000},              -- 15.00% of group, 15.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
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
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 7.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 10.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 6.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 3.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 3.00% total
		},
		lootChance = 3000000, -- 30.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 2.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 3.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 2.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 1.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 1.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},             -- 100.00% of group, 10.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},             -- 100.00% of group, 5.00% total
		},
		lootChance = 500000, -- 5.00% total chance
	},
	{
        groups = {
		    {group = "endgame_weapon_schematics", chance = 10000000}
	    },
	    lootChance = 500000, -- 5.00% total chance
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

CreatureTemplates:addCreatureTemplate(dude_jedi, "dude_jedi")
