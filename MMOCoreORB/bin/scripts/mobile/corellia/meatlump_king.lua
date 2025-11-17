meatlump_king = Creature:new {
    objectName = "Meatlump King",
    randomNameType = NAME_GENERIC,
    randomNameTag = false,
    mobType = MOB_NPC,
    socialGroup = "meatlump",
    faction = "meatlump",
    level = 300,
    chanceHit = 0.85,
    damageMin = 650,
    damageMax = 750,
    baseXp = 250000,
    baseHAM = 550000,
    baseHAMmax = 600000,
    armor = 2,
    resists = {65,70,60,65,65,70,60,-1,-1},
    meatType = "",
    meatAmount = 0,
    hideType = "",
    hideAmount = 0,
    boneType = "",
    boneAmount = 0,
    milk = 0,
    tamingChance = 0.0,
    ferocity = 100,

    -- Make him mean, but only use flags that you KNOW exist in your core
    pvpBitmask = ATTACKABLE + AGGRESSIVE + ENEMY,
    creatureBitmask = PACK + KILLER,
    diet = HERBIVORE,

    -- Same as cretin – "thug" is fine since cretin works
    templates = {"thug"},

    lootGroups = {
        {
            groups = {
                {group = "meatlump_tier_1", chance = 10000000}
            },
			lootChance = 10000000
        },
		{
            groups = {
                {group = "tato_small_table_style_03", chance = 10000000}
            },
			lootChance = 10000000
        },
		{
            groups = {
                {group = "force_power_crystal", chance = 10000000}
            },
			lootChance = 10000000
        },
		{
            groups = {
                {group = "force_color_crystal", chance = 10000000}
            },
			lootChance = 10000000
        },
		{
            groups = {
                {group = "meatlump_tier_1", chance = 10000000}
            },
			lootChance = 10000000
        },
        {
            groups = {
                {group = "bg_token_group", chance = 10000000}
            },
            lootChance = 150000
        }
    },

    primaryWeapon = "pirate_weapons_light",
    secondaryWeapon = "unarmed",
    reactionStf = "@npc_reaction/slang",

    primaryAttacks = merge(brawlernovice, marksmannovice),
    secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(meatlump_king, "meatlump_king")
