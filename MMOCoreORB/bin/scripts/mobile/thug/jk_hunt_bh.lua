jk_hunt_bh = Creature:new {
	objectName = "@mob/creature_names:bounty_hunter",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "mercenary",
	faction = "",
	level = 285,
	chanceHit = 55,
	damageMin = 1200,
	damageMax = 2300,
	baseXp = 25266,
	baseHAM = 100000,
	baseHAMmax = 140000,
	armor = 3,
	resists = {90,90,90,90,90,90,90,90,20},
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
    scale = 1.15,
    customAiMap = "enclaveSentinel",

	templates = {"object/mobile/dressed_death_watch_silver.iff",
                "object/mobile/dressed_death_watch_gold.iff",
                "object/mobile/dressed_death_watch_grey.iff",
                "object/mobile/dressed_death_watch_red.iff"},

	lootGroups = {
		{
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 9000000, -- 90.00% total chance
	},
	{
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 2000000, -- 20.00% total chance
	},
	{
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 500000, -- 5.00% total chance
	},
	{
        groups = {
			{group = "house_deeds", chance = 10000000}
		},
		lootChance = 1000000, -- 10.00% total chance
	},
    {
        groups = {
		    {group = "endgame_weapon_schematics", chance = 10000000}
	    },
	    lootChance = 500000, -- 5.00% total chance
	},
},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "dark_trooper_weapons",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	
	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(bountyhuntermaster,marksmanmaster,brawlermaster,swordsmanmaster,pistoleermaster,fencermaster,pikemanmaster,riflemanmaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jk_hunt_bh, "jk_hunt_bh")