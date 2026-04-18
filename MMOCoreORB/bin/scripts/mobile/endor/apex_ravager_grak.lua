apex_ravager_grak = Creature:new {
	objectName = "",
	customName = "Apex Ravager Grak",
	socialGroup = "rancor",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 185,
	chanceHit = 2.1,
	damageMin = 1450,
	damageMax = 2200,
	baseXp = 18654,
	baseHAM = 470000,
	baseHAMmax = 525000,
	armor = 3,
	resists = {185,195,120,235,235,235,120,120,-1},
	meatType = "meat_reptilian_endor",
	meatAmount = 1700,
	hideType = "hide_leathery_endor",
	hideAmount = 1600,
	boneType = "bone_mammal_endor",
	boneAmount = 1500,
	milk = 0,
	tamingChance = 0,
	ferocity = 26,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	tauntable = false,

	templates = {"object/mobile/bull_rancor.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.6,
	lootGroups = {
		{
			groups = {
				{group = "acklay", chance = 10000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {
		{"creatureareaknockdown","stateAccuracyBonus=75"},
		{"creatureareacombo","stateAccuracyBonus=75"},
		{"posturedownattack","stateAccuracyBonus=75"}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(apex_ravager_grak, "apex_ravager_grak")
