-- Tier 1: modest decorations only. Premium loot waits for the Tier 5 finale.
mando_daily_bounty_tier1_loot = {
	description = "", minimumLevel = 0, maximumLevel = 0,
	lootItems = {
		{itemTemplate = "art_sm_s1", weight = 2500000},
		{itemTemplate = "art_sm_s2", weight = 2500000},
		{itemTemplate = "art_sm_s3", weight = 2500000},
		{itemTemplate = "art_sm_s4", weight = 2500000},
	}
}
addLootGroupTemplate("mando_daily_bounty_tier1_loot", mando_daily_bounty_tier1_loot)
