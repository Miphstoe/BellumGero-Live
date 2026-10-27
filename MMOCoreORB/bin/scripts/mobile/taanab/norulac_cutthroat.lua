norulac_cutthroat = Creature:new {
	objectName = "",
	customName = "a Norulac cutthroat",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "pirate",
	faction = "",
	level = 74,
	creditsMultiplier = 3,
	chanceHit = 0.75,
	damageMin = 520,
	damageMax = 740,
	baseXp = 7100,
	baseHAM = 13500,
	baseHAMmax = 16000,
	armor = 1,
	resists = {35,35,30,30,60,30,30,-1,-1},
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
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 125000
		},
		{
			groups = {
				{group = "taanab_norulac_loot", chance = 10000000}
			},
			lootChance = 25000
		}
	},
	primaryWeapon = "pirate_weapons_light",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = merge(pistoleermid,marksmanmid),
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(norulac_cutthroat, "norulac_cutthroat")
