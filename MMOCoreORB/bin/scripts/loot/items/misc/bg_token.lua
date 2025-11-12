-- Bellum Gero Token (loot item entry)
-- Swap `directObjectTemplate` to any existing client template you like.
-- Examples you might have: "object/tangible/loot/misc/collector_token.iff"
-- If unsure, temporarily use something generic like a datapad or coin-looking loot.

bg_token = {
    minimumLevel = 0,
    maximumLevel = -1,
    customObjectName = "Bellum Gero Token",
    directObjectTemplate = "object/tangible/component/clothing/jewelry_setting.iff",
    craftingValues = {},
    customizationStringName = {},
    customizationValues = {}
}

addLootItemTemplate("bg_token", bg_token)
