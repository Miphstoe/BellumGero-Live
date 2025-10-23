----------------------------------------
-- Mutant Crazed Geonosian Guard
-- Enhanced event creature that escaped the Geo Lab
----------------------------------------

mutant_crazed_geonosian_guard = Creature:new {
	objectName = "@mob/creature_names:geonosian_crazed_guard",
	customName = "a mutant crazed geonosian guard",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "self",
	faction = "",
	level = 78,
	chanceHit = 0.75,
	damageMin = 620,
	damageMax = 850,
	baseXp = 8500,
	baseHAM = 18000,
	baseHAMmax = 22000,
	armor = 2,
	resists = {145,155,25,185,40,145,25,40,15},
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

	templates = {
		"object/mobile/dressed_geonosian_warrior_01.iff",
		"object/mobile/dressed_geonosian_warrior_02.iff",
		"object/mobile/dressed_geonosian_warrior_03.iff"},
	
	lootGroups = {
		{
			groups = {
				{group = "geonosian_common", chance = 3000000},
				{group = "geonosian_relic", chance = 3000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "weapon_component_advanced", chance = 1000000},
				{group = "armor_attachments", chance = 1000000}
			},
            lootChance = 10000000, -- 100.00% total chance
		}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "geonosian_weapons",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	
	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(brawlermaster,marksmanmaster,pistoleermaster,riflemanmaster,fencermaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(mutant_crazed_geonosian_guard, "mutant_crazed_geonosian_guard")