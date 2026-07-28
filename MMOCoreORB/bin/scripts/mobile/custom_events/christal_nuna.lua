-- Round 3 Nuna Event mobile: stronger than brain_food_nuna, loot table matched to the Grand Krayt Dragon
christal_nuna = Creature:new {
	objectName = "@mob/creature_names:nuna",
	customName = "Christal",
	socialGroup = "self",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 190,
	chanceHit = 27.0,
	damageMin = 1900,
	damageMax = 2800,
	baseXp = 25000,
	baseHAM = 95000,
	baseHAMmax = 115000,
	armor = 3,
	resists = {185,185,185,185,165,185,185,185,125},
	meatType = "meat_avian",
	meatAmount = 1500,
	hideType = "hide_leathery",
	hideAmount = 1500,
	boneType = "bone_avian",
	boneAmount = 1400,
	milk = 0,
	tamingChance = 0,
	ferocity = 27,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/nuna_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 2.3,

	-- Loot table matches the Grand Krayt Dragon (tatooine/krayt_dragon_grand.lua)
	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 250000},
				{group = "krayt_tissue_rare", chance = 2750000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 250000},
				{group = "krayt_tissue_rare", chance = 3750000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 5000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 250000},
				{group = "krayt_tissue_rare", chance = 3750000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 3000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 250000},
				{group = "krayt_tissue_rare", chance = 3750000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 1000000,
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000},
			},
			lootChance = 1000000,
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000},
			},
			lootChance = 500000,
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 500000,
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

CreatureTemplates:addCreatureTemplate(christal_nuna, "christal_nuna")
