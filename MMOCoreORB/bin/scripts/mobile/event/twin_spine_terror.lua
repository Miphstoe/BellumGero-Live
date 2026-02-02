twin_spine_terror = Creature:new {
	objectName = "@mob/creature_names:kimogila",
	customName = "The Twin-Spine Terror",
	socialGroup = "kimogila",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 300,
	chanceHit = 25.0,
	damageMin = 1645,
	damageMax = 3000,
	baseXp = 28549,
	baseHAM = 385000,
	baseHAMmax = 471000,
	armor = 3,
	resists = {170,170,170,170,130,170,170,170,20},
	meatType = "meat_carnivore",
	meatAmount = 1500,
	hideType = "hide_leathery",
	hideAmount = 870,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/kimogila_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.15,
	lootGroups = {
	 {
	        groups = {
			{group = "giant_dune_kimo_common", chance = 3500000},
			{group = "kimogila_common", chance = 6500000},
		},
		lootChance = 10000000
	},
	{
		groups = {
			{group = "bg_token_group", chance = 10000000}
		},
		lootChance = 350000
	}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareaattack","stateAccuracyBonus=50"}, {"creatureareaknockdown","stateAccuracyBonus=50"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(twin_spine_terror, "twin_spine_terror")
