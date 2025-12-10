wookiee_jedi_event = Creature:new {
	--objectName = "@mob/creature_names:wookiee_brawler",
	customName = "Wookiee Jedi",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 325,
	chanceHit = 3.0,
	damageMin = 1200,
	damageMax = 2000,
	baseXp = 25000,
	baseHAM = 250000,
	baseHAMmax = 350000,
	armor = 3,
	resists = {65,65,65,65,65,65,65,65,-1},
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
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.2,

	templates = {"object/mobile/wookiee_male.iff"},

	lootGroups = {
		{
			groups = {
				{group = "junk", chance = 3000000},
				{group = "weapon_component_advanced", chance = 2250000},
				{group = "bounty_hunter_armor", chance = 1000000},
				{group = "jetpack_base", chance = 1050000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000},
				{group = "power_crystals", chance = 700000},
			},
			lootChance = 4000000, -- 40.00% total chance
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		}
	},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(lightsabermaster,forcepowermaster),
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(wookiee_jedi_event, "wookiee_jedi_event")
