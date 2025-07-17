krayt_dragon_adolescent = Creature:new {
	objectName = "@mob/creature_names:krayt_dragon_adolescent",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 150,
	chanceHit = 8.0,
	damageMin = 900,
	damageMax = 1500,
	baseXp = 15250,
	baseHAM = 105000,
	baseHAMmax = 125000,
	armor = 2,
	resists = {160,160,150,150,120,150,150,150,-1},
	meatType = "meat_carnivore",
	meatAmount = 800,
	hideType = "hide_bristley",
	hideAmount = 600,
	boneType = "bone_mammal",
	boneAmount = 500,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 0.7,

	templates = {"object/mobile/krayt_dragon_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 8.00% total
			{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 32.00% total
			{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 8.00% total
			{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 8.00% total
			{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 8.00% total
			{group = "armor_all", chance = 1000000},                     -- 10.00% of group, 8.00% total
			{group = "weapons_all", chance = 1000000},                   -- 10.00% of group, 8.00% total
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
			{group = "armor_all", chance = 500000},                      -- 5.00% of group, 1.00% total
			{group = "weapons_all", chance = 500000},                    -- 5.00% of group, 1.00% total
		},
		lootChance = 2000000, -- 20.00% total chance
	},
	{
        groups = {
			{group = "krayt_pearls", chance = 10000000},                 -- 100.00% of group, 5.00% total
		},
		lootChance = 500000, -- 5.00% total chance
	},
},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"posturedownattack",""}, {"creatureareaattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(krayt_dragon_adolescent, "krayt_dragon_adolescent")