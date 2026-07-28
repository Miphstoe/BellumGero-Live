-- Mandalorian Daily Bounty - Tier 3 Loot (Medium drop rates)
-- Better chances for DW Mando schematics
-- BH 44% + DW armor 40% + jetpack 10% + decor 6%
-- Total = 10,000,000

mando_daily_bounty_tier3_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (44% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 440000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 440000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 440000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 440000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 440000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 440000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 440000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 440000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 440000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 440000},
		-- DW Mandalorian armor schematics (40% of pool - higher)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 400000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 400000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 400000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 400000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 400000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 400000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 400000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 400000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 400000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 400000},
		-- DW Mandalorian jetpack schematic (10% - better)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 1000000},
		-- Decor (6% of pool)
		{itemTemplate = "art_sm_s1",                           weight = 75000},
		{itemTemplate = "art_sm_s2",                           weight = 75000},
		{itemTemplate = "art_sm_s3",                           weight = 75000},
		{itemTemplate = "art_sm_s4",                           weight = 75000},
		{itemTemplate = "art_lg_s1",                           weight = 100000},
		{itemTemplate = "art_lg_s2",                           weight = 100000},
		{itemTemplate = "dwb_viewscreen_s1",                   weight = 50000},
		{itemTemplate = "dwb_viewscreen_s2",                   weight = 50000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier3_loot", mando_daily_bounty_tier3_loot)
