-- Slicer's Contraband Cache
-- One item is selected when a locked container is successfully sliced.
-- Total weight: 10,000,000

looted_container = {
	description = "Slicer's Contraband Cache",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- Stolen equipment: 30%
		{groupTemplate = "weapons_all", weight = 1500000},
		{groupTemplate = "armor_all", weight = 1000000},
		{groupTemplate = "wearables_rare", weight = 500000},

		-- Illegal modifications: 16%
		{groupTemplate = "armor_attachments", weight = 800000},
		{groupTemplate = "clothing_attachments", weight = 800000},

		-- Smuggled crafting technology: 32%
		{groupTemplate = "crafting_component_advanced", weight = 1200000},
		{groupTemplate = "component_enhancement", weight = 800000},
		{groupTemplate = "damage_type_powerups", weight = 700000},
		{groupTemplate = "tailor_components", weight = 500000},

		-- Collector finds: 13%
		{groupTemplate = "furniture_container_schematics", weight = 800000},
		{groupTemplate = "loot_kit_parts", weight = 500000},

		-- Force-related contraband: 6%
		{groupTemplate = "color_crystals", weight = 400000},
		{groupTemplate = "power_crystals", weight = 200000},

		-- Jackpot rewards: 2%
		{groupTemplate = "endgame_weapon_schematics", weight = 100000},
		{itemTemplate = "jedi_holocron_dark", weight = 50000},
		{itemTemplate = "jedi_holocron_light", weight = 50000},

		-- Another encrypted cache: 1%
		{itemTemplate = "locked_container", weight = 100000}
	}
}

addLootGroupTemplate("looted_container", looted_container)
