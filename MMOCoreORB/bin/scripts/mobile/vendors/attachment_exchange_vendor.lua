print("[ATTACH-EXCH] loading mobile/vendors/attachment_exchange_vendor.lua")

attachment_exchange_vendor = Creature:new {
  customName = "Attachment Exchange Vendor",
  socialGroup = "", faction = "",
  level = 1, chanceHit = 0.5, damageMin = 0, damageMax = 0,
  baseXp = 0, baseHAM = 1000, baseHAMmax = 1000, armor = 0,
  resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
  pvpBitmask = NONE, creatureBitmask = NONE,
  optionsBitmask = INVULNERABLE + CONVERSABLE, diet = HERBIVORE,

  -- visual appearances ONLY (these .iff exist in Core3)
  templates = {
    "object/mobile/dressed_merchant_trainer_01.iff",
    "object/mobile/dressed_merchant_trainer_02.iff",
    "object/mobile/dressed_merchant_trainer_03.iff"
  },

  conversationTemplate = "sea_attachment_vendor_conv",
  attacks = {}
}

-- >>> THIS string is the spawn key <<<
CreatureTemplates:addCreatureTemplate(attachment_exchange_vendor, "attachment_exchange_vendor")
print("[ATTACH-EXCH] mobile registered: attachment_exchange_vendor")
