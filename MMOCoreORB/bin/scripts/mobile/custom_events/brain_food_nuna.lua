-- Round 2 Nuna Event mobile: stronger than tiny_cabbage_nuna, loot table matched to the Enhanced Gaping Spider
brain_food_nuna = Creature:new {
	objectName = "@mob/creature_names:nuna",
	customName = "Brain Food",
	socialGroup = "self",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 140,
	chanceHit = 6.5,
	damageMin = 1100,
	damageMax = 1700,
	baseXp = 16000,
	baseHAM = 45000,
	baseHAMmax = 55000,
	armor = 3,
	resists = {180, 85, 35, 195, 35, 85, 85, 85, 25},
	meatType = "meat_avian",
	meatAmount = 1200,
	hideType = "hide_leathery",
	hideAmount = 1200,
	boneType = "bone_avian",
	boneAmount = 1100,
	milk = 0,
	tamingChance = 0,
	ferocity = 23,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/nuna_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.8,

	-- Loot table matches the Enhanced Gaping Spider (screenplays/yavin4/egspider_worldboss_loot_wrapper.lua)
	lootGroups = {
		{
			groups = {
				{group = "fire_breathing_spider", chance = 3500000},
				{group = "clothing_attachments", chance = 3500000},
				{group = "armor_attachments", chance = 3000000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "fire_breathing_spider", chance = 3500000},
				{group = "holocron_dark", chance = 3000000},
				{group = "holocron_light", chance = 3500000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "fire_breathing_spider", chance = 3000000},
				{group = "power_crystals", chance = 3500000},
				{group = "color_crystals", chance = 3500000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "chemistry_component_advanced", chance = 2500000},
				{group = "armor_component_advanced", chance = 2500000},
				{group = "weapon_component_advanced", chance = 2500000},
				{group = "crafting_component_advanced", chance = 2500000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "component_enhancement", chance = 10000000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "sea_removal_tool_1x", chance = 2500000},
				{group = "clothing_attachments", chance = 3750000},
				{group = "armor_attachments", chance = 3750000}
			},
			lootChance = 10000000,
		},
		{
			groups = {
				{group = "house_deeds", chance = 10000000}
			},
			lootChance = 2000000,
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
	primaryAttacks = { {"strongpoison",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(brain_food_nuna, "brain_food_nuna")
