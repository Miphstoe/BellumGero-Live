kharzun_dread_sands = Creature:new {
	objectName = "@mob/creature_names:geonosian_acklay_bunker_boss",
	customName = "Khar'zun of the Dread Sands",
	socialGroup = "geonosian_creature",
	mobType = MOB_CARNIVORE,
	faction = "",
	level = 472,
	chanceHit = 277.5,
	damageMin = 2806,
	damageMax = 4740,
	baseXp = 44652,
	baseHAM = 388000,
	baseHAMmax = 454000,
	armor = 2,
	resists = {130,145,155,155,145,30,30,30,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 25,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	tauntable = false,

	templates = {"object/mobile/acklay_hue.iff"},
	lootGroups = {
		{
			groups = {
				{group = "acklay", chance = 10000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 500000,
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"posturedownattack","stateAccuracyBonus=50"}, {"creatureareacombo","stateAccuracyBonus=50"} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(kharzun_dread_sands, "kharzun_dread_sands")
