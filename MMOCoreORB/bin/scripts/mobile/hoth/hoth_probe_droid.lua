hoth_probe_droid = Creature:new {
	objectName = "",
	customName = "an Imperial probe droid",
	socialGroup = "imperial",
	faction = "",
	mobType = MOB_DROID,
	level = 74,
	creditsMultiplier = 3,
	chanceHit = 0.72,
	damageMin = 520,
	damageMax = 720,
	baseXp = 7100,
	baseHAM = 12500,
	baseHAMmax = 15000,
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
	-- loot tuned (tune_hoth_loot.py): lootChance x0.5, creditsMultiplier 3
	lootGroups = {
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 25000
		}
	},
	defaultAttack = "attack",
	primaryWeapon = "droid_probot_ranged",
	secondaryWeapon = "none",
	conversationTemplate = ""
}

CreatureTemplates:addCreatureTemplate(hoth_probe_droid, "hoth_probe_droid")
