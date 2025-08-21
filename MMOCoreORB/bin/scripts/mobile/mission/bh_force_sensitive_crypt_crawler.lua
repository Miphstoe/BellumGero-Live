bh_force_sensitive_crypt_crawler = Creature:new {
	objectName = "@mob/creature_names:force_sensitive_crypt_crawler",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "kun",
	faction = "",
	level = 95,
	chanceHit = 0.9,
	damageMin = 685,
	damageMax = 1080,
	baseXp = 9057,
	baseHAM = 16000,
	baseHAMmax = 19000,
	armor = 2,
	resists = {75,75,40,40,40,40,40,40,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_force_sensitive_crypt_crawler.iff"},
	lootGroups = {
		{
			groups = {
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "power_crystals", chance = 1000000},
				{group = "color_crystals", chance = 500000},
				{group = "weapon_component_advanced", chance = 1000000},
				{group = "chemistry_component_advanced", chance = 1000000},
				{group = "coa_encoded_disk_fragments", chance = 1000000},
				{group = "bounty_hunter_armor_schematics", chance = 1000000},
				{group = "jetpack_base", chance = 500000},
				{group = "jetpack_parts", chance = 500000},
			},
			lootChance = 4900000
		},
		{
			groups = {
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "power_crystals", chance = 1000000},
				{group = "color_crystals", chance = 500000},
				{group = "weapon_component_advanced", chance = 1000000},
				{group = "chemistry_component_advanced", chance = 1000000},
				{group = "coa_encoded_disk_fragments", chance = 1000000},
				{group = "bounty_hunter_armor_schematics", chance = 1000000},
				{group = "jetpack_base", chance = 500000},
				{group = "jetpack_parts", chance = 500000},
			},
			lootChance = 4900000
		},
		{
			groups = {
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "power_crystals", chance = 1000000},
				{group = "color_crystals", chance = 500000},
				{group = "weapon_component_advanced", chance = 1000000},
				{group = "chemistry_component_advanced", chance = 1000000},
				{group = "coa_encoded_disk_fragments", chance = 1000000},
				{group = "bounty_hunter_armor_schematics", chance = 1000000},
				{group = "jetpack_base", chance = 500000},
				{group = "jetpack_parts", chance = 500000},
			},
			lootChance = 4900000
		},
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "force_sword",
	secondaryWeapon = "force_sword_ranged",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(pikemanmaster,swordsmanmaster,fencermaster,brawlermaster,forcewielder),
	secondaryAttacks = forcewielder
}

CreatureTemplates:addCreatureTemplate(bh_force_sensitive_crypt_crawler, "bh_force_sensitive_crypt_crawler")
