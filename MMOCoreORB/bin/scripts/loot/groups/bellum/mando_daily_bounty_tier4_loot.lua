-- Tier 4: better decorations, but no schematics, quest trophies, or premium parts.
mando_daily_bounty_tier4_loot = {
	description = "", minimumLevel = 0, maximumLevel = 0,
	lootItems = {
		{itemTemplate = "art_sm_s1",             weight = 1000000},
		{itemTemplate = "art_sm_s2",             weight = 1000000},
		{itemTemplate = "art_sm_s3",             weight = 1000000},
		{itemTemplate = "art_sm_s4",             weight = 1000000},
		{itemTemplate = "art_lg_s1",             weight = 1250000},
		{itemTemplate = "art_lg_s2",             weight = 1250000},
		{itemTemplate = "dwb_viewscreen_s1",     weight = 1250000},
		{itemTemplate = "dwb_viewscreen_s2",     weight = 1250000},
		{itemTemplate = "mando_hunter_portrait", weight = 1000000},
	}
}
addLootGroupTemplate("mando_daily_bounty_tier4_loot", mando_daily_bounty_tier4_loot)
