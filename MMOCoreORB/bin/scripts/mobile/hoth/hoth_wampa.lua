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
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2300000
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
