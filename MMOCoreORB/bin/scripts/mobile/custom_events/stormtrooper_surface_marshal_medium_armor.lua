-- Tier 4: 500k HAM Stormtrooper Surface Marshal (BOSS) for Tiered Events
stormtrooper_surface_marshal_medium_armor = Creature:new {
	customName = "Stormtrooper Surface Marshal",
	socialGroup = "imperial",
	mobType = MOB_NPC,
	faction = "",  -- No faction so both Rebels and Imperials can attack
	level = 350,
	chanceHit = 1.0,
	damageMin = 1020,
	damageMax = 1200,
	baseXp = 20000,
	baseHAM = 500000,  -- 500k HAM
	baseHAMmax = 500000,
	armor = 3,
	resists = {50,50,50,50,50,50,50,30,30},  -- Medium resists
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
	scale = 1.15,  -- Larger scale for boss

	templates = {"object/mobile/dressed_stormtrooper_m.iff"},
	lootGroups = {
		{
			groups = {
				{group = "imperial_stormtrooper_tier_1", chance = 10000000}
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

CreatureTemplates:addCreatureTemplate(stormtrooper_surface_marshal_medium_armor, "stormtrooper_surface_marshal_medium_armor")
