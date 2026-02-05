mallichae_bg_rite = Creature:new {
	objectName = "@mob/creature_names:mellichae",
	socialGroup = "sith_shadow",
	faction = "sith_shadow",
	mobType = MOB_NPC,
	level = 90,
	chanceHit = 3.75,
	damageMin = 550,
	damageMax = 900,
	baseXp = 9000,
	baseHAM = 22000,
	baseHAMmax = 26000,
	armor = 1,
	resists = {55,55,55,55,55,55,55,55,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0.000000,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = KILLER,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_fs_village_enemy_mellichae.iff"},
	lootGroups = {
		{
			groups = {
				{group = "mallichae_bg_rite", chance = 10000000}
			},
			lootChance = 10000000
		}
	},

	primaryWeapon = "dark_jedi_weapons_gen2",
	secondaryWeapon = "dark_jedi_weapons_ranged",

	primaryAttacks = lightsabermaster,
	secondaryAttacks = forcewielder
}

CreatureTemplates:addCreatureTemplate(mallichae_bg_rite, "mallichae_bg_rite")
