-- Loot item for Subspace Container Expansion Module
-- Always drops with exactly 10 uses (like a fixed "stack" of 10)

container_expansion_module = {
    minimumLevel = 0,
    maximumLevel = -1,
    customObjectName = "",
    directObjectTemplate = "object/tangible/component/structure/container_expansion_module.iff",
    craftingValues = {
        -- Only care about number of uses; no other stats needed
        {"useCount",11,11,0},
    },
    customizationStringName = {},
    customizationValues = {}
}

addLootItemTemplate("container_expansion_module", container_expansion_module)
