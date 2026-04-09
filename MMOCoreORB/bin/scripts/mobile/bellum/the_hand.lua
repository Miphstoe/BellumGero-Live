the_hand = Creature:new {
	objectName = "",
	customName = "The Hand",
	socialGroup = "dark_jedi",
	faction = "dark_jedi",
	mobType = MOB_NPC,
	level = 250,
	chanceHit = 12.5,
	damageMin = 2800,
	damageMax = 5200,
	baseXp = 28000,
	baseHAM = 220000,
	baseHAMmax = 270000,
	armor = 2,
	resists = {95,95,95,95,95,95,95,95,40},
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
	creatureBitmask = PACK + KILLER + HEALER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_dark_jedi_human_female_01.iff"},
	lootGroups = {
		{
			groups = {
				{group = "color_crystals", chance = 2000000},
				{group = "clothing_attachments", chance = 2500000},
				{group = "armor_attachments", chance = 2500000},
				{group = "holocron_dark", chance = 2000000},
				{group = "the_hand", chance = 1500000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "none",
	conversationTemplate = "",

	primaryAttacks = merge(lightsabermaster, forcepowermaster),
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(the_hand, "the_hand")
