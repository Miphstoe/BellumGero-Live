-- Mandalorian Daily Bounty - Tier 2 Loot (Low drop rates)
-- Similar to tier 1, slightly better
-- BH 46.5% + DW armor 30% + jetpack 5% + jetpack parts 4.5% + decor 5% + furniture schematics 9%
-- Total = 10,000,000

mando_daily_bounty_tier2_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (46.5% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 465000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 465000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 465000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 465000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 465000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 465000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 465000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 465000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 465000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 465000},
		-- DW Mandalorian armor schematics (30% of pool)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 300000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 300000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 300000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 300000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 300000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 300000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 300000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 300000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 300000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 300000},
		-- DW Mandalorian jetpack schematic (5%)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 500000},
		-- Jetpack parts - crafting components (4.5% of pool)
		{itemTemplate = "fuel_dispersion_unit",                weight = 150000},
		{itemTemplate = "injector_tank",                       weight = 150000},
		{itemTemplate = "ducted_fan",                          weight = 150000},
		-- Decor (5% of pool)
		{itemTemplate = "art_sm_s1",                           weight = 100000},
		{itemTemplate = "art_sm_s2",                           weight = 100000},
		{itemTemplate = "art_sm_s3",                           weight = 100000},
		{itemTemplate = "art_sm_s4",                           weight = 100000},
		{itemTemplate = "art_lg_s1",                           weight = 50000},
		{itemTemplate = "art_lg_s2",                           weight = 50000},
		-- Furniture and decoration schematics (9% of pool)
		{itemTemplate = "portable_stove_schematic",            weight = 70000},
		{itemTemplate = "potted_plants_sml_s02_schematic",     weight = 70000},
		{itemTemplate = "throw_pillow_schematic",              weight = 70000},
		{itemTemplate = "plain_bowl_schematic",                weight = 70000},
		{itemTemplate = "carved_bowl_schematic",               weight = 70000},
		{itemTemplate = "closed_basket_schematic",             weight = 70000},
		{itemTemplate = "kitchen_utensils",                    weight = 70000},
		{itemTemplate = "fat_bottle_schematic",                weight = 70000},
		{itemTemplate = "pear_bottle_schematic",               weight = 70000},
		{itemTemplate = "tall_bottle_schematic",               weight = 70000},
		{itemTemplate = "cantina_chair_schematic",             weight = 100000},
		{itemTemplate = "tanned_hide_s01_schematic",           weight = 100000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier2_loot", mando_daily_bounty_tier2_loot)
