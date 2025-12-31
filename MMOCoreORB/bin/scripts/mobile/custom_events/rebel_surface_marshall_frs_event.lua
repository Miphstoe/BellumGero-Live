-- Tier 4: Rebel Surface Marshall for FRS Tiered Event - 500k HAM, 150 FRS per kill
rebel_surface_marshall_frs_event = Creature:new {
	customName = "Rebel Surface Marshall",
	socialGroup = "rebel",
	mobType = MOB_NPC,
	faction = "",  -- No faction so all players (Imperial, Neutral, Rebel) can attack
	level = 350,
	chanceHit = 0.75,
	damageMin = 700,
	damageMax = 800,
	baseXp = 25000,
	baseHAM = 500000,  -- 500k HAM
	baseHAMmax = 500000,
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
	scale = 1.15,

	templates = {
		"object/mobile/dressed_rebel_surface_marshal_moncal_female_01.iff",
		"object/mobile/dressed_rebel_surface_marshal_rodian_male_01.iff",
		"object/mobile/dressed_rebel_surface_marshal_human_male_01.iff",
		"object/mobile/dressed_rebel_surface_marshal_rodian_female_01.iff",
		"object/mobile/dressed_rebel_surface_marshal_twk_male_fat_01.iff",
		"object/mobile/dressed_rebel_surface_marshal_zabrak_male_01.iff"
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

CreatureTemplates:addCreatureTemplate(rebel_surface_marshall_frs_event, "rebel_surface_marshall_frs_event")
