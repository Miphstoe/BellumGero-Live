-- Group: event
-- Top-level event loot group. Selects a tier first, then picks one item
-- uniformly at random from that tier's sub-group.
--
--   Tier        Sub-group       Weight    Approx. chance
--   ----------  --------------  --------  ---------------
--   Common      event_common    6,500,000       65 %
--   Hologram    vet_holo_group  2,000,000       20 %
--   Rare        event_rare      1,200,000       12 %
--   Epic        event_epic        300,000        3 %
--               Total          10,000,000      100 %
--
-- To add items: edit the matching sub-group file.
-- To re-balance tiers: adjust the weights below (keep total = 10,000,000).

event = {
    description  = "Event rewards (tiered: common / hologram / rare / epic)",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "event_common",   weight = 6500000 },
        { itemTemplate = "vet_holo_group", weight = 2000000 },
        { itemTemplate = "event_rare",     weight = 1200000 },
        { itemTemplate = "event_epic",     weight =  300000 },
    }
}

addLootGroupTemplate("event", event)
