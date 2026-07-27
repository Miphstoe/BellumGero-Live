-- Round 1 Nuna Event mobile: stats matched to bone_crushing_grak, loot table matched to acklay
tiny_cabbage_nuna = Creature:new {
	objectName = "@mob/creature_names:nuna",
	customName = "Tiny Cabbage",
	socialGroup = "self",
	faction = "",
	mobType = MOB_CARNIVORE,
	level = 98,
	chanceHit = 0.95,
	damageMin = 620,
	damageMax = 950,
	baseXp = 9336,
	baseHAM = 20000,
	baseHAMmax = 25000,
	armor = 2,
	resists = {150,165,0,200,200,200,0,0,-1},
	meatType = "meat_avian",
	meatAmount = 1000,
	hideType = "hide_leathery",
	hideAmount = 1000,
	boneType = "bone_avian",
	boneAmount = 950,
	milk = 0,
	tamingChance = 0,
	ferocity = 20,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/nuna_hue.iff"},
	hues = { 16, 17, 18, 19, 20, 21, 22, 23 },
	scale = 1.4,

	-- Loot table matches the acklay (dungeon/geonosian_bio_lab/acklay.lua)
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
			lootChance = 500000, -- 5.00% total chance
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 500000
		}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareableeding",""}, {"creatureareacombo",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(tiny_cabbage_nuna, "tiny_cabbage_nuna")
