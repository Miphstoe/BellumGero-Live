DroidFoundry = ScreenPlay:new {
	terminalTemplate = "object/tangible/terminal/terminal_nym_cave.iff",
	terminalX = 4784,
	terminalY = 982,
	terminalHeading = 50,
	exitX = 4784,
	exitY = 982,
	timeoutSeconds = 30 * 60,
	entryX = 0.840546,
	entryZ = -4.010900,
	entryY = 16.232117,
	participantRange = 50,
	admissionTimeoutSeconds = 5,

	nexusCellIndex = 5,
	nexusTerminalTemplate = "object/tangible/terminal/terminal_droid_foundry_nexus.iff",
	nexusTerminal = {
		x = -12.9000,
		z = -51.7828,
		y = -176.924,
		heading = 0,
	},
	nexusSecuritySpawns = {
		{ label = "Security Spawn A", x = -11.8647, z = -48.7901, y = -148.075, heading = 180, elite = false },
		{ label = "Security Spawn B", x = 24.4354, z = -52.7565, y = -187.509, heading = -90, elite = false },
		{ label = "Security Spawn C", x = -12.2385, z = -49.4365, y = -216.899, heading = 0, elite = false },
		{ label = "Security Spawn D", x = -55.7501, z = -57.3740, y = -221.262, heading = 45, elite = false },
		{ label = "Elite Spawn", x = -69.9526, z = -55.8785, y = -178.642, heading = 90, elite = true },
	},

	-- Opening Breach encounter. Coordinates are logical-cell local values so the
	-- same layout is reused across all eight physical Foundry instances.
	breachSpawns = {
		-- Cell 2 / r2: first contact
		{ cellIndex = 2, template = "foundry_battle_droid", label = "Breach Cell 2 A", x = 1.1, z = -10.9, y = -16.2, heading = -49 },
		{ cellIndex = 2, template = "foundry_battle_droid", label = "Breach Cell 2 B", x = 2.8, z = -11.1, y = -15.8, heading = -49 },
		{ cellIndex = 2, template = "foundry_battle_droid", label = "Breach Cell 2 C", x = 0.9, z = -11.2, y = -18.2, heading = -49 },

		-- Cell 3 / r3: security begins reinforcing the B1 line
		{ cellIndex = 3, template = "foundry_battle_droid", label = "Breach Cell 3 A", x = -26.8, z = -37.6, y = -60.9, heading = 3 },
		{ cellIndex = 3, template = "foundry_battle_droid", label = "Breach Cell 3 B", x = -25.3, z = -37.7, y = -64.7, heading = 4 },
		{ cellIndex = 3, template = "foundry_security_droid", label = "Breach Cell 3 C", x = -28.5, z = -38.5, y = -65.3, heading = 8 },

		-- Cell 4 / r4: stronger final resistance before the Nexus chamber
		{ cellIndex = 4, template = "foundry_battle_droid", label = "Breach Cell 4 A", x = -23.3, z = -53.3, y = -116.5, heading = -56 },
		{ cellIndex = 4, template = "foundry_security_droid", label = "Breach Cell 4 B", x = -18.2, z = -53.6, y = -118.5, heading = -56 },
		{ cellIndex = 4, template = "foundry_security_droid", label = "Breach Cell 4 C", x = -18.6, z = -53.6, y = -121.6, heading = -56 },
	},

	-- Production approach / Factory Online objective.
	-- Each combat room uses one anchor and a reusable triangle formation.
	productionApproachAnchors = {
		{
			cellIndex = 6,
			label = "Production Cell 6",
			x = 53.5, z = -61.3, y = -190.6, heading = -79,
			spacing = 1.6, depth = 1.4,
			templates = {
				"foundry_battle_droid",
				"foundry_battle_droid",
				"foundry_battle_droid",
			},
		},
		{
			cellIndex = 7,
			label = "Production Cell 7",
			x = 40.9, z = -76.9, y = -243.1, heading = -4,
			spacing = 1.6, depth = 1.4,
			templates = {
				"foundry_battle_droid",
				"foundry_battle_droid",
				"foundry_security_droid",
			},
		},
		{
			cellIndex = 8,
			label = "Production Cell 8",
			x = 98.8, z = -89.2, y = -284.1, heading = -28,
			spacing = 1.8, depth = 1.6,
			templates = {
				"foundry_security_droid",
				"foundry_super_battle_droid",
				"foundry_super_battle_droid",
			},
		},
		{
			cellIndex = 15,
			label = "Production Network",
			x = 110.8, z = -90.9, y = -332.1, heading = -31,
			spacing = 2.2, depth = 1.8,
			objectiveDefenders = true,
			templates = {
				"foundry_super_battle_droid",
				"foundry_super_battle_droid",
				"foundry_elite_b2_enforcer",
			},
		},
	},

	-- Sentinel approach / Droideka defense objective.
	-- Uses the same reusable triangle formation helper as the Production wing.
	sentinelApproachAnchors = {
		{
			cellIndex = 9,
			label = "Sentinel Cell 9",
			x = -6.6, z = -54.9, y = -243.0, heading = -43,
			spacing = 1.6, depth = 1.4,
			templates = {
				"foundry_security_droid",
				"foundry_security_droid",
				"foundry_battle_droid",
			},
		},
		{
			cellIndex = 10,
			label = "Sentinel Cell 10",
			x = 10.5, z = -61.9, y = -271.8, heading = 21,
			spacing = 1.8, depth = 1.5,
			templates = {
				"foundry_security_droid",
				"foundry_security_droid",
				"foundry_droideka_sentinel",
			},
		},
		{
			cellIndex = 11,
			label = "Sentinel Cell 11",
			x = -21.5, z = -74.7, y = -306.7, heading = 1,
			spacing = 2.0, depth = 1.6,
			templates = {
				"foundry_security_droid",
				"foundry_droideka_sentinel",
				"foundry_droideka_sentinel",
			},
		},
		{
			cellIndex = 16,
			label = "Sentinel Core",
			x = -10.9, z = -78.5, y = -359.3, heading = -13,
			spacing = 2.2, depth = 1.8,
			objectiveDefenders = true,
			templates = {
				"foundry_droideka_sentinel",
				"foundry_droideka_sentinel",
				"foundry_elite_droideka_guardian",
			},
		},
	},

	sentinelTerminalCellIndex = 16,
	sentinelTerminal = {
		x = -9.3,
		z = -78.6,
		y = -371.1,
		heading = -1,
	},

	-- Maintenance approach / repair-support objective.
	-- Uses the same reusable triangle formation helper as Production and Sentinel.
	maintenanceApproachAnchors = {
		{
			cellIndex = 12,
			label = "Maintenance Cell 12",
			x = -67.3086, z = -68.3687, y = -253.497, heading = 29,
			spacing = 1.6, depth = 1.4,
			templates = {
				"foundry_repair_droid",
				"foundry_repair_droid",
				"foundry_repair_droid",
			},
		},
		{
			cellIndex = 13,
			label = "Maintenance Cell 13",
			x = -107.252, z = -78.6663, y = -272.805, heading = 37,
			spacing = 1.7, depth = 1.5,
			templates = {
				"foundry_repair_droid",
				"foundry_repair_droid",
				"foundry_security_droid",
			},
		},
		{
			cellIndex = 14,
			label = "Maintenance Cell 14",
			x = -79.9851, z = -85.8939, y = -307.491, heading = 0,
			spacing = 1.9, depth = 1.6,
			templates = {
				"foundry_repair_droid",
				"foundry_repair_droid",
				"foundry_super_battle_droid",
			},
		},
		{
			cellIndex = 17,
			label = "Maintenance Network",
			x = -95.0434, z = -84.5311, y = -336.21, heading = 45,
			spacing = 2.1, depth = 1.8,
			objectiveDefenders = true,
			templates = {
				"foundry_repair_droid",
				"foundry_repair_droid",
				"foundry_elite_b2_enforcer",
			},
		},
	},

	maintenanceTerminalCellIndex = 17,
	maintenanceTerminal = {
		x = -114.526,
		z = -83.0152,
		y = -324.152,
		heading = 113,
	},

	-- Final approach and Overseer chamber.
	-- World Builder authoritative mapping:
	-- Cell 18 = r21, Cell 19 = r22, Cell 20 = roomaab.
	finalApproachAnchors = {
		{
			cellIndex = 18,
			label = "Final Approach r21",
			x = 83.9, z = -100.5, y = -365.2, heading = 11,
			spacing = 1.9, depth = 1.6,
			templates = {
				"foundry_security_droid",
				"foundry_super_battle_droid",
				"foundry_super_battle_droid",
			},
		},
		{
			cellIndex = 19,
			label = "Final Approach r22",
			x = 57.3, z = -113.4, y = -357.0, heading = 136,
			spacing = 2.1, depth = 1.7,
			templates = {
				"foundry_super_battle_droid",
				"foundry_droideka_sentinel",
				"foundry_elite_b2_enforcer",
			},
		},
	},

	overseerCellIndex = 20,
	overseerAnchor = {
		x = -3.1,
		z = -120.6,
		y = -369.7,
		heading = 62,
	},

	-- Each supplied reinforcement area becomes a small three-point formation.
	overseerReinforcementAnchors = {
		{
			x = 15.1, z = -118.3, y = -384.2, heading = -43,
			spacing = 2.0, depth = 1.7,
		},
		{
			x = 2.2, z = -118.6, y = -347.9, heading = -176,
			spacing = 2.0, depth = 1.7,
		},
	},

	archiveTerminal = {
		x = -27.0,
		z = -118.8,
		y = -370.2,
		heading = 82,
	},

	productionTerminalCellIndex = 15,
	productionTerminal = {
		x = 126.9,
		z = -92.6,
		y = -328.2,
		heading = -87,
	},

	NEXUS_READY = 1,
	NEXUS_ACTIVE = 2,
	NEXUS_COMPLETE = 3,

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
	local pTerminal = spawnSceneObject("lok", self.terminalTemplate, self.terminalX, terminalZ, self.terminalY, 0, math.rad(self.terminalHeading or 0))

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

			if (not self:prepareNexusEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry control systems failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

			if (not self:prepareBreachEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry breach defenses failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

			if (not self:prepareProductionEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry production systems failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

			if (not self:prepareSentinelEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry sentinel systems failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

			if (not self:prepareMaintenanceEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry maintenance systems failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

			if (not self:prepareFinalEncounter(instance.rootID)) then
				CreatureObject(pPlayer):sendSystemMessage("The Droid Foundry final sector failed to initialize. Please try another expedition.")
				self:releaseInstance(instance.rootID)
				return
			end

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

	createObserver(PLAYERKILLED, "DroidFoundry", "onParticipantKilled", pPlayer)
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

function DroidFoundry:clearInternalTransfer(pPlayer, rootIDString)
	if (pPlayer == nil) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local rootID = tonumber(rootIDString) or 0
	local key = "droidFoundryInternalTransfer:" .. playerID

	if ((tonumber(readData(key)) or 0) == rootID) then
		deleteData(key)
	end

	return 0
end

function DroidFoundry:onEnterInstance(pBuilding, pPlayer)
	local buildingID = pBuilding ~= nil and SceneObject(pBuilding):getObjectID() or 0

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local rootID = buildingID
	local playerID = SceneObject(pPlayer):getObjectID()
	local internalTransferKey = "droidFoundryInternalTransfer:" .. playerID
	local internalTransferRoot = tonumber(readData(internalTransferKey)) or 0

	if (internalTransferRoot == rootID and self:isParticipant(rootID, playerID)) then
		deleteData(internalTransferKey)
		return 0
	end

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
	local playerID = SceneObject(pPlayer):getObjectID()
	local internalTransferRoot = tonumber(readData("droidFoundryInternalTransfer:" .. playerID)) or 0

	if (internalTransferRoot == rootID and self:isParticipant(rootID, playerID)) then
		return 0
	end

	if (self:isParticipant(rootID, playerID)) then
		self:removeParticipant(rootID, playerID)
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
	self:cleanupEncounter(rootID)
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


function DroidFoundry:getInstanceCellID(rootID, cellIndex)
	local instance = self:getInstance(rootID)
	cellIndex = tonumber(cellIndex) or 0

	if (instance == nil or cellIndex < 1 or cellIndex > #instance.cellIDs) then
		return 0
	end

	return tonumber(instance.cellIDs[cellIndex]) or 0
end

function DroidFoundry:destroyEncounterObjectByID(objectID)
	objectID = tonumber(objectID) or 0
	if (objectID == 0) then
		return
	end

	local pObject = getSceneObject(objectID)
	if (pObject ~= nil) then
		pcall(function()
			SceneObject(pObject):destroyObjectFromWorld()
		end)
		pcall(function()
			SceneObject(pObject):destroyObjectFromDatabase()
		end)
	end
end

function DroidFoundry:trackEncounterObject(rootID, pObject)
	if (pObject == nil) then
		return 0
	end

	local objectID = SceneObject(pObject):getObjectID()
	local countKey = "droidFoundryEncounterObjectCount:" .. rootID
	local count = (tonumber(readData(countKey)) or 0) + 1

	writeData(countKey, count)
	writeData("droidFoundryEncounterObject:" .. rootID .. ":" .. count, objectID)
	writeData("droidFoundryEncounterRoot:" .. objectID, rootID)

	return objectID
end

function DroidFoundry:cleanupEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return
	end

	writeData("droidFoundryEncounterCleaning:" .. rootID, 1)

	local count = tonumber(readData("droidFoundryEncounterObjectCount:" .. rootID)) or 0
	for i = 1, count, 1 do
		local objectKey = "droidFoundryEncounterObject:" .. rootID .. ":" .. i
		local objectID = tonumber(readData(objectKey)) or 0

		if (objectID ~= 0) then
			deleteData("droidFoundryEncounterRoot:" .. objectID)
			self:destroyEncounterObjectByID(objectID)
		end

		deleteData(objectKey)
	end

	deleteData("droidFoundryEncounterObjectCount:" .. rootID)
	deleteData("droidFoundryNexusTerminal:" .. rootID)
	deleteData("droidFoundryNexusState:" .. rootID)
	deleteData("droidFoundryNexusWaveStage:" .. rootID)
	deleteData("droidFoundryNexusAlive:" .. rootID)
	deleteData("droidFoundryNexusActivator:" .. rootID)
	deleteData("droidFoundryProductionDisabled:" .. rootID)
	deleteData("droidFoundryProductionAlive:" .. rootID)
	deleteData("droidFoundryProductionTerminal:" .. rootID)
	deleteData("droidFoundrySentinelDisabled:" .. rootID)
	deleteData("droidFoundrySentinelAlive:" .. rootID)
	deleteData("droidFoundrySentinelTerminal:" .. rootID)
	deleteData("droidFoundryMaintenanceDisabled:" .. rootID)
	deleteData("droidFoundryMaintenanceAlive:" .. rootID)
	deleteData("droidFoundryMaintenanceTerminal:" .. rootID)
	deleteData("droidFoundryOverseerState:" .. rootID)
	deleteData("droidFoundryOverseerBoss:" .. rootID)
	deleteData("droidFoundryOverseerTarget:" .. rootID)
	deleteData("droidFoundryOverseerRepairDroid:" .. rootID)
	deleteData("droidFoundryOverseerPhase75:" .. rootID)
	deleteData("droidFoundryOverseerPhase50:" .. rootID)
	deleteData("droidFoundryOverseerPhase25:" .. rootID)
	deleteData("droidFoundryOverseerLastRepair:" .. rootID)
	deleteData("droidFoundryOverseerNextOverload:" .. rootID)

	local overseerTrackedCount = tonumber(readData("droidFoundryOverseerTrackedCount:" .. rootID)) or 0
	for i = 1, overseerTrackedCount, 1 do
		deleteData("droidFoundryOverseerTracked:" .. rootID .. ":" .. i)
	end
	deleteData("droidFoundryOverseerTrackedCount:" .. rootID)
	self:clearOverseerDownFlags(rootID)

	deleteData("droidFoundryArchiveTerminal:" .. rootID)
	deleteData("droidFoundryRunProtocol:" .. rootID)
	deleteData("droidFoundryEncounterCleaning:" .. rootID)
end

function DroidFoundry:prepareNexusEncounter(rootID)
	rootID = tonumber(rootID) or 0
	local cellID = self:getInstanceCellID(rootID, self.nexusCellIndex)

	if (rootID == 0 or cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:prepareNexusEncounter unable to resolve Nexus cell for instance " .. rootID)
		return false
	end

	self:cleanupEncounter(rootID)

	local serialKey = "droidFoundryEncounterSerial:" .. rootID
	local serial = (tonumber(readData(serialKey)) or 0) + 1
	writeData(serialKey, serial)

	writeData("droidFoundryNexusState:" .. rootID, self.NEXUS_READY)
	writeData("droidFoundryNexusWaveStage:" .. rootID, 0)
	writeData("droidFoundryNexusAlive:" .. rootID, 0)
	writeData("droidFoundryProductionDisabled:" .. rootID, 0)
	writeData("droidFoundrySentinelDisabled:" .. rootID, 0)
	writeData("droidFoundryMaintenanceDisabled:" .. rootID, 0)
	writeData("droidFoundryRunProtocol:" .. rootID, 0)

	local point = self.nexusTerminal
	local pTerminal = spawnSceneObject(
		"dungeon1",
		self.nexusTerminalTemplate,
		point.x,
		point.z,
		point.y,
		cellID,
		math.rad(point.heading or 0)
	)

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareNexusEncounter failed to spawn Nexus terminal for instance " .. rootID)
		self:cleanupEncounter(rootID)
		return false
	end

	SceneObject(pTerminal):setCustomObjectName("Foundry Control Nexus")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundryNexusTerminalMenuComponent")

	local terminalID = self:trackEncounterObject(rootID, pTerminal)
	writeData("droidFoundryNexusTerminal:" .. rootID, terminalID)

	return true
end

function DroidFoundry:spawnBreachUnit(rootID, spawn)
	if (spawn == nil) then
		return nil
	end

	local cellID = self:getInstanceCellID(rootID, spawn.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:spawnBreachUnit unable to resolve cell " .. tostring(spawn.cellIndex) .. " for instance " .. rootID)
		return nil
	end

	local pMobile = spawnMobile(
		"dungeon1",
		spawn.template,
		0,
		spawn.x,
		spawn.z,
		spawn.y,
		spawn.heading or 0,
		cellID
	)

	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnBreachUnit failed at " .. tostring(spawn.label) .. " for instance " .. rootID)
		return nil
	end

	self:trackEncounterObject(rootID, pMobile)
	return pMobile
end

function DroidFoundry:prepareBreachEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return false
	end

	for i = 1, #self.breachSpawns, 1 do
		if (self:spawnBreachUnit(rootID, self.breachSpawns[i]) == nil) then
			printLuaError("DroidFoundry:prepareBreachEncounter failed for instance " .. rootID)
			return false
		end
	end

	return true
end

function DroidFoundry:getTriangleFormation(anchor)
	local heading = math.rad(anchor.heading or 0)
	local spacing = tonumber(anchor.spacing) or 1.6
	local depth = tonumber(anchor.depth) or 1.4

	-- SWG interior movement uses X/Y as the horizontal plane and Z as height.
	-- Point 1 is the supplied anchor; points 2/3 sit behind it in a shallow triangle.
	local forwardX = math.sin(heading)
	local forwardY = math.cos(heading)
	local rightX = math.cos(heading)
	local rightY = -math.sin(heading)

	local backX = anchor.x - (forwardX * depth)
	local backY = anchor.y - (forwardY * depth)

	return {
		{ x = anchor.x, z = anchor.z, y = anchor.y, heading = anchor.heading or 0 },
		{ x = backX + (rightX * spacing), z = anchor.z, y = backY + (rightY * spacing), heading = anchor.heading or 0 },
		{ x = backX - (rightX * spacing), z = anchor.z, y = backY - (rightY * spacing), heading = anchor.heading or 0 },
	}
end

function DroidFoundry:spawnProductionUnit(rootID, anchor, templateName, pointIndex)
	local cellID = self:getInstanceCellID(rootID, anchor.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:spawnProductionUnit unable to resolve cell " .. tostring(anchor.cellIndex) .. " for instance " .. rootID)
		return nil
	end

	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]

	if (point == nil) then
		return nil
	end

	local pMobile = spawnMobile(
		"dungeon1",
		templateName,
		0,
		point.x,
		point.z,
		point.y,
		point.heading or 0,
		cellID
	)

	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnProductionUnit failed at " .. tostring(anchor.label) .. " point " .. tostring(pointIndex) .. " for instance " .. rootID)
		return nil
	end

	self:trackEncounterObject(rootID, pMobile)

	if (anchor.objectiveDefenders) then
		writeData("droidFoundryProductionAlive:" .. rootID, (tonumber(readData("droidFoundryProductionAlive:" .. rootID)) or 0) + 1)
		createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyProductionDefenderDestroyed", pMobile)
	end

	return pMobile
end

function DroidFoundry:prepareProductionEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return false
	end

	writeData("droidFoundryProductionAlive:" .. rootID, 0)

	for i = 1, #self.productionApproachAnchors, 1 do
		local anchor = self.productionApproachAnchors[i]

		for j = 1, #anchor.templates, 1 do
			if (self:spawnProductionUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareProductionEncounter failed for instance " .. rootID)
				return false
			end
		end
	end

	local cellID = self:getInstanceCellID(rootID, self.productionTerminalCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:prepareProductionEncounter unable to resolve Production terminal cell for instance " .. rootID)
		return false
	end

	local point = self.productionTerminal
	local pTerminal = spawnSceneObject(
		"dungeon1",
		self.nexusTerminalTemplate,
		point.x,
		point.z,
		point.y,
		cellID,
		math.rad(point.heading or 0)
	)

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareProductionEncounter failed to spawn Production Network terminal for instance " .. rootID)
		return false
	end

	SceneObject(pTerminal):setCustomObjectName("Foundry Production Network - ONLINE")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundryProductionTerminalMenuComponent")
	writeData("droidFoundryProductionTerminal:" .. rootID, self:trackEncounterObject(rootID, pTerminal))

	return true
end

function DroidFoundry:notifyProductionDefenderDestroyed(pMobile)
	if (pMobile == nil) then
		return 1
	end

	local mobileID = SceneObject(pMobile):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. mobileID)) or 0

	if (rootID == 0 or tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1) then
		return 1
	end

	local aliveKey = "droidFoundryProductionAlive:" .. rootID
	local alive = math.max(0, (tonumber(readData(aliveKey)) or 0) - 1)
	writeData(aliveKey, alive)

	if (alive == 0) then
		self:sendInstanceMessage(rootID, "Production Network defenders neutralized. The factory control interface is accessible.")
	end

	return 1
end

function DroidFoundry:disableProductionNetwork(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0

	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Production Network is not assigned to your expedition.")
		return false
	end

	if ((tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0) ~= self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus must be brought online before this network can be accessed.")
		return false
	end

	if (tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("The Production Network is already offline.")
		return false
	end

	if ((tonumber(readData("droidFoundryProductionAlive:" .. rootID)) or 0) > 0) then
		CreatureObject(pPlayer):sendSystemMessage("Production Network access is locked while factory defenders remain active.")
		return false
	end

	writeData("droidFoundryProductionDisabled:" .. rootID, 1)
	SceneObject(pTerminal):setCustomObjectName("Foundry Production Network - OFFLINE")
	self:sendInstanceMessage(rootID, "Production Network disabled. B1 reinforcement protocol has been disrupted.")

	return true
end

function DroidFoundry:spawnSentinelUnit(rootID, anchor, templateName, pointIndex)
	local cellID = self:getInstanceCellID(rootID, anchor.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:spawnSentinelUnit unable to resolve cell " .. tostring(anchor.cellIndex) .. " for instance " .. rootID)
		return nil
	end

	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]
	if (point == nil) then
		return nil
	end

	local pMobile = spawnMobile("dungeon1", templateName, 0, point.x, point.z, point.y, point.heading or 0, cellID)

	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnSentinelUnit failed at " .. tostring(anchor.label) .. " point " .. tostring(pointIndex) .. " for instance " .. rootID)
		return nil
	end

	self:trackEncounterObject(rootID, pMobile)

	if (anchor.objectiveDefenders) then
		writeData("droidFoundrySentinelAlive:" .. rootID, (tonumber(readData("droidFoundrySentinelAlive:" .. rootID)) or 0) + 1)
		createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifySentinelDefenderDestroyed", pMobile)
	end

	return pMobile
end

function DroidFoundry:prepareSentinelEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return false
	end

	writeData("droidFoundrySentinelAlive:" .. rootID, 0)

	for i = 1, #self.sentinelApproachAnchors, 1 do
		local anchor = self.sentinelApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnSentinelUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareSentinelEncounter failed for instance " .. rootID)
				return false
			end
		end
	end

	local cellID = self:getInstanceCellID(rootID, self.sentinelTerminalCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:prepareSentinelEncounter unable to resolve Sentinel terminal cell for instance " .. rootID)
		return false
	end

	local point = self.sentinelTerminal
	local pTerminal = spawnSceneObject(
		"dungeon1",
		self.nexusTerminalTemplate,
		point.x,
		point.z,
		point.y,
		cellID,
		math.rad(point.heading or 0)
	)

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareSentinelEncounter failed to spawn Sentinel Network terminal for instance " .. rootID)
		return false
	end

	SceneObject(pTerminal):setCustomObjectName("Foundry Sentinel Network - ONLINE")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundrySentinelTerminalMenuComponent")
	writeData("droidFoundrySentinelTerminal:" .. rootID, self:trackEncounterObject(rootID, pTerminal))

	return true
end

function DroidFoundry:notifySentinelDefenderDestroyed(pMobile)
	if (pMobile == nil) then
		return 1
	end

	local mobileID = SceneObject(pMobile):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. mobileID)) or 0

	if (rootID == 0 or tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1) then
		return 1
	end

	local aliveKey = "droidFoundrySentinelAlive:" .. rootID
	local alive = math.max(0, (tonumber(readData(aliveKey)) or 0) - 1)
	writeData(aliveKey, alive)

	if (alive == 0) then
		self:sendInstanceMessage(rootID, "Sentinel Core defenders neutralized. The defensive control interface is accessible.")
	end

	return 1
end

function DroidFoundry:disableSentinelNetwork(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0

	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Sentinel Network is not assigned to your expedition.")
		return false
	end

	if ((tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0) ~= self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus must be brought online before this network can be accessed.")
		return false
	end

	if (tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("The Sentinel Network is already offline.")
		return false
	end

	if ((tonumber(readData("droidFoundrySentinelAlive:" .. rootID)) or 0) > 0) then
		CreatureObject(pPlayer):sendSystemMessage("Sentinel Network access is locked while defensive units remain active.")
		return false
	end

	writeData("droidFoundrySentinelDisabled:" .. rootID, 1)
	SceneObject(pTerminal):setCustomObjectName("Foundry Sentinel Network - OFFLINE")
	self:sendInstanceMessage(rootID, "Sentinel Network disabled. Droideka reinforcement protocol has been disrupted.")

	return true
end

function DroidFoundry:spawnMaintenanceUnit(rootID, anchor, templateName, pointIndex)
	local cellID = self:getInstanceCellID(rootID, anchor.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:spawnMaintenanceUnit unable to resolve cell " .. tostring(anchor.cellIndex) .. " for instance " .. rootID)
		return nil
	end

	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]
	if (point == nil) then
		return nil
	end

	local pMobile = spawnMobile(
		"dungeon1",
		templateName,
		0,
		point.x,
		point.z,
		point.y,
		point.heading or 0,
		cellID
	)

	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnMaintenanceUnit failed at " .. tostring(anchor.label) .. " point " .. tostring(pointIndex) .. " for instance " .. rootID)
		return nil
	end

	self:trackEncounterObject(rootID, pMobile)

	if (anchor.objectiveDefenders) then
		writeData("droidFoundryMaintenanceAlive:" .. rootID, (tonumber(readData("droidFoundryMaintenanceAlive:" .. rootID)) or 0) + 1)
		createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyMaintenanceDefenderDestroyed", pMobile)
	end

	return pMobile
end

function DroidFoundry:prepareMaintenanceEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return false
	end

	writeData("droidFoundryMaintenanceAlive:" .. rootID, 0)

	for i = 1, #self.maintenanceApproachAnchors, 1 do
		local anchor = self.maintenanceApproachAnchors[i]

		for j = 1, #anchor.templates, 1 do
			if (self:spawnMaintenanceUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareMaintenanceEncounter failed for instance " .. rootID)
				return false
			end
		end
	end

	local cellID = self:getInstanceCellID(rootID, self.maintenanceTerminalCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:prepareMaintenanceEncounter unable to resolve Maintenance terminal cell for instance " .. rootID)
		return false
	end

	local point = self.maintenanceTerminal
	local pTerminal = spawnSceneObject(
		"dungeon1",
		self.nexusTerminalTemplate,
		point.x,
		point.z,
		point.y,
		cellID,
		math.rad(point.heading or 0)
	)

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareMaintenanceEncounter failed to spawn Maintenance Network terminal for instance " .. rootID)
		return false
	end

	SceneObject(pTerminal):setCustomObjectName("Foundry Maintenance Network - ONLINE")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundryMaintenanceTerminalMenuComponent")
	writeData("droidFoundryMaintenanceTerminal:" .. rootID, self:trackEncounterObject(rootID, pTerminal))

	return true
end

function DroidFoundry:notifyMaintenanceDefenderDestroyed(pMobile)
	if (pMobile == nil) then
		return 1
	end

	local mobileID = SceneObject(pMobile):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. mobileID)) or 0

	if (rootID == 0 or tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1) then
		return 1
	end

	local aliveKey = "droidFoundryMaintenanceAlive:" .. rootID
	local alive = math.max(0, (tonumber(readData(aliveKey)) or 0) - 1)
	writeData(aliveKey, alive)

	if (alive == 0) then
		self:sendInstanceMessage(rootID, "Maintenance Network defenders neutralized. The repair control interface is accessible.")
	end

	return 1
end

function DroidFoundry:disableMaintenanceNetwork(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0

	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Maintenance Network is not assigned to your expedition.")
		return false
	end

	if ((tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0) ~= self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus must be brought online before this network can be accessed.")
		return false
	end

	if (tonumber(readData("droidFoundryMaintenanceDisabled:" .. rootID)) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("The Maintenance Network is already offline.")
		return false
	end

	if ((tonumber(readData("droidFoundryMaintenanceAlive:" .. rootID)) or 0) > 0) then
		CreatureObject(pPlayer):sendSystemMessage("Maintenance Network access is locked while repair-security units remain active.")
		return false
	end

	writeData("droidFoundryMaintenanceDisabled:" .. rootID, 1)
	SceneObject(pTerminal):setCustomObjectName("Foundry Maintenance Network - OFFLINE")
	self:sendInstanceMessage(rootID, "Maintenance Network disabled. Overseer repair-support protocol has been disrupted.")

	return true
end

function DroidFoundry:spawnFinalApproachUnit(rootID, anchor, templateName, pointIndex)
	local cellID = self:getInstanceCellID(rootID, anchor.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:spawnFinalApproachUnit unable to resolve cell " .. tostring(anchor.cellIndex) .. " for instance " .. rootID)
		return nil
	end

	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]
	if (point == nil) then
		return nil
	end

	local pMobile = spawnMobile("dungeon1", templateName, 0, point.x, point.z, point.y, point.heading or 0, cellID)
	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnFinalApproachUnit failed at " .. tostring(anchor.label) .. " for instance " .. rootID)
		return nil
	end

	self:trackEncounterObject(rootID, pMobile)
	return pMobile
end

function DroidFoundry:trackOverseerObject(rootID, pObject)
	if (rootID == 0 or pObject == nil) then
		return
	end

	local objectID = SceneObject(pObject):getObjectID()
	if (objectID == 0) then
		return
	end

	local count = tonumber(readData("droidFoundryOverseerTrackedCount:" .. rootID)) or 0
	count = count + 1

	writeData("droidFoundryOverseerTrackedCount:" .. rootID, count)
	writeData("droidFoundryOverseerTracked:" .. rootID .. ":" .. count, objectID)
end

function DroidFoundry:clearOverseerDownFlags(rootID)
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0) then
			deleteData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID)
		end
	end
end

function DroidFoundry:refreshOverseerParticipantReturns(rootID)
	if ((tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return
	end

	local bossCellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (bossCellID == 0) then
		return
	end

	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0

		if (playerID ~= 0 and self:isParticipant(rootID, playerID) and
			tonumber(readData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID)) == 1) then

			local pMember = getSceneObject(playerID)
			if (pMember ~= nil and not CreatureObject(pMember):isDead() and
				not CreatureObject(pMember):isIncapacitated() and
				SceneObject(pMember):getParentID() == bossCellID) then

				deleteData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID)
				CreatureObject(pMember):sendSystemMessage("You have rejoined the Overseer encounter.")
			end
		end
	end
end

function DroidFoundry:resetOverseerAfterWipe(rootID)
	if (rootID == 0 or (tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return
	end

	writeData("droidFoundryOverseerState:" .. rootID, 0)
	writeData("droidFoundryEncounterCleaning:" .. rootID, 1)

	local trackedCount = tonumber(readData("droidFoundryOverseerTrackedCount:" .. rootID)) or 0
	for i = 1, trackedCount, 1 do
		local objectID = tonumber(readData("droidFoundryOverseerTracked:" .. rootID .. ":" .. i)) or 0
		if (objectID ~= 0) then
			self:destroyEncounterObjectByID(objectID)
		end
		deleteData("droidFoundryOverseerTracked:" .. rootID .. ":" .. i)
	end

	deleteData("droidFoundryOverseerTrackedCount:" .. rootID)
	writeData("droidFoundryEncounterCleaning:" .. rootID, 0)

	deleteData("droidFoundryOverseerBoss:" .. rootID)
	deleteData("droidFoundryOverseerTarget:" .. rootID)
	deleteData("droidFoundryOverseerRepairDroid:" .. rootID)
	deleteData("droidFoundryOverseerPhase75:" .. rootID)
	deleteData("droidFoundryOverseerPhase50:" .. rootID)
	deleteData("droidFoundryOverseerPhase25:" .. rootID)
	deleteData("droidFoundryOverseerLastRepair:" .. rootID)
	deleteData("droidFoundryOverseerNextOverload:" .. rootID)

	self:clearOverseerDownFlags(rootID)

	local terminalID = tonumber(readData("droidFoundryArchiveTerminal:" .. rootID)) or 0
	local pTerminal = getSceneObject(terminalID)
	if (pTerminal ~= nil) then
		SceneObject(pTerminal):setCustomObjectName("Foundry Archive Interface - LOCKED")
	end

	self:sendInstanceMessage(rootID, "All active expedition members have fallen. Overseer combat protocol has reset.")
end

function DroidFoundry:checkOverseerWipe(pPlayer, rootIDString)
	local rootID = tonumber(rootIDString) or 0
	if (rootID == 0 or (tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return 0
	end

	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	local hasParticipant = false

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0

		if (playerID ~= 0 and self:isParticipant(rootID, playerID)) then
			hasParticipant = true

			if (tonumber(readData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID)) ~= 1) then
				local pMember = getSceneObject(playerID)

				if (pMember ~= nil and not CreatureObject(pMember):isDead() and
					not CreatureObject(pMember):isIncapacitated()) then
					return 0
				end

				if (pMember ~= nil) then
					writeData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID, 1)
				else
					return 0
				end
			end
		end
	end

	if (hasParticipant) then
		self:resetOverseerAfterWipe(rootID)
	end

	return 0
end

function DroidFoundry:recoverParticipantAfterDeath(pPlayer, rootIDString)
	local rootID = tonumber(rootIDString) or 0
	if (pPlayer == nil or rootID == 0) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (playerID == 0 or not self:isParticipant(rootID, playerID) or
		(tonumber(readData("droidFoundryActive:" .. rootID)) or 0) ~= 1) then
		return 0
	end

	local player = CreatureObject(pPlayer)

	for pool = 0, 8, 1 do
		local maximum = tonumber(player:getMaxHAM(pool)) or 0
		if (maximum > 0) then
			player:setHAM(pool, maximum)
		end
	end

	player:setPosture(UPRIGHT)

	local instance = self:getInstance(rootID)
	local destinationCellID = instance ~= nil and instance.cellIDs[1] or 0

	if (destinationCellID == 0 or getSceneObject(destinationCellID) == nil) then
		printLuaError("DroidFoundry:recoverParticipantAfterDeath invalid Cell 1 destination for instance " .. rootID)
		return 0
	end

	-- Internal Foundry recovery: switch back to the exact normal Cell 1 insertion
	-- point without allowing the building exit observer to remove the participant.
	writeData("droidFoundryInternalTransfer:" .. playerID, rootID)
	SceneObject(pPlayer):switchZone("dungeon1", self.entryX, self.entryZ, self.entryY, destinationCellID)
	createEvent(2000, "DroidFoundry", "clearInternalTransfer", pPlayer, tostring(rootID))

	player:sendSystemMessage("You recover at the Droid Foundry entrance. Your expedition remains active.")

	createObserver(PLAYERKILLED, "DroidFoundry", "onParticipantKilled", pPlayer)

	return 0
end

function DroidFoundry:onParticipantKilled(pPlayer, pKiller, nothing)
	if (pPlayer == nil) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local rootID = tonumber(readData("droidFoundryInstance:" .. playerID)) or 0

	if (rootID == 0 or not self:isParticipant(rootID, playerID) or
		(tonumber(readData("droidFoundryActive:" .. rootID)) or 0) ~= 1) then
		return 1
	end

	if ((tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) == 1) then
		writeData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID, 1)
		createEvent(250, "DroidFoundry", "checkOverseerWipe", pPlayer, tostring(rootID))
	end

	createEvent(750, "DroidFoundry", "recoverParticipantAfterDeath", pPlayer, tostring(rootID))

	return 1
end

function DroidFoundry:spawnOverseerSupport(rootID, templateName, anchorIndex, pointIndex)
	local cellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		return nil
	end

	local anchor = self.overseerReinforcementAnchors[anchorIndex]
	if (anchor == nil) then
		return nil
	end

	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]
	if (point == nil) then
		return nil
	end

	local pMobile = spawnMobile(
		"dungeon1",
		templateName,
		0,
		point.x,
		point.z,
		point.y,
		point.heading or 0,
		cellID
	)

	if (pMobile ~= nil) then
		self:trackEncounterObject(rootID, pMobile)
		self:trackOverseerObject(rootID, pMobile)

		local targetID = tonumber(readData("droidFoundryOverseerTarget:" .. rootID)) or 0
		local pTarget = getSceneObject(targetID)

		if (pTarget ~= nil) then
			local ai = AiAgent(pMobile)
			if (ai ~= nil) then
				ai:setAITemplate()
				ai:addDefender(pTarget)
			end
		end
	end

	return pMobile
end

function DroidFoundry:prepareFinalEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return false
	end

	for i = 1, #self.finalApproachAnchors, 1 do
		local anchor = self.finalApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnFinalApproachUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareFinalEncounter failed while spawning final approach for instance " .. rootID)
				return false
			end
		end
	end

	local cellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError("DroidFoundry:prepareFinalEncounter unable to resolve Overseer chamber for instance " .. rootID)
		return false
	end

	local point = self.archiveTerminal
	local pTerminal = spawnSceneObject(
		"dungeon1",
		self.nexusTerminalTemplate,
		point.x,
		point.z,
		point.y,
		cellID,
		math.rad(point.heading or 0)
	)

	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareFinalEncounter failed to spawn Archive interface for instance " .. rootID)
		return false
	end

	SceneObject(pTerminal):setCustomObjectName("Foundry Archive Interface - LOCKED")
	SceneObject(pTerminal):setObjectMenuComponent("DroidFoundryArchiveTerminalMenuComponent")
	writeData("droidFoundryArchiveTerminal:" .. rootID, self:trackEncounterObject(rootID, pTerminal))
	writeData("droidFoundryOverseerState:" .. rootID, 0)

	return true
end

function DroidFoundry:getOverseerNetworkStatus(rootID)
	local productionDisabled = tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) == 1
	local sentinelDisabled = tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) == 1
	local maintenanceDisabled = tonumber(readData("droidFoundryMaintenanceDisabled:" .. rootID)) == 1

	local productionLine = productionDisabled
		and "Production Network: OFFLINE - B1 reinforcement protocol disrupted."
		or "Production Network: ONLINE - B1 reinforcements available."

	local sentinelLine = sentinelDisabled
		and "Sentinel Network: OFFLINE - Droideka reinforcement protocol disrupted."
		or "Sentinel Network: ONLINE - Droideka reinforcements available."

	local maintenanceLine = maintenanceDisabled
		and "Maintenance Network: OFFLINE - Overseer repair-support protocol disrupted."
		or "Maintenance Network: ONLINE - Repair support available."

	local onlineCount = 0
	if (not productionDisabled) then onlineCount = onlineCount + 1 end
	if (not sentinelDisabled) then onlineCount = onlineCount + 1 end
	if (not maintenanceDisabled) then onlineCount = onlineCount + 1 end

	return productionLine, sentinelLine, maintenanceLine, onlineCount
end

function DroidFoundry:showOverseerStatusSui(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0

	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Foundry Archive interface is not assigned to your expedition.")
		return
	end

	if ((tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0) ~= self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus must be online before the Overseer can be engaged.")
		return
	end

	local productionLine, sentinelLine, maintenanceLine, onlineCount = self:getOverseerNetworkStatus(rootID)

	local warning = ""
	if (onlineCount == 3) then
		warning = "\n\nWARNING: All auxiliary Foundry systems remain operational. The Overseer will engage with full reinforcement and repair support."
	elseif (onlineCount > 0) then
		warning = "\n\nOne or more auxiliary Foundry systems remain operational. Disabling them elsewhere in the Foundry will weaken the Overseer encounter."
	else
		warning = "\n\nAll auxiliary Foundry systems have been disabled. The Overseer's support protocols are fully disrupted."
	end

	local prompt =
		"Current Foundry systems:\n\n" ..
		productionLine .. "\n" ..
		sentinelLine .. "\n" ..
		maintenanceLine ..
		warning ..
		"\n\nEngage the Foundry Overseer?"

	local sui = SuiMessageBox.new("DroidFoundry", "overseerStatusSuiCallback")
	sui.setTitle("FOUNDRY OVERSEER PROTOCOL")
	sui.setPrompt(prompt)
	sui.setOkButtonText("Engage Overseer")
	sui.setCancelButtonText("Not Yet")
	sui.setTargetNetworkId(SceneObject(pTerminal):getObjectID())
	sui.setForceCloseDistance(8)
	sui.setProperty("", "Size", "520,330")
	sui.sendTo(pPlayer)
end

function DroidFoundry:overseerStatusSuiCallback(pPlayer, pSui, eventIndex)
	if (pPlayer == nil or eventIndex ~= 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()
	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local terminalID = suiPageData:getTargetNetworkId()
	local pTerminal = getSceneObject(terminalID)

	if (pTerminal == nil) then
		return
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pTerminal, 8)) then
		return
	end

	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0
	if (rootID == 0) then
		return
	end

	self:startOverseerEncounter(pPlayer, rootID)
end

function DroidFoundry:startOverseerEncounter(pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pPlayer == nil or rootID == 0) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (not self:isParticipant(rootID, playerID) or self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Foundry Archive interface is not assigned to your expedition.")
		return false
	end

	if ((tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0) ~= self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus must be online before the Overseer can be engaged.")
		return false
	end

	local stateKey = "droidFoundryOverseerState:" .. rootID
	if ((tonumber(readData(stateKey)) or 0) ~= 0) then
		return false
	end

	local cellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		return false
	end

	writeData(stateKey, 1)
	self:clearOverseerDownFlags(rootID)

	local boss = self.overseerAnchor
	local pBoss = spawnMobile(
		"dungeon1",
		"foundry_overseer_ig_series",
		0,
		boss.x,
		boss.z,
		boss.y,
		boss.heading or 0,
		cellID
	)

	if (pBoss == nil) then
		writeData(stateKey, 0)
		printLuaError("DroidFoundry:startOverseerEncounter failed to spawn Overseer for instance " .. rootID)
		return false
	end

	self:trackEncounterObject(rootID, pBoss)
	self:trackOverseerObject(rootID, pBoss)
	writeData("droidFoundryOverseerBoss:" .. rootID, SceneObject(pBoss):getObjectID())
	writeData("droidFoundryOverseerTarget:" .. rootID, playerID)
	createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyOverseerDestroyed", pBoss)

	-- Optional-wing completion directly controls the opening support package.
	-- Production online: two B1 reinforcements from area A.
	if (tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) ~= 1) then
		self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 1)
		self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 2)
	end

	-- Sentinel online: one Droideka reinforcement from area B.
	if (tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) ~= 1) then
		self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 1)
	end

	-- Maintenance online: one Repair Droid from the third point in area A.
	-- Actual healing behavior remains a later boss-mechanics pass.
	if (tonumber(readData("droidFoundryMaintenanceDisabled:" .. rootID)) ~= 1) then
		local pRepair = self:spawnOverseerSupport(rootID, "foundry_repair_droid", 1, 3)
		if (pRepair ~= nil) then
			writeData("droidFoundryOverseerRepairDroid:" .. rootID, SceneObject(pRepair):getObjectID())
		end
	end

	self:sendInstanceMessage(rootID, "Foundry Overseer combat protocol engaged.")

	writeData("droidFoundryOverseerPhase75:" .. rootID, 0)
	writeData("droidFoundryOverseerPhase50:" .. rootID, 0)
	writeData("droidFoundryOverseerPhase25:" .. rootID, 0)
	writeData("droidFoundryOverseerLastRepair:" .. rootID, os.time())
	writeData("droidFoundryOverseerNextOverload:" .. rootID, 0)

	local ai = AiAgent(pBoss)
	if (ai ~= nil) then
		ai:setAITemplate()
		ai:addDefender(pPlayer)
	end

	createEvent(2000, "DroidFoundry", "overseerMechanicsLoop", pBoss, tostring(rootID))
	return true
end

function DroidFoundry:healOverseerFromMaintenance(rootID, pBoss)
	if (pBoss == nil) then
		return false
	end

	if (tonumber(readData("droidFoundryMaintenanceDisabled:" .. rootID)) == 1) then
		return false
	end

	local repairID = tonumber(readData("droidFoundryOverseerRepairDroid:" .. rootID)) or 0
	if (repairID == 0) then
		return false
	end

	local pRepair = getSceneObject(repairID)
	if (pRepair == nil or CreatureObject(pRepair):isDead() or CreatureObject(pRepair):isIncapacitated()) then
		return false
	end

	local boss = CreatureObject(pBoss)
	if (boss:isDead() or boss:isIncapacitated()) then
		return false
	end

	-- Repair 4% of each primary HAM pool every successful pulse.
	-- Primary pools are Health (0), Action (3), and Mind (6).
	local repaired = false
	local pools = { 0, 3, 6 }

	for i = 1, #pools, 1 do
		local pool = pools[i]
		local current = tonumber(boss:getHAM(pool)) or 0
		local maximum = tonumber(boss:getMaxHAM(pool)) or 0

		if (maximum > 0 and current > 0 and current < maximum) then
			local amount = math.max(1, math.floor(maximum * 0.04))
			boss:setHAM(pool, math.min(maximum, current + amount))
			repaired = true
		end
	end

	return repaired
end

function DroidFoundry:beginOverseerOverload(pBoss, rootID)
	if (pBoss == nil or rootID == 0) then
		return false
	end

	local targetID = tonumber(readData("droidFoundryOverseerTarget:" .. rootID)) or 0
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return false
	end

	local target = CreatureObject(pTarget)
	if (target:isDead() or target:isIncapacitated()) then
		return false
	end

	local expectedCellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (expectedCellID == 0 or SceneObject(pTarget):getParentID() ~= expectedCellID) then
		return false
	end

	local startX = SceneObject(pTarget):getPositionX()
	local startY = SceneObject(pTarget):getPositionY()

	self:sendInstanceMessage(rootID, "OVERSEER: Electrical overload locked. MOVE!")
	target:sendSystemMessage("Electrical overload locked on your position. Move at least 6 meters!")

	local eventData = string.format("%d|%d|%.3f|%.3f", rootID, targetID, startX, startY)

	-- Give players enough time to finish normal SWG combat animations and move
	-- clear of the locked position before the overload resolves.
	createEvent(6000, "DroidFoundry", "resolveOverseerOverload", pBoss, eventData)

	return true
end

function DroidFoundry:resolveOverseerOverload(pBoss, eventData)
	if (pBoss == nil or eventData == nil or eventData == "") then
		return 0
	end

	local rootString, targetString, xString, yString =
		string.match(eventData, "^(%-?%d+)|(%-?%d+)|([%-%.%d]+)|([%-%.%d]+)$")

	local rootID = tonumber(rootString) or 0
	local targetID = tonumber(targetString) or 0
	local startX = tonumber(xString)
	local startY = tonumber(yString)

	if (rootID == 0 or targetID == 0 or startX == nil or startY == nil) then
		return 0
	end

	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		(tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return 0
	end

	local bossID = SceneObject(pBoss):getObjectID()
	if (bossID == 0 or bossID ~= (tonumber(readData("droidFoundryOverseerBoss:" .. rootID)) or 0)) then
		return 0
	end

	local pTarget = getSceneObject(targetID)
	if (pTarget == nil) then
		return 0
	end

	local target = CreatureObject(pTarget)
	if (target:isDead() or target:isIncapacitated()) then
		return 0
	end

	local expectedCellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (expectedCellID == 0 or SceneObject(pTarget):getParentID() ~= expectedCellID) then
		return 0
	end

	local currentX = SceneObject(pTarget):getPositionX()
	local currentY = SceneObject(pTarget):getPositionY()
	local deltaX = currentX - startX
	local deltaY = currentY - startY
	local distance = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

	if (distance >= 6.0) then
		target:sendSystemMessage("You escape the electrical overload.")
		return 0
	end

	local maxHealth = tonumber(target:getMaxHAM(0)) or 0
	if (maxHealth <= 0) then
		return 0
	end

	local damage = math.floor(maxHealth * 0.15)
	damage = math.max(750, math.min(2500, damage))

	target:inflictDamage(pBoss, 0, damage, 0)
	target:sendSystemMessage("Electrical overload hits you for " .. damage .. " damage!")
	self:sendInstanceMessage(rootID, "Electrical overload detonates at the locked position.")

	return 0
end

function DroidFoundry:overseerMechanicsLoop(pBoss, rootIDString)
	local rootID = tonumber(rootIDString) or 0
	if (pBoss == nil or rootID == 0) then
		return 0
	end

	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		(tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return 0
	end

	local bossID = SceneObject(pBoss):getObjectID()
	if (bossID == 0 or bossID ~= (tonumber(readData("droidFoundryOverseerBoss:" .. rootID)) or 0)) then
		return 0
	end

	local boss = CreatureObject(pBoss)
	if (boss:isDead() or boss:isIncapacitated()) then
		return 0
	end

	local currentHealth = tonumber(boss:getHAM(0)) or 0
	local maxHealth = tonumber(boss:getMaxHAM(0)) or 0

	if (maxHealth <= 0) then
		createEvent(2000, "DroidFoundry", "overseerMechanicsLoop", pBoss, tostring(rootID))
		return 0
	end

	local healthPercent = (currentHealth / maxHealth) * 100
	local now = os.time()

	self:refreshOverseerParticipantReturns(rootID)

	-- Electrical Overload begins once the Overseer reaches 70% health.
	-- Move 6+ meters during the 6-second warning to avoid the blast.
	if (healthPercent <= 70) then
		local nextOverload = tonumber(readData("droidFoundryOverseerNextOverload:" .. rootID)) or 0

		if (nextOverload == 0 or now >= nextOverload) then
			local overloadDelay = 20

			if (healthPercent <= 25) then
				overloadDelay = 9
			elseif (healthPercent <= 50) then
				overloadDelay = 14
			end

			if (self:beginOverseerOverload(pBoss, rootID)) then
				writeData("droidFoundryOverseerNextOverload:" .. rootID, now + overloadDelay)
			end
		end
	end

	if (healthPercent <= 75 and tonumber(readData("droidFoundryOverseerPhase75:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase75:" .. rootID, 1)

		if (tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) ~= 1) then
			self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 2)
			self:sendInstanceMessage(rootID, "Production Network dispatches an emergency B1 reinforcement.")
		else
			self:sendInstanceMessage(rootID, "Overseer requests Production reinforcements, but the Production Network is offline.")
		end
	end

	if (healthPercent <= 50 and tonumber(readData("droidFoundryOverseerPhase50:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase50:" .. rootID, 1)

		if (tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) ~= 1) then
			self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 2)
			self:sendInstanceMessage(rootID, "Sentinel Network deploys an emergency Droideka defender.")
		else
			self:sendInstanceMessage(rootID, "Overseer requests Sentinel support, but the Sentinel Network is offline.")
		end
	end

	if (healthPercent <= 25 and tonumber(readData("droidFoundryOverseerPhase25:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase25:" .. rootID, 1)
		self:spawnOverseerSupport(rootID, "foundry_elite_b2_enforcer", 2, 3)
		self:sendInstanceMessage(rootID, "Overseer failsafe combat unit deployed.")
		self:sendInstanceMessage(rootID, "OVERSEER: FINAL COMBAT PROTOCOL ENGAGED.")
	end

	local lastRepair = tonumber(readData("droidFoundryOverseerLastRepair:" .. rootID)) or 0

	if (now - lastRepair >= 8) then
		writeData("droidFoundryOverseerLastRepair:" .. rootID, now)

		if (self:healOverseerFromMaintenance(rootID, pBoss)) then
			self:sendInstanceMessage(rootID, "Maintenance Repair Droid restores Overseer integrity.")
		end
	end

	createEvent(2000, "DroidFoundry", "overseerMechanicsLoop", pBoss, tostring(rootID))
	return 0
end

function DroidFoundry:notifyOverseerDestroyed(pBoss)
	if (pBoss == nil) then
		return 1
	end

	local bossID = SceneObject(pBoss):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. bossID)) or 0

	if (rootID == 0 or tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1) then
		return 1
	end

	writeData("droidFoundryOverseerState:" .. rootID, 2)
	self:sendInstanceMessage(rootID, "Foundry Overseer neutralized. Archive access has been unlocked.")

	local terminalID = tonumber(readData("droidFoundryArchiveTerminal:" .. rootID)) or 0
	local pTerminal = getSceneObject(terminalID)
	if (pTerminal ~= nil) then
		SceneObject(pTerminal):setCustomObjectName("Foundry Archive Interface - UNLOCKED")
	end

	return 1
end

function DroidFoundry:sendInstanceMessage(rootID, message)
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0 and self:isParticipant(rootID, playerID)) then
			local pPlayer = getSceneObject(playerID)
			if (pPlayer ~= nil and SceneObject(pPlayer):isPlayerCreature()) then
				CreatureObject(pPlayer):sendSystemMessage(message)
			end
		end
	end
end

function DroidFoundry:spawnNexusSecurityUnit(rootID, spawnIndex, pTarget)
	local spawn = self.nexusSecuritySpawns[spawnIndex]
	local cellID = self:getInstanceCellID(rootID, self.nexusCellIndex)

	if (spawn == nil or cellID == 0) then
		return nil
	end

	local mobileTemplate = "foundry_security_droid"
	if (spawn.elite) then
		mobileTemplate = "foundry_elite_b1_command_droid"
	end

	local pMobile = spawnMobile(
		"dungeon1",
		mobileTemplate,
		0,
		spawn.x,
		spawn.z,
		spawn.y,
		spawn.heading or 0,
		cellID
	)

	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnNexusSecurityUnit failed at " .. tostring(spawn.label) .. " for instance " .. rootID)
		return nil
	end

	if (not spawn.elite) then
		-- Security responders immediately engage the player who activated the Nexus.
		-- The Elite is intentionally left without a forced target for this milestone.
		if (pTarget ~= nil and SceneObject(pTarget):isPlayerCreature()) then
			AiAgent(pMobile):setAITemplate()
			AiAgent(pMobile):addDefender(pTarget)
		end
	end

	self:trackEncounterObject(rootID, pMobile)
	writeData("droidFoundryNexusAlive:" .. rootID, (tonumber(readData("droidFoundryNexusAlive:" .. rootID)) or 0) + 1)
	createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyNexusSecurityDestroyed", pMobile)

	return pMobile
end

function DroidFoundry:startNexusEncounter(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0

	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This control nexus is not assigned to your expedition.")
		return false
	end

	local state = tonumber(readData("droidFoundryNexusState:" .. rootID)) or 0

	if (state == self.NEXUS_ACTIVE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry security response is already active.")
		return false
	elseif (state == self.NEXUS_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus is already online.")
		return false
	elseif (state ~= self.NEXUS_READY) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Control Nexus is not responding.")
		return false
	end

	writeData("droidFoundryNexusState:" .. rootID, self.NEXUS_ACTIVE)
	writeData("droidFoundryNexusWaveStage:" .. rootID, 1)
	writeData("droidFoundryNexusAlive:" .. rootID, 0)
	writeData("droidFoundryNexusActivator:" .. rootID, playerID)
	SceneObject(pTerminal):setCustomObjectName("Foundry Control Nexus - SECURITY ALERT")

	self:sendInstanceMessage(rootID, "Unauthorized activation detected. Foundry security units are responding.")

	self:spawnNexusSecurityUnit(rootID, 1, pPlayer)
	self:spawnNexusSecurityUnit(rootID, 2, pPlayer)
	self:spawnNexusSecurityUnit(rootID, 3, pPlayer)

	local pRoot = getSceneObject(rootID)
	local serial = tonumber(readData("droidFoundryEncounterSerial:" .. rootID)) or 0

	if (pRoot ~= nil) then
		createEvent(6000, "DroidFoundry", "spawnNexusSecondWave", pRoot, tostring(serial))
	end

	return true
end

function DroidFoundry:spawnNexusSecondWave(pRoot, expectedSerial)
	if (pRoot == nil) then
		return 0
	end

	local rootID = SceneObject(pRoot):getObjectID()
	local serial = tonumber(readData("droidFoundryEncounterSerial:" .. rootID)) or 0

	if (serial ~= tonumber(expectedSerial) or
		tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or
		tonumber(readData("droidFoundryNexusState:" .. rootID)) ~= self.NEXUS_ACTIVE) then
		return 0
	end

	writeData("droidFoundryNexusWaveStage:" .. rootID, 2)
	self:sendInstanceMessage(rootID, "Additional Foundry security units have entered the Nexus chamber.")

	local activatorID = tonumber(readData("droidFoundryNexusActivator:" .. rootID)) or 0
	local pActivator = activatorID ~= 0 and getSceneObject(activatorID) or nil

	self:spawnNexusSecurityUnit(rootID, 4, pActivator)
	self:spawnNexusSecurityUnit(rootID, 5, pActivator)
	self:checkNexusEncounterComplete(rootID)

	return 0
end

function DroidFoundry:notifyNexusSecurityDestroyed(pMobile, pPlayer)
	if (pMobile == nil) then
		return 1
	end

	local objectID = SceneObject(pMobile):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. objectID)) or 0
	deleteData("droidFoundryEncounterRoot:" .. objectID)

	if (rootID == 0 or tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1) then
		return 1
	end

	if (tonumber(readData("droidFoundryNexusState:" .. rootID)) ~= self.NEXUS_ACTIVE) then
		return 1
	end

	local alive = math.max(0, (tonumber(readData("droidFoundryNexusAlive:" .. rootID)) or 0) - 1)
	writeData("droidFoundryNexusAlive:" .. rootID, alive)

	self:checkNexusEncounterComplete(rootID)
	return 1
end

function DroidFoundry:checkNexusEncounterComplete(rootID)
	if (tonumber(readData("droidFoundryNexusState:" .. rootID)) ~= self.NEXUS_ACTIVE) then
		return false
	end

	local waveStage = tonumber(readData("droidFoundryNexusWaveStage:" .. rootID)) or 0
	local alive = tonumber(readData("droidFoundryNexusAlive:" .. rootID)) or 0

	if (waveStage < 2 or alive > 0) then
		return false
	end

	writeData("droidFoundryNexusState:" .. rootID, self.NEXUS_COMPLETE)

	local terminalID = tonumber(readData("droidFoundryNexusTerminal:" .. rootID)) or 0
	local pTerminal = terminalID ~= 0 and getSceneObject(terminalID) or nil
	if (pTerminal ~= nil) then
		SceneObject(pTerminal):setCustomObjectName("Foundry Control Nexus - ONLINE")
	end

	self:sendInstanceMessage(rootID, "Foundry Nexus security response neutralized. The control network is now online.")
	return true
end

DroidFoundryArchiveTerminalMenuComponent = {}

function DroidFoundryArchiveTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	local response = LuaObjectMenuResponse(pMenuResponse)
	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0
	local state = tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0

	if (state == 0) then
		response:addRadialMenuItem(20, 3, "Engage Foundry Overseer")
	elseif (state == 1) then
		response:addRadialMenuItem(20, 3, "Overseer Protocol Active")
	else
		response:addRadialMenuItem(20, 3, "Access Foundry Archive")
	end
end

function DroidFoundryArchiveTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0
	local state = tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0

	if (state == 0) then
		DroidFoundry:showOverseerStatusSui(pSceneObject, pPlayer, rootID)
	elseif (state == 1) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Overseer encounter is already active.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Foundry Archive rewards are not yet implemented.")
	end

	return 0
end

DroidFoundryMaintenanceTerminalMenuComponent = {}

function DroidFoundryMaintenanceTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Disable Maintenance Network")
end

function DroidFoundryMaintenanceTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0

	DroidFoundry:disableMaintenanceNetwork(pSceneObject, pPlayer, rootID)
	return 0
end

DroidFoundrySentinelTerminalMenuComponent = {}

function DroidFoundrySentinelTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Disable Sentinel Network")
end

function DroidFoundrySentinelTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0

	DroidFoundry:disableSentinelNetwork(pSceneObject, pPlayer, rootID)
	return 0
end

DroidFoundryProductionTerminalMenuComponent = {}

function DroidFoundryProductionTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Disable Production Network")
end

function DroidFoundryProductionTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0

	DroidFoundry:disableProductionNetwork(pSceneObject, pPlayer, rootID)
	return 0
end

DroidFoundryNexusTerminalMenuComponent = {}

function DroidFoundryNexusTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Activate Foundry Control Nexus")
end

function DroidFoundryNexusTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or tonumber(selectedID) ~= 20) then
		return 0
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		return 0
	end

	local terminalID = SceneObject(pSceneObject):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. terminalID)) or 0

	DroidFoundry:startNexusEncounter(pSceneObject, pPlayer, rootID)
	return 0
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
