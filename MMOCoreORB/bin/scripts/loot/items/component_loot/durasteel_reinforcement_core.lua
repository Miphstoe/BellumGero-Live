-- Durasteel Reinforcement Core (Acklay-tier reinforcement component)

durasteel_reinforcement_core = {
    minimumLevel = 50,
    maximumLevel = -1,
    customObjectName = "@craft_weapon_ingredients_n:durasteel_reinforcement_core",
    directObjectTemplate = "object/tangible/component/weapon/durasteel_reinforcement_core.iff",
    craftingValues = {
        {"mindamage",65,130,0},
        {"maxdamage",65,130,0},
        {"useCount",1,13,0},
    },
    customizationStringNames = {},
    customizationValues = {}
}

addLootItemTemplate("durasteel_reinforcement_core", durasteel_reinforcement_core)
