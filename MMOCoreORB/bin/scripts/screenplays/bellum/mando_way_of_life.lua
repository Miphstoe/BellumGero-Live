-- ============================================================
-- Mandalorian Way of Life
-- Branch: Ender_MandalorianWay
-- Spec: mando_way_of_life_spec.md v1.0
--
-- Lua-first | Minimal C++ | Pre-CU Authentic | BG Rules Compliant
--
-- C++ hooks live in:
--   MissionManagerImplementation.cpp     (Patch 1 — tag BH at accept)
--   MissionObjectiveImplementation.cpp   (Patches 2 & 3 — count on complete; Foundling planet tracker message)
-- ============================================================

MandoWayOfLife = ScreenPlay:new {
	screenplayName = "MandoWayOfLife",
	numberOfActs   = 1,

	-- --------------------------------------------------------
	-- Recruiter: Mos Eisley cantina main hall — MUST match TatooineMosEisleyScreenPlay
	-- mobiles[] Cantina block (cell 1082877), same convention as other cantina NPCs:
	--   spawnMobile(planet, template, respawn, x, z, y, direction, cell)  -- z = height
	-- Default: spawned only by the city screenplay (see tatooine_mos_eisley.lua). Set
	-- SPAWN_RECRUITER_ON_START=true to also spawn from start() (e.g. no city load).
	-- Reference NPCs in that file: noble @ 8.49,-0.894992,4.64; businessman @ 10.65,-0.894992,1.91; etc.
	-- --------------------------------------------------------
	recruiterConfig = {
		planet   = "tatooine",
		x        = 9.2,
		z        = -0.894992,
		y        = 4.64,
		heading  = 200,
		cellId   = 1082877,
		template = "mando_trialmaster",
		name     = "Mando Recruiter",
		-- World waypoint (exterior) — cantina block; NPC is inside cell 1082877
		recruiterWaypointName = "Mandalorian Recruiter",
		recruiterWaypointDesc = "Mos Eisley cantina — speak with the Mandalorian Recruiter inside.",
		recruiterWpX = 3491,
		recruiterWpZ = 5,
		recruiterWpY = -4782,
	},

	-- --------------------------------------------------------
	-- Planet arc: 10 planets in order
	-- fallback coords = NPC city cantina for each planet
	-- TODO: verify all coordinates in-game before final deploy
	-- --------------------------------------------------------
	planetData = {
		-- Tatooine: spawned by TatooineMosEisleyScreenPlay (citySpawn=true skips spawnStaticInformants for this entry).
		[1]  = { planet = "tatooine",  x =  3491, z = 5,  y = -4782, citySpawn = true, parting = "Tatoo system teaches patience. The suns don't rush." },
		[2]  = { planet = "corellia",  x = -367, z = 28, y = -4577, parting = "Corellians talk too much. Learn to listen first." },
		[3]  = { planet = "naboo",     x = -5468, z = 5,  y =  4382, parting = "Beauty hides danger. Do not be deceived by what you see." },
		[4]  = { planet = "dantooine", x = -594, z = 3, y = 2474, parting = "Wide open space. Nowhere to hide. Good." },
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

	-- Mission-terminal quota per Foundling planet (set to 36 for production)
	FOUNDLING_PLANET_QUOTA_TARGET = 6,

	-- ---- Testing / deployment toggles (keep false on live shards) ----
	-- false = recruiter comes from TatooineMosEisleyScreenPlay mobiles (Cantina); true = duplicate spawn from start().
	SPAWN_RECRUITER_ON_START = false,
	-- Grant waypoint + coords but do not spawn a dynamic informant (use a static-placed mando_foundling_informant at planetData coords).
	DEBUG_SKIP_INFORMANT_MOBILE_SPAWN = false,
	-- Allow any mando_foundling_informant to advance convo while Foundling arc is active (ignores per-player OID link). Dev-only.
	DEBUG_ALLOW_ANY_FOUNDLING_INFORMANT = false,
}

registerScreenPlay("MandoWayOfLife", true)

-- Console + log/lua.log (level 1 survives default Lua file log filter).
function MandoWayOfLife:logDiag(msg)
	printf("[MandoWayOfLife] %s\n", msg)
	logLua(1, "[MandoWayOfLife] " .. msg)
end

function MandoWayOfLife:logDiagPlayer(pPlayer, msg)
	local oid = "nil"
	if (pPlayer ~= nil and SceneObject(pPlayer) ~= nil) then
		oid = tostring(SceneObject(pPlayer):getObjectID())
	end
	self:logDiag(msg .. " playerOid=" .. oid)
end

-- Included many times per boot (each zone gets a fresh Lua env; _G does not dedupe). Use server data once per process.
local _MANDO_LOAD_FLAG = "MandoWayOfLife:script_load_announced"
if (tonumber(readData(_MANDO_LOAD_FLAG)) or 0) == 0 then
	writeData(_MANDO_LOAD_FLAG, 1)
	MandoWayOfLife:logDiag(
		"scripts loaded; ScreenPlay registered (start() at boot — recruiter from Tatooine cantina when SPAWN_RECRUITER_ON_START=false)."
	)
end

-- ============================================================
-- STARTUP
-- ============================================================

function MandoWayOfLife:start()
	self:logDiag("start() running (global screenplay boot).")

	-- TEMP: reset QA tester arc data on boot. Remove after confirmed reset.
	-- MandoWayOfLife.consoleResetArc("Ender")

	if (self.SPAWN_RECRUITER_ON_START == false) then
		self:logDiag(
			"SPAWN_RECRUITER_ON_START=false — recruiter is placed by TatooineMosEisleyScreenPlay (Cantina, mando_trialmaster); not spawning here."
		)
	else
		local cfg = self.recruiterConfig
		local cellId = cfg.cellId or 0

		if (isZoneEnabled(cfg.planet) == false) then
			self:logDiag(string.format(
				"recruiter not spawned: zone '%s' is not enabled on this server.",
				cfg.planet
			))
		else
			-- Match TatooineMosEisleyScreenPlay:spawnMobiles() — respawn 60, post-spawn mood + AI_STATIC + clear AI if non-PvP
			local respawn = 60
			local pRecruiter = spawnMobile(cfg.planet, cfg.template, respawn, cfg.x, cfg.z, cfg.y, cfg.heading, cellId)
			if (pRecruiter ~= nil) then
				CreatureObject(pRecruiter):setMoodString("conversation")
				AiAgent(pRecruiter):addObjectFlag(AI_STATIC)
				if (CreatureObject(pRecruiter):getPvpStatusBitmask() == 0) then
					CreatureObject(pRecruiter):clearOptionBit(AIENABLED)
				end
				SceneObject(pRecruiter):setCustomObjectName(cfg.name)
				AiAgent(pRecruiter):setConvoTemplate("mandoTrialmasterConvoTemplate")
				local rid = SceneObject(pRecruiter):getObjectID()
				writeData("mando_way:recruiter_id", rid)
				self:logDiag(string.format(
					"boot OK: recruiter spawned (start() fallback) template=%s oid=%s planet=%s cellId=%s respawn=%s.",
					tostring(cfg.template),
					tostring(rid),
					tostring(cfg.planet),
					tostring(cellId),
					tostring(respawn)
				))
			else
				self:logDiag(string.format(
					"recruiter spawn FAILED: template=%s planet=%s x=%s z=%s y=%s heading=%s cellId=%s (CreatureManager / wrong cell?)",
					tostring(cfg.template),
					tostring(cfg.planet),
					tostring(cfg.x),
					tostring(cfg.z),
					tostring(cfg.y),
					tostring(cfg.heading),
					tostring(cellId)
				))
			end
		end
	end

	-- Spawn one static informant per planet at the cantina area of each major city.
	-- OIDs are written to global data so tryLinkStaticFoundlingInformant() can find them.
	-- NOTE: z values are approximate (terrain height) — verify in-game and update planetData if needed.
	self:spawnStaticInformants()
end

function MandoWayOfLife:spawnStaticInformants()
	local respawn = 0  -- static; no auto-respawn needed
	for i, data in ipairs(self.planetData) do
		if (isZoneEnabled(data.planet) == false) then
			self:logDiag(string.format(
				"informant[%s] skipped: zone '%s' not enabled.",
				tostring(i),
				tostring(data.planet)
			))
		elseif data.citySpawn then
			self:logDiag(string.format(
				"informant[%s] skipped: planet '%s' informant spawned by city screenplay.",
				tostring(i),
				tostring(data.planet)
			))
		else
			local pInformant = spawnMobile(data.planet, "mando_foundling_informant", respawn, data.x, data.z, data.y, 0, 0)
			if (pInformant ~= nil) then
				CreatureObject(pInformant):setPvpStatusBitmask(0)
				CreatureObject(pInformant):setOptionsBitmask(INVULNERABLE + CONVERSABLE)
				CreatureObject(pInformant):setMoodString("conversation")
				SceneObject(pInformant):setCustomObjectName("Mandalorian Informant")
				AiAgent(pInformant):setConvoTemplate("mandoFoundlingInformantConvoTemplate")
				AiAgent(pInformant):addObjectFlag(AI_STATIC)
				local oid = SceneObject(pInformant):getObjectID()
				local key = "mando_way:foundling_informant_static:" .. data.planet
				writeData(key, oid)
				self:logDiag(string.format(
					"informant[%s] spawned OK planet=%s oid=%s coords=(%.1f, %.1f, %.1f)",
					tostring(i),
					tostring(data.planet),
					tostring(oid),
					data.x, data.z, data.y
				))
			else
				self:logDiag(string.format(
					"informant[%s] spawn FAILED planet=%s coords=(%.1f, %.1f, %.1f)",
					tostring(i),
					tostring(data.planet),
					data.x, data.z, data.y
				))
			end
		end
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
	if (self:readInt(pPlayer, "chapter0Started") == 1) then
		self:logDiagPlayer(pPlayer, "startFoundlingArc skipped (chapter 0 already started).")
		return
	end

	self:writeInt(pPlayer, "chapter0Started", 1)
	self:writeInt(pPlayer, "foundling.planetIndex", 0)
	self:writeInt(pPlayer, "foundling.arcComplete", 0)
	self:logDiagPlayer(pPlayer, "Foundling arc started; advancing to planet index 1.")

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		local rw = self:readInt(pPlayer, "foundling.recruiterWaypointId")
		if (rw ~= 0) then
			PlayerObject(pGhost):removeWaypoint(rw, true)
			self:writeInt(pPlayer, "foundling.recruiterWaypointId", 0)
		end
	end

	-- Advance to planet 1 (Tatooine)
	self:advanceToPlanet(pPlayer, 1)
end

-- Advance to next planet in the arc
function MandoWayOfLife:advanceToPlanet(pPlayer, index)
	if (pPlayer == nil) then return end

	local data = self.planetData[index]
	if (data == nil) then
		self:logDiagPlayer(pPlayer, "advanceToPlanet: all planets complete; finishing Foundling arc.")
		self:completeFoundlingArc(pPlayer)
		return
	end

	self:logDiagPlayer(pPlayer, string.format(
		"advanceToPlanet index=%s planet=%s",
		tostring(index),
		tostring(data.planet)
	))

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
	local spawned = self:spawnInformant(pPlayer, index)
	if (spawned) then
		CreatureObject(pPlayer):sendSystemMessage(
			"Your contact is waiting on " .. data.planet .. ". Find them and accept your assignment."
		)
	else
		CreatureObject(pPlayer):sendSystemMessage(
			"[Mandalorian contact] Could not place your contact on " .. data.planet .. ". Check server logs (spawn failure). A GM may need to advance your arc."
		)
	end
end

-- Link player to city-placed static informant (writeData set at ME boot). Stays in-world; do not destroy in despawnInformant.
-- grantInformantWp: false while mission quota is in progress (no "find contact" yellow marker).
function MandoWayOfLife:tryLinkStaticFoundlingInformant(pPlayer, index, grantInformantWp)
	if (pPlayer == nil) then return false end
	if (grantInformantWp == nil) then grantInformantWp = true end
	local data = self.planetData[index]
	if (data == nil) then return false end
	local key = "mando_way:foundling_informant_static:" .. data.planet
	local sid = tonumber(readData(key)) or 0
	if (sid == 0) then return false end
	local pInf = getSceneObject(sid)
	if (pInf == nil) then return false end

	self:writeStr(pPlayer, "foundling.informantId", tostring(sid))
	self:writeInt(pPlayer, "foundling.informantStatic", 1)
	self:writeStr(pPlayer, "foundling.informantCity", "")
	self:writeInt(pPlayer, "foundling.informantCoordX", data.x)
	self:writeInt(pPlayer, "foundling.informantCoordY", data.y)
	if (grantInformantWp) then
		self:grantInformantWaypoint(pPlayer, data)
	end
	self:logDiagPlayer(pPlayer, string.format(
		"informant linked to STATIC oid=%s planet=%s index=%s grantWp=%s",
		tostring(sid),
		tostring(data.planet),
		tostring(index),
		tostring(grantInformantWp)
	))
	return true
end

-- Link player to the static informant for this planet index and grant waypoint.
-- Returns true if a valid static NPC was found and linked.
function MandoWayOfLife:spawnInformant(pPlayer, index)
	if (pPlayer == nil) then return false end
	if (self:tryLinkStaticFoundlingInformant(pPlayer, index, true)) then
		return true
	end
	local data = self.planetData[index]
	self:logDiag(string.format(
		"spawnInformant: no static informant registered for planet=%s index=%s",
		tostring(data and data.planet or "?"),
		tostring(index)
	))
	return false
end

-- If Foundling arc is active but the player has no informant linked (server restart, stale data),
-- re-link to the static NPC and re-grant the waypoint.
function MandoWayOfLife:ensureFoundlingInformant(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "chapter0Started") ~= 1) then return end
	if (self:readInt(pPlayer, "foundling.arcComplete") == 1) then return end

	local idx = self:readInt(pPlayer, "foundling.planetIndex")
	if (idx < 1 or idx > #self.planetData) then return end

	local oid = tonumber(self:readStr(pPlayer, "foundling.informantId")) or 0
	if (oid ~= 0 and getSceneObject(oid) ~= nil) then return end

	local counting = self:readInt(pPlayer, "foundling.planetCountingEnabled")
	local done = self:readInt(pPlayer, "foundling.planetDone")
	local grantWp = (counting ~= 1)

	if (self:tryLinkStaticFoundlingInformant(pPlayer, idx, grantWp)) then
		if (counting == 1 and done == 0) then
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact is linked. Finish your mission quota on this world — no datapad marker until it is complete."
			)
		elseif (counting == 1 and done == 1) then
			self:grantReturnToInformantWaypoint(pPlayer)
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact is available. Check your datapad waypoint to turn in."
			)
		else
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact is available. Check your datapad waypoint."
			)
		end
	else
		self:logDiagPlayer(pPlayer, string.format(
			"ensureFoundlingInformant: no static informant found for planet index %s.",
			tostring(idx)
		))
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
	local isStatic = self:readInt(pPlayer, "foundling.informantStatic") == 1
	local informantId = tonumber(self:readStr(pPlayer, "foundling.informantId")) or 0
	if (informantId ~= 0) then
		if (not isStatic) then
			local pInformant = getSceneObject(informantId)
			if (pInformant ~= nil) then
				deleteData("mando_way:informant:" .. informantId .. ":player")
				SceneObject(pInformant):destroyObjectFromWorld()
			end
		end
		self:writeStr(pPlayer, "foundling.informantId", "0")
	end
	self:writeInt(pPlayer, "foundling.informantStatic", 0)

	-- Remove the informant waypoint from datapad
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		local wpId = self:readInt(pPlayer, "foundling.waypointId")
		if (wpId ~= 0) then
			PlayerObject(pGhost):removeWaypoint(wpId, true)
			self:writeInt(pPlayer, "foundling.waypointId", 0)
		end
		local rwp = tonumber(self:readStr(pPlayer, "foundling.returnWaypointId")) or 0
		if (rwp ~= 0) then
			PlayerObject(pGhost):removeWaypoint(rwp, true)
			self:writeStr(pPlayer, "foundling.returnWaypointId", "0")
		end
	end
end

-- Remove screenplay-tracked Foundling waypoints (recruiter / informant / return)
function MandoWayOfLife:clearFoundlingTrackedWaypoints(pPlayer)
	if (pPlayer == nil) then return end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end
	local po = PlayerObject(pGhost)

	local rw = self:readInt(pPlayer, "foundling.recruiterWaypointId")
	if (rw ~= 0) then
		po:removeWaypoint(rw, true)
		self:writeInt(pPlayer, "foundling.recruiterWaypointId", 0)
	end
	local iw = self:readInt(pPlayer, "foundling.waypointId")
	if (iw ~= 0) then
		po:removeWaypoint(iw, true)
		self:writeInt(pPlayer, "foundling.waypointId", 0)
	end
	local ret = tonumber(self:readStr(pPlayer, "foundling.returnWaypointId")) or 0
	if (ret ~= 0) then
		po:removeWaypoint(ret, true)
		self:writeStr(pPlayer, "foundling.returnWaypointId", "0")
	end
end

function MandoWayOfLife:grantRecruiterWaypoint(pPlayer)
	if (pPlayer == nil) then return end
	local cfg = self.recruiterConfig
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end

	local old = self:readInt(pPlayer, "foundling.recruiterWaypointId")
	if (old ~= 0) then
		PlayerObject(pGhost):removeWaypoint(old, true)
	end

	local wpId = PlayerObject(pGhost):addWaypoint(
		cfg.planet,
		cfg.recruiterWaypointName or "Mandalorian Recruiter",
		cfg.recruiterWaypointDesc or "Mos Eisley cantina — speak with the Mandalorian Recruiter.",
		cfg.recruiterWpX, cfg.recruiterWpZ, cfg.recruiterWpY,
		WAYPOINT_YELLOW, true, true, 0
	)
	if (wpId ~= nil) then
		self:writeInt(pPlayer, "foundling.recruiterWaypointId", wpId)
	end
end

-- Yellow marker to the static informant after mission quota is met (turn-in)
function MandoWayOfLife:grantReturnToInformantWaypoint(pPlayer)
	if (pPlayer == nil) then return end
	local idx = self:readInt(pPlayer, "foundling.planetIndex")
	local data = self.planetData[idx]
	if (data == nil) then return end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end

	local old = tonumber(self:readStr(pPlayer, "foundling.returnWaypointId")) or 0
	if (old ~= 0) then
		PlayerObject(pGhost):removeWaypoint(old, true)
	end

	local wpId = PlayerObject(pGhost):addWaypoint(
		data.planet,
		"Mandalorian Informant",
		"Return to your contact to complete this world's assignment.",
		data.x, data.z, data.y,
		WAYPOINT_YELLOW, true, true, 0
	)
	if (wpId ~= nil) then
		self:writeStr(pPlayer, "foundling.returnWaypointId", tostring(wpId))
	end
end

-- Login: drop stale markers then restore the correct yellow waypoint for Foundling arc state
function MandoWayOfLife:onPlayerLoggedIn(pPlayer)
	if (pPlayer == nil) then return end

	local arcDone = self:readInt(pPlayer, "foundling.arcComplete") == 1
	local ch0 = self:readInt(pPlayer, "chapter0Started") == 1

	if (not self:meetsPrerequisites(pPlayer) and not ch0 and not arcDone) then
		self:clearFoundlingTrackedWaypoints(pPlayer)
		return
	end

	self:clearFoundlingTrackedWaypoints(pPlayer)

	if (arcDone) then
		return
	end

	if (not ch0) then
		if (self:meetsPrerequisites(pPlayer)) then
			self:grantRecruiterWaypoint(pPlayer)
		end
		return
	end

	-- Mid Foundling arc
	local idx = self:readInt(pPlayer, "foundling.planetIndex")
	if (idx < 1 or idx > #self.planetData) then
		return
	end

	local counting = self:readInt(pPlayer, "foundling.planetCountingEnabled")
	local done = self:readInt(pPlayer, "foundling.planetDone")

	if (counting == 1 and done == 0) then
		-- Working quota — no navigation waypoint until quota met
		local sid = tonumber(self:readStr(pPlayer, "foundling.informantId")) or 0
		if (sid == 0 or getSceneObject(sid) == nil) then
			self:tryLinkStaticFoundlingInformant(pPlayer, idx, false)
		end
		local playerId = SceneObject(pPlayer):getObjectID()
		createEvent(self.PLANET_DONE_POLL_MS, self.screenplayName, "checkPlanetDoneEvent", pPlayer, tostring(playerId))
	elseif (counting == 1 and done == 1) then
		self:tryLinkStaticFoundlingInformant(pPlayer, idx, false)
		self:grantReturnToInformantWaypoint(pPlayer)
	else
		if (self:tryLinkStaticFoundlingInformant(pPlayer, idx, true)) then
			self:logDiagPlayer(pPlayer, "onPlayerLoggedIn: static informant linked + informant waypoint granted.")
		else
			self:logDiagPlayer(pPlayer, string.format(
				"onPlayerLoggedIn: no static informant for planet index %s (zone loaded?).",
				tostring(idx)
			))
		end
	end
end

-- Called from informant conversation when player accepts the planet assignment
function MandoWayOfLife:acceptPlanetAssignment(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "foundling.planetCountingEnabled") == 1) then return end

	local target = self.FOUNDLING_PLANET_QUOTA_TARGET or 6
	self:writeInt(pPlayer, "foundling.planetTarget", target)
	self:writeInt(pPlayer, "foundling.planetCompleted", 0)
	self:writeInt(pPlayer, "foundling.planetDone", 0)
	self:writeInt(pPlayer, "foundling.planetCountingEnabled", 1)   -- C++ reads this
	self:logDiagPlayer(pPlayer, string.format(
		"planet assignment accepted: planet=%s mission quota target=%s",
		tostring(self:readStr(pPlayer, "foundling.currentPlanet")),
		tostring(target)
	))

	-- Remove "find informant" marker; no replacement until quota complete (see grantReturnToInformantWaypoint / login refresh)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		local oldWpId = self:readInt(pPlayer, "foundling.waypointId")
		if (oldWpId ~= 0) then
			PlayerObject(pGhost):removeWaypoint(oldWpId, true)
			self:writeInt(pPlayer, "foundling.waypointId", 0)
		end
	end

	CreatureObject(pPlayer):sendSystemMessage(
		"Assignment accepted. Mission-terminal jobs on this planet count toward your quota (not bounty board contracts). Each completion shows your quota and a full planet status list (Done / In progress / Pending)."
	)

	-- Start polling for quota completion (C++ sets planetDone = 1 when done)
	local playerId = SceneObject(pPlayer):getObjectID()
	createEvent(self.PLANET_DONE_POLL_MS, self.screenplayName, "checkPlanetDoneEvent", pPlayer, tostring(playerId))
end

-- Multi-line planet progress for Foundling arc (mission quota). Called from C++ after each counted mission.
function MandoWayOfLife:buildAndSendFoundlingPlanetTracker(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end
	if (self:readInt(pPlayer, "chapter0Started") ~= 1) then return end
	if (self:isArcComplete(pPlayer)) then return end
	if (self:readInt(pPlayer, "foundling.planetCountingEnabled") ~= 1) then return end

	local idx = self:readInt(pPlayer, "foundling.planetIndex")
	if (idx < 1 or idx > #self.planetData) then return end

	local done = self:readInt(pPlayer, "foundling.planetCompleted")
	local target = self:readInt(pPlayer, "foundling.planetTarget")
	local planetDone = self:readInt(pPlayer, "foundling.planetDone")

	local totalPlanets = #self.planetData
	-- Fully turned in at informant: all worlds before current index
	local planetsComplete = math.max(0, idx - 1)
	local planetsRemaining = totalPlanets - planetsComplete

	local pCreature = CreatureObject(pPlayer)
	pCreature:sendSystemMessage("Foundling arc - planet status:")
	pCreature:sendSystemMessage(string.format(
		"Progress: %s/%s planets complete (%s remaining)",
		tostring(planetsComplete),
		tostring(totalPlanets),
		tostring(planetsRemaining)
	))

	for i, data in ipairs(self.planetData) do
		local key = data.planet or ""
		local label = (key ~= "" and (key:sub(1, 1):upper() .. key:sub(2))) or ("#" .. tostring(i))
		local status
		if (i < idx) then
			status = "Done"
		elseif (i > idx) then
			status = "Pending"
		else
			if (planetDone == 1) then
				status = "In progress (quota met - return to your contact)"
			else
				status = string.format("In progress (%s/%s)", tostring(done), tostring(target))
			end
		end
		pCreature:sendSystemMessage(string.format("%s = %s", label, status))
	end
end

-- Global entry for C++ DirectorManager (MissionObjectiveImplementation.cpp).
function MandoWayOfLife.sendFoundlingQuotaTrackerOnMissionComplete(pPlayer)
	MandoWayOfLife:buildAndSendFoundlingPlanetTracker(pPlayer)
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
		local planetKey = self:readStr(player, "foundling.currentPlanet")
		local planetName = planetKey:sub(1,1):upper() .. planetKey:sub(2)
		self:logDiagPlayer(player, string.format(
			"planet quota DONE: %s (return to informant).",
			tostring(planetKey)
		))
		CreatureObject(player):sendSystemMessage(
			"You have proven yourself on " .. planetName .. ". Return to your contact."
		)
		self:grantReturnToInformantWaypoint(player)
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

	self:logDiagPlayer(pPlayer, string.format("turnInPlanet: finished planet index=%s; advancing.", tostring(index)))
	-- Advance to next planet
	self:advanceToPlanet(pPlayer, index + 1)
end

-- Called after all 10 planets complete
function MandoWayOfLife:completeFoundlingArc(pPlayer)
	if (pPlayer == nil) then return end
	self:logDiagPlayer(pPlayer, "completeFoundlingArc: granting chapter 0 (Foundling).")
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
		self:logDiagPlayer(pPlayer, "startChapterGate blocked: missing Novice Bounty Hunter.")
		CreatureObject(pPlayer):sendSystemMessage(
			"Train your craft first. Come back when you have earned Novice Bounty Hunter."
		)
		return
	end

	-- Gate: must have Foundling title (arc complete flag)
	if (not self:isArcComplete(pPlayer)) then
		self:logDiagPlayer(pPlayer, "startChapterGate blocked: Foundling arc not complete.")
		CreatureObject(pPlayer):sendSystemMessage(
			"No helm. No chain-code. No work."
		)
		return
	end

	-- Already gating
	if (self:readInt(pPlayer, "countingEnabled") == 1) then
		self:logDiagPlayer(pPlayer, "startChapterGate skipped: gate cycle already in progress.")
		return
	end

	-- Reset BH terminal counter for this gate cycle
	self:writeInt(pPlayer, "bhTerminalCount", 0)
	self:writeInt(pPlayer, "countingEnabled", 1)    -- C++ reads this
	self:writeInt(pPlayer, "needsCustomContract", 0)

	self:logDiagPlayer(pPlayer, string.format(
		"startChapterGate OK: chapter=%s BH terminal gate started (0/5).",
		tostring(ch)
	))
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
		self:writeInt(player, "countingEnabled", 0)
		self:writeInt(player, "needsCustomContract", 1)
		self:logDiagPlayer(player, "gateProgressEvent: 5/5 BH terminals — private contract unlocked.")
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
		self:logDiagPlayer(pPlayer, "beginPrivateContract blocked: Foundling helmet not equipped.")
		CreatureObject(pPlayer):sendSystemMessage("No helm. No chain-code. No work.")
		return false
	end

	-- Solo check at accept
	if (CreatureObject(pPlayer):isGrouped()) then
		self:logDiagPlayer(pPlayer, "beginPrivateContract blocked: player is grouped.")
		CreatureObject(pPlayer):sendSystemMessage("You must face this trial alone.")
		return false
	end

	-- Daily cap check
	self:resetDailyCapIfNeeded(pPlayer)
	local todayCount = self:readInt(pPlayer, "privateContractsToday")
	if (todayCount >= self.PRIVATE_CONTRACT_DAILY_CAP) then
		self:logDiagPlayer(pPlayer, string.format(
			"beginPrivateContract blocked: daily cap (%s/%s).",
			tostring(todayCount),
			tostring(self.PRIVATE_CONTRACT_DAILY_CAP)
		))
		CreatureObject(pPlayer):sendSystemMessage(
			"You have reached today's contract limit. Return tomorrow."
		)
		return false
	end

	-- Spawn contract target near player's current position
	local spawnX = SceneObject(pPlayer):getWorldPositionX() + 200
	local spawnZ = SceneObject(pPlayer):getWorldPositionZ()
	local spawnY = SceneObject(pPlayer):getWorldPositionY()
	local planet = SceneObject(pPlayer):getZoneName()

	local pTarget = spawnMobile(planet, "mando_contract_target", 0, spawnX, spawnZ, spawnY, 180, 0)
	if (pTarget == nil) then
		self:logDiagPlayer(pPlayer, string.format(
			"beginPrivateContract FAILED: could not spawn mando_contract_target on %s.",
			tostring(planet)
		))
		CreatureObject(pPlayer):sendSystemMessage(
			"[MandoWayOfLife] ERROR: could not spawn contract target. Contact a GM."
		)
		return false
	end
	local targetOid = SceneObject(pTarget):getObjectID()
	self:writeStr(pPlayer, "contractTargetId", tostring(targetOid))

	-- Mark contract in progress
	self:writeInt(pPlayer, "privateContractActive", 1)
	self:writeInt(pPlayer, "privateContractsToday", todayCount + 1)
	self:logDiagPlayer(pPlayer, string.format(
		"beginPrivateContract OK: target oid=%s planet=%s contractsToday=%s.",
		tostring(targetOid),
		tostring(planet),
		tostring(todayCount + 1)
	))

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
	self:logDiagPlayer(pPlayer, "failPrivateContract: " .. tostring(msg))
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
	self:logDiagPlayer(pPlayer, string.format("completePrivateContract: advanced to chapter %s.", tostring(ch)))

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
	if (pInventory == nil) then
		self:logDiagPlayer(pPlayer, string.format("grantReward FAILED: no inventory (chapter %s).", tostring(chapter)))
		return
	end

	self:logDiagPlayer(pPlayer, string.format("grantReward: chapter %s.", tostring(chapter)))

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
		self:logDiagPlayer(pPlayer, string.format(
			"grantChapterLoot OK: chapter=%s group=%s level=%s.",
			tostring(chapter),
			tostring(entry.group),
			tostring(entry.level)
		))
		CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Way of Life] Chapter " .. chapter .. " bonus reward granted.")
	else
		self:logDiagPlayer(pPlayer, string.format(
			"grantChapterLoot FAILED: chapter=%s group=%s.",
			tostring(chapter),
			tostring(entry.group)
		))
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
-- ADMIN: Foundling quota / screenplay (slash: /mandoFoundlingAdmin)
-- C++ counts standard mission-terminal types; excludes BOUNTY (MissionObjectiveImplementation).
-- ============================================================

function mandoFoundlingAdminRun(pStaff, argLine)
	MandoWayOfLife:adminFoundlingCommand(pStaff, argLine or "")
end

local function _mandoAdminTrim(s)
	if (s == nil) then return "" end
	return (tostring(s):gsub("^%s*(.-)%s*$", "%1"))
end

function MandoWayOfLife:adminFoundlingCommand(pStaff, argLine)
	if (pStaff == nil) then return end
	local sGhost = CreatureObject(pStaff):getPlayerObject()
	if (sGhost == nil or not PlayerObject(sGhost):isPrivileged()) then
		CreatureObject(pStaff):sendSystemMessage("[MandoAdmin] Denied (requires privileged admin).")
		return
	end

	local line = _mandoAdminTrim(argLine)
	local fixdone = false
	local name = ""
	local tokens = {}
	for w in string.gmatch(line, "%S+") do
		tokens[#tokens + 1] = w
	end

	if (#tokens == 1) then
		if (tokens[1]:lower() == "fixdone") then
			fixdone = true
		else
			name = tokens[1]
		end
	elseif (#tokens >= 2) then
		local t1, t2 = tokens[1]:lower(), tokens[2]:lower()
		if (t1 == "fixdone") then
			fixdone = true
			name = tokens[2]
		elseif (t2 == "fixdone") then
			name = tokens[1]
			fixdone = true
		else
			name = tokens[1]
		end
	end

	local pTarget = pStaff
	if (name ~= "") then
		local pNamed = getPlayerByName(name)
		if (pNamed == nil) then
			CreatureObject(pStaff):sendSystemMessage(
				"[MandoAdmin] Character must be online. No match for: " .. name
			)
			return
		end
		pTarget = pNamed
	end

	local tgtName = CreatureObject(pTarget):getFirstName()
	local ch0 = self:readInt(pTarget, "chapter0Started")
	local arc = self:readInt(pTarget, "foundling.arcComplete")
	local idx = self:readInt(pTarget, "foundling.planetIndex")
	local planet = self:readStr(pTarget, "foundling.currentPlanet")
	local cntEn = self:readInt(pTarget, "foundling.planetCountingEnabled")
	local pDone = self:readInt(pTarget, "foundling.planetDone")
	local completed = self:readInt(pTarget, "foundling.planetCompleted")
	local target = self:readInt(pTarget, "foundling.planetTarget")
	local infId = self:readStr(pTarget, "foundling.informantId")
	local infSt = self:readInt(pTarget, "foundling.informantStatic")
	local chapter = self:readInt(pTarget, "chapter")

	CreatureObject(pStaff):sendSystemMessage(string.format(
		"[MandoAdmin] %s | ch0Started=%s arcComplete=%s chapter=%s | planetIdx=%s currentPlanet=%s | counting=%s completed=%s target=%s planetDone=%s | informantOid=%s staticInformant=%s",
		tgtName,
		tostring(ch0),
		tostring(arc),
		tostring(chapter),
		tostring(idx),
		planet,
		tostring(cntEn),
		tostring(completed),
		tostring(target),
		tostring(pDone),
		tostring(infId),
		tostring(infSt)
	))

	CreatureObject(pStaff):sendSystemMessage(
		"[MandoAdmin] Quota counts mission-terminal completions (destroy, deliver, hunting, recon, crafting, survey, escort). Bounty board missions do not count."
	)

	local bhEn = self:readInt(pTarget, "countingEnabled")
	local bhCt = self:readInt(pTarget, "bhTerminalCount")
	CreatureObject(pStaff):sendSystemMessage(string.format(
		"[MandoAdmin] Spynet (later chapter): countingEnabled=%s bhTerminalCount=%s/5",
		tostring(bhEn),
		tostring(bhCt)
	))

	if (not fixdone) then
		return
	end

	if (cntEn ~= 1) then
		CreatureObject(pStaff):sendSystemMessage("[MandoAdmin] fixdone skipped: foundling.planetCountingEnabled ~= 1")
		return
	end
	if (target <= 0) then
		CreatureObject(pStaff):sendSystemMessage("[MandoAdmin] fixdone skipped: planetTarget is 0")
		return
	end
	if (completed < target) then
		CreatureObject(pStaff):sendSystemMessage(string.format(
			"[MandoAdmin] fixdone skipped: completed %s < target %s.",
			tostring(completed),
			tostring(target)
		))
		return
	end
	if (pDone == 1) then
		CreatureObject(pStaff):sendSystemMessage("[MandoAdmin] fixdone noop: planetDone already 1")
		return
	end

	self:writeInt(pTarget, "foundling.planetDone", 1)
	CreatureObject(pStaff):sendSystemMessage("[MandoAdmin] Set foundling.planetDone=1.")
	CreatureObject(pTarget):sendSystemMessage("A GM marked your Foundling planet work complete. Speak with the Mandalorian Informant to turn in.")
end

-- Console reset: runLuaFunction MandoWayOfLife:consoleResetArc <playerName>
-- Defined with dot notation so runLuaFunction passes arg correctly (no implicit self).
function MandoWayOfLife.consoleResetArc(name)
	if (name == nil or name == "") then
		printf("[MandoWayOfLife] consoleResetArc: usage: runLuaFunction MandoWayOfLife consoleResetArc <playerName>\n")
		return
	end
	local p = getPlayerByName(name)
	if (p == nil) then
		printf("[MandoWayOfLife] consoleResetArc: no online player named '%s'\n", tostring(name))
		return
	end
	local keys = {
		"chapter", "chapter0Started", "chapter0Complete", "chapter1Complete",
		"chapter2Complete", "chapter3Complete", "chapter4Complete",
		"foundling.arcComplete", "foundling.planetIndex", "foundling.currentPlanet",
		"foundling.planetCountingEnabled", "foundling.planetDone",
		"foundling.planetCompleted", "foundling.planetTarget",
		"foundling.informantId", "foundling.informantStatic",
		"foundling.informantCoordX", "foundling.informantCoordY",
		"foundling.waypointId", "foundling.returnWaypointId", "foundling.recruiterWaypointId",
		"countingEnabled", "bhTerminalCount", "privateContractActive", "contractTargetId",
	}
	for _, k in ipairs(keys) do
		writeScreenPlayData(p, "MandoWayOfLife", k, "0")
	end
	-- Remove any lingering waypoints
	local pGhost = CreatureObject(p):getPlayerObject()
	if (pGhost ~= nil) then
		local recWp = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.recruiterWaypointId")) or 0
		if (recWp ~= 0) then PlayerObject(pGhost):removeWaypoint(recWp, true) end
		local wpId = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.waypointId")) or 0
		if (wpId ~= 0) then PlayerObject(pGhost):removeWaypoint(wpId, true) end
		local rwpId = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.returnWaypointId")) or 0
		if (rwpId ~= 0) then PlayerObject(pGhost):removeWaypoint(rwpId, true) end
	end
	printf("[MandoWayOfLife] consoleResetArc: arc reset for '%s'. Player must relog and return to Trialmaster.\n", tostring(name))
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
