-- Round 4 Nuna Event mobile: significantly stronger than christal_nuna, loot table matched to the Ancient Krayt Dragon
brussel_sprout_nuna = Creature:new {
	objectName = "@mob/creature_names:nuna",
	customName = "Brussel Sprout",
	socialGroup = "self",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 260,
	chanceHit = 30.0,
	damageMin = 3400,
	damageMax = 5000,
	baseXp = 40000,
	baseHAM = 190000,
	baseHAMmax = 230000,
	armor = 3,
	resists = {195,195,195,195,195,195,195,195,140},
	meatType = "meat_avian",
	meatAmount = 2000,
	hideType = "hide_leathery",
	hideAmount = 2000,
	boneType = "bone_avian",
	boneAmount = 1900,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/nuna_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 3.0,

	-- Loot table matches the Ancient Krayt Dragon (tatooine/krayt_dragon_ancient.lua)
	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 500000},
				{group = "krayt_tissue_rare", chance = 3500000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 500000},
				{group = "krayt_tissue_rare", chance = 3500000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 7000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 500000},
				{group = "krayt_tissue_rare", chance = 3500000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 5000000,
		},
		{
			groups = {
				{group = "krayt_tissue_epic", chance = 500000},
				{group = "krayt_tissue_rare", chance = 3500000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000},
			},
			lootChance = 2500000,
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000},
			},
			lootChance = 1500000,
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000},
			},
			lootChance = 1000000,
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 1500000,
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

CreatureTemplates:addCreatureTemplate(brussel_sprout_nuna, "brussel_sprout_nuna")
