-- Droid Foundry general corpse loot for Droideka-family droids.
-- Premium subpool contains Combat Module, Armor Module, and Droideka chassis only.
-- Total weight = 10,000,000.

droid_foundry_kill_loot_droideka = {
	description = "Droid Foundry on-kill loot - Droideka family",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{groupTemplate = "armor_attachments", weight = 1500000},
		{groupTemplate = "clothing_attachments", weight = 1500000},
		{groupTemplate = "power_crystals", weight = 1100000},
		{groupTemplate = "color_crystals", weight = 1100000},
		{groupTemplate = "weapon_component_advanced", weight = 2400000},
		{groupTemplate = "bg_token_group", weight = 500000},
		{groupTemplate = "droid_foundry_kill_components_droideka", weight = 1400000},
		{groupTemplate = "droid_foundry_kill_furniture", weight = 500000},
	}
}

addLootGroupTemplate("droid_foundry_kill_loot_droideka", droid_foundry_kill_loot_droideka)
