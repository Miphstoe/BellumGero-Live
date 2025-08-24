imperial_inquisitor_boss = Creature:new {
    objectName = "@mob/creature_names:imperial_inquisitor",
    customName = "Valen Kade (Fallen Inquisitor)",
    socialGroup = "dark_jedi",
    faction = "",
    level = 400,
    chanceHit = 30,
    damageMin = 2000,
    damageMax = 4000,
    baseXp = 50000,
    baseHAM = 450000,
    baseHAMmax = 500000,
    armor = 3,
    -- Kinetic, Energy, Blast, Heat, Cold, Electric, Acid, Stun, Lightsaber
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
    creatureBitmask = PACK + KILLER,
    optionsBitmask = AIENABLED,
    diet = HERBIVORE,

    templates = { "object/mobile/dressed_imperial_inquisitor_human_male_01.iff" },

    lootGroups = {
        -- TODO: tune to your server’s groups
	{
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 10000000, -- 100.00% total chance
	},
    {
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 10000000, -- 100.00% total chance
	},
    {
        groups = {
			{group = "dark_jedi_tier_5", chance = 10000000}
		},
		lootChance = 10000000, -- 100.00% total chance
	},
    {
        groups = {
			{group = "blasterfist_schematic", chance = 10000000}
		},
		lootChance = 2000000, -- 20.00% total chance
	},
},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "dark_jedi_weapons_ranged",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(lightsabermaster,forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(imperial_inquisitor_boss, "imperial_inquisitor_boss")