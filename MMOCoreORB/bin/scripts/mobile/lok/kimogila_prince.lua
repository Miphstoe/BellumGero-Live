kimogila_prince = Creature:new {
	objectName = "",
	customName = "Kimogila Prince",
	socialGroup = "kimogila",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 200,
	chanceHit = 9.0,
	damageMin = 1350,
	damageMax = 2200,
	baseXp = 18500,
	baseHAM = 105000,
	baseHAMmax = 128000,
	armor = 2,
	resists = {185,195,185,200,185,185,200,185,-1},
	meatType = "meat_carnivore",
	meatAmount = 1200,
	hideType = "hide_leathery",
	hideAmount = 1200,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/kimogila_hue.iff"},
	hues = { 24, 25, 26, 27, 28, 29, 30, 31 },
	scale = 1.15,

	lootGroups = {
		{
			groups = {
				{group = "kimogila_common", chance = 10000000}
			},
			lootChance = 5000000
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

	primaryAttacks = { {"creatureareaattack",""}, {"blindattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(kimogila_prince, "kimogila_prince")
