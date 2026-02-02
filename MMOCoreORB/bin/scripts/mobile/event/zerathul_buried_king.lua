zerathul_buried_king = Creature:new {
	objectName = "@mob/creature_names:kimogila",
	customName = "Zerathul the Buried King",
	socialGroup = "kimogila",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 350,
	chanceHit = 30.0,
	damageMin = 2951,
	damageMax = 5525,
	baseXp = 42824,
	baseHAM = 1000000,
	baseHAMmax = 1200000,
	armor = 3,
	resists = {195,195,195,195,195,195,195,195,25},
	meatType = "meat_carnivore",
	meatAmount = 2000,
	hideType = "hide_leathery",
	hideAmount = 1000,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 30,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/kimogila_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.3,
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
	primaryAttacks = { {"creatureareacombo","stateAccuracyBonus=100"}, {"creatureareaknockdown","stateAccuracyBonus=100"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(zerathul_buried_king, "zerathul_buried_king")
