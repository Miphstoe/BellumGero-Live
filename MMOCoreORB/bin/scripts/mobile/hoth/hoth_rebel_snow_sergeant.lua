hoth_rebel_snow_sergeant = Creature:new {
	objectName = "",
	customName = "a Rebel snow sergeant",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "rebel",
	faction = "rebel",
	level = 78,
	chanceHit = 0.78,
	damageMin = 560,
	damageMax = 800,
	baseXp = 7484,
	baseHAM = 13500,
	baseHAMmax = 16000,
	armor = 1,
	resists = {50,50,70,50,90,50,50,-1,-1},
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
		"object/mobile/rebel_snow_m_01.iff",
		"object/mobile/rebel_snow_f_01.iff"
	},
	lootGroups = {
		{
			groups = {
				{group = "rebel_tier_4", chance = 10000000}
			}
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		},
		{
			groups = {
				{group = "hoth_rebel_snow_schematics", chance = 10000000}
			},
			lootChance = 400000
		},
		{
			groups = {
				{group = "hoth_decor_common", chance = 10000000}
			},
			lootChance = 300000
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

CreatureTemplates:addCreatureTemplate(hoth_rebel_snow_sergeant, "hoth_rebel_snow_sergeant")
