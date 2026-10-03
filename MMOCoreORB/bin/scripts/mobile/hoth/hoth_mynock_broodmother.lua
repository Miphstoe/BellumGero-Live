hoth_mynock_broodmother = Creature:new {
	objectName = "",
	customName = "the mynock broodmother",
	socialGroup = "mynock",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 85,
	chanceHit = 0.85,
	damageMin = 580,
	damageMax = 880,
	baseXp = 8160,
	baseHAM = 26000,
	baseHAMmax = 30000,
	armor = 2,
	resists = {160,180,45,220,45,220,45,45,-1},
	meatType = "meat_carnivore",
	meatAmount = 150,
	hideType = "hide_leathery",
	hideAmount = 200,
	boneType = "bone_mammal",
	boneAmount = 80,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/salt_mynock_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.8,
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
	primaryAttacks = { {"blindattack",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_mynock_broodmother, "hoth_mynock_broodmother")
