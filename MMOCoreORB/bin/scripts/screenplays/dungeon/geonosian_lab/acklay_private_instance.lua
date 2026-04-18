AcklayPrivateInstance = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "AcklayPrivateInstance",

	planet = "yavin4",
	buildingId = 1627780,

	-- Edit this to change how long a player must wait before starting another run.
	cooldownSeconds = 86400, -- 24 hours

	-- Edit this to change the maximum duration of a single run.
	roomDurationMs = 30 * 60 * 1000, -- 30 minutes

	-- Edit this to change how long the player may loot after killing the Acklay.
	lootWindowMs = 120 * 1000, -- 120 seconds

	-- Edit this to change how long the system waits before failing a player that leaves a room.
	leaveCheckMs = 5000,

	-- Edit this to change how often room access/ownership is revalidated.
	roomValidationMs = 5000,

	-- Edit this if you want a different Acklay mobile template.
	acklayTemplate = "acklay",

	-- Outdoor spawn safety tuning.
	acklaySpawnHeightTolerance = 8,
	defaultAcklaySpawnOffsets = {
		{ x = 34, y = 0, heading = 180 },
		{ x = 26, y = 20, heading = -135 },
		{ x = 0, y = 34, heading = -90 },
		{ x = -26, y = 20, heading = -45 },
		{ x = -34, y = 0, heading = 0 },
		{ x = -26, y = -20, heading = 45 },
		{ x = 0, y = -34, heading = 90 },
		{ x = 26, y = -20, heading = 135 }
	},

	-- PUBLIC ENTRANCE / EXIT LOCATION
	-- Used for timeout ejections, completion ejections, login cleanup, and unauthorized entry removal.
	publicExit = {
		planet = "yavin4",
		x = -5.5,
		z = 10.8,
		y = 13.5,
		cell = 1627781
	},

	-- ENTRY NPC SPAWN
	-- Defaulted to the public exterior staging area so the keeper is not sharing a live dungeon combat cell.
	-- Edit these values if you want to move the keeper elsewhere.
	entryNpc = {
		template = "acklay_instance_keeper",
		customName = "Acklay Instance Keeper",
		planet = "yavin4",
		x = -6514.0,
		z = 85.0,
		y = -425.0,
		heading = 0,
		cell = 0,
		mood = "conversation"
	},

	-- ROOM CONFIGURATION
	-- Outdoor Yavin 4 pseudo-instance locations.
	-- These are intentionally spread into rough map quadrants so each player gets an isolated wild encounter.
	-- Edit these world coordinates to your preferred reserved outdoor positions.
	roomConfigs = {
		[1] = {
			label = "Acklay Wild Room NE",
			room = { planet = "yavin4", x = 4625.0, z = 78.0, y = -4380.0, cell = 0, heading = 180 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = 4625.0, z = 78.0, y = -4380.0, cell = 0, radius = 96 }
		},
		[2] = {
			label = "Acklay Wild Room NW",
			room = { planet = "yavin4", x = -4380.0, z = 92.0, y = -4275.0, cell = 0, heading = 90 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = -4380.0, z = 92.0, y = -4275.0, cell = 0, radius = 96 }
		},
		[3] = {
			label = "Acklay Wild Room SW",
			room = { planet = "yavin4", x = -4525.0, z = 67.0, y = 4310.0, cell = 0, heading = 0 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = -4525.0, z = 67.0, y = 4310.0, cell = 0, radius = 96 }
		},
		[4] = {
			label = "Acklay Wild Room SE",
			room = { planet = "yavin4", x = 4475.0, z = 70.0, y = 4185.0, cell = 0, heading = -90 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = 4475.0, z = 70.0, y = 4185.0, cell = 0, radius = 96 }
		},
		[5] = {
			label = "Acklay Wild Room NE 2",
			room = { planet = "yavin4", x = 4910.0, z = 81.0, y = -4045.0, cell = 0, heading = 135 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = 4910.0, z = 81.0, y = -4045.0, cell = 0, radius = 96 }
		},
		[6] = {
			label = "Acklay Wild Room NW 2",
			room = { planet = "yavin4", x = -4720.0, z = 94.0, y = -3955.0, cell = 0, heading = 45 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = -4720.0, z = 94.0, y = -3955.0, cell = 0, radius = 96 }
		},
		[7] = {
			label = "Acklay Wild Room SW 2",
			room = { planet = "yavin4", x = -4860.0, z = 69.0, y = 3985.0, cell = 0, heading = -45 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = -4860.0, z = 69.0, y = 3985.0, cell = 0, radius = 96 }
		},
		[8] = {
			label = "Acklay Wild Room SE 2",
			room = { planet = "yavin4", x = 4815.0, z = 73.0, y = 3875.0, cell = 0, heading = -135 },
			exit = { planet = "yavin4", x = -6514.0, z = 85.0, y = -425.0, cell = 0 },
			accessArea = { planet = "yavin4", x = 4815.0, z = 73.0, y = 3875.0, cell = 0, radius = 96 }
		}
	},

	rooms = {}
}

registerScreenPlay("AcklayPrivateInstance", true)

AcklayReturnTerminalMenuComponent = {}

function AcklayReturnTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(20, 3, "Return to Entrance")
end

function AcklayReturnTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (selectedID ~= 20 or pSceneObject == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local message = "The return terminal is unavailable."

	if (AcklayPrivateInstance ~= nil and AcklayPrivateInstance.handleReturnTerminalUse ~= nil) then
		message = AcklayPrivateInstance:handleReturnTerminalUse(pSceneObject, pPlayer)
	end

	if (message ~= nil and message ~= "") then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end

	return 0
end

function AcklayPrivateInstance:start()
	if (not isZoneEnabled(self.planet)) then
		return
	end

	self:initializeRooms()
	self:resetAllRooms()
	self:spawnRoomAccessAreas()
	self:spawnEntryNpc()
end

function AcklayPrivateInstance:initializeRooms()
	self.rooms = {}

	for roomId, config in pairs(self.roomConfigs) do
		local acklaySpawn = config.acklaySpawn or {
			planet = config.room.planet,
			x = config.room.x + 34,
			z = config.room.z,
			y = config.room.y,
			cell = config.room.cell,
			heading = 180
		}

		self.rooms[roomId] = {
			roomId = roomId,
			label = config.label or ("Acklay Room " .. roomId),
			status = "idle",
			ownerId = 0,
			acklayId = 0,
			returnNpcId = 0,
			startTime = 0,
			expireEvent = nil,
			complete = false,
			completeAt = 0,
			failureReason = "",
			areaId = 0,
			serial = 0,
			room = {
				planet = config.room.planet,
				x = config.room.x,
				z = config.room.z,
				y = config.room.y,
				cell = config.room.cell,
				heading = config.room.heading or 0
			},
			spawnOffsets = config.spawnOffsets or self.defaultAcklaySpawnOffsets,
			acklaySpawn = {
				planet = acklaySpawn.planet,
				x = acklaySpawn.x,
				z = acklaySpawn.z,
				y = acklaySpawn.y,
				cell = acklaySpawn.cell,
				heading = acklaySpawn.heading or 0
			},
			exit = {
				planet = config.exit.planet,
				x = config.exit.x,
				z = config.exit.z,
				y = config.exit.y,
				cell = config.exit.cell or 0
			},
			accessArea = {
				planet = config.accessArea.planet,
				x = config.accessArea.x,
				z = config.accessArea.z,
				y = config.accessArea.y,
				cell = config.accessArea.cell,
				radius = config.accessArea.radius or 24
			}
		}
	end
end

function AcklayPrivateInstance:shuffleArray(values)
	local copy = {}

	for i = 1, #values, 1 do
		copy[i] = values[i]
	end

	for i = #copy, 2, -1 do
		local swapIndex = getRandomNumber(1, i)
		copy[i], copy[swapIndex] = copy[swapIndex], copy[i]
	end

	return copy
end

function AcklayPrivateInstance:getGroundZ(point)
	if (point == nil) then
		return 0
	end

	if ((point.cell or 0) ~= 0) then
		return point.z
	end

	return getWorldFloor(point.x, point.y, point.planet)
end

function AcklayPrivateInstance:getAcklaySpawnCandidates(room)
	if (room == nil) then
		return {}
	end

	local candidates = {}
	local baseZ = self:getGroundZ(room.room)
	local offsets = room.spawnOffsets or self.defaultAcklaySpawnOffsets
	local shuffledOffsets = self:shuffleArray(offsets)

	for i = 1, #shuffledOffsets, 1 do
		local offset = shuffledOffsets[i]
		local candidate = {
			planet = room.room.planet,
			x = room.room.x + (offset.x or 0),
			y = room.room.y + (offset.y or 0),
			z = room.room.z,
			cell = room.room.cell or 0,
			heading = offset.heading or 0
		}

		candidate.z = self:getGroundZ(candidate)

		if ((candidate.cell or 0) ~= 0 or math.abs(candidate.z - baseZ) <= self.acklaySpawnHeightTolerance) then
			table.insert(candidates, candidate)
		end
	end

	table.insert(candidates, {
		planet = room.acklaySpawn.planet,
		x = room.acklaySpawn.x,
		y = room.acklaySpawn.y,
		z = self:getGroundZ(room.acklaySpawn),
		cell = room.acklaySpawn.cell or 0,
		heading = room.acklaySpawn.heading or 0
	})

	return candidates
end

function AcklayPrivateInstance:ensureRoomsReady()
	if (self.rooms == nil) then
		self:initializeRooms()
		return
	end

	for roomId, config in pairs(self.roomConfigs) do
		if (self.rooms[roomId] == nil) then
			self:initializeRooms()
			return
		end
	end
end

function AcklayPrivateInstance:getRoomDataKey(roomId, field)
	return self.screenplayName .. ":room:" .. tostring(roomId) .. ":" .. tostring(field)
end

function AcklayPrivateInstance:loadRoomState(roomId)
	self:ensureRoomsReady()

	local room = self.rooms[roomId]

	if (room == nil) then
		return nil
	end

	local status = readData(self:getRoomDataKey(roomId, "status"))
	if (status ~= nil and status ~= "" and status ~= 0 and status ~= "0") then
		room.status = tostring(status)
	end

	room.ownerId = tonumber(readData(self:getRoomDataKey(roomId, "ownerId"))) or room.ownerId or 0
	room.acklayId = tonumber(readData(self:getRoomDataKey(roomId, "acklayId"))) or room.acklayId or 0
	room.startTime = tonumber(readData(self:getRoomDataKey(roomId, "startTime"))) or room.startTime or 0
	room.complete = (tonumber(readData(self:getRoomDataKey(roomId, "complete"))) or 0) == 1
	room.completeAt = tonumber(readData(self:getRoomDataKey(roomId, "completeAt"))) or room.completeAt or 0
	room.serial = tonumber(readData(self:getRoomDataKey(roomId, "serial"))) or room.serial or 0

	local failureReason = readData(self:getRoomDataKey(roomId, "failureReason"))
	if (failureReason ~= nil) then
		room.failureReason = tostring(failureReason)
	end

	return room
end

function AcklayPrivateInstance:saveRoomState(roomId)
	local room = self.rooms[roomId]

	if (room == nil) then
		return
	end

	writeData(self:getRoomDataKey(roomId, "status"), room.status or "idle")
	writeData(self:getRoomDataKey(roomId, "ownerId"), room.ownerId or 0)
	writeData(self:getRoomDataKey(roomId, "acklayId"), room.acklayId or 0)
	writeData(self:getRoomDataKey(roomId, "startTime"), room.startTime or 0)
	writeData(self:getRoomDataKey(roomId, "complete"), room.complete and 1 or 0)
	writeData(self:getRoomDataKey(roomId, "completeAt"), room.completeAt or 0)
	writeData(self:getRoomDataKey(roomId, "serial"), room.serial or 0)
	writeData(self:getRoomDataKey(roomId, "failureReason"), room.failureReason or "")
end

function AcklayPrivateInstance:clearPersistedRoomState(roomId)
	deleteData(self:getRoomDataKey(roomId, "status"))
	deleteData(self:getRoomDataKey(roomId, "ownerId"))
	deleteData(self:getRoomDataKey(roomId, "acklayId"))
	deleteData(self:getRoomDataKey(roomId, "startTime"))
	deleteData(self:getRoomDataKey(roomId, "complete"))
	deleteData(self:getRoomDataKey(roomId, "completeAt"))
	deleteData(self:getRoomDataKey(roomId, "serial"))
	deleteData(self:getRoomDataKey(roomId, "failureReason"))
end

function AcklayPrivateInstance:spawnEntryNpc()
	local cfg = self.entryNpc
	local pNpc = spawnMobile(cfg.planet, cfg.template, 0, cfg.x, cfg.z, cfg.y, cfg.heading, cfg.cell)

	if (pNpc == nil) then
		return
	end

	local pAiAgent = AiAgent(pNpc)
	if (pAiAgent ~= nil) then
		pAiAgent:setConvoTemplate("acklay_instance_keeper_conv")
	end

	CreatureObject(pNpc):setCustomObjectName(cfg.customName)
	CreatureObject(pNpc):setMoodString(cfg.mood)
end

function AcklayPrivateInstance:spawnReturnNpcForRoom(roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.ownerId == 0) then
		return nil
	end

	if (room.returnNpcId ~= 0 and getSceneObject(room.returnNpcId) ~= nil) then
		return getSceneObject(room.returnNpcId)
	end

	local spawnX = room.room.x
	local spawnY = room.room.y
	local spawnZ = room.room.z
	local pOwner = getSceneObject(room.ownerId)

	if (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature()) then
		spawnX = SceneObject(pOwner):getWorldPositionX()
		spawnY = SceneObject(pOwner):getWorldPositionY()

		if ((room.room.cell or 0) == 0) then
			spawnZ = getWorldFloor(spawnX, spawnY, room.room.planet)
		else
			spawnZ = SceneObject(pOwner):getWorldPositionZ()
		end
	end

	local pNpc = spawnSceneObject(room.room.planet, "object/tangible/terminal/terminal_mission_newbie.iff", spawnX, spawnZ, spawnY, room.room.cell or 0, 0)

	if (pNpc == nil) then
		return nil
	end

	SceneObject(pNpc):setCustomObjectName("Acklay Return Terminal")
	SceneObject(pNpc):setObjectMenuComponent("AcklayReturnTerminalMenuComponent")

	room.returnNpcId = SceneObject(pNpc):getObjectID()
	self:saveRoomState(roomId)
	writeData(room.returnNpcId .. ":AcklayPrivateInstance:returnRoomId", roomId)
	return pNpc
end

function AcklayPrivateInstance:spawnRoomAccessAreas()
	for roomId, room in pairs(self.rooms) do
		local pArea = spawnActiveArea(room.accessArea.planet, "object/active_area.iff", room.accessArea.x, room.accessArea.z, room.accessArea.y, room.accessArea.radius, room.accessArea.cell)

		if (pArea ~= nil) then
			room.areaId = SceneObject(pArea):getObjectID()
			writeData(room.areaId .. ":AcklayPrivateInstance:roomId", roomId)
			createObserver(ENTEREDAREA, self.screenplayName, "notifyEnteredRoomArea", pArea)
			createObserver(EXITEDAREA, self.screenplayName, "notifyExitedRoomArea", pArea)
		end
	end
end

function AcklayPrivateInstance:getPlayerDataNumber(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, self.screenplayName, key)) or 0
end

function AcklayPrivateInstance:setPlayerDataNumber(pPlayer, key, value)
	writeScreenPlayData(pPlayer, self.screenplayName, key, value)
end

function AcklayPrivateInstance:clearPlayerData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	self:setPlayerDataNumber(pPlayer, "activeRoom", 0)
	self:setPlayerDataNumber(pPlayer, "instanceStart", 0)
	self:setPlayerDataNumber(pPlayer, "loggedOutInside", 0)

	dropObserver(OBJECTDESTRUCTION, self.screenplayName, "handlePlayerDeath", pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "handlePlayerKilledCreature", pPlayer)
end

function AcklayPrivateInstance:getRoomByCell(cellId)
	if (cellId == nil or tonumber(cellId) == nil or tonumber(cellId) == 0) then
		return 0
	end

	for roomId, room in pairs(self.rooms) do
		if (room.room.cell == cellId) then
			return roomId
		end
	end

	return 0
end

function AcklayPrivateInstance:isPlayerWithinRoomBounds(pPlayer, roomId)
	local room = self.rooms[roomId]

	if (pPlayer == nil or room == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	if (SceneObject(pPlayer):getZoneName() ~= room.room.planet) then
		return false
	end

	local playerParent = SceneObject(pPlayer):getParentID()
	local roomCell = room.room.cell or 0

	if (roomCell ~= 0) then
		return playerParent == roomCell
	end

	if (playerParent ~= 0) then
		return false
	end

	local distance = SceneObject(pPlayer):getDistanceToPosition(room.accessArea.x, room.accessArea.z, room.accessArea.y)
	return distance <= (room.accessArea.radius or 0)
end

function AcklayPrivateInstance:getRoomContainingPlayer(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	for roomId, room in pairs(self.rooms) do
		if (room ~= nil and self:isPlayerWithinRoomBounds(pPlayer, roomId)) then
			return roomId
		end
	end

	return 0
end

function AcklayPrivateInstance:getRoomEventData(eventData)
	if (type(eventData) == "number") then
		return eventData, nil
	end

	local eventString = tostring(eventData or "")
	local split = string.find(eventString, ":")

	if (split == nil) then
		return tonumber(eventString) or 0, nil
	end

	local roomId = tonumber(string.sub(eventString, 1, split - 1)) or 0
	local serial = tonumber(string.sub(eventString, split + 1))

	return roomId, serial
end

function AcklayPrivateInstance:formatCooldown(secondsRemaining)
	local total = math.max(0, tonumber(secondsRemaining) or 0)
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local seconds = total % 60
	local parts = {}

	if (hours > 0) then
		table.insert(parts, hours .. "h")
	end

	if (minutes > 0) then
		table.insert(parts, minutes .. "m")
	end

	if (#parts == 0 or seconds > 0) then
		table.insert(parts, seconds .. "s")
	end

	return table.concat(parts, " ")
end

function AcklayPrivateInstance:getAvailableRoom()
	self:ensureRoomsReady()

	for roomId, room in pairs(self.rooms) do
		room = self:loadRoomState(roomId)
		if (room ~= nil and room.status == "idle" and room.ownerId == 0 and room.acklayId == 0) then
			return roomId
		end
	end

	return 0
end

function AcklayPrivateInstance:isPlayerOnCooldown(pPlayer)
	return self:getCooldownRemaining(pPlayer) > 0
end

function AcklayPrivateInstance:getCooldownRemaining(pPlayer)
	if ((tonumber(self.cooldownSeconds) or 0) <= 0) then
		if (pPlayer ~= nil) then
			self:setPlayerDataNumber(pPlayer, "cooldownEnd", 0)
		end
		return 0
	end

	local cooldownEnd = self:getPlayerDataNumber(pPlayer, "cooldownEnd")

	if (cooldownEnd <= 0) then
		return 0
	end

	local remaining = cooldownEnd - os.time()

	if (remaining <= 0) then
		self:setPlayerDataNumber(pPlayer, "cooldownEnd", 0)
		return 0
	end

	return remaining
end

function AcklayPrivateInstance:setPlayerCooldown(pPlayer)
	if ((tonumber(self.cooldownSeconds) or 0) <= 0) then
		self:setPlayerDataNumber(pPlayer, "cooldownEnd", 0)
		return
	end

	self:setPlayerDataNumber(pPlayer, "cooldownEnd", os.time() + self.cooldownSeconds)
end

function AcklayPrivateInstance:canPlayerEnter(pPlayer)
	self:ensureRoomsReady()

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false, "invalid", "You must be a valid player character to enter."
	end

	if (CreatureObject(pPlayer):isDead() or CreatureObject(pPlayer):isIncapacitated()) then
		return false, "dead", "You must be alive and standing before you can enter the Acklay instance."
	end

	if (CreatureObject(pPlayer):isInCombat()) then
		return false, "combat", "You cannot enter while in combat."
	end

	if (self:isPlayerInsideManagedRoom(pPlayer)) then
		return false, "inside", "You are already inside an active Acklay instance."
	end

	local activeRoom = self:getRoomByPlayer(pPlayer)

	if (activeRoom ~= 0) then
		return false, "active", "You already own an active Acklay instance room."
	end

	if (self:isPlayerOnCooldown(pPlayer)) then
		return false, "cooldown", "You must wait " .. self:formatCooldown(self:getCooldownRemaining(pPlayer)) .. " before entering again."
	end

	local roomId = self:getAvailableRoom()

	if (roomId == 0) then
		return false, "full", "All private Acklay rooms are currently occupied. Please try again later."
	end

	return true, roomId, "A private Acklay room is available."
end

function AcklayPrivateInstance:assignRoomToPlayer(pPlayer, roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "idle") then
		return false
	end

	room.serial = room.serial + 1
	room.status = "active"
	room.ownerId = SceneObject(pPlayer):getObjectID()
	room.acklayId = 0
	room.startTime = os.time()
	room.expireEvent = room.serial
	room.complete = false
	room.completeAt = 0
	room.failureReason = ""
	self:saveRoomState(roomId)

	self:setPlayerDataNumber(pPlayer, "activeRoom", roomId)
	self:setPlayerDataNumber(pPlayer, "instanceStart", room.startTime)
	self:setPlayerDataNumber(pPlayer, "loggedOutInside", 0)

	dropObserver(OBJECTDESTRUCTION, self.screenplayName, "handlePlayerDeath", pPlayer)
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "handlePlayerDeath", pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "handlePlayerKilledCreature", pPlayer)
	createObserver(KILLEDCREATURE, self.screenplayName, "handlePlayerKilledCreature", pPlayer)

	return true
end

function AcklayPrivateInstance:teleportCreature(pCreature, point)
	if (pCreature == nil or point == nil) then
		return false
	end

	local destX = point.x
	local destZ = point.z
	local destY = point.y
	local destCell = point.cell or 0

	if (destCell == 0) then
		destZ = getWorldFloor(destX, destY, point.planet)
	end

	if (SceneObject(pCreature):getZoneName() ~= point.planet) then
		SceneObject(pCreature):switchZone(point.planet, destX, destZ, destY, destCell)
	else
		SceneObject(pCreature):teleport(destX, destZ, destY, destCell)
	end

	if (destCell == 0) then
		createEvent(500, self.screenplayName, "stabilizeOutdoorTeleport", pCreature, point.planet .. "|" .. tostring(destX) .. "|" .. tostring(destY))
	end

	return true
end

function AcklayPrivateInstance:stabilizeOutdoorTeleport(pCreature, eventData)
	if (pCreature == nil or not SceneObject(pCreature):isPlayerCreature()) then
		return 0
	end

	local data = tostring(eventData or "")
	local first = string.find(data, "|")
	local second = first and string.find(data, "|", first + 1) or nil

	if (first == nil or second == nil) then
		return 0
	end

	local planet = string.sub(data, 1, first - 1)
	local x = tonumber(string.sub(data, first + 1, second - 1)) or 0
	local y = tonumber(string.sub(data, second + 1)) or 0

	if (SceneObject(pCreature):getZoneName() ~= planet) then
		return 0
	end

	SceneObject(pCreature):teleport(x, getWorldFloor(x, y, planet), y, 0)

	return 0
end

function AcklayPrivateInstance:teleportPlayerToRoom(pPlayer, roomId)
	local room = self.rooms[roomId]

	if (room == nil) then
		return false
	end

	return self:teleportCreature(pPlayer, room.room)
end

function AcklayPrivateInstance:spawnAcklayForRoom(roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return nil
	end

	if (room.acklayId ~= 0 and getSceneObject(room.acklayId) ~= nil) then
		return getSceneObject(room.acklayId)
	end

	local pAcklay = nil
	local spawnPoint = nil
	local candidates = self:getAcklaySpawnCandidates(room)

	for i = 1, #candidates, 1 do
		local candidate = candidates[i]
		pAcklay = spawnMobile(candidate.planet, self.acklayTemplate, 0, candidate.x, candidate.z, candidate.y, candidate.heading, candidate.cell)

		if (pAcklay ~= nil) then
			spawnPoint = candidate
			break
		end
	end

	if (pAcklay == nil) then
		self:failRoom(roomId, "The Acklay could not be spawned for your private run.")
		return nil
	end

	room.acklayId = SceneObject(pAcklay):getObjectID()
	self:saveRoomState(roomId)
	writeData(room.acklayId .. ":AcklayPrivateInstance:roomId", roomId)

	createObserver(OBJECTDESTRUCTION, self.screenplayName, "onAcklayKilled", pAcklay)

	local pCreature = CreatureObject(pAcklay)
	if (pCreature ~= nil and pCreature.setHomeLocation ~= nil) then
		pcall(function()
			pCreature:setHomeLocation(spawnPoint.x, spawnPoint.z, spawnPoint.y, math.max(24, room.accessArea.radius))
		end)
	end

	return pAcklay
end

function AcklayPrivateInstance:startRoomTimer(roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return
	end

	createEvent(self.roomDurationMs, self.screenplayName, "onRoomExpired", nil, roomId)
	createEvent(self.roomValidationMs, self.screenplayName, "validateActiveRoom", nil, roomId)
end

function AcklayPrivateInstance:onRoomExpired(pObject, eventData)
	local roomId, serial = self:getRoomEventData(eventData)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return 0
	end

	if (serial ~= nil and serial ~= room.serial) then
		return 0
	end

	self:failRoom(roomId, "Your 30 minute Acklay instance timer has expired.")

	return 0
end

function AcklayPrivateInstance:validateActiveRoom(pObject, eventData)
	local roomId, serial = self:getRoomEventData(eventData)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return 0
	end

	if (serial ~= nil and serial ~= room.serial) then
		return 0
	end

	local pOwner = getSceneObject(room.ownerId)

	if (pOwner == nil or not SceneObject(pOwner):isPlayerCreature()) then
		self:cleanupRoom(roomId)
		return 0
	end

	if (room.acklayId ~= 0) then
		local pAcklay = getSceneObject(room.acklayId)

		if (pAcklay == nil) then
			room.acklayId = 0
			self:saveRoomState(roomId)
			self:completeRoom(roomId)
			return 0
		end

		local acklay = CreatureObject(pAcklay)

		if (acklay ~= nil and (acklay:isDead() or acklay:isIncapacitated())) then
			room.acklayId = 0
			self:saveRoomState(roomId)
			self:completeRoom(roomId)
			return 0
		end
	end

	if (not self:validateRoomAccess(pOwner)) then
		return 0
	end

	createEvent(self.roomValidationMs, self.screenplayName, "validateActiveRoom", nil, roomId)

	return 0
end

function AcklayPrivateInstance:onAcklayKilled(pCreature, pKiller, roomId)
	local resolvedRoomId = tonumber(roomId) or tonumber(readData(SceneObject(pCreature):getObjectID() .. ":AcklayPrivateInstance:roomId")) or 0
	local room = self:loadRoomState(resolvedRoomId)

	if (room == nil) then
		return 0
	end

	if (room.status ~= "active" or room.ownerId == 0) then
		return 1
	end

	local pOwner = getSceneObject(room.ownerId)

	if (pOwner == nil or not SceneObject(pOwner):isPlayerCreature()) then
		self:cleanupRoom(resolvedRoomId)
		return 1
	end

	room.acklayId = 0
	self:saveRoomState(resolvedRoomId)
	self:completeRoom(resolvedRoomId)

	return 1
end

function AcklayPrivateInstance:handlePlayerKilledCreature(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId = self:getRoomByPlayer(pPlayer)

	if (roomId == 0) then
		return 0
	end

	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active" or room.acklayId == 0) then
		return 0
	end

	if (SceneObject(pVictim):getObjectID() ~= room.acklayId) then
		return 0
	end

	room.acklayId = 0
	self:saveRoomState(roomId)
	self:completeRoom(roomId)

	return 0
end

function AcklayPrivateInstance:completeRoom(roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return false
	end

	room.status = "complete"
	room.complete = true
	room.completeAt = os.time() + math.max(1, math.floor(self.lootWindowMs / 1000))
	room.failureReason = ""
	self:saveRoomState(roomId)

	local pOwner = getSceneObject(room.ownerId)
	if (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature()) then
		CreatureObject(pOwner):sendSystemMessage("The Acklay has been defeated. You have 120 seconds to loot before you are returned to the entrance.")
	end

	createEvent(self.lootWindowMs, self.screenplayName, "finalizeCompletedRoom", nil, roomId)
	createEvent(5000, self.screenplayName, "pollCompletedRoom", nil, roomId)

	return true
end

function AcklayPrivateInstance:pollCompletedRoom(pObject, eventData)
	local roomId, serial = self:getRoomEventData(eventData)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "complete") then
		return 0
	end

	if (serial ~= nil and serial ~= room.serial) then
		return 0
	end

	if ((room.completeAt or 0) <= os.time()) then
		self:ejectPlayerFromRoom(roomId, "Your Acklay run is complete. You are being returned to the entrance.")
		self:cleanupRoom(roomId)
		return 0
	end

	createEvent(5000, self.screenplayName, "pollCompletedRoom", nil, roomId)

	return 0
end

function AcklayPrivateInstance:finalizeCompletedRoom(pObject, eventData)
	local roomId, serial = self:getRoomEventData(eventData)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "complete") then
		return 0
	end

	if (serial ~= nil and serial ~= room.serial) then
		return 0
	end

	self:ejectPlayerFromRoom(roomId, "Your Acklay run is complete. You are being returned to the entrance.")
	self:cleanupRoom(roomId)

	return 0
end

function AcklayPrivateInstance:failRoom(roomId, reason)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status == "idle") then
		return false
	end

	room.status = "failed"
	room.complete = false
	room.completeAt = 0
	room.failureReason = reason or "Your Acklay run has failed."
	self:saveRoomState(roomId)

	local pOwner = getSceneObject(room.ownerId)
	if (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature()) then
		CreatureObject(pOwner):sendSystemMessage(room.failureReason)
	end

	self:ejectPlayerFromRoom(roomId, room.failureReason)
	self:cleanupRoom(roomId)

	return true
end

function AcklayPrivateInstance:ejectPlayerFromRoom(roomId, message)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.ownerId == 0) then
		return false
	end

	local pPlayer = getSceneObject(room.ownerId)

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	if (CreatureObject(pPlayer):isDead() or CreatureObject(pPlayer):isIncapacitated()) then
		return false
	end

	if (message ~= nil and message ~= "") then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end

	return self:teleportCreature(pPlayer, room.exit or self.publicExit)
end

function AcklayPrivateInstance:destroySceneObjectById(objectId)
	if (objectId == nil or tonumber(objectId) == nil or tonumber(objectId) == 0) then
		return
	end

	local pObject = getSceneObject(tonumber(objectId))

	if (pObject ~= nil) then
		pcall(function()
			SceneObject(pObject):destroyObjectFromWorld()
		end)
		pcall(function()
			SceneObject(pObject):destroyObjectFromDatabase()
		end)
	end
end

function AcklayPrivateInstance:cleanupRoom(roomId)
	local room = self:loadRoomState(roomId)

	if (room == nil) then
		return false
	end

	if (room.acklayId ~= 0) then
		deleteData(room.acklayId .. ":AcklayPrivateInstance:roomId")
		self:destroySceneObjectById(room.acklayId)
	end

	local pOwner = nil
	if (room.ownerId ~= 0) then
		pOwner = getSceneObject(room.ownerId)
	end

	if (room.returnNpcId ~= 0) then
		deleteData(room.returnNpcId .. ":AcklayPrivateInstance:returnRoomId")
		self:destroySceneObjectById(room.returnNpcId)
	end

	if (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature()) then
		self:clearPlayerData(pOwner)
	end

	room.status = "idle"
	room.ownerId = 0
	room.acklayId = 0
	room.returnNpcId = 0
	room.startTime = 0
	room.expireEvent = nil
	room.complete = false
	room.completeAt = 0
	room.failureReason = ""
	self:saveRoomState(roomId)

	return true
end

function AcklayPrivateInstance:resetAllRooms()
	for roomId, room in pairs(self.rooms) do
		self:clearPersistedRoomState(roomId)

		if (room.areaId ~= 0) then
			writeData(room.areaId .. ":AcklayPrivateInstance:roomId", roomId)
		end

		room.status = "idle"
		room.ownerId = 0
		room.acklayId = 0
		room.returnNpcId = 0
		room.startTime = 0
		room.expireEvent = nil
		room.complete = false
		room.completeAt = 0
		room.failureReason = ""
		room.serial = room.serial + 1
		self:saveRoomState(roomId)
	end
end

function AcklayPrivateInstance:isPlayerInsideSpecificRoom(pPlayer, roomId)
	return self:isPlayerWithinRoomBounds(pPlayer, roomId)
end

function AcklayPrivateInstance:isPlayerInsideManagedRoom(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	return self:getRoomContainingPlayer(pPlayer) ~= 0
end

function AcklayPrivateInstance:getRoomByPlayer(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local playerId = SceneObject(pPlayer):getObjectID()

	for roomId, room in pairs(self.rooms) do
		if (room.ownerId == playerId and room.status ~= "idle") then
			return roomId
		end
	end

	local storedRoom = self:getPlayerDataNumber(pPlayer, "activeRoom")
	if (storedRoom ~= 0 and self.rooms[storedRoom] ~= nil and self.rooms[storedRoom].ownerId == playerId) then
		return storedRoom
	end

	return 0
end

function AcklayPrivateInstance:validateRoomAccess(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return false
	end

	local roomId = self:getRoomContainingPlayer(pPlayer)

	if (roomId == 0) then
		return true
	end

	local room = self:loadRoomState(roomId)
	local playerId = SceneObject(pPlayer):getObjectID()
	local playerAssignedRoom = self:getPlayerDataNumber(pPlayer, "activeRoom")

	if (room == nil) then
		return true
	end

	if (room.status == "active" and room.ownerId == playerId) then
		return true
	end

	if (playerAssignedRoom == roomId) then
		if (room.ownerId == 0 or room.ownerId ~= playerId) then
			room.ownerId = playerId
			if (room.status == "idle") then
				room.status = "active"
			end
			self:saveRoomState(roomId)
		end

		return true
	end

	CreatureObject(pPlayer):sendSystemMessage("This Acklay room is reserved for another player. You are being returned to the entrance.")
	self:teleportCreature(pPlayer, self.publicExit)

	return false
end

function AcklayPrivateInstance:notifyEnteredRoomArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	self:validateRoomAccess(pPlayer)

	return 0
end

function AcklayPrivateInstance:notifyExitedRoomArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId = tonumber(readData(SceneObject(pArea):getObjectID() .. ":AcklayPrivateInstance:roomId")) or 0
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return 0
	end

	if (room.ownerId ~= SceneObject(pPlayer):getObjectID()) then
		return 0
	end

	createEvent(self.leaveCheckMs, self.screenplayName, "checkOwnerStillInsideRoom", pPlayer, roomId)

	return 0
end

function AcklayPrivateInstance:checkOwnerStillInsideRoom(pPlayer, eventData)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId, serial = self:getRoomEventData(eventData)
	local room = self:loadRoomState(roomId)

	if (room == nil or room.status ~= "active") then
		return 0
	end

	if (serial ~= nil and serial ~= room.serial) then
		return 0
	end

	if (room.ownerId ~= SceneObject(pPlayer):getObjectID()) then
		return 0
	end

	if (not self:isPlayerInsideSpecificRoom(pPlayer, roomId)) then
		self:failRoom(roomId, "You left your reserved Acklay room, so the run has been marked as failed.")
	end

	return 0
end

function AcklayPrivateInstance:handleConversationEntryRequest(pPlayer)
	self:ensureRoomsReady()
	local canEnter, resultCode, message = self:canPlayerEnter(pPlayer)

	if (not canEnter) then
		if (pPlayer ~= nil and message ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage(message)
		end
		return message or "You cannot enter the Acklay instance right now."
	end

	local roomId = tonumber(resultCode) or 0

	if (roomId == 0) then
		return "No private Acklay room is currently available."
	end

	self:setPlayerCooldown(pPlayer)

	if (not self:assignRoomToPlayer(pPlayer, roomId)) then
		return "Failed to reserve a private Acklay room. Please try again."
	end

	if (not self:teleportPlayerToRoom(pPlayer, roomId)) then
		self:cleanupRoom(roomId)
		return "Failed to move you into the private Acklay room."
	end

	if (self:spawnAcklayForRoom(roomId) == nil) then
		return "Failed to start the private Acklay encounter."
	end

	self:spawnReturnNpcForRoom(roomId)

	self:startRoomTimer(roomId)
	CreatureObject(pPlayer):sendSystemMessage("You have 30 minutes to defeat the Acklay. Logging out, dying, or leaving the room will fail the run.")

	return "Your private Acklay challenge has begun."
end

function AcklayPrivateInstance:handleReturnTerminalUse(pTerminal, pPlayer)
	if (pTerminal == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return "You cannot use this terminal right now."
	end

	local roomId = tonumber(readData(SceneObject(pTerminal):getObjectID() .. ":AcklayPrivateInstance:returnRoomId")) or 0

	if (roomId == 0) then
		roomId = self:getRoomByPlayer(pPlayer)
	end

	if (roomId == 0) then
		roomId = self:getRoomContainingPlayer(pPlayer)
	end

	if (roomId == 0) then
		createEvent(250, self.screenplayName, "finishReturnTerminalUse", pPlayer, "0")
		return "You are being returned to the entrance."
	end

	createEvent(250, self.screenplayName, "finishReturnTerminalUse", pPlayer, tostring(roomId))
	return "You are being returned to the entrance."
end

function AcklayPrivateInstance:finishReturnTerminalUse(pPlayer, eventData)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId = tonumber(eventData) or 0

	SceneObject(pPlayer):switchZone(self.publicExit.planet, self.publicExit.x, self.publicExit.z, self.publicExit.y, self.publicExit.cell or 0)

	if (roomId ~= 0) then
		self:cleanupRoom(roomId)
	end

	return 0
end

function AcklayPrivateInstance:handlePlayerLogin(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId = self:getRoomByPlayer(pPlayer)

	if (roomId ~= 0 and self.rooms[roomId] ~= nil and self.rooms[roomId].status ~= "idle") then
		self:cleanupRoom(roomId)
	end

	if (self:isPlayerInsideManagedRoom(pPlayer) or self:getPlayerDataNumber(pPlayer, "loggedOutInside") == 1) then
		self:teleportCreature(pPlayer, self.publicExit)
		CreatureObject(pPlayer):sendSystemMessage("You were returned to the Acklay entrance because logging out inside a private run is not allowed.")
	end

	self:clearPlayerData(pPlayer)

	return 0
end

function AcklayPrivateInstance:handlePlayerDeath(pPlayer, pKiller)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local roomId = self:getRoomByPlayer(pPlayer)

	if (roomId == 0) then
		roomId = self:getPlayerDataNumber(pPlayer, "activeRoom")
	end

	if (roomId ~= 0) then
		self:failRoom(roomId, "You were defeated during the Acklay challenge.")
	end

	return 1
end

function AcklayPrivateInstance:onPlayerLoggedOut(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local roomId = self:getRoomByPlayer(pPlayer)

	if (roomId == 0 and not self:isPlayerInsideManagedRoom(pPlayer)) then
		return
	end

	self:setPlayerDataNumber(pPlayer, "loggedOutInside", 1)

	if (roomId ~= 0) then
		self:cleanupRoom(roomId)
	end
end
