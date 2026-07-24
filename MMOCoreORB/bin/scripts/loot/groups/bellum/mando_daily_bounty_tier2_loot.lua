-- Mandalorian Daily Bounty - Tier 2 Loot (Low drop rates)
-- Similar to tier 1, slightly better
-- BH 60% + DW armor 30% + jetpack 5% + decor 5%
-- Total = 10,000,000

mando_daily_bounty_tier2_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (60% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 600000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 600000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 600000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 600000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 600000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 600000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 600000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 600000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 600000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 600000},
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
		-- Decor (5% of pool)
		{itemTemplate = "art_sm_s1",                           weight = 100000},
		{itemTemplate = "art_sm_s2",                           weight = 100000},
		{itemTemplate = "art_sm_s3",                           weight = 100000},
		{itemTemplate = "art_sm_s4",                           weight = 100000},
		{itemTemplate = "art_lg_s1",                           weight = 50000},
		{itemTemplate = "art_lg_s2",                           weight = 50000},
	}
}

addLootGroupTemplate("mando_daily_bounty_tier2_loot", mando_daily_bounty_tier2_loot)
