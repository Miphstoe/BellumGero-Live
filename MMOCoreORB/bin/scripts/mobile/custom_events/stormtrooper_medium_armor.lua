-- Tier 1: 100k HAM Stormtrooper for Tiered Events
stormtrooper_medium_armor = Creature:new {
	customName = "Stormtrooper",
	socialGroup = "imperial",
	mobType = MOB_NPC,
	faction = "",  -- No faction so both Rebels and Imperials can attack
	level = 150,
	chanceHit = 0.5,
	damageMin = 345,
	damageMax = 400,
	baseXp = 5000,
	baseHAM = 100000,  -- 100k HAM
	baseHAMmax = 100000,
	armor = 1,
	resists = {35,35,35,35,35,35,35,15,15},  -- Medium resists
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
	scale = 1.05,

	templates = {"object/mobile/dressed_stormtrooper_m.iff"},
	lootGroups = {
		{
			groups = {
				{group = "imperial_corvette_loot", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "stormtrooper_carbine",
	secondaryWeapon = "none",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",

	primaryAttacks = carbineermaster,
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(stormtrooper_medium_armor, "stormtrooper_medium_armor")
