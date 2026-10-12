hoth_elder_wampa = Creature:new {
	objectName = "",
	customName = "an elder wampa",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 98,
	chanceHit = 0.95,
	damageMin = 640,
	damageMax = 980,
	baseXp = 9400,
	baseHAM = 22000,
	baseHAMmax = 27000,
	armor = 2,
	resists = {155,170,40,210,40,210,40,40,-1},
	meatType = "meat_carnivore",
	meatAmount = 1000,
	hideType = "hide_wooly",
	hideAmount = 1000,
	boneType = "bone_mammal",
	boneAmount = 850,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/wampa.iff"},
	scale = 1.15,
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
				{group = "hoth_vehicle_deeds", chance = 10000000}
			},
			lootChance = 10000
		},
		{
			groups = {
				{group = "hoth_vehicle_schematics", chance = 10000000}
			},
			lootChance = 20000
		},
		{
			groups = {
				{group = "hoth_ice_decor", chance = 10000000}
			},
			lootChance = 700000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 400000
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
	primaryAttacks = { {"stunattack",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_elder_wampa, "hoth_elder_wampa")
