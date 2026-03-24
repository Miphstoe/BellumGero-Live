-- Sub-group: event_common
-- All common-tier event rewards. Equal weight per item; tier chance is
-- controlled by event.lua (event_common = 8,500,000 / 10,000,000 = 85%).

event_common = {
    description  = "Event common rewards",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "attachment_armor",                  weight = 400000 },
        { itemTemplate = "attachment_clothing",               weight = 400000 },
        { itemTemplate = "be_poster",                         weight = 400000 },
        { itemTemplate = "defensive_stance_poster",           weight = 400000 },
        { itemTemplate = "freedom_painting",                  weight = 400000 },
        { itemTemplate = "painting_bw_stormtrooper",          weight = 400000 },
        { itemTemplate = "painting_fighter_pilot_human_01",   weight = 400000 },
        { itemTemplate = "painting_han_wanted",               weight = 400000 },
        { itemTemplate = "painting_leia_wanted",              weight = 400000 },
        { itemTemplate = "painting_luke_wanted",              weight = 400000 },
        { itemTemplate = "painting_nebula_flower",            weight = 400000 },
        { itemTemplate = "painting_schematic_transport_ship", weight = 400000 },
        { itemTemplate = "painting_tato_s04",                 weight = 400000 },
        { itemTemplate = "painting_trandoshan_wanted",        weight = 400000 },
        { itemTemplate = "painting_vader_victory",            weight = 400000 },
        { itemTemplate = "painting_zabrak_m",                 weight = 400000 },
        { itemTemplate = "party_poster",                      weight = 400000 },
        { itemTemplate = "RIS_diagram",                       weight = 400000 },
        { itemTemplate = "spitting_rawl_poster",              weight = 400000 },
        { itemTemplate = "valley_view_painting",              weight = 400000 },
        { itemTemplate = "bestine_history_quest_painting",    weight = 400000 },
        { itemTemplate = "color_crystals",                    weight = 400000 },
        { itemTemplate = "power_crystals",                    weight = 400000 },
        { itemTemplate = "krayt_pearls",                      weight = 400000 },
        { itemTemplate = "bg_token_group",                    weight = 400000 },
    }
}

addLootGroupTemplate("event_common", event_common)
