-- Mandalorian Way of Life — Chapter 3 completion bonus loot
-- Pool: BH + DW Mando schematics + jetpack parts + krayt mats + DWB classics
-- BH: 330,000 each × 10 = 3,300,000
-- Furniture/decor schematics: 1,000,000
-- DW armor: 300,000 each × 10 = 3,000,000
-- DW jetpack: 200,000 × 1 = 200,000
-- JP parts: 300,000 each × 3 = 900,000
-- Krayt scales: 300,000
-- Krayt tissue common: 400,000
-- Krayt tissue uncommon: 300,000
-- Krayt tissue rare: 200,000
-- DWB classics: 400,000
-- Total = 10,000,000

mando_chapter_loot_3 = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (33% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 330000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 330000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 330000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 330000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 330000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 330000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 330000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 330000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 330000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 330000},
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
		-- Jetpack parts — crafting components (9% total)
		{itemTemplate = "fuel_dispersion_unit",                weight = 300000},
		{itemTemplate = "injector_tank",                       weight = 300000},
		{itemTemplate = "ducted_fan",                          weight = 300000},
		-- Krayt armor/weapon enhancement mats (12% total)
		{itemTemplate = "krayt_dragon_scales",                 weight = 300000},
		{itemTemplate = "krayt_dragon_tissue_common",          weight = 400000},
		{itemTemplate = "krayt_dragon_tissue_uncommon",        weight = 300000},
		{itemTemplate = "krayt_dragon_tissue_rare",            weight = 200000},
		-- Death Watch Bunker classics (4% total)
		{itemTemplate = "pistol_de10_schematic",               weight = 150000},
		{itemTemplate = "executioners_hack_schematic",         weight = 150000},
		{itemTemplate = "mandalorian_wine_schematic",          weight = 50000},
		{itemTemplate = "mandalorian_rebreather",              weight = 50000},
		-- Furniture and decoration schematics (10% total)
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
		{itemTemplate = "cantina_chair_schematic",             weight = 50000},
		{itemTemplate = "tanned_hide_s01_schematic",           weight = 50000},
		{itemTemplate = "streetlamp_schematic",                weight = 50000},
		{itemTemplate = "spear_rack_schematic",                weight = 50000},
		{itemTemplate = "couch_blue_schematic",                weight = 50000},
		{itemTemplate = "armoire_plain_schematic",             weight = 50000},
		{itemTemplate = "cabinet_plain_schematic",             weight = 50000},
		{itemTemplate = "chest_plain_schematic",               weight = 50000},
	}
}

addLootGroupTemplate("mando_chapter_loot_3", mando_chapter_loot_3)
