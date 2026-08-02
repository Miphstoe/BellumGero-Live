-- Mandalorian Daily Bounty - Tier 1 Loot (Low drop rates)
-- Lower chance for DW Mando schematics, higher for BH schematics
-- BH 55% + DW armor 25% + jetpack 5% + jetpack parts 3% + decor 4% + furniture schematics 8%
-- Total = 10,000,000

mando_daily_bounty_tier1_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (55% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 550000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 550000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 550000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 550000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 550000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 550000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 550000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 550000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 550000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 550000},
		-- DW Mandalorian armor schematics (25% of pool - lower than chapter 2)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 250000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 250000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 250000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 250000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 250000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 250000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 250000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 250000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 250000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 250000},
		-- DW Mandalorian jetpack schematic (5% - very rare)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 500000},
		-- Jetpack parts - crafting components (3% of pool)
		{itemTemplate = "fuel_dispersion_unit",                weight = 100000},
		{itemTemplate = "injector_tank",                       weight = 100000},
		{itemTemplate = "ducted_fan",                          weight = 100000},
		-- Decor (4% of pool)
		{itemTemplate = "art_sm_s1",                           weight = 100000},
		{itemTemplate = "art_sm_s2",                           weight = 100000},
		{itemTemplate = "art_sm_s3",                           weight = 100000},
		{itemTemplate = "art_sm_s4",                           weight = 100000},
		-- Furniture and decoration schematics (8% of pool)
		{itemTemplate = "portable_stove_schematic",             weight = 80000},
		{itemTemplate = "potted_plants_sml_s02_schematic",      weight = 80000},
		{itemTemplate = "throw_pillow_schematic",               weight = 80000},
		{itemTemplate = "plain_bowl_schematic",                 weight = 80000},
		{itemTemplate = "carved_bowl_schematic",                weight = 80000},
		{itemTemplate = "closed_basket_schematic",              weight = 80000},
		{itemTemplate = "kitchen_utensils",                     weight = 80000},
		{itemTemplate = "fat_bottle_schematic",                 weight = 80000},
		{itemTemplate = "pear_bottle_schematic",                weight = 80000},
		{itemTemplate = "tall_bottle_schematic",                weight = 80000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier1_loot", mando_daily_bounty_tier1_loot)
