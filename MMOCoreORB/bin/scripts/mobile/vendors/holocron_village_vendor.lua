-- Holocron Village Rewards Vendor Mobile Definition
print("[HOLOCRON-VENDOR] loading mobile/vendors/holocron_village_vendor.lua")

holocron_village_vendor = Creature:new {
  customName = "Village Rewards Trader",
  socialGroup = "", faction = "",
  level = 1, chanceHit = 0.5, damageMin = 0, damageMax = 0,
  baseXp = 0, baseHAM = 1000, baseHAMmax = 1000, armor = 0,
  resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
  pvpBitmask = NONE, creatureBitmask = NONE,
  optionsBitmask = INVULNERABLE + CONVERSABLE, diet = HERBIVORE,

  -- visual appearances (using merchant trainers)
  templates = {
    "object/mobile/dressed_noble_human_male_01.iff",
    "object/mobile/dressed_noble_human_female_01.iff",
    "object/mobile/dressed_noble_human_male_02.iff"
  },

  conversationTemplate = "holocron_village_vendor_conv",
  attacks = {}
}

-- >>> THIS string is the spawn key <<<
CreatureTemplates:addCreatureTemplate(holocron_village_vendor, "holocron_village_vendor")
print("[HOLOCRON-VENDOR] mobile registered: holocron_village_vendor")
