-- Tier 2: Rebel Commander for FRS Tiered Event - 300k HAM, 75 FRS per kill
rebel_commander_frs_event = Creature:new {
	customName = "Rebel Commander",
	socialGroup = "rebel",
	mobType = MOB_NPC,
	faction = "",  -- No faction so all players (Imperial, Neutral, Rebel) can attack
	level = 250,
	chanceHit = 0.65,
	damageMin = 500,
	damageMax = 600,
	baseXp = 15000,
	baseHAM = 300000,  -- 300k HAM
	baseHAMmax = 300000,
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

	templates = {
		"object/mobile/dressed_rebel_commando_human_female_01.iff",
		"object/mobile/dressed_rebel_commando_human_male_01.iff",
		"object/mobile/dressed_rebel_commando_moncal_male_01.iff",
		"object/mobile/dressed_rebel_commando_rodian_male_01.iff",
		"object/mobile/dressed_rebel_commando_twilek_female_01.iff",
		"object/mobile/dressed_rebel_commando_zabrak_female_01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "imperial_corvette_loot", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "rebel_carbine",
	secondaryWeapon = "rebel_pistol",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/military",
	personalityStf = "@hireling/hireling_military",

	primaryAttacks = merge(carbineermaster,marksmanmaster),
	secondaryAttacks = merge(pistoleermaster,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(rebel_commander_frs_event, "rebel_commander_frs_event")
