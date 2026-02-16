-- Spineclaw Alpha - Event Woolamander with Juvenile Canyon Krayt Dragon stats
spineclaw_alpha_woolamander = Creature:new {
	customName = "Spineclaw Alpha",
	socialGroup = "woolamander",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 250,
	chanceHit = 4.0,
	damageMin = 745,
	damageMax = 1200,
	baseXp = 11577,
	baseHAM = 254000,
	baseHAMmax = 264000,
	armor = 2,
	resists = {160,160,15,15,110,15,15,15,-1},
	meatType = "meat_carnivore",
	meatAmount = 750,
	hideType = "hide_wooly",
	hideAmount = 500,
	boneType = "bone_mammal",
	boneAmount = 410,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/woolamander_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },

	lootGroups = {
		{
			groups = {
				{group = "krayt_tissue_uncommon", chance = 1000000},         -- 10.00% of group, 7.00% total
				{group = "krayt_dragon_common", chance = 4000000},           -- 40.00% of group, 28.00% total
				{group = "krayt_pearls", chance = 1000000},                  -- 10.00% of group, 7.00% total
				{group = "armor_attachments", chance = 1500000},             -- 15.00% of group, 10.50% total
				{group = "clothing_attachments", chance = 1500000},          -- 15.00% of group, 10.50% total
				{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 7.00% total
			},
			lootChance = 7000000, -- 70.00% total chance
		},
		{
			groups = {
				{group = "krayt_tissue_uncommon", chance = 2000000},         -- 20.00% of group, 2.00% total
				{group = "krayt_dragon_common", chance = 3000000},           -- 30.00% of group, 3.00% total
				{group = "krayt_pearls", chance = 2000000},                  -- 20.00% of group, 2.00% total
				{group = "armor_attachments", chance = 1000000},             -- 10.00% of group, 1.00% total
				{group = "clothing_attachments", chance = 1000000},          -- 10.00% of group, 1.00% total
				{group = "weapon_component_advanced", chance = 1000000},     -- 10.00% of group, 1.00% total
			},
			lootChance = 1000000, -- 10.00% total chance
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

CreatureTemplates:addCreatureTemplate(spineclaw_alpha_woolamander, "spineclaw_alpha_woolamander")
