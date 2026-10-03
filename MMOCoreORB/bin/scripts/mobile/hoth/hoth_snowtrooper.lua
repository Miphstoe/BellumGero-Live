hoth_snowtrooper = Creature:new {
	objectName = "",
	customName = "a snowtrooper",
	randomNameType = NAME_STORMTROOPER,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "imperial",
	faction = "imperial",
	level = 70,
	chanceHit = 0.7,
	damageMin = 500,
	damageMax = 700,
	baseXp = 6747,
	baseHAM = 12000,
	baseHAMmax = 14500,
	armor = 1,
	resists = {40,40,60,40,80,40,40,-1,-1},
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
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/snowtrooper_s01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "imperial_tier_3", chance = 10000000}
			}
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		}
	},
	primaryWeapon = "stormtrooper_rifle",
	secondaryWeapon = "stormtrooper_pistol",
	thrownWeapon = "thrown_weapons",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",
	primaryAttacks = merge(riflemanmaster,marksmanmaster),
	secondaryAttacks = merge(pistoleermaster,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(hoth_snowtrooper, "hoth_snowtrooper")
