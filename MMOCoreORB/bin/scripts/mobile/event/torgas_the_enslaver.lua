-- ============================================================================
-- TORGAS THE ENSLAVER - EVENT BOSS
-- A fearsome Hutt crime lord brought to life for the Sunday Event
-- ============================================================================

torgas_the_enslaver = Creature:new {
	objectName = "@mob/creature_names:torgas_the_enslaver",
	customName = "Torgas the Enslaver",
	socialGroup = "jabba",
	faction = "",
	mobType = MOB_CARNIVORE,

	-- ========== COMBAT STATS ==========
	level = 350,
	chanceHit = 28.0,
	damageMin = 2100,
	damageMax = 4200,
	baseXp = 28000,

	-- ========== HEALTH & ARMOR ==========
	baseHAM = 450000,
	baseHAMmax = 550000,
	armor = 2,

	-- ========== RESISTANCES ==========
	-- Order: Kinetic, Energy, Electricity, Stun, Blast, Heat, Cold, Acid, Lightsaber
	-- High resistances across the board - Hutts are naturally resilient
	resists = {165, 170, 160, 155, 165, 175, 170, 180, 120},

	-- ========== HARVESTING ==========
	meatType = "meat_herbivore",
	meatAmount = 800,
	hideType = "hide_scaley",
	hideAmount = 600,
	boneType = "bone_mammal",
	boneAmount = 500,
	milk = 0,

	-- ========== BEHAVIOR & APPEARANCE ==========
	tamingChance = 0,
	ferocity = 25,
	scale = 1.5,  -- Hutts are large but not as massive as Krayt Dragons

	-- ========== BITMASKS ==========
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER + STALKER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	-- ========== APPEARANCE ==========
	templates = {"object/mobile/hutt_male.iff"},

	-- ========== LOOT ==========
	-- Uses the same loot tables as Ancient Krayt Dragon for consistency
	lootGroups = {
		{  -- 100% drop chance
			groups = {
				{group = "krayt_tissue_rare", chance = 3000000},         -- 30%
				{group = "krayt_dragon_common", chance = 3000000},       -- 30%
				{group = "krayt_pearls", chance = 2000000},              -- 20%
				{group = "armor_attachments", chance = 1000000},         -- 10%
				{group = "clothing_attachments", chance = 1000000},      -- 10%
			},
			lootChance = 10000000,
		},
		{  -- 70% drop chance
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},         -- 25%
				{group = "krayt_dragon_common", chance = 3500000},       -- 35%
				{group = "krayt_pearls", chance = 2000000},              -- 20%
				{group = "armor_attachments", chance = 1000000},         -- 10%
				{group = "clothing_attachments", chance = 1000000},      -- 10%
			},
			lootChance = 7000000,
		},
		{  -- 50% drop chance
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},         -- 25%
				{group = "krayt_dragon_common", chance = 3500000},       -- 35%
				{group = "krayt_pearls", chance = 2000000},              -- 20%
				{group = "armor_attachments", chance = 1000000},         -- 10%
				{group = "clothing_attachments", chance = 1000000},      -- 10%
			},
			lootChance = 5000000,
		},
		{  -- 25% drop chance
			groups = {
				{group = "krayt_tissue_rare", chance = 2500000},         -- 25%
				{group = "krayt_dragon_common", chance = 3500000},       -- 35%
				{group = "krayt_pearls", chance = 2000000},              -- 20%
				{group = "armor_attachments", chance = 1000000},         -- 10%
				{group = "clothing_attachments", chance = 1000000},      -- 10%
			},
			lootChance = 2500000,
		},
		{  -- 15% drop chance - pearls
			groups = {
				{group = "krayt_pearls", chance = 10000000},             -- 100%
			},
			lootChance = 1500000,
		},
		{  -- 10% drop chance - pearls
			groups = {
				{group = "krayt_pearls", chance = 10000000},             -- 100%
			},
			lootChance = 1000000,
		},
		{  -- 15% drop chance - endgame schematics
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000},
			},
			lootChance = 1500000,
		},
		{  -- 3.5% drop chance - event token (BG Token)
			groups = {
				{group = "bg_token_group", chance = 10000000},
			},
			lootChance = 350000,
		},
	},

	-- ========== WEAPONS & ATTACKS ==========
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",

	-- Torgas uses powerful Hutt crime lord attacks - combination of striking and crowd control
	primaryAttacks = {
		{"creatureareacombo", "stateAccuracyBonus=100"},     -- AOE combo attack
		{"creatureareaknockdown", "stateAccuracyBonus=100"}, -- AOE knockdown attack
		{"creatureconeattack", "stateAccuracyBonus=75"},     -- Cone attack
	},

	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(torgas_the_enslaver, "torgas_the_enslaver")
