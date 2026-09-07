-- Droid Foundry on-kill premium component pool for droids without a family chassis.

droid_foundry_kill_components_generic = {
	description = "Foundry Combat and Armor Modules",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_combat_module", weight = 5555556},
		{itemTemplate = "foundry_armor_module", weight = 4444444},
	}
}

addLootGroupTemplate("droid_foundry_kill_components_generic", droid_foundry_kill_components_generic)
