-- ==========================================================
-- GCW Ranked Ambush (Lambda + Rebel auto-start)
-- MIRRORS CRACKDOWN TIMING: land 34s, ramp 19s, then deploy.
-- Notes:
--   • We DO NOT shorten descend/ramp, even in debug. That matches the working crackdown screenplay.
--   • Mobiles use your core's X,Z,Y order: spawnMobile(planet, tpl, 0, x, yCoord, height, headingDeg, ...)
-- ==========================================================

GCWRankedAmbush = ScreenPlay:new {
    numberOfActs   = 1,
    screenplayName = "GCWRankedAmbush",

    debug = {
        enabled        = true,
        notifyPlayer   = true,
        -- fastTimings WILL NOT touch cinematic times; only affects per-player cadence below.
        fastTimings    = true,
        spawnMarkers   = false,
        verboseSpawns  = true,
    },

    -- Per-player trigger/cadence (safe to speed up for testing)
    trigger = {
        autoForRebels    = true,
        requireOvert     = false,
        firstDelayMin    = 60,
        firstDelayMax    = 180,
        cooldownMin      = 2700,  -- 45m
        cooldownMax      = 7200,  -- 120m
        retryIfNotReady  = 120,
    },

    -- Shuttle & squad
    lambdaTemplate = "object/creature/npc/theme_park/lambda_shuttle.iff",

    -- Priority-ordered fallbacks per slot (so a missing name won't kill the drop)
    squadCandidates = {
        { "stormtrooper_squad_leader", "stormtrooper_captain", "imperial_army_captain", "stormtrooper" },
        { "stormtrooper", "stormtrooper_rifleman", "imperial_army_trooper" },
        { "stormtrooper_rifleman", "stormtrooper", "imperial_army_trooper" },
        { "stormtrooper_medic", "stormtrooper", "imperial_medic" },
        { "stormtrooper_sniper", "stormtrooper_rifleman", "stormtrooper" },
        { "stormtrooper", "stormtrooper_rifleman", "imperial_army_trooper" },
        { "storm_commando", "stormtrooper_commando", "stormtrooper" },
        { "stormtrooper", "stormtrooper_rifleman", "imperial_army_trooper" },
    },

    -- === CRACKDOWN-CANON CINEMATIC TIMINGS (DO NOT ALTER IN DEBUG) ===
    t_descend     = 34,  -- shuttle approach/descend before ramp pose
    t_ramp        = 19,  -- ramp open + settle
    t_buffer      = 2,   -- small safety buffer used by crackdown before spawn logic
    t_deployExtra = 0,   -- keep 0 to mirror exactly; adjust only if you want a later drop
    t_linger      = 30,  -- shuttle stays after deploy
    t_cleanup     = 8*60*60,

    -- Placement
    spawnRadiusMin = 25,
    spawnRadiusMax = 40,
    rampForward    = 7.5,

    markerTemplate = "object/tangible/poi/poi_marker_large.iff",
    fileTag        = "[GCW Ambush λ]"
}

-- ===== Utilities =====

local function msg(self, pPlayer, text)
    if not self.debug.enabled or not self.debug.notifyPlayer then return end
    if pPlayer ~= nil then CreatureObject(pPlayer):sendSystemMessage(self.fileTag .. " " .. text) end
end

-- getTerrainHeight(planet, x, yCoord) → returns height
local function groundYAt(planet, x, yCoord, fallbackY)
    local fn = rawget(_G, "getTerrainHeight")
    if type(fn) == "function" then
        local ok, h = pcall(fn, planet, x, yCoord)
        if ok and type(h) == "number" then return h end
        ok, h = pcall(fn, x, yCoord)
        if ok and type(h) == "number" then return h end
    end
    return fallbackY or 0
end

local function basis(hdgDeg)
    local c = math.cos(math.rad(hdgDeg))
    local s = math.sin(math.rad(hdgDeg))
    return function(f) return c*f, s*f end, function(r) return -s*r, c*r end
end

local function validPlayer(p) return p ~= nil and SceneObject(p):isPlayerCreature() end
local function randBetween(a,b) if b<=a then return a end return a + getRandomNumber(0, b-a) end

-- ===== Landing pad selection =====

function GCWRankedAmbush:pickLandingAround(pPlayer)
    local co = CreatureObject(pPlayer)
    local px, py, pz = co:getPositionX(), co:getPositionY(), co:getPositionZ() -- py=HEIGHT, pz=YCoord
    local r   = getRandomNumber(self.spawnRadiusMin, self.spawnRadiusMax)
    local ang = getRandomNumber(0, 359)
    local sx  = px + r * math.cos(math.rad(ang))
    local sz  = pz + r * math.sin(math.rad(ang)) -- YCoord
    local hdg = (ang + 180) % 360                -- face player
    local sy  = groundYAt(SceneObject(pPlayer):getZoneName(), sx, sz, py) -- HEIGHT
    return sx, sy, sz, hdg -- (x, height, yCoord, heading)
end

-- ===== Lifecycle =====

function GCWRankedAmbush:start()
    -- Allow FAST testing for cadence only (NEVER the cinematic times)
    if self.debug.fastTimings then
        self.trigger.firstDelayMin   = 3
        self.trigger.firstDelayMax   = 5
        self.trigger.cooldownMin     = 30
        self.trigger.cooldownMax     = 45
        self.trigger.retryIfNotReady = 10
    end
    registerScreenPlay(self.screenplayName, true)
end

function GCWRankedAmbush:startHere(pPlayer)
    if not validPlayer(pPlayer) then return end

    local planet = SceneObject(pPlayer):getZoneName()
    local sx, sy, sz, hdg = self:pickLandingAround(pPlayer)

    -- spawnSceneObject expects (x, yCoord, height, ...)
    local pShuttle = spawnSceneObject(planet, self.lambdaTemplate, sx, sz, sy, 0, math.rad(hdg))
    if pShuttle == nil then
        msg(self, pPlayer, "Failed to spawn Lambda shuttle.")
        return
    end

    local shuttleID = SceneObject(pShuttle):getObjectID()
    writeData(shuttleID .. ":gcwAmbush:active", 1)
    writeData(shuttleID .. ":gcwAmbush:hdg", hdg)

    CreatureObject(pShuttle):setCustomObjectName("Lambda Shuttle")
    CreatureObject(pShuttle):setPosture(UPRIGHT)

    msg(self, pPlayer, string.format("Shuttle inbound (%.1fm, heading %d°).", SceneObject(pShuttle):getDistanceTo(pPlayer), hdg))

    -- === CRACKDOWN TIMELINE: DO NOT SHORTEN ===
    -- 1) After 34s, flip to PRONE (landed state/ramp)
    createEvent(self.t_descend * 1000, self.screenplayName, "handleShuttlePosture", pShuttle, "")
    -- 2) After 34 + 19 (+ small buffer) (+ optional extra), deploy squad
    local deployAtMs = (self.t_descend + self.t_ramp + self.t_buffer + self.t_deployExtra) * 1000
    createEvent(deployAtMs, self.screenplayName, "deploySquad", pShuttle, tostring(SceneObject(pPlayer):getObjectID()))
    -- 3) After deploy + linger, depart
    local despawnAtMs = deployAtMs + (self.t_linger * 1000)
    createEvent(despawnAtMs, self.screenplayName, "despawnSequence", pShuttle, "")

    -- Absolute failsafe
    createEvent(self.t_cleanup * 1000, self.screenplayName, "failsafeCleanup", pShuttle, "")
end

function GCWRankedAmbush:handleShuttlePosture(pShuttle)
    if pShuttle == nil then return end
    CreatureObject(pShuttle):setPosture(PRONE) -- landed/ ramp open
end

-- Spawn chosen template for a slot using X,Z,Y ordering
local function spawnSlotXZY(self, planet, list, x, yHeight, zCoord, hdg, cell, mood)
    for _, name in ipairs(list) do
        local p = spawnMobile(planet, name, 0, x, zCoord, yHeight, hdg, cell, mood) -- (x, yCoord, height, degrees)
        if p ~= nil then
            if self.debug.verboseSpawns then
                print(string.format("GCW-Ambush: spawned %s at (X=%d, YCoord=%d, Height=%d) hdg %d",
                    name, math.floor(x), math.floor(zCoord), math.floor(yHeight), hdg))
            end
            return p
        end
    end
    if self.debug.verboseSpawns then
        print(string.format("GCW-Ambush: all fallbacks failed at (X=%d, YCoord=%d, Height=%d)", math.floor(x), math.floor(zCoord), math.floor(yHeight)))
    end
    return nil
end

function GCWRankedAmbush:deploySquad(pShuttle, callerIdStr)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbush:active") ~= 1 then return end

    local planet = SceneObject(pShuttle):getZoneName()
    local sx = SceneObject(pShuttle):getPositionX()
    local sy = SceneObject(pShuttle):getPositionY() -- HEIGHT
    local sz = SceneObject(pShuttle):getPositionZ() -- YCoord
    local hdg = readData(shuttleID .. ":gcwAmbush:hdg")

    local fwd, right = basis(hdg)
    local baseX, baseYCoord = fwd(self.rampForward + 2.5); baseX, baseYCoord = sx + baseX, sz + baseYCoord

    local slots = {
        {  0.0,  0.0 }, {  2.5,  0.4 }, { -2.5,  0.4 },
        {  1.2, -2.0 }, { -1.2, -2.0 },
        {  3.6, -1.6 }, { -3.6, -1.6 },
        {  0.0, -4.0 },
    }

    local spawned = 0
    for i=1, #self.squadCandidates do
        local dxF, dyF = fwd(slots[i][2])
        local dxR, dyR = right(slots[i][1])

        local x       = baseX + dxF + dxR
        local yCoord  = baseYCoord + dyF + dyR
        local height  = groundYAt(planet, x, yCoord, sy)

        if self.debug.spawnMarkers then
            pcall(function() spawnSceneObject(planet, self.markerTemplate, x, yCoord, height, 0, 0) end)
        end

        local pMobile = spawnSlotXZY(self, planet, self.squadCandidates[i], x, height, yCoord, hdg, 0, "")
        if pMobile ~= nil then
            spawned = spawned + 1
            if CreatureObject ~= nil and CreatureObject(pMobile) ~= nil then
                local co = CreatureObject(pMobile)
                if co.setPvpStatusBitmask ~= nil then co:setPvpStatusBitmask(1) end
            end
            if AiAgent ~= nil and AiAgent(pMobile) ~= nil and AiAgent(pMobile).setMovementState ~= nil then
                AiAgent(pMobile):setMovementState(AI_PATROLLING)
            end

            writeData(SceneObject(pMobile):getObjectID() .. ":gcwAmbush:parent", shuttleID)
            createObserver(CREATUREDESPAWNED, self.screenplayName, "onSquadDespawn", pMobile)
        end
    end

    if callerIdStr and callerIdStr ~= "" then
        local pCaller = getSceneObject(tonumber(callerIdStr))
        msg(self, pCaller, string.format("Squad deployed (%d/%d).", spawned, #self.squadCandidates))
        if spawned == 0 then msg(self, pCaller, "No mobiles spawned; verify template names exist in this fork.") end
    end
end

function GCWRankedAmbush:onSquadDespawn(pMobile)
    if pMobile == nil then return 0 end
    deleteData(SceneObject(pMobile):getObjectID() .. ":gcwAmbush:parent")
    return 1
end

function GCWRankedAmbush:despawnSequence(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    if readData(shuttleID .. ":gcwAmbush:active") ~= 1 then return end

    CreatureObject(pShuttle):setPosture(UPRIGHT) -- close ramp / prep to leave
    createEvent(6 * 1000, self.screenplayName, "cleanShuttleOnly", pShuttle, "")
end

function GCWRankedAmbush:cleanShuttleOnly(pShuttle)
    if pShuttle == nil then return end
    local shuttleID = SceneObject(pShuttle):getObjectID()
    SceneObject(pShuttle):destroyObjectFromWorld()
    deleteData(shuttleID .. ":gcwAmbush:active")
    deleteData(shuttleID .. ":gcwAmbush:hdg")
end

function GCWRankedAmbush:failsafeCleanup(pShuttle)
    if pShuttle == nil then return end
    self:cleanShuttleOnly(pShuttle)
end

-- ===== Rebel Auto-Start (per-player cadence) =====

local function playerKey(pPlayer) return tostring(SceneObject(pPlayer):getObjectID()) end
local function timerKey(pid) return pid .. ":gcwAmbush:timer" end

local function isOvert(pPlayer)
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if pGhost ~= nil and PlayerObject(pGhost).isOvert ~= nil then
        return PlayerObject(pGhost):isOvert()
    end
    return true
end

function GCWRankedAmbush:onPlayerLoggedIn(pPlayer)
    if not self.trigger.autoForRebels or not validPlayer(pPlayer) then return end
    local pid = playerKey(pPlayer)
    if readData(timerKey(pid)) == 1 then return end
    writeData(timerKey(pid), 1)

    local delay = randBetween(self.trigger.firstDelayMin, self.trigger.firstDelayMax)
    if self.debug.fastTimings then delay = randBetween(3,5) end
    createEvent(delay * 1000, self.screenplayName, "ambushTick", pPlayer, "")
end

function GCWRankedAmbush:onPlayerLoggedOut(pPlayer)
    if not validPlayer(pPlayer) then return end
    deleteData(timerKey(playerKey(pPlayer)))
end

function GCWRankedAmbush:ambushTick(pPlayer)
    if not validPlayer(pPlayer) then return end

    local co = CreatureObject(pPlayer)
    local ready = co:isRebel()
    if ready and self.trigger.requireOvert then
        ready = isOvert(pPlayer)
    end

    if ready then
        self:startHere(pPlayer)
        local nextDelay = randBetween(self.trigger.cooldownMin, self.trigger.cooldownMax)
        if self.debug.fastTimings then nextDelay = randBetween(30,45) end
        createEvent(nextDelay * 1000, self.screenplayName, "ambushTick", pPlayer, "")
    else
        local retry = self.trigger.retryIfNotReady or 120
        if self.debug.fastTimings then retry = 10 end
        createEvent(retry * 1000, self.screenplayName, "ambushTick", pPlayer, "")
    end
end

registerScreenPlay("GCWRankedAmbush", true)