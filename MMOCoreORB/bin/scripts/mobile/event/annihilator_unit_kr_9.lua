annihilator_unit_kr_9 = Creature:new {
	objectName = "@mob/creature_names:rebel_super_battle_droid",
	customName = "Annihilator Unit KR-9",
	socialGroup = "event_droid",
	faction = "",
	mobType = MOB_DROID,

	level = 250,
	chanceHit = 20.0,
	damageMin = 1520,
	damageMax = 2750,
	baseXp = 26356,
	baseHAM = 321000,
	baseHAMmax = 392000,
	armor = 3,
	resists = {160,160,160,160,120,160,160,160,-1},

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
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/super_battle_droid.iff"},

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

	primaryWeapon = "battle_droid_weapons",
	secondaryWeapon = "unarmed",
	thrownWeapon = "thrown_weapons",
	conversationTemplate = "",
	reactionStf = "",

	primaryAttacks = merge(pistoleermaster, carbineermaster, marksmanmaster),
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(annihilator_unit_kr_9, "annihilator_unit_kr_9")
