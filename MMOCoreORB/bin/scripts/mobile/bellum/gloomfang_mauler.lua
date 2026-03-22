gloomfang_mauler = Creature:new {
	objectName = "",
	customName = "Gloomfang Mauler",
	socialGroup = "mauler",
	faction = "",
	mobType = MOB_NPC,
	level = 150,
	chanceHit = 0.88,
	damageMin = 745,
	damageMax = 1200,
	baseXp = 11600,
	baseHAM = 54000,
	baseHAMmax = 64000,
	armor = 2,
	resists = {160,160,15,15,110,15,15,15,-1},
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

	templates = {"object/mobile/dressed_mauler_master.iff"},
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

CreatureTemplates:addCreatureTemplate(gloomfang_mauler, "gloomfang_mauler")
