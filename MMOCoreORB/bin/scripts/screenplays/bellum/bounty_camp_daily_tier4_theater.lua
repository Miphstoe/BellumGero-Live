-- Bellum Daily Bounty Camp - Tier 4
-- 1 mark, 5 henchmen, high levels

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyDailyTier4Theater = GoToTheater:new {
	taskName = "BellumBountyDailyTier4Theater",
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Daily Bounty Camp (Tier 4)",
	markIndex = 1,
	markLevel = 60,
	henchLevel = 50,
	markDisplayName = "Wanted Outlaw",
	henchDisplayName = "Outlaw Henchman",
	bountyHenchCreditMin = 800,
	bountyHenchCreditMax = 1600,
	bountyMarkCreditMin = 15000,
	bountyMarkCreditMax = 22000,
	lootGroup = "mando_daily_bounty_tier4_loot",
	lootLevel = 60,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyDailyTier4Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then return end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyDailyTier4Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier4: theater created"))
end

function BellumBountyDailyTier4Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier4: entered active area"))
end

function BellumBountyDailyTier4Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyDailyTier4Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyDailyTier4Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Tier 4 complete. Return to your fob for the final mission.")
	end
end

return BellumBountyDailyTier4Theater
