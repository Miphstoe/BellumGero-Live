
droideka_crafted_foundry = Creature:new {
	objectName = "@droid_name:droideka_crafted",
	socialGroup = "",
	faction = "",
	level = 4,
	mobType = MOB_DROID,
	chanceHit = 0.24,
	damageMin = 182,
	damageMax = 191,
	baseXp = 0,
	baseHAM = 3000,
	baseHAMmax = 3200,
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
	pvpBitmask = ATTACKABLE,
	creatureBitmask = HERD,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/droideka.iff"
	},
	lootGroups = {},
	defaultAttack = "attack",
	defaultWeapon = "object/weapon/ranged/droid/droid_droideka_ranged.iff",
	conversationTemplate = "",
}

CreatureTemplates:addCreatureTemplate(droideka_crafted_foundry, "droideka_crafted_foundry")
