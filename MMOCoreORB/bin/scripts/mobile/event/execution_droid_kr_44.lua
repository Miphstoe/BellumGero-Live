execution_droid_kr_44 = Creature:new {
	objectName = "@mob/creature_names:droideka",
	customName = "Execution Droid KR-44",
	socialGroup = "event_droid",
	faction = "",
	mobType = MOB_DROID,

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
	ferocity = 0,

	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/droideka.iff"},

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
				{group = "krayt_tissue_rare", chance = 4000000},         -- 25.00% of group, 17.50% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 14.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 7.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 7.00% total
			},
			lootChance = 7000000, -- 70.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},         -- 25.00% of group, 17.50% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 14.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 7.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 7.00% total
			},
			lootChance = 5000000, -- 50.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},         -- 25.00% of group, 17.50% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 14.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 7.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 7.00% total
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

	conversationTemplate = "",
	reactionStf = "",

	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack",
}

CreatureTemplates:addCreatureTemplate(execution_droid_kr_44, "execution_droid_kr_44")
