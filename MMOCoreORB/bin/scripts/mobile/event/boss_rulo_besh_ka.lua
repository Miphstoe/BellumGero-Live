boss_rulo_besh_ka = Creature:new {
	objectName = "@mob/creature_names:gungan_boss",
	customName = "Boss Rulo Besh-Ka",
	socialGroup = "gungan",
	faction = "gungan",
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

	templates = {"object/mobile/gungan_male.iff", "object/mobile/gungan_s02_male.iff"},

	lootGroups = {
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},         -- 40.00% of group, 40.00% total
			{group = "krayt_pearls", chance = 3000000},              -- 30.00% of group, 30.00% total
			{group = "armor_attachments", chance = 1500000},         -- 15.00% of group, 15.00% total
			{group = "clothing_attachments", chance = 1500000},      -- 15.00% of group, 15.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},         -- 40.00% of group, 28.00% total
			{group = "krayt_pearls", chance = 3000000},              -- 30.00% of group, 21.00% total
			{group = "armor_attachments", chance = 1500000},         -- 15.00% of group, 10.50% total
			{group = "clothing_attachments", chance = 1500000},      -- 15.00% of group, 10.50% total
		},
		lootChance = 7000000, -- 70.00% total chance
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},         -- 40.00% of group, 20.00% total
			{group = "krayt_pearls", chance = 3000000},              -- 30.00% of group, 15.00% total
			{group = "armor_attachments", chance = 1500000},         -- 15.00% of group, 7.50% total
			{group = "clothing_attachments", chance = 1500000},      -- 15.00% of group, 7.50% total
		},
		lootChance = 5000000, -- 50.00% total chance
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},         -- 40.00% of group, 10.00% total
			{group = "krayt_pearls", chance = 3000000},              -- 30.00% of group, 7.50% total
			{group = "armor_attachments", chance = 1500000},         -- 15.00% of group, 3.75% total
			{group = "clothing_attachments", chance = 1500000},      -- 15.00% of group, 3.75% total
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
	},
},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(boss_rulo_besh_ka, "boss_rulo_besh_ka")
