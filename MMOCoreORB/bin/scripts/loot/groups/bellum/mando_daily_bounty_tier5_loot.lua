-- Mandalorian Daily Bounty - Tier 5 Loot (Highest drop rates)
-- Best chances for DW Mando schematics and jetpack
-- BH 22% + DW armor 50% + jetpack 20% + decor/trophies 8%
-- Total = 10,000,000

mando_daily_bounty_tier5_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (22% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 220000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 220000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 220000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 220000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 220000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 220000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 220000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 220000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 220000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 220000},
		-- DW Mandalorian armor schematics (50% of pool - highest)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 500000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 500000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 500000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 500000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 500000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 500000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 500000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 500000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 500000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 500000},
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
	}
}

addLootGroupTemplate("mando_daily_bounty_tier5_loot", mando_daily_bounty_tier5_loot)
