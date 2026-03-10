giant_ewok_graaku = Creature:new {
	customName = "Graaku",
	socialGroup = "gondula_tribe",
	faction = "gondula_tribe",
	mobType = MOB_NPC,
	level = 100,
	chanceHit = 10.0,
	damageMin = 500,
	damageMax = 900,
	baseXp = 150000,
	baseHAM = 300000,
	baseHAMmax = 360000,
	armor = 1,
	resists = {30,30,30,30,30,30,30,30,20},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 4,

	templates = {"object/mobile/dressed_ewok_m_02.iff"},
	lootGroups = {
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "light_jedi_weapons",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = merge(lightsabermaster,fencermaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(giant_ewok_graaku, "giant_ewok_graaku")
