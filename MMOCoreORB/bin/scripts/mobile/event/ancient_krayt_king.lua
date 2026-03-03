ancient_krayt_king = Creature:new {
	objectName = "@mob/creature_names:ancient_krayt_dragon_event",
	customName = "Ancient Krayt King",
	socialGroup = "krayt",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 495,
	chanceHit = 40.5,
	damageMin = 3405,
	damageMax = 6375,
	baseXp = 48824,
	baseHAM = 1365000,
	baseHAMmax = 1501500,
	armor = 3,
	resists = {185,185,185,185,165,185,185,185,125},
	meatType = "meat_carnivore",
	meatAmount = 2550,
	hideType = "hide_bristley",
	hideAmount = 1425,
	boneType = "bone_mammal",
	boneAmount = 1357,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 2.0,

	templates = {"object/mobile/krayt_dragon_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },

	lootGroups = {
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 1500000},         -- 15.00% of group, 15.00% total
			{group = "krayt_dragon_common", chance = 5000000},       -- 50.00% of group, 50.00% total
			{group = "krayt_pearls", chance = 1500000},              -- 15.00% of group, 15.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 12.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 17.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 10.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 5.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 5.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 7.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 10.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 6.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 3.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 3.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "krayt_tissue_rare", chance = 2500000},         -- 25.00% of group, 2.50% total
			{group = "krayt_dragon_common", chance = 3500000},       -- 35.00% of group, 3.50% total
			{group = "krayt_pearls", chance = 2000000},              -- 20.00% of group, 2.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 1.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 1.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
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
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 350000
		}
},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"}, },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(ancient_krayt_king, "ancient_krayt_king")
