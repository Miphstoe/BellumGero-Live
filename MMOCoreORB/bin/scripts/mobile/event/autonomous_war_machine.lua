autonomous_war_machine = Creature:new {
	objectName = "@mob/creature_names:warren_agro_droid_atst",
	customName = "The Autonomous War Machine",
	socialGroup = "event_droid",
	faction = "",
	mobType = MOB_ANDROID,

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
	ferocity = 0,

	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/atst.iff"},

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

	defaultWeapon = "object/weapon/ranged/vehicle/vehicle_atst_ranged.iff",
	defaultAttack = "defaultdroidattack",
}

CreatureTemplates:addCreatureTemplate(autonomous_war_machine, "autonomous_war_machine")
