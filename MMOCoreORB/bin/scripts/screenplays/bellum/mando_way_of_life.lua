-- ============================================================
-- Mandalorian Way of Life
-- Branch: Ender_MandalorianWay
-- Spec: mando_way_of_life_spec.md v1.0
--
-- Lua-first | Minimal C++ | Pre-CU Authentic | BG Rules Compliant
--
-- C++ hooks live in:
--   MissionManagerImplementation.cpp     (Patch 1 — tag BH at accept)
--   MissionObjectiveImplementation.cpp   (Patches 2 & 3 — count on complete)
-- ============================================================

MandoWayOfLife = ScreenPlay:new {
	screenplayName = "MandoWayOfLife",
	numberOfActs   = 1,

	-- --------------------------------------------------------
	-- Recruiter: static spawn at Mos Eisley Cantina (Tatooine)
	-- TODO: verify coordinates in-game
	-- --------------------------------------------------------
	recruiterConfig = {
		planet  = "tatooine",
		x       = 3463,
		z       = 5,
		y       = -4771,
		heading = 180,
		template = "mando_trialmaster",
		name    = "Mando Recruiter",
	},

	-- --------------------------------------------------------
	-- Planet arc: 10 planets in order
	-- fallback coords = NPC city cantina for each planet
	-- TODO: verify all coordinates in-game before final deploy
	-- --------------------------------------------------------
	planetData = {
		[1]  = { planet = "tatooine",  x =  3463, z = 5,  y = -4771, parting = "Tatoo system teaches patience. The suns don't rush." },
		[2]  = { planet = "corellia",  x =  -320, z = 5,  y = -4740, parting = "Corellians talk too much. Learn to listen first." },
		[3]  = { planet = "naboo",     x = -5468, z = 5,  y =  4382, parting = "Beauty hides danger. Do not be deceived by what you see." },
		[4]  = { planet = "dantooine", x =  -602, z = 5,  y =  3060, parting = "Wide open space. Nowhere to hide. Good." },
		[5]  = { planet = "lok",       x = -5537, z = 5,  y =   300, parting = "Lok does not forgive weakness. Neither do we." },
		[6]  = { planet = "rori",      x = -5178, z = 5,  y = -2194, parting = "Two moons. Two sides. Pick neither until you understand both." },
		[7]  = { planet = "talus",     x =   551, z = 5,  y = -2906, parting = "Gray work on a gray world. Stay sharp." },
		[8]  = { planet = "endor",     x = -1335, z = 5,  y = -2116, parting = "The forest watches. So should you." },
		[9]  = { planet = "dathomir",  x = -3800, z = 5,  y =  1100, parting = "Few survive Dathomir. You will not be an exception unless you earn it." },
		[10] = { planet = "yavin4",    x = -6551, z = 5,  y = -4330, parting = "The Force has no claim on us. We claim ourselves." },
	},

	-- --------------------------------------------------------
	-- Chapter reward item templates
	-- TODO: create item Lua files once armor objects are defined
	-- --------------------------------------------------------
	chapterRewards = {
		[0] = "object/tangible/wearables/armor/mandalorian/custom/foundling_helmet.iff",
		[1] = "object/tangible/wearables/armor/mandalorian/custom/initiate_gloves.iff",
		[2] = "object/tangible/wearables/armor/mandalorian/custom/hunter_chest.iff",
		[3] = "object/tangible/wearables/armor/mandalorian/custom/verdika_legs.iff",
		[4] = {   -- Clanbound: remaining set pieces granted together
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_belt.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_bicep_l.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_bicep_r.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_bracer_l.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_bracer_r.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_shoes.iff",
		},
	},

	-- Chapter title strings (set via custom badge/title system)
	chapterTitles = {
		[0] = "Foundling",
		[1] = "Initiate",
		[2] = "Hunter",
		[3] = "Verd'ika",
		[4] = "Clanbound",
	},

	-- Private contract daily cap
	PRIVATE_CONTRACT_DAILY_CAP = 3,

	-- Solo check interval (ms)
	SOLO_CHECK_INTERVAL_MS = 30000,

	-- Contract target completion check interval (ms)
	CONTRACT_CHECK_INTERVAL_MS = 10000,

	-- planetDone poll interval (ms)
	PLANET_DONE_POLL_MS = 60000,
}

registerScreenPlay("MandoWayOfLife", true)

-- ============================================================
-- STARTUP
-- ============================================================

function MandoWayOfLife:start()
	local cfg = self.recruiterConfig
	local pRecruiter = spawnMobile(cfg.planet, cfg.template, 0, cfg.x, cfg.z, cfg.y, cfg.heading, 0)
	if (pRecruiter ~= nil) then
		CreatureObject(pRecruiter):setPvpStatusBitmask(0)
		CreatureObject(pRecruiter):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
		SceneObject(pRecruiter):setCustomObjectName(cfg.name)
		AiAgent(pRecruiter):setConvoTemplate("mandoTrialmasterConvoTemplate")
		AiAgent(pRecruiter):addObjectFlag(AI_STATIC)
		writeData("mando_way:recruiter_id", SceneObject(pRecruiter):getObjectID())
	end
end

-- ============================================================
-- STATE HELPERS
-- ============================================================

function MandoWayOfLife:readInt(pPlayer, key)
	if (pPlayer == nil) then return 0 end
	return tonumber(readScreenPlayData(pPlayer, "MandoWayOfLife", key)) or 0
end

function MandoWayOfLife:writeInt(pPlayer, key, value)
	if (pPlayer == nil) then return end
	writeScreenPlayData(pPlayer, "MandoWayOfLife", key, tostring(value))
end

function MandoWayOfLife:readStr(pPlayer, key)
	if (pPlayer == nil) then return "" end
	return readScreenPlayData(pPlayer, "MandoWayOfLife", key) or ""
end

function MandoWayOfLife:writeStr(pPlayer, key, value)
	if (pPlayer == nil) then return end
	writeScreenPlayData(pPlayer, "MandoWayOfLife", key, tostring(value))
end

function MandoWayOfLife:getChapter(pPlayer)
	return self:readInt(pPlayer, "chapter")
end

function MandoWayOfLife:setChapter(pPlayer, ch)
	self:writeInt(pPlayer, "chapter", ch)
end

function MandoWayOfLife:isArcComplete(pPlayer)
	return self:readInt(pPlayer, "foundling.arcComplete") == 1
end

-- ============================================================
-- PREREQUISITES (Chapter 0 entry gate)
-- Novice Scout + Novice Marksman + Novice Medic
-- ============================================================

function MandoWayOfLife:meetsPrerequisites(pPlayer)
	if (pPlayer == nil) then return false end
	local creature = CreatureObject(pPlayer)
	return creature:hasSkill("outdoors_scout_novice")
		and creature:hasSkill("combat_marksman_novice")
		and creature:hasSkill("science_medic_novice")
end

-- ============================================================
-- CHAPTER 0: FOUNDLING ARC
-- ============================================================

-- Called from Trialmaster conversation when player accepts Chapter 0
function MandoWayOfLife:startFoundlingArc(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "chapter0Started") == 1) then return end

	self:writeInt(pPlayer, "chapter0Started", 1)
	self:writeInt(pPlayer, "foundling.planetIndex", 0)
	self:writeInt(pPlayer, "foundling.arcComplete", 0)

	-- Advance to planet 1 (Tatooine)
	self:advanceToPlanet(pPlayer, 1)
end

-- Advance to next planet in the arc
function MandoWayOfLife:advanceToPlanet(pPlayer, index)
	if (pPlayer == nil) then return end

	local data = self.planetData[index]
	if (data == nil) then
		-- All 10 planets done
		self:completeFoundlingArc(pPlayer)
		return
	end

	self:writeInt(pPlayer, "foundling.planetIndex", index)
	self:writeStr(pPlayer, "foundling.currentPlanet", data.planet)

	-- Disable counting until player accepts assignment on this planet
	self:writeInt(pPlayer, "foundling.planetCountingEnabled", 0)
	self:writeInt(pPlayer, "foundling.planetDone", 0)
	self:writeInt(pPlayer, "foundling.planetCompleted", 0)
	self:writeInt(pPlayer, "foundling.planetTarget", 0)

	-- Despawn previous informant if any
	self:despawnInformant(pPlayer)

	-- Spawn informant at this planet's fallback coordinates
	-- TODO: add player-city detection via getCityRegionAt() when available
	self:spawnInformant(pPlayer, index)

	CreatureObject(pPlayer):sendSystemMessage(
		"Your contact is waiting on " .. data.planet .. ". Find them and accept your assignment."
	)
end

-- Spawn a per-player informant NPC at the planet fallback location
function MandoWayOfLife:spawnInformant(pPlayer, index)
	if (pPlayer == nil) then return end
	local data = self.planetData[index]
	if (data == nil) then return end

	local pInformant = spawnMobile(data.planet, "mando_foundling_informant", 0, data.x, data.z, data.y, 0, 0)
	if (pInformant ~= nil) then
		CreatureObject(pInformant):setPvpStatusBitmask(0)
		CreatureObject(pInformant):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
		SceneObject(pInformant):setCustomObjectName("Mandalorian Informant")
		AiAgent(pInformant):setConvoTemplate("mandoFoundlingInformantConvoTemplate")
		AiAgent(pInformant):addObjectFlag(AI_STATIC)

		-- Store informant ID and coords for waypoint/cleanup
		local informantId = SceneObject(pInformant):getObjectID()
		self:writeStr(pPlayer, "foundling.informantId", tostring(informantId))
		self:writeStr(pPlayer, "foundling.informantCity", "")
		self:writeInt(pPlayer, "foundling.informantCoordX", data.x)
		self:writeInt(pPlayer, "foundling.informantCoordY", data.y)

		-- Link informant to this player so the conversation knows who to update
		writeData("mando_way:informant:" .. informantId .. ":player", SceneObject(pPlayer):getObjectID())

		-- Grant waypoint to informant location
		self:grantInformantWaypoint(pPlayer, data)
	end
end

-- Add a datapad waypoint pointing to the current planet's informant
function MandoWayOfLife:grantInformantWaypoint(pPlayer, data)
	if (pPlayer == nil or data == nil) then return end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end

	-- Clear any previous informant waypoint first
	local oldWpId = self:readInt(pPlayer, "foundling.waypointId")
	if (oldWpId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(oldWpId, true)
	end

	local wpId = PlayerObject(pGhost):addWaypoint(
		data.planet,
		"Mandalorian Informant",
		"Find your contact and accept your assignment.",
		data.x, data.z, data.y,
		WAYPOINT_YELLOW, true, true, 0
	)
	if (wpId ~= nil) then
		self:writeInt(pPlayer, "foundling.waypointId", wpId)
	end
end

-- Despawn the current informant for this player
function MandoWayOfLife:despawnInformant(pPlayer)
	if (pPlayer == nil) then return end
	local informantId = tonumber(self:readStr(pPlayer, "foundling.informantId")) or 0
	if (informantId ~= 0) then
		local pInformant = getSceneObject(informantId)
		if (pInformant ~= nil) then
			deleteData("mando_way:informant:" .. informantId .. ":player")
			SceneObject(pInformant):destroyObjectFromWorld()
		end
		self:writeStr(pPlayer, "foundling.informantId", "0")
	end

	-- Remove the informant waypoint from datapad
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		local wpId = self:readInt(pPlayer, "foundling.waypointId")
		if (wpId ~= 0) then
			PlayerObject(pGhost):removeWaypoint(wpId, true)
			self:writeInt(pPlayer, "foundling.waypointId", 0)
		end
	end
end

-- Called from informant conversation when player accepts the planet assignment
function MandoWayOfLife:acceptPlanetAssignment(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "foundling.planetCountingEnabled") == 1) then return end

	-- Roll random quota 25-100
	local target = math.random(25, 100)
	self:writeInt(pPlayer, "foundling.planetTarget", target)
	self:writeInt(pPlayer, "foundling.planetCompleted", 0)
	self:writeInt(pPlayer, "foundling.planetDone", 0)
	self:writeInt(pPlayer, "foundling.planetCountingEnabled", 1)   -- C++ reads this

	-- Issue return waypoint to informant location
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		local planet = self:readStr(pPlayer, "foundling.currentPlanet")
		local ix = self:readInt(pPlayer, "foundling.informantCoordX")
		local iy = self:readInt(pPlayer, "foundling.informantCoordY")
		local wpId = PlayerObject(pGhost):addWaypoint(planet, "Return to your contact", "", ix, 0, iy, WAYPOINT_YELLOW, true, true, 0)
		self:writeStr(pPlayer, "foundling.returnWaypointId", tostring(wpId))
	end

	CreatureObject(pPlayer):sendSystemMessage(
		"Assignment accepted. Complete destroy or deliver missions on this planet."
	)

	-- Start polling for quota completion (C++ sets planetDone = 1 when done)
	local playerId = SceneObject(pPlayer):getObjectID()
	createEvent(self.PLANET_DONE_POLL_MS, self.screenplayName, "checkPlanetDoneEvent", pPlayer, tostring(playerId))
end

-- Periodic event: check if C++ has set planetDone = 1
function MandoWayOfLife:checkPlanetDoneEvent(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end
	if (player == nil or SceneObject(player) == nil) then return end

	-- Stop polling if counting disabled (arc advanced or abandoned)
	if (self:readInt(player, "foundling.planetCountingEnabled") ~= 1) then return end

	if (self:readInt(player, "foundling.planetDone") == 1) then
		-- Quota met — notify player (return waypoint already in datapad from accept)
		local planetKey = self:readStr(player, "foundling.currentPlanet")
		local planetName = planetKey:sub(1,1):upper() .. planetKey:sub(2)
		CreatureObject(player):sendSystemMessage(
			"You have proven yourself on " .. planetName .. ". Return to your contact."
		)
		-- Stop polling — player now needs to walk back to informant
	else
		-- Quota not yet met — reschedule
		local playerId = SceneObject(player):getObjectID()
		createEvent(self.PLANET_DONE_POLL_MS, self.screenplayName, "checkPlanetDoneEvent", player, tostring(playerId))
	end
end

-- Called from informant conversation when player turns in after completing quota
function MandoWayOfLife:turnInPlanet(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "foundling.planetDone") ~= 1) then return end

	local index = self:readInt(pPlayer, "foundling.planetIndex")

	-- Deliver parting line via system message (conversation handles full dialogue)
	local data = self.planetData[index]
	if (data ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(data.parting)
	end

	-- Remove return waypoint
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	local wpId = tonumber(self:readStr(pPlayer, "foundling.returnWaypointId")) or 0
	if (pGhost ~= nil and wpId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(wpId, true)
	end
	self:writeStr(pPlayer, "foundling.returnWaypointId", "0")

	-- Disable counting
	self:writeInt(pPlayer, "foundling.planetCountingEnabled", 0)

	-- Despawn this informant
	self:despawnInformant(pPlayer)

	-- Advance to next planet
	self:advanceToPlanet(pPlayer, index + 1)
end

-- Called after all 10 planets complete
function MandoWayOfLife:completeFoundlingArc(pPlayer)
	if (pPlayer == nil) then return end
	self:writeInt(pPlayer, "foundling.arcComplete", 1)
	self:writeInt(pPlayer, "foundling.planetCountingEnabled", 0)
	self:setChapter(pPlayer, 0)
	self:writeInt(pPlayer, "chapter0Complete", 1)

	-- Grant Foundling Helmet
	self:grantReward(pPlayer, 0)

	-- TODO: grant title via badge system when title IDs confirmed
	CreatureObject(pPlayer):sendSystemMessage(
		"You have proven yourself across the galaxy. The Foundling Helmet is yours. Wear it only if you can live up to it."
	)
end

-- ============================================================
-- CHAPTERS 1-4: INITIATE → CLANBOUND GATE CYCLE
-- ============================================================

-- Called from Trialmaster / Operative conversation after chapter prereqs met
function MandoWayOfLife:startChapterGate(pPlayer)
	if (pPlayer == nil) then return end
	local ch = self:getChapter(pPlayer)

	-- Gate: must have Novice BH for chapters 1+
	if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
		CreatureObject(pPlayer):sendSystemMessage(
			"Train your craft first. Come back when you have earned Novice Bounty Hunter."
		)
		return
	end

	-- Gate: must have Foundling title (arc complete flag)
	if (not self:isArcComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage(
			"No helm. No chain-code. No work."
		)
		return
	end

	-- Already gating
	if (self:readInt(pPlayer, "countingEnabled") == 1) then return end

	-- Reset BH terminal counter for this gate cycle
	self:writeInt(pPlayer, "bhTerminalCount", 0)
	self:writeInt(pPlayer, "countingEnabled", 1)    -- C++ reads this
	self:writeInt(pPlayer, "needsCustomContract", 0)

	CreatureObject(pPlayer):sendSystemMessage(
		"Spynet contracts: 0/5. Complete five bounty terminal missions."
	)
end

-- Called when C++ increments bhTerminalCount to 5.
-- C++ sends the "Spynet contracts: 5/5" message automatically.
-- Lua polls this via gateProgressEvent.
function MandoWayOfLife:startGateProgressPoll(pPlayer)
	if (pPlayer == nil) then return end
	local playerId = SceneObject(pPlayer):getObjectID()
	createEvent(15000, self.screenplayName, "gateProgressEvent", pPlayer, tostring(playerId))
end

function MandoWayOfLife:gateProgressEvent(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end
	if (player == nil or SceneObject(player) == nil) then return end

	if (self:readInt(player, "countingEnabled") ~= 1) then return end

	local count = self:readInt(player, "bhTerminalCount")
	if (count >= 5 and self:readInt(player, "needsCustomContract") == 0) then
		-- Gate A complete — unlock private contract
		self:writeInt(player, "countingEnabled", 0)
		self:writeInt(player, "needsCustomContract", 1)
		CreatureObject(player):sendSystemMessage(
			"Five contracts confirmed. Seek out the private network operative for your trial."
		)
	else
		-- Still counting — reschedule
		local playerId = SceneObject(player):getObjectID()
		createEvent(15000, self.screenplayName, "gateProgressEvent", player, tostring(playerId))
	end
end

-- ============================================================
-- PRIVATE CONTRACTS: SOLO ENFORCEMENT
-- ============================================================

-- Called from operative conversation when private contract is accepted
-- Returns true if player may proceed, false if they should be blocked
function MandoWayOfLife:beginPrivateContract(pPlayer)
	if (pPlayer == nil) then return false end

	-- Helmet equipped check
	if (not self:hasFoundlingHelmet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("No helm. No chain-code. No work.")
		return false
	end

	-- Solo check at accept
	if (CreatureObject(pPlayer):isGrouped()) then
		CreatureObject(pPlayer):sendSystemMessage("You must face this trial alone.")
		return false
	end

	-- Daily cap check
	self:resetDailyCapIfNeeded(pPlayer)
	local todayCount = self:readInt(pPlayer, "privateContractsToday")
	if (todayCount >= self.PRIVATE_CONTRACT_DAILY_CAP) then
		CreatureObject(pPlayer):sendSystemMessage(
			"You have reached today's contract limit. Return tomorrow."
		)
		return false
	end

	-- Spawn contract target near player's current position
	local spawnX = SceneObject(pPlayer):getWorldPositionX() + 200
	local spawnY = SceneObject(pPlayer):getWorldPositionY()
	local spawnZ = SceneObject(pPlayer):getWorldPositionZ() + 200
	local planet = SceneObject(pPlayer):getZoneName()

	local pTarget = spawnMobile(planet, "mando_contract_target", 0, spawnX, spawnY, spawnZ, 180, 0)
	if (pTarget == nil) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[MandoWayOfLife] ERROR: could not spawn contract target. Contact a GM."
		)
		return false
	end
	self:writeStr(pPlayer, "contractTargetId", tostring(SceneObject(pTarget):getObjectID()))

	-- Mark contract in progress
	self:writeInt(pPlayer, "privateContractActive", 1)
	self:writeInt(pPlayer, "privateContractsToday", todayCount + 1)

	-- Start periodic solo + helmet enforcement
	local playerId = SceneObject(pPlayer):getObjectID()
	createEvent(self.SOLO_CHECK_INTERVAL_MS, self.screenplayName, "soloCheckEvent", pPlayer, tostring(playerId))

	-- Start contract completion check
	createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", pPlayer, tostring(playerId))

	return true
end

function MandoWayOfLife:soloCheckEvent(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end
	if (player == nil or SceneObject(player) == nil) then return end

	-- Stop if contract no longer active
	if (self:readInt(player, "privateContractActive") ~= 1) then return end

	-- Grouped check
	if (CreatureObject(player):isGrouped()) then
		self:failPrivateContract(player, "You broke the trial. A Mandalorian hunts alone.")
		return
	end

	-- Helmet check
	if (not self:hasFoundlingHelmet(player)) then
		self:failPrivateContract(player, "You removed your helm. The trial is void.")
		return
	end

	-- Reschedule
	local playerId = SceneObject(player):getObjectID()
	createEvent(self.SOLO_CHECK_INTERVAL_MS, self.screenplayName, "soloCheckEvent", player, tostring(playerId))
end

function MandoWayOfLife:failPrivateContract(pPlayer, msg)
	if (pPlayer == nil) then return end
	self:writeInt(pPlayer, "privateContractActive", 0)
	CreatureObject(pPlayer):sendSystemMessage(msg)

	-- Despawn contract target if still alive
	local targetId = tonumber(self:readStr(pPlayer, "contractTargetId")) or 0
	if (targetId ~= 0) then
		local pTarget = getSceneObject(targetId)
		if (pTarget ~= nil) then
			SceneObject(pTarget):destroyObjectFromWorld()
		end
		self:writeStr(pPlayer, "contractTargetId", "0")
	end
end

-- Periodic check: has the contract target been defeated?
function MandoWayOfLife:contractCheckEvent(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end
	if (player == nil or SceneObject(player) == nil) then return end

	-- Stop if contract no longer active (failed or player logged off)
	if (self:readInt(player, "privateContractActive") ~= 1) then return end

	local targetId = tonumber(self:readStr(player, "contractTargetId")) or 0
	if (targetId == 0) then return end

	local pTarget = getSceneObject(targetId)
	local isDead = (pTarget == nil or CreatureObject(pTarget):isDead())

	if (isDead) then
		self:completePrivateContract(player)
	else
		-- Target still alive — reschedule
		local playerId = SceneObject(player):getObjectID()
		createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", player, tostring(playerId))
	end
end

-- Called from contract completion trigger when player succeeds
function MandoWayOfLife:completePrivateContract(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then return end

	self:writeInt(pPlayer, "privateContractActive", 0)
	self:writeInt(pPlayer, "needsCustomContract", 0)
	self:writeStr(pPlayer, "contractTargetId", "0")

	-- Advance chapter
	local ch = self:getChapter(pPlayer)
	ch = ch + 1
	self:setChapter(pPlayer, ch)
	self:writeInt(pPlayer, "chapter" .. ch .. "Complete", 1)

	-- Grant armor reward
	self:grantReward(pPlayer, ch)

	-- Grant scaling chapter completion loot (Ch1+)
	if (ch >= 1) then
		self:grantChapterLoot(pPlayer, ch)
	end

	local title = self.chapterTitles[ch] or ""
	CreatureObject(pPlayer):sendSystemMessage(
		"The trial is complete. You have earned the rank of " .. title .. "."
	)

	-- TODO: grant title via badge system when title IDs confirmed
end

-- ============================================================
-- REWARD GRANT
-- ============================================================

function MandoWayOfLife:grantReward(pPlayer, chapter)
	if (pPlayer == nil) then return end
	local reward = self.chapterRewards[chapter]
	if (reward == nil) then return end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then return end

	if (type(reward) == "table") then
		-- Multiple pieces (e.g. Clanbound set)
		for _, template in ipairs(reward) do
			local pItem = giveItem(pInventory, template, -1)
			if (pItem == nil) then
				CreatureObject(pPlayer):sendSystemMessage(
					"[MandoWayOfLife] ERROR: could not grant " .. template .. ". Contact a GM."
				)
			end
		end
	else
		local pItem = giveItem(pInventory, reward, -1)
		if (pItem == nil) then
			CreatureObject(pPlayer):sendSystemMessage(
				"[MandoWayOfLife] ERROR: could not grant reward for chapter " .. chapter .. ". Contact a GM."
			)
		end
	end
end

-- ============================================================
-- CHAPTER COMPLETION LOOT
-- ============================================================
-- Each chapter tier has a dedicated loot group registered in loot/groups/bellum/.
-- createLoot() runs through the full loot system pipeline — craftingValues stat
-- randomization (quality tiers, DoTs, skill mods) is applied automatically.
-- Ch0: nothing (intro only)
-- Ch1: BH armor schematics (mando_chapter_loot_1)
-- Ch2: BH + DW Mando armor schematics (mando_chapter_loot_2)
-- Ch3: Ch2 + jetpack parts + krayt mats (mando_chapter_loot_3)
-- Ch4: Ch3 + jetpack base + RIS schematic + peko feather + JP stabilizer (mando_chapter_loot_4)

-- Loot level controls stat roll quality (min/max range, exceptional/legendary chance).
-- Chapters stay in the 30-80 band; FRS endgame reserves level 90-200 (10 per rank).
MandoWayOfLife.chapterLootGroups = {
	[1] = { group = "mando_chapter_loot_1", level = 30 },
	[2] = { group = "mando_chapter_loot_2", level = 45 },
	[3] = { group = "mando_chapter_loot_3", level = 60 },
	[4] = { group = "mando_chapter_loot_4", level = 80 },
}

function MandoWayOfLife:grantChapterLoot(pPlayer, chapter)
	if (pPlayer == nil) then return end
	local entry = self.chapterLootGroups[chapter]
	if (entry == nil) then return end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then return end

	local itemID = createLoot(pInventory, entry.group, entry.level, false)
	if (itemID ~= nil and itemID ~= 0) then
		CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Way of Life] Chapter " .. chapter .. " bonus reward granted.")
	else
		CreatureObject(pPlayer):sendSystemMessage("[MandoWayOfLife] ERROR: could not grant chapter loot for chapter " .. chapter .. ". Contact a GM.")
	end
end

--[[ REPLACED: old manual pool/IFF implementation (chapterLootPools, chapterLootIffMap,
     resolveChapterLootIff, grantChapterLoot manual weighted-random) — deleted in favour
     of createLoot() which applies full stat randomization via LootManager.
MandoWayOfLife.chapterLootPools = {
	[1] = {
		{ "bounty_hunter_belt_schematic",        1 },
		{ "bounty_hunter_bicep_l_schematic",     1 },
		{ "bounty_hunter_bicep_r_schematic",     1 },
		{ "bounty_hunter_boots_schematic",       1 },
		{ "bounty_hunter_bracer_l_schematic",    1 },
		{ "bounty_hunter_bracer_r_schematic",    1 },
		{ "bounty_hunter_chest_plate_schematic", 1 },
		{ "bounty_hunter_gloves_schematic",      1 },
		{ "bounty_hunter_helmet_schematic",      1 },
		{ "bounty_hunter_leggings_schematic",    1 },
	},
	[2] = {
		{ "bounty_hunter_belt_schematic",        2 },
		{ "bounty_hunter_bicep_l_schematic",     2 },
		{ "bounty_hunter_bicep_r_schematic",     2 },
		{ "bounty_hunter_boots_schematic",       2 },
		{ "bounty_hunter_bracer_l_schematic",    2 },
		{ "bounty_hunter_bracer_r_schematic",    2 },
		{ "bounty_hunter_chest_plate_schematic", 2 },
		{ "bounty_hunter_gloves_schematic",      2 },
		{ "bounty_hunter_helmet_schematic",      2 },
		{ "bounty_hunter_leggings_schematic",    2 },
		{ "dw_mando_helmet_schematic",           1 },
		{ "dw_mando_chest_plate_schematic",      1 },
		{ "dw_mando_belt_schematic",             1 },
		{ "dw_mando_boots_schematic",            1 },
		{ "dw_mando_bracer_l_schematic",         1 },
		{ "dw_mando_bracer_r_schematic",         1 },
		{ "dw_mando_bicep_l_schematic",          1 },
		{ "dw_mando_bicep_r_schematic",          1 },
		{ "dw_mando_gloves_schematic",           1 },
		{ "dw_mando_leggings_schematic",         1 },
		{ "dw_mando_jetpack_schematic",          1 },
	},
	[3] = {
		{ "bounty_hunter_belt_schematic",        2 },
		{ "bounty_hunter_bicep_l_schematic",     2 },
		{ "bounty_hunter_bicep_r_schematic",     2 },
		{ "bounty_hunter_boots_schematic",       2 },
		{ "bounty_hunter_bracer_l_schematic",    2 },
		{ "bounty_hunter_bracer_r_schematic",    2 },
		{ "bounty_hunter_chest_plate_schematic", 2 },
		{ "bounty_hunter_gloves_schematic",      2 },
		{ "bounty_hunter_helmet_schematic",      2 },
		{ "bounty_hunter_leggings_schematic",    2 },
		{ "dw_mando_helmet_schematic",           2 },
		{ "dw_mando_chest_plate_schematic",      2 },
		{ "dw_mando_belt_schematic",             2 },
		{ "dw_mando_boots_schematic",            2 },
		{ "dw_mando_bracer_l_schematic",         2 },
		{ "dw_mando_bracer_r_schematic",         2 },
		{ "dw_mando_bicep_l_schematic",          2 },
		{ "dw_mando_bicep_r_schematic",          2 },
		{ "dw_mando_gloves_schematic",           2 },
		{ "dw_mando_leggings_schematic",         2 },
		{ "dw_mando_jetpack_schematic",          2 },
		{ "fuel_dispersion_unit",                3 },
		{ "injector_tank",                       3 },
		{ "ducted_fan",                          3 },
		{ "krayt_dragon_scales",                 2 },
		{ "krayt_dragon_tissue_common",          3 },
		{ "krayt_dragon_tissue_uncommon",        2 },
		{ "krayt_dragon_tissue_rare",            1 },
	},
	[4] = {
		{ "bounty_hunter_belt_schematic",        2 },
		{ "bounty_hunter_bicep_l_schematic",     2 },
		{ "bounty_hunter_bicep_r_schematic",     2 },
		{ "bounty_hunter_boots_schematic",       2 },
		{ "bounty_hunter_bracer_l_schematic",    2 },
		{ "bounty_hunter_bracer_r_schematic",    2 },
		{ "bounty_hunter_chest_plate_schematic", 2 },
		{ "bounty_hunter_gloves_schematic",      2 },
		{ "bounty_hunter_helmet_schematic",      2 },
		{ "bounty_hunter_leggings_schematic",    2 },
		{ "dw_mando_helmet_schematic",           3 },
		{ "dw_mando_chest_plate_schematic",      3 },
		{ "dw_mando_belt_schematic",             3 },
		{ "dw_mando_boots_schematic",            3 },
		{ "dw_mando_bracer_l_schematic",         3 },
		{ "dw_mando_bracer_r_schematic",         3 },
		{ "dw_mando_bicep_l_schematic",          3 },
		{ "dw_mando_bicep_r_schematic",          3 },
		{ "dw_mando_gloves_schematic",           3 },
		{ "dw_mando_leggings_schematic",         3 },
		{ "dw_mando_jetpack_schematic",          3 },
		{ "fuel_dispersion_unit",                3 },
		{ "injector_tank",                       3 },
		{ "ducted_fan",                          3 },
		{ "krayt_dragon_scales",                 2 },
		{ "krayt_dragon_tissue_common",          3 },
		{ "krayt_dragon_tissue_uncommon",        2 },
		{ "krayt_dragon_tissue_rare",            1 },
		{ "jet_pack_base",                       1 },
		{ "acklay_ris_armor_schematic",          1 },
		{ "peko_albatross_feather",              2 },
		{ "jetpack_stabilizer",                  2 },
	},
}

function MandoWayOfLife:grantChapterLoot(pPlayer, chapter)
	if (pPlayer == nil) then return end
	local pool = self.chapterLootPools[chapter]
	if (pool == nil) then return end

	-- Weighted random pick from pool
	local totalWeight = 0
	for _, entry in ipairs(pool) do
		totalWeight = totalWeight + entry[2]
	end
	local roll = math.random(1, totalWeight)
	local cumulative = 0
	local chosen = nil
	for _, entry in ipairs(pool) do
		cumulative = cumulative + entry[2]
		if (roll <= cumulative) then
			chosen = entry[1]
			break
		end
	end
	if (chosen == nil) then return end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then return end

	-- chapter loot items are loot group item templates, not object templates —
	-- use giveItem with the directObjectTemplate IFF path
	local itemPath = self:resolveChapterLootIff(chosen)
	if (itemPath == nil) then return end

	local pItem = giveItem(pInventory, itemPath, -1)
	if (pItem ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Way of Life] Chapter " .. chapter .. " bonus reward granted.")
	else
		CreatureObject(pPlayer):sendSystemMessage("[MandoWayOfLife] ERROR: could not grant chapter loot (" .. chosen .. "). Contact a GM.")
	end
end

-- Maps loot item template keys to their directObjectTemplate IFF paths
MandoWayOfLife.chapterLootIffMap = {
	-- BH schematics (IFF prefix: death_watch_bounty_hunter_*)
	["bounty_hunter_belt_schematic"]        = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_belt_schematic.iff",
	["bounty_hunter_bicep_l_schematic"]     = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_bicep_l_schematic.iff",
	["bounty_hunter_bicep_r_schematic"]     = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_bicep_r_schematic.iff",
	["bounty_hunter_boots_schematic"]       = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_boots_schematic.iff",
	["bounty_hunter_bracer_l_schematic"]    = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_bracer_l_schematic.iff",
	["bounty_hunter_bracer_r_schematic"]    = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_bracer_r_schematic.iff",
	["bounty_hunter_chest_plate_schematic"] = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_chest_plate_schematic.iff",
	["bounty_hunter_gloves_schematic"]      = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_gloves_schematic.iff",
	["bounty_hunter_helmet_schematic"]      = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_helmet_schematic.iff",
	["bounty_hunter_leggings_schematic"]    = "object/tangible/loot/loot_schematic/death_watch_bounty_hunter_leggings_schematic.iff",
	-- DW Mando schematics
	["dw_mando_helmet_schematic"]           = "object/tangible/loot/loot_schematic/death_watch_mandalorian_helmet_schematic.iff",
	["dw_mando_chest_plate_schematic"]      = "object/tangible/loot/loot_schematic/death_watch_mandalorian_chest_plate_schematic.iff",
	["dw_mando_belt_schematic"]             = "object/tangible/loot/loot_schematic/death_watch_mandalorian_belt_schematic.iff",
	["dw_mando_boots_schematic"]            = "object/tangible/loot/loot_schematic/death_watch_mandalorian_boots_schematic.iff",
	["dw_mando_bracer_l_schematic"]         = "object/tangible/loot/loot_schematic/death_watch_mandalorian_bracer_l_schematic.iff",
	["dw_mando_bracer_r_schematic"]         = "object/tangible/loot/loot_schematic/death_watch_mandalorian_bracer_r_schematic.iff",
	["dw_mando_bicep_l_schematic"]          = "object/tangible/loot/loot_schematic/death_watch_mandalorian_bicep_l_schematic.iff",
	["dw_mando_bicep_r_schematic"]          = "object/tangible/loot/loot_schematic/death_watch_mandalorian_bicep_r_schematic.iff",
	["dw_mando_gloves_schematic"]           = "object/tangible/loot/loot_schematic/death_watch_mandalorian_gloves_schematic.iff",
	["dw_mando_leggings_schematic"]         = "object/tangible/loot/loot_schematic/death_watch_mandalorian_leggings_schematic.iff",
	["dw_mando_jetpack_schematic"]          = "object/tangible/loot/loot_schematic/death_watch_mandalorian_jetpack_schematic.iff",
	-- Jetpack parts (dungeon path confirmed from item templates)
	["fuel_dispersion_unit"]                = "object/tangible/loot/dungeon/death_watch_bunker/fuel_dispersion_unit.iff",
	["injector_tank"]                       = "object/tangible/loot/dungeon/death_watch_bunker/fuel_injector_tank.iff",
	["ducted_fan"]                          = "object/tangible/loot/dungeon/death_watch_bunker/ducted_fan.iff",
	-- Krayt mats (all tissues share the same base IFF; stats vary via loot system)
	["krayt_dragon_scales"]                 = "object/tangible/component/armor/armor_segment_enhancement_krayt.iff",
	["krayt_dragon_tissue_common"]          = "object/tangible/component/weapon/blaster_power_handler_enhancement_krayt.iff",
	["krayt_dragon_tissue_uncommon"]        = "object/tangible/component/weapon/blaster_power_handler_enhancement_krayt.iff",
	["krayt_dragon_tissue_rare"]            = "object/tangible/component/weapon/blaster_power_handler_enhancement_krayt.iff",
	-- Ch4 rare tier
	["jet_pack_base"]                       = "object/tangible/loot/dungeon/death_watch_bunker/jetpack_base.iff",
	["acklay_ris_armor_schematic"]          = "object/tangible/loot/loot_schematic/geonosian_acklay_muscle_armor_schematic.iff",
	["peko_albatross_feather"]              = "object/tangible/component/armor/feather_peko_albatross.iff",
	["jetpack_stabilizer"]                  = "object/tangible/loot/dungeon/death_watch_bunker/jetpack_stabilizer.iff",
}

-- end of replaced implementation ]]

-- ============================================================
-- HELMET CHECK
-- ============================================================

function MandoWayOfLife:hasFoundlingHelmet(pPlayer)
	if (pPlayer == nil) then return false end
	-- Check if Foundling Helmet is in the helmet armor slot
	-- TODO: confirm slot name ("helmet" vs "hat") and template path in-game
	local pSlot = SceneObject(pPlayer):getSlottedObject("helmet")
	if (pSlot == nil) then return false end
	local templateStr = SceneObject(pSlot):getObjectTemplate()
	if (templateStr == nil) then return false end
	return string.find(tostring(templateStr), "foundling_helmet") ~= nil
end

-- ============================================================
-- DAILY CAP RESET
-- ============================================================

function MandoWayOfLife:resetDailyCapIfNeeded(pPlayer)
	if (pPlayer == nil) then return end
	local lastReset = self:readInt(pPlayer, "privateDailyReset")
	local now = os.time()
	-- Reset if more than 24 hours have passed
	if (now - lastReset > 86400) then
		self:writeInt(pPlayer, "privateContractsToday", 0)
		self:writeInt(pPlayer, "privateDailyReset", now)
	end
end

-- ============================================================
-- FRS ENDGAME (Ranks 1-11)
-- TODO: implement after Chapters 0-4 are tested
-- Entry gate: Chapter 4 complete + Master BH
-- See spec Section 16 for full FRS design
-- ============================================================

function MandoWayOfLife:enterFRS(pPlayer)
	-- TODO: implement FRS entry, alignment choice, rank ladder
end
