-- Blue Shadow Virus Quiz 3PO Droid

bsv_quiz_3po = Creature:new {
    objectName = "@mob/creature_names:protocol_droid_3po",
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
        "object/mobile/3po_protocol_droid.iff"
    },

    primaryWeapon = "unarmed",
    secondaryWeapon = "none",
    primaryAttacks = {},
    secondaryAttacks = {},

    optionsBitmask = INVULNERABLE + CONVERSABLE,
    conversationTemplate = "bsv_quiz_convo",

    lootGroups = {}
}

CreatureTemplates:addCreatureTemplate(bsv_quiz_3po, "bsv_quiz_3po")