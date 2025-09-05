sea_removal_tool_group = {
    description = "Dev test: always drops the SEA Removal Tool",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "sea_removal_tool", weight = 10000000 } -- 100% in practice
    }
}
addLootGroupTemplate("sea_removal_tool_group", sea_removal_tool_group)
