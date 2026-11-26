-- Taanab boss loot. Weights total 10,000,000. The Taanab paintings are their own group (taanab_art).
taanab_norulac_loot = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "taanab_norulac_captains_coat", weight = 4000000},
		{itemTemplate = "taanab_kessics_scourge", weight = 2500000},
		{itemTemplate = "taanab_norulac_war_banner", weight = 3500000},
	}
}

addLootGroupTemplate("taanab_norulac_loot", taanab_norulac_loot)
