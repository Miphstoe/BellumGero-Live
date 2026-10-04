hoth_wampa_snowblind = Creature:new {
	objectName = "",
	customName = "Snowblind the Ravager",
	socialGroup = "wampa",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 92,
	chanceHit = 0.93,
	damageMin = 640,
	damageMax = 980,
	baseXp = 8832,
	baseHAM = 32000,
	baseHAMmax = 36000,
	armor = 2,
	resists = {160,180,45,220,45,220,45,45,-1},
	meatType = "meat_carnivore",
	meatAmount = 1400,
	hideType = "hide_wooly",
	hideAmount = 1400,
	boneType = "bone_mammal",
	boneAmount = 1200,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/wampa.iff"},
	scale = 1.35,
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
		},
		{
			groups = {
				{group = "hoth_paintings", chance = 10000000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "hoth_decor_rare", chance = 10000000}
			},
			lootChance = 1500000
		},
		{
			groups = {
				{group = "hoth_ice_decor", chance = 10000000}
			},
			lootChance = 2000000
		},
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 1000000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"blindattack",""}, {"creatureareaknockdown",""}, {"stunattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_wampa_snowblind, "hoth_wampa_snowblind")
