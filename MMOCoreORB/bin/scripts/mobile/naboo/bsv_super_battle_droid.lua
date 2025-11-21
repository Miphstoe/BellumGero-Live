bsv_super_battle_droid = Creature:new {
    objectName = "@mob/creature_names:rebel_super_battle_droid",
    customName = "Bunker Super Battle Droid",
    socialGroup = "bsv_droids",
    faction = "",
    mobType = MOB_DROID,

    level = 150,
    chanceHit = 0.6,
    damageMin = 300,
    damageMax = 360,
    baseXp = 9200,
    baseHAM = 30000,
    baseHAMmax = 38000,
    armor = 1,
    resists = {25,25,25,25,25,25,25,-1,-1},

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
        "object/mobile/super_battle_droid.iff"
    },

    lootGroups = {
        {
            groups = {
                {group = "bsv_droid_bunker", chance = 10000000}
            },
            lootChance = 3000000, -- 30%
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

CreatureTemplates:addCreatureTemplate(bsv_super_battle_droid, "bsv_super_battle_droid")
