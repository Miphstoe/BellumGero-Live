rebel_first_lieutenant = Creature:new {
	objectName = "@mob/creature_names:rebel_first_lieutenant",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "rebel",
	faction = "rebel",
	level = 60,
	chanceHit = 0.55,
	damageMin = 370,
	damageMax = 550,
	baseXp = 5830,
	baseHAM = 12000,
	baseHAMmax = 14000,
	armor = 1,
	resists = {15,15,15,15,15,15,15,-1,-1},
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
		"object/mobile/dressed_rebel_first_lieutenant_bothan_male_01.iff",
		"object/mobile/dressed_rebel_first_lieutenant_human_female_01.iff",
		"object/mobile/dressed_rebel_first_lieutenant_human_male_01.iff",
		"object/mobile/dressed_rebel_first_lieutenant_moncal_female_01.iff",
		"object/mobile/dressed_rebel_first_lieutenant_moncal_female_02.iff",
		"object/mobile/dressed_rebel_first_lieutenant_sullustan_male_01.iff"},
	lootGroups = {
		{
			groups = {
				{group = "rebel_officer_tier_1", chance = 10000000}
			}
		}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "rebel_carbine",
	secondaryWeapon = "rebel_pistol",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/military",
	personalityStf = "@hireling/hireling_military",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = marksmanmaster,
	secondaryAttacks = marksmanmaster
}

CreatureTemplates:addCreatureTemplate(rebel_first_lieutenant, "rebel_first_lieutenant")
