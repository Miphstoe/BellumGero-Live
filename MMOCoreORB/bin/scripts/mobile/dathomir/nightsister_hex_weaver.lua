nightsister_hex_weaver = Creature:new {
	objectName = "@mob/creature_names:nightsister_hex_weaver",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "nightsister",
	faction = "",
	level = 281,
	chanceHit = 23.5,
	damageMin = 1645,
	damageMax = 3000,
	baseXp = 25266,
	baseHAM = 261000,
	baseHAMmax = 320000,
	armor = 3,
	resists = {90,90,90,90,90,90,90,90,-1},
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
	creatureBitmask = KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
    scale = 1.30,

	templates = { "object/mobile/dressed_dathomir_nightsister_spellweaver.iff" },
	lootGroups = {
	{
        groups = {
			{group = "nightsister_cave", chance = 10000000}
		},
		lootChance = 9000000, -- 90.00% total chance
	},
	{
        groups = {
			{group = "nightsister_cave", chance = 10000000}
		},
		lootChance = 2000000, -- 20.00% total chance
	},
	{
        groups = {
			{group = "nightsister_cave", chance = 10000000}
		},
		lootChance = 500000, -- 5.00% total chance
	},
	{
        groups = {
			{group = "nightsister_cave", chance = 10000000}
		},
		lootChance = 500000, -- 5.00% total chance
	},
},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "force_sword",
	secondaryWeapon = "force_sword_ranged",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(tkamaster,swordsmanmaster,fencermaster,pikemanmaster,brawlermaster,forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(nightsister_hex_weaver, "nightsister_hex_weaver")