GalacticTour = ScreenPlay:new {
	screenplayName = "GalacticTour",
	numberOfActs = 1,
}

registerScreenPlay("GalacticTour", true)

GalacticTour.NPC_TEMPLATE = "tour_coordinator"
GalacticTour.NPC_NAME = "Tour Coordinator"
GalacticTour.NPC_PLANET = "tatooine"
GalacticTour.NPC_X = 3481
GalacticTour.NPC_Z = 5
GalacticTour.NPC_Y = -4846
GalacticTour.NPC_HEADING = 90

GalacticTour.DATA_NAMESPACE = "galactic_tour"
GalacticTour.CONVO_TEMPLATE = "galacticTourConvoTemplate"
GalacticTour.COOLDOWN_SECONDS = 3600
GalacticTour.REQUIRED_PLANET_COUNT = 5
GalacticTour.REQUIRED_PERFORMANCE_SECONDS = 600
GalacticTour.REQUIRED_FLOURISHES = 10
GalacticTour.FLOURISH_COOLDOWN_SECONDS = 3
GalacticTour.HEARTBEAT_MS = 5000
GalacticTour.REWARD_CREDITS = 150000
GalacticTour.REWARD_ATTACHMENT_TEMPLATE = "object/tangible/gem/clothing.iff"
GalacticTour.HEARTBEAT_TASK = "performanceHeartbeat"

GalacticTour.STATE_KEYS = {
	active = "active",
	completedMask = "completedMask",
	cooldownEnd = "cooldownEnd",
	readyToTurnIn = "readyToTurnIn",
	sessionPlanet = "sessionPlanet",
	sessionAccumulated = "sessionAccumulated",
	sessionFlourishes = "sessionFlourishes",
	sessionLastTick = "sessionLastTick",
	sessionLastFlourish = "sessionLastFlourish",
	sessionNotice = "sessionNotice",
}

GalacticTour.allowedPlanets = {
	{ key = "tatooine", display = "Tatooine", bit = 1 },
	{ key = "naboo", display = "Naboo", bit = 2 },
	{ key = "corellia", display = "Corellia", bit = 4 },
	{ key = "talus", display = "Talus", bit = 8 },
	{ key = "rori", display = "Rori", bit = 16 },
	{ key = "lok", display = "Lok", bit = 32 },
	{ key = "dantooine", display = "Dantooine", bit = 64 },
	{ key = "endor", display = "Endor", bit = 128 },
}

GalacticTour.npcCantinaOids = {
	corellia = {
		[2625352] = true,
		[3005396] = true,
		[3005694] = true,
		[3075426] = true,
		[3375352] = true,
		[8105493] = true,
	},
	naboo = {
		[2] = true,
		[61] = true,
		[88] = true,
		[108] = true,
	},
	tatooine = {
		[1028644] = true,
		[1082874] = true,
		[1134557] = true,
		[1256055] = true,
	},
}

GalacticTour.rewardStatPool = {
	{ key = "healing_dance_mind", display = "Healing Dance Mind" },
	{ key = "healing_dance_shock", display = "Healing Dance Shock" },
	{ key = "healing_dance_wound", display = "Healing Dance Wound" },
	{ key = "healing_music_mind", display = "Healing Music Mind" },
	{ key = "healing_music_shock", display = "Healing Music Shock" },
	{ key = "healing_music_wound", display = "Healing Music Wound" },
	{ key = "healing_range", display = "Healing Range" },
	{ key = "healing_range_speed", display = "Healing Range Speed" },
}

GalacticTour.entertainerSkills = {
	"social_entertainer_novice",
	"social_entertainer_master",
	"social_entertainer_hairstyle_01",
	"social_entertainer_hairstyle_02",
	"social_entertainer_hairstyle_03",
	"social_entertainer_hairstyle_04",
	"social_entertainer_music_01",
	"social_entertainer_music_02",
	"social_entertainer_music_03",
	"social_entertainer_music_04",
	"social_entertainer_dance_01",
	"social_entertainer_dance_02",
	"social_entertainer_dance_03",
	"social_entertainer_dance_04",
	"social_entertainer_healing_01",
	"social_entertainer_healing_02",
	"social_entertainer_healing_03",
	"social_entertainer_healing_04",
	"social_dancer_novice",
	"social_dancer_master",
	"social_dancer_ability_01",
	"social_dancer_ability_02",
	"social_dancer_ability_03",
	"social_dancer_ability_04",
	"social_dancer_wound_01",
	"social_dancer_wound_02",
	"social_dancer_wound_03",
	"social_dancer_wound_04",
	"social_dancer_knowledge_01",
	"social_dancer_knowledge_02",
	"social_dancer_knowledge_03",
	"social_dancer_knowledge_04",
	"social_dancer_shock_01",
	"social_dancer_shock_02",
	"social_dancer_shock_03",
	"social_dancer_shock_04",
	"social_musician_novice",
	"social_musician_master",
	"social_musician_ability_01",
	"social_musician_ability_02",
	"social_musician_ability_03",
	"social_musician_ability_04",
	"social_musician_wound_01",
	"social_musician_wound_02",
	"social_musician_wound_03",
	"social_musician_wound_04",
	"social_musician_knowledge_01",
	"social_musician_knowledge_02",
	"social_musician_knowledge_03",
	"social_musician_knowledge_04",
	"social_musician_shock_01",
	"social_musician_shock_02",
	"social_musician_shock_03",
	"social_musician_shock_04",
}

function GalacticTour:start()
	self:spawnNpc()
end

function GalacticTour:spawnNpc()
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, self.NPC_Z, self.NPC_Y, self.NPC_HEADING, 0)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function GalacticTour:getNow()
	return os.time()
end

function GalacticTour:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)) or 0
end

function GalacticTour:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value)
end

function GalacticTour:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key) or ""
end

function GalacticTour:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value or "")
end

function GalacticTour:isEligibleEntertainer(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	for i = 1, #self.entertainerSkills, 1 do
		if (CreatureObject(pPlayer):hasSkill(self.entertainerSkills[i])) then
			return true
		end
	end

	return false
end

function GalacticTour:isActive(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.active) == 1
end

function GalacticTour:isReadyToTurnIn(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.readyToTurnIn) == 1
end

function GalacticTour:getRemainingCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, self.STATE_KEYS.cooldownEnd) - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function GalacticTour:isOnCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function GalacticTour:getCompletedMask(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.completedMask)
end

function GalacticTour:setCompletedMask(pPlayer, mask)
	self:setNumber(pPlayer, self.STATE_KEYS.completedMask, mask)
end

function GalacticTour:getPlanetData(planetKey)
	for i = 1, #self.allowedPlanets, 1 do
		if (self.allowedPlanets[i].key == planetKey) then
			return self.allowedPlanets[i]
		end
	end

	return nil
end

function GalacticTour:getPlanetDisplayName(planetKey)
	local planet = self:getPlanetData(planetKey)

	if (planet == nil) then
		return planetKey or "Unknown"
	end

	return planet.display
end

function GalacticTour:isAllowedPlanet(planetKey)
	return self:getPlanetData(planetKey) ~= nil
end

function GalacticTour:isPlanetCompleted(pPlayer, planetKey)
	local planet = self:getPlanetData(planetKey)

	if (planet == nil) then
		return false
	end

	local mask = self:getCompletedMask(pPlayer)
	return math.floor(mask / planet.bit) % 2 == 1
end

function GalacticTour:markPlanetCompleted(pPlayer, planetKey)
	local planet = self:getPlanetData(planetKey)

	if (planet == nil) then
		return
	end

	local mask = self:getCompletedMask(pPlayer)

	if (math.floor(mask / planet.bit) % 2 == 0) then
		self:setCompletedMask(pPlayer, mask + planet.bit)
	end
end

function GalacticTour:getCompletedCount(pPlayer)
	local count = 0

	for i = 1, #self.allowedPlanets, 1 do
		if (self:isPlanetCompleted(pPlayer, self.allowedPlanets[i].key)) then
			count = count + 1
		end
	end

	return count
end

function GalacticTour:getCompletedPlanetNames(pPlayer)
	local names = {}

	for i = 1, #self.allowedPlanets, 1 do
		if (self:isPlanetCompleted(pPlayer, self.allowedPlanets[i].key)) then
			table.insert(names, self.allowedPlanets[i].display)
		end
	end

	return names
end

function GalacticTour:getRemainingPlanetNames(pPlayer)
	local names = {}

	for i = 1, #self.allowedPlanets, 1 do
		if (not self:isPlanetCompleted(pPlayer, self.allowedPlanets[i].key)) then
			table.insert(names, self.allowedPlanets[i].display)
		end
	end

	return names
end

function GalacticTour:joinNames(names)
	if (names == nil or #names == 0) then
		return "None"
	end

	return table.concat(names, ", ")
end

function GalacticTour:formatDuration(seconds)
	if (seconds <= 0) then
		return "0 minutes"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	local parts = {}

	if (hours > 0) then
		table.insert(parts, hours .. " hour" .. (hours == 1 and "" or "s"))
	end

	if (minutes > 0) then
		table.insert(parts, minutes .. " minute" .. (minutes == 1 and "" or "s"))
	end

	if (#parts == 0 or secs > 0) then
		table.insert(parts, secs .. " second" .. (secs == 1 and "" or "s"))
	end

	return table.concat(parts, ", ")
end

function GalacticTour:getCooldownStatusText(pPlayer)
	local remaining = self:getRemainingCooldown(pPlayer)

	if (remaining <= 0) then
		return "Your Galactic Tour cooldown has ended. You may begin another tour."
	end

	return "You must wait " .. self:formatDuration(remaining) .. " before beginning another Galactic Tour."
end

function GalacticTour:getRulesText()
	return "Galactic Tour Rules:\n\n"
		.. "- Perform in valid NPC city cantinas on 5 different planets.\n"
		.. "- Each stop requires 10 continuous minutes of music or dance.\n"
		.. "- Each stop also requires 10 counted flourishes.\n"
		.. "- Counted flourishes must be at least 3 seconds apart.\n"
		.. "- You may choose the planets in any order.\n"
		.. "- The same planet cannot count twice in one tour.\n"
		.. "- Return to the Tour Coordinator after 5 planets for your reward."
end

function GalacticTour:getProgressReportText(pPlayer)
	local completed = self:getCompletedPlanetNames(pPlayer)
	local remaining = self:getRemainingPlanetNames(pPlayer)
	local progress = self:getCompletedCount(pPlayer)
	local lines = {
		"Galactic Tour Progress",
		"",
		"Completed: " .. progress .. "/" .. self.REQUIRED_PLANET_COUNT,
		"Completed planets: " .. self:joinNames(completed),
		"Remaining eligible planets: " .. self:joinNames(remaining),
	}

	if (self:isReadyToTurnIn(pPlayer)) then
		table.insert(lines, "Status: Tour complete. Return to the Tour Coordinator for your reward.")
	elseif (self:isActive(pPlayer)) then
		local sessionPlanet = self:getString(pPlayer, self.STATE_KEYS.sessionPlanet)

		if (sessionPlanet ~= "") then
			local sessionSeconds = self:getNumber(pPlayer, self.STATE_KEYS.sessionAccumulated)
			local sessionFlourishes = self:getNumber(pPlayer, self.STATE_KEYS.sessionFlourishes)
			table.insert(lines, "Current stop: " .. self:getPlanetDisplayName(sessionPlanet))
			table.insert(lines, "Current timer: " .. tostring(sessionSeconds) .. "/" .. tostring(self.REQUIRED_PERFORMANCE_SECONDS) .. " seconds")
			table.insert(lines, "Current flourishes: " .. tostring(sessionFlourishes) .. "/" .. tostring(self.REQUIRED_FLOURISHES))
		else
			table.insert(lines, "Status: Active. Begin performing in any valid cantina on a new planet.")
		end
	else
		table.insert(lines, "Status: No active tour.")
	end

	return table.concat(lines, "\n")
end

function GalacticTour:clearSession(pPlayer)
	self:setString(pPlayer, self.STATE_KEYS.sessionPlanet, "")
	self:setNumber(pPlayer, self.STATE_KEYS.sessionAccumulated, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionFlourishes, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastTick, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastFlourish, 0)
	self:setString(pPlayer, self.STATE_KEYS.sessionNotice, "")
end

function GalacticTour:cancelHeartbeat(pPlayer)
	if (pPlayer ~= nil and SceneObject(pPlayer):hasPendingTask(self.screenplayName, self.HEARTBEAT_TASK)) then
		SceneObject(pPlayer):cancelPendingTask(self.screenplayName, self.HEARTBEAT_TASK)
	end
end

function GalacticTour:scheduleHeartbeat(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer) or self:isReadyToTurnIn(pPlayer)) then
		return
	end

	if (SceneObject(pPlayer):hasPendingTask(self.screenplayName, self.HEARTBEAT_TASK)) then
		SceneObject(pPlayer):cancelPendingTask(self.screenplayName, self.HEARTBEAT_TASK)
	end

	SceneObject(pPlayer):addPendingTask(self.HEARTBEAT_MS, self.screenplayName, self.HEARTBEAT_TASK)
end

function GalacticTour:refreshObservers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)
	dropObserver(FLOURISH, pPlayer)

	if (not self:isActive(pPlayer)) then
		return
	end

	createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)
	createObserver(FLOURISH, self.screenplayName, "notifyFlourish", pPlayer, 1)
end

function GalacticTour:resetQuestState(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.completedMask, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.readyToTurnIn, 0)
	self:clearSession(pPlayer)
	self:cancelHeartbeat(pPlayer)
	self:refreshObservers(pPlayer)
end

function GalacticTour:startTour(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot begin a tour without a registered performer."
	end

	if (not self:isEligibleEntertainer(pPlayer)) then
		return false, "This tour is reserved for entertainers, dancers, and musicians."
	end

	if (self:isOnCooldown(pPlayer)) then
		return false, self:getCooldownStatusText(pPlayer)
	end

	if (self:isActive(pPlayer)) then
		return false, "Your Galactic Tour is already active.\n\n" .. self:getProgressReportText(pPlayer)
	end

	self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
	self:setNumber(pPlayer, self.STATE_KEYS.completedMask, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.readyToTurnIn, 0)
	self:clearSession(pPlayer)
	self:refreshObservers(pPlayer)
	self:scheduleHeartbeat(pPlayer)

	local message = "Galactic Tour started. Perform in valid cantinas on 5 different planets. Each stop requires 10 continuous minutes of music or dance and 10 flourishes. You may choose the planets in any order, then return here for your reward."
	CreatureObject(pPlayer):sendSystemMessage(message)

	return true, message
end

function GalacticTour:getCurrentPlanetKey(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	local zoneName = SceneObject(pPlayer):getZoneName()

	if (self:isAllowedPlanet(zoneName)) then
		return zoneName
	end

	return nil
end

function GalacticTour:isActivelyPerforming(pPlayer)
	return CreatureObject(pPlayer):isDancing() or CreatureObject(pPlayer):isPlayingMusic()
end

function GalacticTour:isInNpcCityCantina(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local pParent = SceneObject(pPlayer):getParent()
	if (pParent == nil or not SceneObject(pParent):isCellObject()) then
		return false
	end

	local pBuilding = SceneObject(pPlayer):getRootParent()
	if (pBuilding == nil or not SceneObject(pBuilding):isBuildingObject()) then
		return false
	end

	local zoneName = SceneObject(pPlayer):getZoneName()
	local buildingId = SceneObject(pBuilding):getObjectID()
	local knownCantinas = self.npcCantinaOids[zoneName]

	if (knownCantinas ~= nil and knownCantinas[buildingId] == true) then
		return true
	end

	local templatePath = string.lower(SceneObject(pBuilding):getTemplateObjectPath() or "")
	local isEntertainerVenue = string.find(templatePath, "cantina", 1, true) ~= nil or string.find(templatePath, "theater", 1, true) ~= nil

	if (not isEntertainerVenue) then
		return false
	end

	local worldX = SceneObject(pPlayer):getWorldPositionX()
	local worldY = SceneObject(pPlayer):getWorldPositionY()
	local pCityRegion = getCityRegionAt(zoneName, worldX, worldY)

	if (pCityRegion == nil) then
		return false
	end

	return LuaCityRegion(pCityRegion):isClientRegion()
end

function GalacticTour:getSessionNotice(pPlayer)
	return self:getString(pPlayer, self.STATE_KEYS.sessionNotice)
end

function GalacticTour:setSessionNotice(pPlayer, token)
	self:setString(pPlayer, self.STATE_KEYS.sessionNotice, token)
end

function GalacticTour:sendNoticeOnce(pPlayer, token, message)
	if (self:getSessionNotice(pPlayer) == token) then
		return
	end

	self:setSessionNotice(pPlayer, token)
	CreatureObject(pPlayer):sendSystemMessage(message)
end

function GalacticTour:getInvalidState(pPlayer)
	if (pPlayer == nil) then
		return "invalid", nil, nil
	end

	if (CreatureObject(pPlayer):isDead() or CreatureObject(pPlayer):isIncapacitated()) then
		return "dead", nil, "Your Galactic Tour performance was interrupted because you were incapacitated."
	end

	if (CreatureObject(pPlayer):isInCombat()) then
		return "combat", nil, "Your Galactic Tour performance was interrupted by combat."
	end

	if (not self:isActivelyPerforming(pPlayer)) then
		return "not_performing", nil, "Your Galactic Tour performance has reset because you stopped performing."
	end

	local planetKey = self:getCurrentPlanetKey(pPlayer)
	if (planetKey == nil) then
		return "invalid_planet", nil, "This planet is not part of the Galactic Tour route."
	end

	if (self:isPlanetCompleted(pPlayer, planetKey)) then
		return "completed_planet", planetKey, "You have already completed " .. self:getPlanetDisplayName(planetKey) .. " on this tour."
	end

	if (not self:isInNpcCityCantina(pPlayer)) then
		return "invalid_cantina", planetKey, "Only valid NPC city cantinas count toward Galactic Tour performances."
	end

	return nil, planetKey, nil
end

function GalacticTour:startSession(pPlayer, planetKey)
	local now = self:getNow()
	self:setString(pPlayer, self.STATE_KEYS.sessionPlanet, planetKey)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionAccumulated, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionFlourishes, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastTick, now)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastFlourish, 0)
	self:setSessionNotice(pPlayer, "tracking")
	CreatureObject(pPlayer):sendSystemMessage("Galactic Tour tracking started on " .. self:getPlanetDisplayName(planetKey) .. ". Maintain your performance here for 10 minutes and complete 10 flourishes.")
end

function GalacticTour:resetSessionWithMessage(pPlayer, message)
	self:clearSession(pPlayer)
	if (message ~= nil and message ~= "") then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end
end

function GalacticTour:completePlanet(pPlayer, planetKey)
	self:markPlanetCompleted(pPlayer, planetKey)
	self:clearSession(pPlayer)

	local completed = self:getCompletedCount(pPlayer)
	local planetName = self:getPlanetDisplayName(planetKey)

	if (completed >= self.REQUIRED_PLANET_COUNT) then
		self:setNumber(pPlayer, self.STATE_KEYS.readyToTurnIn, 1)
		self:cancelHeartbeat(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("Your performance has won over the crowd on " .. planetName .. ".")
		CreatureObject(pPlayer):sendSystemMessage("Your Galactic Tour is complete. Return to the Tour Coordinator in Mos Eisley for your reward.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Your performance has won over the crowd on " .. planetName .. ". It is time to move on to your next destination.")
		self:scheduleHeartbeat(pPlayer)
	end
end

function GalacticTour:ensureValidSessionForFlourish(pPlayer)
	local invalidState, planetKey = self:getInvalidState(pPlayer)

	if (invalidState ~= nil) then
		return false, nil
	end

	local sessionPlanet = self:getString(pPlayer, self.STATE_KEYS.sessionPlanet)

	if (sessionPlanet == "") then
		self:startSession(pPlayer, planetKey)
		return true, planetKey
	end

	if (sessionPlanet ~= planetKey) then
		self:resetSessionWithMessage(pPlayer, "Your Galactic Tour performance has reset because you changed planets before completing this stop.")
		return false, nil
	end

	return true, planetKey
end

function GalacticTour:notifyFlourish(pPlayer, pPlayer2, flourishId)
	if (pPlayer == nil or not self:isActive(pPlayer) or self:isReadyToTurnIn(pPlayer)) then
		return 0
	end

	local isValid = self:ensureValidSessionForFlourish(pPlayer)

	if (not isValid) then
		return 0
	end

	local now = self:getNow()
	local lastFlourish = self:getNumber(pPlayer, self.STATE_KEYS.sessionLastFlourish)

	if (lastFlourish > 0 and (now - lastFlourish) < self.FLOURISH_COOLDOWN_SECONDS) then
		return 0
	end

	local flourishes = self:getNumber(pPlayer, self.STATE_KEYS.sessionFlourishes) + 1
	self:setNumber(pPlayer, self.STATE_KEYS.sessionFlourishes, flourishes)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastFlourish, now)

	if (flourishes >= self.REQUIRED_FLOURISHES) then
		local accumulated = self:getNumber(pPlayer, self.STATE_KEYS.sessionAccumulated)

		if (accumulated < self.REQUIRED_PERFORMANCE_SECONDS) then
			self:sendNoticeOnce(pPlayer, "need_time", "Flourish requirement met. Keep performing until the full 10 minutes are complete.")
		end
	end

	return 0
end

function GalacticTour:performanceHeartbeat(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer) or self:isReadyToTurnIn(pPlayer)) then
		return 0
	end

	local invalidState, planetKey, message = self:getInvalidState(pPlayer)
	local sessionPlanet = self:getString(pPlayer, self.STATE_KEYS.sessionPlanet)

	if (invalidState ~= nil) then
		if (sessionPlanet ~= "") then
			self:resetSessionWithMessage(pPlayer, message)
		else
			self:sendNoticeOnce(pPlayer, invalidState, message)
		end

		self:scheduleHeartbeat(pPlayer)
		return 0
	end

	if (sessionPlanet == "") then
		self:startSession(pPlayer, planetKey)
		self:scheduleHeartbeat(pPlayer)
		return 0
	end

	if (sessionPlanet ~= planetKey) then
		self:resetSessionWithMessage(pPlayer, "Your Galactic Tour performance has reset because you changed planets before completing this stop.")
		self:scheduleHeartbeat(pPlayer)
		return 0
	end

	local now = self:getNow()
	local lastTick = self:getNumber(pPlayer, self.STATE_KEYS.sessionLastTick)

	if (lastTick <= 0) then
		lastTick = now
	end

	local delta = now - lastTick
	if (delta < 0) then
		delta = 0
	end

	local accumulated = self:getNumber(pPlayer, self.STATE_KEYS.sessionAccumulated) + delta
	local flourishes = self:getNumber(pPlayer, self.STATE_KEYS.sessionFlourishes)

	self:setNumber(pPlayer, self.STATE_KEYS.sessionAccumulated, accumulated)
	self:setNumber(pPlayer, self.STATE_KEYS.sessionLastTick, now)

	if (accumulated >= self.REQUIRED_PERFORMANCE_SECONDS and flourishes >= self.REQUIRED_FLOURISHES) then
		self:completePlanet(pPlayer, planetKey)
		return 0
	end

	if (accumulated >= self.REQUIRED_PERFORMANCE_SECONDS and flourishes < self.REQUIRED_FLOURISHES) then
		self:sendNoticeOnce(pPlayer, "need_flourishes", "Time requirement met on " .. self:getPlanetDisplayName(planetKey) .. ". Keep performing and complete " .. tostring(self.REQUIRED_FLOURISHES - flourishes) .. " more counted flourishes.")
	elseif (flourishes >= self.REQUIRED_FLOURISHES and accumulated < self.REQUIRED_PERFORMANCE_SECONDS) then
		self:sendNoticeOnce(pPlayer, "need_time", "Flourish requirement met. Keep performing for " .. tostring(self.REQUIRED_PERFORMANCE_SECONDS - accumulated) .. " more seconds.")
	else
		self:setSessionNotice(pPlayer, "tracking")
	end

	self:scheduleHeartbeat(pPlayer)
	return 0
end

function GalacticTour:grantRewardAttachment(pPlayer)
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return false, "I could not locate your inventory."
	end

	if (SceneObject(pInventory):isContainerFullRecursive()) then
		return false, "Your inventory is full. Make room for your reward attachment and speak to me again."
	end

	local rewardData = self.rewardStatPool[getRandomNumber(1, #self.rewardStatPool)]
	local pReward = giveItem(pInventory, self.REWARD_ATTACHMENT_TEMPLATE, -1, true)

	if (pReward == nil) then
		return false, "Your reward attachment could not be created. Please contact staff."
	end

	local rewardName = "Galactic Tour Clothing Attachment (+25 " .. rewardData.display .. ")"
	SceneObject(pReward):setCustomObjectName(rewardName)
	TangibleObject(pReward):addAttachmentSkillModBonus(rewardData.key, 25)

	return true, rewardName
end

function GalacticTour:turnIn(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot process a reward without a performer present."
	end

	if (not self:isEligibleEntertainer(pPlayer)) then
		return false, "This tour is reserved for entertainers, dancers, and musicians."
	end

	if (not self:isActive(pPlayer)) then
		return false, "You do not currently have an active Galactic Tour."
	end

	if (not self:isReadyToTurnIn(pPlayer) or self:getCompletedCount(pPlayer) < self.REQUIRED_PLANET_COUNT) then
		return false, "You have not yet completed 5 unique Galactic Tour performances.\n\n" .. self:getProgressReportText(pPlayer)
	end

	local rewardGranted, rewardInfo = self:grantRewardAttachment(pPlayer)
	if (not rewardGranted) then
		return false, rewardInfo
	end

	CreatureObject(pPlayer):addCashCredits(self.REWARD_CREDITS)
	self:setNumber(pPlayer, self.STATE_KEYS.cooldownEnd, self:getNow() + self.COOLDOWN_SECONDS)
	self:resetQuestState(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("Reward granted: 150000 credits and " .. rewardInfo .. ".")
	CreatureObject(pPlayer):sendSystemMessage("Your name now echoes across the galaxy as a seasoned performer.")

	return true, "Your Galactic Tour reward has been granted. Return in " .. self:formatDuration(self.COOLDOWN_SECONDS) .. " if you wish to tour again."
end

function GalacticTour:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local hadSession = self:getString(pPlayer, self.STATE_KEYS.sessionPlanet) ~= ""
	self:clearSession(pPlayer)
	self:refreshObservers(pPlayer)

	if (self:isActive(pPlayer) and not self:isReadyToTurnIn(pPlayer)) then
		self:scheduleHeartbeat(pPlayer)
	end

	if (hadSession) then
		CreatureObject(pPlayer):sendSystemMessage("Your partial Galactic Tour performance was reset when your session ended. Begin a new stop in a valid cantina.")
	end

	return 0
end
