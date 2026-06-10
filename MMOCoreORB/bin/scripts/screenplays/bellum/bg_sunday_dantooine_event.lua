BgSundayDantooineEvent = ScreenPlay:new {
	screenplayName = "BgSundayDantooineEvent",
	numberOfActs = 1,
}

registerScreenPlay("BgSundayDantooineEvent", true)

BgSundayDantooineEvent.CONFIG = {
	debugEnabled = true,
	debugForceStarterOnBoot = false,
	debugIgnoreSchedule = false,
	scheduleMode = "absolute", -- "weekly" or "absolute"
	planet = "naboo",
	activeDay = "sunday",
	activeHour = 1,
	activeMinute = 0,
	activeSecond = 0,
	absoluteStartDate = {
		year = 2026,
		month = 6,
		day = 14,
		hour = 18,
		minute = 0,
		second = 0,
	},
	schedulerIntervalMs = 60 * 1000,
	checkpointPollIntervalMs = 5 * 1000,
	starterWindowSeconds = 1 * 60 * 60,
	rewardRadius = 128,
	totalCheckpoints = 8,
	allowDuplicateBossesPerRun = false,
	allowLateJoinerRewards = true,
	enableInactivityFail = false,
	inactivityFailSeconds = 90 * 60,
	starter = {
		template = "object/tangible/terminal/terminal_mission.iff",
		name = "Bellum Gero Sunday Operations Terminal",
		planet = "naboo",
		x = 227,
		y = 5436,
		heading = 0,
	},
	messages = {
		starterSpawned = "\\#FFCC66Bellum Gero Sunday Event: the operations terminal is now active on Naboo.",
		runStarted = "\\#FFCC66Sunday run begun. Move to the first ambush point and stay with your group.",
		ambush = "\\#FF6600Ambush! A hostile world boss is closing on your position.",
		checkpointComplete = "\\#66FF66Checkpoint secured.",
		nextWaypoint = "\\#FFCC66New waypoint uploaded. Advance to the next ambush sector.",
		finalVictory = "\\#66FF66The Sunday run is complete. Naboo is secure for this week.",
		alreadyStarted = "This Sunday's run is already underway.",
		runComplete = "This Sunday's run has already been completed.",
		ungrouped = "You must be grouped to activate the Sunday run.",
		notLeader = "Only the current group leader can activate the Sunday run.",
		recommendedSize = "Recommended group size for this run is 10 to 20 players.",
		timeout = "\\#FF3300The Sunday run has gone stale and has been locked for the remainder of this week's window.",
	},
	checkpoints = {
		{
			name = "Western Staging Point",
			trigger = { x = -650, z = 0, y = 5436, radius = 96 },
			spawn = { x = -730, z = 0, y = 5506, heading = 90 },
			waypointName = "Sunday Ambush 1",
			waypointDesc = "Head west to the first Naboo ambush point.",
		},
		{
			name = "Naboo Western Flats",
			trigger = { x = -1500, z = 0, y = 5436, radius = 96 },
			spawn = { x = -1580, z = 0, y = 5366, heading = 90 },
			waypointName = "Sunday Ambush 2",
			waypointDesc = "Continue west across the Naboo flats.",
		},
		{
			name = "Royal Grassland Cutoff",
			trigger = { x = -2350, z = 0, y = 5436, radius = 96 },
			spawn = { x = -2430, z = 0, y = 5506, heading = 90 },
			waypointName = "Sunday Ambush 3",
			waypointDesc = "Keep west to the Royal Grassland Cutoff.",
		},
		{
			name = "Lake Country Approach",
			trigger = { x = -3200, z = 0, y = 5436, radius = 96 },
			spawn = { x = -3280, z = 0, y = 5366, heading = 90 },
			waypointName = "Sunday Ambush 4",
			waypointDesc = "Push west to the Lake Country Approach.",
		},
		{
			name = "Western Lake Verge",
			trigger = { x = -4050, z = 0, y = 5436, radius = 96 },
			spawn = { x = -4130, z = 0, y = 5506, heading = 90 },
			waypointName = "Sunday Ambush 5",
			waypointDesc = "Advance west to the Western Lake Verge.",
		},
		{
			name = "Naboo Lowland Trail",
			trigger = { x = -4900, z = 0, y = 5436, radius = 96 },
			spawn = { x = -4980, z = 0, y = 5366, heading = 90 },
			waypointName = "Sunday Ambush 6",
			waypointDesc = "Cross west along the Naboo Lowland Trail.",
		},
		{
			name = "Western Wilds",
			trigger = { x = -5750, z = 0, y = 5436, radius = 96 },
			spawn = { x = -5830, z = 0, y = 5506, heading = 90 },
			waypointName = "Sunday Ambush 7",
			waypointDesc = "Breach west into the Western Wilds.",
		},
		{
			name = "Far Western Breach",
			trigger = { x = -6600, z = 0, y = 5436, radius = 96 },
			spawn = { x = -6680, z = 0, y = 5366, heading = 90 },
			waypointName = "Sunday Ambush 8",
			waypointDesc = "Hold the Far Western Breach and finish the run.",
		},
	},
	bossPool = {
		{ template = "acklay_worldboss", name = "Acklay Brood Tyrant" },
		{ template = "torgas_the_enslaver", name = "Torgas the Enslaver" },
		{ template = "enhanced_gaping_spider_boss", name = "Enhanced Gaping Spider" },
		{ template = "peko_peko_infernomaw", name = "Infernomaw" },
		{ template = "boss_grakk_na_joor", name = "Grakk Na'joor" },
		{ template = "boss_vreego_makk_tarn", name = "Vreego Makk Tarn" },
		{ template = "boss_rulo_besh_ka", name = "Rulo Besh-Ka" },
		{ template = "boss_tarko_muu_zenn", name = "Tarko Muu Zenn" },
		{ template = "the_hand", name = "The Hand" },
	},
	rewardPool = {
		{ group = "event", weight = 4000000 },
		{ group = "armor_attachments", weight = 1500000 },
		{ group = "clothing_attachments", weight = 1500000 },
		{ group = "event_rare", weight = 900000 },
		{ group = "event_epic", weight = 250000 },
		{ group = "endgame_weapon_schematics", weight = 350000 },
		{ group = "bg_token_group", weight = 1500000 },
	},
}

BgSundayDantooineEvent.DATA = {
	starterObjectId = "bg_sunday_event:starterObjectId",
	starterSpawned = "bg_sunday_event:starterSpawned",
	activeRunStamp = "bg_sunday_event:activeRunStamp",
	completedRunStamp = "bg_sunday_event:completedRunStamp",
	expiredRunStamp = "bg_sunday_event:expiredRunStamp",
	eventStarted = "bg_sunday_event:eventStarted",
	finalEventComplete = "bg_sunday_event:finalEventComplete",
	activeGroupId = "bg_sunday_event:activeGroupId",
	activeLeaderId = "bg_sunday_event:activeLeaderId",
	currentCheckpoint = "bg_sunday_event:currentCheckpoint",
	activeBossId = "bg_sunday_event:activeBossId",
	activeBossCheckpoint = "bg_sunday_event:activeBossCheckpoint",
	activeBossCleanup = "bg_sunday_event:activeBossCleanup",
	lastActivityAt = "bg_sunday_event:lastActivityAt",
	memberCount = "bg_sunday_event:memberCount",
}

BgSundayDantooineEvent.runtime = {
	checkpointAreaIds = {},
	usedBossTemplates = {},
}

local function bgSundayNow()
	return os.time()
end

local function bgSundayNum(value, fallback)
	local number = tonumber(value)
	if (number == nil) then
		return fallback
	end

	return number
end

local function bgSundayClampSeconds(seconds)
	local value = tonumber(seconds) or 1

	if (value < 1) then
		value = 1
	end

	return math.floor(value)
end

local function bgSundayTryBroadcast(msg)
	if (msg == nil or msg == "") then
		return
	end

	if (type(broadcastMessage) == "function") then
		pcall(broadcastMessage, msg)
	elseif (type(broadcastToGalaxy) == "function") then
		pcall(broadcastToGalaxy, msg)
	end
end

local function bgSundaySafeTerrainZ(planet, x, y, fallback)
	if (type(getTerrainHeight) == "function") then
		local calls = {
			function()
				return getTerrainHeight(x, y)
			end,
			function()
				return getTerrainHeight(planet, x, y)
			end,
		}

		for index = 1, #calls, 1 do
			local ok, z = pcall(calls[index])

			if (ok and type(z) == "number") then
				return z
			end
		end
	end

	return fallback or 0
end

function BgSundayDantooineEvent:log(message)
	local prefix = "[BG-SUNDAY-DANTOOINE] "

	if (printLuaError ~= nil) then
		printLuaError(prefix .. tostring(message))
	else
		print(prefix .. tostring(message))
	end
end

function BgSundayDantooineEvent:debug(message)
	if (self.CONFIG.debugEnabled ~= true) then
		return
	end

	self:log(message)
end

function BgSundayDantooineEvent:getDataNumber(key, fallback)
	return bgSundayNum(readData(key), fallback or 0)
end

function BgSundayDantooineEvent:setDataNumber(key, value)
	writeData(key, bgSundayNum(value, 0))
end

function BgSundayDantooineEvent:deleteDataKey(key)
	deleteData(key)
end

function BgSundayDantooineEvent:getRunMemberKey(index)
	return "bg_sunday_event:member:" .. tostring(index)
end

function BgSundayDantooineEvent:getCheckpointSpawnedKey(index)
	return "bg_sunday_event:checkpoint:" .. tostring(index) .. ":spawned"
end

function BgSundayDantooineEvent:getCheckpointCompletedKey(index)
	return "bg_sunday_event:checkpoint:" .. tostring(index) .. ":completed"
end

function BgSundayDantooineEvent:getPlayerWaypointKey(playerId)
	return tostring(playerId) .. ":bg_sunday_event:waypointId"
end

function BgSundayDantooineEvent:start()
	self.runtime.checkpointAreaIds = {}
	self.runtime.usedBossTemplates = {}
	self:spawnCheckpointAreas()
	self:recoverRuntimeState()
	self:schedulerTick()
	self:checkpointPollTick()
end

function BgSundayDantooineEvent:recoverRuntimeState()
	if (self:getDataNumber(self.DATA.eventStarted, 0) == 1) then
		local bossId = self:getDataNumber(self.DATA.activeBossId, 0)

		if (bossId > 0) then
			local pBoss = getSceneObject(bossId)

			if (pBoss ~= nil) then
				createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyBossKilled", pBoss)
				createObserver(DAMAGERECEIVED, self.screenplayName, "notifyBossDamaged", pBoss)
				self:debug("Recovered active boss observer for object " .. tostring(bossId))
			else
				self:setDataNumber(self.DATA.activeBossId, 0)
				self:setDataNumber(self.DATA.activeBossCheckpoint, 0)
			end
		end
	end
end

function BgSundayDantooineEvent:spawnCheckpointAreas()
	for index = 1, #self.CONFIG.checkpoints, 1 do
		local checkpoint = self.CONFIG.checkpoints[index]
		local trigger = checkpoint.trigger
		local z = bgSundaySafeTerrainZ(self.CONFIG.planet, trigger.x, trigger.y, trigger.z)
		local pArea = spawnActiveArea(self.CONFIG.planet, "object/active_area.iff", trigger.x, z, trigger.y, trigger.radius or 96, 0)

		if (pArea ~= nil) then
			createObserver(ENTEREDAREA, self.screenplayName, "notifyEnteredCheckpointArea", pArea)
			self.runtime.checkpointAreaIds[index] = SceneObject(pArea):getObjectID()
			writeData(SceneObject(pArea):getObjectID() .. ":bg_sunday_event:checkpoint", index)
			self:debug("Spawned checkpoint area " .. tostring(index) .. " at " .. tostring(trigger.x) .. ", " .. tostring(trigger.y))
		else
			self:log("Failed to spawn checkpoint area " .. tostring(index))
		end
	end
end

function BgSundayDantooineEvent:getDayIndex(dayName)
	local days = {
		sunday = 0,
		monday = 1,
		tuesday = 2,
		wednesday = 3,
		thursday = 4,
		friday = 5,
		saturday = 6,
	}

	return days[string.lower(tostring(dayName or "sunday"))] or 0
end

function BgSundayDantooineEvent:getAbsoluteRunStamp()
	local startDate = self.CONFIG.absoluteStartDate or {}

	return os.time({
		year = bgSundayNum(startDate.year, 1970),
		month = bgSundayNum(startDate.month, 1),
		day = bgSundayNum(startDate.day, 1),
		hour = bgSundayNum(startDate.hour, 0),
		min = bgSundayNum(startDate.minute, 0),
		sec = bgSundayNum(startDate.second, 0),
	})
end

function BgSundayDantooineEvent:getMostRecentRunStamp(atTime)
	if (string.lower(tostring(self.CONFIG.scheduleMode or "weekly")) == "absolute") then
		return self:getAbsoluteRunStamp()
	end

	local currentTime = atTime or bgSundayNow()
	local schedule = self.CONFIG
	local currentDate = os.date("*t", currentTime)
	local todayStamp = os.time({
		year = currentDate.year,
		month = currentDate.month,
		day = currentDate.day,
		hour = schedule.activeHour,
		min = schedule.activeMinute,
		sec = schedule.activeSecond,
	})
	local wantedDay = self:getDayIndex(schedule.activeDay)
	local currentDay = tonumber(os.date("%w", todayStamp)) or 0
	local daysBack = (currentDay - wantedDay) % 7

	if (daysBack == 0 and todayStamp > currentTime) then
		daysBack = 7
	end

	return todayStamp - (daysBack * 24 * 60 * 60)
end

function BgSundayDantooineEvent:isRunWindowOpen(runStamp, atTime)
	local currentTime = atTime or bgSundayNow()
	local windowEnd = runStamp + bgSundayClampSeconds(self.CONFIG.starterWindowSeconds)
	return currentTime >= runStamp and currentTime < windowEnd
end

function BgSundayDantooineEvent:getCurrentRunStamp()
	if (self.CONFIG.debugIgnoreSchedule == true) then
		return self:getMostRecentRunStamp(bgSundayNow())
	end

	local runStamp = self:getMostRecentRunStamp(bgSundayNow())

	if (self:isRunWindowOpen(runStamp, bgSundayNow())) then
		return runStamp
	end

	return 0
end

function BgSundayDantooineEvent:isActiveRunStarted()
	return self:getDataNumber(self.DATA.eventStarted, 0) == 1
end

function BgSundayDantooineEvent:isRunCompleteForStamp(runStamp)
	return runStamp > 0 and self:getDataNumber(self.DATA.completedRunStamp, 0) == runStamp
end

function BgSundayDantooineEvent:isRunExpiredForStamp(runStamp)
	return runStamp > 0 and self:getDataNumber(self.DATA.expiredRunStamp, 0) == runStamp
end

function BgSundayDantooineEvent:isStarterSpawned()
	if (self:getDataNumber(self.DATA.starterSpawned, 0) ~= 1) then
		return false
	end

	if (self:getStarterObject() == nil) then
		self:setDataNumber(self.DATA.starterSpawned, 0)
		self:setDataNumber(self.DATA.starterObjectId, 0)
		return false
	end

	return true
end

function BgSundayDantooineEvent:getStarterObject()
	local starterId = self:getDataNumber(self.DATA.starterObjectId, 0)

	if (starterId <= 0) then
		return nil
	end

	return getSceneObject(starterId)
end

function BgSundayDantooineEvent:spawnStarter(runStamp)
	local existing = self:getStarterObject()

	if (existing ~= nil) then
		self:setDataNumber(self.DATA.starterSpawned, 1)
		self:setDataNumber(self.DATA.activeRunStamp, runStamp)
		return existing
	end

	local starter = self.CONFIG.starter
	local z = starter.z or bgSundaySafeTerrainZ(starter.planet, starter.x, starter.y, 0)
	local pTerminal = spawnSceneObject(starter.planet, starter.template, starter.x, z, starter.y, 0, math.rad(starter.heading or 0))

	if (pTerminal == nil) then
		self:log("Starter spawn failed.")
		return nil
	end

	SceneObject(pTerminal):setObjectMenuComponent("BgSundayDantooineStarterMenuComponent")
	SceneObject(pTerminal):setCustomObjectName(starter.name)

	local starterId = SceneObject(pTerminal):getObjectID()
	self:setDataNumber(self.DATA.starterObjectId, starterId)
	self:setDataNumber(self.DATA.starterSpawned, 1)
	self:setDataNumber(self.DATA.activeRunStamp, runStamp)
	self:log("Starter spawned for run " .. tostring(runStamp) .. " on Naboo.")
	bgSundayTryBroadcast(self.CONFIG.messages.starterSpawned)
	return pTerminal
end

function BgSundayDantooineEvent:despawnStarter()
	local pStarter = self:getStarterObject()

	if (pStarter ~= nil) then
		SceneObject(pStarter):destroyObjectFromWorld()
		SceneObject(pStarter):destroyObjectFromDatabase()
		self:debug("Starter despawned.")
	end

	self:setDataNumber(self.DATA.starterObjectId, 0)
	self:setDataNumber(self.DATA.starterSpawned, 0)
end

function BgSundayDantooineEvent:schedulerTick()
	local currentTime = bgSundayNow()
	local runStamp = self:getCurrentRunStamp()
	local activeRunStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

	if (self.CONFIG.debugForceStarterOnBoot == true and self:isStarterSpawned() ~= true and self:isActiveRunStarted() ~= true) then
		self:spawnStarter(activeRunStamp > 0 and activeRunStamp or self:getMostRecentRunStamp(currentTime))
	end

	if (runStamp > 0) then
		if (self:isRunCompleteForStamp(runStamp) ~= true and self:isRunExpiredForStamp(runStamp) ~= true and self:isStarterSpawned() ~= true and self:isActiveRunStarted() ~= true) then
			self:spawnStarter(runStamp)
		end
	else
		if (self:isActiveRunStarted() ~= true and self:isStarterSpawned() == true) then
			local oldRunStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

			if (oldRunStamp > 0 and self:isRunCompleteForStamp(oldRunStamp) ~= true) then
				self:setDataNumber(self.DATA.expiredRunStamp, oldRunStamp)
				self:log("Starter window expired for run " .. tostring(oldRunStamp))
			end

			self:despawnStarter()
		end
	end

	if (self.CONFIG.enableInactivityFail == true) then
		self:checkInactivityTimeout(currentTime)
	end

	createEvent(self.CONFIG.schedulerIntervalMs, self.screenplayName, "schedulerTick", nil, "")
	return 0
end

function BgSundayDantooineEvent:checkInactivityTimeout(currentTime)
	if (self:isActiveRunStarted() ~= true or self:getDataNumber(self.DATA.finalEventComplete, 0) == 1) then
		return
	end

	local lastActivityAt = self:getDataNumber(self.DATA.lastActivityAt, 0)

	if (lastActivityAt <= 0) then
		return
	end

	if ((currentTime - lastActivityAt) >= bgSundayClampSeconds(self.CONFIG.inactivityFailSeconds)) then
		self:log("Inactivity timeout reached. Locking current run.")
		self:failCurrentRun(self.CONFIG.messages.timeout)
	end
end

function BgSundayDantooineEvent:touchActivity(reason)
	self:setDataNumber(self.DATA.lastActivityAt, bgSundayNow())

	if (reason ~= nil and reason ~= "") then
		self:debug("Activity touched: " .. tostring(reason))
	end
end

function BgSundayDantooineEvent:getDistance2d(x1, y1, x2, y2)
	local dx = (x1 or 0) - (x2 or 0)
	local dy = (y1 or 0) - (y2 or 0)
	return math.sqrt((dx * dx) + (dy * dy))
end

function BgSundayDantooineEvent:getPlayerId(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	return SceneObject(pPlayer):getObjectID()
end

function BgSundayDantooineEvent:isValidPlayer(pPlayer)
	return pPlayer ~= nil and SceneObject(pPlayer):isPlayerCreature()
end

function BgSundayDantooineEvent:isPlayerGrouped(pPlayer)
	return self:isValidPlayer(pPlayer) and CreatureObject(pPlayer):isGrouped()
end

function BgSundayDantooineEvent:getPlayerGroupId(pPlayer)
	if (self:isPlayerGrouped(pPlayer) ~= true) then
		return 0
	end

	return bgSundayNum(CreatureObject(pPlayer):getGroupID(), 0)
end

function BgSundayDantooineEvent:isGroupLeader(pPlayer)
	if (self:isPlayerGrouped(pPlayer) ~= true) then
		return false
	end

	local leader = CreatureObject(pPlayer):getGroupMember(0)

	if (leader == nil) then
		return false
	end

	return self:getPlayerId(leader) == self:getPlayerId(pPlayer)
end

function BgSundayDantooineEvent:getGroupMembersFromReference(pPlayer)
	local members = {}
	local seen = {}

	if (self:isPlayerGrouped(pPlayer) ~= true) then
		return members
	end

	local creature = CreatureObject(pPlayer)
	local groupSize = bgSundayNum(creature:getGroupSize(), 0)

	for index = 0, groupSize - 1, 1 do
		local pMember = creature:getGroupMember(index)

		if (self:isValidPlayer(pMember)) then
			local memberId = self:getPlayerId(pMember)

			if (seen[memberId] ~= true) then
				seen[memberId] = true
				table.insert(members, pMember)
			end
		end
	end

	return members
end

function BgSundayDantooineEvent:getSnapshotMembers()
	local members = {}
	local seen = {}
	local memberCount = self:getDataNumber(self.DATA.memberCount, 0)

	for index = 1, memberCount, 1 do
		local memberId = self:getDataNumber(self:getRunMemberKey(index), 0)

		if (memberId > 0 and seen[memberId] ~= true) then
			local pMember = getSceneObject(memberId)

			if (self:isValidPlayer(pMember)) then
				seen[memberId] = true
				table.insert(members, pMember)
			end
		end
	end

	return members
end

function BgSundayDantooineEvent:getPlayersInZone()
	local players = {}
	local seen = {}

	if (type(getPlayerCreaturesInZone) == "function") then
		local ok, list = pcall(getPlayerCreaturesInZone, self.CONFIG.planet)

		if (ok and type(list) == "table") then
			for index = 1, #list, 1 do
				local pPlayer = list[index]

				if (self:isValidPlayer(pPlayer)) then
					local playerId = self:getPlayerId(pPlayer)

					if (seen[playerId] ~= true) then
						seen[playerId] = true
						table.insert(players, pPlayer)
					end
				end
			end
		end
	end

	return players
end

function BgSundayDantooineEvent:getActiveGroupMembers()
	local members = {}
	local seen = {}
	local activeGroupId = self:getDataNumber(self.DATA.activeGroupId, 0)

	if (activeGroupId <= 0) then
		return members
	end

	local function addMember(pPlayer)
		if (self:isValidPlayer(pPlayer) ~= true) then
			return
		end

		if (self:getPlayerGroupId(pPlayer) ~= activeGroupId) then
			return
		end

		local playerId = self:getPlayerId(pPlayer)

		if (seen[playerId] == true) then
			return
		end

		seen[playerId] = true
		table.insert(members, pPlayer)
	end

	local zonePlayers = self:getPlayersInZone()

	for index = 1, #zonePlayers, 1 do
		addMember(zonePlayers[index])
	end

	local leaderId = self:getDataNumber(self.DATA.activeLeaderId, 0)

	if (leaderId > 0) then
		local pLeader = getSceneObject(leaderId)
		local leaderMembers = self:getGroupMembersFromReference(pLeader)

		for index = 1, #leaderMembers, 1 do
			addMember(leaderMembers[index])
		end
	end

	local fallbackMembers = self:getSnapshotMembers()

	for index = 1, #fallbackMembers, 1 do
		addMember(fallbackMembers[index])
	end

	return members
end

function BgSundayDantooineEvent:sendGroupMessage(message)
	local members = self:getActiveGroupMembers()

	for index = 1, #members, 1 do
		CreatureObject(members[index]):sendSystemMessage(message)
	end
end

function BgSundayDantooineEvent:removePlayerWaypoint(pPlayer)
	if (self:isValidPlayer(pPlayer) ~= true) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local waypointKey = self:getPlayerWaypointKey(self:getPlayerId(pPlayer))
	local waypointId = self:getDataNumber(waypointKey, 0)

	if (waypointId > 0) then
		PlayerObject(pGhost):removeWaypoint(waypointId, true)
		self:deleteDataKey(waypointKey)
	end
end

function BgSundayDantooineEvent:grantWaypointToPlayer(pPlayer, checkpointIndex)
	if (self:isValidPlayer(pPlayer) ~= true) then
		return
	end

	local checkpoint = self.CONFIG.checkpoints[checkpointIndex]

	if (checkpoint == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	self:removePlayerWaypoint(pPlayer)

	local trigger = checkpoint.trigger
	local z = bgSundaySafeTerrainZ(self.CONFIG.planet, trigger.x, trigger.y, trigger.z)
	local waypointId = PlayerObject(pGhost):addWaypoint(self.CONFIG.planet, checkpoint.waypointName, checkpoint.waypointDesc, trigger.x, z, trigger.y, WAYPOINT_YELLOW, true, true, 0, 0)

	if (waypointId ~= nil and tonumber(waypointId) ~= nil and tonumber(waypointId) > 0) then
		self:setDataNumber(self:getPlayerWaypointKey(self:getPlayerId(pPlayer)), waypointId)
		self:debug("Granted checkpoint " .. tostring(checkpointIndex) .. " waypoint to " .. tostring(self:getPlayerId(pPlayer)))
	end
end

function BgSundayDantooineEvent:grantWaypointToActiveGroup(checkpointIndex)
	local members = self:getActiveGroupMembers()

	for index = 1, #members, 1 do
		self:grantWaypointToPlayer(members[index], checkpointIndex)
	end
end

function BgSundayDantooineEvent:clearAllGroupWaypoints()
	local members = self:getActiveGroupMembers()

	for index = 1, #members, 1 do
		self:removePlayerWaypoint(members[index])
	end

	local snapshotMembers = self:getSnapshotMembers()

	for index = 1, #snapshotMembers, 1 do
		self:removePlayerWaypoint(snapshotMembers[index])
	end
end

function BgSundayDantooineEvent:resetCheckpointState()
	for index = 1, self.CONFIG.totalCheckpoints, 1 do
		self:setDataNumber(self:getCheckpointSpawnedKey(index), 0)
		self:setDataNumber(self:getCheckpointCompletedKey(index), 0)
	end
end

function BgSundayDantooineEvent:snapshotGroupMembers(pLeader)
	local members = self:getGroupMembersFromReference(pLeader)
	self:setDataNumber(self.DATA.memberCount, #members)

	for index = 1, #members, 1 do
		self:setDataNumber(self:getRunMemberKey(index), self:getPlayerId(members[index]))
	end

	for index = #members + 1, 24, 1 do
		self:deleteDataKey(self:getRunMemberKey(index))
	end

	self:debug("Snapshotted " .. tostring(#members) .. " starting group members.")
end

function BgSundayDantooineEvent:getStarterUseState(pPlayer)
	local activeRunStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

	if (self:isStarterSpawned() ~= true and self:isActiveRunStarted() ~= true) then
		return false, "The Sunday run is not available right now."
	end

	if (activeRunStamp > 0 and self:isRunCompleteForStamp(activeRunStamp) == true) then
		return false, self.CONFIG.messages.runComplete
	end

	if (self:isActiveRunStarted() == true) then
		return false, self.CONFIG.messages.alreadyStarted
	end

	if (self:isPlayerGrouped(pPlayer) ~= true) then
		return false, self.CONFIG.messages.ungrouped
	end

	if (self:isGroupLeader(pPlayer) ~= true) then
		return false, self.CONFIG.messages.notLeader
	end

	return true, ""
end

function BgSundayDantooineEvent:handleStarterUsed(pPlayer)
	if (self:isValidPlayer(pPlayer) ~= true) then
		return 0
	end

	local playerId = self:getPlayerId(pPlayer)
	self:log("Starter use attempt by " .. tostring(playerId))

	local allowed, message = self:getStarterUseState(pPlayer)

	if (allowed ~= true) then
		self:log("Starter use rejected for " .. tostring(playerId) .. ": " .. tostring(message))
		CreatureObject(pPlayer):sendSystemMessage(message)
		return 0
	end

	local groupSize = bgSundayNum(CreatureObject(pPlayer):getGroupSize(), 0)

	if (groupSize < 2) then
		self:log("Starter use rejected for " .. tostring(playerId) .. ": group size below 2.")
		CreatureObject(pPlayer):sendSystemMessage(self.CONFIG.messages.ungrouped)
		return 0
	end

	if (groupSize < 10 or groupSize > 20) then
		CreatureObject(pPlayer):sendSystemMessage(self.CONFIG.messages.recommendedSize)
	end

	local groupId = self:getPlayerGroupId(pPlayer)
	local runStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

	if (runStamp <= 0) then
		runStamp = self:getCurrentRunStamp()
	end

	self:setDataNumber(self.DATA.activeRunStamp, runStamp)
	self:setDataNumber(self.DATA.activeGroupId, groupId)
	self:setDataNumber(self.DATA.activeLeaderId, playerId)
	self:setDataNumber(self.DATA.eventStarted, 1)
	self:setDataNumber(self.DATA.finalEventComplete, 0)
	self:setDataNumber(self.DATA.currentCheckpoint, 1)
	self:setDataNumber(self.DATA.activeBossId, 0)
	self:setDataNumber(self.DATA.activeBossCheckpoint, 0)
	self:setDataNumber(self.DATA.activeBossCleanup, 0)
	self.runtime.usedBossTemplates = {}
	self:resetCheckpointState()
	self:snapshotGroupMembers(pPlayer)
	self:touchActivity("run_started")

	self:grantWaypointToActiveGroup(1)
	self:sendGroupMessage(self.CONFIG.messages.runStarted)
	self:sendGroupMessage(self.CONFIG.messages.nextWaypoint)
	self:log("Registered active group " .. tostring(groupId) .. " with leader " .. tostring(playerId))
	return 0
end

function BgSundayDantooineEvent:isPlayerInActiveGroup(pPlayer)
	return self:isValidPlayer(pPlayer) == true and self:getPlayerGroupId(pPlayer) == self:getDataNumber(self.DATA.activeGroupId, 0)
end

function BgSundayDantooineEvent:notifyEnteredCheckpointArea(pArea, pPlayer)
	if (pArea == nil or self:isValidPlayer(pPlayer) ~= true) then
		return 0
	end

	local checkpointIndex = bgSundayNum(readData(SceneObject(pArea):getObjectID() .. ":bg_sunday_event:checkpoint"), 0)
	self:tryTriggerCheckpointFromPlayer(pPlayer, checkpointIndex, "area")
	return 0
end

function BgSundayDantooineEvent:tryTriggerCheckpointFromPlayer(pPlayer, checkpointIndex, sourceTag)
	if (self:isValidPlayer(pPlayer) ~= true) then
		return false
	end

	if (self:isActiveRunStarted() ~= true or self:getDataNumber(self.DATA.finalEventComplete, 0) == 1) then
		return false
	end

	if (self:isPlayerInActiveGroup(pPlayer) ~= true) then
		return false
	end

	local currentCheckpoint = self:getDataNumber(self.DATA.currentCheckpoint, 0)

	if (checkpointIndex <= 0 or currentCheckpoint ~= checkpointIndex) then
		return false
	end

	if (self:getDataNumber(self:getCheckpointCompletedKey(checkpointIndex), 0) == 1) then
		return false
	end

	if (self:getDataNumber(self:getCheckpointSpawnedKey(checkpointIndex), 0) == 1) then
		return false
	end

	self:setDataNumber(self:getCheckpointSpawnedKey(checkpointIndex), 1)
	self:touchActivity("checkpoint_" .. tostring(checkpointIndex) .. "_triggered_" .. tostring(sourceTag or "unknown"))
	self:log("Checkpoint " .. tostring(checkpointIndex) .. " triggered by player " .. tostring(self:getPlayerId(pPlayer)) .. " via " .. tostring(sourceTag or "unknown"))

	if (self:spawnCheckpointBoss(checkpointIndex) ~= true) then
		self:setDataNumber(self:getCheckpointSpawnedKey(checkpointIndex), 0)
		CreatureObject(pPlayer):sendSystemMessage("The ambush failed to materialize. Contact staff.")
		return false
	end

	return true
end

function BgSundayDantooineEvent:checkpointPollTick()
	if (self:isActiveRunStarted() == true and self:getDataNumber(self.DATA.finalEventComplete, 0) ~= 1) then
		local checkpointIndex = self:getDataNumber(self.DATA.currentCheckpoint, 0)
		local checkpoint = self.CONFIG.checkpoints[checkpointIndex]

		if (checkpoint ~= nil and self:getDataNumber(self:getCheckpointCompletedKey(checkpointIndex), 0) ~= 1 and self:getDataNumber(self:getCheckpointSpawnedKey(checkpointIndex), 0) ~= 1) then
			local trigger = checkpoint.trigger
			local members = self:getActiveGroupMembers()

			for index = 1, #members, 1 do
				local pMember = members[index]
				local memberX = SceneObject(pMember):getWorldPositionX()
				local memberY = SceneObject(pMember):getWorldPositionY()
				local distance = self:getDistance2d(memberX, memberY, trigger.x, trigger.y)

				if (distance <= (trigger.radius or 96)) then
					self:tryTriggerCheckpointFromPlayer(pMember, checkpointIndex, "poll")
					break
				end
			end
		end
	end

	createEvent(self.CONFIG.checkpointPollIntervalMs, self.screenplayName, "checkpointPollTick", nil, "")
	return 0
end

function BgSundayDantooineEvent:pickBossEntry()
	local available = {}
	local used = self.runtime.usedBossTemplates or {}

	for index = 1, #self.CONFIG.bossPool, 1 do
		local entry = self.CONFIG.bossPool[index]

		if (self.CONFIG.allowDuplicateBossesPerRun == true or used[entry.template] ~= true) then
			table.insert(available, entry)
		end
	end

	if (#available == 0) then
		available = self.CONFIG.bossPool
	end

	if (#available == 0) then
		return nil
	end

	return available[math.random(#available)]
end

function BgSundayDantooineEvent:spawnCheckpointBoss(checkpointIndex)
	local checkpoint = self.CONFIG.checkpoints[checkpointIndex]
	local bossEntry = self:pickBossEntry()

	if (checkpoint == nil or bossEntry == nil) then
		self:log("Checkpoint boss spawn aborted: missing checkpoint or boss entry.")
		return false
	end

	local spawn = checkpoint.spawn
	local z = bgSundaySafeTerrainZ(self.CONFIG.planet, spawn.x, spawn.y, spawn.z)
	local pBoss = spawnMobile(self.CONFIG.planet, bossEntry.template, 0, spawn.x, z, spawn.y, spawn.heading or 0, 0)

	if (pBoss == nil) then
		self:log("Checkpoint " .. tostring(checkpointIndex) .. " boss spawn failed for template " .. tostring(bossEntry.template))
		return false
	end

	local bossName = bossEntry.name or bossEntry.template
	if (CreatureObject(pBoss) ~= nil and CreatureObject(pBoss).setCustomObjectName ~= nil) then
		CreatureObject(pBoss):setCustomObjectName(bossName)
	else
		SceneObject(pBoss):setCustomObjectName(bossName)
	end
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyBossKilled", pBoss)
	createObserver(DAMAGERECEIVED, self.screenplayName, "notifyBossDamaged", pBoss)

	local bossId = SceneObject(pBoss):getObjectID()
	self:setDataNumber(self.DATA.activeBossId, bossId)
	self:setDataNumber(self.DATA.activeBossCheckpoint, checkpointIndex)
	self:setDataNumber(self.DATA.activeBossCleanup, 0)
	self.runtime.usedBossTemplates[bossEntry.template] = true
	self:sendGroupMessage(self.CONFIG.messages.ambush)
	self:sendGroupMessage("\\#FF6600" .. bossName .. " has appeared near " .. checkpoint.name .. ".")
	self:sendGroupMessage("\\#FFCC66Ambush coordinates: " .. tostring(spawn.x) .. ", " .. tostring(spawn.y))
	self:log("Spawned checkpoint " .. tostring(checkpointIndex) .. " boss " .. tostring(bossEntry.template) .. " (" .. tostring(bossId) .. ")")
	return true
end

function BgSundayDantooineEvent:notifyBossDamaged(pBoss, pAttacker, damage)
	local bossId = pBoss ~= nil and self:getPlayerId(pBoss) or 0
	local activeBossId = self:getDataNumber(self.DATA.activeBossId, 0)

	if (bossId > 0 and bossId == activeBossId) then
		self:touchActivity("boss_damaged")
	end

	return 0
end

function BgSundayDantooineEvent:pickRewardGroup()
	local pool = self.CONFIG.rewardPool
	local totalWeight = 0

	for index = 1, #pool, 1 do
		totalWeight = totalWeight + bgSundayNum(pool[index].weight, 0)
	end

	if (totalWeight <= 0) then
		return nil
	end

	local roll = math.random(totalWeight)
	local cumulative = 0

	for index = 1, #pool, 1 do
		cumulative = cumulative + bgSundayNum(pool[index].weight, 0)

		if (roll <= cumulative) then
			return pool[index].group
		end
	end

	return nil
end

function BgSundayDantooineEvent:grantRewardToPlayer(pPlayer, bossLevel)
	if (self:isValidPlayer(pPlayer) ~= true) then
		return false
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Reward delivery failed because your inventory is unavailable.")
		return false
	end

	local rewardGroup = self:pickRewardGroup()

	if (rewardGroup == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Reward delivery failed because the event reward table is empty.")
		return false
	end

	local itemOid = createLoot(pInventory, rewardGroup, bossLevel or 1, true)
	local itemName = rewardGroup

	if (itemOid ~= nil and tonumber(itemOid) ~= nil and tonumber(itemOid) > 0) then
		local pItem = getSceneObject(itemOid)

		if (pItem ~= nil) then
			itemName = SceneObject(pItem):getDisplayedName() or rewardGroup
		end
	end

	CreatureObject(pPlayer):sendSystemMessage("\\#00FF00Sunday run reward granted: " .. tostring(itemName))
	self:log("Reward granted to player " .. tostring(self:getPlayerId(pPlayer)) .. " from group " .. tostring(rewardGroup))
	return true
end

function BgSundayDantooineEvent:getEligibleRewardPlayers(pBoss)
	local eligible = {}
	local members = self.CONFIG.allowLateJoinerRewards == true and self:getActiveGroupMembers() or self:getSnapshotMembers()

	for index = 1, #members, 1 do
		local pMember = members[index]

		if (self:isPlayerInActiveGroup(pMember) == true and SceneObject(pMember):isInRangeWithObject(pBoss, self.CONFIG.rewardRadius)) then
			table.insert(eligible, pMember)
		end
	end

	return eligible
end

function BgSundayDantooineEvent:notifyBossKilled(pBoss, pKiller)
	if (pBoss == nil) then
		return 0
	end

	local bossId = SceneObject(pBoss):getObjectID()
	local activeBossId = self:getDataNumber(self.DATA.activeBossId, 0)
	local checkpointIndex = self:getDataNumber(self.DATA.activeBossCheckpoint, 0)

	if (bossId == 0 or bossId ~= activeBossId or checkpointIndex <= 0) then
		return 0
	end

	if (self:getDataNumber(self.DATA.activeBossCleanup, 0) == 1) then
		return 0
	end

	self:touchActivity("boss_killed")
	self:log("Boss " .. tostring(bossId) .. " killed for checkpoint " .. tostring(checkpointIndex))

	local eligiblePlayers = self:getEligibleRewardPlayers(pBoss)
	local bossLevel = 1

	local bossCreature = CreatureObject(pBoss)

	if (bossCreature ~= nil and bossCreature.getLevel ~= nil) then
		bossLevel = bgSundayNum(bossCreature:getLevel(), 1)
	end

	for index = 1, #eligiblePlayers, 1 do
		self:grantRewardToPlayer(eligiblePlayers[index], bossLevel)
	end

	self:setDataNumber(self:getCheckpointCompletedKey(checkpointIndex), 1)
	self:setDataNumber(self.DATA.activeBossId, 0)
	self:setDataNumber(self.DATA.activeBossCheckpoint, 0)
	self:sendGroupMessage(self.CONFIG.messages.checkpointComplete)

	if (checkpointIndex < self.CONFIG.totalCheckpoints) then
		local nextCheckpoint = checkpointIndex + 1
		self:setDataNumber(self.DATA.currentCheckpoint, nextCheckpoint)
		self:grantWaypointToActiveGroup(nextCheckpoint)
		self:sendGroupMessage(self.CONFIG.messages.nextWaypoint)
		self:sendGroupMessage("\\#FFCC66Proceed to " .. tostring(self.CONFIG.checkpoints[nextCheckpoint].name) .. ".")
		self:log("Advanced to checkpoint " .. tostring(nextCheckpoint))
	else
		self:completeCurrentRun()
	end

	return 0
end

function BgSundayDantooineEvent:destroyActiveBossIfNeeded()
	local bossId = self:getDataNumber(self.DATA.activeBossId, 0)

	if (bossId <= 0) then
		return
	end

	local pBoss = getSceneObject(bossId)

	if (pBoss ~= nil) then
		self:setDataNumber(self.DATA.activeBossCleanup, 1)
		SceneObject(pBoss):destroyObjectFromWorld()
		SceneObject(pBoss):destroyObjectFromDatabase()
	end

	self:setDataNumber(self.DATA.activeBossId, 0)
	self:setDataNumber(self.DATA.activeBossCheckpoint, 0)
	self:setDataNumber(self.DATA.activeBossCleanup, 0)
end

function BgSundayDantooineEvent:clearRunMembership()
	local memberCount = self:getDataNumber(self.DATA.memberCount, 0)

	for index = 1, memberCount, 1 do
		self:deleteDataKey(self:getRunMemberKey(index))
	end

	self:setDataNumber(self.DATA.memberCount, 0)
end

function BgSundayDantooineEvent:clearRunState(lockRunStamp)
	self:destroyActiveBossIfNeeded()
	self:clearAllGroupWaypoints()
	self:setDataNumber(self.DATA.eventStarted, 0)
	self:setDataNumber(self.DATA.finalEventComplete, 0)
	self:setDataNumber(self.DATA.activeGroupId, 0)
	self:setDataNumber(self.DATA.activeLeaderId, 0)
	self:setDataNumber(self.DATA.currentCheckpoint, 0)
	self:setDataNumber(self.DATA.lastActivityAt, 0)
	self:clearRunMembership()
	self.runtime.usedBossTemplates = {}
	self:resetCheckpointState()

	if (lockRunStamp ~= nil and tonumber(lockRunStamp) ~= nil and tonumber(lockRunStamp) > 0) then
		self:setDataNumber(self.DATA.activeRunStamp, tonumber(lockRunStamp))
	else
		self:setDataNumber(self.DATA.activeRunStamp, 0)
	end
end

function BgSundayDantooineEvent:completeCurrentRun()
	local runStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

	self:setDataNumber(self.DATA.finalEventComplete, 1)
	self:setDataNumber(self.DATA.completedRunStamp, runStamp)
	self:sendGroupMessage(self.CONFIG.messages.finalVictory)
	bgSundayTryBroadcast(self.CONFIG.messages.finalVictory)
	self:log("Run completed for stamp " .. tostring(runStamp))
	self:despawnStarter()
	self:clearRunState(runStamp)
end

function BgSundayDantooineEvent:failCurrentRun(message)
	local runStamp = self:getDataNumber(self.DATA.activeRunStamp, 0)

	if (message ~= nil and message ~= "") then
		self:sendGroupMessage(message)
	end

	self:despawnStarter()
	self:setDataNumber(self.DATA.expiredRunStamp, runStamp)
	self:clearRunState(runStamp)
end

function BgSundayDantooineEvent:adminForceSpawnStarter()
	local runStamp = self:getMostRecentRunStamp(bgSundayNow())
	self:setDataNumber(self.DATA.completedRunStamp, 0)
	self:setDataNumber(self.DATA.expiredRunStamp, 0)
	self:spawnStarter(runStamp)
end

function BgSundayDantooineEvent:adminResetCurrentRun()
	self:despawnStarter()
	self:setDataNumber(self.DATA.completedRunStamp, 0)
	self:setDataNumber(self.DATA.expiredRunStamp, 0)
	self:clearRunState(0)
end

BgSundayDantooineStarterMenuComponent = {}

function BgSundayDantooineStarterMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(20, 3, "Activate Sunday Run")
end

function BgSundayDantooineStarterMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 20) then
		return BgSundayDantooineEvent:handleStarterUsed(pPlayer)
	end

	return 0
end
