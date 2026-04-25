primordial_warlord_grak = Creature:new {
	objectName = "",
	customName = "Primordial Warlord Grak",
	socialGroup = "rancor",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 525,
	chanceHit = 45.0,
	damageMin = 3800,
	damageMax = 7200,
	baseXp = 57500,
	baseHAM = 1800000,
	baseHAMmax = 2200000,
	armor = 3,
	resists = {195,195,195,195,195,195,195,195,160},
	meatType = "meat_reptilian_endor",
	meatAmount = 2500,
	hideType = "hide_leathery_endor",
	hideAmount = 1800,
	boneType = "bone_mammal_endor",
	boneAmount = 1800,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	scale = 2.2,
	tauntable = false,

	templates = {"object/mobile/bull_rancor.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000}
			},
			lootChance = 7000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000}
			},
			lootChance = 5000000
		},
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 4000000},
				{group = "krayt_pearls", chance = 3000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 1500000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 1000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 1500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 350000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {
		{"creatureareacombo","stateAccuracyBonus=100"},
		{"creatureareaknockdown","stateAccuracyBonus=100"},
		{"creatureareapoison","stateAccuracyBonus=100"},
		{"creatureareadisease","stateAccuracyBonus=100"}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(primordial_warlord_grak, "primordial_warlord_grak")
