master_artisan_procurement_officer = Creature:new {
	customName = "Master Artisan Procurement Officer",
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
	resists = { -1, -1, -1, -1, -1, -1, -1, -1, -1 },
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_merchant_trainer_01.iff",
		"object/mobile/dressed_merchant_trainer_02.iff",
		"object/mobile/dressed_merchant_trainer_03.iff",
	},

	conversationTemplate = "artisanResourceContractConvoTemplate",
	attacks = {}
}

CreatureTemplates:addCreatureTemplate(master_artisan_procurement_officer, "master_artisan_procurement_officer")
