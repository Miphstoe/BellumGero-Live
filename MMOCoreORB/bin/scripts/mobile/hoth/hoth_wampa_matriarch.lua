hoth_wampa_matriarch = Creature:new {
	objectName = "",
	customName = "the wampa matriarch",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 95,
	chanceHit = 0.92,
	damageMin = 650,
	damageMax = 1000,
	baseXp = 9057,
	baseHAM = 36000,
	baseHAMmax = 40000,
	armor = 2,
	resists = {160,180,45,220,45,220,45,45,-1},
	meatType = "meat_carnivore",
	meatAmount = 1200,
	hideType = "hide_wooly",
	hideAmount = 1200,
	boneType = "bone_mammal",
	boneAmount = 1000,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/wampa.iff"},
	scale = 1.45,
	lootGroups = {
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 8000000
		},
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 6000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 1000000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 2500000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"stunattack",""}, {"creatureareaknockdown",""}, {"intimidationattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_wampa_matriarch, "hoth_wampa_matriarch")
