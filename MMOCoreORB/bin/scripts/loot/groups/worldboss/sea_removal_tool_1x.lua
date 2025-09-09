-- sea_removal_tool_1x.lua
-- A one-item loot group that always rolls the SEA Removal Tool
sea_removal_tool_1x = {
    description  = "Single SEA Removal Tool group",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems    = {
        { itemTemplate = "sea_removal_tool", weight = 10000000 }
    }
}
addLootGroupTemplate("sea_removal_tool_1x", sea_removal_tool_1x)

-- (optional debug)
print("[LOOT] loaded group sea_removal_tool_1x")
