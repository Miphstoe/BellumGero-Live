bg_force_old_man = Creature:new {
	objectName = "The Hermit",
	socialGroup = "fs_villager",
	faction = "fs_villager",
	mobType = MOB_NPC,
	level = 5,
	chanceHit = 0.25,
	damageMin = 10,
	damageMax = 20,
	baseXp = 0,
	baseHAM = 1000,
	baseHAMmax = 1200,
	armor = 0,
	resists = {0,0,0,0,0,0,0,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = 0,
	creatureBitmask = NONE,
	optionsBitmask = AIENABLED + INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_fs_village_oldman.iff"},
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "bgForceHermitConvoTemplate",
	primaryAttacks = brawlermid,
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(bg_force_old_man, "bg_force_old_man")
