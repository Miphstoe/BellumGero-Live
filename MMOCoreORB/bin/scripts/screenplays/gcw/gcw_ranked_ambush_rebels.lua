-- ==========================================================
-- GCW Ranked Ambush — Rebels (targets Rebels; spawns Imperial squad)
-- (Unified with the Imperials file)
-- ==========================================================

GCWRankedAmbushRebels = ScreenPlay:new {
    numberOfActs   = 1,
    screenplayName = "GCWRankedAmbushRebels",

    debug = {
        enabled        = false,
        notifyPlayer   = false,
        fastTimings    = false,
        spawnMarkers   = false,
        verboseSpawns  = false,
        markerCleanup  = true,
    },

    trigger = {
        autoForRebels     = true,
        autoForImperials  = false,

        firstDelayMin     = 1800,
        firstDelayMax     = 3600,
        cooldownMin       = 1800,
        cooldownMax       = 2600,
        retryIfNotReady   = 30,
        -- requireOvert   = true,
    },

    shuttleTemplate = "object/creature/npc/theme_park/lambda_shuttle.iff",
    imperialTrooper = "ambush_imperial_storm_commando",

    t_descend     = 34,
    t_ramp        = 19,
    t_buffer      = 2,
    t_deployExtra = 0,
    t_linger      = 30,
    t_cleanup     = 5*60,

    spawnRadiusMin = 25,
    spawnRadiusMax = 40,
    leashRadius    = 110,
    dropRadius     = 14,
    spawnSpread    = 6,
    dropOffset     = { x = -0.2, y = -6.5 },
    rampForward    = 7.5,

    markerTemplate = "object/tangible/poi/poi_marker_large.iff",
    fileTag        = "[GCW Ambush - vs Rebels]",
    optTag         = "GCW_Ambush_Rebels",

    FP_REWARD      = 2500,
    FP_SIDE        = "rebel",
    FP_RANGE       = 80
}

GCWRankedAmbushRebels.barks = {
    "Seize those Rebel plans now!",
    "Confiscate the documents, for the Empire!",
    "By order of the Emperor, surrender that intelligence!",
    "Secure the data case, move!"
}

-- ========= Utilities (identical) =========
local function nowHHMMSS() return (os and os.date) and os.date("%H:%M:%S") or "" end
function GCWRankedAmbushRebels:_log(msg)
    if self.debug and self.debug.enabled then
        printLuaError(string.format("%s [%s] %s", self.fileTag, nowHHMMSS(), tostring(msg)))
    end
end
local function msg(self, pPlayer, text)
    if not self.debug.enabled or not self.debug.notifyPlayer or pPlayer == nil then return end
    CreatureObject(pPlayer):sendSystemMessage(self.fileTag .. " " .. text)
end
local function notify(pPlayer, text) if pPlayer ~= nil then CreatureObject(pPlayer):sendSystemMessage(text) end end
local function groundYAt(planet, x, yCoord, fallbackY)
    local fn = rawget(_G, "getTerrainHeight")
    if type(fn) == "function" then
        local ok, h = pcall(fn, planet, x, yCoord); if ok and type(h) == "number" then return h end
        ok, h = pcall(fn, x, yCoord); if ok and type(h) == "number" then return h end
    end
    return fallbackY or 0
end
local function basis(hdg)
    local r = math.rad(hdg); local s, c = math.sin(r), math.cos(r)
    local function fwd(d)   return d * c, d * s end
    local function right(d) return d * s, -d * c end
    return fwd, right
end
local function validPlayer(p) return p ~= nil and SceneObject(p):isPlayerCreature() end
local function randBetween(a,b) return getRandomNumber(a, b) end
local function forceAggroToTarget(pMobile, pTarget)
    if pMobile == nil or pTarget == nil then return end
    pcall(function() AiAgent(pMobile):clearHateList() end)
    pcall(function() AiAgent(pMobile):addHate(pTarget, 10000) end)
    pcall(function() CreatureObject(pMobile):engageCombat(pTarget) end)
    pcall(function() AiAgent(pMobile):setFollowObject(pTarget) end)
    pcall(function() AiAgent(pMobile):setFollowTarget(pTarget) end)
end
local function awardFactionPointsNearby(self, pPlayer, side, amount, range)
    if pPlayer == nil then return end
    local function grant(pTgt)
        if pTgt == nil or not SceneObject(pTgt):isPlayerCreature() then return end
        if not SceneObject(pTgt):isInRangeWithObject(pPlayer, range) then return end
        local ghost = CreatureObject(pTgt):getPlayerObject()
        if ghost ~= nil then PlayerObject(ghost):increaseFactionStanding(side, amount) end
    end
    local co = CreatureObject(pPlayer)
    if co.isGrouped and co:isGrouped() then for i=0, co:getGroupSize()-1 do grant(co:getGroupMember(i)) end
    else grant(pPlayer) end
    notify(pPlayer, "Ambush Squad Eliminated.")
end
local function pidOf(pPlayer) return tostring(SceneObject(pPlayer):getObjectID()) end

-- ========= Opt-in helper =========
function GCWRankedAmbushRebels:isOptedIn(pPlayer)
    if pPlayer == nil then return false end
    return CreatureObject(pPlayer):hasScreenPlayState(1, self.optTag)
end

-- ========= Global concurrency lock (prevents both screenplays triggering simultaneously) =========
local GLOBAL_AMBUSH_LOCK = "gcwAmbush:globalLock"
local ACTIVE_AMBUSH_COUNT = "gcwAmbush:activeCount"
local MAX_CONCURRENT_AMBUSHES = 2  -- Prevent server overload
local LOCK_TIMEOUT = 120 * 1000    -- 2 minute timeout to prevent deadlock

function GCWRankedAmbushRebels:acquireGlobalLock()
    local now = os.time() * 1000  -- Current time in ms
    local lockData = readData(GLOBAL_AMBUSH_LOCK) or "0:0"
    local lockTime, lockOwner = string.match(lockData, "(%d+):(%d+)")
    lockTime = tonumber(lockTime) or 0

    -- Check if lock is stale (timeout)
    if now - lockTime > LOCK_TIMEOUT then
        writeData(GLOBAL_AMBUSH_LOCK, now .. ":1")
        return true
    end

    return false
end

function GCWRankedAmbushRebels:releaseGlobalLock()
    deleteData(GLOBAL_AMBUSH_LOCK)
end

function GCWRankedAmbushRebels:checkAmbushCap()
    local count = tonumber(readData(ACTIVE_AMBUSH_COUNT) or "0")
    return count < MAX_CONCURRENT_AMBUSHES
end

function GCWRankedAmbushRebels:incrementAmbushCount()
    local count = tonumber(readData(ACTIVE_AMBUSH_COUNT) or "0")
    writeData(ACTIVE_AMBUSH_COUNT, count + 1)
end

function GCWRankedAmbushRebels:decrementAmbushCount()
    local count = tonumber(readData(ACTIVE_AMBUSH_COUNT) or "0")
    if count > 0 then
        writeData(ACTIVE_AMBUSH_COUNT, count - 1)
    end
end

-- ========= Scheduling =========
function GCWRankedAmbushRebels:_sched(pPlayer, seconds, reason)
    local s = seconds or self.trigger.retryIfNotReady or 120
    local oid = pPlayer and SceneObject(pPlayer):getObjectID() or 0
    self:_log(string.format("schedule next tick: reason=%s delay=%ds oid=%s", tostring(reason), s, tostring(oid)))
    createEvent(s * 1000, self.screenplayName, "ambushTick", pPlayer, tostring(oid))
end

function GCWRankedAmbushRebels:pickLandingAround(pPlayer)
    local co = CreatureObject(pPlayer)
    local px, py, pz = co:getPositionX(), co:getPositionY(), co:getPositionZ()
    local r   = getRandomNumber(self.spawnRadiusMin, self.spawnRadiusMax)
    local ang = getRandomNumber(0, 359)
    local sx  = px + r * math.cos(math.rad(ang))
    local sz  = pz + r * math.sin(math.rad(ang))
    local hdg = (ang + 180) % 360
    local sy  = groundYAt(SceneObject(pPlayer):getZoneName(), sx, sz, py)
    return sx, sy, sz, hdg
end

function GCWRankedAmbushRebels:start()
    self:_log("start(): screenplay registered & idle.")
end

function GCWRankedAmbushRebels:startHere(pPlayer)
    if not validPlayer(pPlayer) or not self:isOptedIn(pPlayer) then return end

    -- Prevent concurrent encounters for the same player
    local playerId = SceneObject(pPlayer):getObjectID()
    local concurrentKey = playerId .. ":gcwAmbushRebels:encounter_active"
    if readData(concurrentKey) == 1 then
        self:_log("startHere: encounter already active for this player, aborting")
        return
    end

    -- Check global ambush cap to prevent server overload from concurrent encounters
    if not self:checkAmbushCap() then
        self:_log("startHere: ambush cap reached, deferring encounter")
        msg(self, pPlayer, "Too many ambushes active. Retrying soon.")
        self:_sched(pPlayer, 30, "ambush_cap_reached")
        return
    end

    local planet = SceneObject(pPlayer):getZoneName()
    local sx, sy, sz, hdg = self:pickLandingAround(pPlayer)

    local pShuttle = spawnSceneObject(planet, self.shuttleTemplate, sx, sz, sy, 0, math.rad(hdg))
    if pShuttle == nil then
        self:_log("startHere: FAILED to spawn Imperial shuttle; will retry soon.")
        msg(self, pPlayer, "Failed to spawn Imperial shuttle (retrying).")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "spawn_shuttle_failed")
        return
    end

    local shuttleID = SceneObject(pShuttle):getObjectID()
    writeData(shuttleID .. ":gcwAmbushRebels:active", 1)
    writeData(shuttleID .. ":gcwAmbushRebels:hdg", hdg)
    writeData(playerId .. ":gcwAmbushRebels:encounter_active", 1)

    -- Increment global ambush counter
    self:incrementAmbushCount()

    CreatureObject(pShuttle):setCustomObjectName("Lambda Shuttle")
    CreatureObject(pShuttle):setPosture(UPRIGHT)

    local eta = self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra
    notify(pPlayer, string.format("Imperial shuttle inbound on your position (ETA %ds).", eta))
    self:_log(string.format("spawned shuttle %s at (%.1f, %.1f) hdg=%d, ETA=%ds",
        tostring(shuttleID), sx, sz, hdg, eta))

    createEvent(self.t_descend * 1000, self.screenplayName, "handleShuttlePosture", pShuttle, "")
    local deployAtMs  = (self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra) * 1000
    local despawnAtMs = deployAtMs + (self.t_linger * 1000)
    createEvent(deployAtMs,  self.screenplayName, "deploySquad",     pShuttle, tostring(SceneObject(pPlayer):getObjectID()))
    createEvent(despawnAtMs, self.screenplayName, "despawnSequence", pShuttle, "")
    -- Robust failsafe (also cleans children). Format: "shuttleID,playerID"
    createEvent(self.t_cleanup * 1000, self.screenplayName, "failsafeCleanup", pShuttle, tostring(shuttleID) .. "," .. tostring(playerId))
end

function GCWRankedAmbushRebels:handleShuttlePosture(pShuttle)
    if pShuttle == nil then return end
    CreatureObject(pShuttle):setPosture(PRONE)
end

local function spawnSingleXZY(self, planet, template, x, height, yCoord, hdg, cell, mood)
    if self.debug.verboseSpawns then self:_log("spawn mobile: "..template) end
    return spawnMobile(planet, template, 0, x, yCoord, height, hdg, cell, mood)
end

function GCWRankedAmbushRebels:deploySquad(pShuttle, callerIdStr)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbushRebels:active") ~= 1 then return end

    local planet = SceneObject(pShuttle):getZoneName()
    local sx = SceneObject(pShuttle):getPositionX()
    local sy = SceneObject(pShuttle):getPositionY()
    local sz = SceneObject(pShuttle):getPositionZ()
    local hdg = readData(shuttleID .. ":gcwAmbushRebels:hdg")

    local pCaller = nil
    if callerIdStr and callerIdStr ~= "" then pCaller = getSceneObject(tonumber(callerIdStr)) end
    if pCaller ~= nil then writeData(shuttleID .. ":gcwAmbushRebels:caller", tonumber(callerIdStr)) end
    writeData(shuttleID .. ":gcwAmbushRebels:rewarded", 0)

    local fwd, right = basis(hdg)
    local baseX, baseYCoord = fwd(self.rampForward + 2.5); baseX, baseYCoord = sx + baseX, sz + baseYCoord

    local slots = {
        {  0.0,  0.0 }, {  2.5,  0.4 }, { -2.5,  0.4 },
        {  1.2, -2.0 }, { -1.2, -2.0 },
        {  3.6, -1.6 }, { -3.6, -1.6 },
        {  0.0, -4.0 },
    }

    local EVT_CREATUREDEATH = rawget(_G, "CREATUREDEATH")

    local spawned = 0
    local childIdx = readData(shuttleID .. ":gcwAmbushRebels:childCount") or 0
    for i=1,#slots do
        local dxF, dyF = fwd(slots[i][2]); local dxR, dyR = right(slots[i][1])
        local x = baseX + dxF + dxR
        local yCoord = baseYCoord + dyF + dyR
        local height = groundYAt(planet, x, yCoord, sy)

        local pMobile = spawnSingleXZY(self, planet, self.imperialTrooper, x, height, yCoord, hdg, 0, "")
        if pMobile ~= nil then
            spawned = spawned + 1
            local coMob = CreatureObject(pMobile)
            if coMob and coMob.setPvpStatusBitmask then coMob:setPvpStatusBitmask(1) end
            if pCaller ~= nil then forceAggroToTarget(pMobile, pCaller) end

            local mobOID = SceneObject(pMobile):getObjectID()
            writeData(mobOID .. ":gcwAmbushRebels:parent", shuttleID)
            childIdx = childIdx + 1
            writeData(shuttleID .. ":gcwAmbushRebels:child:" .. childIdx, mobOID)

            if EVT_CREATUREDEATH ~= nil then
                createObserver(EVT_CREATUREDEATH, self.screenplayName, "onSquadMemberDied", pMobile)
            end
            createObserver(OBJECTDESTRUCTION, self.screenplayName, "onSquadMemberDied", pMobile)
        end
    end

    writeData(shuttleID .. ":gcwAmbushRebels:childCount", childIdx)
    writeData(shuttleID .. ":gcwAmbushRebels:alive", spawned)
    self:_log(string.format("deploySquad: spawned=%d setAlive=%d (planet=%s) at %.1f,%.1f",
        spawned, spawned, tostring(planet), sx, sz))

    if pCaller ~= nil then
        msg(self, pCaller, string.format("Imperial squad deployed (%d/%d).", spawned, #slots))
    end

    createEvent(1500, self.screenplayName, "landingBarks", pShuttle, "")
end

function GCWRankedAmbushRebels:landingBarks(pShuttle)
    if pShuttle == nil or #self.barks == 0 then return end
    local sid = SceneObject(pShuttle):getObjectID()
    local count = readData(sid .. ":gcwAmbushRebels:childCount") or 0
    if count <= 0 then return end

    local barkers = math.min(2, count)
    local used = {}
    for n=1,barkers do
        local idx = getRandomNumber(1, count)
        local guard = 0
        while used[idx] and guard < 5 do idx = getRandomNumber(1, count); guard = guard + 1 end
        used[idx] = true
        local mid = readData(sid .. ":gcwAmbushRebels:child:" .. idx)
        if mid and mid ~= 0 then
            local pm = getSceneObject(tonumber(mid))
            local line = self.barks[getRandomNumber(1, #self.barks)]
            if pm and line then pcall(spatialChat, pm, line) end
        end
    end
end

function GCWRankedAmbushRebels:onSquadMemberDied(pMob, pKiller)
    if pMob == nil then return 1 end
    local mobId   = SceneObject(pMob):getObjectID()
    local parentID = readData(mobId .. ":gcwAmbushRebels:parent")
    if not parentID or parentID == 0 then return 1 end

    local aliveKey  = parentID .. ":gcwAmbushRebels:alive"
    local rewardKey = parentID .. ":gcwAmbushRebels:rewarded"
    local callerKey = parentID .. ":gcwAmbushRebels:caller"

    local before = readData(aliveKey) or 0
    local after  = before - 1; if after < 0 then after = 0 end
    writeData(aliveKey, after)

    self:_log(string.format("onSquadMemberDied: mob=%s parent=%s alive %d->%d", tostring(mobId), tostring(parentID), before, after))

    if after == 0 and readData(rewardKey) ~= 1 then
        writeData(rewardKey, 1)
        local callerId = readData(callerKey)
        if callerId and callerId ~= 0 then
            local pCaller = getSceneObject(tonumber(callerId))
            if pCaller ~= nil then awardFactionPointsNearby(self, pCaller, self.FP_SIDE, self.FP_REWARD, self.FP_RANGE) end
        end
        self:_log("wipe complete: FP awarded and cleanup queued")
    end
    return 1
end

function GCWRankedAmbushRebels:despawnSequence(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbushRebels:active") ~= 1 then return end
    CreatureObject(pShuttle):setPosture(UPRIGHT)
    -- Pass player ID to cleanShuttleOnly so it can clear the encounter_active flag
    local playerId = readData(shuttleID .. ":gcwAmbushRebels:caller") or 0
    createEvent(6 * 1000, self.screenplayName, "cleanShuttleOnly", pShuttle, tostring(playerId))
end

function GCWRankedAmbushRebels:cleanShuttleOnly(pShuttle, playerIdStr)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    deleteData(shuttleID .. ":gcwAmbushRebels:active")
    deleteData(shuttleID .. ":gcwAmbushRebels:caller")
    deleteData(shuttleID .. ":gcwAmbushRebels:alive")
    deleteData(shuttleID .. ":gcwAmbushRebels:rewarded")
    deleteData(shuttleID .. ":gcwAmbushRebels:hdg")

    -- Clear the encounter_active flag
    if playerIdStr and playerIdStr ~= "" and playerIdStr ~= "0" then
        local pid = tonumber(playerIdStr) or 0
        if pid ~= 0 then
            deleteData(pid .. ":gcwAmbushRebels:encounter_active")
        end
    end

    -- Decrement global ambush counter
    self:decrementAmbushCount()

    SceneObject(pShuttle):destroyObjectFromWorld()
    SceneObject(pShuttle):destroyObjectFromDatabase()
    self:_log("cleanShuttleOnly: shuttle removed")
end

function GCWRankedAmbushRebels:failsafeCleanup(pShuttle, shuttleIdStr)
    -- Robust cleanup: work even if shuttle object was already removed.
    -- shuttleIdStr format: "shuttleID" or "shuttleID,playerID"
    local sid = 0
    local pid = 0
    if pShuttle ~= nil then sid = SceneObject(pShuttle):getObjectID() end
    if (sid == nil or sid == 0) and shuttleIdStr and shuttleIdStr ~= "" then
        -- Parse shuttleID and optional playerID
        local parts = string.split(shuttleIdStr, ",")
        if parts and parts[1] then sid = tonumber(parts[1]) or 0 end
        if parts and parts[2] then pid = tonumber(parts[2]) or 0 end
    end
    if sid == nil or sid == 0 then self:_log("failsafeCleanup: no shuttle id; nothing to do"); return end

    local count = readData(sid .. ":gcwAmbushRebels:childCount") or 0
    for i = 1, count do
        local mid = readData(sid .. ":gcwAmbushRebels:child:" .. i)
        if mid and mid ~= 0 then
            local pm = getSceneObject(tonumber(mid))
            if pm ~= nil then
                pcall(function() SceneObject(pm):destroyObjectFromWorld() end)
                pcall(function() SceneObject(pm):destroyObjectFromDatabase() end)
            end
            deleteData(sid .. ":gcwAmbushRebels:child:" .. i)
        end
    end
    deleteData(sid .. ":gcwAmbushRebels:childCount")

    local pS = pShuttle; if pS == nil then pS = getSceneObject(sid) end
    if pS ~= nil then
        self:cleanShuttleOnly(pS, tostring(pid))
    else
        deleteData(sid .. ":gcwAmbushRebels:active")
        deleteData(sid .. ":gcwAmbushRebels:caller")
        deleteData(sid .. ":gcwAmbushRebels:alive")
        deleteData(sid .. ":gcwAmbushRebels:rewarded")
        deleteData(sid .. ":gcwAmbushRebels:hdg")

        -- Decrement if we're manually cleaning up
        self:decrementAmbushCount()
    end

    -- Clear the encounter_active flag if we have the player ID
    if pid ~= 0 then
        deleteData(pid .. ":gcwAmbushRebels:encounter_active")
    end

    self:_log("failsafeCleanup: encounter despawned after timeout")
end

-- ========= Per-player loop =========
local function isOvert(pPlayer)
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if pGhost ~= nil and PlayerObject(pGhost).isOvert ~= nil then return PlayerObject(pGhost):isOvert() end
    return true
end
local function armKey(pid) return pid .. ":gcwAmbushRebels:armed" end

function GCWRankedAmbushRebels:onPlayerLoggedIn(pPlayer)
    if not self.trigger.autoForRebels or not validPlayer(pPlayer) then return end
    local pid = pidOf(pPlayer)
    if readData(armKey(pid)) == 1 then return end
    writeData(armKey(pid), 1)
    local delay = randBetween(self.trigger.firstDelayMin, self.trigger.firstDelayMax)
    self:_log(string.format("onLogin: arming in %ds (opted=%s sideOK=%s)",
        delay, tostring(self:isOptedIn(pPlayer)), tostring(CreatureObject(pPlayer):isRebel())))
    self:_sched(pPlayer, delay, "first arm")
end

function GCWRankedAmbushRebels:onPlayerLoggedOut(pPlayer)
    if validPlayer(pPlayer) then deleteData(armKey(pidOf(pPlayer))) end
end

function GCWRankedAmbushRebels:ambushTick(pPlayer, pParam)
    if not validPlayer(pPlayer) then
        local oid = tonumber(pParam or "0") or 0
        if oid ~= 0 then
            local p = getSceneObject(oid)
            if validPlayer(p) then
                self:_log(string.format("ambushTick: recovered player ptr from oid=%s", tostring(oid)))
                pPlayer = p
            end
        end
    end
    if not validPlayer(pPlayer) then
        self:_log("ambushTick: player pointer invalid; rescheduling short retry")
        self:_sched(nil, self.trigger.retryIfNotReady, "player_lost")
        return
    end

    -- Hard stop if opted-out: do NOT reschedule
    if not self:isOptedIn(pPlayer) then
        deleteData(armKey(pidOf(pPlayer)))
        self:_log("ambushTick: opted-out -> stopping loop")
        return
    end

    local co   = CreatureObject(pPlayer)
    local zone = SceneObject(pPlayer):getZoneName()

    -- ===== JK-style location gate: block indoors & in NPC cities (Encounter pre-check). :contentReference[oaicite:3]{index=3}
    -- Block while inside a building/interior cell
    local okParent, parentId = pcall(function() return SceneObject(pPlayer):getParentID() end)
    if okParent and parentId ~= 0 then
        self:_log("tick: deferred while in building")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "building")
        return
    end
    -- Block inside NPC cities (use WORLD coords for region lookup)
    local wx, wy = SceneObject(pPlayer):getWorldPositionX(), SceneObject(pPlayer):getWorldPositionY()
    local inCity = false
    local okCity, pCity = pcall(getCityRegionAt, zone, wx, wy)
    if okCity and pCity then
        local cr = CityRegion(pCity)
        local okClient, isClient = pcall(function() return cr:isClientRegion() end)
        inCity = okClient and isClient or false
    end
    if inCity then
        self:_log("tick: deferred in NPC city")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "npc_city")
        return
    end
    -- ===== end gate =====

    local sideOK  = co:isRebel()
    local overtOK = (not self.trigger.requireOvert) or isOvert(pPlayer)
    if not (sideOK and overtOK) then
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "not_eligible")
        return
    end

    self:startHere(pPlayer)
    local nextDelay = randBetween(self.trigger.cooldownMin, self.trigger.cooldownMax)
    self:_sched(pPlayer, nextDelay, "cooldown")
end

function GCWRankedAmbushRebels:stopForPlayer(pPlayer)
    if not validPlayer(pPlayer) then return end
    deleteData(armKey(pidOf(pPlayer)))
    msg(self, pPlayer, "GCW courier duty stood down. (Ambush loop stopped.)")
end

registerScreenPlay("GCWRankedAmbushRebels", true)