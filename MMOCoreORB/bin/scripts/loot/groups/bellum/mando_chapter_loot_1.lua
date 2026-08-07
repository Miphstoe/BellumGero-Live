-- Mandalorian Way of Life — Chapter 1 completion bonus loot
-- Pool: BH armor schematics (90%) + basic furniture/decor schematics (10%)
-- Weights sum to exactly 10,000,000

mando_chapter_loot_1 = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "bounty_hunter_belt_schematic",        weight = 900000},
		{itemTemplate = "bounty_hunter_bicep_l_schematic",     weight = 900000},
		{itemTemplate = "bounty_hunter_bicep_r_schematic",     weight = 900000},
		{itemTemplate = "bounty_hunter_boots_schematic",       weight = 900000},
		{itemTemplate = "bounty_hunter_bracer_l_schematic",    weight = 900000},
		{itemTemplate = "bounty_hunter_bracer_r_schematic",    weight = 900000},
		{itemTemplate = "bounty_hunter_chest_plate_schematic", weight = 900000},
		{itemTemplate = "bounty_hunter_gloves_schematic",      weight = 900000},
		{itemTemplate = "bounty_hunter_helmet_schematic",      weight = 900000},
		{itemTemplate = "bounty_hunter_leggings_schematic",    weight = 900000},
		-- Furniture and decoration schematics (10% of pool)
		{itemTemplate = "portable_stove_schematic",            weight = 100000},
		{itemTemplate = "potted_plants_sml_s02_schematic",     weight = 100000},
		{itemTemplate = "throw_pillow_schematic",              weight = 100000},
		{itemTemplate = "plain_bowl_schematic",                weight = 100000},
		{itemTemplate = "carved_bowl_schematic",               weight = 100000},
		{itemTemplate = "closed_basket_schematic",             weight = 100000},
		{itemTemplate = "kitchen_utensils",                    weight = 100000},
		{itemTemplate = "fat_bottle_schematic",                weight = 100000},
		{itemTemplate = "pear_bottle_schematic",               weight = 100000},
		{itemTemplate = "tall_bottle_schematic",               weight = 100000},
	}
}

addLootGroupTemplate("mando_chapter_loot_1", mando_chapter_loot_1)
