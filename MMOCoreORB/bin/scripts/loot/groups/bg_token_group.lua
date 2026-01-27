bg_token_group = {
    description = "BG Token Group",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        {itemTemplate = "bg_token", weight = 9000000}, -- 90%
        {itemTemplate = "holocron_of_destiny", weight = 1000000}-- 10%
    }
}
addLootGroupTemplate("bg_token_group", bg_token_group)
