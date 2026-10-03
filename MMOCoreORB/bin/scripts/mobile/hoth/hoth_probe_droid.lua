hoth_probe_droid = Creature:new {
	objectName = "",
	customName = "an Imperial probe droid",
	socialGroup = "imperial",
	faction = "",
	mobType = MOB_DROID,
	level = 68,
	chanceHit = 0.65,
	damageMin = 480,
	damageMax = 660,
	baseXp = 6563,
	baseHAM = 10500,
	baseHAMmax = 12500,
	armor = 1,
	resists = {140,140,140,30,30,30,30,-1,-1},
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
	templates = {"object/mobile/probot.iff"},
	lootGroups = {
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2000000
		}
	},
	defaultAttack = "attack",
	primaryWeapon = "droid_probot_ranged",
	secondaryWeapon = "none",
	conversationTemplate = ""
}

CreatureTemplates:addCreatureTemplate(hoth_probe_droid, "hoth_probe_droid")
