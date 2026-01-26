-- Group: event (tiered: Epic/Rare/Common)
event = {
  description  = "Event rewards with epic/rare/common tiers",
  minimumLevel = 0,
  maximumLevel = 0,
  lootItems = {
    -- ===================== Commons (24) =====================
    -- 16 at 394,792:
{ itemTemplate = "attachment_armor",                weight = 377084 },
{ itemTemplate = "attachment_clothing",             weight = 377084 },
{ itemTemplate = "be_poster",                       weight = 377084 },
{ itemTemplate = "defensive_stance_poster",         weight = 377084 },
{ itemTemplate = "freedom_painting",                weight = 377084 },
{ itemTemplate = "painting_bw_stormtrooper",        weight = 377084 },
{ itemTemplate = "painting_fighter_pilot_human_01", weight = 377084 },
{ itemTemplate = "painting_han_wanted",             weight = 377084 },
{ itemTemplate = "painting_leia_wanted",            weight = 377084 },
{ itemTemplate = "painting_luke_wanted",            weight = 377084 },
{ itemTemplate = "painting_nebula_flower",          weight = 377084 },
{ itemTemplate = "painting_schematic_transport_ship", weight = 377084 },
{ itemTemplate = "painting_tato_s04",               weight = 377084 },
{ itemTemplate = "painting_trandoshan_wanted",      weight = 377084 },
{ itemTemplate = "painting_vader_victory",          weight = 377084 },
{ itemTemplate = "painting_zabrak_m",               weight = 377084 },

{ itemTemplate = "party_poster",                    weight = 335184 },
{ itemTemplate = "RIS_diagram",                     weight = 335184 },
{ itemTemplate = "spitting_rawl_poster",            weight = 335184 },
{ itemTemplate = "valley_view_painting",            weight = 335184 },
{ itemTemplate = "bestine_history_quest_painting",  weight = 335184 },
{ itemTemplate = "color_crystals",                  weight = 335184 },
{ itemTemplate = "power_crystals",                  weight = 335184 },
{ itemTemplate = "krayt_pearls",                    weight = 335184 },
{ itemTemplate = "bg_token_group",                  weight = 335184 },

-- ===================== Rares (10) @ 85,000 =====================
{ itemTemplate = "potted_plants_sml_s02_schematic", weight = 85000 },  -- RARE
{ itemTemplate = "sea_removal_tool",                weight = 85000 },  -- RARE
{ itemTemplate = "bestine_quest_imp_banner",        weight = 85000 },  -- RARE
{ itemTemplate = "rebel_banner",                    weight = 85000 },  -- RARE
{ itemTemplate = "force_color_crystal_special",     weight = 85000 },  -- RARE
{ itemTemplate = "clonetrooper_armor_schematics",   weight = 85000 },  -- RARE (moved)
{ itemTemplate = "blasterfist_schematic",           weight = 85000 },  -- RARE (moved)
{ itemTemplate = "bounty_hunter_armor_schematics",  weight = 85000 },  -- RARE (moved)
{ itemTemplate = "nightsister_clothing_schematics", weight = 85000 },  -- RARE (moved)
{ itemTemplate = "bestine_quest_painting",          weight = 85000 },  -- RARE (moved)

-- ===================== Epic (2) @ 50,000 =====================
{ itemTemplate = "house_deeds",                     weight = 50000 }, -- EPIC
{ itemTemplate = "scrolling_screen",                weight = 50000 }, -- EPIC
  }
}

addLootGroupTemplate("event", event)