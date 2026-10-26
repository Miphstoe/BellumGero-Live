-- Sub-group: event_epic
-- All epic-tier event rewards. Equal weight per item; tier chance is
-- controlled by event.lua (event_epic = 300,000 / 10,000,000 = 3%).

event_epic = {
    description  = "Event epic rewards",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "house_deeds",     weight = 4500000 },
        { itemTemplate = "scrolling_screen", weight = 3000000 },
         { itemTemplate = "gambling_table_schematic", weight = 2500000 },
    }
}

addLootGroupTemplate("event_epic", event_epic)
