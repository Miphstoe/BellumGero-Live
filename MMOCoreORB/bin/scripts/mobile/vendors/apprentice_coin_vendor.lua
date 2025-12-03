-- Apprentice Experience Coin Vendor NPC
print("[APPRENTICE-VENDOR] loading mobile/vendors/apprentice_coin_vendor.lua")

apprentice_coin_vendor = Creature:new {
	customName = "Apprentice Experience Vendor",
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

	conversationTemplate = "apprentice_coin_vendor_conv",
	attacks = {}
}

CreatureTemplates:addCreatureTemplate(apprentice_coin_vendor, "apprentice_coin_vendor")
print("[APPRENTICE-VENDOR] mobile registered: apprentice_coin_vendor")
