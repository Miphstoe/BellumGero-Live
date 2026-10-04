hoth_scavenger_raider = Creature:new {
	objectName = "",
	customName = "a scavenger raider",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "thug",
	faction = "thug",
	level = 68,
	chanceHit = 0.58,
	damageMin = 440,
	damageMax = 590,
	baseXp = 6010,
	baseHAM = 10000,
	baseHAMmax = 12000,
	armor = 1,
	resists = {30,30,30,30,60,30,30,-1,-1},
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
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/dressed_tatooine_scavenger.iff",
		"object/mobile/dressed_mercenary_commander_zab_m.iff",
		"object/mobile/dressed_goon_twk_male_01.iff",
		"object/mobile/dressed_robber_human_female_01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "hoth_paintings", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 1000000
		}
	},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = marksmanmid,
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(hoth_scavenger_raider, "hoth_scavenger_raider")
