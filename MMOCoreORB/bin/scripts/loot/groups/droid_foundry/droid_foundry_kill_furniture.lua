-- Droid furniture salvage already used by the Blue Shadow Virus quiz.
-- Each furniture item has its own LootItemTemplate Lua under loot/items/droid_foundry.

droid_foundry_kill_furniture = {
	description = "Droid Foundry furniture salvage",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "foundry_furniture_battle_droid", weight = 2000000},
		{itemTemplate = "foundry_furniture_super_battle_droid", weight = 2000000},
		{itemTemplate = "foundry_furniture_droideka", weight = 2000000},
		{itemTemplate = "foundry_furniture_21b_surgical_droid", weight = 2000000},
		{itemTemplate = "foundry_furniture_ito_droid", weight = 2000000},
	}
}

addLootGroupTemplate("droid_foundry_kill_furniture", droid_foundry_kill_furniture)
