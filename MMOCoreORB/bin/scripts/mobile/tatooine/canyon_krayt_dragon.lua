canyon_krayt_dragon = Creature:new {
	objectName = "@mob/creature_names:canyon_krayt_dragon",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 275,
	chanceHit = 20.0,
	damageMin = 1520,
	damageMax = 2750,
	baseXp = 26356,
	baseHAM = 321000,
	baseHAMmax = 392000,
	armor = 3,
	resists = {160,160,160,160,120,160,160,160,-1},
	meatType = "meat_carnivore",
	meatAmount = 1000,
	hideType = "hide_bristley",
	hideAmount = 750,
	boneType = "bone_mammal",
	boneAmount = 675,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 1,

	templates = {"object/mobile/canyon_krayt_dragon.iff"},
	hues = { 8, 9, 10, 11, 12, 13, 14, 15 },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 40.00% total
			{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 10.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 10.00% total
			{group = "armor_all", chance = 1000000},                     -- 10.00% of group, 10.00% total
			{group = "weapons_all", chance = 1000000},                   -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 6.00% total
			{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 9.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 6.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 3.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 3.00% total
			{group = "armor_all", chance = 500000},                      -- 5.00% of group, 1.50% total
			{group = "weapons_all", chance = 500000},                    -- 5.00% of group, 1.50% total
		},
		lootChance = 3000000, -- 30.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2500000},         -- 25.00% of group, 2.50% total
			{group = "krayt_dragon_common", chance = 3500000},           -- 35.00% of group, 3.50% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 2.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 1.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 1.00% total
			{group = "armor_all", chance = 500000},                      -- 5.00% of group, 0.50% total
			{group = "weapons_all", chance = 500000},                    -- 5.00% of group, 0.50% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},                 -- 100.00% of group, 10.00% total
		},
		lootChance = 1000000, -- 10.00% total chance
	},
},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareaattack","stateAccuracyBonus=50"}, {"stunattack","stateAccuracyBonus=50"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(canyon_krayt_dragon, "canyon_krayt_dragon")
