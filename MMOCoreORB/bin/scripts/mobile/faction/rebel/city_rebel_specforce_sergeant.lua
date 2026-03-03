city_rebel_specforce_sergeant = Creature:new {
	objectName = "@mob/creature_names:rebel_specforce_sergeant",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "rebel",
	faction = "rebel",
	level = 135,
	chanceHit = 0.38,
	damageMin = 350,
	damageMax = 500,
	baseXp = 4300,
	baseHAM = 50000,
	baseHAMmax = 60000,
	armor = 1,
	resists = {20,20,20,20,-1,20,-1,-1,-1},
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
		"object/mobile/dressed_rebel_specforce_sergeant_bothan_male_01.iff",
		"object/mobile/dressed_rebel_specforce_sergeant_human_male_01.iff",
		"object/mobile/dressed_rebel_specforce_sergeant_moncal_female_01.iff",
		"object/mobile/dressed_rebel_specforce_sergeant_moncal_male_01.iff",
		"object/mobile/dressed_rebel_specforce_sergeant_trandoshan_male_01.iff",
		"object/mobile/dressed_rebel_specforce_sergeant_twk_female_01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "rebel_officer_tier_1", chance = 10000000}
			}
		},
		{
		groups = {
			{group = "bg_token_group", chance = 10000000}
		},
		lootChance = 250000
		}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "rebel_carbine",
	secondaryWeapon = "rebel_pistol",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/military",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(commandomaster,carbineermaster,marksmanmaster),
	secondaryAttacks = merge(pistoleermaster,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(city_rebel_specforce_sergeant, "city_rebel_specforce_sergeant")