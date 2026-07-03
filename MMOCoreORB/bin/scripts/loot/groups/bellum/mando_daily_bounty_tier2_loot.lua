-- Mandalorian Daily Bounty - Tier 2 Loot (Low drop rates)
-- Similar to tier 1, slightly better
-- Total = 10,000,000

mando_daily_bounty_tier2_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (65% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 650000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 650000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 650000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 650000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 650000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 650000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 650000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 650000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 650000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 650000},
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
	}
}

addLootGroupTemplate("mando_daily_bounty_tier2_loot", mando_daily_bounty_tier2_loot)
