-- C-3PO (Event Mobile) - protocol droid body, same options as R2-D2
-- Place under: scripts/mobile/droid/ (or wherever you keep custom event mobs)

c3po_event = Creature:new {
    -- Name & identity
    customName = "C-3PO",
    randomNameType = 0,
    randomNameTag = false,

    objectName = "@mob/creature_names:c3po",  -- optional fallback string tag if you have one
    socialGroup = "event_droids",
    faction = "",
    mobType = MOB_DROID,

    -- Tuning: “somewhat strong” like your R2 template
    level = 85,
    chanceHit = 0.62,
    damageMin = 350,
    damageMax = 520,
    baseXp = 8500,

    -- HAM / Armor / Resists
    baseHAM = 210000,
    baseHAMmax = 250000,
    armor = 1,  -- light
    -- Resist order: kinetic, energy, blast, heat, cold, electricity, acid, stun, lightsaber
    resists = {65, 65, 55, 60, 55, 70, 45, 35, 25},

    -- Droid “resources”
    meatType = "",
    meatAmount = 0,
    hideType = "",
    hideAmount = 0,
    boneType = "",
    boneAmount = 0,
    milk = 0,

    -- Behavior
    tamingChance = 0,
    ferocity = 0,

    -- Flags
    pvpBitmask = ATTACKABLE + AGGRESSIVE + ENEMY,
    creatureBitmask = PACK,
    optionsBitmask = AIENABLED,
    diet = HERBIVORE,

    -- Appearance: pick the path that exists in your TREs
    -- Common variants in many client sets (names vary by pack):
    --   "object/mobile/protocol_droid_c3po.iff"
    --   "object/mobile/protocol_droid_3po.iff"
    --   "object/mobile/protocol_droid.iff"
    templates = {"object/mobile/3po_protocol_droid.iff"},

    -- Loot: reuse the R2 group; change to your own if desired
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

    -- Protocol droid is human-height; no upscale needed
    scale = 1.5,

    -- Combat setup (same as R2)
    primaryWeapon = "ranged_carbine",
    secondaryWeapon = "unarmed",
    attacks = merge(marksmanmaster, brawlermaster),

    conversationTemplate = "",
}

CreatureTemplates:addCreatureTemplate(c3po_event, "c3po_event")
