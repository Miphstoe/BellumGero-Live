gurk_king = Creature:new {
	objectName = "@mob/creature_names:gurk",
	customName = "Gurk King",
	socialGroup = "gurk",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 300,
	chanceHit = 0.95,
	damageMin = 1500,
	damageMax = 2200,
	baseXp = 28000,
	baseHAM = 500000,
	baseHAMmax = 600000,
	armor = 3,
	resists = {170,170,120,100,120,60,60,60,40},
	meatType = "meat_herbivore",
	meatAmount = 350,
	hideType = "hide_leathery",
	hideAmount = 276,
	boneType = "bone_mammal",
	boneAmount = 301,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + HERD + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/recluse_gurk_king.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.8,
	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},         -- 30.00% of group, 30.00% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 20.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 10.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 10.00% total
			},
			lootChance = 10000000, -- 100.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 7000000, -- 70.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 5000000, -- 50.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
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

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(gurk_king, "gurk_king")
