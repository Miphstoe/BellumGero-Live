-- Bellum Daily Bounty Camp - Tier 3
-- 1 mark, 4 henchmen, higher levels

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyDailyTier3Theater = GoToTheater:new {
	taskName = "BellumBountyDailyTier3Theater",
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Daily Bounty Camp (Tier 3)",
	markIndex = 1,
	markLevel = 55,
	henchLevel = 46,
	markDisplayName = "Wanted Outlaw",
	henchDisplayName = "Outlaw Henchman",
	bountyHenchCreditMin = 700,
	bountyHenchCreditMax = 1400,
	bountyMarkCreditMin = 12000,
	bountyMarkCreditMax = 18000,
	lootGroup = "mando_daily_bounty_tier3_loot",
	lootLevel = 55,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyDailyTier3Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then return end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyDailyTier3Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier3: theater created"))
end

function BellumBountyDailyTier3Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier3: entered active area"))
end

function BellumBountyDailyTier3Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyDailyTier3Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyDailyTier3Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		CreatureObject(pOwner):sendSystemMessage("[Mandalorian Daily Bounty] Tier 3 complete. Return to your fob for the next mission.")
	end
end

return BellumBountyDailyTier3Theater
