
super_battle_droid_crafted_foundry = Creature:new {
	objectName = "@droid_name:super_battle_droid",
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
		"object/mobile/super_battle_droid.iff"
	},
	lootGroups = {},
	defaultAttack = "attack",
	primaryWeapon = "droid_foundry_b2_ranged",
	conversationTemplate = "",
}

CreatureTemplates:addCreatureTemplate(super_battle_droid_crafted_foundry, "super_battle_droid_crafted_foundry")
