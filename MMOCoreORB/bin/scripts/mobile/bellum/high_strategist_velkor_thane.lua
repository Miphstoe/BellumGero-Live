high_strategist_velkor_thane = Creature:new {
	objectName = "",
	customName = "High Strategist Velkor Thane",
	--randomNameType = NAME_GENERIC,
	randomNameTag = true,
	socialGroup = "dark_jedi",
	faction = "",
	mobType = MOB_NPC,
	level = 245,
	chanceHit = 1.5,
	damageMin = 1450,
	damageMax = 2250,
	baseXp = 23800,
	baseHAM = 230000,
	baseHAMmax = 280000,
	armor = 3,
	resists = {170,175,180,180,175,90,90,90,20},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {
		"object/mobile/dressed_dark_jedi_human_male_01.iff",
		"object/mobile/dressed_sith_shadow_trn_f_01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "acklay", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/fancy",

	primaryAttacks = {
		{"creatureareaknockdown", "stateAccuracyBonus=40"},
		{"creatureareapoison", ""},
		{"creatureareadisease", ""},
		{"strongpoison", ""},
		{"strongdisease", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(high_strategist_velkor_thane, "high_strategist_velkor_thane")
