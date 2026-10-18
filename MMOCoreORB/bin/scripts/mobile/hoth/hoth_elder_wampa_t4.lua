hoth_elder_wampa_t4 = Creature:new {
	objectName = "",
	customName = "a ravenous elder wampa",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 110,
	creditsMultiplier = 3,
	chanceHit = 1.04,
	damageMin = 832,
	damageMax = 1274,
	baseXp = 10551,
	baseHAM = 33000,
	baseHAMmax = 40500,
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
	-- loot tuned (tune_hoth_loot.py): lootChance x0.5, creditsMultiplier 3
	lootGroups = {
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 375000
		},
		{
			groups = {
				{group = "armor_attachments", chance = 10000000}
			},
			lootChance = 375000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 10000000}
			},
			lootChance = 375000
		},
		{
			groups = {
				{group = "color_crystals", chance = 10000000}
			},
			lootChance = 225000
		},
		{
			groups = {
				{group = "power_crystals", chance = 10000000}
			},
			lootChance = 225000
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000}
			},
			lootChance = 75000
		},
		{
			groups = {
				{group = "jedi_robe", chance = 10000000}
			},
			lootChance = 30000
		},
		{
			groups = {
				{group = "hoth_vehicle_deeds", chance = 10000000}
			},
			lootChance = 15000
		},
		{
			groups = {
				{group = "hoth_vehicle_schematics", chance = 10000000}
			},
			lootChance = 30000
		},
		{
			groups = {
				{group = "hoth_ice_decor", chance = 10000000}
			},
			lootChance = 1050000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 600000
		},
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 75000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"stunattack",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_elder_wampa_t4, "hoth_elder_wampa_t4")
