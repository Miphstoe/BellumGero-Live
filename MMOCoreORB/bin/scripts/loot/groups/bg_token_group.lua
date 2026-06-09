bg_token_group = {
    description = "BG Token Group",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        {itemTemplate = "bg_token", weight = 8000000}, -- 80%
        {itemTemplate = "holocron_of_destiny", weight = 1000000}, -- 10%
        {itemTemplate = "droid_head", weight = 1000000} -- 10%
    }
}
addLootGroupTemplate("bg_token_group", bg_token_group)
