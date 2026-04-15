-- Bellum Spynet bounty camp — primary mark (level set at spawn by screenplay)
bellum_bounty_mark = Creature:new {
	objectName = "",
	customName = "",
	socialGroup = "criminal",
	faction = "",
	mobType = MOB_NPC,
	level = 48,
	chanceHit = 0.58,
	damageMin = 460,
	damageMax = 700,
	baseXp = 2800,
	baseHAM = 34000,
	baseHAMmax = 41000,
	armor = 1,
	resists = {10, 10, 0, 0, 15, 10, 0, 10, -1},
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
	creatureBitmask = NONE,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	-- Trainer Wookiee/human BH trainer IFFs often lack normal civilian death/knockdown; use a standard humanoid smuggler mesh.
	templates = {"object/mobile/dressed_criminal_smuggler_human_male_01.iff"},
	lootGroups = {},

	primaryWeapon = "general_pistol",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = marksmanmid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(bellum_bounty_mark, "bellum_bounty_mark")
