-- ==========================================================
-- GCW Ranked Ambush — Imperials target (spawns REBEL custom squad)
-- Cinematic timing mirrored from crackdown; death observers; +2500 Imperial FP on full wipe.
-- Recruiter OPT-IN required: ScreenPlayState bit 1 on tag "GCW_Ambush_Imperials".
-- ==========================================================

GCWRankedAmbushImperials = ScreenPlay:new {
    numberOfActs   = 1,
    screenplayName = "GCWRankedAmbushImperials",

    debug = {
        enabled        = true,
        notifyPlayer   = true,
        fastTimings    = false,
        spawnMarkers   = false,
        verboseSpawns  = true,
    },

    trigger = {
        autoForImperials = true,
        requireOvert      = false,
        firstDelayMin     = 20,
        firstDelayMax     = 30,
        cooldownMin       = 30,  -- 45m
        cooldownMax       = 40,  -- 120m
        retryIfNotReady   = 30,   -- retry cadence if blocked/not eligible
    },

    shuttleTemplate   = "object/creature/npc/theme_park/lambda_shuttle.iff",
    rebelTrooper      = "ambush_rebel_commando",

    -- Cinematic
    t_descend     = 34,
    t_ramp        = 19,
    t_buffer      = 2,
    t_deployExtra = 0,
    t_linger      = 30,
    t_cleanup     = 8*60*60,

    -- Placement
    spawnRadiusMin = 25,
    spawnRadiusMax = 40,
    leashRadius    = 110,
    dropRadius     = 14,
    spawnSpread    = 6,
    dropOffset     = { x = -0.2, y = -6.5 },
    rampForward    = 7.5,

    markerTemplate = "object/tangible/poi/poi_marker_large.iff",
    fileTag        = "[GCW Ambush — vs Imperials]",

    optTag         = "GCW_Ambush_Imperials",

    FP_REWARD      = 2500,
    FP_SIDE        = "imperial",
    FP_RANGE       = 80
}

-- ========= Utilities =========
local function nowHHMMSS() if os and os.date then return os.date("%H:%M:%S") end return "" end
function GCWRankedAmbushImperials:_log(msg)
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

-- Always pass the player's OID as the event param and use it to recover if the pointer is lost.
function GCWRankedAmbushImperials:_sched(pPlayer, seconds, reason)
    local s = seconds or self.trigger.retryIfNotReady or 120
    local oid = pPlayer and SceneObject(pPlayer):getObjectID() or 0
    self:_log(string.format("schedule next tick: reason=%s delay=%ds oid=%s", tostring(reason), s, tostring(oid)))
    createEvent(s * 1000, self.screenplayName, "ambushTick", pPlayer, tostring(oid))
end

-- ========= Landing selection =========
function GCWRankedAmbushImperials:pickLandingAround(pPlayer)
    local co = CreatureObject(pPlayer)
    local px, py, pz = co:getPositionX(), co:getPositionY(), co:getPositionZ()
    local r   = getRandomNumber(self.spawnRadiusMin, self.spawnRadiusMax)
    local ang = getRandomNumber(0, 359)
    local sx  = px + r * math.cos(math.rad(ang))
    local sz  = pz + r * math.sin(math.rad(ang)) -- world YCoord
    local hdg = (ang + 180) % 360
    local sy  = groundYAt(SceneObject(pPlayer):getZoneName(), sx, sz, py)
    return sx, sy, sz, hdg
end

-- ========= Lifecycle =========
function GCWRankedAmbushImperials:start()
    self:_log("start(): screenplay registered & idle.")
end

function GCWRankedAmbushImperials:isOptedIn(pPlayer)
    return CreatureObject(pPlayer):hasScreenPlayState(1, self.optTag)
end

function GCWRankedAmbushImperials:startHere(pPlayer)
    if not validPlayer(pPlayer) or not self:isOptedIn(pPlayer) then return end
    local planet = SceneObject(pPlayer):getZoneName()
    local sx, sy, sz, hdg = self:pickLandingAround(pPlayer)

    -- Heading overload that works in your build
    local pShuttle = spawnSceneObject(planet, self.shuttleTemplate, sx, sz, sy, 0, math.rad(hdg))
    if pShuttle == nil then
        self:_log("startHere: FAILED to spawn Rebel shuttle scene object; will retry soon.")
        msg(self, pPlayer, "Failed to spawn Rebel shuttle (retrying).")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "spawn_shuttle_failed")
        return
    end

    local shuttleID = SceneObject(pShuttle):getObjectID()
    writeData(shuttleID .. ":gcwAmbushImperials:active", 1)
    writeData(shuttleID .. ":gcwAmbushImperials:hdg", hdg)

    CreatureObject(pShuttle):setCustomObjectName("Lambda Shuttle")
    CreatureObject(pShuttle):setPosture(UPRIGHT)

    local eta = self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra
    notify(pPlayer, string.format("Rebel shuttle inbound on your position (ETA %ds).", eta))
    self:_log(string.format("spawned shuttle %s at (%.1f, %.1f) hdg=%d, ETA=%ds",
        tostring(shuttleID), sx, sz, hdg, eta))

    createEvent(self.t_descend * 1000, self.screenplayName, "handleShuttlePosture", pShuttle, "")
    local deployAtMs  = eta * 1000
    local despawnAtMs = deployAtMs + (self.t_linger * 1000)
    createEvent(deployAtMs,  self.screenplayName, "deploySquad",     pShuttle, tostring(SceneObject(pPlayer):getObjectID()))
    createEvent(despawnAtMs, self.screenplayName, "despawnSequence", pShuttle, "")
    createEvent(self.t_cleanup * 1000, self.screenplayName, "failsafeCleanup", pShuttle, "")
end

function GCWRankedAmbushImperials:handleShuttlePosture(pShuttle)
    if pShuttle == nil then return end
    CreatureObject(pShuttle):setPosture(PRONE)
end

-- Mobile spawner (core is X, Z, Y for mobiles)
local function spawnSingleXZY(self, planet, template, x, height, yCoord, hdg, cell, mood)
    if self.debug.verboseSpawns then self:_log("spawn mobile: "..template) end
    return spawnMobile(planet, template, 0, x, yCoord, height, hdg, cell, mood)
end

function GCWRankedAmbushImperials:deploySquad(pShuttle, callerIdStr)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbushImperials:active") ~= 1 then return end

    local planet = SceneObject(pShuttle):getZoneName()
    local sx = SceneObject(pShuttle):getPositionX()
    local sy = SceneObject(pShuttle):getPositionY()  -- height
    local sz = SceneObject(pShuttle):getPositionZ()  -- yCoord
    local hdg = readData(shuttleID .. ":gcwAmbushImperials:hdg")

    local pCaller = nil
    if callerIdStr and callerIdStr ~= "" then pCaller = getSceneObject(tonumber(callerIdStr)) end
    if pCaller ~= nil then writeData(shuttleID .. ":gcwAmbushImperials:caller", tonumber(callerIdStr)) end
    writeData(shuttleID .. ":gcwAmbushImperials:rewarded", 0)

    local fwd, right = basis(hdg)
    local baseX, baseYCoord = fwd(self.rampForward + 2.5); baseX, baseYCoord = sx + baseX, sz + baseYCoord

    local slots = {
        {  0.0,  0.0 }, {  2.5,  0.4 }, { -2.5,  0.4 },
        {  1.2, -2.0 }, { -1.2, -2.0 },
        {  3.6, -1.6 }, { -3.6, -1.6 },
        {  0.0, -4.0 },
    }

    local EVT_CREATUREDEATH = rawget(_G, "CREATUREDEATH")  -- prefer immediate death event if available

    local spawned = 0
    for i=1,#slots do
        local dxF, dyF = fwd(slots[i][2]); local dxR, dyR = right(slots[i][1])
        local x = baseX + dxF + dxR
        local yCoord = baseYCoord + dyF + dyR
        local height = groundYAt(planet, x, yCoord, sy)

        local pMobile = spawnSingleXZY(self, planet, self.rebelTrooper, x, height, yCoord, hdg, 0, "")
        if pMobile ~= nil then
            spawned = spawned + 1
            local coMob = CreatureObject(pMobile)
            if coMob and coMob.setPvpStatusBitmask then coMob:setPvpStatusBitmask(1) end
            if pCaller ~= nil then forceAggroToTarget(pMobile, pCaller) end

            local mobOID = SceneObject(pMobile):getObjectID()
            writeData(mobOID .. ":gcwAmbushImperials:parent", shuttleID)

            if EVT_CREATUREDEATH ~= nil then
                createObserver(EVT_CREATUREDEATH, self.screenplayName, "onSquadMemberDied", pMobile)
            end
            createObserver(OBJECTDESTRUCTION, self.screenplayName, "onSquadMemberDied", pMobile)
        end
    end

    writeData(shuttleID .. ":gcwAmbushImperials:alive", spawned)
    self:_log(string.format("deploySquad: spawned=%d setAlive=%d (planet=%s) at %.1f,%.1f",
        spawned, spawned, tostring(planet), sx, sz))

    if pCaller ~= nil then
        msg(self, pCaller, string.format("Rebel squad deployed (%d/%d).", spawned, #slots))
    end
end

function GCWRankedAmbushImperials:onSquadMemberDied(pMob, pKiller)
    if pMob == nil then return 1 end
    local mobId   = SceneObject(pMob):getObjectID()
    local parentID = readData(mobId .. ":gcwAmbushImperials:parent")
    if not parentID or parentID == 0 then return 1 end

    local aliveKey  = parentID .. ":gcwAmbushImperials:alive"
    local rewardKey = parentID .. ":gcwAmbushImperials:rewarded"
    local callerKey = parentID .. ":gcwAmbushImperials:caller"

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

function GCWRankedAmbushImperials:despawnSequence(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbushImperials:active") ~= 1 then return end
    CreatureObject(pShuttle):setPosture(UPRIGHT)
    createEvent(6 * 1000, self.screenplayName, "cleanShuttleOnly", pShuttle, "")
end

function GCWRankedAmbushImperials:cleanShuttleOnly(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    deleteData(shuttleID .. ":gcwAmbushImperials:active")
    deleteData(shuttleID .. ":gcwAmbushImperials:caller")
    deleteData(shuttleID .. ":gcwAmbushImperials:alive")
    deleteData(shuttleID .. ":gcwAmbushImperials:rewarded")
    SceneObject(pShuttle):destroyObjectFromWorld()
    SceneObject(pShuttle):destroyObjectFromDatabase()
    self:_log("cleanShuttleOnly: shuttle removed")
end

function GCWRankedAmbushImperials:failsafeCleanup(pShuttle)
    if pShuttle ~= nil then self:cleanShuttleOnly(pShuttle) end
end

-- ========= Per-player loop =========
local function isOvert(pPlayer)
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if pGhost ~= nil and PlayerObject(pGhost).isOvert ~= nil then return PlayerObject(pGhost):isOvert() end
    return true
end
local function armKey(pid) return pid .. ":gcwAmbushImperials:armed" end
GCWRankedAmbushImperials._tickCount = {}

function GCWRankedAmbushImperials:onPlayerLoggedIn(pPlayer)
    if not self.trigger.autoForImperials or not validPlayer(pPlayer) then return end
    local pid = pidOf(pPlayer)
    if readData(armKey(pid)) == 1 then return end
    writeData(armKey(pid), 1)
    local delay = randBetween(self.trigger.firstDelayMin, self.trigger.firstDelayMax)
    self:_log(string.format("onLogin: arming in %ds (opted=%s sideOK=%s)",
        delay, tostring(self:isOptedIn(pPlayer)), tostring(CreatureObject(pPlayer):isImperial())))
    self:_sched(pPlayer, delay, "first arm")
end

function GCWRankedAmbushImperials:onPlayerLoggedOut(pPlayer)
    if validPlayer(pPlayer) then deleteData(armKey(pidOf(pPlayer))) end
end

function GCWRankedAmbushImperials:ambushTick(pPlayer, pParam)
    -- Recover pointer if it was lost
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

    local pid  = pidOf(pPlayer)
    local so   = SceneObject(pPlayer)
    local co   = CreatureObject(pPlayer)
    local zone = so:getZoneName() or "?"
    local x    = so:getWorldPositionX() or 0
    local y    = so:getWorldPositionY() or 0

    self._tickCount[pid] = (self._tickCount[pid] or 0) + 1
    self:_log(string.format("tick#%d: zone=%s x=%.1f y=%.1f", self._tickCount[pid], zone, x, y))

    -- Indoors restriction
    if so:getParentID() ~= 0 then
        self:_log("tick: deferred (indoors)")
        msg(self, pPlayer, "Ambush deferred (indoors).")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "indoors")
        return
    end

    -- NPC city restriction
    local inCity, cityName = false, "unknown"
    local okCity, pCity = pcall(getCityRegionAt, zone, x, y)
    if okCity and pCity then
        local cr = CityRegion(pCity)
        local okClient, isClient = pcall(function() return cr:isClientRegion() end)
        local okName, rname = pcall(function() return cr:getRegionName() end)
        inCity   = okClient and isClient or false
        cityName = (okName and rname) and rname or cityName
    end
    if inCity then
        self:_log(string.format("tick: deferred (NPC city: %s)", cityName))
        msg(self, pPlayer, "Ambush deferred (NPC city).")
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "npc_city")
        return
    end

    -- Eligibility (side + opt-in + overt if required)
    local opted   = self:isOptedIn(pPlayer)
    local sideOK  = co:isImperial()
    local overtOK = (not self.trigger.requireOvert) or isOvert(pPlayer)
    local eligible = opted and sideOK and overtOK

    self:_log(string.format("eligibility: opted=%s sideOK=%s overtOK=%s => %s",
        tostring(opted), tostring(sideOK), tostring(overtOK), tostring(eligible)))

    if not eligible then
        self:_sched(pPlayer, self.trigger.retryIfNotReady, "not_eligible")
        return
    end

    -- Fire encounter
    self:startHere(pPlayer)

    local nextDelay = randBetween(self.trigger.cooldownMin, self.trigger.cooldownMax)
    self:_sched(pPlayer, nextDelay, "cooldown")
end

registerScreenPlay("GCWRankedAmbushImperials", true)