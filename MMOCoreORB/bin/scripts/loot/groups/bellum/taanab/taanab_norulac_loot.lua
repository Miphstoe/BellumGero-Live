-- Taanab boss loot. Weights total 10,000,000.
taanab_norulac_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "taanab_norulac_captains_coat", weight = 3000000},
		{itemTemplate = "taanab_kessics_scourge", weight = 2000000},
		{itemTemplate = "taanab_battle_of_taanab_painting", weight = 2500000},
		{itemTemplate = "taanab_norulac_war_banner", weight = 2500000},
	}
}

addLootGroupTemplate("taanab_norulac_loot", taanab_norulac_loot)
