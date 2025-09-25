-- Group: event (equal-chance pool)
event = {
  description  = "Equal-chance event rewards",
  minimumLevel = 0,
  maximumLevel = 0,
  lootItems = {
  -- Commons (24) -> 16 @ 401,042, 8 @ 401,041
  { itemTemplate = "attachment_armor",                weight = 401042 },
  { itemTemplate = "attachment_clothing",             weight = 401042 },
  { itemTemplate = "be_poster",                       weight = 401042 },
  { itemTemplate = "defensive_stance_poster",         weight = 401042 },
  { itemTemplate = "freedom_painting",                weight = 401042 },
  { itemTemplate = "painting_bw_stormtrooper",        weight = 401042 },
  { itemTemplate = "painting_fighter_pilot_human_01", weight = 401042 },
  { itemTemplate = "painting_han_wanted",             weight = 401042 },
  { itemTemplate = "painting_leia_wanted",            weight = 401042 },
  { itemTemplate = "painting_luke_wanted",            weight = 401042 },
  { itemTemplate = "painting_nebula_flower",          weight = 401042 },
  { itemTemplate = "painting_schematic_transport_ship", weight = 401042 },
  { itemTemplate = "painting_tato_s04",               weight = 401042 },
  { itemTemplate = "painting_trandoshan_wanted",      weight = 401042 },
  { itemTemplate = "painting_vader_victory",          weight = 401042 },
  { itemTemplate = "painting_zabrak_m",               weight = 401042 },

  { itemTemplate = "party_poster",                    weight = 401041 },
  { itemTemplate = "RIS_diagram",                     weight = 401041 },
  { itemTemplate = "spitting_rawl_poster",            weight = 401041 },
  { itemTemplate = "valley_view_painting",            weight = 401041 },
  { itemTemplate = "bestine_history_quest_painting",         weight = 401041 },
  { itemTemplate = "color_crystals",                  weight = 401041 },
  { itemTemplate = "power_crystals",                  weight = 401041 },
  { itemTemplate = "krayt_pearls",                    weight = 401041 },

  -- Rares (5) @ 50,000 each
  { itemTemplate = "potted_plants_sml_s02_schematic", weight = 50000 },   -- RARE
  { itemTemplate = "sea_removal_tool",                weight = 50000 },   -- RARE
  { itemTemplate = "bestine_quest_imp_banner",        weight = 50000 },   -- RARE
  { itemTemplate = "rebel_banner",                    weight = 50000 },   -- RARE
  { itemTemplate = "force_color_crystal_special",     weight = 50000 },   -- RARE

  -- Epics (5) @ 25,000 each
  { itemTemplate = "clonetrooper_armor_schematics",   weight = 25000 },   -- EPIC
  { itemTemplate = "blasterfist_schematic",           weight = 25000 },   -- EPIC
  { itemTemplate = "bounty_hunter_armor_schematics",  weight = 25000 },   -- EPIC
  { itemTemplate = "nightsister_clothing_schematics",    weight = 25000 },   -- EPIC
  { itemTemplate = "bestine_quest_painting",   weight = 25000 },   -- EPIC
}
}
addLootGroupTemplate("event", event)
