giant_canyon_krayt_dragon = Creature:new {
	objectName = "@mob/creature_names:giant_canyon_krayt_dragon",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 300,
	chanceHit = 25.0,
	damageMin = 1645,
	damageMax = 3000,
	baseXp = 28549,
	baseHAM = 385000,
	baseHAMmax = 471000,
	armor = 3,
	resists = {170,170,170,170,130,170,170,170,115},
	meatType = "meat_carnivore",
	meatAmount = 1500,
	hideType = "hide_bristley",
	hideAmount = 870,
	boneType = "bone_mammal",
	boneAmount = 805,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 1.2,

	templates = {"object/mobile/canyon_krayt_dragon.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 20.00% total
			{group = "krayt_dragon_common", chance = 5500000},           -- 55.00% of group, 55.00% total
			{group = "krayt_pearls", chance = 1500000},                  -- 15.00% of group, 15.00% total
			{group = "armor_attachments", chance = 500000},              -- 5.00% of group, 5.00% total
			{group = "clothing_attachments", chance = 500000},           -- 5.00% of group, 5.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2500000},         -- 25.00% of group, 10.00% total
			{group = "krayt_dragon_common", chance = 3500000},           -- 35.00% of group, 14.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 8.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 4.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 4.00% total
		},
		lootChance = 4000000, -- 40.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2500000},         -- 25.00% of group, 5.00% total
			{group = "krayt_dragon_common", chance = 3500000},           -- 35.00% of group, 7.00% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 4.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 2.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 2.00% total
		},
		lootChance = 2000000, -- 20.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 2500000},         -- 25.00% of group, 2.50% total
			{group = "krayt_dragon_common", chance = 3500000},           -- 35.00% of group, 3.50% total
			{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 2.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 1.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 1.00% total
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
	primaryAttacks = { {"creatureareaattack","stateAccuracyBonus=50"}, {"creatureareaknockdown","stateAccuracyBonus=50"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(giant_canyon_krayt_dragon, "giant_canyon_krayt_dragon")
