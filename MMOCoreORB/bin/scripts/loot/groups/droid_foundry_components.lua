droid_foundry_components = {
	description = "Droid Foundry variable-quality combat components",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_combat_module", weight = 3500000},
		{itemTemplate = "foundry_armor_module", weight = 2000000},
		{itemTemplate = "foundry_probot_chassis", weight = 562500},
		{itemTemplate = "foundry_r2_chassis", weight = 562500},
		{itemTemplate = "foundry_r3_chassis", weight = 562500},
		{itemTemplate = "foundry_r4_chassis", weight = 562500},
		{itemTemplate = "foundry_le_repair_chassis", weight = 562500},
		{itemTemplate = "foundry_battle_droid_chassis", weight = 562500},
		{itemTemplate = "foundry_super_battle_droid_chassis", weight = 562500},
		{itemTemplate = "foundry_droideka_chassis", weight = 562500},
	}
}
addLootGroupTemplate("droid_foundry_components", droid_foundry_components)
