print("[JEDI-SEA-VENDOR] loading mobile/vendors/jedi_furniture_sea_vendor.lua")

jedi_furniture_sea_vendor = Creature:new {
	customName = "Jedi Furniture SEA Vendor",
	socialGroup = "",
	faction = "",
	level = 1,
	chanceHit = 0.5,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 1000,
	baseHAMmax = 1000,
	armor = 0,
	resists = {-1, -1, -1, -1, -1, -1, -1, -1, -1},
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_merchant_trainer_01.iff",
		"object/mobile/dressed_merchant_trainer_02.iff",
		"object/mobile/dressed_merchant_trainer_03.iff"
	},

	conversationTemplate = "jedi_furniture_sea_vendor_conv",
	attacks = {}
}

CreatureTemplates:addCreatureTemplate(jedi_furniture_sea_vendor, "jedi_furniture_sea_vendor")
print("[JEDI-SEA-VENDOR] mobile registered: jedi_furniture_sea_vendor")
