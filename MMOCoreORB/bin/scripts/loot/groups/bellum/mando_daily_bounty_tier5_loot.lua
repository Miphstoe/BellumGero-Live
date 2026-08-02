-- Mandalorian Daily Bounty - Tier 5 Loot (Highest drop rates)
-- Best chances for DW Mando schematics and jetpack
-- BH 16% + DW armor 44% + jetpack 20% + decor/trophies 8% + furniture schematics 12%
-- Total = 10,000,000

mando_daily_bounty_tier5_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (16% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 160000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 160000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 160000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 160000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 160000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 160000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 160000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 160000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 160000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 160000},
		-- DW Mandalorian armor schematics (44% of pool - highest)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 440000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 440000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 440000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 440000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 440000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 440000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 440000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 440000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 440000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 440000},
		-- DW Mandalorian jetpack schematic (20% - best)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 2000000},
		-- Decor and trophies (8% of pool)
		{itemTemplate = "dwb_viewscreen_s1",                   weight = 75000},
		{itemTemplate = "dwb_viewscreen_s2",                   weight = 75000},
		{itemTemplate = "mando_armor_blueprint_painting",      weight = 100000},
		{itemTemplate = "mando_hunter_portrait",               weight = 100000},
		{itemTemplate = "mando_clan_banner",                   weight = 100000},
		{itemTemplate = "death_watch_lamp",                    weight = 150000},
		{itemTemplate = "mando_clan_painting",                 weight = 75000},
		{itemTemplate = "mando_holo_emblem",                   weight = 50000},
		{itemTemplate = "mando_helmet_trophy",                 weight = 50000},
		{itemTemplate = "mando_helmet_holo",                   weight = 25000},
		-- Furniture and decoration schematics (12% of pool)
		{itemTemplate = "portable_stove_schematic",            weight = 45000},
		{itemTemplate = "potted_plants_sml_s02_schematic",     weight = 45000},
		{itemTemplate = "throw_pillow_schematic",              weight = 45000},
		{itemTemplate = "plain_bowl_schematic",                weight = 45000},
		{itemTemplate = "carved_bowl_schematic",               weight = 45000},
		{itemTemplate = "closed_basket_schematic",             weight = 45000},
		{itemTemplate = "kitchen_utensils",                    weight = 45000},
		{itemTemplate = "fat_bottle_schematic",                weight = 45000},
		{itemTemplate = "pear_bottle_schematic",               weight = 45000},
		{itemTemplate = "tall_bottle_schematic",               weight = 45000},
		{itemTemplate = "cantina_chair_schematic",             weight = 50000},
		{itemTemplate = "tanned_hide_s01_schematic",           weight = 40000},
		{itemTemplate = "tanned_hide_s02_schematic",           weight = 40000},
		{itemTemplate = "streetlamp_schematic",                weight = 50000},
		{itemTemplate = "spear_rack_schematic",                weight = 50000},
		{itemTemplate = "couch_blue_schematic",                weight = 50000},
		{itemTemplate = "armoire_technical_schematic",         weight = 55000},
		{itemTemplate = "cabinet_technical_schematic",         weight = 55000},
		{itemTemplate = "chest_technical_schematic",           weight = 55000},
		{itemTemplate = "elegant_cabinet_schematic",           weight = 70000},
		{itemTemplate = "gambling_table_schematic",            weight = 70000},
		{itemTemplate = "tatooine_tapestry_schematic",         weight = 60000},
		{itemTemplate = "technical_console_schematic_1",       weight = 30000},
		{itemTemplate = "technical_console_schematic_2",       weight = 30000},
		{itemTemplate = "radar_screen_schematic",              weight = 25000},
		{itemTemplate = "radio_schematic",                     weight = 20000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier5_loot", mando_daily_bounty_tier5_loot)
