-- ============================================================
-- Mandalorian Way of Life
-- Branch: Ender_MandalorianWay
-- Spec: mando_way_of_life_spec.md v1.0
--
-- Lua-first | Minimal C++ | Pre-CU Authentic | BG Rules Compliant
--
-- C++ hooks live in:
--   MissionManagerImplementation.cpp     (Patch 1 - tag BH at accept; optional, completion no longer depends on it)
--   MissionObjectiveImplementation.cpp   (Patches 2 & 3 - count NPC BH on complete; Foundling planet tracker message)
--
-- --- AiAgent options: AIENABLED (project convention) ---
-- AIENABLED is OptionBitmask::AIENABLED (0x00000080) in src/templates/params/OptionBitmask.h.
-- Lua globals AIENABLED, CONVERSABLE, INVULNERABLE are injected by DirectorManager / CreatureTemplateManager
-- (same numeric values as C++ OptionBitmask).
-- CreatureObject:setOptionsBitmask(bits) REPLACES the whole mask, it does not OR with the creature template.
-- So any post-spawn script that sets the mask must list every required bit. For Bellum quest NPCs that use
-- radial "Converse", use AIENABLED + INVULNERABLE + CONVERSABLE unless a case intentionally disables AI
-- (document that exception inline). AiAgentImplementation gates various AI/conversation paths on AIENABLED;
-- CONVERSABLE is the Lua name for the CONVERSE bit (0x08).
-- Shared setup for Foundling informant mobiles: configureFoundlingInformantMobile() below.
-- ============================================================

MandoWayOfLife = ScreenPlay:new {
	screenplayName = "MandoWayOfLife",
	numberOfActs   = 1,

	-- --------------------------------------------------------
	-- Recruiter: Mos Eisley cantina main hall - MUST match TatooineMosEisleyScreenPlay
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
		-- World waypoint (exterior) - cantina block; NPC is inside cell 1082877
		recruiterWaypointName = "Mandalorian Recruiter",
		recruiterWaypointDesc = "Mos Eisley cantina. Speak with the Mandalorian Recruiter inside.",
		recruiterWpX = 3491,
		recruiterWpZ = 5,
		recruiterWpY = -4782,
	},

	-- --------------------------------------------------------
	-- Chapter gate briefing (Foundling + Novice BH): recruiter sends player to operative + BH terminals
	-- Operative spawn MUST match corellia_static_spawns.lua (mando_spynet_operative).
	-- BH reference: Corellia Tyrena exterior near trainer_bountyhunter (terminals in guild hall).
	-- --------------------------------------------------------
	chapterGateBriefingConfig = {
		operativePlanet = "corellia",
		operativeWaypointName = "Mandalorian Operative (Spynet)",
		operativeWaypointDesc = "Private network contact. Start your Spynet count here before using BH terminals.",
		operativeX = 27,
		operativeZ = 28,
		operativeY = -4712,
		bhRefPlanet = "corellia",
		bhRefWaypointName = "BH mission terminals (Tyrena)",
		bhRefWaypointDesc = "Bounty Hunter guild. Use mission terminals here for Spynet NPC bounty contracts.",
		bhRefX = -5130,
		bhRefZ = 21,
		bhRefY = -2302,
		-- Purple datapad waypoint: return to operative after 5/5 or after each trial (next gate cycle)
		-- Player-visible strings: plain ASCII letters and punctuation only (no hyphen or em dash as separators; some clients box them).
		trialReturnWaypointName = "Mandalorian Operative (private trial)",
		trialReturnWaypointDesc = "Spynet 5/5 complete, or next chapter gate: return here (helmet on, solo for the trial).",
		-- Orange datapad pin for the active private trial mark (not a terminal mission object).
		privateContractMarkWaypointName = "Spynet contract mark",
		privateContractMarkWaypointDesc = "Private trial: eliminate this mark. Helmet on, solo, no group.",
	},

	-- --------------------------------------------------------
	-- Planet arc: 10 planets in order
	-- fallback coords = NPC city cantina for each planet
	-- TODO: verify all coordinates in-game before final deploy
	-- --------------------------------------------------------
	planetData = {
		-- Tatooine: per-player informant via spawnInformant(); citySpawn=false so GM spawnStaticInformants can place a hub if ever needed.
		[1]  = { planet = "tatooine",  x =  3491, z = 5,  y = -4782, citySpawn = false, parting = "Tatoo system teaches patience. The suns don't rush." },
		[2]  = { planet = "corellia",  x = -367, z = 28, y = -4577, parting = "Corellians talk too much. Learn to listen first." },
		[3]  = { planet = "naboo",     x = -5468, z = 5,  y =  4382, parting = "Beauty hides danger. Do not be deceived by what you see." },
		[4]  = { planet = "dantooine", x = -594, z = 3, y = 2474, parting = "Wide open space. Nowhere to hide. Good." },
		[5]  = { planet = "lok",       x =   456, z = 2,  y =  5434, parting = "Lok does not forgive weakness. Neither do we." },
		-- Rori / Narmle: player-verified open-ground HUD (avoid prior porch/structure spot; LoS + cell rules for Converse).
		[6]  = { planet = "rori",      x = -5185, z =  80, y = -2197, parting = "Two moons. Two sides. Pick neither until you understand both." },
		-- Talus / Dearic: open-ground HUD (revert mistaken Talus assignment of Endor outpost coords).
		[7]  = { planet = "talus",     x = 455, z = 6, y = -3120, parting = "Gray work on a gray world. Stay sharp." },
		-- Endor: player HUD near research/smuggler outpost (spawnMobile x,z,y); aligns ~ w/ myswg_vendor @ 3201,24,-3501.
		[8]  = { planet = "endor",     x = 3220, z = 24, y = -3430, parting = "The forest watches. So should you." },
		-- Dathomir / Science Outpost: player HUD open ground (spawnMobile x,z,y); prior coords were remote.
		[9]  = { planet = "dathomir",  x = -123, z = 18, y = -1609, parting = "Few survive Dathomir. You will not be an exception unless you earn it." },
		[10] = { planet = "yavin4",    x = -289, z = 35,  y = 4901, parting = "The Force has no claim on us. We claim ourselves." },
	},

	-- --------------------------------------------------------
	-- Chapter rewards - each chapter grants only that tier’s armor set.
	-- Ch0 Foundling  LIGHT  25% K/E                      | helmet only
	-- Ch1 Initiate   LIGHT  35% K/E+Heat                 | helmet + chest
	-- Ch2 Hunter     LIGHT  45% K/E+Heat+Cold             | helmet + chest + legs
	-- Ch3 Verd’ika   MEDIUM 55% K/E+Heat+Cold+Blast       | helmet + chest + legs + gloves
	-- Ch4 Clanbound  HEAVY  65% K/E+Heat+Cold+Blast+Acid  | helmet + chest + legs + gloves + boots
	-- Ch5 Mandalorian: title + badge only (see grantMandalorian). Requires Jabba Themepark.
	-- Ch0 = Foundling arc. Ch1-4 = Spynet 5+1 gate completions. Ch5 = Jabba Themepark gate.
	-- --------------------------------------------------------
	chapterRewards = {
		[0] = "object/tangible/wearables/armor/mandalorian/custom/foundling_helmet.iff",
		[1] = {
			"object/tangible/wearables/armor/mandalorian/custom/initiate_helmet.iff",
			"object/tangible/wearables/armor/mandalorian/custom/initiate_chest.iff",
		},
		[2] = {
			"object/tangible/wearables/armor/mandalorian/custom/hunter_helmet.iff",
			"object/tangible/wearables/armor/mandalorian/custom/hunter_chest.iff",
			"object/tangible/wearables/armor/mandalorian/custom/hunter_legs.iff",
		},
		[3] = {
			"object/tangible/wearables/armor/mandalorian/custom/verdika_helmet.iff",
			"object/tangible/wearables/armor/mandalorian/custom/verdika_chest.iff",
			"object/tangible/wearables/armor/mandalorian/custom/verdika_legs.iff",
			"object/tangible/wearables/armor/mandalorian/custom/verdika_gloves.iff",
		},
		[4] = {
			-- Clanbound 5-piece set (boots are the new addition at this tier)
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_helmet.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_chest.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_legs.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_gloves.iff",
			"object/tangible/wearables/armor/mandalorian/custom/clanbound_shoes.iff",
		},
		-- [5] Mandalorian: no armor reward; title + badge only (grantMandalorian)
	},

	-- System messages / prose (human-readable)
	chapterTitles = {
		[0] = "Foundling",
		[1] = "Initiate",
		[2] = "Hunter",
		[3] = "Verd’ika",
		[4] = "Clanbound",
		[5] = "Mandalorian",
	},
	-- Equippable title skills (title = 1); must match bin/scripts/skills/bellum/mando_titles.lua
	chapterTitleSkills = {
		[0] = "mando_title_foundling",
		[1] = "mando_title_initiate",
		[2] = "mando_title_hunter",
		[3] = "mando_title_verdika",
		[4] = "mando_title_clanbound",
		[5] = "mando_title_mandalorian",
	},
	-- Badge bitmask indices from datatables/badge/badge_map.iff (0-159). Must match client + server TRE (e.g. bg_custom1) and badge_n/badge_d.
	chapterBadgeIds = {
		[0] = 140, -- bdg_mando_foundling
		[1] = 141, -- bdg_mando_initiate
		[2] = 142, -- bdg_mando_hunter
		[3] = 143, -- bdg_mando_verdika
		[4] = 144, -- bdg_mando_clanbound
		[5] = 145, -- bdg_mando_mandalorian
	},

	-- Jabba Themepark badge (global THEME_PARK_JABBA_BADGE = 105 from themeParkJabba.lua).
	-- grantMandalorian() checks this before granting Ch5.
	JABBA_THEMEPARK_BADGE = 105,

	-- Chapter trial gifts: clan armory weapons (hidden certs; not usable without Mando Way chapter skill).
	-- Schematics sold by recruiter after the same chapter completes (see trySellMandoArmorySchematic).
	mandoWayArmoryChapters = {
		[1] = {
			certSkill = "mando_way_cert_geo_blaster",
			weaponIff = "object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.iff",
			giftMsg = "[Mandalorian Way] Armory gift: Mandalorian Geonosian blaster pistol. Only those who hold your certifications can fire it.",
		},
		[2] = {
			certSkill = "mando_way_cert_slugthrower_carbine",
			weaponIff = "object/weapon/ranged/carbine/carbine_mando_way_slugthrower.iff",
			giftMsg = "[Mandalorian Way] Armory gift: Mandalorian Nym slugthrower carbine. Your trials earned the right to carry it.",
		},
		[3] = {
			certSkill = "mando_way_cert_lightning_cannon",
			weaponIff = "object/weapon/ranged/rifle/rifle_mando_way_lightning.iff",
			giftMsg = "[Mandalorian Way] Armory gift: Mandalorian light lightning cannon. Respect the charge.",
		},
	},
	mandoWayArmorySchematicSales = {
		[1] = { chapterFlag = "chapter1Complete", cost = 25000, iff = "object/tangible/loot/loot_schematic/mando_way_geo_blaster_schematic.iff" },
		[2] = { chapterFlag = "chapter2Complete", cost = 50000, iff = "object/tangible/loot/loot_schematic/mando_way_slugthrower_schematic.iff" },
		[3] = { chapterFlag = "chapter3Complete", cost = 85000, iff = "object/tangible/loot/loot_schematic/mando_way_lightning_schematic.iff" },
	},

	-- Legacy: strip old Spynet coordinate disks from inventory on fail/complete/reset (no longer granted).
	SPYNET_CONTRACT_WAYPOINT_DISK_IFF = "object/tangible/mission/mando_spynet_contract_waypoint_disk.iff",
	SPYNET_CONTRACT_DISK_FALLBACK_IFF = "object/tangible/mission/mission_datadisk.iff",
	SPYNET_CONTRACT_DISK_DISPLAY_NAME = "Spynet Coordinate Disk",

	-- Solo check interval (ms)
	SOLO_CHECK_INTERVAL_MS = 30000,

	-- Contract target completion check interval (ms)
	CONTRACT_CHECK_INTERVAL_MS = 10000,
	-- After Spynet bounty-camp mark kill: defer GoToTheater teardown; chapter rewards run after this delay (camp despawn) for camp trials.
	SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS = 60000,
	-- If getSceneObject/getCreatureObject never resolve the contract OID but the player stays near the stored spawn anchor, complete after this many unresolved ticks (x interval above).
	PRIVATE_CONTRACT_FALLBACK_COMPLETE_NIL_TICKS = 9,
	-- Squared horizontal distance in world X/Y (m^2) from stored anchor for fallback completion. Default 192m radius.
	PRIVATE_CONTRACT_FALLBACK_RADIUS_SQ = 36864,

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
	-- Extra printf/logLua lines for Spynet private trial + bounty camp GoToTheater (grep [SpynetDebug]). Default false; set true on dev shards when diagnosing.
	SPYNET_BOUNTY_DEBUG_VERBOSE = false,
}

registerScreenPlay("MandoWayOfLife", true)

-- Console + log/lua.log (level 1 survives default Lua file log filter). Always uses printf so lines appear on the core3 terminal / core3.log.
function MandoWayOfLife:logDiag(msg)
	printf("[MandoWayOfLife] %s\n", msg)
	logLua(1, "[MandoWayOfLife] " .. msg)
end

-- Appends playerOid and delegates to logDiag only (one printf + one logLua). Do not call printf/logLua here.
function MandoWayOfLife:logDiagPlayer(pPlayer, msg)
	local oid = "nil"
	if (pPlayer ~= nil and SceneObject(pPlayer) ~= nil) then
		oid = tostring(SceneObject(pPlayer):getObjectID())
	end
	self:logDiag(msg .. " playerOid=" .. oid)
end

-- Spynet / bounty camp only; gated by SPYNET_BOUNTY_DEBUG_VERBOSE (grep [SpynetDebug]).
function MandoWayOfLife:logSpynetDebug(pPlayer, msg)
	if (self.SPYNET_BOUNTY_DEBUG_VERBOSE ~= true) then
		return
	end
	self:logDiagPlayer(pPlayer, "[SpynetDebug] " .. tostring(msg))
end

-- Included many times per boot (each zone gets a fresh Lua env; _G does not dedupe). Use server data once per process.
local _MANDO_LOAD_FLAG = "MandoWayOfLife:script_load_announced"
if (tonumber(readData(_MANDO_LOAD_FLAG)) or 0) == 0 then
	writeData(_MANDO_LOAD_FLAG, 1)
	MandoWayOfLife:logDiag(
		"scripts loaded; ScreenPlay registered (start() at boot: recruiter from Tatooine cantina when SPAWN_RECRUITER_ON_START=false)."
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
			"SPAWN_RECRUITER_ON_START=false - recruiter is placed by TatooineMosEisleyScreenPlay (Cantina, mando_trialmaster); not spawning here."
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
			-- Match TatooineMosEisleyScreenPlay mando_trialmaster block: AIENABLED + CONVERSABLE (do NOT clear AIENABLED).
			-- Older generic pattern cleared AI for PvP-neutral mobs; recruiter must stay conversable like city spawn.
			local respawn = 60
			local pRecruiter = spawnMobile(cfg.planet, cfg.template, respawn, cfg.x, cfg.z, cfg.y, cfg.heading, cellId)
			if (pRecruiter ~= nil) then
				CreatureObject(pRecruiter):setPvpStatusBitmask(0)
				CreatureObject(pRecruiter):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
				CreatureObject(pRecruiter):setMoodString("conversation")
				SceneObject(pRecruiter):setCustomObjectName(cfg.name)
				AiAgent(pRecruiter):setConvoTemplate("mandoTrialmasterConvoTemplate")
				AiAgent(pRecruiter):addObjectFlag(AI_STATIC)
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

	-- Dynamic spawn mode: informant NPCs are spawned per-player via spawnInformant() when
	-- a player advances to each planet. spawnStaticInformants() is kept below for GM admin
	-- use (Option 5 respawn command) but is NOT called at boot.
end

-- Post-spawn configuration for template mando_foundling_informant (dynamic spawn, GM static spawn).
-- Keeps AIENABLED + CONVERSABLE + INVULNERABLE in one place - see file header for why all three matter.
function MandoWayOfLife:configureFoundlingInformantMobile(pInformant)
	if (pInformant == nil) then return end
	CreatureObject(pInformant):setPvpStatusBitmask(0)
	-- Full mask replace: must include AIENABLED (see OptionBitmask.h) so AI agent accepts converse pipeline.
	CreatureObject(pInformant):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
	CreatureObject(pInformant):setMoodString("conversation")
	SceneObject(pInformant):setCustomObjectName("Mandalorian Informant")
	AiAgent(pInformant):setConvoTemplate("mandoFoundlingInformantConvoTemplate")
	AiAgent(pInformant):addObjectFlag(AI_STATIC)
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
				-- GM / legacy static hub: same options as per-player dynamic informant (AIENABLED + converse bits).
				self:configureFoundlingInformantMobile(pInformant)
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
	self:grantFoundlingBeskarCdefKit(pPlayer)
end

-- Foundling arc start: recruiter kit (CDEF appearance family, species CDEF certs, tuned combat).
function MandoWayOfLife:grantFoundlingBeskarCdefKit(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end

	local iffs = {
		"object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.iff",
		"object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.iff",
		"object/weapon/ranged/carbine/carbine_foundling_cdef_beskar.iff",
	}

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		self:logDiagPlayer(pPlayer, "grantFoundlingBeskarCdefKit: no inventory.")
		return
	end

	for i = 1, #iffs do
		if (SceneObject(pInventory):isContainerFullRecursive()) then
			CreatureObject(pPlayer):sendSystemMessage(
				"Your inventory is full. I could not pass you the full Foundling Beskar arm. Clear at least three slots and contact staff if you need the kit."
			)
			self:logDiagPlayer(pPlayer, "grantFoundlingBeskarCdefKit: inventory full before kit complete.")
			return
		end
		local pItem = giveItem(pInventory, iffs[i], -1)
		if (pItem == nil) then
			CreatureObject(pPlayer):sendSystemMessage(
				"Something blocked your Foundling Beskar transfer. Clear bag space and contact staff if this repeats."
			)
			self:logDiagPlayer(pPlayer, string.format("grantFoundlingBeskarCdefKit: giveItem failed at index %s.", tostring(i)))
			return
		end
	end

	CreatureObject(pPlayer):sendSystemMessage(
		"You carry Foundling Beskar CDEF arms now. Use what fits your stance. Your contact on Tatooine is waiting."
	)
	self:logDiagPlayer(pPlayer, "grantFoundlingBeskarCdefKit: all three weapons granted.")
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

-- Spawn a private informant NPC for this player on the given planet index.
-- Each player gets their own NPC - no shared static keys, no zone-restart wipe.
-- grantWaypoint: true = grant "find informant" yellow waypoint (pass false when mid-quota).
-- Returns true on success.
function MandoWayOfLife:spawnInformant(pPlayer, index, grantWaypoint)
	if (pPlayer == nil) then return false end
	if (grantWaypoint == nil) then grantWaypoint = true end
	local data = self.planetData[index]
	if (data == nil) then return false end

	-- Clean up any existing informant first (defensive: handles desync where old NPC still alive)
	local oldOid = tonumber(self:readStr(pPlayer, "foundling.informantId")) or 0
	if (oldOid ~= 0) then
		local pOld = getSceneObject(oldOid)
		if (pOld ~= nil) then
			deleteData("mando_way:informant:" .. tostring(oldOid) .. ":player")
			SceneObject(pOld):destroyObjectFromWorld()
		end
		self:writeStr(pPlayer, "foundling.informantId", "0")
	end

	local pInformant = spawnMobile(data.planet, "mando_foundling_informant", 0, data.x, data.z, data.y, 0, 0)
	if (pInformant == nil) then
		self:logDiagPlayer(pPlayer, string.format(
			"spawnInformant: spawnMobile FAILED planet=%s index=%s coords=(%.1f, %.1f, %.1f)",
			tostring(data.planet), tostring(index), data.x, data.z, data.y
		))
		return false
	end

	-- Per-player informant: shared creature flags (AIENABLED + CONVERSABLE + INVULNERABLE); see configureFoundlingInformantMobile().
	-- Note: NpcConversationStart still requires same cell as player, ~6m, LoS - bad z on planetData breaks LoS with no client error.
	self:configureFoundlingInformantMobile(pInformant)

	local oid = SceneObject(pInformant):getObjectID()
	local playerOid = SceneObject(pPlayer):getObjectID()

	-- Register ownership so conv handler can reject other players clicking this NPC
	writeData("mando_way:informant:" .. tostring(oid) .. ":player", playerOid)

	-- Per-player state
	self:writeStr(pPlayer, "foundling.informantId", tostring(oid))
	self:writeInt(pPlayer, "foundling.informantStatic", 0)
	self:writeInt(pPlayer, "foundling.informantCoordX", data.x)
	self:writeInt(pPlayer, "foundling.informantCoordY", data.y)

	if (grantWaypoint) then
		self:grantInformantWaypoint(pPlayer, data)
	end

	local parentId = SceneObject(pInformant):getParentID()
	self:logDiagPlayer(pPlayer, string.format(
		"spawnInformant: dynamic NPC spawned oid=%s planet=%s index=%s parentId=%s coords=(%.1f,%.1f,%.1f) grantWp=%s (converse: same outdoor cell as NPC, within ~6m, clear LoS)",
		tostring(oid), tostring(data.planet), tostring(index), tostring(parentId),
		data.x, data.z, data.y, tostring(grantWaypoint)
	))
	return true
end

-- If Foundling arc is active but the player's private informant OID is missing (restart, death, stale data),
-- spawn a fresh dynamic NPC and re-grant the appropriate waypoint.
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

	-- No live NPC - re-spawn one for this player.
	-- Do not grant a "find informant" waypoint while mid-quota (player should be doing missions).
	local spawned = self:spawnInformant(pPlayer, idx, (counting ~= 1))
	if (spawned) then
		if (counting == 1 and done == 1) then
			self:grantReturnToInformantWaypoint(pPlayer)
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact has been relocated. Quota complete. Check your datapad to turn in."
			)
		elseif (counting == 1 and done == 0) then
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact has been relocated on this world. Finish your quota first."
			)
		else
			CreatureObject(pPlayer):sendSystemMessage(
				"Your Mandalorian contact is available. Check your datapad waypoint."
			)
		end
	else
		self:logDiagPlayer(pPlayer, string.format(
			"ensureFoundlingInformant: spawn failed for planet index %s - player may need GM assist.",
			tostring(idx)
		))
	end
end

-- Trialmaster "What is my status?" / "Mandalorian Way status" and Say-line !foundling !mando (ChatManagerImplementation -> mandoFoundlingStatusRun).
-- Stock client blocks unknown /slash commands; use !foundling or !mando in Say (spatial) so the server receives the line.
function MandoWayOfLife:sendFoundlingStatusReportToPlayer(pPlayer)
	if (pPlayer == nil) then return end
	local creo = CreatureObject(pPlayer)
	if (self:readInt(pPlayer, "foundling.arcComplete") == 1) then
		local ch = self:readInt(pPlayer, "chapter")
		local title = (self.chapterTitles ~= nil and self.chapterTitles[ch]) or "Unknown"
		creo:sendSystemMessage(string.format(
			"[Mandalorian Way] Story chapter: %s (%s). Ranks: 0 Foundling, 1 through 4 Spynet (Initiate through Clanbound).",
			tostring(ch),
			title
		))
		if (self:readInt(pPlayer, "chapter4Complete") == 1) then
			creo:sendSystemMessage(
				"[Mandalorian Way] Clanbound path complete. Return to the Mandalorian Recruiter in the Mos Eisley cantina on Tatooine. They will set your next path when you are ready."
			)
			creo:sendSystemMessage("[Mandalorian Way] Tip: in Say, !foundling or !mando (no slash). Or ask the Trialmaster.")
			self:logDiagPlayer(pPlayer, "sendFoundlingStatusReportToPlayer: arc complete, chapter 4 done.")
			return
		end
		if (not creo:hasSkill("combat_bountyhunter_novice")) then
			creo:sendSystemMessage(
				"[Mandalorian Way] Next: train Bounty Hunter Novice. After that, the Spynet gate opens: five counted terminal bounties, then one private trial per chapter on Corellia."
			)
			creo:sendSystemMessage("[Mandalorian Way] Tip: in Say, !foundling or !mando (no slash). Or ask the Trialmaster.")
			self:logDiagPlayer(pPlayer, "sendFoundlingStatusReportToPlayer: arc complete, no BH novice.")
			return
		end
		creo:sendSystemMessage(self:formatChapterGateOperativeStatusLine(pPlayer))
		local c = self:readInt(pPlayer, "bhTerminalCount")
		creo:sendSystemMessage(string.format("[Mandalorian Way] Spynet terminal count this cycle: %s/5.", tostring(c)))
		creo:sendSystemMessage(
			"[Mandalorian Way] How to advance: finish 5/5 Spynet-counted BH terminal missions, then use the purple waypoint to the Corellia operative, accept the solo private trial (helmet on, not grouped), and kill the mark. "
				.. "Each successful trial raises your chapter by one until Clanbound (4). After a bounty-camp kill, rewards may apply after the camp stands down."
		)
		creo:sendSystemMessage(
			"[Mandalorian Way] Staff: slash /mandoFoundlingAdmin only works on clients whose command_table includes it (custom TRE). Otherwise use the Trialmaster: What is my Mandalorian Way status?"
		)
		creo:sendSystemMessage("[Mandalorian Way] Tip: in Say (spatial), type !foundling or !mando (no slash). /foundling is wrong; the client blocks it before the server.")
		self:logDiagPlayer(pPlayer, "sendFoundlingStatusReportToPlayer: arc complete, spynet status.")
		return
	end
	if (self:readInt(pPlayer, "chapter0Started") ~= 1) then
		creo:sendSystemMessage("[Foundling] You have not started the Foundling arc yet.")
		creo:sendSystemMessage("[Foundling] Train Novice Scout, Novice Marksman, and Novice Medic, then speak to the Mandalorian Recruiter in Mos Eisley cantina.")
		self:logDiagPlayer(pPlayer, "sendFoundlingStatusReportToPlayer: ch0 not started.")
		return
	end

	local idx = self:readInt(pPlayer, "foundling.planetIndex")
	local planetStr = self:readStr(pPlayer, "foundling.currentPlanet")
	if (planetStr == "" and idx >= 1 and idx <= #self.planetData) then
		planetStr = self.planetData[idx].planet
	end
	local counting = self:readInt(pPlayer, "foundling.planetCountingEnabled")
	local done = self:readInt(pPlayer, "foundling.planetDone")
	local completed = self:readInt(pPlayer, "foundling.planetCompleted")
	local target = self:readInt(pPlayer, "foundling.planetTarget")
	local infStr = self:readStr(pPlayer, "foundling.informantId")
	local infOid = tonumber(infStr) or 0
	local alive = (infOid ~= 0 and getSceneObject(infOid) ~= nil)
	local phase = "Travel to your contact and accept the assignment for this world."
	if (counting == 1 and done == 0) then
		phase = string.format("Mission quota in progress: %s / %s missions completed (terminal quota).", tostring(completed), tostring(target))
	elseif (counting == 1 and done == 1) then
		phase = "Quota complete. Return to your contact on this world to turn in."
	end
	creo:sendSystemMessage("[Foundling] Mandalorian Foundling arc status.")
	creo:sendSystemMessage(string.format("[Foundling] Current step: world index %s, planet %s.", tostring(idx), planetStr ~= "" and planetStr or "(unknown)"))
	local here = SceneObject(pPlayer):getZoneName() or ""
	if (planetStr ~= "" and here ~= "" and here ~= planetStr) then
		creo:sendSystemMessage(string.format("[Foundling] You are on %s; your contact is on %s. Travel there for this step.", here, planetStr))
	end
	creo:sendSystemMessage(string.format("[Foundling] %s", phase))
	if (alive) then
		creo:sendSystemMessage(string.format("[Foundling] Your contact NPC is in this zone (id %s). Converse: same cell, within ~6m, clear line of sight.", tostring(infOid)))
	else
		creo:sendSystemMessage("[Foundling] Your contact is not loaded here (wrong planet or needs respawn). Talk to the Recruiter: \"Reset contact\", or relog on the correct world.")
	end
	creo:sendSystemMessage("[Foundling] Tip: in Say (spatial), type !foundling or !mando, not /foundling (slash is client-blocked). Or use the Trialmaster.")
	self:logDiagPlayer(pPlayer, "sendFoundlingStatusReportToPlayer: delivered status lines.")
end

-- Trialmaster "Reset contact" - strips old private informant + waypoints, then same path as login recovery.
function MandoWayOfLife:resyncFoundlingContactAndWaypoints(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "chapter0Started") ~= 1) then return end
	if (self:readInt(pPlayer, "foundling.arcComplete") == 1) then return end
	self:logDiagPlayer(pPlayer, "resyncFoundlingContactAndWaypoints: despawn + ensureFoundlingInformant.")
	self:despawnInformant(pPlayer)
	self:ensureFoundlingInformant(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Recruiter] Contact and waypoint refreshed for your current Foundling world.")
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
		cfg.recruiterWaypointDesc or "Mos Eisley cantina. Speak with the Mandalorian Recruiter.",
		cfg.recruiterWpX, cfg.recruiterWpZ, cfg.recruiterWpY,
		WAYPOINT_YELLOW, true, true, 0
	)
	if (wpId ~= nil) then
		self:writeInt(pPlayer, "foundling.recruiterWaypointId", wpId)
	end
end

-- Two datapad waypoints for the chapter gate: operative (must speak first) + a Corellia BH terminal hub.
-- skipInstructions: true when refreshing waypoints for a player already mid gate (avoid repeating the long system brief).
-- suppressSystemMessages: true = only update datapad waypoints (no \"refreshed\" recruiter line); use after trial / login restore.
-- Returns true if both operative and BH reference waypoints were created.
function MandoWayOfLife:grantChapterGateBriefingWaypoints(pPlayer, skipInstructions, suppressSystemMessages)
	if (pPlayer == nil) then return false end
	local cfg = self.chapterGateBriefingConfig
	if (cfg == nil) then return false end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return false end

	local po = PlayerObject(pGhost)

	self:clearChapterGateTrialPurpleWaypoint(pPlayer)

	local oldOp = self:readInt(pPlayer, "chapterGate.operativeWpId")
	if (oldOp ~= 0) then
		po:removeWaypoint(oldOp, true)
		self:writeInt(pPlayer, "chapterGate.operativeWpId", 0)
	end
	local oldBh = self:readInt(pPlayer, "chapterGate.bhTerminalWpId")
	if (oldBh ~= 0) then
		po:removeWaypoint(oldBh, true)
		self:writeInt(pPlayer, "chapterGate.bhTerminalWpId", 0)
	end

	if (isZoneEnabled(cfg.operativePlanet) == false or isZoneEnabled(cfg.bhRefPlanet) == false) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[Mandalorian Recruiter] Corellia is not available on this server. I cannot place gate waypoints. Ask staff or check the change log for operative coordinates."
		)
		return false
	end

	local opId = po:addWaypoint(
		cfg.operativePlanet,
		cfg.operativeWaypointName or "Mandalorian Operative (Spynet)",
		cfg.operativeWaypointDesc or "Speak here first to open your Spynet count.",
		cfg.operativeX, cfg.operativeZ, cfg.operativeY,
		WAYPOINT_BLUE, true, true, 0
	)
	if (opId ~= nil) then
		self:writeInt(pPlayer, "chapterGate.operativeWpId", opId)
	end

	local bhId = po:addWaypoint(
		cfg.bhRefPlanet,
		cfg.bhRefWaypointName or "BH mission terminals",
		cfg.bhRefWaypointDesc or "Bounty Hunter mission terminals for Spynet contracts.",
		cfg.bhRefX, cfg.bhRefZ, cfg.bhRefY,
		WAYPOINT_YELLOW, true, true, 0
	)
	if (bhId ~= nil) then
		self:writeInt(pPlayer, "chapterGate.bhTerminalWpId", bhId)
	end

	local bothOk = (opId ~= nil and bhId ~= nil)
	if (not bothOk) then
		self:logDiagPlayer(pPlayer, "grantChapterGateBriefingWaypoints: addWaypoint failed (operative or BH pin missing).")
	end

	if (skipInstructions == true) then
		if (suppressSystemMessages ~= true) then
			CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Recruiter] Corellia gate waypoints refreshed on your datapad.")
		end
		self:sendChapterGateOperativeStatusIfRelevant(pPlayer)
		return bothOk
	end

	CreatureObject(pPlayer):sendSystemMessage(
		"[Mandalorian Recruiter] Gate order: (1) On Corellia, talk to the Mandalorian Operative at the blue waypoint and begin the Spynet count. " ..
		"(2) Pull and complete five NPC bounty missions from Bounty Hunter mission terminals only (yellow waypoint: Tyrena guild; any BH terminal works once the count is live). " ..
		"Watch for system: Spynet contracts x/5. (3) At 5/5 and after each trial, a purple waypoint marks the operative for your private trial or the next gate cycle."
	)
	self:sendChapterGateOperativeStatusIfRelevant(pPlayer)
	return bothOk
end

-- Remove purple \"return to operative\" highlight (datapad)
function MandoWayOfLife:clearChapterGateTrialPurpleWaypoint(pPlayer)
	if (pPlayer == nil) then return end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end
	local id = self:readInt(pPlayer, "chapterGate.trialPurpleWpId")
	if (id ~= 0) then
		PlayerObject(pGhost):removeWaypoint(id, true)
		self:writeInt(pPlayer, "chapterGate.trialPurpleWpId", 0)
	end
end

-- Orange datapad pin for the private trial mark (not a BH terminal mission object).
function MandoWayOfLife:clearPrivateContractTargetWaypoint(pPlayer)
	if (pPlayer == nil) then return end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end
	local id = self:readInt(pPlayer, "chapterGate.contractMarkWpId")
	if (id ~= 0) then
		PlayerObject(pGhost):removeWaypoint(id, true)
		self:writeInt(pPlayer, "chapterGate.contractMarkWpId", 0)
	end
end

-- Orange Spynet trial mark on datapad. Caller should clear any previous contract-mark pin first when replacing.
function MandoWayOfLife:grantPrivateContractMarkWaypointAt(pPlayer, planet, spawnX, spawnZ, spawnY)
	if (pPlayer == nil or planet == nil or planet == "") then
		self:logDiag("grantPrivateContractMarkWaypointAt: early return (nil player or empty planet).")
		return
	end
	self:logDiagPlayer(pPlayer, string.format(
		"DEBUG grantPrivateContractMarkWaypointAt: enter planet=%s pos=(%.2f,%.2f,%.2f)",
		tostring(planet),
		spawnX,
		spawnZ,
		spawnY
	))
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		self:logDiagPlayer(pPlayer, "grantPrivateContractMarkWaypointAt FAILED: player ghost nil.")
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Datapad link failed. Relog and try again, or speak to the operative on Corellia."
		)
		return
	end
	local cfg = self.chapterGateBriefingConfig
	local markName = "Spynet contract mark"
	local markDesc = "Private trial: eliminate this mark. Helmet on, solo, no group."
	if (cfg ~= nil) then
		if (cfg.privateContractMarkWaypointName ~= nil and cfg.privateContractMarkWaypointName ~= "") then
			markName = cfg.privateContractMarkWaypointName
		end
		if (cfg.privateContractMarkWaypointDesc ~= nil and cfg.privateContractMarkWaypointDesc ~= "") then
			markDesc = cfg.privateContractMarkWaypointDesc
		end
	end
	local wpId = PlayerObject(pGhost):addWaypoint(
		planet,
		markName,
		markDesc,
		spawnX, spawnZ, spawnY,
		WAYPOINT_ORANGE, true, true, 0
	)
	if (wpId ~= nil and wpId ~= 0) then
		self:writeInt(pPlayer, "chapterGate.contractMarkWpId", wpId)
		self:logDiagPlayer(pPlayer, string.format("DEBUG grantPrivateContractMarkWaypointAt: SUCCESS wpId=%s", tostring(wpId)))
	else
		self:writeInt(pPlayer, "chapterGate.contractMarkWpId", 0)
		self:logDiagPlayer(pPlayer, string.format(
			"grantPrivateContractMarkWaypointAt FAILED: addWaypoint returned invalid id (planet=%s x=%s y=%s).",
			tostring(planet),
			tostring(spawnX),
			tostring(spawnY)
		))
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Datapad waypoint did not register. Rough sector "
				.. tostring(planet)
				.. " ("
				.. string.format("%.0f", spawnX)
				.. ", "
				.. string.format("%.0f", spawnY)
				.. "). Relog or speak to the operative."
		)
	end
end

-- Persist trial spawn sector when the contract NPC is created. getSceneObject(contractTargetId) can be nil on some
-- servers (object not in this process map, unloaded, etc.); refresh then uses this anchor for the orange mark.
function MandoWayOfLife:writePrivateContractSpawnAnchor(pPlayer, planet, x, z, y)
	if (pPlayer == nil) then return end
	self:writeStr(pPlayer, "privateContract.anchorPlanet", tostring(planet))
	self:writeStr(pPlayer, "privateContract.anchorX", string.format("%.6f", x))
	self:writeStr(pPlayer, "privateContract.anchorZ", string.format("%.6f", z))
	self:writeStr(pPlayer, "privateContract.anchorY", string.format("%.6f", y))
end

function MandoWayOfLife:readPrivateContractSpawnAnchor(pPlayer)
	if (pPlayer == nil) then return nil end
	local pl = self:readStr(pPlayer, "privateContract.anchorPlanet")
	if (pl == nil or pl == "") then return nil end
	local xs = self:readStr(pPlayer, "privateContract.anchorX")
	local zs = self:readStr(pPlayer, "privateContract.anchorZ")
	local ys = self:readStr(pPlayer, "privateContract.anchorY")
	local x = tonumber(xs)
	local z = tonumber(zs)
	local y = tonumber(ys)
	if (x == nil or z == nil or y == nil) then return nil end
	return pl, x, z, y
end

function MandoWayOfLife:clearPrivateContractSpawnAnchor(pPlayer)
	if (pPlayer == nil) then return end
	self:writeStr(pPlayer, "privateContract.anchorPlanet", "")
	self:writeStr(pPlayer, "privateContract.anchorX", "")
	self:writeStr(pPlayer, "privateContract.anchorZ", "")
	self:writeStr(pPlayer, "privateContract.anchorY", "")
end

function MandoWayOfLife:hasPrivateContractSpawnAnchor(pPlayer)
	if (pPlayer == nil) then return false end
	return self:readPrivateContractSpawnAnchor(pPlayer) ~= nil
end

-- Trials started before anchor persistence have contractTargetId but no anchor; refresh/reissue could not place a pin.
-- Stamp the same offset used in beginPrivateContract (player X + 200, same Z/Y) from the player's current position.
function MandoWayOfLife:ensurePrivateContractSpawnAnchorForLegacyTrial(pPlayer)
	if (pPlayer == nil) then return end
	if (self:hasPrivateContractSpawnAnchor(pPlayer)) then return end
	local planet = SceneObject(pPlayer):getZoneName()
	if (planet == nil or planet == "") then return end
	local px = SceneObject(pPlayer):getWorldPositionX()
	local pz = SceneObject(pPlayer):getWorldPositionZ()
	local py = SceneObject(pPlayer):getWorldPositionY()
	self:writePrivateContractSpawnAnchor(pPlayer, planet, px + 200, pz, py)
	self:logDiagPlayer(pPlayer, string.format(
		"healPrivateContractAnchor: missing anchor for active trial; stamped (%.2f,%.2f,%.2f) on %s (+200 X vs player, matches beginPrivateContract).",
		px + 200,
		pz,
		py,
		tostring(planet)
	))
end

-- One automatic respawn per trial when stored OID does not resolve (ghost waypoint). Spawns mando_contract_target at anchor.
function MandoWayOfLife:tryRespawnPrivateContractTargetOnce(pPlayer, ap, ax, az, ay)
	if (pPlayer == nil or ap == nil or ap == "") then return nil end
	if (self:readInt(pPlayer, "privateContract.spawnRelinkDone") == 1) then
		self:logSpynetDebug(pPlayer, string.format(
			"tryRespawnPrivateContractTargetOnce: skip (spawnRelinkDone=1) planet=%s anchor=(%.2f,%.2f,%.2f)",
			tostring(ap),
			ax,
			az,
			ay
		))
		return nil
	end
	local pMob = spawnMobile(ap, "mando_contract_target", 0, ax, az, ay, 180, 0)
	if (pMob == nil) then
		self:logDiagPlayer(pPlayer, string.format(
			"tryRespawnPrivateContractTargetOnce FAILED: spawnMobile nil planet=%s pos=(%.2f,%.2f,%.2f)",
			tostring(ap),
			ax,
			az,
			ay
		))
		return nil
	end
	local oid = SceneObject(pMob):getObjectID()
	local sx = SceneObject(pMob):getWorldPositionX()
	local sz = SceneObject(pMob):getWorldPositionZ()
	local sy = SceneObject(pMob):getWorldPositionY()
	local zn = SceneObject(pMob):getZoneName()
	self:writeStr(pPlayer, "contractTargetId", tostring(oid))
	self:writePrivateContractSpawnAnchor(pPlayer, (zn ~= nil and zn ~= "") and zn or ap, sx, sz, sy)
	self:writeInt(pPlayer, "privateContract.spawnRelinkDone", 1)
	self:writeInt(pPlayer, "privateContractTargetResolveMisses", 0)
	self:logDiagPlayer(pPlayer, string.format(
		"tryRespawnPrivateContractTargetOnce OK newOid=%s world=(%.2f,%.2f,%.2f) planet=%s",
		tostring(oid),
		sx,
		sz,
		sy,
		tostring((zn ~= nil and zn ~= "") and zn or ap)
	))
	return pMob
end

-- Try both Lua lookups (same C++ map today; kept for parity with older forks / future splits).
function MandoWayOfLife:resolvePrivateContractTargetById(targetId)
	if (targetId == nil or targetId == 0) then return nil end
	local p = getSceneObject(targetId)
	if (p ~= nil) then return p end
	return getCreatureObject(targetId)
end

-- Horizontal distance uses world X and Y (matches typical ground plane usage in screenplays).
function MandoWayOfLife:isPlayerNearPrivateContractAnchorXY(pPlayer, radiusSq)
	if (pPlayer == nil or radiusSq == nil) then return false end
	local ap, ax, az, ay = self:readPrivateContractSpawnAnchor(pPlayer)
	if (ap == nil) then return false end
	if (SceneObject(pPlayer):getZoneName() ~= ap) then return false end
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - ax
	local dy = py - ay
	return (dx * dx + dy * dy) <= radiusSq
end

-- Mid-trial saves from before bounty-camp Spynet (useBountyCampTheater=0, stale contractTargetId, spawnRelinkDone blocking respawn).
-- Destroys a still-spawned legacy mando_contract_target if it resolves.
function MandoWayOfLife:migrateLegacyPrivateContractToBountyCampTheater(pPlayer)
	if (pPlayer == nil) then return false end
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then return false end
	if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1) then return false end

	self:logDiagPlayer(pPlayer, "migrateLegacyPrivateContractToBountyCampTheater: upgrading legacy trial to bounty camp theater.")
	self:logSpynetDebug(pPlayer, string.format(
		"migrateLegacy: enter spawnRelinkDone=%s useBountyCampTheater=%s",
		tostring(self:readInt(pPlayer, "privateContract.spawnRelinkDone")),
		tostring(self:readInt(pPlayer, "privateContract.useBountyCampTheater"))
	))

	local tid = tonumber(self:readStr(pPlayer, "contractTargetId")) or 0
	if (tid ~= 0) then
		local pLeg = self:resolvePrivateContractTargetById(tid)
		if (pLeg ~= nil and not CreatureObject(pLeg):isDead()) then
			SceneObject(pLeg):destroyObjectFromWorld()
			self:logDiagPlayer(pPlayer, string.format("migrateLegacy: destroyed legacy contract target oid=%s.", tostring(tid)))
		end
	end

	self:writeStr(pPlayer, "contractTargetId", "0")
	self:writeInt(pPlayer, "privateContract.spawnRelinkDone", 0)
	self:clearPrivateContractTargetWaypoint(pPlayer)
	self:writeInt(pPlayer, "privateContract.pendingCampTeardown", 0)
	self:writeInt(pPlayer, "privateContract.pendingTrialFinalize", 0)
	self:writeInt(pPlayer, "privateContract.postTrialChapter", 0)
	self:finishActiveSpynetBountyCampTheater(pPlayer)

	local spawnX = SceneObject(pPlayer):getWorldPositionX()
	local spawnZ = SceneObject(pPlayer):getWorldPositionZ()
	local spawnY = SceneObject(pPlayer):getWorldPositionY()
	local planet = SceneObject(pPlayer):getZoneName()

	local tier = math.min(3, math.max(1, self:getChapter(pPlayer) + 1))
	local campTheaters = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	local T = campTheaters[tier]
	if (T == nil or T.start == nil) then
		self:logDiagPlayer(pPlayer, "migrateLegacy: FAILED bounty camp screenplay global missing.")
		return false
	end
	if (not T:start(pPlayer)) then
		self:logDiagPlayer(pPlayer, string.format("migrateLegacy: FAILED GoToTheater:start tier=%s planet=%s.", tostring(tier), tostring(planet)))
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Could not place the bounty camp. Move to open ground away from cities, then relog or speak to the operative on Corellia."
		)
		return false
	end

	self:writePrivateContractSpawnAnchor(pPlayer, planet, spawnX, spawnZ, spawnY)
	self:writeInt(pPlayer, "privateContract.useBountyCampTheater", 1)
	self:writeInt(pPlayer, "privateContractTargetResolveMisses", 0)
	self:writeInt(pPlayer, "privateContract.fallbackNilStreak", 0)

	self:restoreSpynetBountyCampQuestWaypoint(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage(
		"[Spynet trial] Your trial now uses the new bounty camp. Open your datapad Quest tab and activate the yellow Spynet bounty camp waypoint. Enter that area to load the camp and fight the mark."
	)
	self:logDiagPlayer(pPlayer, string.format("migrateLegacy: OK tier=%s.", tostring(tier)))
	return true
end

-- After relog: re-pin the live contract NPC if the trial is still active.
function MandoWayOfLife:refreshPrivateContractTargetWaypointFromActiveTarget(pPlayer)
	if (pPlayer == nil) then return end
	self:logSpynetDebug(pPlayer, string.format(
		"refreshWaypoint: enter active=%s useCamp=%s contractTargetId=%s spawnRelinkDone=%s zone=%s",
		tostring(self:readInt(pPlayer, "privateContractActive")),
		tostring(self:readInt(pPlayer, "privateContract.useBountyCampTheater")),
		tostring(self:readStr(pPlayer, "contractTargetId")),
		tostring(self:readInt(pPlayer, "privateContract.spawnRelinkDone")),
		tostring(SceneObject(pPlayer):getZoneName())
	))
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then
		self:logDiagPlayer(pPlayer, "DEBUG refreshPrivateContractTargetWaypoint: skip (privateContractActive ~= 1).")
		return
	end
	if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1) then
		self:logDiagPlayer(pPlayer, "DEBUG refreshPrivateContractTargetWaypoint: bounty camp mode (yellow quest waypoint on datapad).")
		self:restoreSpynetBountyCampQuestWaypoint(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Open your datapad Quest tab (not only Waypoints). Activate the yellow Spynet bounty camp task waypoint, travel there, and enter the radius to load the camp."
		)
		return
	end
	local targetId = tonumber(self:readStr(pPlayer, "contractTargetId")) or 0
	if (targetId == 0) then
		self:logDiagPlayer(pPlayer, "DEBUG refreshPrivateContractTargetWaypoint: skip (contractTargetId 0).")
		return
	end
	self:ensurePrivateContractSpawnAnchorForLegacyTrial(pPlayer)
	local pTarget = self:resolvePrivateContractTargetById(targetId)
	if (pTarget == nil) then
		local ap, ax, az, ay = self:readPrivateContractSpawnAnchor(pPlayer)
		if (ap ~= nil) then
			self:clearPrivateContractTargetWaypoint(pPlayer)
			local pNewMob = self:tryRespawnPrivateContractTargetOnce(pPlayer, ap, ax, az, ay)
			if (pNewMob ~= nil) then
				local sx = SceneObject(pNewMob):getWorldPositionX()
				local sz = SceneObject(pNewMob):getWorldPositionZ()
				local sy = SceneObject(pNewMob):getWorldPositionY()
				local zn = SceneObject(pNewMob):getZoneName() or ap
				self:grantPrivateContractMarkWaypointAt(pPlayer, zn, sx, sz, sy)
				CreatureObject(pPlayer):sendSystemMessage(
					"[Spynet trial] Your contract mark was placed in the world at the anchor. Look for Private Contract Target near the orange waypoint."
				)
				self:logDiagPlayer(pPlayer, string.format(
					"refreshPrivateContractTargetWaypoint: RESPAWN + waypoint (was nil targetId=%s) new wpId=%s",
					tostring(targetId),
					tostring(self:readInt(pPlayer, "chapterGate.contractMarkWpId"))
				))
				return
			end
			if (self:migrateLegacyPrivateContractToBountyCampTheater(pPlayer)) then
				self:logDiagPlayer(pPlayer, "refreshPrivateContractTargetWaypoint: migrated legacy trial to bounty camp after respawn failed.")
				return
			end
			self:grantPrivateContractMarkWaypointAt(pPlayer, ap, ax, az, ay)
			if (self:readInt(pPlayer, "privateContract.spawnRelinkDone") == 1) then
				CreatureObject(pPlayer):sendSystemMessage(
					"[Spynet trial] Waypoint refreshed. A world relink already ran this trial. If you still see no mark, restart the trial from the operative."
				)
			else
				CreatureObject(pPlayer):sendSystemMessage(
					"[Spynet trial] Could not spawn the contract mark here. Move to open ground or restart the trial from the operative."
				)
			end
			self:logDiagPlayer(pPlayer, string.format(
				"refreshPrivateContractTargetWaypoint: ANCHOR WAYPOINT ONLY (resolve nil, spawn failed) oldTargetId=%s planet=%s pos=(%.2f,%.2f,%.2f) wpId=%s",
				tostring(targetId),
				tostring(ap),
				ax,
				az,
				ay,
				tostring(self:readInt(pPlayer, "chapterGate.contractMarkWpId"))
			))
			return
		end
		self:logDiagPlayer(pPlayer, string.format(
			"DEBUG refreshPrivateContractTargetWaypoint: skip (resolve nil, no anchor) targetId=%s",
			tostring(targetId)
		))
		return
	end
	if (CreatureObject(pTarget):isDead()) then
		self:logDiagPlayer(pPlayer, string.format(
			"refreshPrivateContractTargetWaypoint: target dead -> completePrivateContract (targetId=%s)",
			tostring(targetId)
		))
		self:completePrivateContract(pPlayer)
		return
	end
	local planet = SceneObject(pTarget):getZoneName()
	if (planet == nil or planet == "") then
		self:logDiagPlayer(pPlayer, "DEBUG refreshPrivateContractTargetWaypoint: skip (target zone name empty).")
		return
	end
	self:clearPrivateContractTargetWaypoint(pPlayer)
	local sx = SceneObject(pTarget):getWorldPositionX()
	local sz = SceneObject(pTarget):getWorldPositionZ()
	local sy = SceneObject(pTarget):getWorldPositionY()
	self:grantPrivateContractMarkWaypointAt(pPlayer, planet, sx, sz, sy)
	self:logDiagPlayer(pPlayer, string.format(
		"DEBUG refreshPrivateContractTargetWaypoint: refreshed from live target oid=%s storedWpId=%s",
		tostring(targetId),
		tostring(self:readInt(pPlayer, "chapterGate.contractMarkWpId"))
	))
end

-- True for our custom Spynet disk IFF or a tagged mission_datadisk fallback (custom name must match).
function MandoWayOfLife.isSpynetContractDiskObject(pObj)
	if (pObj == nil) then return false end
	local path = SceneObject(pObj):getTemplateObjectPath()
	if (path == MandoWayOfLife.SPYNET_CONTRACT_WAYPOINT_DISK_IFF) then return true end
	if (path == MandoWayOfLife.SPYNET_CONTRACT_DISK_FALLBACK_IFF) then
		local ok, nm = pcall(function()
			return SceneObject(pObj):getCustomObjectName()
		end)
		if (not ok or nm == nil) then return false end
		return tostring(nm) == MandoWayOfLife.SPYNET_CONTRACT_DISK_DISPLAY_NAME
	end
	return false
end

-- Remove all Spynet coordinate disks from a container tree (inventory bags, etc.).
function MandoWayOfLife:removeSpynetContractWaypointDisksFromContainer(pContainer)
	if (pContainer == nil) then return end
	local cont = SceneObject(pContainer)
	local n = cont:getContainerObjectsSize()
	for i = n - 1, 0, -1 do
		local pObj = cont:getContainerObject(i)
		if (pObj ~= nil) then
			local so = SceneObject(pObj)
			if (so:getContainerObjectsSize() > 0) then
				self:removeSpynetContractWaypointDisksFromContainer(pObj)
			end
			if (MandoWayOfLife.isSpynetContractDiskObject(pObj)) then
				so:destroyObjectFromWorld(true)
				so:destroyObjectFromDatabase(true)
			end
		end
	end
end

function MandoWayOfLife:removeSpynetContractWaypointDisksFromPlayer(pPlayer)
	if (pPlayer == nil) then return end
	local pInv = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInv ~= nil) then
		self:removeSpynetContractWaypointDisksFromContainer(pInv)
	end
	local pDatapad = SceneObject(pPlayer):getSlottedObject("datapad")
	if (pDatapad ~= nil) then
		self:removeSpynetContractWaypointDisksFromContainer(pDatapad)
	end
end

-- Operative conversation: waypoint / trial reminder (no inventory disk).
function MandoWayOfLife:refreshSpynetTrialSupportFromOperative(pPlayer)
	if (pPlayer == nil) then return end
	self:logDiagPlayer(pPlayer, string.format(
		"DEBUG refreshSpynetTrialSupport: enter privateContractActive=%s useBountyCampTheater=%s contractTargetId=%s",
		tostring(self:readInt(pPlayer, "privateContractActive")),
		tostring(self:readInt(pPlayer, "privateContract.useBountyCampTheater")),
		tostring(self:readStr(pPlayer, "contractTargetId"))
	))
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then
		self:logDiagPlayer(pPlayer, "DEBUG refreshSpynetTrialSupport: blocked (no active trial).")
		CreatureObject(pPlayer):sendSystemMessage("You have no active Spynet trial.")
		return
	end
	if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 0) then
		if (self:migrateLegacyPrivateContractToBountyCampTheater(pPlayer)) then
			self:logDiagPlayer(pPlayer, "DEBUG refreshSpynetTrialSupport: legacy trial migrated to bounty camp.")
			return
		end
	end
	self:refreshPrivateContractTargetWaypointFromActiveTarget(pPlayer)
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then
		self:logDiagPlayer(pPlayer, "DEBUG refreshSpynetTrialSupport: trial completed during refresh.")
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] The contract is cleared. Check your rank and the operative for your next step."
		)
		return
	end
	-- Operative-only: if Quest-tab pin still missing (task flag desync, etc.), rebuild the camp.
	if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1) then
		if (not self:restoreSpynetBountyCampQuestWaypoint(pPlayer)) then
			self:logDiagPlayer(pPlayer, "refreshSpynetTrialSupport: restore failed; rebuilding bounty camp.")
			if (self:restartSpynetBountyCampTrialFromOperative(pPlayer)) then
				CreatureObject(pPlayer):sendSystemMessage(
					"[Spynet trial] Your bounty camp was rebuilt. Open your datapad Quest tab and activate the new yellow Spynet bounty camp waypoint."
				)
			end
		end
	end
	self:logDiagPlayer(pPlayer, "DEBUG refreshSpynetTrialSupport: OK (reminder sent).")
end

-- Blue operative waypoint when the player is mid Spynet count (not 5/5 trial-ready) and has no operative pin
function MandoWayOfLife:ensureChapterGateOperativeBlueWaypoint(pPlayer)
	if (pPlayer == nil) then return end
	local cfg = self.chapterGateBriefingConfig
	if (cfg == nil) then return end
	if (isZoneEnabled(cfg.operativePlanet) == false) then return end
	if (self:readInt(pPlayer, "chapterGate.operativeWpId") ~= 0) then return end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end
	local opId = PlayerObject(pGhost):addWaypoint(
		cfg.operativePlanet,
		cfg.operativeWaypointName or "Mandalorian Operative (Spynet)",
		cfg.operativeWaypointDesc or "Speak here first to open your Spynet count.",
		cfg.operativeX, cfg.operativeZ, cfg.operativeY,
		WAYPOINT_BLUE, true, true, 0
	)
	if (opId ~= nil) then
		self:writeInt(pPlayer, "chapterGate.operativeWpId", opId)
	end
end

-- Purple pin at current briefing coords (fixes stale blue after NPC moves); replaces blue operative pin only. Returns true if waypoint created.
function MandoWayOfLife:grantPurpleOperativeReturnWaypoint(pPlayer)
	if (pPlayer == nil) then return false end
	local cfg = self.chapterGateBriefingConfig
	if (cfg == nil) then return false end
	if (isZoneEnabled(cfg.operativePlanet) == false) then return false end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return false end
	local po = PlayerObject(pGhost)

	self:clearChapterGateTrialPurpleWaypoint(pPlayer)

	local oldOp = self:readInt(pPlayer, "chapterGate.operativeWpId")
	if (oldOp ~= 0) then
		po:removeWaypoint(oldOp, true)
		self:writeInt(pPlayer, "chapterGate.operativeWpId", 0)
	end

	local name = cfg.trialReturnWaypointName or "Mandalorian Operative (private trial)"
	local desc = cfg.trialReturnWaypointDesc or "Return here for your private trial or the next Spynet gate."
	local pid = po:addWaypoint(
		cfg.operativePlanet,
		name,
		desc,
		cfg.operativeX, cfg.operativeZ, cfg.operativeY,
		WAYPOINT_PURPLE, true, true, 0
	)
	if (pid ~= nil) then
		self:writeInt(pPlayer, "chapterGate.trialPurpleWpId", pid)
		self:logDiagPlayer(pPlayer, "grantPurpleOperativeReturnWaypoint OK.")
		CreatureObject(pPlayer):sendSystemMessage("[Mandalorian Way of Life] Purple waypoint: Mandalorian Operative on Corellia (datapad).")
		return true
	end
	self:logDiagPlayer(pPlayer, "grantPurpleOperativeReturnWaypoint FAILED: addWaypoint returned nil.")
	return false
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
		self:sendChapterGateOperativeStatusIfRelevant(pPlayer)
		if (self:readInt(pPlayer, "privateContractActive") == 1) then
			if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 0) then
				if (not self:migrateLegacyPrivateContractToBountyCampTheater(pPlayer)) then
					self:refreshPrivateContractTargetWaypointFromActiveTarget(pPlayer)
				end
			else
				self:refreshPrivateContractTargetWaypointFromActiveTarget(pPlayer)
			end
		end
		if (self:readInt(pPlayer, "needsCustomContract") == 1) then
			self:grantChapterGateBriefingWaypoints(pPlayer, true, true)
			self:grantPurpleOperativeReturnWaypoint(pPlayer)
		end
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

	-- Re-spawn informant if missing; handles zone restarts, NPC death, stale OIDs.
	-- Grants the correct waypoint type based on counting/done state.
	self:ensureFoundlingInformant(pPlayer)

	-- Resume quota-completion poll if mid-count
	local counting = self:readInt(pPlayer, "foundling.planetCountingEnabled")
	local done = self:readInt(pPlayer, "foundling.planetDone")
	if (counting == 1 and done == 0) then
		local playerId = SceneObject(pPlayer):getObjectID()
		createEvent(self.PLANET_DONE_POLL_MS, self.screenplayName, "checkPlanetDoneEvent", pPlayer, tostring(playerId))
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
		"Assignment accepted. Mission terminal jobs on this planet count toward your quota (not bounty board contracts). Each completion shows your quota and a full planet status list (Done / In progress / Pending)."
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
	pCreature:sendSystemMessage("Foundling arc: planet status:")
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
				status = "In progress (quota met; return to your contact)"
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
		-- Stop polling - player now needs to walk back to informant
	else
		-- Quota not yet met - reschedule
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

	self:grantChapterRankTitle(pPlayer, 0)
	self:tryAwardChapterBadge(pPlayer, 0)
	CreatureObject(pPlayer):sendSystemMessage(
		"You have proven yourself across the galaxy. The Foundling Helmet is yours. Wear it only if you can live up to it."
	)
end

-- ============================================================
-- CHAPTERS 1-4: INITIATE → CLANBOUND GATE CYCLE
-- ============================================================

-- Reminder context: Foundling arc done, Novice BH, still climbing toward Clanbound (Ch4+ gate).
function MandoWayOfLife:inChapterGateReminderContext(pPlayer)
	if (pPlayer == nil) then return false end
	if (not self:isArcComplete(pPlayer)) then return false end
	if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then return false end
	if (self:readInt(pPlayer, "chapter4Complete") == 1) then return false end
	return true
end

-- True after the operative has opened the Spynet count, or trial is in progress / unlocked.
function MandoWayOfLife:getChapterGateOperativeVisitDone(pPlayer)
	if (pPlayer == nil) then return false end
	if (self:readInt(pPlayer, "countingEnabled") == 1) then return true end
	if (self:readInt(pPlayer, "needsCustomContract") == 1) then return true end
	if (self:readInt(pPlayer, "privateContractActive") == 1) then return true end
	return false
end

function MandoWayOfLife:formatChapterGateOperativeStatusLine(pPlayer)
	if (not self:getChapterGateOperativeVisitDone(pPlayer)) then
		return 'Spynet gate, Phase 0: Mandalorian Operative (Corellia) not started. Visit the blue waypoint and choose "Begin the count" before terminal bounties track toward 5/5.'
	end
	if (self:readInt(pPlayer, "privateContractActive") == 1) then
		if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1) then
			return "Spynet gate, Phase 3: Private trial active. Use the yellow Quest tab waypoint to the bounty camp (not the purple operative pin)."
		end
		return "Spynet gate, Phase 3: Private trial active. Complete your datapad objective."
	end
	if (self:readInt(pPlayer, "needsCustomContract") == 1) then
		return "Spynet gate, Phase 2: Five terminal bounties done. Use the purple waypoint to return to the Mandalorian Operative and accept the private trial."
	end
	return "Spynet gate, Phase 1: Clear five Spynet-counted NPC bounties from BH terminals. Operative path is open; after 5/5, the purple waypoint brings you back for the trial."
end

-- Login / recruiter brief / operative nudge
function MandoWayOfLife:sendChapterGateOperativeStatusIfRelevant(pPlayer)
	if (not self:inChapterGateReminderContext(pPlayer)) then return end
	CreatureObject(pPlayer):sendSystemMessage(self:formatChapterGateOperativeStatusLine(pPlayer))
end

-- Optional contract count (from C++ after increment, or nil to read screenplay).
function MandoWayOfLife:sendChapterGateProgressFooter(pPlayer, contractCountOrNil)
	if (not self:inChapterGateReminderContext(pPlayer)) then return end
	local c = contractCountOrNil
	if (c == nil) then
		c = self:readInt(pPlayer, "bhTerminalCount")
	end
	if (not self:getChapterGateOperativeVisitDone(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage(
			"Spynet gate, Phase 0: Meet the operative first. Open your Spynet count on Corellia (blue waypoint, Begin the count). Spynet contracts stay at 0/5 until you do."
		)
		return
	end

	local priv = self:readInt(pPlayer, "privateContractActive") == 1
	local needTrial = self:readInt(pPlayer, "needsCustomContract") == 1
	local useCamp = self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1

	if (priv) then
		if (useCamp) then
			CreatureObject(pPlayer):sendSystemMessage(
				"Spynet gate, Phase 3: Private trial (bounty camp). Terminal Spynet count is complete (5/5). "
					.. "Use the yellow pin under your datapad Quest tab to reach the camp. The purple pin was only to return here and accept the trial."
			)
		else
			CreatureObject(pPlayer):sendSystemMessage(
				"Spynet gate, Phase 3: Private trial in progress. Finish the objective on your datapad."
			)
		end
		return
	end

	if (needTrial) then
		CreatureObject(pPlayer):sendSystemMessage(
			"Spynet gate, Phase 2: Accept the private trial. Terminal Spynet count is complete (5/5). "
				.. "Follow the purple Mandalorian Operative waypoint to Corellia, talk to the contact, and begin the trial."
		)
		return
	end

	-- Phase 1: counting terminal bounties toward 5/5
	local tail = "At 5/5 you get a purple waypoint to return here for Phase 2."
	CreatureObject(pPlayer):sendSystemMessage(
		"Spynet gate, Phase 1: Terminal bounties. Mandalorian Operative: 1/1 | Spynet contracts: " .. tostring(c) .. "/5 | " .. tail
	)
end

-- Called from C++ after each counted Spynet bounty completion (args: player, new contract count).
function MandoWayOfLife.sendChapterGateProgressReminder(pPlayer, countFromCpp)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end
	local ok, err = pcall(function()
		local c = countFromCpp
		if (type(c) ~= "number") then
			c = tonumber(countFromCpp)
		end
		if (c == nil) then
			c = MandoWayOfLife:readInt(pPlayer, "bhTerminalCount")
		end
		MandoWayOfLife:sendChapterGateProgressFooter(pPlayer, c)
	end)
	if (not ok) then
		MandoWayOfLife:logDiagPlayer(pPlayer, "sendChapterGateProgressReminder pcall failed: " .. tostring(err))
	end
end

-- Returns true if the player meets the BH specialization requirement to open the Spynet gate
-- for nextChapter. Called at gate start so the skill must be trained BEFORE counting begins.
-- Skill IDs from terminal_character_builder.lua:
--   Ch1 Pistol  = combat_bountyhunter_droidresponse_04  (Bounty Pistol Specialization IV)
--   Ch2 Carbine = combat_bountyhunter_droidcontrol_04   (Bounty Carbine Specialization IV)
--   Ch3 LLC     = combat_bountyhunter_support_04        (Light Lightning Cannon Specialization IV)
--   Ch4 Master  = combat_bountyhunter_investigation_04 + combat_bountyhunter_master
function MandoWayOfLife:meetsChapterSkillGate(pPlayer, nextChapter)
	if (pPlayer == nil) then return false end
	local creo = CreatureObject(pPlayer)
	if (nextChapter == 1) then
		return creo:hasSkill("combat_bountyhunter_droidresponse_04")
	elseif (nextChapter == 2) then
		return creo:hasSkill("combat_bountyhunter_droidcontrol_04")
	elseif (nextChapter == 3) then
		return creo:hasSkill("combat_bountyhunter_support_04")
	elseif (nextChapter == 4) then
		return creo:hasSkill("combat_bountyhunter_investigation_04")
			and creo:hasSkill("combat_bountyhunter_master")
	end
	return true
end

-- Returns a player-facing message explaining what skill is required and how to get it.
function MandoWayOfLife:chapterSkillGateBlockMessage(nextChapter)
	if (nextChapter == 1) then
		return "[Mandalorian Way] Gate blocked: Initiate requires Bounty Pistol Specialization IV. "
			.. "Equip a pistol and train all four boxes of the Bounty Pistol column at a Bounty Hunter trainer."
	elseif (nextChapter == 2) then
		return "[Mandalorian Way] Gate blocked: Hunter requires Bounty Carbine Specialization IV. "
			.. "Equip a carbine and train all four boxes of the Bounty Carbine column at a Bounty Hunter trainer."
	elseif (nextChapter == 3) then
		return "[Mandalorian Way] Gate blocked: Verd'ika requires Light Lightning Cannon Specialization IV. "
			.. "Equip an LLC and train all four boxes of the Light Lightning Cannon column at a Bounty Hunter trainer."
	elseif (nextChapter == 4) then
		return "[Mandalorian Way] Gate blocked: Clanbound requires Investigation IV and Master Bounty Hunter. "
			.. "Complete all four Investigation boxes and the Master skill at a Bounty Hunter trainer."
	end
	return "[Mandalorian Way] You do not yet meet the skill requirements for this gate. Check with the Bounty Hunter trainer."
end

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
			"No helm. No chain code. No work."
		)
		return
	end

	-- Already gating
	if (self:readInt(pPlayer, "countingEnabled") == 1) then
		self:logDiagPlayer(pPlayer, "startChapterGate skipped: gate cycle already in progress.")
		return
	end

	-- Chapter skill gate: each chapter requires a specific BH specialization column maxed
	-- before the Spynet count opens. nextCh is the chapter the player would advance TO.
	local nextCh = ch + 1
	if (not self:meetsChapterSkillGate(pPlayer, nextCh)) then
		self:logDiagPlayer(pPlayer, string.format(
			"startChapterGate blocked: skill gate for chapter %s not met.", tostring(nextCh)
		))
		CreatureObject(pPlayer):sendSystemMessage(self:chapterSkillGateBlockMessage(nextCh))
		return
	end

	-- Reset BH terminal counter for this gate cycle
	self:writeInt(pPlayer, "bhTerminalCount", 0)
	self:writeInt(pPlayer, "countingEnabled", 1)    -- C++ reads this
	self:writeInt(pPlayer, "needsCustomContract", 0)

	self:clearChapterGateTrialPurpleWaypoint(pPlayer)
	self:ensureChapterGateOperativeBlueWaypoint(pPlayer)

	self:logDiagPlayer(pPlayer, string.format(
		"startChapterGate OK: chapter=%s BH terminal gate started (0/5).",
		tostring(ch)
	))
	CreatureObject(pPlayer):sendSystemMessage(
		"Spynet contracts: 0/5. Finish five NPC mark bounties (Bounty Hunter mission terminals) while this count is open. " ..
		"If you use Choose Bounty Contract Tier on the terminal (Easy / Hard), it only changes which contracts are offered; it does not change this count. " ..
		"Missions already on your datapad count too, as long as they are NPC targets, not player bounties. Watch for Spynet contracts x/5 on each completion."
	)
	self:sendChapterGateProgressFooter(pPlayer, 0)
end

-- Apply the same state transition as gateProgressEvent when 5/5 is already stored but Lua flags lag.
-- C++ sets bhTerminalCount immediately on the 5th completion; gateProgressEvent only runs every 15s, so
-- players can talk to the operative while countingEnabled is still 1 and needsCustomContract still 0 - the
-- convo then shows gate_in_progress ("keep clearing bounties") until the poll fires. Call this from the
-- operative handler (and anywhere else that needs consistent gate UI) before branching on those flags.
function MandoWayOfLife:unlockPrivateTrialGateIfEligible(pPlayer)
	if (pPlayer == nil) then return false end
	if (self:readInt(pPlayer, "needsCustomContract") == 1) then return false end
	if (self:readInt(pPlayer, "bhTerminalCount") < 5) then return false end
	if (self:readInt(pPlayer, "chapter4Complete") == 1) then return false end
	if (self:readInt(pPlayer, "privateContractActive") == 1) then return false end

	self:writeInt(pPlayer, "countingEnabled", 0)
	self:writeInt(pPlayer, "needsCustomContract", 1)
	self:logDiagPlayer(pPlayer, "unlockPrivateTrialGateIfEligible: 5/5 synced (convo or recovery), trial gate open.")
	self:grantPurpleOperativeReturnWaypoint(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage(
		"Five Spynet contracts confirmed. Return to the Mandalorian Operative on Corellia. Follow the purple datapad waypoint for the private trial."
	)
	self:sendChapterGateProgressFooter(pPlayer, 5)
	return true
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
		if (not self:unlockPrivateTrialGateIfEligible(player)) then
			local playerId = SceneObject(player):getObjectID()
			createEvent(15000, self.screenplayName, "gateProgressEvent", player, tostring(playerId))
		end
	else
		local playerId = SceneObject(player):getObjectID()
		createEvent(15000, self.screenplayName, "gateProgressEvent", player, tostring(playerId))
	end
end

-- ============================================================
-- PRIVATE CONTRACTS: SOLO ENFORCEMENT
-- ============================================================

-- Tear down an active Spynet bounty camp GoToTheater if one is running (fail / reset / restart trial).
-- Finishes every chapter camp that still has :taskStarted: set (avoids stale flags blocking a new :start).
function MandoWayOfLife:finishActiveSpynetBountyCampTheater(pPlayer)
	if (pPlayer == nil) then return end
	local camps = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	local any = false
	for i = 1, #camps, 1 do
		local T = camps[i]
		if (T ~= nil and T.hasTaskStarted ~= nil and T:hasTaskStarted(pPlayer)) then
			self:logSpynetDebug(pPlayer, string.format("finishActiveSpynetBountyCampTheater: calling finish taskName=%s", tostring(T.taskName)))
			T:finish(pPlayer)
			any = true
		end
	end
	if (not any) then
		self:logSpynetDebug(pPlayer, "finishActiveSpynetBountyCampTheater: no BellumBountyCampChapter* task started")
	end
end

-- Which GoToTheater instance (if any) is active for this player.
function MandoWayOfLife:getActiveSpynetBountyCampTheater(pPlayer)
	if (pPlayer == nil) then return nil end
	local camps = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	for i = 1, #camps, 1 do
		local T = camps[i]
		if (T ~= nil and T.hasTaskStarted ~= nil and T:hasTaskStarted(pPlayer)) then
			return T
		end
	end
	return nil
end

-- If :taskStarted: desynced but theaterID data + world object still exist, recover the GoToTheater table.
function MandoWayOfLife:resolveSpynetBountyCampTheaterFromTheaterId(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return nil end
	local camps = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	local pid = SceneObject(pPlayer):getObjectID()
	for i = 1, #camps, 1 do
		local T = camps[i]
		if (T ~= nil and T.taskName ~= nil and T.taskName ~= "") then
			local tid = tonumber(readData(pid .. T.taskName .. "theaterID")) or 0
			if (tid ~= 0) then
				local pTh = getSceneObject(tid)
				if (pTh ~= nil) then
					return T
				end
			end
		end
	end
	return nil
end

-- Tear down all bounty-camp GoToTheater world state for this player (direct taskFinish; clears orphan theaters when Task flags are wrong).
function MandoWayOfLife:forceTeardownSpynetBountyCampTheaters(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end
	local camps = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	for i = 1, #camps, 1 do
		local T = camps[i]
		if (T ~= nil and T.taskFinish ~= nil) then
			T:taskFinish(pPlayer)
		end
	end
	local pid = SceneObject(pPlayer):getObjectID()
	for i = 1, #camps, 1 do
		local T = camps[i]
		if (T ~= nil and T.taskName ~= nil) then
			deleteData(pid .. ":taskStarted:" .. T.taskName)
		end
	end
	self:logDiagPlayer(pPlayer, "forceTeardownSpynetBountyCampTheaters: ran taskFinish x3 + cleared :taskStarted: flags.")
end

-- Full camp rebuild: use at operative when waypoint restore fails (stuck trial, lost task flag, missing theater).
function MandoWayOfLife:restartSpynetBountyCampTrialFromOperative(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return false end
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then return false end
	if (self:readInt(pPlayer, "privateContract.useBountyCampTheater") ~= 1) then return false end
	if (not self:hasFoundlingHelmet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("[Spynet trial] Wear your Foundling helmet, then ask again.")
		return false
	end
	if (CreatureObject(pPlayer):isGrouped()) then
		CreatureObject(pPlayer):sendSystemMessage("[Spynet trial] Leave your group before I rebuild the camp.")
		return false
	end
	self:logDiagPlayer(pPlayer, "restartSpynetBountyCampTrialFromOperative: force teardown + beginPrivateContract.")
	self:forceTeardownSpynetBountyCampTheaters(pPlayer)
	local ok = self:beginPrivateContract(pPlayer)
	if (not ok) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Rebuild failed. Stand on open ground away from cities and walls on a surface planet, then open this conversation again."
		)
	end
	return ok
end

-- Re-add the yellow Quest-tab waypoint from the spawned theater anchor (login / UI loss / failed first addWaypoint).
function MandoWayOfLife:restoreSpynetBountyCampQuestWaypoint(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return false end
	local T = self:getActiveSpynetBountyCampTheater(pPlayer)
	if (T == nil) then
		T = self:resolveSpynetBountyCampTheaterFromTheaterId(pPlayer)
	end
	if (T == nil or T.getTheaterObject == nil) then
		return false
	end
	local pTh = T:getTheaterObject(pPlayer)
	if (pTh == nil) then
		self:logDiagPlayer(pPlayer, "restoreSpynetBountyCampQuestWaypoint: theater object nil (task started but no theaterID?).")
		return false
	end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return false
	end
	local zoneName = SceneObject(pTh):getZoneName()
	local x = SceneObject(pTh):getWorldPositionX()
	local y = SceneObject(pTh):getWorldPositionY()
	local desc = T.waypointDescription or "Spynet bounty camp"
	PlayerObject(pGhost):removeWaypointBySpecialType(WAYPOINTQUESTTASK)
	local wpId = PlayerObject(pGhost):addWaypoint(zoneName, desc, "", x, 0, y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)
	if (wpId == nil) then
		self:logDiagPlayer(pPlayer, "restoreSpynetBountyCampQuestWaypoint FAILED: addWaypoint returned nil.")
		return false
	end
	self:logDiagPlayer(pPlayer, string.format("restoreSpynetBountyCampQuestWaypoint OK task=%s zone=%s", tostring(T.taskName), tostring(zoneName)))
	return true
end

-- Scheduled from completePrivateContract when the trial used the bounty camp; tears down GoToTheater after a short delay.
function MandoWayOfLife:delayedFinishSpynetBountyCampTheater(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end
	if (player == nil or SceneObject(player) == nil) then
		return
	end
	if (self:readInt(player, "privateContract.pendingCampTeardown") ~= 1) then
		self:logSpynetDebug(player, "delayedFinishSpynetBountyCampTheater: skip (no pending flag or superseded by new trial / fail / reset)")
		return
	end
	self:writeInt(player, "privateContract.pendingCampTeardown", 0)
	self:logSpynetDebug(player, "delayedFinishSpynetBountyCampTheater: running finishActiveSpynetBountyCampTheater")
	self:finishActiveSpynetBountyCampTheater(player)

	if (self:readInt(player, "privateContract.pendingTrialFinalize") == 1) then
		self:writeInt(player, "privateContract.pendingTrialFinalize", 0)
		local chNew = self:readInt(player, "privateContract.postTrialChapter")
		self:writeInt(player, "privateContract.postTrialChapter", 0)
		if (chNew >= 1) then
			self:applyChapterAdvanceAfterTrial(player, chNew)
		else
			self:logDiagPlayer(player, "delayedFinishSpynetBountyCampTheater: pendingTrialFinalize set but postTrialChapter invalid; skipped advance.")
		end
	end
end

-- Called from operative conversation when private contract is accepted
-- Returns true if player may proceed, false if they should be blocked
function MandoWayOfLife:beginPrivateContract(pPlayer)
	if (pPlayer == nil) then return false end
	if (self:readInt(pPlayer, "privateContract.pendingTrialFinalize") == 1) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Your last trial is still closing out. Wait until the camp finishes standing down and the Guild records your chapter before accepting another private contract."
		)
		return false
	end
	self:writeInt(pPlayer, "privateContract.pendingCampTeardown", 0)
	self:writeInt(pPlayer, "privateContract.pendingTrialFinalize", 0)
	self:writeInt(pPlayer, "privateContract.postTrialChapter", 0)
	self:logDiagPlayer(pPlayer, string.format(
		"DEBUG beginPrivateContract: enter needsCustomContract=%s countingEnabled=%s privateContractActive=%s",
		tostring(self:readInt(pPlayer, "needsCustomContract")),
		tostring(self:readInt(pPlayer, "countingEnabled")),
		tostring(self:readInt(pPlayer, "privateContractActive"))
	))

	-- Helmet equipped check
	if (not self:hasFoundlingHelmet(pPlayer)) then
		self:logDiagPlayer(pPlayer, "beginPrivateContract blocked: Foundling helmet not equipped.")
		CreatureObject(pPlayer):sendSystemMessage("No helm. No chain code. No work.")
		return false
	end

	-- Solo check at accept
	if (CreatureObject(pPlayer):isGrouped()) then
		self:logDiagPlayer(pPlayer, "beginPrivateContract blocked: player is grouped.")
		CreatureObject(pPlayer):sendSystemMessage("You must face this trial alone.")
		return false
	end

	local spawnX = SceneObject(pPlayer):getWorldPositionX()
	local spawnZ = SceneObject(pPlayer):getWorldPositionZ()
	local spawnY = SceneObject(pPlayer):getWorldPositionY()
	local planet = SceneObject(pPlayer):getZoneName()

	-- Mellichae-style bounty camp (GoToTheater): yellow quest waypoint; camp spawns when you enter the area.
	self:finishActiveSpynetBountyCampTheater(pPlayer)
	local tier = math.min(3, math.max(1, self:getChapter(pPlayer) + 1))
	local campTheaters = {
		BellumBountyCampChapter1Theater,
		BellumBountyCampChapter2Theater,
		BellumBountyCampChapter3Theater,
	}
	local T = campTheaters[tier]
	self:logSpynetDebug(pPlayer, string.format(
		"beginPrivateContract: pre-start tier=%s chapter=%s acceptAt=(%.1f,%.1f,%.1f) zone=%s taskName=%s minDist=%s maxDist=%s",
		tostring(tier),
		tostring(self:getChapter(pPlayer)),
		spawnX,
		spawnZ,
		spawnY,
		tostring(planet),
		(T ~= nil) and tostring(T.taskName) or "nil",
		(T ~= nil) and tostring(T.minimumDistance) or "?",
		(T ~= nil) and tostring(T.maximumDistance) or "?"
	))
	if (T == nil or T.start == nil) then
		self:logDiagPlayer(pPlayer, "beginPrivateContract FAILED: bounty camp screenplay global missing.")
		CreatureObject(pPlayer):sendSystemMessage("[MandoWayOfLife] ERROR: bounty camp could not start. Contact a GM.")
		return false
	end
	if (not T:start(pPlayer)) then
		self:logDiagPlayer(pPlayer, string.format(
			"beginPrivateContract FAILED: GoToTheater:start false (tier=%s planet=%s).",
			tostring(tier),
			tostring(planet)
		))
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Could not place the bounty camp. Move to open ground away from cities and walls, then try again."
		)
		return false
	end

	self:writeStr(pPlayer, "contractTargetId", "0")
	self:writePrivateContractSpawnAnchor(pPlayer, planet, spawnX, spawnZ, spawnY)
	self:writeInt(pPlayer, "privateContract.useBountyCampTheater", 1)

	-- Mark contract in progress
	self:writeInt(pPlayer, "privateContractActive", 1)
	self:writeInt(pPlayer, "privateContractTargetResolveMisses", 0)
	self:writeInt(pPlayer, "privateContract.fallbackNilStreak", 0)
	self:writeInt(pPlayer, "privateContract.spawnRelinkDone", 0)
	self:clearChapterGateTrialPurpleWaypoint(pPlayer)
	self:clearPrivateContractTargetWaypoint(pPlayer)
	local pTh = T:getTheaterObject(pPlayer)
	if (pTh ~= nil) then
		self:logSpynetDebug(pPlayer, string.format(
			"beginPrivateContract: post-start theaterOid=%s world=(%.1f,%.1f,%.1f) zone=%s",
			tostring(SceneObject(pTh):getObjectID()),
			SceneObject(pTh):getWorldPositionX(),
			SceneObject(pTh):getWorldPositionZ(),
			SceneObject(pTh):getWorldPositionY(),
			tostring(SceneObject(pTh):getZoneName())
		))
	else
		self:logSpynetDebug(pPlayer, "beginPrivateContract: post-start getTheaterObject nil (unexpected after start ok)")
	end
	self:logDiagPlayer(pPlayer, string.format(
		"beginPrivateContract OK: bounty camp tier=%s planet=%s (yellow waypoint on datapad).",
		tostring(tier),
		tostring(planet)
	))
	self:restoreSpynetBountyCampQuestWaypoint(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage(
		"[Spynet trial] A yellow Spynet bounty camp pin was added under your datapad Quest tab (mission/task waypoint, not the normal Waypoints list). Open Quest, activate it, then travel there. The camp spawns when you enter the area. "
			.. "Eliminate the marked outlaw. Helmet on, solo, until it is done."
	)
	self:sendChapterGateProgressFooter(pPlayer, 5)

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
	self:logSpynetDebug(pPlayer, string.format(
		"failPrivateContract: useCamp=%s contractTargetId=%s msg=%s",
		tostring(self:readInt(pPlayer, "privateContract.useBountyCampTheater")),
		tostring(self:readStr(pPlayer, "contractTargetId")),
		tostring(msg)
	))
	self:logDiagPlayer(pPlayer, "failPrivateContract: " .. tostring(msg))
	self:writeInt(pPlayer, "privateContract.pendingCampTeardown", 0)
	self:writeInt(pPlayer, "privateContract.pendingTrialFinalize", 0)
	self:writeInt(pPlayer, "privateContract.postTrialChapter", 0)
	self:finishActiveSpynetBountyCampTheater(pPlayer)
	self:writeInt(pPlayer, "privateContract.useBountyCampTheater", 0)
	self:writeInt(pPlayer, "privateContractActive", 0)
	self:writeInt(pPlayer, "privateContractTargetResolveMisses", 0)
	self:writeInt(pPlayer, "privateContract.fallbackNilStreak", 0)
	self:writeInt(pPlayer, "privateContract.spawnRelinkDone", 0)
	self:clearPrivateContractSpawnAnchor(pPlayer)
	self:clearPrivateContractTargetWaypoint(pPlayer)
	self:removeSpynetContractWaypointDisksFromPlayer(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage(msg)

	-- Despawn contract target if still alive
	local targetId = tonumber(self:readStr(pPlayer, "contractTargetId")) or 0
	if (targetId ~= 0) then
		local pTarget = self:resolvePrivateContractTargetById(targetId)
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

	if (self:readInt(player, "privateContract.useBountyCampTheater") == 1) then
		local c1 = (BellumBountyCampChapter1Theater ~= nil and BellumBountyCampChapter1Theater.hasTaskStarted ~= nil and BellumBountyCampChapter1Theater:hasTaskStarted(player))
		local c2 = (BellumBountyCampChapter2Theater ~= nil and BellumBountyCampChapter2Theater.hasTaskStarted ~= nil and BellumBountyCampChapter2Theater:hasTaskStarted(player))
		local c3 = (BellumBountyCampChapter3Theater ~= nil and BellumBountyCampChapter3Theater.hasTaskStarted ~= nil and BellumBountyCampChapter3Theater:hasTaskStarted(player))
		local px = SceneObject(player):getWorldPositionX()
		local pz = SceneObject(player):getWorldPositionZ()
		local py = SceneObject(player):getWorldPositionY()
		self:logSpynetDebug(player, string.format(
			"contractCheck: camp mode heartbeat intervalMs=%s theaterTaskStarted ch1=%s ch2=%s ch3=%s playerPos=(%.1f,%.1f,%.1f) zone=%s",
			tostring(self.CONTRACT_CHECK_INTERVAL_MS),
			tostring(c1),
			tostring(c2),
			tostring(c3),
			px,
			pz,
			py,
			tostring(SceneObject(player):getZoneName())
		))
		local playerId = SceneObject(player):getObjectID()
		createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", player, tostring(playerId))
		self:logDiagPlayer(player, "TRIAL contractCheckEvent: bounty camp mode (heartbeat only; completion on mark kill)")
		return
	end

	local targetId = tonumber(self:readStr(player, "contractTargetId")) or 0
	self:logDiagPlayer(player, string.format("TRIAL contractCheckEvent: tick targetId=%s", tostring(targetId)))
	if (targetId == 0) then
		self:logDiagPlayer(player, "TRIAL contractCheckEvent: stop (contractTargetId 0)")
		return
	end

	self:ensurePrivateContractSpawnAnchorForLegacyTrial(player)
	local pTarget = self:resolvePrivateContractTargetById(targetId)

	if (pTarget == nil) then
		local ap, ax, az, ay = self:readPrivateContractSpawnAnchor(player)
		if (ap ~= nil) then
			local pR = self:tryRespawnPrivateContractTargetOnce(player, ap, ax, az, ay)
			if (pR ~= nil) then
				self:logDiagPlayer(player, "TRIAL contractCheckEvent: auto-respawn at anchor (stored OID never resolved)")
				local playerId = SceneObject(player):getObjectID()
				createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", player, tostring(playerId))
				return
			end
		end
	end

	pTarget = self:resolvePrivateContractTargetById(targetId)

	if (pTarget ~= nil) then
		self:writeInt(player, "privateContractTargetResolveMisses", 0)
		self:writeInt(player, "privateContract.fallbackNilStreak", 0)
		local isDead = CreatureObject(pTarget):isDead()
		self:logDiagPlayer(player, string.format(
			"TRIAL contractCheckEvent: resolved targetId=%s isDead=%s",
			tostring(targetId),
			tostring(isDead)
		))
		if (isDead) then
			self:logDiagPlayer(player, "TRIAL contractCheckEvent: COMPLETE (target dead)")
			self:completePrivateContract(player)
			return
		end
		local playerId = SceneObject(player):getObjectID()
		createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", player, tostring(playerId))
		self:logDiagPlayer(player, "TRIAL contractCheckEvent: reschedule (target alive)")
		return
	end

	-- OID not in this process object map: never treat a single nil as dead. Optional fallback if player stays at spawn sector.
	local misses = self:readInt(player, "privateContractTargetResolveMisses") + 1
	self:writeInt(player, "privateContractTargetResolveMisses", misses)

	local nearAnchor = self:isPlayerNearPrivateContractAnchorXY(player, self.PRIVATE_CONTRACT_FALLBACK_RADIUS_SQ)
	local fbStreak = self:readInt(player, "privateContract.fallbackNilStreak")
	if (nearAnchor) then
		fbStreak = fbStreak + 1
		self:writeInt(player, "privateContract.fallbackNilStreak", fbStreak)
	else
		self:writeInt(player, "privateContract.fallbackNilStreak", 0)
		fbStreak = 0
	end

	self:logDiagPlayer(player, string.format(
		"TRIAL contractCheckEvent: unresolved targetId=%s misses=%s nearAnchor=%s fallbackNilStreak=%s (need %s for fallback complete)",
		tostring(targetId),
		tostring(misses),
		tostring(nearAnchor),
		tostring(fbStreak),
		tostring(self.PRIVATE_CONTRACT_FALLBACK_COMPLETE_NIL_TICKS)
	))

	if (nearAnchor and fbStreak >= self.PRIVATE_CONTRACT_FALLBACK_COMPLETE_NIL_TICKS) then
		self:logDiagPlayer(player, "TRIAL contractCheckEvent: COMPLETE (fallback near anchor + unresolved streak)")
		self:completePrivateContract(player)
		return
	end

	if (misses >= 90) then
		self:logDiagPlayer(player, "TRIAL contractCheckEvent: FAIL (miss cap, target never resolved)")
		self:failPrivateContract(
			player,
			"The mark dropped off the network. Return to the Mandalorian Operative on Corellia."
		)
		return
	end

	local playerId = SceneObject(player):getObjectID()
	createEvent(self.CONTRACT_CHECK_INTERVAL_MS, self.screenplayName, "contractCheckEvent", player, tostring(playerId))
	self:logDiagPlayer(player, "TRIAL contractCheckEvent: reschedule (unresolved)")
end

-- After a successful private trial: set chapter, grant armor (chapterRewards) + loot, title, badge, gate waypoints.
-- For bounty-camp trials this runs from delayedFinishSpynetBountyCampTheater after camp teardown; non-camp runs immediately from completePrivateContract.
function MandoWayOfLife:applyChapterAdvanceAfterTrial(pPlayer, chNew)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end
	if (chNew == nil or type(chNew) ~= "number" or chNew < 1) then
		self:logDiagPlayer(pPlayer, string.format("applyChapterAdvanceAfterTrial: invalid chNew=%s.", tostring(chNew)))
		return
	end

	self:setChapter(pPlayer, chNew)
	self:writeInt(pPlayer, "chapter" .. chNew .. "Complete", 1)
	self:logDiagPlayer(pPlayer, string.format("applyChapterAdvanceAfterTrial: chapter set to %s.", tostring(chNew)))

	self:grantReward(pPlayer, chNew)
	self:grantMandoWayArmoryChapterGift(pPlayer, chNew)

	if (chNew >= 1) then
		self:grantChapterLoot(pPlayer, chNew)
	end

	local title = self.chapterTitles[chNew] or ""
	self:grantChapterRankTitle(pPlayer, chNew)
	self:tryAwardChapterBadge(pPlayer, chNew)

	CreatureObject(pPlayer):sendSystemMessage(
		"The trial is complete. You have earned the rank of " .. title .. "."
	)

	-- Critical: after a trial, C++/Lua used to leave bhTerminalCount at 5 with needsCustomContract=0.
	-- Operative convo then runs unlockPrivateTrialGateIfEligible and re-opens the private trial without
	-- five new BH terminal completions. Zero counters first, then open the next 0/5 cycle (Ch1–Ch3 only).
	self:writeInt(pPlayer, "bhTerminalCount", 0)
	self:writeInt(pPlayer, "needsCustomContract", 0)
	self:writeInt(pPlayer, "countingEnabled", 0)

	local gatePinsOk = self:grantChapterGateBriefingWaypoints(pPlayer, true, true)
	if (not gatePinsOk) then
		self:logDiagPlayer(pPlayer, "applyChapterAdvanceAfterTrial: grantChapterGateBriefingWaypoints returned false (operative or BH pin missing).")
		CreatureObject(pPlayer):sendSystemMessage(
			"[Mandalorian Way of Life] One or more Corellia gate waypoints could not be placed. Check your datapad; if pins are missing, relog or contact staff."
		)
	end
	-- Purple pin is only for trial-ready (5/5); grantPurpleOperativeReturnWaypoint belongs in unlockPrivateTrialGateIfEligible, not here.
	if (chNew < 4) then
		self:startChapterGate(pPlayer)
		self:startGateProgressPoll(pPlayer)
		self:logDiagPlayer(pPlayer, string.format(
			"applyChapterAdvanceAfterTrial: started next Spynet terminal gate (0/5) after chapter %s.", tostring(chNew)
		))
	else
		self:clearChapterGateTrialPurpleWaypoint(pPlayer)
	end
end

-- Called from contract completion trigger when player succeeds
function MandoWayOfLife:completePrivateContract(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "privateContractActive") ~= 1) then return end

	local chBefore = self:getChapter(pPlayer)
	local chNew = chBefore + 1

	self:logSpynetDebug(pPlayer, string.format(
		"completePrivateContract: enter useCamp=%s contractTargetId=%s chapterBefore=%s chNew=%s",
		tostring(self:readInt(pPlayer, "privateContract.useBountyCampTheater")),
		tostring(self:readStr(pPlayer, "contractTargetId")),
		tostring(chBefore),
		tostring(chNew)
	))
	local useCamp = self:readInt(pPlayer, "privateContract.useBountyCampTheater") == 1
	if useCamp then
		self:writeInt(pPlayer, "privateContract.pendingCampTeardown", 1)
		self:writeInt(pPlayer, "privateContract.pendingTrialFinalize", 1)
		self:writeInt(pPlayer, "privateContract.postTrialChapter", chNew)
		local playerId = SceneObject(pPlayer):getObjectID()
		createEvent(self.SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS, self.screenplayName, "delayedFinishSpynetBountyCampTheater", pPlayer, tostring(playerId))
		self:logSpynetDebug(pPlayer, string.format(
			"completePrivateContract: deferred camp teardown + chapter advance by %sms",
			tostring(self.SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS)
		))
	else
		self:finishActiveSpynetBountyCampTheater(pPlayer)
	end
	-- Gate waypoints for the next cycle are applied in applyChapterAdvanceAfterTrial (immediate for legacy, deferred for camp).
	self:writeInt(pPlayer, "privateContractActive", 0)
	self:writeInt(pPlayer, "needsCustomContract", 0)
	self:writeStr(pPlayer, "contractTargetId", "0")
	self:writeInt(pPlayer, "privateContract.useBountyCampTheater", 0)
	self:writeInt(pPlayer, "privateContractTargetResolveMisses", 0)
	self:writeInt(pPlayer, "privateContract.fallbackNilStreak", 0)
	self:writeInt(pPlayer, "privateContract.spawnRelinkDone", 0)
	self:clearPrivateContractSpawnAnchor(pPlayer)
	self:clearPrivateContractTargetWaypoint(pPlayer)
	self:removeSpynetContractWaypointDisksFromPlayer(pPlayer)

	if useCamp then
		CreatureObject(pPlayer):sendSystemMessage(
			"You have defeated the mark. The Spynet camp will stand down in about one minute; when it does, the Guild will record your trial, open the next gate, and deliver your armor."
		)
	else
		self:applyChapterAdvanceAfterTrial(pPlayer, chNew)
	end
end

-- ============================================================
-- CHAPTER 5: MANDALORIAN (Jabba Themepark gate)
-- ============================================================
-- Called from ThemeParkLogic when Jabba themepark awards badge 105; only messages Clanbound players awaiting ch5.
function MandoWayOfLife:onJabbaThemeparkBadgeEarned(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "chapter4Complete") ~= 1) then return end
	if (self:readInt(pPlayer, "chapter5Complete") == 1) then return end

	CreatureObject(pPlayer):sendSystemMessage(
		"[Mandalorian Way] Incoming message from the Spynet comlink. Congratulations. Return to Mos Eisley and seek our recruiter."
	)
end

-- Called from mando_trialmaster_conv_handler when the player returns with Jabba badge 105.
-- Idempotent: no-ops if chapter5Complete is already set.
-- No armor reward at this tier; title + badge only.
function MandoWayOfLife:grantMandalorian(pPlayer)
	if (pPlayer == nil) then return end
	if (self:readInt(pPlayer, "chapter5Complete") == 1) then return end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		self:logDiagPlayer(pPlayer, "grantMandalorian: player ghost nil.")
		return
	end

	if (not PlayerObject(pGhost):hasBadge(self.JABBA_THEMEPARK_BADGE)) then
		self:logDiagPlayer(pPlayer, "grantMandalorian: blocked (Jabba themepark badge not present).")
		CreatureObject(pPlayer):sendSystemMessage(
			"[Mandalorian Way] You have not yet earned favor with the Hunts. "
			.. "Complete Jabba's operations on Tatooine and return to me."
		)
		return
	end

	self:writeInt(pPlayer, "chapter5Complete", 1)
	self:setChapter(pPlayer, 5)
	self:grantChapterRankTitle(pPlayer, 5)
	self:tryAwardChapterBadge(pPlayer, 5)

	self:logDiagPlayer(pPlayer, "grantMandalorian: Mandalorian rank granted (chapter 5).")
	CreatureObject(pPlayer):sendSystemMessage(
		"[Mandalorian Way] Word of your deeds reached me before you did. "
		.. "The Hunts have spoken. You are Mandalorian. Wear the title."
	)
	CreatureObject(pPlayer):sendSystemMessage(
		"[Mandalorian Way] Incoming message from the Spynet comlink. Continue your Hunt. We will be in touch. THIS IS THE WAY!"
	)
end

-- ============================================================
-- RANK TITLE (title skill) + OPTIONAL BADGE
-- ============================================================
-- Titles: Lua skills with title=1 + PlayerObject:setTitle for immediate display (see skills/bellum/mando_titles.lua).
-- Badges: numeric indices from client/server badge_map.iff; set chapterBadgeIds when your TRE defines rows.

function MandoWayOfLife:grantChapterRankTitle(pPlayer, chapterIndex)
	if (pPlayer == nil) then return end
	local skillName = self.chapterTitleSkills[chapterIndex]
	if (skillName == nil or skillName == "") then return end

	if (not CreatureObject(pPlayer):hasSkill(skillName)) then
		awardSkill(pPlayer, skillName)
	end

	if (not CreatureObject(pPlayer):hasSkill(skillName)) then
		self:logDiagPlayer(pPlayer, string.format(
			"grantChapterRankTitle FAILED: skill not held after award (%s). Check skills/serverobjects.lua includes bellum/mando_titles.lua.",
			skillName
		))
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil) then
		PlayerObject(pGhost):setTitle(skillName)
	end
end

function MandoWayOfLife:tryAwardChapterBadge(pPlayer, chapterIndex)
	if (pPlayer == nil) then return end
	local badgeId = nil
	if (self.chapterBadgeIds ~= nil) then
		badgeId = self.chapterBadgeIds[chapterIndex]
	end
	if (badgeId == nil) then return end
	local id = tonumber(badgeId)
	if (id == nil or id < 0) then return end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then return end
	if (PlayerObject(pGhost):hasBadge(id)) then return end
	PlayerObject(pGhost):awardBadge(id)
end

-- ============================================================
-- REWARD GRANT
-- ============================================================

-- Mandalorian armory: hidden weapon certs + gift weapon on chapters 1 through 3 (Initiate, Hunter, Verd'ika).
function MandoWayOfLife:grantMandoWayArmoryChapterGift(pPlayer, chNew)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return end
	if (chNew == nil or type(chNew) ~= "number" or chNew < 1 or chNew > 3) then return end

	local cfg = self.mandoWayArmoryChapters[chNew]
	if (cfg == nil) then return end

	if (not CreatureObject(pPlayer):hasSkill(cfg.certSkill)) then
		awardSkill(pPlayer, cfg.certSkill)
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		self:logDiagPlayer(pPlayer, string.format("grantMandoWayArmoryChapterGift: no inventory (chapter %s).", tostring(chNew)))
		return
	end

	local pItem = giveItem(pInventory, cfg.weaponIff, -1)
	if (pItem ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(cfg.giftMsg)
		self:logDiagPlayer(pPlayer, string.format("grantMandoWayArmoryChapterGift OK chapter=%s.", tostring(chNew)))
	else
		CreatureObject(pPlayer):sendSystemMessage(
			"[MandoWayOfLife] Armory gift could not be placed in inventory. Free a slot and contact staff to recover your chapter weapon."
		)
		self:logDiagPlayer(pPlayer, string.format("grantMandoWayArmoryChapterGift FAILED giveItem chapter=%s.", tostring(chNew)))
	end
end

function MandoWayOfLife:playerEligibleForMandoArmoryCatalog(pPlayer)
	if (pPlayer == nil) then return false end
	if (not self:isArcComplete(pPlayer)) then return false end
	if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then return false end
	return true
end

-- Recruiter sale: tier 1..3 matches Initiate, Hunter, Verd'ika chapter completion.
-- Returns ok (boolean), message (string for convo or system).
function MandoWayOfLife:trySellMandoArmorySchematic(pPlayer, tier)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then return false, "Something went wrong." end
	if (tier == nil or type(tier) ~= "number" or tier < 1 or tier > 3) then return false, "Invalid request." end

	if (not self:playerEligibleForMandoArmoryCatalog(pPlayer)) then
		return false, "You are not cleared for the Mandalorian armory. Finish the Foundling arc and earn Novice Bounty Hunter first."
	end

	local sale = self.mandoWayArmorySchematicSales[tier]
	if (sale == nil) then return false, "Invalid request." end

	if (self:readInt(pPlayer, sale.chapterFlag) ~= 1) then
		return false, "You have not completed the trial for that rank yet. Earn the chapter first, then come back for the schematic."
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then return false, "I cannot reach your inventory." end
	if (SceneObject(pInventory):isContainerFullRecursive()) then return false, "Your inventory is full. Make room for a datapad schematic." end

	local cost = tonumber(sale.cost) or 0
	if (cost < 1) then return false, "Invalid sale." end

	local cash = CreatureObject(pPlayer):getCashCredits()
	if (cash < cost) then
		return false, string.format("That schematic is %s credits, cash on hand. You are short.", tostring(cost))
	end

	CreatureObject(pPlayer):subtractCashCredits(cost)
	local pItem = giveItem(pInventory, sale.iff, -1)
	if (pItem == nil) then
		CreatureObject(pPlayer):addCashCredits(cost, true)
		return false, "The schematic did not transfer. Your credits were refunded. Try again with a clear inventory slot."
	end

	self:logDiagPlayer(pPlayer, string.format("trySellMandoArmorySchematic OK tier=%s cost=%s.", tostring(tier), tostring(cost)))
	return true, "Done. Give that datapad to a master weaponsmith you trust. Experiments matter."
end

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
-- createLoot() runs through the full loot system pipeline - craftingValues stat
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
     resolveChapterLootIff, grantChapterLoot manual weighted-random) - deleted in favour
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

	-- Chapter loot items are loot group item templates, not object templates; use giveItem with the directObjectTemplate IFF path.
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

-- Closed / full-face helmets usually use "hat" on Core3 (including Wookiees - same IFF, same arrangement).
-- "helmet" covers odd templates; "hair" covers rare slot edge cases.
-- Any Mandalorian Way custom helmet tier (foundling_*, initiate_helmet, hunter_helmet, …) counts for trial gate.
-- Must use getTemplateObjectPath() - getObjectTemplate() is not exposed on LuaSceneObject.
function MandoWayOfLife:objectTemplateIsFoundlingHelmet(pObj)
	if (pObj == nil or SceneObject(pObj) == nil) then return false end
	local path = SceneObject(pObj):getTemplateObjectPath()
	if (path == nil or path == "") then return false end
	if (string.find(path, "mandalorian/custom/", 1, true) == nil) then return false end
	return string.find(path, "_helmet.iff", 1, true) ~= nil
end

function MandoWayOfLife:hasFoundlingHelmet(pPlayer)
	if (pPlayer == nil) then return false end
	local so = SceneObject(pPlayer)
	for _, slot in ipairs({ "hat", "helmet", "hair" }) do
		if (self:objectTemplateIsFoundlingHelmet(so:getSlottedObject(slot))) then
			return true
		end
	end
	return false
end

-- ============================================================
-- PLAYER: planet + quota report (ChatManagerImplementation on spatial "!foundling" -> this)
-- ============================================================

function mandoFoundlingStatusRun(pPlayer)
	MandoWayOfLife:sendFoundlingStatusReportToPlayer(pPlayer)
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
		"[MandoAdmin] Quota counts mission terminal completions (destroy, deliver, hunting, recon, crafting, survey, escort). Bounty board missions do not count."
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
		"countingEnabled", "bhTerminalCount", "needsCustomContract", "privateContractActive", "contractTargetId",
		"privateContractTargetResolveMisses",
		"privateContract.fallbackNilStreak",
		"privateContract.spawnRelinkDone",
		"privateContract.useBountyCampTheater",
		"privateContract.pendingCampTeardown",
		"privateContract.pendingTrialFinalize",
		"privateContract.postTrialChapter",
		"chapterGate.operativeWpId", "chapterGate.bhTerminalWpId", "chapterGate.trialPurpleWpId",
		"chapterGate.contractMarkWpId",
	}
	-- Snapshot waypoint ids before clearing screenplay keys (otherwise reads return 0).
	local recWp = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.recruiterWaypointId")) or 0
	local wpId = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.waypointId")) or 0
	local rwpId = tonumber(readScreenPlayData(p, "MandoWayOfLife", "foundling.returnWaypointId")) or 0
	local cgOp = tonumber(readScreenPlayData(p, "MandoWayOfLife", "chapterGate.operativeWpId")) or 0
	local cgBh = tonumber(readScreenPlayData(p, "MandoWayOfLife", "chapterGate.bhTerminalWpId")) or 0
	local cgPurp = tonumber(readScreenPlayData(p, "MandoWayOfLife", "chapterGate.trialPurpleWpId")) or 0
	local cgMark = tonumber(readScreenPlayData(p, "MandoWayOfLife", "chapterGate.contractMarkWpId")) or 0
	MandoWayOfLife:finishActiveSpynetBountyCampTheater(p)
	for _, k in ipairs(keys) do
		writeScreenPlayData(p, "MandoWayOfLife", k, "0")
	end
	writeScreenPlayData(p, "MandoWayOfLife", "privateContract.anchorPlanet", "")
	writeScreenPlayData(p, "MandoWayOfLife", "privateContract.anchorX", "")
	writeScreenPlayData(p, "MandoWayOfLife", "privateContract.anchorZ", "")
	writeScreenPlayData(p, "MandoWayOfLife", "privateContract.anchorY", "")
	local pGhost = CreatureObject(p):getPlayerObject()
	if (pGhost ~= nil) then
		local po = PlayerObject(pGhost)
		if (recWp ~= 0) then po:removeWaypoint(recWp, true) end
		if (wpId ~= 0) then po:removeWaypoint(wpId, true) end
		if (rwpId ~= 0) then po:removeWaypoint(rwpId, true) end
		if (cgOp ~= 0) then po:removeWaypoint(cgOp, true) end
		if (cgBh ~= 0) then po:removeWaypoint(cgBh, true) end
		if (cgPurp ~= 0) then po:removeWaypoint(cgPurp, true) end
		if (cgMark ~= 0) then po:removeWaypoint(cgMark, true) end
	end
	MandoWayOfLife:removeSpynetContractWaypointDisksFromPlayer(p)
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
