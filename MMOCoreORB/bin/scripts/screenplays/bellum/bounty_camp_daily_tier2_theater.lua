-- Bellum Daily Bounty Camp - Tier 2
-- 1 mark, 3 henchmen, medium levels

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyDailyTier2Theater = GoToTheater:new {
	taskName = "BellumBountyDailyTier2Theater",
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Daily Bounty Camp (Tier 2)",
	markIndex = 1,
	markLevel = 50,
	henchLevel = 42,
	markDisplayName = "Wanted Outlaw",
	henchDisplayName = "Outlaw Henchman",
	bountyHenchCreditMin = 600,
	bountyHenchCreditMax = 1200,
	bountyMarkCreditMin = 10000,
	bountyMarkCreditMax = 15000,
	lootGroup = "mando_daily_bounty_tier2_loot",
	lootLevel = 50,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyDailyTier2Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then return end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyDailyTier2Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier2: theater created"))
end

function BellumBountyDailyTier2Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier2: entered active area"))
end

function BellumBountyDailyTier2Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyDailyTier2Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyDailyTier2Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Tier 2 complete. Return to your fob for the next mission.")
	end
end

return BellumBountyDailyTier2Theater
