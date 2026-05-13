-- Group: vet_holo_group
-- All 14 veteran-reward holograms with equal drop chance.
-- 10 items × 714,286 + 4 items × 714,285 = 10,000,000 total.

vet_holo_group = {
    description  = "Veteran reward holograms",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        { itemTemplate = "frn_vet_holo_corvette",            weight = 714286 },
        { itemTemplate = "frn_vet_holo_darth_vader",         weight = 714286 },
        { itemTemplate = "frn_vet_holo_deathstar",           weight = 714286 },
        { itemTemplate = "frn_vet_holo_imperial_guard",      weight = 714286 },
        { itemTemplate = "frn_vet_holo_jawa",                weight = 714285 },
        { itemTemplate = "frn_vet_holo_lambda",              weight = 714285 },
        { itemTemplate = "frn_vet_holo_leia",                weight = 714285 },
        { itemTemplate = "frn_vet_holo_luke_skywalker",      weight = 714285 },
        { itemTemplate = "frn_vet_holo_sandcrawler",         weight = 714286 },
        { itemTemplate = "frn_vet_holo_starfighter",         weight = 714286 },
        { itemTemplate = "frn_vet_holo_yoda",                weight = 714286 },
        { itemTemplate = "hologram_aotc_cybernetic_arm",     weight = 714286 },
        { itemTemplate = "hologram_ff_space_battle_2010",    weight = 714286 },
        { itemTemplate = "hologram_hk47",                    weight = 714286 },
    }
}

addLootGroupTemplate("vet_holo_group", vet_holo_group)
