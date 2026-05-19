-- Bellum Spynet — bounty camp encounter (Mellichae-style GoToTheater, simplified).
-- Chapter 1: no green/red power shrines, no healing pulses. Credits only (scripted on kill).
-- Start from another screenplay: BellumBountyCampChapter1Theater:start(pPlayer)

local BountyCamp = require("screenplays.bellum.bounty_camp_theater_helpers")

BellumBountyCampChapter1Theater = GoToTheater:new {
	taskName = "BellumBountyCampChapter1Theater",
	-- Wide ring from the player at trial accept: keeps camps out of city cores / no-spawn shells (Corellia, etc.).
	minimumDistance = 1600,
	maximumDistance = 2200,
	theater = BountyCamp.CAMP_DECOR,
	waypointDescription = "Spynet bounty camp (Chapter 1)",
	markIndex = 1,
	markLevel = 42,
	henchLevel = 34,
	markDisplayName = "Wanted Outlaw",
	henchDisplayName = "Outlaw Thief",
	bountyHenchCreditMin = 350,
	bountyHenchCreditMax = 750,
	bountyMarkCreditMin = 6500,
	bountyMarkCreditMax = 9500,
	mobileList = {
		{ template = "bellum_bounty_mark", minimumDistance = 3, maximumDistance = 6, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
		{ template = "bellum_bounty_henchman", minimumDistance = 8, maximumDistance = 28, referencePoint = 0 },
	},
	activeAreaRadius = 56,
	flattenLayer = true,
}

function BellumBountyCampChapter1Theater:onObjectsSpawned(pPlayer, spawnedList)
	if (pPlayer == nil) then
		return
	end
	BountyCamp.applyBountyMobPresentation(self, pPlayer, spawnedList, self.markIndex or 1)
	BountyCamp.setupKillObservers(self, pPlayer, spawnedList, self.markIndex or 1)
end

function BellumBountyCampChapter1Theater:onTheaterCreated(pPlayer)
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

function BellumBountyCampChapter1Theater:onEnteredActiveArea(pPlayer, spawnedList)
	if (pPlayer == nil or MandoWayOfLife == nil or MandoWayOfLife.logSpynetDebug == nil) then
		return
	end
	local n = 0
	if (spawnedList ~= nil) then
		n = #spawnedList
	end
	MandoWayOfLife:logSpynetDebug(pPlayer, string.format(
		"BountyCamp %s onEnteredActiveArea listSlots=%s (enter camp radius; props/mobs should spawn)",
		tostring(self.taskName),
		tostring(n)
	))
end

function BellumBountyCampChapter1Theater:notifyBountyMobileKilled(pVictim, pAttacker)
	return BountyCamp.notifyBountyMobileKilled(self, pVictim, pAttacker)
end

function BellumBountyCampChapter1Theater:onTheaterDespawn(pPlayer)
	BountyCamp.clearCampFlags(self, pPlayer)
end

function BellumBountyCampChapter1Theater:onSpynetMarkDown(pOwner)
	if (pOwner ~= nil and MandoWayOfLife ~= nil) then
		MandoWayOfLife:completePrivateContract(pOwner)
	end
end

return BellumBountyCampChapter1Theater
