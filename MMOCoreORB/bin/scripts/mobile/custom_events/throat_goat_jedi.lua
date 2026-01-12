-- Jedi NPC modeled after canyon_krayt_dragon for Sunday event
throat_goat_jedi = Creature:new {
	customName = "Throat Goat",
	socialGroup = "dark_jedi",
	faction = "",
	mobType = MOB_NPC,
	level = 250,
	chanceHit = 20.0,
	damageMin = 1520,
	damageMax = 2750,
	baseXp = 26356,
	baseHAM = 321000,
	baseHAMmax = 392000,
	armor = 3,
	resists = {160,160,160,160,120,160,160,160,-1},
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
			{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 9.00% total
			{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 36.00% total
			{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 9.00% total
			{group = "armor_attachments", chance = 1500000},             -- 15.00% of group, 13.50% total
			{group = "clothing_attachments", chance = 1500000},          -- 15.00% of group, 13.50% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 9.00% total
		},
		lootChance = 9000000, -- 90.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 6.00% total
			{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 9.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 6.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 3.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 3.00% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 3.00% total
		},
		lootChance = 3000000, -- 30.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 2.00% total
			{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 3.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 2.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 1.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 1.00% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 1.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},                 -- 100.00% of group, 10.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
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

CreatureTemplates:addCreatureTemplate(throat_goat_jedi, "throat_goat_jedi")
