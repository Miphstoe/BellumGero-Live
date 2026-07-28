-- Bellum Daily Bounty Camp - Tier 5 (Hardest)
-- 1 mark, 6 henchmen, highest levels

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyDailyTier5Theater = GoToTheater:new {
	taskName = "BellumBountyDailyTier5Theater",
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Daily Bounty Camp (Tier 5)",
	markIndex = 1,
	bossIndex = 8,
	markLevel = 70,
	henchLevel = 54,
	bossLevel = 100,
	markDisplayName = "Wanted Warlord",
	henchDisplayName = "Outlaw Henchman",
	bossDisplayName = "IG-88 Assassin Droid",
	bountyHenchCreditMin = 1000,
	bountyHenchCreditMax = 2000,
	bountyMarkCreditMin = 20000,
	bountyMarkCreditMax = 30000,
	bountyBossCreditMin = 35000,
	bountyBossCreditMax = 50000,
	lootGroup = "mando_daily_bounty_tier5_loot",
	lootLevel = 65,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		-- Dormant boss (index 8): invulnerable + passive until the mark and
		-- every henchman above are dead, then wakes and attacks (see helpers).
		{ template = "ig_88", minimumDistance = 4, maximumDistance = 7, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyDailyTier5Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then return end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyDailyTier5Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logSpynetDebug == nil) then return end
	MandoWayOfLife:logSpynetDebug(pPlayer, "Daily Bounty Tier5: theater created")
end

function BellumBountyDailyTier5Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logSpynetDebug == nil) then return end
	MandoWayOfLife:logSpynetDebug(pPlayer, "Daily Bounty Tier5: entered active area")
end

function BellumBountyDailyTier5Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyDailyTier5Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyDailyTier5Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] All 5 daily missions complete! Return tomorrow for more. This is the Way.")
		if (MandoDailyHoloStory ~= nil) then
			pcall(function() MandoDailyHoloStory:onCampCompleted(pOwner, 5) end)
		end

		local pInventory = SceneObject(pOwner):getSlottedObject("inventory")
		if (pInventory ~= nil) then
			local itemID = createLoot(pInventory, "mando_daily_bounty_tier5_loot", self.lootLevel, false)
			if (itemID ~= nil and itemID ~= 0) then
				CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Your guild contact awarded you an additional top tier reward.")
			else
				CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Your final reward could not be placed in your inventory. Clear a slot and contact staff.")
			end
		else
			CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Your final reward could not be placed in your inventory. Clear a slot and contact staff.")
		end
	end
end

return BellumBountyDailyTier5Theater
