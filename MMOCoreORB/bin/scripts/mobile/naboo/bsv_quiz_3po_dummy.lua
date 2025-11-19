bsv_quiz_3po_dummy = Creature:new {
    objectName = "@mob/creature_names:protocol_droid_3po",
    socialGroup = "townsperson",
    mobType = MOB_DROID,
    faction = "",
    level = 1,

    templates = {
        "object/mobile/3po_protocol_droid.iff"
    },

    pvpBitmask = NONE,
    creatureBitmask = NONE,
    diet = HERBIVORE,

    primaryWeapon = "unarmed",
    secondaryWeapon = "none",
    primaryAttacks = {},
    secondaryAttacks = {},

    optionsBitmask = INVULNERABLE,
    conversationTemplate = "",

    lootGroups = {},
    resists = {0,0,0,0,0,0,0,0,-1},
    damageMin = 0,
    damageMax = 0,
    baseHAM = 500,
    baseHAMmax = 500
}

CreatureTemplates:addCreatureTemplate(bsv_quiz_3po_dummy, "bsv_quiz_3po_dummy")
