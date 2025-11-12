-- Bellum Gero Token Vendor Mobile Definition
print("[BG-TOKEN-VENDOR] loading mobile/vendors/bg_token_vendor.lua")

bg_token_vendor = Creature:new {
  customName = "Bellum Gero Token Vendor",
  socialGroup = "", faction = "",
  level = 1, chanceHit = 0.5, damageMin = 0, damageMax = 0,
  baseXp = 0, baseHAM = 1000, baseHAMmax = 1000, armor = 0,
  resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
  pvpBitmask = NONE, creatureBitmask = NONE,
  optionsBitmask = INVULNERABLE + CONVERSABLE, diet = HERBIVORE,

  -- visual appearances (using merchant trainers)
  templates = {
    "object/mobile/dressed_merchant_trainer_01.iff",
    "object/mobile/dressed_merchant_trainer_02.iff",
    "object/mobile/dressed_merchant_trainer_03.iff"
  },

  conversationTemplate = "bg_token_vendor_conv",
  attacks = {}
}

-- >>> THIS string is the spawn key <<<
CreatureTemplates:addCreatureTemplate(bg_token_vendor, "bg_token_vendor")
print("[BG-TOKEN-VENDOR] mobile registered: bg_token_vendor")
