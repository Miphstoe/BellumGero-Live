-- Bellum Gero Token Vendor 2 Mobile Definition
print("[BG-TOKEN-VENDOR-2] loading mobile/vendors/bg_token_vendor_2.lua")

bg_token_vendor_2 = Creature:new {
  customName = "Bellum Gero Token Vendor 2",
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

  conversationTemplate = "bg_token_vendor_2_conv",
  attacks = {}
}

-- >>> THIS string is the spawn key <<<
CreatureTemplates:addCreatureTemplate(bg_token_vendor_2, "bg_token_vendor_2")
print("[BG-TOKEN-VENDOR-2] mobile registered: bg_token_vendor_2")
