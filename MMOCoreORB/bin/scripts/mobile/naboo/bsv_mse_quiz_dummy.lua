-- scripts/mobile/blue_shadow_virus/bsv_mse_quiz_dummy.lua

bsv_mse_quiz_dummy = Creature:new {
  objectName = "@droid_name:mse_6_crafted",
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

  -- Non-combat, NOT conversable
  pvpBitmask = NONE,
  creatureBitmask = NONE,
  optionsBitmask = AIENABLED,

  diet = NONE,

  templates = {
    "object/creature/npc/droid/crafted/mse_6_droid.iff",
    "object/creature/npc/droid/crafted/mse_6_droid_advanced.iff"
  },

  lootGroups = {},
  weapons = {},

  conversationTemplate = "",  -- no convo
  attacks = {}
}

CreatureTemplates:addCreatureTemplate(bsv_mse_quiz_dummy, "bsv_mse_quiz_dummy")
