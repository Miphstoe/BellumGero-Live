treasure_map_group = {
	description = "",
	minimumLevel = 50,
	maximumLevel = 250,
	lootItems = {
		{itemTemplate = "junk",                      weight = 3500000}, 

		{itemTemplate = "armor_attachments",         weight = 800000},  
		{itemTemplate = "clothing_attachments",      weight = 800000},  
		{itemTemplate = "color_crystals",            weight = 800000},  
		{itemTemplate = "house_deeds",               weight = 500000},  

		{itemTemplate = "chemistry_component_advanced", weight = 700000}, 
		{itemTemplate = "weapon_component_advanced",    weight = 700000}, 
		{itemTemplate = "loot_kit_parts",            weight = 700000},  

		{itemTemplate = "damage_type_powerups",      weight = 900000},
		{itemTemplate = "sea_removal_tool_1x",      weight = 500000},  
		{itemTemplate = "bg_token",                  weight = 100000},  
	}
}

addLootGroupTemplate("treasure_map_group", treasure_map_group)
