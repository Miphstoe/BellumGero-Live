-- Droid Foundry on-kill premium component pool for B2-family droids.

droid_foundry_kill_components_b2 = {
	description = "Foundry B2 premium parts",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_combat_module", weight = 3571429},
		{itemTemplate = "foundry_armor_module", weight = 2857142},
		{itemTemplate = "foundry_super_battle_droid_chassis", weight = 3571429},
	}
}

addLootGroupTemplate("droid_foundry_kill_components_b2", droid_foundry_kill_components_b2)
