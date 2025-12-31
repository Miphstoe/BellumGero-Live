-- Tier 3: Rebel General for FRS Tiered Event - 400k HAM, 100 FRS per kill
rebel_general_frs_event = Creature:new {
	customName = "Rebel General",
	socialGroup = "rebel",
	mobType = MOB_NPC,
	faction = "",  -- No faction so all players (Imperial, Neutral, Rebel) can attack
	level = 300,
	chanceHit = 0.7,
	damageMin = 600,
	damageMax = 700,
	baseXp = 20000,
	baseHAM = 400000,  -- 400k HAM
	baseHAMmax = 400000,
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
	scale = 1.1,

	templates = {
		"object/mobile/dressed_rebel_general_fat_human_male_01.iff",
		"object/mobile/dressed_rebel_general_human_female_01.iff",
		"object/mobile/dressed_rebel_general_human_female_02.iff",
		"object/mobile/dressed_rebel_general_moncal_male_01.iff",
		"object/mobile/dressed_rebel_general_old_twilek_male_01.iff",
		"object/mobile/dressed_rebel_general_rodian_female_01.iff"
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

CreatureTemplates:addCreatureTemplate(rebel_general_frs_event, "rebel_general_frs_event")
