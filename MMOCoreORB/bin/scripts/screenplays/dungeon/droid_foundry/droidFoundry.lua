DroidFoundry = ScreenPlay:new {
	terminalTemplate = "object/tangible/terminal/terminal_geo_bunker.iff",
	terminalX = 4784,
	terminalY = 982,
	exitX = 4784,
	exitY = 982,
	timeoutSeconds = 30 * 60,
	entryX = 0.840546,
	entryZ = -4.010900,
	entryY = 16.232117,
	participantRange = 50,
	admissionTimeoutSeconds = 5,

	instances = {
		{
			rootID = 1879048191,
			cellIDs = {
				1879048190, 1879048189, 1879048188, 1879048187, 1879048186,
				1879048185, 1879048184, 1879048183, 1879048182, 1879048181,
				1879048180, 1879048179, 1879048178, 1879048177, 1879048176,
				1879048175, 1879048174, 1879048173, 1879048172, 1879048171,
			},
		},
		{
			rootID = 1879048170,
			cellIDs = {
				1879048169, 1879048168, 1879048167, 1879048166, 1879048165,
				1879048164, 1879048163, 1879048162, 1879048161, 1879048160,
				1879048159, 1879048158, 1879048157, 1879048156, 1879048155,
				1879048154, 1879048153, 1879048152, 1879048151, 1879048150,
			},
		},
		{
			rootID = 1879048149,
			cellIDs = {
				1879048148, 1879048147, 1879048146, 1879048145, 1879048144,
				1879048143, 1879048142, 1879048141, 1879048140, 1879048139,
				1879048138, 1879048137, 1879048136, 1879048135, 1879048134,
				1879048133, 1879048132, 1879048131, 1879048130, 1879048129,
			},
		},
		{
			rootID = 1879048128,
			cellIDs = {
				1879048127, 1879048126, 1879048125, 1879048124, 1879048123,
				1879048122, 1879048121, 1879048120, 1879048119, 1879048118,
				1879048117, 1879048116, 1879048115, 1879048114, 1879048113,
				1879048112, 1879048111, 1879048110, 1879048109, 1879048108,
			},
		},
		{
			rootID = 1879048107,
			cellIDs = {
				1879048106, 1879048105, 1879048104, 1879048103, 1879048102,
				1879048101, 1879048100, 1879048099, 1879048098, 1879048097,
				1879048096, 1879048095, 1879048094, 1879048093, 1879048092,
				1879048091, 1879048090, 1879048089, 1879048088, 1879048087,
			},
		},
		{
			rootID = 1879048086,
			cellIDs = {
				1879048085, 1879048084, 1879048083, 1879048082, 1879048081,
				1879048080, 1879048079, 1879048078, 1879048077, 1879048076,
				1879048075, 1879048074, 1879048073, 1879048072, 1879048071,
				1879048070, 1879048069, 1879048068, 1879048067, 1879048066,
			},
		},
		{
			rootID = 1879048065,
			cellIDs = {
				1879048064, 1879048063, 1879048062, 1879048061, 1879048060,
				1879048059, 1879048058, 1879048057, 1879048056, 1879048055,
				1879048054, 1879048053, 1879048052, 1879048051, 1879048050,
				1879048049, 1879048048, 1879048047, 1879048046, 1879048045,
			},
		},
		{
			rootID = 1879048044,
			cellIDs = {
				1879048043, 1879048042, 1879048041, 1879048040, 1879048039,
				1879048038, 1879048037, 1879048036, 1879048035, 1879048034,
				1879048033, 1879048032, 1879048031, 1879048030, 1879048029,
				1879048028, 1879048027, 1879048026, 1879048025, 1879048024,
			},
		},
	},
}

registerScreenPlay("DroidFoundry", true)

function DroidFoundry:start()
	if (not isZoneEnabled("lok") or not isZoneEnabled("dungeon1")) then
		return
	end

	for i = 1, #self.instances, 1 do
		local instance = self.instances[i]
		local pBuilding = getSceneObject(instance.rootID)

		self:ejectAllPlayers(instance)
		self:releaseInstance(instance.rootID)

		if (pBuilding == nil or not SceneObject(pBuilding):isBuildingObject()) then
			printLuaError("DroidFoundry:start unable to find instance building " .. instance.rootID)
		else
			createObserver(ENTEREDBUILDING, "DroidFoundry", "onEnterInstance", pBuilding)
			createObserver(EXITEDBUILDING, "DroidFoundry", "onExitInstance", pBuilding)
		end
	end

	local terminalZ = getWorldFloor(self.terminalX, self.terminalY, "lok")
	local pTerminal = spawnSceneObject("lok", self.terminalTemplate, self.terminalX, terminalZ, self.terminalY, 0, math.rad(0))

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:start unable to spawn the expedition terminal")
		return
	end

	SceneObject(pTerminal):setCustomObjectName("Droid Foundry Expedition Terminal")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundryTerminalMenuComponent")
end

function DroidFoundry:getInstance(rootID)
	rootID = tonumber(rootID) or 0

	for i = 1, #self.instances, 1 do
		if (self.instances[i].rootID == rootID) then
			return self.instances[i]
		end
	end

	return nil
end

function DroidFoundry:beginExpedition(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	if (not isZoneEnabled("dungeon1")) then
		CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry expedition area is currently unavailable.")
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local assignedRootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0

	if (assignedRootID ~= 0) then
		if (self:getInstance(assignedRootID) ~= nil and tonumber(readData("droidFoundryActive:" .. assignedRootID)) == 1) then
			if (self:isParticipant(assignedRootID, playerID) or self:isAdmitted(assignedRootID, playerID)) then
				self:transportPlayer(pPlayer, assignedRootID)
				return
			end
		end

		deleteData("droidFoundryInstance:" .. playerID)
	end

	if (self:tryLateJoin(pPlayer)) then
		return
	end

	if (CreatureObject(pPlayer):isGrouped()) then
		local pLeader = CreatureObject(pPlayer):getGroupMember(0)
		if (pLeader == nil or SceneObject(pLeader):getObjectID() ~= playerID) then
			CreatureObject(pPlayer):sendSystemMessage("Only the group leader can begin a Droid Foundry expedition.")
			return
		end
	end

	local eligiblePlayers = self:getEligiblePlayers(pPlayer)

	for i = 1, #self.instances, 1 do
		local instance = self.instances[i]
		local pBuilding = getSceneObject(instance.rootID)
		if (pBuilding ~= nil and SceneObject(pBuilding):isBuildingObject() and tonumber(readData("droidFoundryActive:" .. instance.rootID)) ~= 1) then
			local started = os.time()
			writeData("droidFoundryActive:" .. instance.rootID, 1)
			writeData("droidFoundryOwner:" .. instance.rootID, playerID)
			writeData("droidFoundryStarted:" .. instance.rootID, started)
			writeData("droidFoundryGroup:" .. instance.rootID, CreatureObject(pPlayer):isGrouped() and CreatureObject(pPlayer):getGroupID() or 0)

			for j = 1, #eligiblePlayers, 1 do
				self:addEligiblePlayer(instance.rootID, eligiblePlayers[j])
			end

			self:admitPlayer(instance.rootID, pPlayer)

			createEvent(self.timeoutSeconds * 1000, "DroidFoundry", "handleTimeout", pBuilding, tostring(started))
			self:scheduleTransport(pPlayer, instance.rootID)

			for j = 1, #eligiblePlayers, 1 do
				local pMember = eligiblePlayers[j]
				if (pMember ~= pPlayer and CreatureObject(pPlayer):isInRangeWithObject(pMember, self.participantRange)) then
					self:sendAuthorizationSui(pMember, pPlayer, instance.rootID)
				end
			end

			return
		end
	end

	CreatureObject(pPlayer):sendSystemMessage("No Droid Foundry expedition instance is currently available. Please try again later.")
end

function DroidFoundry:getEligiblePlayers(pLeader)
	local eligiblePlayers = { pLeader }

	if (not CreatureObject(pLeader):isGrouped()) then
		return eligiblePlayers
	end

	local groupSize = CreatureObject(pLeader):getGroupSize()
	for i = 0, groupSize - 1, 1 do
		local pMember = CreatureObject(pLeader):getGroupMember(i)
		if (pMember ~= nil and pMember ~= pLeader and not SceneObject(pMember):isAiAgent()) then
			local memberID = SceneObject(pMember):getObjectID()
			local assignedRootID = tonumber(readData("droidFoundryInstance:" .. memberID)) or 0
			if (assignedRootID ~= 0 and (tonumber(readData("droidFoundryActive:" .. assignedRootID)) ~= 1 or
				(not self:isParticipant(assignedRootID, memberID) and not self:isAdmitted(assignedRootID, memberID)))) then
				deleteData("droidFoundryInstance:" .. memberID)
				assignedRootID = 0
			end

			if (assignedRootID ~= 0) then
				CreatureObject(pMember):sendSystemMessage("You are already assigned to a Droid Foundry expedition.")
			else
				table.insert(eligiblePlayers, pMember)
			end
		end
	end

	return eligiblePlayers
end

function DroidFoundry:isEligible(rootID, playerID)
	return tonumber(readData("droidFoundryEligible:" .. rootID .. ":" .. playerID)) == 1
end

function DroidFoundry:addEligiblePlayer(rootID, pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	if (self:isEligible(rootID, playerID)) then
		return
	end

	local rosterSize = tonumber(readData("droidFoundryEligibilitySize:" .. rootID)) or 0

	writeData("droidFoundryEligibilitySize:" .. rootID, rosterSize + 1)
	writeData("droidFoundryEligibility:" .. rootID .. ":" .. (rosterSize + 1), playerID)
	writeData("droidFoundryEligible:" .. rootID .. ":" .. playerID, 1)
end

function DroidFoundry:isStillInExpeditionGroup(pPlayer, rootID)
	if (pPlayer == nil or not CreatureObject(pPlayer):isGrouped()) then
		return false
	end

	local ownerID = tonumber(readData("droidFoundryOwner:" .. rootID)) or 0
	local pLeader = CreatureObject(pPlayer):getGroupMember(0)

	return ownerID ~= 0 and pLeader ~= nil and SceneObject(pLeader):getObjectID() == ownerID
end

function DroidFoundry:acceptEligiblePlayer(pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pPlayer == nil or tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (not self:isEligible(rootID, playerID) or not self:isStillInExpeditionGroup(pPlayer, rootID)) then
		return false
	end

	local assignedRootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0
	if (assignedRootID ~= 0 and assignedRootID ~= rootID) then
		return false
	end

	if (not self:isParticipant(rootID, playerID) and not self:isAdmitted(rootID, playerID)) then
		self:admitPlayer(rootID, pPlayer)
	end

	writeData("droidFoundryInstance:" .. playerID, rootID)
	self:scheduleTransport(pPlayer, rootID)
	return true
end

function DroidFoundry:tryLateJoin(pPlayer)
	if (pPlayer == nil or not CreatureObject(pPlayer):isGrouped()) then
		return false
	end

	local pLeader = CreatureObject(pPlayer):getGroupMember(0)
	if (pLeader == nil) then
		return false
	end

	local leaderID = SceneObject(pLeader):getObjectID()

	for i = 1, #self.instances, 1 do
		local rootID = self.instances[i].rootID
		if (tonumber(readData("droidFoundryActive:" .. rootID)) == 1 and
			(tonumber(readData("droidFoundryOwner:" .. rootID)) or 0) == leaderID) then
			self:addEligiblePlayer(rootID, pPlayer)
			return self:acceptEligiblePlayer(pPlayer, rootID)
		end
	end

	return false
end

function DroidFoundry:sendAuthorizationSui(pPlayer, pLeader, rootID)
	writeData("droidFoundryInvite:" .. SceneObject(pPlayer):getObjectID(), rootID)

	local sui = SuiMessageBox.new("DroidFoundry", "authorizationSuiCallback")
	sui.setTargetNetworkId(rootID)
	sui.setTitle("Droid Foundry Expedition")
	sui.setPrompt(CreatureObject(pLeader):getFirstName() .. " is starting a Droid Foundry expedition. Do you want to join?")
	sui.setOkButtonText("Yes")
	sui.setCancelButtonText("No")

	local pageID = sui.sendTo(pPlayer)
	createEvent(30 * 1000, "DroidFoundry", "closeAuthorizationSui", pPlayer, tostring(rootID) .. ":" .. tostring(pageID))
end

function DroidFoundry:authorizationSuiCallback(pPlayer, pSui, eventIndex, args)
	local playerID = SceneObject(pPlayer):getObjectID()
	local rootID = tonumber(readData("droidFoundryInvite:" .. playerID)) or 0
	deleteData("droidFoundryInvite:" .. playerID)

	if (tonumber(eventIndex) ~= 1) then
		self:acceptEligiblePlayer(pPlayer, rootID)
	end
end

function DroidFoundry:closeAuthorizationSui(pPlayer, eventData)
	if (pPlayer == nil or self:getPlayerInstanceRoot(pPlayer) ~= 0) then
		return
	end

	local separator = string.find(tostring(eventData), ":")
	local rootID = separator ~= nil and tonumber(string.sub(tostring(eventData), 1, separator - 1)) or 0
	local pageID = separator ~= nil and tonumber(string.sub(tostring(eventData), separator + 1)) or 0

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		PlayerObject(pGhost):removeSuiBox(pageID)
	end

	local inviteKey = "droidFoundryInvite:" .. SceneObject(pPlayer):getObjectID()
	if ((tonumber(readData(inviteKey)) or 0) == rootID) then
		deleteData(inviteKey)
	end
end

function DroidFoundry:isParticipant(rootID, playerID)
	return tonumber(readData("droidFoundryParticipant:" .. rootID .. ":" .. playerID)) == 1
end

function DroidFoundry:isAdmitted(rootID, playerID)
	return tonumber(readData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)) == 1
end

function DroidFoundry:admitPlayer(rootID, pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	writeData("droidFoundryAdmission:" .. rootID .. ":" .. playerID, 1)
	writeData("droidFoundryInstance:" .. playerID, rootID)
end

function DroidFoundry:scheduleTransport(pPlayer, rootID)
	createEvent(250, "DroidFoundry", "transportPlayer", pPlayer, tostring(rootID))
	createEvent(self.admissionTimeoutSeconds * 1000, "DroidFoundry", "handleAdmissionTimeout", pPlayer, tostring(rootID))
end

function DroidFoundry:handleAdmissionTimeout(pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pPlayer == nil or rootID == 0) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (not self:isAdmitted(rootID, playerID) or self:isParticipant(rootID, playerID)) then
		return
	end

	printLuaError("DroidFoundry:handleAdmissionTimeout rolling back failed admission for player " .. playerID .. " to instance " .. rootID)
	deleteData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)
	if ((tonumber(readData("droidFoundryInstance:" .. playerID)) or 0) == rootID) then
		deleteData("droidFoundryInstance:" .. playerID)
	end

	if ((tonumber(readData("droidFoundryParticipantCount:" .. rootID)) or 0) == 0 and not self:hasPendingAdmissions(rootID)) then
		self:releaseInstance(rootID)
	end
end

function DroidFoundry:hasPendingAdmissions(rootID)
	local eligibilitySize = tonumber(readData("droidFoundryEligibilitySize:" .. rootID)) or 0

	for i = 1, eligibilitySize, 1 do
		local playerID = tonumber(readData("droidFoundryEligibility:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0 and self:isAdmitted(rootID, playerID)) then
			return true
		end
	end

	return false
end

function DroidFoundry:addParticipant(rootID, pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0

	writeData("droidFoundryRosterSize:" .. rootID, rosterSize + 1)
	writeData("droidFoundryRoster:" .. rootID .. ":" .. (rosterSize + 1), playerID)
	writeData("droidFoundryParticipant:" .. rootID .. ":" .. playerID, 1)
	writeData("droidFoundryParticipantCount:" .. rootID, (tonumber(readData("droidFoundryParticipantCount:" .. rootID)) or 0) + 1)
	writeData("droidFoundryInstance:" .. playerID, rootID)
end

function DroidFoundry:removeParticipant(rootID, playerID)
	rootID = tonumber(rootID) or 0
	playerID = tonumber(playerID) or 0

	if (rootID == 0 or playerID == 0 or not self:isParticipant(rootID, playerID)) then
		deleteData("droidFoundryInstance:" .. playerID)
		return
	end

	deleteData("droidFoundryParticipant:" .. rootID .. ":" .. playerID)
	deleteData("droidFoundryInstance:" .. playerID)

	local participantCount = math.max(0, (tonumber(readData("droidFoundryParticipantCount:" .. rootID)) or 0) - 1)
	writeData("droidFoundryParticipantCount:" .. rootID, participantCount)

	if (participantCount == 0) then
		self:releaseInstance(rootID)
	end
end

function DroidFoundry:transportPlayer(pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	local instance = self:getInstance(rootID)
	local pRoot = getSceneObject(rootID)
	local pDestinationCell = instance ~= nil and getSceneObject(instance.cellIDs[1]) or nil
	if (pPlayer == nil or instance == nil or pRoot == nil or pDestinationCell == nil) then
		printLuaError("DroidFoundry:transportPlayer invalid destination root=" .. rootID ..
			" instance=" .. tostring(instance ~= nil) .. " root=" .. tostring(pRoot ~= nil) ..
			" cell=" .. tostring(pDestinationCell ~= nil))
		if (pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry expedition could not be started.")
		end
		self:releaseInstance(rootID)
		return
	end

	if (CreatureObject(pPlayer):isRidingMount()) then
		CreatureObject(pPlayer):dismount()
	end

	local destinationCellID = instance.cellIDs[1]
	SceneObject(pPlayer):switchZone("dungeon1", self.entryX, self.entryZ, self.entryY, destinationCellID)
end

function DroidFoundry:onEnterInstance(pBuilding, pPlayer)
	local buildingID = pBuilding ~= nil and SceneObject(pBuilding):getObjectID() or 0

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local rootID = buildingID
	local playerID = SceneObject(pPlayer):getObjectID()
	local ownerID = tonumber(readData("droidFoundryOwner:" .. rootID)) or 0
	local mappedRootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0
	local validAdmission = mappedRootID == rootID and self:isAdmitted(rootID, playerID) and self:isEligible(rootID, playerID) and (playerID == ownerID or self:isStillInExpeditionGroup(pPlayer, rootID))

	if (tonumber(readData("droidFoundryActive:" .. rootID)) == 1 and validAdmission) then
		deleteData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)
		self:addParticipant(rootID, pPlayer)
	elseif (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or not self:isParticipant(rootID, playerID)) then
		printLuaError("DroidFoundry:onEnterInstance rejected unauthorized player " .. playerID .. " from instance " .. rootID)
		deleteData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)
		deleteData("droidFoundryInstance:" .. playerID)
		CreatureObject(pPlayer):sendSystemMessage("You are not authorized to enter this Droid Foundry expedition instance.")
		createEvent(1000, "DroidFoundry", "returnPlayer", pPlayer, "")
	end

	return 0
end

function DroidFoundry:onExitInstance(pBuilding, pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local rootID = SceneObject(pBuilding):getObjectID()
	if (self:isParticipant(rootID, SceneObject(pPlayer):getObjectID())) then
		self:removeParticipant(rootID, SceneObject(pPlayer):getObjectID())
		createEvent(250, "DroidFoundry", "returnPlayer", pPlayer, "")
	end

	return 0
end

function DroidFoundry:handleTimeout(pBuilding, expectedStart)
	if (pBuilding == nil) then
		return
	end

	local rootID = SceneObject(pBuilding):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or tonumber(readData("droidFoundryStarted:" .. rootID)) ~= tonumber(expectedStart)) then
		return
	end

	self:ejectAllPlayers(self:getInstance(rootID))
	createEvent(5000, "DroidFoundry", "finishTimeout", pBuilding, expectedStart)
end

function DroidFoundry:finishTimeout(pBuilding, expectedStart)
	if (pBuilding == nil) then
		return
	end

	local rootID = SceneObject(pBuilding):getObjectID()
	if (tonumber(readData("droidFoundryStarted:" .. rootID)) == tonumber(expectedStart)) then
		self:releaseInstance(rootID)
	end
end

function DroidFoundry:ejectAllPlayers(instance)
	if (instance == nil) then
		return
	end

	local players = {}
	for i = 1, #instance.cellIDs, 1 do
		local pCell = getSceneObject(instance.cellIDs[i])
		if (pCell ~= nil) then
			for j = 0, SceneObject(pCell):getContainerObjectsSize() - 1, 1 do
				local pObject = SceneObject(pCell):getContainerObject(j)
				if (pObject ~= nil and SceneObject(pObject):isPlayerCreature()) then
					table.insert(players, pObject)
				end
			end
		end
	end

	for i = 1, #players, 1 do
		createEvent(1000, "DroidFoundry", "returnPlayer", players[i], "")
	end
end

function DroidFoundry:returnPlayer(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local rootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0
	local exitZ = getWorldFloor(self.exitX, self.exitY, "lok")

	if (rootID ~= 0 and self:isParticipant(rootID, playerID)) then
		self:removeParticipant(rootID, playerID)
	else
		deleteData("droidFoundryInstance:" .. playerID)
	end

	SceneObject(pPlayer):switchZone("lok", self.exitX, exitZ, self.exitY, 0)
end

function DroidFoundry:releaseInstance(rootID)
	rootID = tonumber(rootID) or 0
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	local eligibilitySize = tonumber(readData("droidFoundryEligibilitySize:" .. rootID)) or 0
	local ownerID = tonumber(readData("droidFoundryOwner:" .. rootID)) or 0

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0) then
			deleteData("droidFoundryParticipant:" .. rootID .. ":" .. playerID)
			if ((tonumber(readData("droidFoundryInstance:" .. playerID)) or 0) == rootID) then
				deleteData("droidFoundryInstance:" .. playerID)
			end
		end
		deleteData("droidFoundryRoster:" .. rootID .. ":" .. i)
	end

	for i = 1, eligibilitySize, 1 do
		local playerID = tonumber(readData("droidFoundryEligibility:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0) then
			deleteData("droidFoundryEligible:" .. rootID .. ":" .. playerID)
			deleteData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)
			if ((tonumber(readData("droidFoundryInvite:" .. playerID)) or 0) == rootID) then
				deleteData("droidFoundryInvite:" .. playerID)
			end
			if ((tonumber(readData("droidFoundryInstance:" .. playerID)) or 0) == rootID) then
				deleteData("droidFoundryInstance:" .. playerID)
			end
		end
		deleteData("droidFoundryEligibility:" .. rootID .. ":" .. i)
	end

	if (ownerID ~= 0 and (tonumber(readData("droidFoundryInstance:" .. ownerID)) or 0) == rootID) then
		deleteData("droidFoundryInstance:" .. ownerID)
	end

	deleteData("droidFoundryRosterSize:" .. rootID)
	deleteData("droidFoundryEligibilitySize:" .. rootID)
	deleteData("droidFoundryParticipantCount:" .. rootID)
	deleteData("droidFoundryGroup:" .. rootID)
	deleteData("droidFoundryActive:" .. rootID)
	deleteData("droidFoundryOwner:" .. rootID)
	deleteData("droidFoundryStarted:" .. rootID)
end

function DroidFoundry:getInstanceRootForCell(cellID)
	cellID = tonumber(cellID) or 0

	for i = 1, #self.instances, 1 do
		local instance = self.instances[i]
		if (cellID == instance.rootID) then
			return instance.rootID
		end

		for j = 1, #instance.cellIDs, 1 do
			if (cellID == instance.cellIDs[j]) then
				return instance.rootID
			end
		end
	end

	return 0
end

function DroidFoundry:getPlayerInstanceRoot(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer):getZoneName() ~= "dungeon1") then
		return 0
	end

	return self:getInstanceRootForCell(SceneObject(pPlayer):getParentID())
end

function DroidFoundry:clearPlayerAssignment(pPlayer, physicalRootID)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local mappedRootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0
	local rootID = tonumber(physicalRootID) or 0
	if (rootID == 0) then
		rootID = mappedRootID
	end

	if (rootID ~= 0 and self:isAdmitted(rootID, playerID)) then
		deleteData("droidFoundryAdmission:" .. rootID .. ":" .. playerID)
		if ((tonumber(readData("droidFoundryParticipantCount:" .. rootID)) or 0) == 0 and (tonumber(readData("droidFoundryOwner:" .. rootID)) or 0) == playerID) then
			self:releaseInstance(rootID)
		end
	end

	if (rootID ~= 0 and self:isParticipant(rootID, playerID)) then
		self:removeParticipant(rootID, playerID)
	end

	for i = 1, #self.instances, 1 do
		if (self:isParticipant(self.instances[i].rootID, playerID)) then
			self:removeParticipant(self.instances[i].rootID, playerID)
		end
	end

	deleteData("droidFoundryInstance:" .. playerID)
end

function DroidFoundry:handlePlayerLogin(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local physicalRootID = self:getPlayerInstanceRoot(pPlayer)
	local loggedOutInside = tonumber(readScreenPlayData(pPlayer, "DroidFoundry", "loggedOutInside")) or 0

	self:clearPlayerAssignment(pPlayer, physicalRootID)
	writeScreenPlayData(pPlayer, "DroidFoundry", "loggedOutInside", 0)

	if (physicalRootID ~= 0 or loggedOutInside == 1) then
		local exitZ = getWorldFloor(self.exitX, self.exitY, "lok")
		SceneObject(pPlayer):switchZone("lok", self.exitX, exitZ, self.exitY, 0)
		CreatureObject(pPlayer):sendSystemMessage("You were returned to the Droid Foundry entrance because your expedition is no longer active.")
	end

	return 0
end

function DroidFoundry:onPlayerLoggedOut(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local physicalRootID = self:getPlayerInstanceRoot(pPlayer)
	self:clearPlayerAssignment(pPlayer, physicalRootID)

	if (physicalRootID ~= 0) then
		writeScreenPlayData(pPlayer, "DroidFoundry", "loggedOutInside", 1)
	end
end

DroidFoundryTerminalMenuComponent = {}

function DroidFoundryTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Begin Droid Foundry Expedition")
end

function DroidFoundryTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isInCombat() or CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	DroidFoundry:beginExpedition(pPlayer)
	return 0
end
