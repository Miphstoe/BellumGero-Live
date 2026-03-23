imperial_traitor_elite = Creature:new {
	objectName = "",
	customName = "Imperial Traitor Elite",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	socialGroup = "imperial_traitor",
	faction = "",
	mobType = MOB_NPC,
	level = 175,
	chanceHit = 1.15,
	damageMin = 1050,
	damageMax = 1750,
	baseXp = 16600,
	baseHAM = 115000,
	baseHAMmax = 140000,
	armor = 2,
	resists = {145,155,165,165,155,45,45,45,-1},
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

	templates = {
		"object/mobile/dressed_stormtrooper_commando1_m.iff",
		"object/mobile/dressed_stormtrooper_assault_trooper_m.iff",
		"object/mobile/dressed_imperial_exterminator.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "acklay", chance = 10000000}
			},
			lootChance = 9000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = merge(brawlermaster, marksmanmaster, bountyhuntermaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(imperial_traitor_elite, "imperial_traitor_elite")
