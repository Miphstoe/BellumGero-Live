-- Mandalorian Way of Life — Chapter 3 completion bonus loot
-- Pool: BH + DW Mando schematics + jetpack parts + krayt mats
-- BH: 500,000 each × 10 = 5,000,000
-- DW armor: 300,000 each × 10 = 3,000,000
-- DW jetpack: 200,000 × 1 = 200,000
-- JP parts: 200,000 each × 3 = 600,000
-- Krayt scales: 300,000
-- Krayt tissue common: 400,000
-- Krayt tissue uncommon: 300,000
-- Krayt tissue rare: 200,000
-- Total = 10,000,000

mando_chapter_loot_3 = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (50% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 500000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 500000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 500000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 500000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 500000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 500000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 500000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 500000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 500000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 500000},
		-- DW Mandalorian armor schematics (30%)
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
		-- DW jetpack (2%)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 200000},
		-- Jetpack parts — crafting components (6% total)
		{itemTemplate = "fuel_dispersion_unit",                weight = 200000},
		{itemTemplate = "injector_tank",                       weight = 200000},
		{itemTemplate = "ducted_fan",                          weight = 200000},
		-- Krayt armor/weapon enhancement mats (12% total)
		{itemTemplate = "krayt_dragon_scales",                 weight = 300000},
		{itemTemplate = "krayt_dragon_tissue_common",          weight = 400000},
		{itemTemplate = "krayt_dragon_tissue_uncommon",        weight = 300000},
		{itemTemplate = "krayt_dragon_tissue_rare",            weight = 200000},
	}
}

addLootGroupTemplate("mando_chapter_loot_3", mando_chapter_loot_3)
