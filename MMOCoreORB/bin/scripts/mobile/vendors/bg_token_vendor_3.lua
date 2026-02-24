-- Bellum Gero Token Vendor 3 - Veteran Rewards Mobile Definition
print("[BG-TOKEN-VENDOR-3] loading mobile/vendors/bg_token_vendor_3.lua")

bg_token_vendor_3 = Creature:new {
  customName = "Bellum Gero Veteran Rewards Vendor",
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

  conversationTemplate = "bg_token_vendor_3_conv",
  attacks = {}
}

-- >>> THIS string is the spawn key <<<
CreatureTemplates:addCreatureTemplate(bg_token_vendor_3, "bg_token_vendor_3")
print("[BG-TOKEN-VENDOR-3] mobile registered: bg_token_vendor_3")
