bsv_droideka = Creature:new {
    objectName = "@mob/creature_names:droideka",
    customName = "Bunker Droideka",
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

    pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
    creatureBitmask = PACK + KILLER,
    optionsBitmask = AIENABLED,
    diet = HERBIVORE,

    templates = {
        "object/mobile/droideka.iff"
    },

    lootGroups = {
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

    conversationTemplate = "",
    reactionStf = "",

    -- Uses droid weapon directly like the existing Lok droideka
    defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
    defaultAttack = "attack",
}

CreatureTemplates:addCreatureTemplate(bsv_droideka, "bsv_droideka")
