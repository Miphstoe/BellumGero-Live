-- Gravejaw Colossus - Event Woolamander with Adolescent Krayt Dragon stats
gravejaw_colossus_woolamander = Creature:new {
	customName = "Gravejaw Colossus",
	socialGroup = "woolamander",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 275,
	chanceHit = 8.0,
	damageMin = 900,
	damageMax = 1500,
	baseXp = 15250,
	baseHAM = 305000,
	baseHAMmax = 325000,
	armor = 2,
	resists = {160,160,150,150,120,150,150,150,-1},
	meatType = "meat_carnivore",
	meatAmount = 800,
	hideType = "hide_wooly",
	hideAmount = 600,
	boneType = "bone_mammal",
	boneAmount = 500,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/woolamander_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },

	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 8.00% total
				{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 32.00% total
				{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 8.00% total
				{group = "armor_attachments", chance = 1500000},             -- 15.00% of group, 12.00% total
				{group = "clothing_attachments", chance = 1500000},          -- 15.00% of group, 12.00% total
				{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 8.00% total
			},
			lootChance = 8000000, -- 80.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 4.00% total
				{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 6.00% total
				{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 4.00% total
				{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 2.00% total
				{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 2.00% total
				{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 2.00% total
			},
			lootChance = 2000000, -- 20.00% total chance
		},
		{
			groups = {
				{group = "krayt_pearls", chance = 10000000},                 -- 100.00% of group, 5.00% total
			},
			lootChance = 500000, -- 5.00% total chance
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

	primaryAttacks = { {"posturedownattack",""}, {"creatureareaattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(gravejaw_colossus_woolamander, "gravejaw_colossus_woolamander")
