bsv_gate_officer = Creature:new {
    objectName = "@mob/creature_names:imperial_officer",
    customName = "Imperial Bunker Officer",
    socialGroup = "imperial",
    pvpFaction = "imperial",
    faction = "imperial",
    level = 10,
    chanceHit = 0.35,
    damageMin = 50,
    damageMax = 70,
    baseXp = 200,
    baseHAM = 500,
    baseHAMmax = 700,
    armor = 0,
    resists = {0,0,0,0,0,0,0,0,0},
    templates = {"object/mobile/dressed_imperial_officer_m.iff"},
    conversationTemplate = "bsv_gate_convo",
    optionsBitmask = AIENABLED + CONVERSABLE,
    pvpBitmask = NONE,
    creatureBitmask = NONE,
    lootGroups = {},
    weapons = {},
    attacks = {}
}

CreatureTemplates:addCreatureTemplate(bsv_gate_officer, "bsv_gate_officer")
