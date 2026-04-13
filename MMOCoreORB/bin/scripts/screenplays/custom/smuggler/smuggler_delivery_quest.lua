SmugglerDeliveryQuest = ScreenPlay:new {
	screenplayName = "SmugglerDeliveryQuest",
	numberOfActs = 1,
}

registerScreenPlay("SmugglerDeliveryQuest", true)

SmugglerDeliveryQuest.DATA_NAMESPACE = "smuggler_delivery_quest"
SmugglerDeliveryQuest.VEX_CONVO_TEMPLATE = "vexTalonConvoTemplate"
SmugglerDeliveryQuest.RECEIVER_CONVO_TEMPLATE = "smugglerReceiverConvoTemplate"
SmugglerDeliveryQuest.DATADISK_TEMPLATE = "object/tangible/mission/mission_datadisk.iff"
SmugglerDeliveryQuest.HOLOCRON_TEMPLATE = "object/tangible/loot/misc/holocron_of_destiny.iff"
SmugglerDeliveryQuest.BG_TOKEN_TEMPLATE = "object/tangible/component/clothing/jewelry_setting.iff"
SmugglerDeliveryQuest.MISSION_DURATION_SECONDS = 2 * 60 * 60
SmugglerDeliveryQuest.SUCCESS_COOLDOWN_SECONDS = 4 * 60 * 60
SmugglerDeliveryQuest.FAILURE_COOLDOWN_SECONDS = 30 * 60
SmugglerDeliveryQuest.HEARTBEAT_MS = 60 * 1000
SmugglerDeliveryQuest.HEARTBEAT_TASK = "missionHeartbeat"
SmugglerDeliveryQuest.MAX_AMBUSH_MOBS = 4
SmugglerDeliveryQuest.MAX_AMBUSH_AREAS = 2
SmugglerDeliveryQuest.MAX_AMBUSH_DESPAWN_MS = 5 * 60 * 1000

SmugglerDeliveryQuest.VEX_NPC = {
	template = "info_broker",
	name = "Vex Talon",
	planet = "tatooine",
	x = -12.4,
	z = -0.9,
	y = 8.7,
	heading = 118,
	cell = 1082877,
}

SmugglerDeliveryQuest.STATE_KEYS = {
	active = "active",
	missionId = "missionId",
	destinationKey = "destinationKey",
	riskKey = "riskKey",
	startTime = "startTime",
	expirationTime = "expirationTime",
	cooldownTime = "cooldownTime",
	datadiskId = "datadiskId",
	destinationWaypoint = "destinationWaypoint",
	ambushRolled = "ambushRolled",
	ambushTriggered = "ambushTriggered",
	ambushArea1 = "ambushArea1",
	ambushArea2 = "ambushArea2",
	ambushMob1 = "ambushMob1",
	ambushMob2 = "ambushMob2",
	ambushMob3 = "ambushMob3",
	ambushMob4 = "ambushMob4",
	ambushSerial = "ambushSerial",
	lastFailureReason = "lastFailureReason",
}

SmugglerDeliveryQuest.riskTiers = {
	low = {
		key = "low",
		display = "Low",
		credits = 50000,
		tokens = 5,
		ambushChance = 33,
	},
	medium = {
		key = "medium",
		display = "Medium",
		credits = 100000,
		tokens = 10,
		ambushChance = 67,
	},
	high = {
		key = "high",
		display = "High",
		credits = 175000,
		tokens = 20,
		ambushChance = 100,
	},
}

SmugglerDeliveryQuest.destinations = {
	coronet = {
		key = "coronet",
		name = "Nera Voss",
		planet = "corellia",
		planetName = "Corellia",
		city = "Coronet",
		template = "bothan_information_broker",
		x = -112.0,
		z = 28.0,
		y = -4807.0,
		heading = -118,
		cell = 0,
		deliveryText = "Coronet, Corellia",
		ambushName = "CorSec Shadows",
		ambushTemplates = { "assassin", "bounty_hunter_thug", "criminal", "slicer" },
		triggerPoints = {
			{ x = -170.0, z = 28.0, y = -4788.0, radius = 72 },
			{ x = -112.0, z = 28.0, y = -4807.0, radius = 48 },
		},
	},
	bestine = {
		key = "bestine",
		name = "Dax Rinn",
		planet = "tatooine",
		planetName = "Tatooine",
		city = "Bestine",
		template = "businessman",
		x = -1117.0,
		z = 12.0,
		y = -3642.0,
		heading = -88,
		cell = 0,
		deliveryText = "Bestine, Tatooine",
		ambushName = "Sand Ghosts",
		ambushTemplates = { "roughneck", "outlaw", "mercenary_aggro", "thug" },
		triggerPoints = {
			{ x = -1085.0, z = 12.0, y = -3595.0, radius = 72 },
			{ x = -1117.0, z = 12.0, y = -3642.0, radius = 48 },
		},
	},
	theed = {
		key = "theed",
		name = "Selka Renn",
		planet = "naboo",
		planetName = "Naboo",
		city = "Theed",
		template = "noble",
		x = -4897.0,
		z = 6.0,
		y = 4124.0,
		heading = 179,
		cell = 0,
		deliveryText = "Theed, Naboo",
		ambushName = "Royal Shadows",
		ambushTemplates = { "industrial_spy", "assassin", "mercenary_aggro", "bith_assassin" },
		triggerPoints = {
			{ x = -4928.0, z = 6.0, y = 4154.0, radius = 72 },
			{ x = -4897.0, z = 6.0, y = 4124.0, radius = 48 },
		},
	},
	narmle = {
		key = "narmle",
		name = "Torv Malk",
		planet = "rori",
		planetName = "Rori",
		city = "Narmle",
		template = "mercenary",
		x = -5257.0,
		z = 80.0,
		y = -2214.0,
		heading = -15,
		cell = 0,
		deliveryText = "Narmle, Rori",
		ambushName = "Militia Turncoats",
		ambushTemplates = { "brigand", "outlaw", "criminal", "rodian_thug" },
		triggerPoints = {
			{ x = -5120.0, z = 80.0, y = -2269.0, radius = 72 },
			{ x = -5257.0, z = 80.0, y = -2214.0, radius = 48 },
		},
	},
	dearic = {
		key = "dearic",
		name = "Jerek Vale",
		planet = "talus",
		planetName = "Talus",
		city = "Dearic",
		template = "slicer",
		x = 414.0,
		z = 6.0,
		y = -2987.0,
		heading = 200,
		cell = 0,
		deliveryText = "Dearic, Talus",
		ambushName = "Corporate Cleaners",
		ambushTemplates = { "spynet_operative", "slicer", "mercenary_aggro", "criminal" },
		triggerPoints = {
			{ x = 319.0, z = 6.0, y = -3001.0, radius = 72 },
			{ x = 414.0, z = 6.0, y = -2987.0, radius = 48 },
		},
	},
	dantooine_outpost = {
		key = "dantooine_outpost",
		name = "Kavos Drin",
		planet = "dantooine",
		planetName = "Dantooine",
		city = "Dantooine Outpost",
		template = "smuggler",
		x = 1601.0,
		z = 4.0,
		y = -6395.0,
		heading = 115,
		cell = 0,
		deliveryText = "Dantooine Outpost, Dantooine",
		ambushName = "Frontier Reclaimers",
		ambushTemplates = { "bandit", "highwayman", "outlaw", "thug" },
		triggerPoints = {
			{ x = 1567.0, z = 4.0, y = -6413.0, radius = 72 },
			{ x = 1601.0, z = 4.0, y = -6395.0, radius = 48 },
		},
	},
}

local function smugglerTry(fn, ...)
	return pcall(fn, ...)
end

function SmugglerDeliveryQuest:start()
	self:spawnVex()
end

function SmugglerDeliveryQuest:spawnVex()
	local cfg = self.VEX_NPC
	local pNpc = spawnMobile(cfg.planet, cfg.template, 0, cfg.x, cfg.z, cfg.y, cfg.heading, cfg.cell)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(cfg.name)
	AiAgent(pNpc):setConvoTemplate(self.VEX_CONVO_TEMPLATE)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function SmugglerDeliveryQuest:getNow()
	return os.time()
end

function SmugglerDeliveryQuest:getPlayerId(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then
		return 0
	end

	return SceneObject(pPlayer):getObjectID()
end

function SmugglerDeliveryQuest:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)) or 0
end

function SmugglerDeliveryQuest:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, tostring(value or 0))
end

function SmugglerDeliveryQuest:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key) or "")
end

function SmugglerDeliveryQuest:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, tostring(value or ""))
end

function SmugglerDeliveryQuest:getRiskData(riskKey)
	return self.riskTiers[riskKey]
end

function SmugglerDeliveryQuest:getDestination(destinationKey)
	return self.destinations[destinationKey]
end

function SmugglerDeliveryQuest:isActive(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.active) == 1
end

function SmugglerDeliveryQuest:getRemainingCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, self.STATE_KEYS.cooldownTime) - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function SmugglerDeliveryQuest:isOnCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function SmugglerDeliveryQuest:getRemainingMissionTime(pPlayer)
	local remaining = self:getNumber(pPlayer, self.STATE_KEYS.expirationTime) - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function SmugglerDeliveryQuest:isExpired(pPlayer)
	return self:isActive(pPlayer) and self:getRemainingMissionTime(pPlayer) <= 0
end

function SmugglerDeliveryQuest:formatDurationWords(seconds)
	if (seconds <= 0) then
		return "0m"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if (hours > 0 and minutes > 0) then
		return tostring(hours) .. "h " .. tostring(minutes) .. "m"
	end

	if (hours > 0) then
		return tostring(hours) .. "h"
	end

	return tostring(minutes) .. "m"
end

function SmugglerDeliveryQuest:isEligibleSmuggler(pPlayer)
	return pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("combat_smuggler_novice")
end

function SmugglerDeliveryQuest:getInventory(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return CreatureObject(pPlayer):getSlottedObject("inventory")
end

function SmugglerDeliveryQuest:hasInventorySpace(pPlayer)
	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false
	end

	return not SceneObject(pInventory):isContainerFullRecursive()
end

function SmugglerDeliveryQuest:soHasVar(pObject, key)
	local ok, result = smugglerTry(function()
		local so = LuaSceneObject(pObject)

		if (so ~= nil and so.hasObjVar ~= nil) then
			return so:hasObjVar(key)
		end

		if (hasObjVar ~= nil) then
			return hasObjVar(pObject, key)
		end

		return false
	end)

	return ok and result or false
end

function SmugglerDeliveryQuest:soGetVar(pObject, key)
	local ok, result = smugglerTry(function()
		local so = LuaSceneObject(pObject)

		if (so ~= nil and so.getObjVar ~= nil) then
			return so:getObjVar(key)
		end

		if (getObjVar ~= nil) then
			return getObjVar(pObject, key)
		end

		return nil
	end)

	if (not ok) then
		return nil
	end

	return result
end

function SmugglerDeliveryQuest:soSetVar(pObject, key, value)
	smugglerTry(function()
		local so = LuaSceneObject(pObject)

		if (so ~= nil and so.setObjVar ~= nil) then
			so:setObjVar(key, value)
			return
		end

		if (setObjVar ~= nil) then
			setObjVar(pObject, key, value)
		end
	end)
end

function SmugglerDeliveryQuest:getMissionDiskVar(pDisk, key)
	local value = self:soGetVar(pDisk, key)

	if (value == nil) then
		return ""
	end

	return tostring(value)
end

function SmugglerDeliveryQuest:isExpectedDiskIdentity(pPlayer, pDisk)
	if (pPlayer == nil or pDisk == nil) then
		return false
	end

	local storedDiskId = self:getNumber(pPlayer, self.STATE_KEYS.datadiskId)

	if (storedDiskId <= 0 or SceneObject(pDisk):getObjectID() ~= storedDiskId) then
		return false
	end

	local customName = tostring(SceneObject(pDisk):getCustomObjectName() or "")

	return customName == "Sealed Smuggling Datadisk"
end

function SmugglerDeliveryQuest:isMissionDiskValid(pPlayer, pDisk, missionId)
	if (pDisk == nil) then
		return false
	end

	local templatePath = string.lower(SceneObject(pDisk):getTemplateObjectPath() or "")
	local sharedTemplatePath = "object/tangible/mission/shared_mission_datadisk.iff"

	if (templatePath ~= string.lower(self.DATADISK_TEMPLATE) and templatePath ~= sharedTemplatePath) then
		return false
	end

	local cargoFlag = tonumber(self:getMissionDiskVar(pDisk, "smugglerCargo")) or 0
	local storedMissionId = tostring(missionId or "")

	if (cargoFlag == 1) then
		if (storedMissionId == "") then
			return true
		end

		return self:getMissionDiskVar(pDisk, "smugglerMissionId") == storedMissionId
	end

	if (storedMissionId == "") then
		return true
	end

	return self:isExpectedDiskIdentity(pPlayer, pDisk)
end

function SmugglerDeliveryQuest:findMissionDisk(pPlayer, missionId)
	local diskId = self:getNumber(pPlayer, self.STATE_KEYS.datadiskId)

	if (diskId > 0) then
		local pDisk = getSceneObject(diskId)

		if (pDisk ~= nil and SceneObject(pDisk):isASubChildOf(pPlayer) and self:isMissionDiskValid(pPlayer, pDisk, missionId)) then
			return pDisk
		end
	end

	local containers = {
		SceneObject(pPlayer):getSlottedObject("inventory"),
		SceneObject(pPlayer):getSlottedObject("datapad"),
		SceneObject(pPlayer):getSlottedObject("mission_bag"),
	}

	for i = 1, #containers, 1 do
		local pContainer = containers[i]

		if (pContainer ~= nil) then
			local pDisk = getContainerObjectByTemplate(pContainer, self.DATADISK_TEMPLATE, true)

			if (pDisk ~= nil and SceneObject(pDisk):isASubChildOf(pPlayer) and self:isMissionDiskValid(pPlayer, pDisk, missionId)) then
				self:setNumber(pPlayer, self.STATE_KEYS.datadiskId, SceneObject(pDisk):getObjectID())
				return pDisk
			end
		end
	end

	return nil
end

function SmugglerDeliveryQuest:destroySceneObject(pObject)
	if (pObject == nil) then
		return
	end

	smugglerTry(function()
		SceneObject(pObject):destroyObjectFromWorld(true)
	end)
	smugglerTry(function()
		SceneObject(pObject):destroyObjectFromDatabase(true)
	end)
end

function SmugglerDeliveryQuest:removeMissionDisk(pPlayer, missionId)
	local pDisk = self:findMissionDisk(pPlayer, missionId)

	if (pDisk == nil) then
		return false
	end

	self:destroySceneObject(pDisk)
	self:setNumber(pPlayer, self.STATE_KEYS.datadiskId, 0)
	return true
end

function SmugglerDeliveryQuest:clearWaypoint(pPlayer)
	local waypointId = self:getNumber(pPlayer, self.STATE_KEYS.destinationWaypoint)

	if (waypointId <= 0) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		PlayerObject(pGhost):removeWaypoint(waypointId, true)
	end

	self:setNumber(pPlayer, self.STATE_KEYS.destinationWaypoint, 0)
end

function SmugglerDeliveryQuest:addDestinationWaypoint(pPlayer)
	local destination = self:getDestination(self:getString(pPlayer, self.STATE_KEYS.destinationKey))

	if (pPlayer == nil or destination == nil) then
		return 0
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return 0
	end

	self:clearWaypoint(pPlayer)

	local desc = "Deliver the Sealed Smuggling Datadisk to " .. destination.name .. "."
	local waypointId = PlayerObject(pGhost):addWaypoint(destination.planet, destination.name, desc, destination.x, destination.z, destination.y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)
	self:setNumber(pPlayer, self.STATE_KEYS.destinationWaypoint, waypointId)
	return waypointId
end

function SmugglerDeliveryQuest:getMissionId(pPlayer)
	return self:getString(pPlayer, self.STATE_KEYS.missionId)
end

function SmugglerDeliveryQuest:nextMissionId(pPlayer)
	return tostring(self:getPlayerId(pPlayer)) .. tostring(self:getNow()) .. tostring(getRandomNumber(1000, 9999))
end

function SmugglerDeliveryQuest:pickRandomDestinationKey()
	local keys = {}

	for key, _ in pairs(self.destinations) do
		table.insert(keys, key)
	end

	if (#keys <= 0) then
		return nil
	end

	return keys[getRandomNumber(1, #keys)]
end

function SmugglerDeliveryQuest:clearAmbushAreas(pPlayer)
	for i = 1, self.MAX_AMBUSH_AREAS, 1 do
		local key = self.STATE_KEYS["ambushArea" .. tostring(i)]
		local areaId = self:getNumber(pPlayer, key)

		if (areaId > 0) then
			local pArea = getSceneObject(areaId)

			if (pArea ~= nil) then
				self:destroySceneObject(pArea)
			end

			self:setNumber(pPlayer, key, 0)
		end
	end
end

function SmugglerDeliveryQuest:despawnAmbushMobiles(pPlayer)
	for i = 1, self.MAX_AMBUSH_MOBS, 1 do
		local key = self.STATE_KEYS["ambushMob" .. tostring(i)]
		local mobId = self:getNumber(pPlayer, key)

		if (mobId > 0) then
			local pMobile = getSceneObject(mobId)

			if (pMobile ~= nil) then
				self:destroySceneObject(pMobile)
			end

			self:setNumber(pPlayer, key, 0)
		end
	end
end

function SmugglerDeliveryQuest:clearAmbushState(pPlayer)
	self:clearAmbushAreas(pPlayer)
	self:despawnAmbushMobiles(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.ambushSerial, 0)
end

function SmugglerDeliveryQuest:resetMissionState(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 0)
	self:setString(pPlayer, self.STATE_KEYS.missionId, "")
	self:setString(pPlayer, self.STATE_KEYS.destinationKey, "")
	self:setString(pPlayer, self.STATE_KEYS.riskKey, "")
	self:setNumber(pPlayer, self.STATE_KEYS.startTime, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.expirationTime, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.datadiskId, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.ambushRolled, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.ambushTriggered, 0)
	self:clearWaypoint(pPlayer)
	self:clearAmbushState(pPlayer)
end

function SmugglerDeliveryQuest:cancelHeartbeat(pPlayer)
	if (pPlayer ~= nil and SceneObject(pPlayer):hasPendingTask(self.screenplayName, self.HEARTBEAT_TASK)) then
		SceneObject(pPlayer):cancelPendingTask(self.screenplayName, self.HEARTBEAT_TASK)
	end
end

function SmugglerDeliveryQuest:scheduleHeartbeat(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer)) then
		return
	end

	self:cancelHeartbeat(pPlayer)
	SceneObject(pPlayer):addPendingTask(self.HEARTBEAT_MS, self.screenplayName, self.HEARTBEAT_TASK)
end

function SmugglerDeliveryQuest:refreshObservers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)

	if (not self:isActive(pPlayer)) then
		self:cancelHeartbeat(pPlayer)
		return
	end

	createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)
	self:scheduleHeartbeat(pPlayer)
end

function SmugglerDeliveryQuest:getStatusLine(pPlayer)
	if (not self:isEligibleSmuggler(pPlayer)) then
		return "Vex Talon only deals with Novice Smugglers or better."
	end

	if (self:isActive(pPlayer)) then
		local destination = self:getDestination(self:getString(pPlayer, self.STATE_KEYS.destinationKey))
		local risk = self:getRiskData(self:getString(pPlayer, self.STATE_KEYS.riskKey))
		local destinationText = "unknown contact"

		if (destination ~= nil) then
			destinationText = destination.name .. " in " .. destination.deliveryText
		end

		if (risk ~= nil) then
			return "Active " .. risk.display .. " risk run. Deliver to " .. destinationText .. ". Time remaining: " .. self:formatDurationWords(self:getRemainingMissionTime(pPlayer)) .. "."
		end

		return "Active run: deliver to " .. destinationText .. "."
	end

	if (self:isOnCooldown(pPlayer)) then
		return "Lay low for " .. self:formatDurationWords(self:getRemainingCooldown(pPlayer)) .. " before you ask for more work."
	end

	return "Take the disk. Make the drop. No questions."
end

function SmugglerDeliveryQuest:validatePlayerForMission(pPlayer)
	if (pPlayer == nil) then
		return false, "No registered smuggler was found."
	end

	if (not self:isEligibleSmuggler(pPlayer)) then
		return false, "Vex Talon only hires Novice Smugglers or higher."
	end

	if (self:isActive(pPlayer)) then
		return false, self:getStatusLine(pPlayer)
	end

	if (self:isOnCooldown(pPlayer)) then
		return false, "Lay low for " .. self:formatDurationWords(self:getRemainingCooldown(pPlayer)) .. " and come back when the heat is off."
	end

	if (not self:hasInventorySpace(pPlayer)) then
		return false, "Clear space in your inventory before you take contraband."
	end

	return true, ""
end

function SmugglerDeliveryQuest:createMissionDisk(pPlayer, missionId, destinationKey, riskKey)
	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return nil
	end

	local pDisk = giveItem(pInventory, self.DATADISK_TEMPLATE, -1, true)

	if (pDisk == nil) then
		return nil
	end

	SceneObject(pDisk):setCustomObjectName("Sealed Smuggling Datadisk")
	self:soSetVar(pDisk, "smugglerCargo", 1)
	self:soSetVar(pDisk, "smugglerMissionId", tostring(missionId))
	self:soSetVar(pDisk, "smugglerDestination", tostring(destinationKey))
	self:soSetVar(pDisk, "smugglerRisk", tostring(riskKey))
	self:soSetVar(pDisk, "smugglerDescription", "A sealed datadisk containing highly restricted underworld transaction data.")
	return pDisk
end

function SmugglerDeliveryQuest:rebuildAmbushAreas(pPlayer)
	self:clearAmbushAreas(pPlayer)

	if (pPlayer == nil or not self:isActive(pPlayer) or self:getNumber(pPlayer, self.STATE_KEYS.ambushRolled) == 1) then
		return
	end

	local destination = self:getDestination(self:getString(pPlayer, self.STATE_KEYS.destinationKey))

	if (destination == nil or destination.triggerPoints == nil) then
		return
	end

	local playerId = self:getPlayerId(pPlayer)

	for i = 1, #destination.triggerPoints, 1 do
		local point = destination.triggerPoints[i]
		local pArea = spawnActiveArea(destination.planet, "object/active_area.iff", point.x, point.z, point.y, point.radius, 0)

		if (pArea ~= nil) then
			local areaId = SceneObject(pArea):getObjectID()
			writeData(areaId .. ":SmugglerDeliveryQuest:ownerID", playerId)
			createObserver(ENTEREDAREA, self.screenplayName, "notifyEnteredAmbushArea", pArea)
			self:setNumber(pPlayer, self.STATE_KEYS["ambushArea" .. tostring(i)], areaId)
		end
	end
end

function SmugglerDeliveryQuest:startMission(pPlayer, riskKey)
	local allowed, reason = self:validatePlayerForMission(pPlayer)

	if (not allowed) then
		return false, reason
	end

	local risk = self:getRiskData(riskKey)

	if (risk == nil) then
		return false, "That risk tier is unavailable."
	end

	local destinationKey = self:pickRandomDestinationKey()
	local destination = self:getDestination(destinationKey)

	if (destination == nil) then
		return false, "No valid receiver is available."
	end

	local missionId = self:nextMissionId(pPlayer)
	local pDisk = self:createMissionDisk(pPlayer, missionId, destinationKey, riskKey)

	if (pDisk == nil) then
		return false, "The sealed datadisk could not be issued. Free inventory space and try again."
	end

	local now = self:getNow()
	self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
	self:setString(pPlayer, self.STATE_KEYS.missionId, missionId)
	self:setString(pPlayer, self.STATE_KEYS.destinationKey, destinationKey)
	self:setString(pPlayer, self.STATE_KEYS.riskKey, riskKey)
	self:setNumber(pPlayer, self.STATE_KEYS.startTime, now)
	self:setNumber(pPlayer, self.STATE_KEYS.expirationTime, now + self.MISSION_DURATION_SECONDS)
	self:setNumber(pPlayer, self.STATE_KEYS.cooldownTime, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.datadiskId, SceneObject(pDisk):getObjectID())
	self:setNumber(pPlayer, self.STATE_KEYS.ambushRolled, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.ambushTriggered, 0)
	self:setString(pPlayer, self.STATE_KEYS.lastFailureReason, "")
	self:addDestinationWaypoint(pPlayer)
	self:rebuildAmbushAreas(pPlayer)
	self:refreshObservers(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("Mission accepted: Sealed Smuggling Datadisk received.")
	CreatureObject(pPlayer):sendSystemMessage("Destination assigned: " .. destination.name .. " in " .. destination.deliveryText .. ".")

	return true, "You get paid for silence.\n\n" ..
		"Risk: " .. risk.display .. "\n" ..
		"Destination: " .. destination.name .. " - " .. destination.deliveryText .. "\n" ..
		"Reward:\n" ..
		"- " .. tostring(risk.credits) .. " credits\n" ..
		"- " .. tostring(risk.tokens) .. " BG Tokens\n" ..
		"- 1 Holocron of Destiny\n" ..
		"Mission expires in " .. self:formatDurationWords(self.MISSION_DURATION_SECONDS) .. "."
end

function SmugglerDeliveryQuest:getDeliveryStatusText(pPlayer)
	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return "No active cargo. Your cooldown ends in " .. self:formatDurationWords(self:getRemainingCooldown(pPlayer)) .. "."
		end

		return "You do not have an active smuggling contract."
	end

	local destination = self:getDestination(self:getString(pPlayer, self.STATE_KEYS.destinationKey))
	local risk = self:getRiskData(self:getString(pPlayer, self.STATE_KEYS.riskKey))
	local destinationText = "unknown destination"
	local riskText = "Unknown"

	if (destination ~= nil) then
		destinationText = destination.name .. " in " .. destination.deliveryText
	end

	if (risk ~= nil) then
		riskText = risk.display
	end

	return "Current delivery:\n" ..
		"- Risk: " .. riskText .. "\n" ..
		"- Contact: " .. destinationText .. "\n" ..
		"- Time remaining: " .. self:formatDurationWords(self:getRemainingMissionTime(pPlayer))
end

function SmugglerDeliveryQuest:grantRewardItems(pPlayer, risk)
	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false, "Your inventory could not be located."
	end

	local pToken = giveItem(pInventory, self.BG_TOKEN_TEMPLATE, -1, true)

	if (pToken == nil) then
		return false, "I could not place your BG Tokens into your inventory."
	end

	SceneObject(pToken):setCustomObjectName("Bellum Gero Token")
	smugglerTry(function()
		LuaTangibleObject(pToken):setCount(risk.tokens)
	end)

	local pHolocron = giveItem(pInventory, self.HOLOCRON_TEMPLATE, -1, true)

	if (pHolocron == nil) then
		self:destroySceneObject(pToken)
		return false, "I could not place the Holocron of Destiny into your inventory."
	end

	SceneObject(pHolocron):setCustomObjectName("Holocron of Destiny")
	CreatureObject(pPlayer):addBankCredits(risk.credits, true)
	return true, ""
end

function SmugglerDeliveryQuest:rollAmbush(pPlayer)
	if (self:getNumber(pPlayer, self.STATE_KEYS.ambushRolled) == 1) then
		return false
	end

	local risk = self:getRiskData(self:getString(pPlayer, self.STATE_KEYS.riskKey))
	self:setNumber(pPlayer, self.STATE_KEYS.ambushRolled, 1)

	if (risk == nil or getRandomNumber(1, 100) > risk.ambushChance) then
		self:clearAmbushAreas(pPlayer)
		return false
	end

	self:setNumber(pPlayer, self.STATE_KEYS.ambushTriggered, 1)
	return true
end

function SmugglerDeliveryQuest:scheduleAmbushCleanup(pPlayer)
	local serial = self:getNumber(pPlayer, self.STATE_KEYS.ambushSerial) + 1
	self:setNumber(pPlayer, self.STATE_KEYS.ambushSerial, serial)
	createEvent(self.MAX_AMBUSH_DESPAWN_MS, self.screenplayName, "cleanupAmbush", pPlayer, tostring(serial))
end

function SmugglerDeliveryQuest:spawnAmbush(pPlayer)
	local destination = self:getDestination(self:getString(pPlayer, self.STATE_KEYS.destinationKey))

	if (destination == nil or destination.ambushTemplates == nil) then
		return
	end

	self:clearAmbushAreas(pPlayer)
	self:despawnAmbushMobiles(pPlayer)

	local count = getRandomNumber(2, 4)
	local spawned = 0
	local px = SceneObject(pPlayer):getWorldPositionX()
	local pz = SceneObject(pPlayer):getWorldPositionZ()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local playerId = self:getPlayerId(pPlayer)

	for i = 1, count, 1 do
		local template = destination.ambushTemplates[getRandomNumber(1, #destination.ambushTemplates)]
		local dx = getRandomNumber(-12, 12)
		local dy = getRandomNumber(-12, 12)
		local heading = getRandomNumber(0, 359)
		local pMobile = spawnMobile(destination.planet, template, 0, px + dx, pz, py + dy, heading, 0)

		if (pMobile ~= nil) then
			spawned = spawned + 1
			writeData(SceneObject(pMobile):getObjectID() .. ":SmugglerDeliveryQuest:ownerID", playerId)
			createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyAmbushMobileDestroyed", pMobile)
			self:setNumber(pPlayer, self.STATE_KEYS["ambushMob" .. tostring(spawned)], SceneObject(pMobile):getObjectID())
			AiAgent(pMobile):setDefender(pPlayer)
			SceneObject(pMobile):setCustomObjectName(destination.ambushName)
		end
	end

	if (spawned > 0) then
		CreatureObject(pPlayer):sendSystemMessage("Ambush triggered: hostile contacts are moving on your cargo.")
		self:scheduleAmbushCleanup(pPlayer)
	end
end

function SmugglerDeliveryQuest:notifyAmbushMobileDestroyed(pVictim, pAttacker)
	if (pVictim == nil) then
		return 0
	end

	local ownerId = tonumber(readData(SceneObject(pVictim):getObjectID() .. ":SmugglerDeliveryQuest:ownerID")) or 0

	if (ownerId <= 0) then
		return 0
	end

	local pPlayer = getSceneObject(ownerId)

	if (pPlayer == nil) then
		return 0
	end

	for i = 1, self.MAX_AMBUSH_MOBS, 1 do
		local key = self.STATE_KEYS["ambushMob" .. tostring(i)]

		if (self:getNumber(pPlayer, key) == SceneObject(pVictim):getObjectID()) then
			self:setNumber(pPlayer, key, 0)
		end
	end

	return 0
end

function SmugglerDeliveryQuest:cleanupAmbush(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial ~= self:getNumber(pPlayer, self.STATE_KEYS.ambushSerial)) then
		return 0
	end

	self:despawnAmbushMobiles(pPlayer)
	return 0
end

function SmugglerDeliveryQuest:notifyEnteredAmbushArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local ownerId = tonumber(readData(SceneObject(pArea):getObjectID() .. ":SmugglerDeliveryQuest:ownerID")) or 0

	if (ownerId ~= self:getPlayerId(pPlayer) or not self:isActive(pPlayer)) then
		return 0
	end

	if (self:rollAmbush(pPlayer)) then
		self:spawnAmbush(pPlayer)
	end

	return 0
end

function SmugglerDeliveryQuest:failMission(pPlayer, message, applyCooldown)
	if (pPlayer == nil) then
		return false
	end

	local missionId = self:getMissionId(pPlayer)

	if (missionId ~= "") then
		self:removeMissionDisk(pPlayer, missionId)
	end

	if (applyCooldown == true) then
		self:setNumber(pPlayer, self.STATE_KEYS.cooldownTime, self:getNow() + self.FAILURE_COOLDOWN_SECONDS)
	end

	self:setString(pPlayer, self.STATE_KEYS.lastFailureReason, message or "")
	self:resetMissionState(pPlayer)
	self:refreshObservers(pPlayer)

	if (message ~= nil and message ~= "") then
		CreatureObject(pPlayer):sendSystemMessage("Mission failure: " .. message)
	end

	return true
end

function SmugglerDeliveryQuest:validateActiveMission(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer)) then
		return false
	end

	if (self:isExpired(pPlayer)) then
		self:failMission(pPlayer, "Your contract expired before the handoff window closed.", true)
		return false
	end

	return true
end

function SmugglerDeliveryQuest:completeMission(pPlayer, receiverKey)
	if (pPlayer == nil) then
		return false, "No active smuggler was found."
	end

	if (not self:isActive(pPlayer)) then
		return false, "You do not have an active smuggling delivery."
	end

	if (self:isExpired(pPlayer)) then
		self:failMission(pPlayer, "Your cargo spoiled on the clock. The contract has expired.", true)
		return false, "Your contract expired before the handoff."
	end

	local missionDestination = self:getString(pPlayer, self.STATE_KEYS.destinationKey)

	if (receiverKey ~= missionDestination) then
		self:failMission(pPlayer, "Wrong receiver. The underworld heard about it immediately.", true)
		return false, "You approached the wrong contact. The run is burned."
	end

	local missionId = self:getMissionId(pPlayer)
	local pDisk = self:findMissionDisk(pPlayer, missionId)

	if (pDisk == nil) then
		self:failMission(pPlayer, "The sealed datadisk is missing. No cargo, no payment.", true)
		return false, "You no longer have the correct Sealed Smuggling Datadisk."
	end

	if (not self:hasInventorySpace(pPlayer)) then
		return false, "Free at least one inventory slot before I hand over your payment."
	end

	local risk = self:getRiskData(self:getString(pPlayer, self.STATE_KEYS.riskKey))

	if (risk == nil) then
		return false, "Your contract risk data is invalid."
	end

	local rewardOk, rewardReason = self:grantRewardItems(pPlayer, risk)

	if (not rewardOk) then
		return false, rewardReason
	end

	self:removeMissionDisk(pPlayer, missionId)
	self:setNumber(pPlayer, self.STATE_KEYS.cooldownTime, self:getNow() + self.SUCCESS_COOLDOWN_SECONDS)
	self:resetMissionState(pPlayer)
	self:refreshObservers(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Mission success: delivery confirmed and payment transferred.")

	return true, "Good. No one followed you.\n\nRewarded:\n" ..
		"- " .. tostring(risk.credits) .. " credits\n" ..
		"- " .. tostring(risk.tokens) .. " BG Tokens\n" ..
		"- 1 Holocron of Destiny\n\n" ..
		"Cooldown: " .. self:formatDurationWords(self.SUCCESS_COOLDOWN_SECONDS)
end

function SmugglerDeliveryQuest:missionHeartbeat(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer)) then
		return 0
	end

	if (not self:validateActiveMission(pPlayer)) then
		return 0
	end

	self:scheduleHeartbeat(pPlayer)
	return 0
end

function SmugglerDeliveryQuest:onLoggedIn(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer)) then
		return 0
	end

	if (not self:validateActiveMission(pPlayer)) then
		return 0
	end

	self:addDestinationWaypoint(pPlayer)
	self:rebuildAmbushAreas(pPlayer)
	self:refreshObservers(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Smuggler delivery restored. Check your waypoint and complete the drop before the timer expires.")
	return 0
end

VexTalonConvoHandler = conv_handler:new {}

function VexTalonConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	return LuaConversationTemplate(pConvTemplate):getScreen("vex_hub")
end

function VexTalonConvoHandler:cloneScreen(pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local pCloned = screen:cloneScreen()
	return pCloned, LuaConversationScreen(pCloned)
end

function VexTalonConvoHandler:sendResponse(pPlayer, clonedScreen, message)
	if (pPlayer ~= nil and message ~= nil and message ~= "") then
		for line in string.gmatch(message, "([^\n]+)") do
			if (line ~= "") then
				CreatureObject(pPlayer):sendSystemMessage(line)
			end
		end
	end

	clonedScreen:setCustomDialogText(message or "")
end

function VexTalonConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenId = screen:getScreenID()
	local pCloned, cloned = self:cloneScreen(pConvScreen)

	if (screenId == "vex_hub") then
		cloned:setCustomDialogText(SmugglerDeliveryQuest:getStatusLine(pPlayer))
		return pCloned
	end

	if (screenId == "vex_job") then
		self:sendResponse(pPlayer, cloned, "Take the disk. Make the drop. No questions.\n\nChoose your risk tier if you are ready.")
		return pCloned
	end

	if (screenId == "vex_low") then
		local _, message = SmugglerDeliveryQuest:startMission(pPlayer, "low")
		self:sendResponse(pPlayer, cloned, message)
		return pCloned
	end

	if (screenId == "vex_medium") then
		local _, message = SmugglerDeliveryQuest:startMission(pPlayer, "medium")
		self:sendResponse(pPlayer, cloned, message)
		return pCloned
	end

	if (screenId == "vex_high") then
		local _, message = SmugglerDeliveryQuest:startMission(pPlayer, "high")
		self:sendResponse(pPlayer, cloned, message)
		return pCloned
	end

	if (screenId == "vex_status") then
		self:sendResponse(pPlayer, cloned, SmugglerDeliveryQuest:getDeliveryStatusText(pPlayer))
		return pCloned
	end

	return pConvScreen
end
