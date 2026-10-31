norulac_raider = Creature:new {
	objectName = "",
	customName = "a Norulac raider",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "pirate",
	faction = "",
	level = 70,
	creditsMultiplier = 3,
	chanceHit = 0.7,
	damageMin = 500,
	damageMax = 700,
	baseXp = 6800,
	baseHAM = 12000,
	baseHAMmax = 14500,
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
		"object/mobile/dressed_criminal_pirate_human_male_01.iff",
		"object/mobile/dressed_criminal_pirate_human_female_01.iff",
		"object/mobile/dressed_raider_trandoshan_male_01.iff",
		"object/mobile/dressed_marooned_pirate_tran_m.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "pirate_tier_1", chance = 10000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 125000
		},
		{
			groups = {
				{group = "taanab_norulac_loot", chance = 10000000}
			},
			lootChance = 20000
		}
	},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = marksmanmid,
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(norulac_raider, "norulac_raider")
