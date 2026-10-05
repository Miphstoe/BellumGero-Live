hoth_greater_ice_mynock = Creature:new {
	objectName = "",
	customName = "a greater ice mynock",
	socialGroup = "mynock",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 76,
	chanceHit = 0.73,
	damageMin = 545,
	damageMax = 760,
	baseXp = 7300,
	baseHAM = 13000,
	baseHAMmax = 15500,
	armor = 1,
	resists = {130,130,25,25,190,130,25,25,-1},
	meatType = "meat_carnivore",
	meatAmount = 90,
	hideType = "hide_leathery",
	hideAmount = 110,
	boneType = "bone_mammal",
	boneAmount = 50,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/salt_mynock_hue.iff"},
	hues = { 8, 9, 10, 11, 12, 13, 14, 15 },
	scale = 1.35,
	lootGroups = {
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 50000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"blindattack",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_greater_ice_mynock, "hoth_greater_ice_mynock")
