dreadmaw_devourer_grak = Creature:new {
	objectName = "",
	customName = "Dreadmaw Devourer Grak",
	socialGroup = "rancor",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 140,
	chanceHit = 1.45,
	damageMin = 980,
	damageMax = 1450,
	baseXp = 13892,
	baseHAM = 270000,
	baseHAMmax = 285000,
	armor = 2,
	resists = {175,190,80,225,225,225,80,80,-1},
	meatType = "meat_reptilian_endor",
	meatAmount = 1400,
	hideType = "hide_leathery_endor",
	hideAmount = 1350,
	boneType = "bone_mammal_endor",
	boneAmount = 1250,
	milk = 0,
	tamingChance = 0,
	ferocity = 24,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/bull_rancor.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.45,
	lootGroups = {
		{
			groups = {
				{group = "rancor_common", chance = 4000000},
				{group = "armor_all", chance = 2000000},
				{group = "weapons_all", chance = 2500000},
				{group = "wearables_all", chance = 1500000}
			},
			lootChance = 2960000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {
		{"strongpoison",""},
		{"creatureareapoison",""},
		{"creatureareacombo",""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(dreadmaw_devourer_grak, "dreadmaw_devourer_grak")
