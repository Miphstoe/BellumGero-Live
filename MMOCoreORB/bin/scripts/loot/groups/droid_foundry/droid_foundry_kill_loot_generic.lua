-- Droid Foundry general corpse loot for Security, Repair, and Overseer droids.
-- No B1/B2/Droideka premium chassis are available from this pool.
-- Total weight = 10,000,000.

droid_foundry_kill_loot_generic = {
	description = "Droid Foundry on-kill loot - generic droids",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{groupTemplate = "armor_attachments", weight = 1500000},
		{groupTemplate = "clothing_attachments", weight = 1500000},
		{groupTemplate = "power_crystals", weight = 1100000},
		{groupTemplate = "color_crystals", weight = 1100000},
		{groupTemplate = "weapon_component_advanced", weight = 2900000},
		{groupTemplate = "bg_token_group", weight = 500000},
		{groupTemplate = "droid_foundry_kill_components_generic", weight = 900000},
		{groupTemplate = "droid_foundry_kill_furniture", weight = 500000},
	}
}

addLootGroupTemplate("droid_foundry_kill_loot_generic", droid_foundry_kill_loot_generic)
