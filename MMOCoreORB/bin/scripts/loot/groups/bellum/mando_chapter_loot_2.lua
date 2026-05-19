-- Mandalorian Way of Life — Chapter 2 completion bonus loot
-- Pool: BH schematics (common) + DW Mando schematics (rarer)
-- BH: 600,000 each × 10 = 6,000,000
-- DW armor: 370,000 each × 10 = 3,700,000
-- DW jetpack: 300,000 × 1 = 300,000
-- Total = 10,000,000

mando_chapter_loot_2 = {
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
		-- DW Mandalorian armor schematics (37% of pool)
		{itemTemplate = "dw_mando_helmet_schematic",           weight = 370000},
		{itemTemplate = "dw_mando_chest_plate_schematic",      weight = 370000},
		{itemTemplate = "dw_mando_belt_schematic",             weight = 370000},
		{itemTemplate = "dw_mando_boots_schematic",            weight = 370000},
		{itemTemplate = "dw_mando_bracer_l_schematic",         weight = 370000},
		{itemTemplate = "dw_mando_bracer_r_schematic",         weight = 370000},
		{itemTemplate = "dw_mando_bicep_l_schematic",          weight = 370000},
		{itemTemplate = "dw_mando_bicep_r_schematic",          weight = 370000},
		{itemTemplate = "dw_mando_gloves_schematic",           weight = 370000},
		{itemTemplate = "dw_mando_leggings_schematic",         weight = 370000},
		-- DW Mandalorian jetpack schematic (3% — rarest)
		{itemTemplate = "dw_mando_jetpack_schematic",          weight = 300000},
	}
}

addLootGroupTemplate("mando_chapter_loot_2", mando_chapter_loot_2)
