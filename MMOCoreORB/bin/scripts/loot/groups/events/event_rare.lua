-- Sub-group: event_rare
-- All rare-tier event rewards. Equal weight per item; tier chance is
-- controlled by event.lua (event_rare = 1,200,000 / 10,000,000 = 12%).

event_rare = {
    description  = "Event rare rewards",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "potted_plants_sml_s02_schematic", weight = 1000000 },
        { itemTemplate = "sea_removal_tool",                weight = 1000000 },
        { itemTemplate = "bestine_quest_imp_banner",        weight = 1000000 },
        { itemTemplate = "rebel_banner",                    weight = 1000000 },
        { itemTemplate = "force_color_crystal_special",     weight = 1000000 },
        { itemTemplate = "clonetrooper_armor_schematics",   weight = 1000000 },
        { itemTemplate = "blasterfist_schematic",           weight = 1000000 },
        { itemTemplate = "bounty_hunter_armor_schematics",  weight = 1000000 },
        { itemTemplate = "nightsister_clothing_schematics", weight = 1000000 },
        { itemTemplate = "bestine_quest_painting",          weight = 1000000 },
    }
}

addLootGroupTemplate("event_rare", event_rare)
