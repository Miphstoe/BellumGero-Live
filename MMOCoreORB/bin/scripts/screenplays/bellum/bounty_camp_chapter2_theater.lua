-- Chapter 2: harder camp (extra associate). Still no green/red shrines.
-- Future: optional green power_shrine.iff objects + destroy hooks (see MellichaeOutroTheater).

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyCampChapter2Theater = GoToTheater:new {
	taskName = "BellumBountyCampChapter2Theater",
	minimumDistance = 1700,
	maximumDistance = 3400,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Spynet bounty camp (Chapter 2)",
	markIndex = 1,
	markLevel = 47,
	henchLevel = 39,
	markDisplayName = "Marked Smuggler",
	henchDisplayName = "Syndicate Thief",
	bountyHenchCreditMin = 500,
	bountyHenchCreditMax = 1100,
	bountyMarkCreditMin = 10000,
	bountyMarkCreditMax = 15000,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 30, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 30, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 30, referencePoint = 0 },
	},
	activeAreaRadius = 58,
	flattenLayer = true,
}

function BellumBountyCampChapter2Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then
		return
	end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyCampChapter2Theater:onTheaterCreated(pPlayer)
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

function BellumBountyCampChapter2Theater:onEnteredActiveArea(pPlayer, spawnedList)
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

function BellumBountyCampChapter2Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyCampChapter2Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyCampChapter2Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		MandoWayOfLife:completePrivateContract(pOwner)
	end
end

return BellumBountyCampChapter2Theater
