-- Mandalorian Way of Life — Chapter 1 completion bonus loot
-- Pool: BH armor schematics only (10 items, equal weight)
-- Weights sum to exactly 10,000,000

mando_chapter_loot_1 = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 1000000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 1000000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 1000000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 1000000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 1000000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 1000000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 1000000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 1000000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 1000000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 1000000},
	}
}

addLootGroupTemplate("mando_chapter_loot_1", mando_chapter_loot_1)
