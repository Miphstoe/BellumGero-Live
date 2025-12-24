-- Tier 1: Rebel Soldier for FRS Tiered Event - 200k HAM, 50 FRS per kill
rebel_soldier_frs_event = Creature:new {
	customName = "Rebel Soldier",
	socialGroup = "rebel",
	mobType = MOB_NPC,
	faction = "",  -- No faction so all players (Imperial, Neutral, Rebel) can attack
	level = 200,
	chanceHit = 0.6,
	damageMin = 400,
	damageMax = 500,
	baseXp = 10000,
	baseHAM = 200000,  -- 200k HAM
	baseHAMmax = 200000,
	armor = 1,
	resists = {40,40,40,40,40,40,40,20,20},  -- Somewhat tough resists
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
	scale = 1.0,

	templates = {
		"object/mobile/dressed_rebel_trooper_bith_m_01.iff",
		"object/mobile/dressed_rebel_trooper_human_female_01.iff",
		"object/mobile/dressed_rebel_trooper_human_male_01.iff",
		"object/mobile/dressed_rebel_trooper_sullustan_male_01.iff",
		"object/mobile/dressed_rebel_trooper_twk_female_01.iff",
		"object/mobile/dressed_rebel_trooper_twk_male_01.iff"
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

	primaryAttacks = merge(carbineermid,marksmanmaster),
	secondaryAttacks = merge(pistoleermid,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(rebel_soldier_frs_event, "rebel_soldier_frs_event")
