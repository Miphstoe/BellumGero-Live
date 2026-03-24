-- Group: vet_holo_group
-- All 11 veteran-reward holograms with equal drop chance.
-- 11 items × 909,090 = 9,999,990 + 10 on yoda = 10,000,000 total.

vet_holo_group = {
    description  = "Veteran reward holograms",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "frn_vet_holo_corvette",       weight = 909090 },
        { itemTemplate = "frn_vet_holo_darth_vader",    weight = 909090 },
        { itemTemplate = "frn_vet_holo_deathstar",      weight = 909090 },
        { itemTemplate = "frn_vet_holo_imperial_guard", weight = 909090 },
        { itemTemplate = "frn_vet_holo_jawa",           weight = 909090 },
        { itemTemplate = "frn_vet_holo_lambda",         weight = 909090 },
        { itemTemplate = "frn_vet_holo_leia",           weight = 909090 },
        { itemTemplate = "frn_vet_holo_luke_skywalker", weight = 909090 },
        { itemTemplate = "frn_vet_holo_sandcrawler",    weight = 909090 },
        { itemTemplate = "frn_vet_holo_starfighter",    weight = 909090 },
        { itemTemplate = "frn_vet_holo_yoda",           weight = 909100 },
    }
}

addLootGroupTemplate("vet_holo_group", vet_holo_group)
