-- Mandalorian Way of Life — Chapter 4 (Clanbound) completion bonus loot
-- Pool: All Ch3 items + rare tier (jetpack base, RIS schematic, peko feather, jetpack stabilizer)
-- BH: 350,000 each × 10 = 3,500,000
-- DW armor: 250,000 each × 10 = 2,500,000
-- DW jetpack: 150,000 × 1 = 150,000
-- JP parts: 150,000 each × 3 = 450,000
-- Krayt scales: 200,000
-- Krayt tissue common: 300,000
-- Krayt tissue uncommon: 200,000
-- Krayt tissue rare: 150,000
-- Jet pack base: 500,000
-- RIS armor schematic: 500,000
-- Peko albatross feather: 850,000
-- Jetpack stabilizer: 700,000
-- Total = 10,000,000

mando_chapter_loot_4 = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (35% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 350000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 350000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 350000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 350000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 350000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 350000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 350000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 350000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 350000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 350000},
		-- DW Mandalorian armor schematics (25%)
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
		-- DW jetpack (1.5%)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 150000},
		-- Jetpack parts (4.5% total)
		{itemTemplate = "fuel_dispersion_unit",                weight = 150000},
		{itemTemplate = "injector_tank",                       weight = 150000},
		{itemTemplate = "ducted_fan",                          weight = 150000},
		-- Krayt mats (8.5% total)
		{itemTemplate = "krayt_dragon_scales",                 weight = 200000},
		{itemTemplate = "krayt_dragon_tissue_common",          weight = 300000},
		{itemTemplate = "krayt_dragon_tissue_uncommon",        weight = 200000},
		{itemTemplate = "krayt_dragon_tissue_rare",            weight = 150000},
		-- Rare tier unlocked at Clanbound (15% total)
		{itemTemplate = "jet_pack_base",                       weight = 500000},
		{itemTemplate = "acklay_ris_armor_schematic",          weight = 500000},
		{itemTemplate = "peko_albatross_feather",              weight = 850000},
		{itemTemplate = "jetpack_stabilizer",                  weight = 700000},
	}
}

addLootGroupTemplate("mando_chapter_loot_4", mando_chapter_loot_4)
