bsv_quiz_ra7_dummy = Creature:new {
    objectName = "@mob/creature_names:ra7_bug_droid",
    mobType = MOB_DROID,

    templates = {
        "object/mobile/ra7_bug_droid.iff"
    },

    optionsBitmask = INVULNERABLE,
    conversationTemplate = "",

    pvpBitmask = NONE,
    creatureBitmask = NONE,
    diet = HERBIVORE,

    primaryWeapon = "unarmed",
    secondaryWeapon = "none",
    primaryAttacks = {},
    secondaryAttacks = {},

    lootGroups = {},
    damageMin = 0,
    damageMax = 0,
    baseHAM = 500,
    baseHAMmax = 500,
    resists = {0,0,0,0,0,0,0,0,-1}
}

CreatureTemplates:addCreatureTemplate(bsv_quiz_ra7_dummy, "bsv_quiz_ra7_dummy")
