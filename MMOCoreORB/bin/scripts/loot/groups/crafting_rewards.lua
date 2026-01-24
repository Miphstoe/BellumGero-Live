-- Crafting Rewards Loot Group
-- Rewards given to crafters when they assemble items
-- Used by CreateObjectTask when createItem=true (non-practice mode)

crafting_rewards = {
	description = "Rewards for crafting items",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		-- 100% drop rate for Holocron of Destiny (for testing)
		-- Total weight: 10000000 = 100%
		{itemTemplate = "holocron_of_destiny", weight = 10000000}
	}
}

addLootGroupTemplate("crafting_rewards", crafting_rewards)
