-- The Dark Lord: GM-spawned event world boss (Vader-style Sith Lord).
-- Appearance reuses object/mobile/darth_vader.iff (same client template as Supreme Warlord Darth Malvek).
-- Weapon reuses weapon group "darth_vader_weapons" (sword_lightsaber_vader.iff).
-- NOT registered in any spawn manager, lair, mission or screenplay: it only exists when a GM runs
--   /createCreature bg_dark_lord_boss
-- Loot is rolled on the corpse via the normal lootGroups system (per-roll chances, see below).
bg_dark_lord_boss = Creature:new {
	objectName = "",
	customName = "The Dark Lord",
	socialGroup = "dark_jedi",
	-- faction left empty on purpose: an "imperial" faction would exempt Imperial-flagged players from aggro.
	faction = "",
	mobType = MOB_NPC,
	level = 350,
	chanceHit = 30,
	damageMin = 3500,
	damageMax = 6500,
	baseXp = 45000,
	baseHAM = 2500000,
	baseHAMmax = 2500000,
	armor = 3, -- heavy
	-- kinetic, energy, blast, heat, cold, electricity, acid, stun, lightsaber
	resists = {175,175,175,175,170,175,175,175,90},
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
	creatureBitmask = KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.3,

	templates = {"object/mobile/darth_vader.iff"},

	lootGroups = {
		{
			groups = {
				{group = "power_crystals", chance = 2500000},
				{group = "color_crystals", chance = 2500000},
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "krayt_tissue_rare", chance = 1000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "power_crystals", chance = 2500000},
				{group = "color_crystals", chance = 2500000},
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "krayt_tissue_rare", chance = 1000000}
			},
			lootChance = 6000000
		},
		{
			groups = {
				{group = "power_crystals", chance = 2500000},
				{group = "color_crystals", chance = 2500000},
				{group = "armor_attachments", chance = 2000000},
				{group = "clothing_attachments", chance = 2000000},
				{group = "krayt_tissue_rare", chance = 1000000}
			},
			lootChance = 3000000
		},
		{ groups = { {group = "krayt_pearls", chance = 10000000} }, lootChance = 2000000 },
		{ groups = { {group = "endgame_weapon_schematics", chance = 10000000} }, lootChance = 1000000 },
		{ groups = { {group = "bg_token_group", chance = 10000000} }, lootChance = 350000 }
	},

	primaryWeapon = "darth_vader_weapons",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- Single saber (1h/2h/polearm sweeps + spin = area "whirlwind") plus Force powers
	-- (lightning single + cone, choke, knockdown, throw). The AI picks randomly from this list;
	-- Core3 has no per-attack cooldown field for NPCs (see report).
	primaryAttacks = {
		{"saber1hhit3", ""},
		{"saber1hflurry2", ""},
		{"saberslash2", ""},
		{"saber2hphantom", ""},
		{"saber2hsweep3", ""},
		{"saberpolearmspinattack3", ""},
		{"forcelightningsingle2", ""},
		{"forcelightningcone2", ""},
		{"forcechoke", ""},
		{"forceknockdown2", ""},
		{"forcethrow2", ""}
	},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(bg_dark_lord_boss, "bg_dark_lord_boss")
