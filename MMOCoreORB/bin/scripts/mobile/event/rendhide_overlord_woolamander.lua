-- Rendhide Overlord - Event Woolamander with Grand Krayt Dragon stats
rendhide_overlord_woolamander = Creature:new {
	customName = "Rendhide Overlord",
	socialGroup = "woolamander",
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
	hideType = "hide_wooly",
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

	templates = {"object/mobile/woolamander_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },

	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 3000000},         -- 15.00% of group, 15.00% total
				{group = "krayt_pearls", chance = 3000000},              -- 15.00% of group, 15.00% total
				{group = "armor_attachments", chance = 2000000},         -- 10.00% of group, 10.00% total
				{group = "clothing_attachments", chance = 2000000},      -- 10.00% of group, 10.00% total
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
			lootChance = 5000000, -- 50.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},         -- 25.00% of group, 17.50% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 14.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 7.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 7.00% total
			},
			lootChance = 3000000, -- 30.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},         -- 25.00% of group, 17.50% total
				{group = "krayt_pearls", chance = 3000000},              -- 20.00% of group, 14.00% total
				{group = "armor_attachments", chance = 1500000},         -- 10.00% of group, 7.00% total
				{group = "clothing_attachments", chance = 1500000},      -- 10.00% of group, 7.00% total
			},
			lootChance = 1000000, -- 10.00% total chance
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

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"}, },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(rendhide_overlord_woolamander, "rendhide_overlord_woolamander")
