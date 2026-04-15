-- Chapter 3: strongest mark + four associates. No shrines yet.
-- Future: add object/tangible/jedi/power_shrine.iff (green) and power_shrine_red.iff to .theater
-- plus Mellichae-style setupPowerShrines / doHealingPulse if you want crystals that heal the mark.

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyCampChapter3Theater = GoToTheater:new {
	taskName = "BellumBountyCampChapter3Theater",
	minimumDistance = 1800,
	maximumDistance = 3600,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Spynet bounty camp (Chapter 3)",
	markIndex = 1,
	markLevel = 52,
	henchLevel = 44,
	markDisplayName = "High-Value Thief",
	henchDisplayName = "Cartel Enforcer",
	bountyHenchCreditMin = 650,
	bountyHenchCreditMax = 1400,
	bountyMarkCreditMin = 15000,
	bountyMarkCreditMax = 22000,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 32, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 32, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 32, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 32, referencePoint = 0 },
	},
	activeAreaRadius = 60,
	flattenLayer = true,
}

function BellumBountyCampChapter3Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then
		return
	end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyCampChapter3Theater:onTheaterCreated(pPlayer)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logSpynetDebug == nil) then
		return
	end
	local pTh = self:getTheaterObject(pPlayer)
	if (pTh ~= nil) then
		MandoWayOfLife:logSpynetDebug(pPlayer, string.format(
			"BountyCamp %s onTheaterCreated theaterOid=%s world=(%.1f,%.1f,%.1f) zone=%s minDist=%s maxDist=%s activeRadius=%s",
			tostring(self.taskName),
			tostring(SceneObject(pTh):getObjectID()),
			SceneObject(pTh):getWorldPositionX(),
			SceneObject(pTh):getWorldPositionZ(),
			SceneObject(pTh):getWorldPositionY(),
			tostring(SceneObject(pTh):getZoneName()),
			tostring(self.minimumDistance),
			tostring(self.maximumDistance),
			tostring(self.activeAreaRadius)
		))
	else
		MandoWayOfLife:logSpynetDebug(pPlayer, string.format("BountyCamp %s onTheaterCreated: theater object nil", tostring(self.taskName)))
	end
end

function BellumBountyCampChapter3Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logSpynetDebug == nil) then
		return
	end
	local n = (spawnedList ~= nil) and #spawnedList or 0
	MandoWayOfLife:logSpynetDebug(pPlayer, string.format(
		"BountyCamp %s onEnteredActiveArea listSlots=%s",
		tostring(self.taskName),
		tostring(n)
	))
end

function BellumBountyCampChapter3Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyCampChapter3Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyCampChapter3Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		MandoWayOfLife:completePrivateContract(pOwner)
	end
end

return BellumBountyCampChapter3Theater
