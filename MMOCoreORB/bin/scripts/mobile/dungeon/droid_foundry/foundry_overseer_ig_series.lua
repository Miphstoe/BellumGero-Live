foundry_overseer_ig_series = Creature:new {
	objectName = "@mob/creature_names:ig_assassin_droid",
	customName = "Foundry Overseer",
	socialGroup = "droid_foundry",
	faction = "",
	mobType = MOB_ANDROID,

	level = 250,
	chanceHit = 0.95,
	damageMin = 675,
	damageMax = 825,
	baseXp = 18000,
	baseHAM = 90000,
	baseHAMmax = 110000,
	armor = 2,
	resists = {50,50,50,50,50,50,50,-1,-1},

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
	creatureBitmask = PACK + KILLER + NOINTIMIDATE,
	optionsBitmask = AIENABLED,
	diet = NONE,
	scale = 1.75,

	templates = {"object/mobile/ig_assassin_droid.iff"},
	lootGroups = {
		{
			groups = {{group = "droid_foundry_kill_loot_generic", chance = 10000000}},
			lootChance = 10000000,
		},
		{
			groups = {{group = "droid_foundry_kill_loot_generic", chance = 10000000}},
			lootChance = 5000000,
		},
		{
			groups = {{group = "droid_foundry_schematics", chance = 10000000}},
			lootChance = 50000, -- 0.50% jackpot
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

	conversationTemplate = "",
	reactionStf = "",
	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	defaultAttack = "attack",

	-- Curated ranged boss attacks. Core3 filters these against the equipped
	-- default weapon and selects compatible attacks through the normal AI.
	primaryAttacks = {
		{"suppressionfire2", ""},
		{"fullautoarea2", ""},
		{"strafeshot2", ""},
		{"flurryshot2", ""},
	},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(foundry_overseer_ig_series, "foundry_overseer_ig_series")
