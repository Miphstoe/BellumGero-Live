hoth_elder_wampa = Creature:new {
	objectName = "",
	customName = "an elder wampa",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 88,
	chanceHit = 0.85,
	damageMin = 600,
	damageMax = 900,
	baseXp = 8408,
	baseHAM = 13000,
	baseHAMmax = 16000,
	armor = 1,
	resists = {150,170,40,210,40,210,40,40,-1},
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
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2780000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
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
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"stunattack",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_elder_wampa, "hoth_elder_wampa")
