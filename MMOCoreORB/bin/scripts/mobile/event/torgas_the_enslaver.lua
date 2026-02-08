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
	-- Corpse loot disabled; worldboss screenplay handles shared loot distribution.
	lootGroups = {},

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
