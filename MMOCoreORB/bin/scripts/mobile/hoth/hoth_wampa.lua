hoth_wampa = Creature:new {
	objectName = "",
	customName = "a wampa",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 90,
	chanceHit = 0.86,
	damageMin = 590,
	damageMax = 880,
	baseXp = 8600,
	baseHAM = 16000,
	baseHAMmax = 20000,
	armor = 1,
	resists = {150,165,35,200,35,200,35,35,-1},
	meatType = "meat_carnivore",
	meatAmount = 900,
	hideType = "hide_wooly",
	hideAmount = 900,
	boneType = "bone_mammal",
	boneAmount = 750,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/wampa.iff"},
	scale = 1.0,
	lootGroups = {
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "armor_attachments", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "color_crystals", chance = 10000000}
			},
			lootChance = 150000
		},
		{
			groups = {
				{group = "power_crystals", chance = 10000000}
			},
			lootChance = 150000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 50000
		},
		{
			groups = {
				{group = "jedi_robe", chance = 10000000}
			},
			lootChance = 20000
		},
		{
			groups = {
				{group = "hoth_ice_decor", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 300000
		},
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 50000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"intimidationattack",""}, {"knockdownattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_wampa, "hoth_wampa")
