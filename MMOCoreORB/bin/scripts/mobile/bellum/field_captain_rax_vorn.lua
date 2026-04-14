field_captain_rax_vorn = Creature:new {
	objectName = "",
	customName = "Field Captain Rax Vorn",
	--randomNameType = NAME_GENERIC,
	randomNameTag = true,
	socialGroup = "imperial",
	faction = "",
	mobType = MOB_NPC,
	level = 160,
	chanceHit = 1.1,
	damageMin = 950,
	damageMax = 1550,
	baseXp = 15250,
	baseHAM = 100000,
	baseHAMmax = 125000,
	armor = 2,
	resists = {135,145,150,150,145,35,35,35,-1},
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
		"object/mobile/dressed_stormtrooper_commander_black_gold.iff",
		"object/mobile/dressed_imperial_officer_m.iff",
		"object/mobile/dressed_imperial_officer_f.iff"
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
		{"knockdownattack", ""},
		{"mildpoison", ""},
		{"mediumpoison", ""},
		{"posturedownattack", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(field_captain_rax_vorn, "field_captain_rax_vorn")
