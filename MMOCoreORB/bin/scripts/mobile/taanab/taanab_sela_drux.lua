-- Norulac Raider Cave boss (screenplays/caves/taanab_norulac_raider_cave.lua). Rewards are per player, so the corpse carries none.
taanab_sela_drux = Creature:new {
	objectName = "",
	customName = "Sela Drux, Kessic's Quartermaster",
	mobType = MOB_NPC,
	socialGroup = "pirate",
	faction = "",
	level = 105,
	creditsMultiplier = 0,
	chanceHit = 1.0,
	damageMin = 720,
	damageMax = 1080,
	baseXp = 10080,
	baseHAM = 46000,
	baseHAMmax = 51000,
	armor = 2,
	resists = {60,60,45,45,70,45,45,25,-1},
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
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/dressed_criminal_smuggler_human_female_01.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_light",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = merge(pistoleermaster,marksmanmaster),
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(taanab_sela_drux, "taanab_sela_drux")
