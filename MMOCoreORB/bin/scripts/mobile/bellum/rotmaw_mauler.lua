rotmaw_mauler = Creature:new {
	objectName = "",
	customName = "Rotmaw Mauler",
	socialGroup = "mauler",
	faction = "",
	mobType = MOB_NPC,
	level = 200,
	chanceHit = 0.93,
	damageMin = 830,
	damageMax = 1320,
	baseXp = 12800,
	baseHAM = 168000,
	baseHAMmax = 182000,
	armor = 2,
	resists = {160,160,50,50,120,50,50,50,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_mauler_master.iff"},
	lootGroups = {
		{
			groups = {
				{group = "fire_breathing_spider", chance = 10000000}
			},
			lootChance = 9000000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		},
		-- BEGIN Hoth boss loot (gen_boss_loot.py)
		{
			groups = {
				{group = "hoth_snowtrooper_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "hoth_rebel_snow_schematics", chance = 10000000}
			},
			lootChance = 500000
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
		},
		{
			groups = {
				{group = "hoth_vehicle_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "hoth_vehicle_deeds", chance = 10000000}
			},
			lootChance = 200000
		}
		-- END Hoth boss loot
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = {
		{"strongpoison", ""},
		{"strongdisease", ""},
		{"stunattack", ""},
		{"posturedownattack", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(rotmaw_mauler, "rotmaw_mauler")
