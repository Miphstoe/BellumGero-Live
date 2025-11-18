bsv_lab_guard_droid = Creature:new {
    objectName = "@mob/creature_names:super_battle_droid",
    customName = "Lab Security Droid",
    socialGroup = "bsv_droids",
    faction = "",
    mobType = MOB_DROID,

    level = 155,
    chanceHit = 0.65,
    damageMin = 340,
    damageMax = 400,
    baseXp = 10000,
    baseHAM = 34000,
    baseHAMmax = 42000,
    armor = 2,
    resists = {35,35,35,35,35,35,35,-1,-1},

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

    templates = {
        "object/mobile/super_battle_droid.iff"
    },

    lootGroups = {
        {
            groups = {
                {group = "bsv_lab_key_guard", chance = 10000000}
            },
            lootChance = 10000000  -- always drop the passkey
        },
        {
            groups = {
                {group = "bsv_lab_key_guard", chance = 10000000}
            },
            lootChance = 10000000  -- always drop the passkey
        },
        {
            groups = {
                {group = "bsv_lab_key_guard", chance = 10000000}
            },
            lootChance = 10000000  -- always drop the passkey
        },
        {
            groups = {
                {group = "bsv_droid_bunker", chance = 10000000}
            },
            lootChance = 3500000, -- 35%
        },
        {
            groups = {
                {group = "bsv_droid_bunker", chance = 10000000}
            },
            lootChance = 2000000, -- 20%
        },
    },

    primaryWeapon   = "battle_droid_weapons",
    secondaryWeapon = "unarmed",
    thrownWeapon    = "thrown_weapons",

    conversationTemplate = "",
    reactionStf = "",

    primaryAttacks   = merge(pistoleermaster, carbineermaster, marksmanmaster),
    secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(bsv_lab_guard_droid, "bsv_lab_guard_droid")
