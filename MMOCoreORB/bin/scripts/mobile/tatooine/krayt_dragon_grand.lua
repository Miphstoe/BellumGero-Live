krayt_dragon_grand = Creature:new {
	objectName = "@mob/creature_names:krayt_dragon_grand",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 330,
	chanceHit = 27.0,
	damageMin = 2270,
	damageMax = 4250,
	baseXp = 32549,
	baseHAM = 510000,
	baseHAMmax = 601000,
	armor = 3,
	resists = {185,185,185,185,165,185,185,185,125},
	meatType = "meat_carnivore",
	meatAmount = 1700,
	hideType = "hide_bristley",
	hideAmount = 950,
	boneType = "bone_mammal",
	boneAmount = 905,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 1.8,

	templates = {"object/mobile/krayt_dragon_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },

	lootGroups = {

    {
        groups = {
            {group = "krayt_tissue_epic", chance = 500000},          -- 5.00% of group, 5.00% total
            {group = "krayt_tissue_rare", chance = 2679487},         -- 26.79% of group
            --{group = "krayt_dragon_common", chance = 2000000},
            {group = "krayt_pearls", chance = 2923077},              -- 29.23% of group
            {group = "armor_attachments", chance = 1948718},         -- 19.49% of group
            {group = "clothing_attachments", chance = 1948718},      -- 19.49% of group
        },

        lootChance = 10000000, -- 100.00% chance this loot roll occurs
    },

    {
        groups = {
            {group = "krayt_tissue_epic", chance = 500000},          -- 5.00% of group, 2.50% total
            {group = "krayt_tissue_rare", chance = 3653846},         -- 36.54% of group
            --{group = "krayt_dragon_common", chance = 3500000},
            {group = "krayt_pearls", chance = 2923077},              -- 29.23% of group
            {group = "armor_attachments", chance = 1461539},         -- 14.62% of group
            {group = "clothing_attachments", chance = 1461538},      -- 14.62% of group
        },

        lootChance = 5000000, -- 50.00% chance this loot roll occurs
    },

    {
        groups = {
            {group = "krayt_tissue_epic", chance = 500000},          -- 5.00% of group, 1.50% total
            {group = "krayt_tissue_rare", chance = 3653846},         -- 36.54% of group
            --{group = "krayt_dragon_common", chance = 3500000},
            {group = "krayt_pearls", chance = 2923077},              -- 29.23% of group
            {group = "armor_attachments", chance = 1461539},         -- 14.62% of group
            {group = "clothing_attachments", chance = 1461538},      -- 14.62% of group
        },

        lootChance = 3000000, -- 30.00% chance this loot roll occurs
    },

    {
        groups = {
            {group = "krayt_tissue_epic", chance = 500000},          -- 5.00% of group, 0.50% total
            {group = "krayt_tissue_rare", chance = 3653846},         -- 36.54% of group
            --{group = "krayt_dragon_common", chance = 3500000},
            {group = "krayt_pearls", chance = 2923077},              -- 29.23% of group
            {group = "armor_attachments", chance = 1461539},         -- 14.62% of group
            {group = "clothing_attachments", chance = 1461538},      -- 14.62% of group
        },

        lootChance = 1000000, -- 10.00% chance this loot roll occurs
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


	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"}, },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(krayt_dragon_grand, "krayt_dragon_grand")