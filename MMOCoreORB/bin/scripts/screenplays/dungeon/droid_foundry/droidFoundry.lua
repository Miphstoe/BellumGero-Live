DroidFoundry = ScreenPlay:new {
	terminalTemplate = "object/tangible/terminal/terminal_nym_cave.iff",
	terminalX = 4784,
	terminalY = 982,
	terminalHeading = 50,
	exitX = 4788.85,
	exitY = 984.699,
	timeoutSeconds = 60 * 60,
	entryX = 0.840546,
	entryZ = -4.010900,
	entryY = 16.232117,
	participantRange = 50,
	admissionTimeoutSeconds = 5,

	-- DROID_FOUNDRY_SCALING_V1
	-- Difficulty is locked from nearby human expedition members at launch.
	-- Late joins remain allowed but do not rescale an already-created instance.
	SCALE_SOLO = 1,
	SCALE_SMALL = 2,
	SCALE_GROUP = 3,
	nexusSecondWaveDelayMs = 10 * 1000,
	overseerOverloadWarningMs = 6 * 1000,
	overseerOverloadEffect = "clienteffect/trap_electric_01.cef",

	-- Applied to every Overseer HAM pool immediately after spawn.
	overseerHamMultipliers = {
		[1] = 1.0,
		[2] = 2.5,
		[3] = 5.0,
	},

	-- Personal Archive reward tuning. Every eligible participant receives one
	-- guaranteed component. The independent schematic jackpot is 0.75% total.
	archiveComponentLootGroup = "droid_foundry_components",
	archiveSchematicLootGroup = "droid_foundry_schematics",
	archiveSchematicChancePerMillion = 7500,

	-- DROID_FOUNDRY_ARCHIVE_COOLDOWN_V1
	-- The premium Archive roll is intentionally invisible to players. Every
	-- eligible claim still produces a component; only its internal loot level
	-- and access to the Archive schematic jackpot change during this cooldown.
	archivePremiumCooldownSeconds = 4 * 60 * 60,
	archivePremiumLootLevel = 350,
	archiveFallbackLootLevel = 175,
	archivePremiumScreenPlay = "DroidFoundry",
	archivePremiumTimestampKey = "archivePremiumClaimedAt",

	-- DROID_FOUNDRY_OVERSEER_PERSONAL_LOOT_V1
	-- World-boss-style participation reward: one personal level-250 roll for
	-- each active expedition participant who actually damages the Overseer.
	overseerPersonalLootGroup = "droid_foundry_kill_loot_generic",
	overseerPersonalLootLevel = 250,

	-- DROID_FOUNDRY_PROTOTYPE_EXIT_RETURN_V1
	prototypeSpawnChancePerMillion = 400000,

	-- DROID_FOUNDRY_PROTOTYPE_VISUAL_V1
	-- Reuse the already-proven Overseer electrical effect as a subtle,
	-- recurring visual tell for the rare Prototype encounter.
	prototypeVisualEffect = "clienteffect/trap_electric_01.cef",
	prototypeVisualPulseMs = 4 * 1000,
	prototypeTemplates = {
		"foundry_prototype_b1_command_droid",
		"foundry_prototype_b2_enforcer",
		"foundry_prototype_droideka_guardian",
	},

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

		-- Scaling-only positions. These remain normal Security Droids so group
		-- scaling does not multiply elite corpse-loot opportunities.
		{ label = "Scaling Spawn A", x = -9.8647, z = -48.7901, y = -148.075, heading = 180, elite = false },
		{ label = "Scaling Spawn B", x = 22.4354, z = -52.7565, y = -187.509, heading = -90, elite = false },
		{ label = "Scaling Spawn C", x = -14.2385, z = -49.4365, y = -216.899, heading = 0, elite = false },
		{ label = "Scaling Spawn D", x = -53.7501, z = -57.3740, y = -221.262, heading = 45, elite = false },
	},

	-- Index 1 is added for 2-3 players; indexes 1 and 2 are added for 4+.
	-- No extra elites are introduced by normal-room scaling.
	scaledPackExtras = {
		["Production Cell 6"] = { "foundry_battle_droid", "foundry_battle_droid" },
		["Production Cell 7"] = { "foundry_battle_droid", "foundry_security_droid" },
		["Production Cell 8"] = { "foundry_super_battle_droid", "foundry_security_droid" },
		["Production Network"] = { "foundry_super_battle_droid", "foundry_super_battle_droid" },
		["Sentinel Cell 9"] = { "foundry_security_droid", "foundry_battle_droid" },
		["Sentinel Cell 10"] = { "foundry_droideka_sentinel", "foundry_security_droid" },
		["Sentinel Cell 11"] = { "foundry_droideka_sentinel", "foundry_security_droid" },
		["Sentinel Core"] = { "foundry_droideka_sentinel", "foundry_droideka_sentinel" },
		["Maintenance Cell 12"] = { "foundry_security_droid", "foundry_repair_droid" },
		["Maintenance Cell 13"] = { "foundry_security_droid", "foundry_repair_droid" },
		["Maintenance Cell 14"] = { "foundry_super_battle_droid", "foundry_repair_droid" },
		["Maintenance Network"] = { "foundry_super_battle_droid", "foundry_security_droid" },
		["Final Approach r21"] = { "foundry_super_battle_droid", "foundry_security_droid" },
		["Final Approach r22"] = { "foundry_super_battle_droid", "foundry_droideka_sentinel" },
	},

	-- The opening Breach keeps its nine authored Solo positions exactly as-is.
	-- Points 4/5 are calculated from each room's existing front spawn only for
	-- scaled runs.
	breachScalingAnchors = {
		{
			cellIndex = 2,
			label = "Breach Cell 2",
			x = 1.1, z = -10.9, y = -16.2, heading = -49,
			spacing = 1.6, depth = 1.4, scaleDepth = 5.0,
			scaleTemplates = { "foundry_battle_droid", "foundry_battle_droid" },
		},
		{
			cellIndex = 3,
			label = "Breach Cell 3",
			x = -26.8, z = -37.6, y = -60.9, heading = 3,
			spacing = 1.6, depth = 1.4, scaleDepth = 5.5,
			scaleTemplates = { "foundry_battle_droid", "foundry_security_droid" },
		},
		{
			cellIndex = 4,
			label = "Breach Cell 4",
			x = -23.3, z = -53.3, y = -116.5, heading = -56,
			spacing = 1.6, depth = 1.4, scaleDepth = 5.0,
			scaleTemplates = { "foundry_security_droid", "foundry_battle_droid" },
		},
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

function DroidFoundry:getScaleTierForPartySize(partySize)
	partySize = math.max(1, tonumber(partySize) or 1)
	if (partySize >= 4) then
		return self.SCALE_GROUP
	elseif (partySize >= 2) then
		return self.SCALE_SMALL
	end
	return self.SCALE_SOLO
end

function DroidFoundry:getScaleTier(rootID)
	local tier = tonumber(readData("droidFoundryScaleTier:" .. rootID)) or self.SCALE_SOLO
	if (tier < self.SCALE_SOLO or tier > self.SCALE_GROUP) then
		return self.SCALE_SOLO
	end
	return tier
end

function DroidFoundry:getScaleTierName(tier)
	tier = tonumber(tier) or self.SCALE_SOLO
	if (tier == self.SCALE_GROUP) then
		return "Group (4+)"
	elseif (tier == self.SCALE_SMALL) then
		return "Duo/Small Group (2-3)"
	end
	return "Solo"
end

function DroidFoundry:getScaleExtraCount(rootID)
	local tier = self:getScaleTier(rootID)
	if (tier == self.SCALE_GROUP) then
		return 2
	elseif (tier == self.SCALE_SMALL) then
		return 1
	end
	return 0
end

function DroidFoundry:getLaunchScalePartySize(pLeader, eligiblePlayers)
	if (pLeader == nil) then
		return 1
	end
	local count = 1
	for i = 1, #eligiblePlayers, 1 do
		local pMember = eligiblePlayers[i]
		if (pMember ~= nil and pMember ~= pLeader and
			SceneObject(pMember):isPlayerCreature() and
			not SceneObject(pMember):isAiAgent() and
			CreatureObject(pLeader):isInRangeWithObject(pMember, self.participantRange)) then
			count = count + 1
		end
	end
	return count
end

function DroidFoundry:getScaledPackExtras(anchorLabel, rootID)
	local extraCount = self:getScaleExtraCount(rootID)
	local configured = self.scaledPackExtras[anchorLabel]
	local extras = {}
	if (extraCount == 0 or configured == nil) then
		return extras
	end
	for i = 1, math.min(extraCount, #configured), 1 do
		table.insert(extras, configured[i])
	end
	return extras
end

function DroidFoundry:getRandomActiveParticipant(rootID, cellID, pFallback)
	rootID = tonumber(rootID) or 0
	cellID = tonumber(cellID) or 0
	local candidates = {}
	local seen = {}
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0 and not seen[playerID] and self:isParticipant(rootID, playerID)) then
			seen[playerID] = true
			local pMember = getSceneObject(playerID)
			if (pMember ~= nil and SceneObject(pMember):isPlayerCreature() and
				not CreatureObject(pMember):isDead() and
				not CreatureObject(pMember):isIncapacitated() and
				(cellID == 0 or SceneObject(pMember):getParentID() == cellID)) then
				table.insert(candidates, pMember)
			end
		end
	end
	if (#candidates > 0) then
		return candidates[math.random(1, #candidates)]
	end
	if (pFallback ~= nil and SceneObject(pFallback):isPlayerCreature() and
		not CreatureObject(pFallback):isDead() and
		not CreatureObject(pFallback):isIncapacitated() and
		(cellID == 0 or SceneObject(pFallback):getParentID() == cellID)) then
		return pFallback
	end
	return nil
end

function DroidFoundry:scaleOverseerHAM(rootID, pBoss)
	if (pBoss == nil) then return end
	local tier = self:getScaleTier(rootID)
	local multiplier = tonumber(self.overseerHamMultipliers[tier]) or 1.0
	if (multiplier <= 1.0) then return end
	local boss = CreatureObject(pBoss)
	for pool = 0, 8, 1 do
		local base = tonumber(boss:getBaseHAM(pool)) or 0
		local maximum = tonumber(boss:getMaxHAM(pool)) or 0
		if (base > 0) then
			boss:setBaseHAM(pool, math.max(1, math.floor(base * multiplier)))
		end
		if (maximum > 0) then
			local scaledMax = math.max(1, math.floor(maximum * multiplier))
			boss:setMaxHAM(pool, scaledMax)
			boss:setHAM(pool, scaledMax)
		end
	end
end

function DroidFoundry:playOverseerOverloadEffect(rootID, x, z, y, cellID)
	rootID = tonumber(rootID) or 0
	cellID = tonumber(cellID) or 0
	if (rootID == 0 or cellID == 0) then return end
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	local seen = {}
	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0 and not seen[playerID] and self:isParticipant(rootID, playerID)) then
			seen[playerID] = true
			local pMember = getSceneObject(playerID)
			if (pMember ~= nil and SceneObject(pMember):isPlayerCreature() and SceneObject(pMember):getParentID() == cellID) then
				playClientEffectLoc(pMember, self.overseerOverloadEffect, "dungeon1", x, z, y, cellID)
			end
		end
	end
end

function DroidFoundry:beginExpedition(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then return end
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
	if (self:tryLateJoin(pPlayer)) then return end
	if (CreatureObject(pPlayer):isGrouped()) then
		local pLeader = CreatureObject(pPlayer):getGroupMember(0)
		if (pLeader == nil or SceneObject(pLeader):getObjectID() ~= playerID) then
			CreatureObject(pPlayer):sendSystemMessage("Only the group leader can begin a Droid Foundry expedition.")
			return
		end
	end
	local eligiblePlayers = self:getEligiblePlayers(pPlayer)
	local scalePartySize = self:getLaunchScalePartySize(pPlayer, eligiblePlayers)
	local scaleTier = self:getScaleTierForPartySize(scalePartySize)
	for i = 1, #self.instances, 1 do
		local instance = self.instances[i]
		local pBuilding = getSceneObject(instance.rootID)
		if (pBuilding ~= nil and SceneObject(pBuilding):isBuildingObject() and tonumber(readData("droidFoundryActive:" .. instance.rootID)) ~= 1) then
			local started = os.time()
			writeData("droidFoundryActive:" .. instance.rootID, 1)
			writeData("droidFoundryOwner:" .. instance.rootID, playerID)
			writeData("droidFoundryStarted:" .. instance.rootID, started)
			writeData("droidFoundryGroup:" .. instance.rootID, CreatureObject(pPlayer):isGrouped() and CreatureObject(pPlayer):getGroupID() or 0)
			writeData("droidFoundryScaleTier:" .. instance.rootID, scaleTier)
			writeData("droidFoundryScalePartySize:" .. instance.rootID, scalePartySize)
			CreatureObject(pPlayer):sendSystemMessage("Droid Foundry difficulty locked: " .. self:getScaleTierName(scaleTier) .. " (" .. scalePartySize .. " nearby expedition player" .. (scalePartySize == 1 and "" or "s") .. ").")
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

			-- Optional repeat-run variety. Failure to spawn a Prototype never
			-- blocks the expedition itself.
			self:preparePrototypeEncounter(instance.rootID)
			for j = 1, #eligiblePlayers, 1 do self:addEligiblePlayer(instance.rootID, eligiblePlayers[j]) end
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
	deleteData("droidFoundryScaleTier:" .. rootID)
	deleteData("droidFoundryScalePartySize:" .. rootID)
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
	deleteData("droidFoundryPrototypeObject:" .. rootID)
	deleteData("droidFoundryPrototypeArea:" .. rootID)
	deleteData("droidFoundryPrototypeType:" .. rootID)

	local overseerTrackedCount = tonumber(readData("droidFoundryOverseerTrackedCount:" .. rootID)) or 0
	for i = 1, overseerTrackedCount, 1 do
		deleteData("droidFoundryOverseerTracked:" .. rootID .. ":" .. i)
	end
	deleteData("droidFoundryOverseerTrackedCount:" .. rootID)
	self:clearOverseerPersonalLootState(rootID)
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
	if (rootID == 0) then return false end
	for i = 1, #self.breachSpawns, 1 do
		if (self:spawnBreachUnit(rootID, self.breachSpawns[i]) == nil) then
			printLuaError("DroidFoundry:prepareBreachEncounter failed for instance " .. rootID)
			return false
		end
	end
	local extraCount = self:getScaleExtraCount(rootID)
	if (extraCount > 0) then
		for i = 1, #self.breachScalingAnchors, 1 do
			local anchor = self.breachScalingAnchors[i]
			local points = self:getTriangleFormation(anchor)
			for j = 1, extraCount, 1 do
				local point = points[3 + j]
				local templateName = anchor.scaleTemplates[j]
				if (point == nil or templateName == nil or self:spawnBreachUnit(rootID, {
					cellIndex = anchor.cellIndex,
					template = templateName,
					label = anchor.label .. " Scaling " .. j,
					x = point.x, z = point.z, y = point.y, heading = point.heading,
				}) == nil) then
					printLuaError("DroidFoundry:prepareBreachEncounter failed scaled spawn for " .. tostring(anchor.label) .. " instance " .. rootID)
					return false
				end
			end
		end
	end
	return true
end

function DroidFoundry:getTriangleFormation(anchor)
	local heading = math.rad(anchor.heading or 0)
	local spacing = tonumber(anchor.spacing) or 1.6
	local depth = tonumber(anchor.depth) or 1.4
	local forwardX = math.sin(heading)
	local forwardY = math.cos(heading)
	local rightX = math.cos(heading)
	local rightY = -math.sin(heading)
	local backX = anchor.x - (forwardX * depth)
	local backY = anchor.y - (forwardY * depth)
	local scaleDepth = tonumber(anchor.scaleDepth) or (depth * 2.75)
	local scaleSpacing = tonumber(anchor.scaleSpacing) or (spacing * 0.75)
	local scaleBackX = anchor.x - (forwardX * scaleDepth)
	local scaleBackY = anchor.y - (forwardY * scaleDepth)
	return {
		{ x = anchor.x, z = anchor.z, y = anchor.y, heading = anchor.heading or 0 },
		{ x = backX + (rightX * spacing), z = anchor.z, y = backY + (rightY * spacing), heading = anchor.heading or 0 },
		{ x = backX - (rightX * spacing), z = anchor.z, y = backY - (rightY * spacing), heading = anchor.heading or 0 },
		{ x = scaleBackX + (rightX * scaleSpacing), z = anchor.z, y = scaleBackY + (rightY * scaleSpacing), heading = anchor.heading or 0 },
		{ x = scaleBackX - (rightX * scaleSpacing), z = anchor.z, y = scaleBackY - (rightY * scaleSpacing), heading = anchor.heading or 0 },
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
	if (rootID == 0) then return false end
	writeData("droidFoundryProductionAlive:" .. rootID, 0)
	for i = 1, #self.productionApproachAnchors, 1 do
		local anchor = self.productionApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnProductionUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareProductionEncounter failed for instance " .. rootID)
				return false
			end
		end
		local extras = self:getScaledPackExtras(anchor.label, rootID)
		for j = 1, #extras, 1 do
			if (self:spawnProductionUnit(rootID, anchor, extras[j], 3 + j) == nil) then
				printLuaError("DroidFoundry:prepareProductionEncounter failed scaled spawn for " .. tostring(anchor.label) .. " instance " .. rootID)
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
	local pTerminal = spawnSceneObject("dungeon1", self.nexusTerminalTemplate, point.x, point.z, point.y, cellID, math.rad(point.heading or 0))
	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareProductionEncounter failed to spawn terminal for instance " .. rootID)
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
	if (rootID == 0) then return false end
	writeData("droidFoundrySentinelAlive:" .. rootID, 0)
	for i = 1, #self.sentinelApproachAnchors, 1 do
		local anchor = self.sentinelApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnSentinelUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareSentinelEncounter failed for instance " .. rootID)
				return false
			end
		end
		local extras = self:getScaledPackExtras(anchor.label, rootID)
		for j = 1, #extras, 1 do
			if (self:spawnSentinelUnit(rootID, anchor, extras[j], 3 + j) == nil) then
				printLuaError("DroidFoundry:prepareSentinelEncounter failed scaled spawn for " .. tostring(anchor.label) .. " instance " .. rootID)
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
	local pTerminal = spawnSceneObject("dungeon1", self.nexusTerminalTemplate, point.x, point.z, point.y, cellID, math.rad(point.heading or 0))
	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareSentinelEncounter failed to spawn terminal for instance " .. rootID)
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
	if (rootID == 0) then return false end
	writeData("droidFoundryMaintenanceAlive:" .. rootID, 0)
	for i = 1, #self.maintenanceApproachAnchors, 1 do
		local anchor = self.maintenanceApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnMaintenanceUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareMaintenanceEncounter failed for instance " .. rootID)
				return false
			end
		end
		local extras = self:getScaledPackExtras(anchor.label, rootID)
		for j = 1, #extras, 1 do
			if (self:spawnMaintenanceUnit(rootID, anchor, extras[j], 3 + j) == nil) then
				printLuaError("DroidFoundry:prepareMaintenanceEncounter failed scaled spawn for " .. tostring(anchor.label) .. " instance " .. rootID)
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
	local pTerminal = spawnSceneObject("dungeon1", self.nexusTerminalTemplate, point.x, point.z, point.y, cellID, math.rad(point.heading or 0))
	if (pTerminal == nil) then
		printLuaError("DroidFoundry:prepareMaintenanceEncounter failed to spawn terminal for instance " .. rootID)
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

function DroidFoundry:resolveOverseerDamagePlayer(pAttacker)
	if (pAttacker == nil) then
		return nil
	end

	local isPlayer = false
	pcall(function()
		isPlayer = SceneObject(pAttacker):isPlayerCreature()
	end)

	if (isPlayer) then
		return pAttacker
	end

	-- Mirror the existing WorldBossLootManager ownership handling so combat
	-- pets/droids credit their owner rather than the AI object.
	local pOwner = nil
	pcall(function()
		pOwner = CreatureObject(pAttacker):getLinkedCreature()
	end)

	if (pOwner ~= nil) then
		local ownerIsPlayer = false
		pcall(function()
			ownerIsPlayer = SceneObject(pOwner):isPlayerCreature()
		end)
		if (ownerIsPlayer) then
			return pOwner
		end
	end

	pOwner = nil
	pcall(function()
		pOwner = CreatureObject(pAttacker):getOwner()
	end)

	if (pOwner ~= nil) then
		local ownerIsPlayer = false
		pcall(function()
			ownerIsPlayer = SceneObject(pOwner):isPlayerCreature()
		end)
		if (ownerIsPlayer) then
			return pOwner
		end
	end

	return nil
end

function DroidFoundry:clearOverseerPersonalLootState(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return
	end

	local count = tonumber(readData("droidFoundryOverseerDamagerCount:" .. rootID)) or 0
	for i = 1, count, 1 do
		local listKey = "droidFoundryOverseerDamager:" .. rootID .. ":" .. i
		local playerID = tonumber(readData(listKey)) or 0

		if (playerID ~= 0) then
			deleteData("droidFoundryOverseerDamaged:" .. rootID .. ":" .. playerID)
			deleteData("droidFoundryOverseerRewardPending:" .. rootID .. ":" .. playerID)
			deleteData("droidFoundryOverseerRewardGranted:" .. rootID .. ":" .. playerID)
		end

		deleteData(listKey)
	end

	deleteData("droidFoundryOverseerDamagerCount:" .. rootID)
end

function DroidFoundry:notifyOverseerDamaged(pBoss, pAttacker, damage)
	if (pBoss == nil or pAttacker == nil) then
		return 0
	end

	local bossID = SceneObject(pBoss):getObjectID()
	local rootID = tonumber(readData("droidFoundryEncounterRoot:" .. bossID)) or 0

	if (rootID == 0 or
		tonumber(readData("droidFoundryEncounterCleaning:" .. rootID)) == 1 or
		(tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then
		return 0
	end

	local pPlayer = self:resolveOverseerDamagePlayer(pAttacker)
	if (pPlayer == nil) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (playerID == 0 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		return 0
	end

	local damagedKey = "droidFoundryOverseerDamaged:" .. rootID .. ":" .. playerID
	if (tonumber(readData(damagedKey)) == 1) then
		return 0
	end

	writeData(damagedKey, 1)

	local count = (tonumber(readData("droidFoundryOverseerDamagerCount:" .. rootID)) or 0) + 1
	writeData("droidFoundryOverseerDamagerCount:" .. rootID, count)
	writeData("droidFoundryOverseerDamager:" .. rootID .. ":" .. count, playerID)

	return 0
end

function DroidFoundry:isOverseerPersonalLootEligible(rootID, playerID)
	rootID = tonumber(rootID) or 0
	playerID = tonumber(playerID) or 0

	if (rootID == 0 or playerID == 0 or
		tonumber(readData("droidFoundryOverseerDamaged:" .. rootID .. ":" .. playerID)) ~= 1 or
		not self:isParticipant(rootID, playerID)) then
		return false
	end

	local pPlayer = getSceneObject(playerID)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		return false
	end

	local bossCellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (bossCellID ~= 0 and SceneObject(pPlayer):getParentID() == bossCellID) then
		return true
	end

	-- A participant may have just died and been moved to the Foundry entrance
	-- by the encounter recovery system. Preserve eligibility for that real
	-- participant instead of letting the 750 ms recovery teleport cost loot.
	return tonumber(readData("droidFoundryOverseerDown:" .. rootID .. ":" .. playerID)) == 1
end

function DroidFoundry:grantOverseerPersonalLoot(rootID, pPlayer)
	rootID = tonumber(rootID) or 0
	if (rootID == 0 or pPlayer == nil) then
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pendingKey = "droidFoundryOverseerRewardPending:" .. rootID .. ":" .. playerID
	local grantedKey = "droidFoundryOverseerRewardGranted:" .. rootID .. ":" .. playerID

	if (tonumber(readData(grantedKey)) == 1) then
		deleteData(pendingKey)
		return true
	end

	if (tonumber(readData(pendingKey)) ~= 1) then
		return true
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		return false
	end

	local rewardOID = createLoot(
		pInventory,
		self.overseerPersonalLootGroup,
		self.overseerPersonalLootLevel,
		true
	)

	if (rewardOID == nil or tonumber(rewardOID) == 0) then
		return false
	end

	writeData(grantedKey, 1)
	deleteData(pendingKey)

	local rewardName = "an Overseer reward"
	local pReward = getSceneObject(tonumber(rewardOID))
	if (pReward ~= nil) then
		rewardName = SceneObject(pReward):getDisplayedName() or rewardName
	end

	CreatureObject(pPlayer):sendSystemMessage(
		"\\#00FF00Foundry Overseer personal reward: " .. rewardName .. ".\\#FFFFFF"
	)

	return true
end

function DroidFoundry:distributeOverseerPersonalLoot(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return
	end

	local count = tonumber(readData("droidFoundryOverseerDamagerCount:" .. rootID)) or 0
	for i = 1, count, 1 do
		local playerID = tonumber(readData("droidFoundryOverseerDamager:" .. rootID .. ":" .. i)) or 0

		if (playerID ~= 0 and self:isOverseerPersonalLootEligible(rootID, playerID)) then
			local pPlayer = getSceneObject(playerID)
			if (pPlayer ~= nil) then
				local pendingKey = "droidFoundryOverseerRewardPending:" .. rootID .. ":" .. playerID
				local grantedKey = "droidFoundryOverseerRewardGranted:" .. rootID .. ":" .. playerID

				if (tonumber(readData(grantedKey)) ~= 1) then
					writeData(pendingKey, 1)

					if (not self:grantOverseerPersonalLoot(rootID, pPlayer)) then
						CreatureObject(pPlayer):sendSystemMessage(
							"Your personal Overseer reward is waiting at the Foundry Archive."
						)
					end
				end
			end
		end
	end
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

	self:clearOverseerPersonalLootState(rootID)
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
	if (cellID == 0 or getSceneObject(cellID) == nil) then return nil end
	local anchor = self.overseerReinforcementAnchors[anchorIndex]
	if (anchor == nil) then return nil end
	local points = self:getTriangleFormation(anchor)
	local point = points[pointIndex]
	if (point == nil) then return nil end
	local pMobile = spawnMobile("dungeon1", templateName, 0, point.x, point.z, point.y, point.heading or 0, cellID)
	if (pMobile ~= nil) then
		self:trackEncounterObject(rootID, pMobile)
		self:trackOverseerObject(rootID, pMobile)
		local targetID = tonumber(readData("droidFoundryOverseerTarget:" .. rootID)) or 0
		local pFallback = targetID ~= 0 and getSceneObject(targetID) or nil
		local pTarget = self:getRandomActiveParticipant(rootID, cellID, pFallback)
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
	if (rootID == 0) then return false end
	for i = 1, #self.finalApproachAnchors, 1 do
		local anchor = self.finalApproachAnchors[i]
		for j = 1, #anchor.templates, 1 do
			if (self:spawnFinalApproachUnit(rootID, anchor, anchor.templates[j], j) == nil) then
				printLuaError("DroidFoundry:prepareFinalEncounter failed while spawning final approach for instance " .. rootID)
				return false
			end
		end
		local extras = self:getScaledPackExtras(anchor.label, rootID)
		for j = 1, #extras, 1 do
			if (self:spawnFinalApproachUnit(rootID, anchor, extras[j], 3 + j) == nil) then
				printLuaError("DroidFoundry:prepareFinalEncounter failed scaled spawn for " .. tostring(anchor.label) .. " instance " .. rootID)
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
	local pTerminal = spawnSceneObject("dungeon1", self.nexusTerminalTemplate, point.x, point.z, point.y, cellID, math.rad(point.heading or 0))
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

function DroidFoundry:getPrototypeSpawnPoint(anchor)
	if (anchor == nil) then
		return nil
	end

	local heading = math.rad(anchor.heading or 0)
	local forwardX = math.sin(heading)
	local forwardY = math.cos(heading)

	-- Place the Prototype behind the normal formation center rather than on
	-- points used by normal/scaled packs. This keeps the random Elite visually
	-- part of the room while minimizing overlap with the 1-5 formation slots.
	local baseDepth = tonumber(anchor.depth) or 1.4
	local prototypeDepth = math.max(3.4, (baseDepth * 2.4) + 0.5)

	return {
		x = anchor.x - (forwardX * prototypeDepth),
		z = anchor.z,
		y = anchor.y - (forwardY * prototypeDepth),
		heading = anchor.heading or 0,
	}
end

function DroidFoundry:pulsePrototypeVisual(pPrototype, rootIDString)
	local rootID = tonumber(rootIDString) or 0
	if (pPrototype == nil or rootID == 0) then
		return 0
	end

	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1) then
		return 0
	end

	local prototypeID = SceneObject(pPrototype):getObjectID()
	if (prototypeID == 0 or
		prototypeID ~= (tonumber(readData("droidFoundryPrototypeObject:" .. rootID)) or 0)) then
		return 0
	end

	local prototype = CreatureObject(pPrototype)
	if (prototype:isDead() or prototype:isIncapacitated()) then
		return 0
	end

	local cellID = SceneObject(pPrototype):getParentID()
	if (cellID == 0) then
		return 0
	end

	local x = SceneObject(pPrototype):getPositionX()
	local z = SceneObject(pPrototype):getPositionZ()
	local y = SceneObject(pPrototype):getPositionY()

	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0

		if (playerID ~= 0 and self:isParticipant(rootID, playerID)) then
			local pMember = getSceneObject(playerID)

			if (pMember ~= nil and
				SceneObject(pMember):isPlayerCreature() and
				SceneObject(pMember):getParentID() == cellID) then

				playClientEffectLoc(
					pMember,
					self.prototypeVisualEffect,
					"dungeon1",
					x,
					z,
					y,
					cellID
				)
			end
		end
	end

	createEvent(
		self.prototypeVisualPulseMs,
		"DroidFoundry",
		"pulsePrototypeVisual",
		pPrototype,
		tostring(rootID)
	)

	return 0
end

function DroidFoundry:preparePrototypeEncounter(rootID)
	rootID = tonumber(rootID) or 0
	if (rootID == 0) then
		return
	end

	deleteData("droidFoundryPrototypeObject:" .. rootID)
	deleteData("droidFoundryPrototypeArea:" .. rootID)
	deleteData("droidFoundryPrototypeType:" .. rootID)

	if (math.random(1, 1000000) > self.prototypeSpawnChancePerMillion) then
		return
	end

	local areas = {
		self.productionApproachAnchors,
		self.sentinelApproachAnchors,
		self.maintenanceApproachAnchors,
		self.finalApproachAnchors,
	}

	local areaIndex = math.random(1, #areas)
	local anchors = areas[areaIndex]
	if (anchors == nil or #anchors == 0) then
		printLuaError(
			"DroidFoundry:preparePrototypeEncounter selected an empty area for instance " ..
			tostring(rootID)
		)
		return
	end

	local anchor = anchors[math.random(1, #anchors)]
	local point = self:getPrototypeSpawnPoint(anchor)
	if (point == nil) then
		return
	end

	local cellID = self:getInstanceCellID(rootID, anchor.cellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then
		printLuaError(
			"DroidFoundry:preparePrototypeEncounter could not resolve selected cell for instance " ..
			tostring(rootID)
		)
		return
	end

	local typeIndex = math.random(1, #self.prototypeTemplates)
	local templateName = self.prototypeTemplates[typeIndex]

	local pPrototype = spawnMobile(
		"dungeon1",
		templateName,
		0,
		point.x,
		point.z,
		point.y,
		point.heading or 0,
		cellID
	)

	if (pPrototype == nil) then
		printLuaError(
			"DroidFoundry:preparePrototypeEncounter failed to spawn " ..
			tostring(templateName) .. " for instance " .. tostring(rootID)
		)
		return
	end

	local objectID = self:trackEncounterObject(rootID, pPrototype)
	writeData("droidFoundryPrototypeObject:" .. rootID, objectID)
	writeData("droidFoundryPrototypeArea:" .. rootID, areaIndex)
	writeData("droidFoundryPrototypeType:" .. rootID, typeIndex)

	-- Pulse immediately, then continue every four seconds while the Prototype
	-- remains alive and attached to this expedition.
	self:pulsePrototypeVisual(pPrototype, tostring(rootID))
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
	if (pPlayer == nil or rootID == 0) then return false end
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
	if ((tonumber(readData(stateKey)) or 0) ~= 0) then return false end
	local cellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (cellID == 0 or getSceneObject(cellID) == nil) then return false end
	writeData(stateKey, 1)
	self:clearOverseerPersonalLootState(rootID)
	self:clearOverseerDownFlags(rootID)
	local boss = self.overseerAnchor
	local pBoss = spawnMobile("dungeon1", "foundry_overseer_ig_series", 0, boss.x, boss.z, boss.y, boss.heading or 0, cellID)
	if (pBoss == nil) then
		writeData(stateKey, 0)
		printLuaError("DroidFoundry:startOverseerEncounter failed to spawn Overseer for instance " .. rootID)
		return false
	end
	self:scaleOverseerHAM(rootID, pBoss)
	self:trackEncounterObject(rootID, pBoss)
	self:trackOverseerObject(rootID, pBoss)
	writeData("droidFoundryOverseerBoss:" .. rootID, SceneObject(pBoss):getObjectID())
	writeData("droidFoundryOverseerTarget:" .. rootID, playerID)
	createObserver(DAMAGERECEIVED, "DroidFoundry", "notifyOverseerDamaged", pBoss)
	createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyOverseerDestroyed", pBoss)
	local tier = self:getScaleTier(rootID)
	if (tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) ~= 1) then
		self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 1)
		self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 2)
		if (tier >= self.SCALE_SMALL) then self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 4) end
		if (tier >= self.SCALE_GROUP) then self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 5) end
	end
	if (tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) ~= 1) then
		self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 1)
		if (tier >= self.SCALE_SMALL) then self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 4) end
		if (tier >= self.SCALE_GROUP) then self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 5) end
	end
	if (tonumber(readData("droidFoundryMaintenanceDisabled:" .. rootID)) ~= 1) then
		local pRepair = self:spawnOverseerSupport(rootID, "foundry_repair_droid", 1, 3)
		if (pRepair ~= nil) then writeData("droidFoundryOverseerRepairDroid:" .. rootID, SceneObject(pRepair):getObjectID()) end
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

-- DROID_FOUNDRY_QUALITY_DUAL_OVERLOAD_V1
function DroidFoundry:getOverseerOverloadTargets(rootID, cellID)
	rootID = tonumber(rootID) or 0
	cellID = tonumber(cellID) or 0

	local candidates = {}
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0

	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0

		if (playerID ~= 0 and self:isParticipant(rootID, playerID)) then
			local pMember = getSceneObject(playerID)

			if (pMember ~= nil and SceneObject(pMember):isPlayerCreature() and
				not CreatureObject(pMember):isDead() and
				not CreatureObject(pMember):isIncapacitated() and
				SceneObject(pMember):getParentID() == cellID) then
				table.insert(candidates, pMember)
			end
		end
	end

	if (#candidates == 0) then
		return {}
	end

	local targets = {}
	local preferredID = tonumber(readData("droidFoundryOverseerTarget:" .. rootID)) or 0
	local preferredIndex = 0

	if (preferredID ~= 0) then
		for i = 1, #candidates, 1 do
			if (SceneObject(candidates[i]):getObjectID() == preferredID) then
				preferredIndex = i
				break
			end
		end
	end

	if (preferredIndex == 0) then
		preferredIndex = math.random(1, #candidates)
	end

	table.insert(targets, candidates[preferredIndex])
	table.remove(candidates, preferredIndex)

	-- Full 4+ scaling gets a second simultaneous Overload on a distinct player
	-- whenever at least two valid participants remain in the chamber.
	if (self:getScaleTier(rootID) == self.SCALE_GROUP and #candidates > 0) then
		local secondIndex = math.random(1, #candidates)
		table.insert(targets, candidates[secondIndex])
	end

	return targets
end

function DroidFoundry:scheduleOverseerOverloadTarget(pBoss, rootID, pTarget, expectedCellID)
	if (pBoss == nil or pTarget == nil or rootID == 0 or expectedCellID == 0) then
		return false
	end

	local target = CreatureObject(pTarget)
	if (target:isDead() or target:isIncapacitated() or
		SceneObject(pTarget):getParentID() ~= expectedCellID) then
		return false
	end

	local targetID = SceneObject(pTarget):getObjectID()
	local startX = SceneObject(pTarget):getPositionX()
	local startZ = SceneObject(pTarget):getPositionZ()
	local startY = SceneObject(pTarget):getPositionY()

	target:sendSystemMessage("Electrical Overload locked on your position. Move at least 6 meters!")
	self:playOverseerOverloadEffect(rootID, startX, startZ, startY, expectedCellID)

	local pulseData = string.format("%d|%.3f|%.3f|%.3f|%d", rootID, startX, startZ, startY, expectedCellID)
	createEvent(2000, "DroidFoundry", "pulseOverseerOverload", pBoss, pulseData)
	createEvent(4000, "DroidFoundry", "pulseOverseerOverload", pBoss, pulseData)

	local eventData = string.format(
		"%d|%d|%.3f|%.3f|%.3f|%d",
		rootID,
		targetID,
		startX,
		startZ,
		startY,
		expectedCellID
	)
	createEvent(self.overseerOverloadWarningMs, "DroidFoundry", "resolveOverseerOverload", pBoss, eventData)

	return true
end

function DroidFoundry:beginOverseerOverload(pBoss, rootID)
	if (pBoss == nil or rootID == 0) then
		return false
	end

	local expectedCellID = self:getInstanceCellID(rootID, self.overseerCellIndex)
	if (expectedCellID == 0) then
		return false
	end

	local targets = self:getOverseerOverloadTargets(rootID, expectedCellID)
	if (#targets == 0) then
		return false
	end

	local overloadCount = #targets
	if (overloadCount >= 2) then
		self:sendInstanceMessage(rootID, "OVERSEER: Dual Electrical Overloads locked. MOVE!")
	else
		self:sendInstanceMessage(rootID, "OVERSEER: Electrical Overload locked. MOVE!")
	end

	local scheduled = 0
	for i = 1, overloadCount, 1 do
		if (self:scheduleOverseerOverloadTarget(pBoss, rootID, targets[i], expectedCellID)) then
			scheduled = scheduled + 1
		end
	end

	if (scheduled == 0) then
		return false
	end

	local announceData = string.format("%d|%d", rootID, scheduled)
	createEvent(
		self.overseerOverloadWarningMs,
		"DroidFoundry",
		"announceOverseerOverloadDetonation",
		pBoss,
		announceData
	)

	return true
end

function DroidFoundry:pulseOverseerOverload(pBoss, eventData)
	if (pBoss == nil or eventData == nil or eventData == "") then return 0 end
	local rootString, xString, zString, yString, cellString = string.match(eventData, "^(%-?%d+)|([%-%.%d]+)|([%-%.%d]+)|([%-%.%d]+)|(%-?%d+)$")
	local rootID = tonumber(rootString) or 0
	local x, z, y, cellID = tonumber(xString), tonumber(zString), tonumber(yString), tonumber(cellString) or 0
	if (rootID == 0 or x == nil or z == nil or y == nil or cellID == 0) then return 0 end
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or (tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then return 0 end
	local bossID = SceneObject(pBoss):getObjectID()
	if (bossID == 0 or bossID ~= (tonumber(readData("droidFoundryOverseerBoss:" .. rootID)) or 0)) then return 0 end
	self:playOverseerOverloadEffect(rootID, x, z, y, cellID)
	return 0
end

function DroidFoundry:announceOverseerOverloadDetonation(pBoss, eventData)
	if (pBoss == nil or eventData == nil or eventData == "") then
		return 0
	end

	local rootString, countString = string.match(eventData, "^(%-?%d+)|(%d+)$")
	local rootID = tonumber(rootString) or 0
	local overloadCount = tonumber(countString) or 0

	if (rootID == 0 or overloadCount == 0) then
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

	if (overloadCount >= 2) then
		self:sendInstanceMessage(rootID, "Electrical Overloads detonate.")
	else
		self:sendInstanceMessage(rootID, "Electrical Overload detonates.")
	end

	return 0
end

function DroidFoundry:resolveOverseerOverload(pBoss, eventData)
	if (pBoss == nil or eventData == nil or eventData == "") then return 0 end
	local rootString, targetString, xString, zString, yString, cellString = string.match(eventData, "^(%-?%d+)|(%-?%d+)|([%-%.%d]+)|([%-%.%d]+)|([%-%.%d]+)|(%-?%d+)$")
	local rootID = tonumber(rootString) or 0
	local targetID = tonumber(targetString) or 0
	local startX, startZ, startY = tonumber(xString), tonumber(zString), tonumber(yString)
	local expectedCellID = tonumber(cellString) or 0
	if (rootID == 0 or targetID == 0 or startX == nil or startZ == nil or startY == nil or expectedCellID == 0) then return 0 end
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or (tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 1) then return 0 end
	local bossID = SceneObject(pBoss):getObjectID()
	if (bossID == 0 or bossID ~= (tonumber(readData("droidFoundryOverseerBoss:" .. rootID)) or 0)) then return 0 end

	-- Always show the final detonation at the original locked position.
	self:playOverseerOverloadEffect(rootID, startX, startZ, startY, expectedCellID)

	local pTarget = getSceneObject(targetID)
	if (pTarget == nil) then return 0 end
	local target = CreatureObject(pTarget)
	if (target:isDead() or target:isIncapacitated() or SceneObject(pTarget):getParentID() ~= expectedCellID) then return 0 end

	local deltaX = SceneObject(pTarget):getPositionX() - startX
	local deltaY = SceneObject(pTarget):getPositionY() - startY
	local distance = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

	if (distance >= 6.0) then
		target:sendSystemMessage("You escape the Electrical Overload.")
		return 0
	end

	local maxHealth = tonumber(target:getMaxHAM(0)) or 0
	if (maxHealth <= 0) then return 0 end

	local damage = math.max(750, math.min(2500, math.floor(maxHealth * 0.15)))
	target:inflictDamage(pBoss, 0, damage, 0)
	target:sendSystemMessage("Electrical Overload hits you for " .. damage .. " damage!")

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

	local tier = self:getScaleTier(rootID)

	if (healthPercent <= 75 and tonumber(readData("droidFoundryOverseerPhase75:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase75:" .. rootID, 1)
		if (tonumber(readData("droidFoundryProductionDisabled:" .. rootID)) ~= 1) then
			self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 2)
			if (tier >= self.SCALE_SMALL) then self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 4) end
			if (tier >= self.SCALE_GROUP) then self:spawnOverseerSupport(rootID, "foundry_battle_droid", 1, 5) end
			self:sendInstanceMessage(rootID, "Production Network dispatches emergency B1 reinforcements.")
		else
			self:sendInstanceMessage(rootID, "Overseer requests Production reinforcements, but the Production Network is offline.")
		end
	end

	if (healthPercent <= 50 and tonumber(readData("droidFoundryOverseerPhase50:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase50:" .. rootID, 1)
		if (tonumber(readData("droidFoundrySentinelDisabled:" .. rootID)) ~= 1) then
			self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 2)
			if (tier >= self.SCALE_SMALL) then self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 4) end
			if (tier >= self.SCALE_GROUP) then self:spawnOverseerSupport(rootID, "foundry_droideka_sentinel", 2, 5) end
			self:sendInstanceMessage(rootID, "Sentinel Network deploys emergency Droideka defenders.")
		else
			self:sendInstanceMessage(rootID, "Overseer requests Sentinel support, but the Sentinel Network is offline.")
		end
	end

	if (healthPercent <= 25 and tonumber(readData("droidFoundryOverseerPhase25:" .. rootID)) ~= 1) then
		writeData("droidFoundryOverseerPhase25:" .. rootID, 1)
		self:spawnOverseerSupport(rootID, "foundry_elite_b2_enforcer", 2, 3)
		if (tier >= self.SCALE_SMALL) then self:spawnOverseerSupport(rootID, "foundry_super_battle_droid", 2, 4) end
		if (tier >= self.SCALE_GROUP) then self:spawnOverseerSupport(rootID, "foundry_super_battle_droid", 2, 5) end
		self:sendInstanceMessage(rootID, "Overseer failsafe combat units deployed.")
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

function DroidFoundry:prepareArchiveRewards(rootID)
	local rosterSize = tonumber(readData("droidFoundryRosterSize:" .. rootID)) or 0
	for i = 1, rosterSize, 1 do
		local playerID = tonumber(readData("droidFoundryRoster:" .. rootID .. ":" .. i)) or 0
		if (playerID ~= 0 and self:isParticipant(rootID, playerID)) then
			writeData("droidFoundryArchiveEligible:" .. rootID .. ":" .. playerID, 1)
			deleteData("droidFoundryArchiveClaimed:" .. rootID .. ":" .. playerID)
		end
	end
end

function DroidFoundry:showArchiveExitSui(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pTerminal == nil or pPlayer == nil or rootID == 0) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	if ((tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 2 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID or
		tonumber(readData("droidFoundryArchiveClaimed:" .. rootID .. ":" .. playerID)) ~= 1) then
		return
	end

	local sui = SuiMessageBox.new("DroidFoundry", "archiveExitSuiCallback")
	sui.setTargetNetworkId(SceneObject(pTerminal):getObjectID())
	sui.setTitle("FOUNDRY ARCHIVE")
	sui.setPrompt("Archive reward secured.\n\nExit the Droid Foundry?")
	sui.setOkButtonText("Exit Droid Foundry")
	sui.setCancelButtonText("Remain")
	sui.setForceCloseDistance(8)
	sui.setProperty("", "Size", "430,210")
	sui.sendTo(pPlayer)
end

function DroidFoundry:archiveExitSuiCallback(pPlayer, pSui, eventIndex)
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
	local playerID = SceneObject(pPlayer):getObjectID()

	if (rootID == 0 or
		(tonumber(readData("droidFoundryOverseerState:" .. rootID)) or 0) ~= 2 or
		not self:isParticipant(rootID, playerID) or
		self:getPlayerInstanceRoot(pPlayer) ~= rootID or
		tonumber(readData("droidFoundryArchiveClaimed:" .. rootID .. ":" .. playerID)) ~= 1) then
		return
	end

	self:returnPlayer(pPlayer)
end

function DroidFoundry:claimArchiveReward(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pTerminal == nil or pPlayer == nil or rootID == 0) then return false end

	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryOverseerState:" .. rootID)) ~= 2 or
		not self:isParticipant(rootID, playerID) or self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
		CreatureObject(pPlayer):sendSystemMessage("This Foundry Archive is not available to your expedition.")
		return false
	end
	if (tonumber(readData("droidFoundryArchiveEligible:" .. rootID .. ":" .. playerID)) ~= 1) then
		CreatureObject(pPlayer):sendSystemMessage("You were not present when this Archive reward was unlocked.")
		return false
	end
	if (tonumber(readData("droidFoundryArchiveClaimed:" .. rootID .. ":" .. playerID)) == 1) then
		self:showArchiveExitSui(pTerminal, pPlayer, rootID)
		return true
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("You need inventory space before accessing the Foundry Archive.")
		return false
	end

	local pendingOverseerReward =
		tonumber(readData("droidFoundryOverseerRewardPending:" .. rootID .. ":" .. playerID)) == 1

	if (pendingOverseerReward and not self:grantOverseerPersonalLoot(rootID, pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage(
			"The Foundry Overseer reward could not be materialized. Try again."
		)
		return false
	end

	-- The personal reward may have consumed the final free inventory slot.
	if (SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("You need inventory space before accessing the Foundry Archive.")
		return false
	end

	local now = os.time()
	local lastPremiumClaim = tonumber(
		readScreenPlayData(pPlayer, self.archivePremiumScreenPlay, self.archivePremiumTimestampKey)
	) or 0

	local premiumArchiveReady =
		lastPremiumClaim <= 0 or
		(now - lastPremiumClaim) >= self.archivePremiumCooldownSeconds

	local archiveLootLevel = premiumArchiveReady and
		self.archivePremiumLootLevel or
		self.archiveFallbackLootLevel

	local componentOID = createLoot(pInventory, self.archiveComponentLootGroup, archiveLootLevel, true)
	if (componentOID == nil or tonumber(componentOID) == 0) then
		CreatureObject(pPlayer):sendSystemMessage("The Foundry Archive failed to materialize your component. Try again.")
		return false
	end

	-- The premium timestamp starts only after the guaranteed component was
	-- successfully created. Fallback claims never extend the premium cooldown.
	if (premiumArchiveReady) then
		writeScreenPlayData(
			pPlayer,
			self.archivePremiumScreenPlay,
			self.archivePremiumTimestampKey,
			now
		)
	end

	writeData("droidFoundryArchiveClaimed:" .. rootID .. ":" .. playerID, 1)

	local componentName = "a Foundry component"
	local pComponent = getSceneObject(tonumber(componentOID))
	if (pComponent ~= nil) then componentName = SceneObject(pComponent):getDisplayedName() or componentName end
	CreatureObject(pPlayer):sendSystemMessage("\\#00FF00Foundry Archive reward: " .. componentName .. ".\\#FFFFFF")

	if (premiumArchiveReady and
		math.random(1, 1000000) <= self.archiveSchematicChancePerMillion and
		not SceneObject(pInventory):isContainerFullRecursive()) then
		local schematicOID = createLoot(pInventory, self.archiveSchematicLootGroup, 175, true)
		if (schematicOID ~= nil and tonumber(schematicOID) ~= 0) then
			local schematicName = "a rare combat droid schematic"
			local pSchematic = getSceneObject(tonumber(schematicOID))
			if (pSchematic ~= nil) then schematicName = SceneObject(pSchematic):getDisplayedName() or schematicName end
			CreatureObject(pPlayer):sendSystemMessage("\\#FFD700JACKPOT! The Foundry Archive also contains " .. schematicName .. "!\\#FFFFFF")
			self:sendInstanceMessage(rootID, SceneObject(pPlayer):getDisplayedName() .. " recovered a rare combat droid schematic from the Foundry Archive!")
		end
	end

	self:showArchiveExitSui(pTerminal, pPlayer, rootID)
	return true
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

	self:distributeOverseerPersonalLoot(rootID)

	writeData("droidFoundryOverseerState:" .. rootID, 2)
	self:prepareArchiveRewards(rootID)
	self:sendInstanceMessage(rootID, "Foundry Overseer destroyed. The Foundry Archive is now accessible.")

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
	if (spawn == nil or cellID == 0) then return nil end
	local mobileTemplate = spawn.elite and "foundry_elite_b1_command_droid" or "foundry_security_droid"
	local pMobile = spawnMobile("dungeon1", mobileTemplate, 0, spawn.x, spawn.z, spawn.y, spawn.heading or 0, cellID)
	if (pMobile == nil) then
		printLuaError("DroidFoundry:spawnNexusSecurityUnit failed at " .. tostring(spawn.label) .. " for instance " .. rootID)
		return nil
	end
	local pEngageTarget = self:getRandomActiveParticipant(rootID, cellID, pTarget)
	if (pEngageTarget ~= nil) then
		local ai = AiAgent(pMobile)
		if (ai ~= nil) then
			ai:setAITemplate()
			ai:addDefender(pEngageTarget)
		end
	end
	self:trackEncounterObject(rootID, pMobile)
	writeData("droidFoundryNexusAlive:" .. rootID, (tonumber(readData("droidFoundryNexusAlive:" .. rootID)) or 0) + 1)
	createObserver(OBJECTDESTRUCTION, "DroidFoundry", "notifyNexusSecurityDestroyed", pMobile)
	return pMobile
end

function DroidFoundry:startNexusEncounter(pTerminal, pPlayer, rootID)
	rootID = tonumber(rootID) or 0
	if (pTerminal == nil or pPlayer == nil or rootID == 0) then return false end
	local playerID = SceneObject(pPlayer):getObjectID()
	if (tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or not self:isParticipant(rootID, playerID) or self:getPlayerInstanceRoot(pPlayer) ~= rootID) then
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
	local tier = self:getScaleTier(rootID)
	self:spawnNexusSecurityUnit(rootID, 1, pPlayer)
	self:spawnNexusSecurityUnit(rootID, 2, pPlayer)
	self:spawnNexusSecurityUnit(rootID, 3, pPlayer)
	if (tier >= self.SCALE_SMALL) then self:spawnNexusSecurityUnit(rootID, 6, pPlayer) end
	if (tier >= self.SCALE_GROUP) then self:spawnNexusSecurityUnit(rootID, 8, pPlayer) end
	local pRoot = getSceneObject(rootID)
	local serial = tonumber(readData("droidFoundryEncounterSerial:" .. rootID)) or 0
	if (pRoot ~= nil) then createEvent(self.nexusSecondWaveDelayMs, "DroidFoundry", "spawnNexusSecondWave", pRoot, tostring(serial)) end
	return true
end

function DroidFoundry:spawnNexusSecondWave(pRoot, expectedSerial)
	if (pRoot == nil) then return 0 end
	local rootID = SceneObject(pRoot):getObjectID()
	local serial = tonumber(readData("droidFoundryEncounterSerial:" .. rootID)) or 0
	if (serial ~= tonumber(expectedSerial) or tonumber(readData("droidFoundryActive:" .. rootID)) ~= 1 or tonumber(readData("droidFoundryNexusState:" .. rootID)) ~= self.NEXUS_ACTIVE) then return 0 end
	writeData("droidFoundryNexusWaveStage:" .. rootID, 2)
	self:sendInstanceMessage(rootID, "Additional Foundry security units have entered the Nexus chamber.")
	local activatorID = tonumber(readData("droidFoundryNexusActivator:" .. rootID)) or 0
	local pActivator = activatorID ~= 0 and getSceneObject(activatorID) or nil
	local tier = self:getScaleTier(rootID)
	self:spawnNexusSecurityUnit(rootID, 4, pActivator)
	self:spawnNexusSecurityUnit(rootID, 5, pActivator)
	if (tier >= self.SCALE_SMALL) then self:spawnNexusSecurityUnit(rootID, 7, pActivator) end
	if (tier >= self.SCALE_GROUP) then self:spawnNexusSecurityUnit(rootID, 9, pActivator) end
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
		DroidFoundry:claimArchiveReward(pSceneObject, pPlayer, rootID)
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
