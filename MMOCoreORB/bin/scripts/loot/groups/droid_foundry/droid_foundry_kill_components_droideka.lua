-- Droid Foundry on-kill premium component pool for Droideka-family droids.

droid_foundry_kill_components_droideka = {
	description = "Foundry Droideka premium parts",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_combat_module", weight = 3571429},
		{itemTemplate = "foundry_armor_module", weight = 2857142},
		{itemTemplate = "foundry_droideka_chassis", weight = 3571429},
	}
}

addLootGroupTemplate("droid_foundry_kill_components_droideka", droid_foundry_kill_components_droideka)
