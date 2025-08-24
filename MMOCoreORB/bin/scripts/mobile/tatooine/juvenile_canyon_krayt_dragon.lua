juvenile_canyon_krayt_dragon = Creature:new {
	objectName = "@mob/creature_names:juvenile_canyon_krayt",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 122,
	chanceHit = 4.0,
	damageMin = 745,
	damageMax = 1200,
	baseXp = 11577,
	baseHAM = 54000,
	baseHAMmax = 64000,
	armor = 2,
	resists = {160,160,15,15,110,15,15,15,-1},
	meatType = "meat_carnivore",
	meatAmount = 750,
	hideType = "hide_bristley",
	hideAmount = 500,
	boneType = "bone_mammal",
	boneAmount = 410,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 0.5,

	templates = {"object/mobile/juvenile_canyon_krayt.iff"},
	hues = { 24, 25, 26, 27, 28, 29, 30, 31 },

lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 7.00% total
			{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 28.00% total
			{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 7.00% total
			{group = "armor_attachments", chance = 1500000},             -- 15.00% of group, 10.50% total
			{group = "clothing_attachments", chance = 1500000},          -- 15.00% of group, 10.50% total
			{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 7.00% total
		},
		lootChance = 7000000, -- 70.00% total chance
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

CreatureTemplates:addCreatureTemplate(juvenile_canyon_krayt_dragon, "juvenile_canyon_krayt_dragon")