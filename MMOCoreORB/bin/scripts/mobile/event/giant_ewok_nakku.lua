giant_ewok_nakku = Creature:new {
	customName = "Nakku",
	socialGroup = "gondula_tribe",
	faction = "gondula_tribe",
	mobType = MOB_NPC,
	level = 250,
	chanceHit = 24.0,
	damageMin = 1200,
	damageMax = 2100,
	baseXp = 420000,
	baseHAM = 800000,
	baseHAMmax = 960000,
	armor = 2,
	resists = {55,55,55,55,55,55,55,55,20},
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
	scale = 6,

	templates = {"object/mobile/dressed_ewok_m_11.iff"},
	lootGroups = {
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "clothing_attachments", chance = 5000000},
				{group = "armor_attachments", chance = 2500000},
				{group = "power_crystals", chance = 2500000}
			},
			lootChance = 10000000
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

	primaryWeapon = "light_jedi_weapons",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = merge(lightsabermaster,fencermaster,swordsmanmaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(giant_ewok_nakku, "giant_ewok_nakku")
