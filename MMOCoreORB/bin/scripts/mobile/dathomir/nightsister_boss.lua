nightsister_boss = Creature:new {
	objectName = "@mob/creature_names:axkva_min",
    customName = "Zaritha (a Nightsister clan mother)",
	socialGroup = "nightsister",
	faction = "nightsister",
	mobType = MOB_NPC,
	level = 315,
	chanceHit = 30,
	damageMin = 2000,
	damageMax = 3500,
	baseXp = 28549,
	baseHAM = 385000,
	baseHAMmax = 471000,
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
	creatureBitmask = PACK + KILLER + HEALER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
    scale = 1.30,

	templates = {"object/mobile/dressed_dathomir_nightsister_axkva.iff"},
	lootGroups = {
		{
			groups = {
				{group = "nightsister_cave", chance = 10000000}
			},
			lootChance = 10000000 -- 100.00% total chance
		},
		{
			groups = {
				{group = "nightsister_cave", chance = 10000000}
			},
			lootChance = 10000000 -- 100.00% total chance
		},
		{
			groups = {
				{group = "nightsister_cave", chance = 10000000}
			},
			lootChance = 10000000 -- 100.00% total chance
		},
		{
			groups = {
				{group = "nightsister_cave", chance = 10000000},
			},
			lootChance = 2000000 -- 20.00% total chance
		},
        {
            groups = {
			    {group = "house_deeds", chance = 10000000}
		    },
		    lootChance = 2000000, -- 20.00% total chance
	    },
        {
            groups = {
			    {group = "endgame_weapon_schematics", chance = 10000000}
		    },
		    lootChance = 500000, -- 5.00% total chance
	    },
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "vet_holo_group", chance = 10000000}
			},
			lootChance = 1000000 -- 10.00% chance
		},
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "force_sword",
	secondaryWeapon = "force_sword_ranged",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(fencermaster,swordsmanmaster,pikemanmaster,brawlermaster,forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(nightsister_boss, "nightsister_boss")