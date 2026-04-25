savage_rend_grak = Creature:new {
	objectName = "",
	customName = "Savage Rend Grak",
	socialGroup = "rancor",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 115,
	chanceHit = 1.15,
	damageMin = 780,
	damageMax = 1180,
	baseXp = 11472,
	baseHAM = 142000,
	baseHAMmax = 152000,
	armor = 2,
	resists = {165,180,40,210,210,210,40,40,-1},
	meatType = "meat_reptilian_endor",
	meatAmount = 1200,
	hideType = "hide_leathery_endor",
	hideAmount = 1200,
	boneType = "bone_mammal_endor",
	boneAmount = 1100,
	milk = 0,
	tamingChance = 0,
	ferocity = 22,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/bull_rancor.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.35,
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
		{"creatureareableeding",""},
		{"creatureareacombo",""},
		{"creatureareaattack",""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(savage_rend_grak, "savage_rend_grak")
