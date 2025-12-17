-- Tier 2: 200k HAM Stormtrooper Captain for Tiered Events
stormtrooper_captain_medium_armor = Creature:new {
	customName = "Stormtrooper Captain",
	socialGroup = "imperial",
	mobType = MOB_NPC,
	faction = "",  -- No faction so both Rebels and Imperials can attack
	level = 200,
	chanceHit = 0.65,
	damageMin = 520,
	damageMax = 600,
	baseXp = 8000,
	baseHAM = 200000,  -- 200k HAM
	baseHAMmax = 200000,
	armor = 1,
	resists = {40,40,40,40,40,40,40,20,20},  -- Medium resists
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
	scale = 1.08,

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
	secondaryWeapon = "none",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",

	primaryAttacks = riflemanmaster,
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(stormtrooper_captain_medium_armor, "stormtrooper_captain_medium_armor")
