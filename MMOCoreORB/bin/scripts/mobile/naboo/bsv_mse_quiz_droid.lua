-- bin/scripts/mobile/blue_shadow_virus/bsv_mse_quiz_droid.lua

bsv_mse_quiz_droid = Creature:new {
  objectName = "@droid_name:mse_6_crafted",  -- or whatever name you want
  socialGroup = "townsperson",
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
    templates = {"object/creature/npc/droid/crafted/mse_6_droid.iff",
    "object/creature/npc/droid/crafted/mse_6_droid_advanced.iff"},
    conversationTemplate = "bsv_quiz_convo",
    optionsBitmask = AIENABLED + CONVERSABLE,
    pvpBitmask = NONE,
    creatureBitmask = NONE,
    lootGroups = {},
    weapons = {},
    attacks = {}
}

CreatureTemplates:addCreatureTemplate(bsv_mse_quiz_droid, "bsv_mse_quiz_droid")
