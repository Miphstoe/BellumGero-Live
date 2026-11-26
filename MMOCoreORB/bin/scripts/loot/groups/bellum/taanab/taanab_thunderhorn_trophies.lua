-- Taanab boss loot. Weights total 10,000,000.
taanab_thunderhorn_trophies = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "taanab_thunderhorn_hide_rug", weight = 4000000},
		{itemTemplate = "taanab_thunderhorn_skull", weight = 3000000},
		{itemTemplate = "taanab_thunderhorn_plush", weight = 3000000},
	}
}

addLootGroupTemplate("taanab_thunderhorn_trophies", taanab_thunderhorn_trophies)
