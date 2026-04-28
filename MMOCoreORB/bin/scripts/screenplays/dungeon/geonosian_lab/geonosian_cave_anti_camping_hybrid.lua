GeonosianCaveAntiCampingHybrid = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "GeonosianCaveAntiCampingHybrid",
	planet = "yavin4",

	-- Edit this if the Geonosian Cave building object changes.
	caveBuildingID = 1627780,

	-- Edit this if you want a different removal location outside the cave.
	caveExitPoint = { x = -6404.5, z = 64.3, y = -412.4, cell = 0, planet = "yavin4" },

	-- Edit this to change the total time allowed inside the cave.
	caveTimerDurationMs = 2 * 60 * 60 * 1000,

	-- Edit these to change warning timings.
	warningTimes = {
		{ ms = 10 * 60 * 1000, message = "You have 10 minutes remaining inside the Geonosian Cave." },
		{ ms = 5 * 60 * 1000, message = "You have 5 minutes remaining inside the Geonosian Cave." },
		{ ms = 1 * 60 * 1000, message = "You have 1 minute remaining inside the Geonosian Cave." },
	},

	timerValidationMs = 60 * 1000,

	enhancedGapingSpiderTemplate = "enhanced_gaping_spider",
	enhancedGapingSpiderRespawnSeconds = 2700,
	spiderActivationRadius = 17,

	-- Edit these spawn points to move the randomized Enhanced Gaping Spider locations.
	-- These points are based on the current Geonosian Lab interior cells in geoLab.lua.
	spiderSpawnPoints = {
		{ x = -74.0, z = -18.9, y = -38.0, cell = 1627788 }, -- caveroom1
		{ x = -109.0, z = -22.0, y = -110.0, cell = 1627793 }, -- largecavehall1
		{ x = -130.0, z = -22.1, y = -85.0, cell = 1627794 }, -- largecavehall2
		{ x = 29.5, z = -31.0, y = -85.0, cell = 1627798 }, -- caveroom2
		{ x = -28.0, z = -22.2, y = -156.0, cell = 1627803 }, -- cavecage1
	},
}

registerScreenPlay("GeonosianCaveAntiCampingHybrid", true)

function GeonosianCaveAntiCampingHybrid:start()
	if (not isZoneEnabled(self.planet)) then
		return
	end

	self:setupBuildingObservers()
	self:ensureEnhancedGapingSpiderSpawned()
end

function GeonosianCaveAntiCampingHybrid:getPlayerKey(pPlayer, suffix)
	return SceneObject(pPlayer):getObjectID() .. ":geoCave:" .. suffix
end

function GeonosianCaveAntiCampingHybrid:isPlayerInCave(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	if (SceneObject(pPlayer):getZoneName() ~= self.planet) then
		return false
	end

	local pParent = SceneObject(pPlayer):getParent()

	if (pParent == nil or not SceneObject(pParent):isCellObject()) then
		return false
	end

	local pBuilding = SceneObject(pParent):getParent()

	if (pBuilding == nil) then
		return false
	end

	return SceneObject(pBuilding):getObjectID() == self.caveBuildingID
end

function GeonosianCaveAntiCampingHybrid:setupBuildingObservers()
	local pBuilding = getSceneObject(self.caveBuildingID)

	if (pBuilding == nil) then
		printLuaError("GeonosianCaveAntiCampingHybrid: missing cave building object " .. self.caveBuildingID)
		return
	end

	createObserver(ENTEREDBUILDING, self.screenplayName, "notifyEnteredCave", pBuilding)
	createObserver(EXITEDBUILDING, self.screenplayName, "notifyExitedCave", pBuilding)
end

function GeonosianCaveAntiCampingHybrid:notifyEnteredCave(pBuilding, pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	self:startPlayerTimer(pPlayer)

	return 0
end

function GeonosianCaveAntiCampingHybrid:notifyExitedCave(pBuilding, pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	self:clearPlayerTimer(pPlayer)

	return 0
end

function GeonosianCaveAntiCampingHybrid:startPlayerTimer(pPlayer)
	if (pPlayer == nil or not self:isPlayerInCave(pPlayer)) then
		return
	end

	local tokenKey = self:getPlayerKey(pPlayer, "token")
	local activeKey = self:getPlayerKey(pPlayer, "active")
	local expiresAtKey = self:getPlayerKey(pPlayer, "expiresAt")

	local newToken = readData(tokenKey) + 1

	writeData(tokenKey, newToken)
	writeData(activeKey, 1)
	writeData(expiresAtKey, os.time() + math.floor(self.caveTimerDurationMs / 1000))

	dropObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyPlayerKilled", pPlayer)
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyPlayerKilled", pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("You may remain in the Geonosian Cave for up to 2 hours before being removed.")

	for i = 1, #self.warningTimes, 1 do
		local warning = self.warningTimes[i]
		local delay = self.caveTimerDurationMs - warning.ms

		if (delay > 0) then
			createEvent(delay, self.screenplayName, "handleWarningEvent", pPlayer, newToken .. ":" .. warning.ms)
		end
	end

	createEvent(self.timerValidationMs, self.screenplayName, "validateTimerState", pPlayer, tostring(newToken))
	createEvent(self.caveTimerDurationMs, self.screenplayName, "expirePlayerTimer", pPlayer, tostring(newToken))
end

function GeonosianCaveAntiCampingHybrid:clearPlayerTimer(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	deleteData(self:getPlayerKey(pPlayer, "active"))
	deleteData(self:getPlayerKey(pPlayer, "expiresAt"))

	dropObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyPlayerKilled", pPlayer)
end

function GeonosianCaveAntiCampingHybrid:isTimerTokenActive(pPlayer, token)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	return readData(self:getPlayerKey(pPlayer, "active")) == 1 and readData(self:getPlayerKey(pPlayer, "token")) == tonumber(token)
end

function GeonosianCaveAntiCampingHybrid:handleWarningEvent(pPlayer, args)
	if (pPlayer == nil or args == nil) then
		return 0
	end

	local split = string.find(args, ":")

	if (split == nil) then
		return 0
	end

	local token = tonumber(string.sub(args, 1, split - 1))
	local warningMs = tonumber(string.sub(args, split + 1))

	if (token == nil or warningMs == nil or not self:isTimerTokenActive(pPlayer, token) or not self:isPlayerInCave(pPlayer)) then
		return 0
	end

	for i = 1, #self.warningTimes, 1 do
		local warning = self.warningTimes[i]

		if (warning.ms == warningMs) then
			CreatureObject(pPlayer):sendSystemMessage(warning.message)
			break
		end
	end

	return 0
end

function GeonosianCaveAntiCampingHybrid:validateTimerState(pPlayer, args)
	local token = tonumber(args)

	if (token == nil or not self:isTimerTokenActive(pPlayer, token)) then
		return 0
	end

	if (not self:isPlayerInCave(pPlayer)) then
		self:clearPlayerTimer(pPlayer)
		return 0
	end

	createEvent(self.timerValidationMs, self.screenplayName, "validateTimerState", pPlayer, tostring(token))

	return 0
end

function GeonosianCaveAntiCampingHybrid:expirePlayerTimer(pPlayer, args)
	local token = tonumber(args)

	if (token == nil or not self:isTimerTokenActive(pPlayer, token)) then
		return 0
	end

	if (not self:isPlayerInCave(pPlayer)) then
		self:clearPlayerTimer(pPlayer)
		return 0
	end

	self:clearPlayerTimer(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Your time inside the Geonosian Cave has expired. You are being returned to the cave entrance.")
	self:returnPlayerToEntrance(pPlayer)

	return 0
end

function GeonosianCaveAntiCampingHybrid:notifyPlayerKilled(pPlayer, pKiller)
	if (pPlayer == nil) then
		return 0
	end

	self:clearPlayerTimer(pPlayer)

	return 1
end

function GeonosianCaveAntiCampingHybrid:returnPlayerToEntrance(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	if (SceneObject(pPlayer):getZoneName() ~= self.caveExitPoint.planet) then
		SceneObject(pPlayer):switchZone(self.caveExitPoint.planet, self.caveExitPoint.x, self.caveExitPoint.z, self.caveExitPoint.y, self.caveExitPoint.cell)
	else
		SceneObject(pPlayer):teleport(self.caveExitPoint.x, self.caveExitPoint.z, self.caveExitPoint.y, self.caveExitPoint.cell)
	end
end

function GeonosianCaveAntiCampingHybrid:onPlayerLoggedIn(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local loggedOutInCave = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "loggedOutInCave")) or 0
	writeScreenPlayData(pPlayer, self.screenplayName, "loggedOutInCave", 0)

	-- Only eject if the player was confirmed inside the cave when they logged out.
	-- Checking isPlayerInCave alone can produce false positives during the login
	-- sequence (e.g. for Jedi Enclave players) because the parent chain may not
	-- yet be fully settled when this callback fires.
	if (loggedOutInCave == 1) then
		self:clearPlayerTimer(pPlayer)
		self:returnPlayerToEntrance(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("You were returned to the Geonosian Cave entrance because you logged out inside the cave.")
		return
	end

	self:clearPlayerTimer(pPlayer)
end

function GeonosianCaveAntiCampingHybrid:onPlayerLoggedOut(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	if (self:isPlayerInCave(pPlayer)) then
		writeScreenPlayData(pPlayer, self.screenplayName, "loggedOutInCave", 1)
	else
		writeScreenPlayData(pPlayer, self.screenplayName, "loggedOutInCave", 0)
	end

	self:clearPlayerTimer(pPlayer)
end

function GeonosianCaveAntiCampingHybrid:getSpiderDataKey(suffix)
	return "geoCave:enhancedGapingSpider:" .. suffix
end

function GeonosianCaveAntiCampingHybrid:getRandomSpiderSpawnPoint()
	if (#self.spiderSpawnPoints == 0) then
		return nil
	end

	local index = getRandomNumber(1, #self.spiderSpawnPoints)

	return self.spiderSpawnPoints[index]
end

function GeonosianCaveAntiCampingHybrid:ensureEnhancedGapingSpiderSpawned()
	local spiderOID = readData(self:getSpiderDataKey("oid"))

	if (spiderOID ~= 0 and getSceneObject(spiderOID) ~= nil) then
		return
	end

	self:spawnEnhancedGapingSpider()
end

function GeonosianCaveAntiCampingHybrid:clearSpiderActivationArea()
	local areaOID = readData(self:getSpiderDataKey("activationAreaOid"))

	if (areaOID ~= 0) then
		local pArea = getSceneObject(areaOID)

		if (pArea ~= nil) then
			SceneObject(pArea):destroyObjectFromWorld()
			SceneObject(pArea):destroyObjectFromDatabase()
		end
	end

	deleteData(self:getSpiderDataKey("activationAreaOid"))
end

function GeonosianCaveAntiCampingHybrid:createSpiderActivationArea(pSpider)
	if (pSpider == nil) then
		return
	end

	self:clearSpiderActivationArea()

	local pArea = spawnActiveArea(
		self.planet,
		"object/active_area.iff",
		SceneObject(pSpider):getWorldPositionX(),
		SceneObject(pSpider):getWorldPositionZ(),
		SceneObject(pSpider):getWorldPositionY(),
		self.spiderActivationRadius,
		SceneObject(pSpider):getParentID()
	)

	if (pArea == nil) then
		printLuaError("GeonosianCaveAntiCampingHybrid: failed to create spider activation area.")
		return
	end

	writeData(self:getSpiderDataKey("activationAreaOid"), SceneObject(pArea):getObjectID())
	createObserver(ENTEREDAREA, self.screenplayName, "notifySpiderActivationAreaEntered", pArea)
end

function GeonosianCaveAntiCampingHybrid:protectSpiderUntilPlayerArrives(pSpider)
	if (pSpider == nil) then
		return
	end

	CreatureObject(pSpider):setPvpStatusBitmask(0)
	CreatureObject(pSpider):setOptionBit(INVULNERABLE)
	self:createSpiderActivationArea(pSpider)
end

function GeonosianCaveAntiCampingHybrid:activateSpiderForCombat(pSpider)
	if (pSpider == nil) then
		return
	end

	CreatureObject(pSpider):setPvpStatusBitmask(AGGRESSIVE + ATTACKABLE + ENEMY)
	CreatureObject(pSpider):clearOptionBit(INVULNERABLE)
	self:clearSpiderActivationArea()
end

function GeonosianCaveAntiCampingHybrid:spawnEnhancedGapingSpider()
	local spawnPoint = self:getRandomSpiderSpawnPoint()

	if (spawnPoint == nil) then
		printLuaError("GeonosianCaveAntiCampingHybrid: no spider spawn points configured.")
		return
	end

	local pSpider = spawnMobile(self.planet, self.enhancedGapingSpiderTemplate, 0, spawnPoint.x, spawnPoint.z, spawnPoint.y, getRandomNumber(0, 359), spawnPoint.cell)

	if (pSpider == nil) then
		printLuaError("GeonosianCaveAntiCampingHybrid: failed to spawn Enhanced Gaping Spider.")
		return
	end

	writeData(self:getSpiderDataKey("oid"), SceneObject(pSpider):getObjectID())
	writeData(self:getSpiderDataKey("nextRespawnAt"), 0)
	self:protectSpiderUntilPlayerArrives(pSpider)
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyEnhancedGapingSpiderKilled", pSpider)
end

function GeonosianCaveAntiCampingHybrid:notifySpiderActivationAreaEntered(pArea, pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local spiderOID = readData(self:getSpiderDataKey("oid"))
	local pSpider = getSceneObject(spiderOID)

	if (pSpider == nil) then
		self:clearSpiderActivationArea()
		return 1
	end

	self:activateSpiderForCombat(pSpider)

	return 1
end

function GeonosianCaveAntiCampingHybrid:notifyEnhancedGapingSpiderKilled(pSpider, pKiller)
	self:clearSpiderActivationArea()
	deleteData(self:getSpiderDataKey("oid"))
	writeData(self:getSpiderDataKey("nextRespawnAt"), os.time() + self.enhancedGapingSpiderRespawnSeconds)
	createEvent(self.enhancedGapingSpiderRespawnSeconds * 1000, self.screenplayName, "respawnEnhancedGapingSpider", nil, "")

	return 1
end

function GeonosianCaveAntiCampingHybrid:respawnEnhancedGapingSpider()
	self:ensureEnhancedGapingSpiderSpawned()

	return 0
end
