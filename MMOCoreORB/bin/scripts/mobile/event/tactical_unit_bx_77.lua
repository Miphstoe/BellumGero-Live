tactical_unit_bx_77 = Creature:new {
	objectName = "@mob/creature_names:rebel_battle_droid",
	customName = "Tactical Unit BX-77",
	socialGroup = "event_droid",
	faction = "",
	mobType = MOB_DROID,

	level = 200,
	chanceHit = 4.0,
	damageMin = 745,
	damageMax = 1200,
	baseXp = 11577,
	baseHAM = 54000,
	baseHAMmax = 64000,
	armor = 2,
	resists = {160,160,15,15,110,15,15,15,-1},

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

	templates = {"object/mobile/battle_droid.iff"},

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

CreatureTemplates:addCreatureTemplate(tactical_unit_bx_77, "tactical_unit_bx_77")
