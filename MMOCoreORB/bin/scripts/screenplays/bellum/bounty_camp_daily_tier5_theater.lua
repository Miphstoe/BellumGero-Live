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
	markLevel = 100,
	henchLevel = 54,
	markDisplayName = "IG-88 Assassin Droid",
	henchDisplayName = "Outlaw Henchman",
	bountyHenchCreditMin = 1000,
	bountyHenchCreditMax = 2000,
	bountyMarkCreditMin = 20000,
	bountyMarkCreditMax = 30000,
	lootGroup = "mando_daily_bounty_tier5_loot",
	lootLevel = 65,
	mobileList = {
		{ template = "ig_88", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
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
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier5: theater created"))
end

function BellumBountyDailyTier5Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logDiag == nil) then return end
	self:logDiagPlayer(pPlayer, string.format("Daily Bounty Tier5: entered active area"))
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
	end
end

return BellumBountyDailyTier5Theater
