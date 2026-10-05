hoth_ice_mynock = Creature:new {
	objectName = "",
	customName = "an ice mynock",
	socialGroup = "mynock",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 67,
	chanceHit = 0.63,
	damageMin = 480,
	damageMax = 640,
	baseXp = 6470,
	baseHAM = 11500,
	baseHAMmax = 13500,
	armor = 1,
	resists = {110,110,20,20,170,110,20,20,-1},
	meatType = "meat_carnivore",
	meatAmount = 60,
	hideType = "hide_leathery",
	hideAmount = 80,
	boneType = "bone_mammal",
	boneAmount = 30,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,
	templates = {"object/mobile/salt_mynock_hue.iff"},
	hues = { 0, 1, 2, 3, 4, 5, 6, 7 },
	scale = 1.1,
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
	primaryAttacks = { {"blindattack",""}, {"knockdownattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_ice_mynock, "hoth_ice_mynock")
