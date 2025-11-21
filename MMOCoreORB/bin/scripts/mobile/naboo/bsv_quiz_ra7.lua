-- Blue Shadow Virus Quiz RA-7 Bug Droid

bsv_quiz_ra7 = Creature:new {
    objectName = "@mob/creature_names:ra7_bug_droid",
    socialGroup = "townsperson",
    mobType = MOB_DROID,
    faction = "",
    level = 1,
    chanceHit = 0.01,
    damageMin = 0,
    damageMax = 0,
    baseXp = 0,
    baseHAM = 500,
    baseHAMmax = 500,
    armor = 0,
    resists = {0,0,0,0,0,0,0,0,-1},

    pvpBitmask = NONE,
    creatureBitmask = NONE,
    diet = HERBIVORE,

    templates = {
        "object/mobile/ra7_bug_droid.iff"
    },

    primaryWeapon = "unarmed",
    secondaryWeapon = "none",
    primaryAttacks = {},
    secondaryAttacks = {},

    optionsBitmask = INVULNERABLE + CONVERSABLE,
    conversationTemplate = "bsv_quiz_convo",

    lootGroups = {}
}

CreatureTemplates:addCreatureTemplate(bsv_quiz_ra7, "bsv_quiz_ra7")
