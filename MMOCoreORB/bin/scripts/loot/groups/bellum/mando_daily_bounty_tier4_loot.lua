-- Mandalorian Daily Bounty - Tier 4 Loot (High drop rates)
-- Better chances for DW Mando schematics and jetpack
-- BH 14.5% + DW armor 45% + jetpack 15% + jetpack parts 7.5% + decor/trophies 7% + furniture schematics 11%
-- Total = 10,000,000

mando_daily_bounty_tier4_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (14.5% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 145000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 145000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 145000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 145000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 145000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 145000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 145000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 145000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 145000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 145000},
		-- DW Mandalorian armor schematics (45% of pool - high)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 450000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 450000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 450000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 450000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 450000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 450000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 450000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 450000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 450000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 450000},
		-- DW Mandalorian jetpack schematic (15% - good)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 1500000},
		-- Jetpack parts - crafting components (7.5% of pool)
		{itemTemplate = "fuel_dispersion_unit",                weight = 250000},
		{itemTemplate = "injector_tank",                       weight = 250000},
		{itemTemplate = "ducted_fan",                          weight = 250000},
		-- Decor and trophies (7% of pool)
		{itemTemplate = "art_lg_s1",                           weight = 75000},
		{itemTemplate = "art_lg_s2",                           weight = 75000},
		{itemTemplate = "dwb_viewscreen_s1",                   weight = 75000},
		{itemTemplate = "dwb_viewscreen_s2",                   weight = 75000},
		{itemTemplate = "mando_armor_blueprint_painting",      weight = 100000},
		{itemTemplate = "mando_hunter_portrait",               weight = 100000},
		{itemTemplate = "mando_clan_banner",                   weight = 100000},
		{itemTemplate = "mando_clan_painting",                 weight = 50000},
		{itemTemplate = "mando_holo_emblem",                   weight = 25000},
		{itemTemplate = "mando_helmet_trophy",                 weight = 25000},
		-- Furniture and decoration schematics (11% of pool)
		{itemTemplate = "portable_stove_schematic",            weight = 60000},
		{itemTemplate = "potted_plants_sml_s02_schematic",     weight = 60000},
		{itemTemplate = "throw_pillow_schematic",              weight = 60000},
		{itemTemplate = "plain_bowl_schematic",                weight = 60000},
		{itemTemplate = "carved_bowl_schematic",               weight = 60000},
		{itemTemplate = "closed_basket_schematic",             weight = 60000},
		{itemTemplate = "kitchen_utensils",                    weight = 60000},
		{itemTemplate = "fat_bottle_schematic",                weight = 60000},
		{itemTemplate = "pear_bottle_schematic",               weight = 60000},
		{itemTemplate = "tall_bottle_schematic",               weight = 60000},
		{itemTemplate = "cantina_chair_schematic",             weight = 60000},
		{itemTemplate = "tanned_hide_s01_schematic",           weight = 60000},
		{itemTemplate = "streetlamp_schematic",                weight = 60000},
		{itemTemplate = "spear_rack_schematic",                weight = 60000},
		{itemTemplate = "couch_blue_schematic",                weight = 80000},
		{itemTemplate = "armoire_plain_schematic",             weight = 60000},
		{itemTemplate = "cabinet_plain_schematic",             weight = 60000},
		{itemTemplate = "chest_plain_schematic",               weight = 60000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier4_loot", mando_daily_bounty_tier4_loot)
