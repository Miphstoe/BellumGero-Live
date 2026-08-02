-- Mandalorian Way of Life — guaranteed drop from contract target kill
-- One item drawn from this pool per kill.
-- Pool: BH schematics (10), DW Mando schematics (11), jetpack parts (3),
--       krayt scales (1), krayt tissues common/uncommon/rare (3),
--       DWB classics: DE-10 schematic, Executioner's Hack schematic,
--       Mandalorian Wine schematic, rebreather, DE-10 barrel = 33 items,
--       furniture/decor schematics (14, 8% of pool)

mando_contract_kill_reward = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- Bounty Hunter armor schematics
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 320000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 320000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 320000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 320000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 320000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 320000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 320000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 320000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 320000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 320000},
		-- DW Mandalorian armor schematics (rarer than BH)
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
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 250000},
		-- Jetpack parts (crafting mats)
		{itemTemplate = "fuel_dispersion_unit",                weight = 500000},
		{itemTemplate = "injector_tank",                       weight = 500000},
		{itemTemplate = "ducted_fan",                          weight = 500000},
		-- Krayt mats (armor enhancement components)
		{itemTemplate = "krayt_dragon_scales",                 weight = 350000},
		{itemTemplate = "krayt_dragon_tissue_common",          weight = 500000},
		{itemTemplate = "krayt_dragon_tissue_uncommon",        weight = 350000},
		{itemTemplate = "krayt_dragon_tissue_rare",            weight = 200000},
		-- Death Watch Bunker classics (3.5% total)
		{itemTemplate = "pistol_de10_schematic",               weight = 100000},
		{itemTemplate = "executioners_hack_schematic",         weight = 100000},
		{itemTemplate = "mandalorian_wine_schematic",          weight = 50000},
		{itemTemplate = "mandalorian_rebreather",              weight = 50000},
		{itemTemplate = "de10_pistol_barrel",                  weight = 50000},
		-- Furniture and decoration schematics (8% total)
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
		{itemTemplate = "streetlamp_schematic",                weight = 50000},
		{itemTemplate = "tanned_hide_s01_schematic",           weight = 50000},
		{itemTemplate = "spear_rack_schematic",                weight = 50000},
	}
}

addLootGroupTemplate("mando_contract_kill_reward", mando_contract_kill_reward)
