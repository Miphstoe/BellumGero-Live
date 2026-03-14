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
		[1] = "object/tangible/wearables/armor/mandalorian/custom/initiate_chest.iff",
		[2] = "object/tangible/wearables/armor/mandalorian/custom/hunter_bracers.iff",
		[3] = "object/tangible/wearables/armor/mandalorian/custom/verdika_boots.iff",
		[4] = nil, -- Clanbound: no new armor piece; grants alignment access
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

	-- Mark contract in progress
	self:writeInt(pPlayer, "privateContractActive", 1)
	self:writeInt(pPlayer, "privateContractsToday", todayCount + 1)

	-- Start periodic solo + helmet enforcement
	local playerId = SceneObject(pPlayer):getObjectID()
	createEvent(self.SOLO_CHECK_INTERVAL_MS, self.screenplayName, "soloCheckEvent", pPlayer, tostring(playerId))

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
	-- TODO: cancel the active mission object when mission scripting is complete
end

-- Called from contract completion trigger when player succeeds
function MandoWayOfLife:completePrivateContract(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then return end

	self:writeInt(pPlayer, "privateContractActive", 0)
	self:writeInt(pPlayer, "needsCustomContract", 0)

	-- Advance chapter
	local ch = self:getChapter(pPlayer)
	ch = ch + 1
	self:setChapter(pPlayer, ch)
	self:writeInt(pPlayer, "chapter" .. ch .. "Complete", 1)

	-- Grant armor reward
	self:grantReward(pPlayer, ch)

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
	local template = self.chapterRewards[chapter]
	if (template == nil) then return end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then return end

	local pItem = giveItem(pInventory, template, -1)
	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[MandoWayOfLife] ERROR: could not grant reward for chapter " .. chapter .. ". Contact a GM."
		)
	end
end

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
