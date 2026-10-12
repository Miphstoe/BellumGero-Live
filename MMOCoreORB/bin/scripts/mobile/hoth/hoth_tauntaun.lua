hoth_tauntaun = Creature:new {
	objectName = "",
	customName = "a Hoth tauntaun",
	socialGroup = "tauntaun",
	faction = "",
	mobType = MOB_HERBIVORE,
	level = 65,
	chanceHit = 0.6,
	damageMin = 470,
	damageMax = 610,
	baseXp = 6290,
	baseHAM = 12500,
	baseHAMmax = 14500,
	armor = 1,
	resists = {120,120,20,150,20,150,20,20,-1},
	meatType = "meat_herbivore",
	meatAmount = 700,
	hideType = "hide_wooly",
	hideAmount = 600,
	boneType = "bone_mammal",
	boneAmount = 500,
	milk = 300,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = HERD,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {"object/mobile/tauntaun_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.0,
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
	primaryAttacks = { {"knockdownattack",""}, {"dizzyattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(hoth_tauntaun, "hoth_tauntaun")
