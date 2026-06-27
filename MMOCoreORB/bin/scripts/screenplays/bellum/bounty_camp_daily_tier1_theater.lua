-- Bellum Daily Bounty Camp - Tier 1 (Easiest)
-- 1 mark, 2 henchmen, lower levels

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyDailyTier1Theater = GoToTheater:new {
	taskName = "BellumBountyDailyTier1Theater",
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Daily Bounty Camp (Tier 1)",
	markIndex = 1,
	markLevel = 45,
	henchLevel = 38,
	markDisplayName = "Wanted Outlaw",
	henchDisplayName = "Outlaw Henchman",
	bountyHenchCreditMin = 500,
	bountyHenchCreditMax = 1000,
	bountyMarkCreditMin = 8000,
	bountyMarkCreditMax = 12000,
	lootGroup = "mando_daily_bounty_tier1_loot",
	lootLevel = 45,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyDailyTier1Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then return end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyDailyTier1Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier1: theater created"))
end

function BellumBountyDailyTier1Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier1: entered active area"))
end

function BellumBountyDailyTier1Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyDailyTier1Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyDailyTier1Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Tier 1 complete. Return to your fob for the next mission.")
	end
end

return BellumBountyDailyTier1Theater
