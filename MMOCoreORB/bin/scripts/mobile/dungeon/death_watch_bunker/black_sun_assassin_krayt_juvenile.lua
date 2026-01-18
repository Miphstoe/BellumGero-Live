black_sun_assassin_krayt_juvenile = Creature:new {
	objectName = "",
	customName = "Black Sun Assassin (Juvenile)",
	mobType = MOB_NPC,
	socialGroup = "death_watch",
	faction = "",
	level = 122,
	chanceHit = 4.0,
	damageMin = 745,
	damageMax = 1200,
	baseXp = 11577,
	baseHAM = 154000,
	baseHAMmax = 164000,
	armor = 2,
	resists = {160,160,15,15,110,15,15,15,10},
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
	scale = 1.15,

	templates = {"object/mobile/dressed_black_sun_assassin.iff"},
	lootGroups = {
		{
			groups = {
				{group = "junk", chance = 5000000},
				{group = "weapon_component_advanced", chance = 2250000},
				{group = "bounty_hunter_armor", chance = 200000},
				{group = "jetpack_base", chance = 50000},
				{group = "armor_attachments", chance = 1000000},
				{group = "clothing_attachments", chance = 1000000},
				{group = "power_crystals", chance = 500000},
			},
			lootChance = 10000000, -- 100.00% total chance
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
	primaryWeapon = "deathwatch_ranged",
	secondaryWeapon = "pirate_unarmed",
	conversationTemplate = "",
	thrownWeapon = "thrown_weapons",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(bountyhuntermaster,marksmanmaster,carbineermaster),
	secondaryAttacks = brawlermaster,
}

CreatureTemplates:addCreatureTemplate(black_sun_assassin_krayt_juvenile, "black_sun_assassin_krayt_juvenile")
