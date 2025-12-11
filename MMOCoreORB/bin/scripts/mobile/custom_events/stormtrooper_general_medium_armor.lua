-- Tier 3: 300k HAM Stormtrooper General for Tiered Events
stormtrooper_general_medium_armor = Creature:new {
	customName = "Stormtrooper General",
	socialGroup = "imperial",
	mobType = MOB_NPC,
	faction = "",  -- No faction so both Rebels and Imperials can attack
	level = 300,
	chanceHit = 0.8,
	damageMin = 695,
	damageMax = 800,
	baseXp = 12000,
	baseHAM = 300000,  -- 300k HAM
	baseHAMmax = 300000,
	armor = 2,
	resists = {45,45,45,45,45,45,45,25,25},  -- Medium resists
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,  -- Attackable by all
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.1,

	templates = {"object/mobile/dressed_stormtrooper_m.iff"},
	lootGroups = {
		{
			groups = {
				{group = "imperial_corvette_loot", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "stormtrooper_rifle",
	secondaryWeapon = "stormtrooper_pistol",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",

	primaryAttacks = riflemanmaster,
	secondaryAttacks = pistoleermaster
}

CreatureTemplates:addCreatureTemplate(stormtrooper_general_medium_armor, "stormtrooper_general_medium_armor")
