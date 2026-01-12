-- Jedi NPC modeled after krayt_dragon_adolescent for Sunday event
deez_nuts_jedi = Creature:new {
	customName = "Deez Nuts",
	socialGroup = "dark_jedi",
	faction = "",
	mobType = MOB_NPC,
	level = 150,
	chanceHit = 8.0,
	damageMin = 900,
	damageMax = 1500,
	baseXp = 15250,
	baseHAM = 105000,
	baseHAMmax = 125000,
	armor = 2,
	resists = {160,160,150,150,120,150,150,150,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.0,

	templates = { "dark_jedi" },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 8.00% total
			{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 32.00% total
			{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 8.00% total
			{group = "armor_attachments", chance = 1500000},             -- 15.00% of group, 12.00% total
			{group = "clothing_attachments", chance = 1500000},          -- 15.00% of group, 12.00% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 8.00% total
		},
		lootChance = 8000000, -- 80.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 4.00% total
			{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 6.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 4.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 2.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 2.00% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 2.00% total
		},
		lootChance = 2000000, -- 20.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},                 -- 100.00% of group, 5.00% total
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

CreatureTemplates:addCreatureTemplate(deez_nuts_jedi, "deez_nuts_jedi")
