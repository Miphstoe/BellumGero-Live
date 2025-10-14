-- R2-D2 (Event Mobile) - high resists, Marksman primary, Brawler secondary
-- Place under: scripts/mobile/droid/ (or wherever you keep custom event mobs)

r2_d2_event = Creature:new {
    -- Name & identity
    customName = "R2-D2",
    randomNameType = 0,
    randomNameTag = false,

    objectName = "@mob/creature_names:r2_d2",  -- fallback if you have a localized string
    socialGroup = "event_droids",
    faction = "",
    mobType = MOB_DROID,

    -- Tuning: “somewhat strong” elite add, not a boss
    level = 200,
    chanceHit = 0.62,
    damageMin = 350,
    damageMax = 520,
    baseXp = 8500,

    -- HAM / Armor / Resists (droid-leaning, generally high; LS kept modest)
    baseHAM = 210000,
    baseHAMmax = 250000,
    armor = 1,  -- 0=none, 1=light, 2=medium, 3=heavy (keep light to let resists do the work)
    -- Resist order: kinetic, energy, blast, heat, cold, electricity, acid, stun, lightsaber
    resists = {65, 65, 55, 60, 55, 70, 45, 35, 25},

    -- Creature “resources” (droid: none)
    meatType = "",
    meatAmount = 0,
    hideType = "",
    hideAmount = 0,
    boneType = "",
    boneAmount = 0,
    milk = 0,

    -- Taming/behavior
    tamingChance = 0,
    ferocity = 0,

    -- Flags (usually fine for event encounters)
    pvpBitmask = ATTACKABLE + AGGRESSIVE + ENEMY,
    creatureBitmask = PACK,      -- remove if you’ll only ever spawn a single unit
    optionsBitmask = AIENABLED,
    diet = HERBIVORE,

    -- Appearance (pick the one that exists in your TREs)
    -- Common options in core3 packs:
    --   "object/mobile/r2.iff"
    --   "object/mobile/droid_r2.iff"
    --   "object/mobile/astromech_r2.iff"
    templates = {"object/mobile/r2.iff"},

    lootGroups = {
		{
			groups = {
				{group = "color_crystals", chance = 1000000},
				{group = "power_crystals", chance = 1750000},
                {group = "coa_encoded_disk_fragments", chance = 2000000},
				{group = "weapon_component_advanced", chance = 2000000},
                {group = "coa3_alderaan_flora", chance = 1000000},
				{group = "clothing_attachments", chance = 1025000},
				{group = "armor_attachments", chance = 1025000}
			},
			lootChance = 7500000
		}
	},
    scale = 1.5,

    -- Combat setup
    -- Primary: Marksman (carbine/rifle/pistol) — choose carbine for classic “pew” pacing
    -- Secondary: Brawler (unarmed)
    -- If your server uses weapon-group strings, set them here; if not, leave “unarmed” and rely on attacks merge.
    primaryWeapon = "ranged_carbine",  -- alternatives: "ranged_rifle", "ranged_weapons"
    secondaryWeapon = "unarmed",

    -- Attack pools: give it full Marksman + Brawler trees so it actually uses the abilities
    attacks = merge(marksmanmaster, brawlermaster),

    conversationTemplate = "",
}

CreatureTemplates:addCreatureTemplate(r2_d2_event, "r2_d2_event")
