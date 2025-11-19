bsv_quiz_21b_dummy = Creature:new {
    objectName = "@mob/creature_names:surgical_droid_21b",
    mobType = MOB_DROID,

    templates = {
        "object/mobile/21b_surgical_droid.iff"
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

CreatureTemplates:addCreatureTemplate(bsv_quiz_21b_dummy, "bsv_quiz_21b_dummy")
