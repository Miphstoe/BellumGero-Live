-- Mandalorian Daily Bounty - Tier 1 Loot (Low drop rates)
-- Lower chance for DW Mando schematics, higher for BH schematics
-- Total = 10,000,000

mando_daily_bounty_tier1_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- BH armor schematics (70% of pool)
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 700000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 700000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 700000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 700000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 700000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 700000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 700000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 700000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 700000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 700000},
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
	}
}

addLootGroupTemplate("mando_daily_bounty_tier1_loot", mando_daily_bounty_tier1_loot)
