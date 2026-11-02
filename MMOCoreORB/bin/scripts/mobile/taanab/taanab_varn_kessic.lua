-- Taanab world boss (screenplays/bellum/taanab_norulac_raid_worldboss.lua). Loot is per player via WorldBossLootManager.
taanab_varn_kessic = Creature:new {
	objectName = "",
	customName = "Varn Kessic, the Scourge of Taanab",
	mobType = MOB_NPC,
	socialGroup = "pirate",
	faction = "",
	level = 400,
	creditsMultiplier = 0,
	chanceHit = 95,
	damageMin = 1050,
	damageMax = 1700,
	baseXp = 17000,
	baseHAM = 1200000,
	baseHAMmax = 1600000,
	armor = 2,
	resists = {175,175,160,160,200,160,160,80,25},
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
	scale = 1.15,
	templates = {
		"object/mobile/dressed_mercenary_warlord_nikto_m.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = merge(commandomaster,marksmanmaster),
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(taanab_varn_kessic, "taanab_varn_kessic")
