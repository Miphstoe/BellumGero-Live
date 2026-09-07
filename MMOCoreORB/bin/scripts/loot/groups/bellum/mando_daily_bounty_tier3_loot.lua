-- Tier 3: mid-grade decorations only; no schematics or premium crafting loot.
mando_daily_bounty_tier3_loot = {
	description = "", minimumLevel = 0, maximumLevel = 0,
	lootItems = {
		{itemTemplate = "art_sm_s1",         weight = 1250000},
		{itemTemplate = "art_sm_s2",         weight = 1250000},
		{itemTemplate = "art_sm_s3",         weight = 1250000},
		{itemTemplate = "art_sm_s4",         weight = 1250000},
		{itemTemplate = "art_lg_s1",         weight = 1500000},
		{itemTemplate = "art_lg_s2",         weight = 1500000},
		{itemTemplate = "dwb_viewscreen_s1", weight = 1000000},
		{itemTemplate = "dwb_viewscreen_s2", weight = 1000000},
	}
}
addLootGroupTemplate("mando_daily_bounty_tier3_loot", mando_daily_bounty_tier3_loot)
