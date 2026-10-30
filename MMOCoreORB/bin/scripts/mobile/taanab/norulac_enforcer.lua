norulac_enforcer = Creature:new {
	objectName = "",
	customName = "a Norulac enforcer",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "pirate",
	faction = "",
	level = 82,
	creditsMultiplier = 4,
	chanceHit = 0.8,
	damageMin = 600,
	damageMax = 850,
	baseXp = 7900,
	baseHAM = 19000,
	baseHAMmax = 22000,
	armor = 1,
	resists = {45,45,40,40,60,40,40,-1,-1},
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
		"object/mobile/dressed_mercenary_warlord_wee_m.iff",
		"object/mobile/dressed_raider_trandoshan_female_01.iff",
		"object/mobile/dressed_mercenary_commander_zab_m.iff"
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
			lootChance = 40000
		}
	},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = merge(carbineermid,marksmanmid),
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(norulac_enforcer, "norulac_enforcer")
