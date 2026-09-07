-- Droid Foundry on-kill premium component pool for B1-family droids.

droid_foundry_kill_components_b1 = {
	description = "Foundry B1 premium parts",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_combat_module", weight = 3571429},
		{itemTemplate = "foundry_armor_module", weight = 2857142},
		{itemTemplate = "foundry_battle_droid_chassis", weight = 3571429},
	}
}

addLootGroupTemplate("droid_foundry_kill_components_b1", droid_foundry_kill_components_b1)
