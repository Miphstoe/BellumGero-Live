hoth_snowtrooper_sergeant = Creature:new {
	objectName = "",
	customName = "a snowtrooper sergeant",
	randomNameType = NAME_STORMTROOPER,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "imperial",
	faction = "imperial",
	level = 85,
	creditsMultiplier = 3,
	chanceHit = 0.84,
	damageMin = 610,
	damageMax = 870,
	baseXp = 8160,
	baseHAM = 15500,
	baseHAMmax = 18500,
	armor = 1,
	resists = {50,50,70,50,90,50,50,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/snowtrooper_s01.iff"
	},
	-- loot tuned (tune_hoth_loot.py): lootChance x0.5, creditsMultiplier 3
	lootGroups = {
		{
			groups = {
				{group = "imperial_tier_4", chance = 10000000}
			}
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 125000
		},
		{
			groups = {
				{group = "hoth_snowtrooper_schematics", chance = 10000000}
			},
			lootChance = 200000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 150000
		},
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 25000
		}
	},
	primaryWeapon = "stormtrooper_rifle",
	secondaryWeapon = "stormtrooper_pistol",
	thrownWeapon = "thrown_weapons",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",
	primaryAttacks = merge(riflemanmaster,marksmanmaster),
	secondaryAttacks = merge(pistoleermaster,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(hoth_snowtrooper_sergeant, "hoth_snowtrooper_sergeant")
