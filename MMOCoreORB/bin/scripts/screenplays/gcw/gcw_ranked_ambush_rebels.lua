-- ==========================================================
-- GCW Ranked Ambush — Rebels target (spawns IMPERIAL custom squad)
-- Cinematic: 34s descend, 19s ramp, 2s buffer → deploy.
-- Uses OBJECTDESTRUCTION death observers and awards +2500 Rebel FP on full wipe.
-- Now shows only: "Ambush Squad Eliminated." (no FP amount) to avoid duplicate messaging.
-- ==========================================================

GCWRankedAmbushRebels = ScreenPlay:new {
    numberOfActs   = 1,
    screenplayName = "GCWRankedAmbushRebels",

    debug = {
        enabled        = true,
        notifyPlayer   = true,
        fastTimings    = false,
        spawnMarkers   = false,
        verboseSpawns  = true,
    },

    trigger = {
        autoForRebels   = true,
        requireOvert    = false,
        firstDelayMin   = 20,
        firstDelayMax   = 30,
        cooldownMin     = 2700,   -- 45m
        cooldownMax     = 7200,   -- 120m
        retryIfNotReady = 120,
    },

    shuttleTemplate = "object/creature/npc/theme_park/lambda_shuttle.iff",
    imperialTrooper = "ambush_imperial_storm_commando",

    -- cinematic timings
    t_descend     = 34,
    t_ramp        = 19,
    t_buffer      = 2,
    t_deployExtra = 0,
    t_linger      = 30,
    t_cleanup     = 8*60*60,

    -- placement
    spawnRadiusMin = 25,
    spawnRadiusMax = 40,
    rampForward    = 7.5,

    markerTemplate = "object/tangible/poi/poi_marker_large.iff",
    fileTag        = "[GCW Ambush — vs Rebels]",

    -- reward
    FP_REWARD      = 2500,
    FP_SIDE        = "rebel",     -- players are Rebel here; they kill Imperials
    FP_RANGE       = 80
}

-- ===== Utilities =====
local function msg(self, pPlayer, text)
    if not self.debug.enabled or not self.debug.notifyPlayer or pPlayer == nil then return end
    CreatureObject(pPlayer):sendSystemMessage(self.fileTag .. " " .. text)
end
local function notify(pPlayer, text)
    if pPlayer ~= nil then CreatureObject(pPlayer):sendSystemMessage(text) end
end
local function groundYAt(planet, x, yCoord, fallbackY)
    local fn = rawget(_G, "getTerrainHeight")
    if type(fn) == "function" then
        local ok, h = pcall(fn, planet, x, yCoord); if ok and type(h) == "number" then return h end
        ok, h = pcall(fn, x, yCoord);      if ok and type(h) == "number" then return h end
    end
    return fallbackY or 0
end
local function basis(hdgDeg)
    local c = math.cos(math.rad(hdgDeg)); local s = math.sin(math.rad(hdgDeg))
    return function(f) return c*f, s*f end, function(r) return -s*r, c*r end
end
local function validPlayer(p) return p ~= nil and SceneObject(p):isPlayerCreature() end
local function randBetween(a,b) if b<=a then return a end return a + getRandomNumber(0, b-a) end

-- immediate aggro helper
local function forceAggroToTarget(pMobile, pTarget)
    if pMobile == nil or pTarget == nil then return end
    pcall(function() AiAgent(pMobile):clearHateList() end)
    pcall(function() AiAgent(pMobile):addHate(pTarget, 10000) end)
    pcall(function() CreatureObject(pMobile):engageCombat(pTarget) end)
    pcall(function() AiAgent(pMobile):setFollowObject(pTarget) end)
    pcall(function() AiAgent(pMobile):setFollowTarget(pTarget) end)
end

-- award helper (group-aware; shows only a single "Ambush Squad Eliminated." to caller)
local function awardFactionPointsNearby(self, pPlayer, side, amount, range)
    if pPlayer == nil then return end
    local function grant(pTgt)
        if pTgt == nil or not SceneObject(pTgt):isPlayerCreature() then return end
        if not SceneObject(pTgt):isInRangeWithObject(pPlayer, range) then return end
        local ghost = CreatureObject(pTgt):getPlayerObject()
        if ghost ~= nil then PlayerObject(ghost):increaseFactionStanding(side, amount) end
    end
    local co = CreatureObject(pPlayer)
    if co.isGrouped and co:isGrouped() then
        for i = 0, co:getGroupSize() - 1 do grant(co:getGroupMember(i)) end
    else
        grant(pPlayer)
    end
    -- single, clean confirmation
    notify(pPlayer, "Ambush Squad Eliminated.")
end

-- ===== Landing pad selection =====
function GCWRankedAmbushRebels:pickLandingAround(pPlayer)
    local co = CreatureObject(pPlayer)
    local px, py, pz = co:getPositionX(), co:getPositionY(), co:getPositionZ()
    local r   = getRandomNumber(self.spawnRadiusMin, self.spawnRadiusMax)
    local ang = getRandomNumber(0, 359)
    local sx  = px + r * math.cos(math.rad(ang))
    local sz  = pz + r * math.sin(math.rad(ang)) -- YCoord
    local hdg = (ang + 180) % 360
    local sy  = groundYAt(SceneObject(pPlayer):getZoneName(), sx, sz, py)
    return sx, sy, sz, hdg
end

-- ===== Lifecycle =====
function GCWRankedAmbushRebels:start()
    registerScreenPlay(self.screenplayName, true)
end

function GCWRankedAmbushRebels:startHere(pPlayer)
    if not validPlayer(pPlayer) then return end
    local planet = SceneObject(pPlayer):getZoneName()
    local sx, sy, sz, hdg = self:pickLandingAround(pPlayer)

    local pShuttle = spawnSceneObject(planet, self.shuttleTemplate, sx, sz, sy, 0, math.rad(hdg))
    if pShuttle == nil then msg(self, pPlayer, "Failed to spawn Imperial shuttle."); return end

    local shuttleID = SceneObject(pShuttle):getObjectID()
    writeData(shuttleID .. ":gcwAmbushRebels:active", 1)
    writeData(shuttleID .. ":gcwAmbushRebels:hdg", hdg)

    CreatureObject(pShuttle):setCustomObjectName("Lambda Shuttle")
    CreatureObject(pShuttle):setPosture(UPRIGHT)

    local eta = self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra
    notify(pPlayer, string.format("Imperial shuttle inbound on your position (ETA %ds).", eta))
    msg(self, pPlayer, string.format("Imperial shuttle inbound (%.1fm, heading %d°).", SceneObject(pShuttle):getDistanceTo(pPlayer), hdg))

    createEvent(self.t_descend * 1000, self.screenplayName, "handleShuttlePosture", pShuttle, "")
    local deployAtMs  = (self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra) * 1000
    local despawnAtMs = deployAtMs + (self.t_linger * 1000)
    createEvent(deployAtMs,  self.screenplayName, "deploySquad",     pShuttle, tostring(SceneObject(pPlayer):getObjectID()))
    createEvent(despawnAtMs, self.screenplayName, "despawnSequence", pShuttle, "")
    createEvent(self.t_cleanup * 1000, self.screenplayName, "failsafeCleanup", pShuttle, "")
end

function GCWRankedAmbushRebels:handleShuttlePosture(pShuttle)
    if pShuttle == nil then return end
    CreatureObject(pShuttle):setPosture(PRONE)
end

-- spawner (X,Z,Y ordering for mobiles)
local function spawnSingleXZY(self, planet, template, x, height, yCoord, hdg, cell, mood)
    if self.debug.verboseSpawns then print("GCW-Ambush-Rebels: spawn " .. template) end
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

    local spawned = 0
    for i=1, #slots do
        local dxF, dyF = fwd(slots[i][2]); local dxR, dyR = right(slots[i][1])
        local x = baseX + dxF + dxR
        local yCoord = baseYCoord + dyF + dyR
        local height = groundYAt(planet, x, yCoord, sy)

        if self.debug.spawnMarkers then pcall(function() spawnSceneObject(planet, self.markerTemplate, x, yCoord, height, 0, 0) end) end

        local pMobile = spawnSingleXZY(self, planet, self.imperialTrooper, x, height, yCoord, hdg, 0, "")
        if pMobile ~= nil then
            spawned = spawned + 1
            if CreatureObject ~= nil and CreatureObject(pMobile) ~= nil then
                local co = CreatureObject(pMobile); if co.setPvpStatusBitmask ~= nil then co:setPvpStatusBitmask(1) end
            end
            if pCaller ~= nil then forceAggroToTarget(pMobile, pCaller) end

            local mobOID = SceneObject(pMobile):getObjectID()
            writeData(mobOID .. ":gcwAmbushRebels:parent", shuttleID)
            -- Death observer (Jedi Knight Visibility uses OBJECTDESTRUCTION)
            createObserver(OBJECTDESTRUCTION, self.screenplayName, "onSquadMemberDied", pMobile)
        end
    end

    writeData(shuttleID .. ":gcwAmbushRebels:alive", spawned)
    if pCaller ~= nil then
        msg(self, pCaller, string.format("Imperial squad deployed (%d/%d).", spawned, #slots))
        if spawned == 0 then msg(self, pCaller, "No mobiles spawned; verify template ‘" .. self.imperialTrooper .. "’ exists.") end
    end
end

-- Death handler
function GCWRankedAmbushRebels:onSquadMemberDied(pMob, pKiller)
    if pMob == nil then return 1 end
    local mobOID   = SceneObject(pMob):getObjectID()
    local parentID = readData(mobOID .. ":gcwAmbushRebels:parent")
    deleteData(mobOID .. ":gcwAmbushRebels:parent")
    if parentID == nil or parentID == 0 then return 1 end

    local aliveKey   = parentID .. ":gcwAmbushRebels:alive"
    local rewardKey  = parentID .. ":gcwAmbushRebels:rewarded"
    local callerKey  = parentID .. ":gcwAmbushRebels:caller"

    local alive = (readData(aliveKey) or 0) - 1
    if alive < 0 then alive = 0 end
    writeData(aliveKey, alive)

    if alive == 0 and readData(rewardKey) ~= 1 then
        writeData(rewardKey, 1)
        local callerId = readData(callerKey)
        if callerId ~= nil and callerId ~= 0 then
            local pCaller = getSceneObject(tonumber(callerId))
            if pCaller ~= nil then
                awardFactionPointsNearby(self, pCaller, self.FP_SIDE, self.FP_REWARD, self.FP_RANGE)
            end
        end
    end
    return 1
end

function GCWRankedAmbushRebels:despawnSequence(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbushRebels:active") ~= 1 then return end
    CreatureObject(pShuttle):setPosture(UPRIGHT)
    createEvent(6 * 1000, self.screenplayName, "cleanShuttleOnly", pShuttle, "")
end

function GCWRankedAmbushRebels:cleanShuttleOnly(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    SceneObject(pShuttle):destroyObjectFromWorld()
    deleteData(shuttleID .. ":gcwAmbushRebels:active")
    deleteData(shuttleID .. ":gcwAmbushRebels:hdg")
    deleteData(shuttleID .. ":gcwAmbushRebels:alive")
    deleteData(shuttleID .. ":gcwAmbushRebels:rewarded")
    deleteData(shuttleID .. ":gcwAmbushRebels:caller")
end

function GCWRankedAmbushRebels:failsafeCleanup(pShuttle)
    if pShuttle == nil then return end
    self:cleanShuttleOnly(pShuttle)
end

-- ===== Rebel Auto-Start =====
local function playerKey(pPlayer) return tostring(SceneObject(pPlayer):getObjectID()) end
local function timerKey(pid) return pid .. ":gcwAmbushRebels:timer" end
local function isOvert(pPlayer)
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if pGhost ~= nil and PlayerObject(pGhost).isOvert ~= nil then return PlayerObject(pGhost):isOvert() end
    return true
end

function GCWRankedAmbushRebels:onPlayerLoggedIn(pPlayer)
    if not self.trigger.autoForRebels or not validPlayer(pPlayer) then return end
    local pid = playerKey(pPlayer); if readData(timerKey(pid)) == 1 then return end
    writeData(timerKey(pid), 1)
    local delay = randBetween(self.trigger.firstDelayMin, self.trigger.firstDelayMax)
    createEvent(delay * 1000, self.screenplayName, "ambushTick", pPlayer, "")
end

function GCWRankedAmbushRebels:onPlayerLoggedOut(pPlayer)
    if not validPlayer(pPlayer) then return end
    deleteData(timerKey(playerKey(pPlayer)))
end

function GCWRankedAmbushRebels:ambushTick(pPlayer)
    if not validPlayer(pPlayer) then return end
    local co = CreatureObject(pPlayer)
    local ready = co:isRebel()
    if ready and self.trigger.requireOvert then ready = isOvert(pPlayer) end

    if ready then
        self:startHere(pPlayer)
        local nextDelay = randBetween(self.trigger.cooldownMin, self.trigger.cooldownMax)
        createEvent(nextDelay * 1000, self.screenplayName, "ambushTick", pPlayer, "")
    else
        local retry = self.trigger.retryIfNotReady or 120
        createEvent(retry * 1000, self.screenplayName, "ambushTick", pPlayer, "")
    end
end

registerScreenPlay("GCWRankedAmbushRebels", true)