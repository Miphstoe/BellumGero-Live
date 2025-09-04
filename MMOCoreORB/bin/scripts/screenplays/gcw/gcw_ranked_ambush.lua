local Logger = require("utils.logger")

-- ==========================================================
-- GCW Ranked Ambush (Lambda-only; CityControl timings; terrain-height aware)
-- Land (34s) → posture flip → wait (19s) → deploy → linger → fly-off → remove
-- Shuttle life is independent of troop survival.
-- Spawning fixed: correct X,Z,Y order for SWGEmu spawnMobile.
-- ==========================================================
GCWRankedAmbush = ScreenPlay:new {
    numberOfActs   = 1,
    screenplayName = "GCWRankedAmbush",

    -- ===== Debug controls =====
    debug = {
        enabled             = true,     -- keep on while iterating
        fastCooldowns       = true,     -- shorten encounter cooldowns (not the cinematic!)
        bypassMinRank       = true,     -- ignore minRank (still requires non-neutral)
        forceAttackers      = nil,      -- nil | "imperial" | "rebel"
        forceBucketIndex    = nil,      -- nil or 1..#buckets
        chatSpam            = true,     -- [GCW DEBUG] messages to player
        forceFullCinematic  = true,     -- use full CityControl timing (34s + 19s + buffer)
        logSpawnAttempts    = true,     -- print each candidate tried for a mob
        forceSimpleMobs     = true,     -- ✅ use known-good templates (stormtrooper/rebel_trooper)
        simpleCount         = 6,        -- # of attackers when forceSimpleMobs=true
        simpleRolesAsArc    = true,     -- lay them out in the ramp arc (not at player)
        flyOffMode          = "auto",   -- "auto" | "ai" | "teleport" | "static"
    },

    -- ===== Eligibility / cadence =====
    minRank              = 3,
    cooldownMinSec       = 45 * 60,
    cooldownMaxSec       = 120 * 60,
    loginGraceSec        = 90,
    retryWhenNotEligible = 5 * 60,

    -- ===== Geometry / placement =====
    spawnRadiusMin       = 110,     -- pad ~110–150m away (CityControl feel)
    spawnRadiusMax       = 150,
    shuttlePadOffset     = 0.6,     -- keep shuttle just above ground to avoid clipping

    -- Ambusher (mob) despawn safety (not shuttle cinematic life)
    mobDespawnSec        = 10 * 60,

    -- ===== CityControl/Contraband timings (Lambda) =====
    approachMsFull       = 34000,   -- wait before flip
    rampMsLambdaFull     = 19000,   -- after flip, wait before deploy
    landingBufferFull    = 2000,    -- safety after ramp before deploy
    lingerMsFull         = 8000,    -- linger before takeoff
    departMsFull         = 10000,   -- departure window (stepper duration)

    -- Debug timings (visible but faster)
    approachMsDebug      = 8000,
    rampMsDebug          = 8000,
    landingBufferDebug   = 1500,
    lingerMsDebug        = 4000,
    departMsDebug        = 3000,

    -- ===== Fly-off profile =====
    flyOffTotalDistance  = 120,     -- meters forward during departure
    flyOffTotalAltitude  = 50,      -- meters up during departure
    flyOffSteps          = 10,      -- number of motion ticks
    flyOffMinIntervalMs  = 500,     -- per-step min interval

    -- Troop placement arc relative to shuttle heading
    rampForward          = 6.0,
    arcRadius            = 4.0,
    arcRows              = 2,

    -- Lambda for BOTH sides (mirrors contraband screenplay)
    lambdaTemplate       = "object/creature/npc/theme_park/lambda_shuttle.iff",

    -- Simple, known-good templates for debug/bring-up
    simpleRoleTemplates = {
        rebel    = "rebel_trooper",
        imperial = "stormtrooper",
    },

    -- Vanilla-only candidates (used when forceSimpleMobs=false)
    roleCandidates = {
        rebel = {
            trooper  = { "rebel_trooper", "rebel_scout", "rebel_commando" },
            officer  = { "rebel_warrant_officer_i", "rebel_first_lieutenant", "rebel_sergeant" },
            sniper   = { "rebel_commando", "fbase_rebel_rifleman", "rebel_scout" },
            commando = { "rebel_commando", "rebel_trooper" },
            medic    = { "rebel_medic", "rebel_trooper" },
        },
        imperial = {
            trooper  = { "stormtrooper", "stormtrooper_rifleman", "crackdown_stormtrooper" },
            officer  = { "stormtrooper_captain", "stormtrooper_squad_leader", "imperial_first_lieutenant" },
            sniper   = { "stormtrooper_sniper", "crackdown_stormtrooper_sniper", "stormtrooper_rifleman" },
            commando = { "stormtrooper_commando", "crackdown_stormtrooper_commando", "stormtrooper" },
            medic    = { "stormtrooper_medic", "crackdown_stormtrooper_medic", "stormtrooper" },
        }
    },

    -- Rank buckets (rank <= maxRank)
    buckets = {
        { maxRank = 2,   points = 150, comp = { {role="trooper", n=3} } },
        { maxRank = 4,   points = 225, comp = { {role="trooper", n=4}, {role="officer", n=1} } },
        { maxRank = 6,   points = 300, comp = { {role="trooper", n=4}, {role="sniper", n=1}, {role="officer", n=1} } },
        { maxRank = 8,   points = 375, comp = { {role="trooper", n=4}, {role="sniper", n=1}, {role="commando", n=1}, {role="officer", n=1} } },
        { maxRank = 100, points = 450, comp = { {role="trooper", n=5}, {role="sniper", n=1}, {role="commando", n=1}, {role="medic", n=1}, {role="officer", n=1} } },
    },

    taunts = {
        imperial = { "Target acquired. Eliminate!", "By order of the Empire!", "Rebel contact confirmed. Move!", "For the Emperor!" },
        rebel    = { "Imperial scum, this is for Alderaan!", "Eyes up! Contact!", "For the Alliance!", "Stay sharp—go, go!" }
    }
}

registerScreenPlay("GCWRankedAmbush", true)

-- ===== util / state keys =====
local function now() return getTimestamp() end
local function toNum(v) local n = tonumber(v) return n or 0 end
local function randBetween(a,b) return getRandomNumber(a,b) end

local function K(pid, s) return "GCWA:" .. s .. ":" .. pid end
local function key_next(pid)     return K(pid,"next") end
local function key_active(pid)   return K(pid,"active") end
local function key_shuttle(pid)  return K(pid,"shuttle") end
local function key_alive(pid)    return K(pid,"alive") end
local function key_mob(pid,i)    return K(pid, "mob:"..i) end
local function key_lx(pid)       return K(pid,"lx") end
local function key_ly(pid)       return K(pid,"ly") end
local function key_lz(pid)       return K(pid,"lz") end
local function key_hdg(pid)      return K(pid,"hdg") end
local function key_side(pid)     return K(pid,"side") end
local function key_phase(pid)    return K(pid,"phase") end -- approach|flipped|landed|deployed|departing|departed
local function key_flySteps(pid) return K(pid,"flysteps") end
local function key_flyInt(pid)   return K(pid,"flyint") end
local function key_flyMode(pid)  return K(pid,"flymode") end

local function msg(self, pPlayer, text)
    if not self.debug.enabled or not self.debug.chatSpam or pPlayer == nil then return end
    local co = CreatureObject(pPlayer)
    if co and co.sendSystemMessage then co:sendSystemMessage("[GCW DEBUG] " .. text) end
end

-- Terrain height helper (robust to different cores; falls back to given Y)
local function groundYAt(planet, x, z, fallbackY)
    local fn = rawget(_G, "getTerrainHeight")
    if type(fn) == "function" then
        local ok, h = pcall(fn, planet, x, z)
        if ok and type(h) == "number" then return h end
        ok, h = pcall(fn, x, z) -- some cores expose (x,z) signature
        if ok and type(h) == "number" then return h end
    end
    return fallbackY or 0
end

local function playerFactionString(pPlayer)
    local c = CreatureObject(pPlayer)
    if c:isImperial() then return "imperial" end
    if c:isRebel() then return "rebel" end
    return "neutral"
end

local function isEligible(self, pPlayer)
    if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then return false end
    local co = CreatureObject(pPlayer)
    if co:isNeutral() then return false end
    if self.debug.enabled and self.debug.bypassMinRank then return true end
    return co:getFactionRank() >= self.minRank
end

local function bucketFor(self, rank)
    for i,b in ipairs(self.buckets) do
        if rank <= b.maxRank then return b, i end
    end
    return self.buckets[#self.buckets], #self.buckets
end

-- Choose a landing pad around the player and use the pad's ground height (not player's Y)
local function pickLandingAround(self, planet, pPlayer)
    local co = CreatureObject(pPlayer)
    local px, py, pz = co:getPositionX(), co:getPositionY(), co:getPositionZ()
    local r   = randBetween(self.spawnRadiusMin, self.spawnRadiusMax)
    local ang = randBetween(0, 359)
    local sx  = px + r * math.cos(math.rad(ang))
    local sz  = pz + r * math.sin(math.rad(ang))
    local hdg = (ang + 180) % 360 -- face roughly toward the player
    local gy  = groundYAt(planet, sx, sz, py)
    local sy  = gy + (self.shuttlePadOffset or 0)
    return sx, sy, sz, hdg
end

local function schedule(self, pPlayer, delay, reason)
    if pPlayer == nil then return end
    local pid = SceneObject(pPlayer):getObjectID()
    writeData(key_next(pid), now() + delay)
    createEvent(delay * 1000, self.screenplayName, "attempt", pPlayer, "")
    msg(self, pPlayer, ("Next attempt in %ds (%s)"):format(delay, reason or "?"))
end

local function clearState(pid)
    writeData(key_active(pid), 0)
    writeData(key_alive(pid),  0)
    writeData(key_shuttle(pid), 0)
    writeData(key_lx(pid), 0); writeData(key_ly(pid), 0); writeData(key_lz(pid), 0)
    writeData(key_hdg(pid), 0)
    writeStringData(key_side(pid), "")
    writeStringData(key_phase(pid), "")
    writeData(key_flySteps(pid), 0)
    writeData(key_flyInt(pid), 0)
    writeStringData(key_flyMode(pid), "")
end

-- Resolve timing profile (debug vs. full)
local function resolveTimings(self)
    local full = self.debug.forceFullCinematic or not self.debug.enabled
    return {
        approach = full and self.approachMsFull or self.approachMsDebug,
        ramp     = full and self.rampMsLambdaFull or self.rampMsDebug,
        buffer   = full and self.landingBufferFull or self.landingBufferDebug,
        linger   = full and self.lingerMsFull or self.lingerMsDebug,
        depart   = full and self.departMsFull or self.departMsDebug,
    }
end

-- ===== lifecycle =====
function GCWRankedAmbush:start()
    if self.debug.enabled and self.debug.fastCooldowns then
        self.cooldownMinSec = 8
        self.cooldownMaxSec = 15
        self.loginGraceSec  = 3
        self.retryWhenNotEligible = 5
    end
    Logger:log("[GCWA] screenplay loaded", LT_INFO)
end

function GCWRankedAmbush:onPlayerLoggedIn(pPlayer)
    if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then return end
    schedule(self, pPlayer, self.loginGraceSec, "login_grace")
end

function GCWRankedAmbush:attempt(pPlayer)
    if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()

    -- Do not start a new encounter if a shuttle is still present (let it depart first)
    if toNum(readData(key_shuttle(pid))) ~= 0 then
        schedule(self, pPlayer, 10, "shuttle_present")
        return 0
    end

    if toNum(readData(key_active(pid))) == 1 then return 0 end
    if not isEligible(self, pPlayer) then schedule(self, pPlayer, self.retryWhenNotEligible, "not_eligible") return 0 end

    local sideOfPlayer = playerFactionString(pPlayer)
    if sideOfPlayer == "neutral" then schedule(self, pPlayer, self.retryWhenNotEligible, "neutral") return 0 end

    -- Attackers are the opposite side; shuttle is ALWAYS Lambda
    local attackers = (self.debug.enabled and self.debug.forceAttackers) or ((sideOfPlayer == "imperial") and "rebel" or "imperial")
    writeStringData(key_side(pid), attackers)

    local planet = SceneObject(pPlayer):getZoneName()
    local sx, sy, sz, hdg = pickLandingAround(self, planet, pPlayer)
    msg(self, pPlayer, ("Landing point (X,Z,Y): (%.1f, %.1f, %.1f) hdg=%.0f"):format(sx, sz, sy, hdg))

    -- Spawn Lambda (X,Z,Y). Seed posture UPRIGHT like contraband screenplays.
    local pShuttle = spawnSceneObject(planet, self.lambdaTemplate, sx, sz, sy, 0, math.rad(hdg))
    if pShuttle == nil then schedule(self, pPlayer, 60, "spawn_failed") return 0 end

    writeData(key_active(pid), 1)
    writeData(key_shuttle(pid), SceneObject(pShuttle):getObjectID())
    writeData(key_lx(pid), sx); writeData(key_ly(pid), sy); writeData(key_lz(pid), sz)
    writeData(key_hdg(pid), hdg)

    CreatureObject(pShuttle):setPosture(UPRIGHT)
    CreatureObject(pShuttle):setCustomObjectName("Lambda Shuttle")
    writeStringData(key_phase(pid), "approach")

    local T = resolveTimings(self)

    createEvent(T.approach, self.screenplayName, "handleShuttlePosture", pPlayer, "")

    -- Safety cleanup after whole cinematic (+buffer)
    local safetySec = math.ceil((T.approach + T.ramp + T.buffer + T.linger + T.depart) / 1000) + 30
    createEvent(safetySec * 1000, self.screenplayName, "timeoutCleanup", pPlayer, "")
    return 0
end

-- Posture tick → flip to PRONE then deploy after ramp+buffer
function GCWRankedAmbush:handleShuttlePosture(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()
    local soid = toNum(readData(key_shuttle(pid)))
    local pShuttle = (soid ~= 0) and getSceneObject(soid) or nil
    if pShuttle == nil then return 0 end

    local T = resolveTimings(self)

    CreatureObject(pShuttle):setPosture(PRONE)
    writeStringData(key_phase(pid), "flipped")
    createEvent(T.ramp + T.buffer, self.screenplayName, "deploySquad", pPlayer, "")
    msg(self, pPlayer, "Lambda touchdown…")
    return 0
end

-- ===== Spawn helpers =====
local function logSpawn(self, pPlayer, text)
    if self.debug.enabled and self.debug.logSpawnAttempts then msg(self, pPlayer, text) end
end

-- IMPORTANT: This function accepts px, py, pz (standard X,Y,Z)
-- but maps to spawnMobile(planet, tpl, 0, X, Z, Y, hdg, 0)
function GCWRankedAmbush:spawnOne(pid, planet, tpl, px, py, pz, hdg, pPlayer)
    if not tpl or tpl == "" then return nil end
    logSpawn(self, pPlayer, ("Trying template: %s @ (X,Z,Y)=(%.1f, %.1f, %.1f)"):format(tostring(tpl), px, pz, py))
    -- SWGEmu: spawnMobile(name, template, respawn, x, z, y, heading, cell)
    local pMob = spawnMobile(planet, tpl, 0, px, pz, py, hdg, 0)
    if pMob == nil then
        logSpawn(self, pPlayer, "  -> FAILED: " .. tostring(tpl))
        return nil
    end
    local idxKey = key_alive(pid) .. ":index"
    local idx = toNum(readData(idxKey)) + 1
    writeData(idxKey, idx)
    writeData(key_mob(pid, idx), SceneObject(pMob):getObjectID())
    createObserver(OBJECTDESTRUCTION, self.screenplayName, "onAmbusherDied", pMob)
    if pPlayer then CreatureObject(pMob):engageCombat(pPlayer) end
    createEvent(self.mobDespawnSec * 1000, self.screenplayName, "despawnMob", pMob, tostring(pid))
    return pMob
end

function GCWRankedAmbush:spawnFromCandidates(pid, planet, candidates, fallbackTpl, px, py, pz, hdg, pPlayer)
    if candidates then
        for _,tpl in ipairs(candidates) do
            local p = self:spawnOne(pid, planet, tpl, px, py, pz, hdg, pPlayer)
            if p ~= nil then return p end
        end
    end
    if fallbackTpl then
        return self:spawnOne(pid, planet, fallbackTpl, px, py, pz, hdg, pPlayer)
    end
    return nil
end

local function spawnArc(self, pid, planet, attackers, sx, sy, sz, hdg, pPlayer)
    local function fwd(d)   return math.cos(math.rad(hdg)) * d, math.sin(math.rad(hdg)) * d end
    local function right(d) return -math.sin(math.rad(hdg)) * d, math.cos(math.rad(hdg)) * d end

    local taunts = (attackers == "rebel") and self.taunts.rebel or self.taunts.imperial
    local didTaunt = false
    local spawned = 0
    local rowSpacing = 2.2
    local baseFwd = self.rampForward

    return function(candidates, fallbackTpl)
        local row  = math.floor(spawned / 5)
        local slot = spawned % 5
        local lateral = (slot - 2) * (self.arcRadius / 2)

        local fwdDist = baseFwd + row * rowSpacing
        local fx, fz = fwd(fwdDist)
        local rx, rz = right(lateral)

        local px = sx + fx + rx
        local pz = sz + fz + rz
        local py = sy

        local pMob = self:spawnFromCandidates(pid, planet, candidates, fallbackTpl, px, py, pz, hdg, pPlayer)
        if pMob and not didTaunt then
            spatialChat(pMob, taunts[randBetween(1, #taunts)])
            didTaunt = true
        end
        if pMob then
            spawned = spawned + 1
            logSpawn(self, pPlayer, ("  -> Spawned mob #%d at (X,Z,Y)=(%.1f, %.1f, %.1f) hdg=%.0f"):format(
                spawned, px, pz, py, hdg))
        end
        return pMob ~= nil
    end
end

function GCWRankedAmbush:deploySquad(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()

    local ph = readStringData(key_phase(pid))
    if ph ~= "flipped" and ph ~= "landed" then
        createEvent(1000, self.screenplayName, "deploySquad", pPlayer, "")
        return 0
    end
    writeStringData(key_phase(pid), "landed")

    local planet = SceneObject(pPlayer):getZoneName()
    local sx = tonumber(readData(key_lx(pid))) or 0
    local sy = tonumber(readData(key_ly(pid))) or 0
    local sz = tonumber(readData(key_lz(pid))) or 0
    local hdg = tonumber(readData(key_hdg(pid))) or 0

    sy = groundYAt(planet, sx, sz, sy) + (self.shuttlePadOffset or 0)

    local attackers = readStringData(key_side(pid))
    local rank = CreatureObject(pPlayer):getFactionRank()
    local bucket, idx = bucketFor(self, rank)
    if self.debug.enabled and self.debug.forceBucketIndex then
        idx = math.max(1, math.min(self.debug.forceBucketIndex, #self.buckets))
        bucket = self.buckets[idx]
    end

    msg(self, pPlayer, ("Deploying attackers=%s bucket=%d (rank=%d)"):format(attackers, idx, rank))

    local spawnedCount = 0

    if self.debug.forceSimpleMobs then
        local tpl = self.simpleRoleTemplates[attackers] or ((attackers == "rebel") and "rebel_trooper" or "stormtrooper")
        local placeOne = spawnArc(self, pid, planet, attackers, sx, sy, sz, hdg, pPlayer)
        for i = 1, (self.debug.simpleCount or 6) do
            local ok = placeOne({ tpl }, tpl)
            if ok then spawnedCount = spawnedCount + 1 end
        end
    else
        local roleMap = self.roleCandidates[attackers]
        local trooperFallback = roleMap and roleMap.trooper and roleMap.trooper[1] or ((attackers == "rebel") and "rebel_trooper" or "stormtrooper")
        local placeOne = spawnArc(self, pid, planet, attackers, sx, sy, sz, hdg, pPlayer)
        for _,part in ipairs(bucket.comp) do
            local candidates = roleMap and roleMap[part.role] or nil
            for i = 1, (part.n or 0) do
                local ok = placeOne(candidates, trooperFallback)
                if ok then spawnedCount = spawnedCount + 1 end
            end
        end
    end

    writeData(key_alive(pid), spawnedCount)
    writeData(key_alive(pid) .. ":index", spawnedCount)

    if spawnedCount <= 0 then
        msg(self, pPlayer, "No attackers spawned (check rebel/imperial template names). Shuttle will still depart normally.")
    else
        msg(self, pPlayer, ("Spawned %d attackers."):format(spawnedCount))
    end

    writeStringData(key_phase(pid), "deployed")

    local T = resolveTimings(self)
    createEvent(T.linger, self.screenplayName, "shuttleTakeoff", pPlayer, "")
    return 0
end

-- ===== Move helper: try several motion APIs (AI → teleport → setWorldPosition → warpTo → setPosition) =====
local function tryMoveShuttle(planet, pShuttle, nx, ny, nz)
    if AiAgent ~= nil then
        local aa = AiAgent(pShuttle)
        if aa and aa.setNextPosition then
            local ok = pcall(function() aa:setNextPosition(nx, nz, ny, 0) end) -- X, Z, Y
            if ok then return "ai" end
        end
    end
    local so = SceneObject(pShuttle)

    if so and so.teleport then
        local ok = pcall(function() so:teleport(nx, nz, ny) end)
        if ok then return "teleport" end
    end

    if so and so.setWorldPosition then
        local ok = pcall(function() so:setWorldPosition(nx, ny, nz) end)
        if ok then return "setWorldPosition(x,y,z)" end
        ok = pcall(function() so:setWorldPosition(nx, nz, ny) end)
        if ok then return "setWorldPosition(x,z,y)" end
    end

    if so and so.warpTo then
        local ok = pcall(function() so:warpTo(planet, nx, nz, ny) end)
        if ok then return "warpTo" end
    end

    if so and so.setPosition then
        local ok = pcall(function() so:setPosition(nx, ny, nz) end)
        if ok then return "setPosition(x,y,z)" end
        ok = pcall(function() so:setPosition(nx, nz, ny) end)
        if ok then return "setPosition(x,z,y)" end
    end

    return nil
end

-- ===== Shuttle departure (animated flight) =====
function GCWRankedAmbush:shuttleTakeoff(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()
    local soid = toNum(readData(key_shuttle(pid)))
    local pShuttle = (soid ~= 0) and getSceneObject(soid) or nil
    if pShuttle == nil then return 0 end

    writeStringData(key_phase(pid), "departing")
    CreatureObject(pShuttle):setPosture(UPRIGHT)
    msg(self, pPlayer, "Shuttle departing…")

    local T = resolveTimings(self)
    local steps = math.max(1, tonumber(self.flyOffSteps) or 10)
    local perStep = math.floor(T.depart / steps)
    if perStep < (self.flyOffMinIntervalMs or 500) then
        steps   = math.max(1, math.floor(T.depart / (self.flyOffMinIntervalMs or 500)))
        perStep = math.max((self.flyOffMinIntervalMs or 500), math.floor(T.depart / math.max(1, steps)))
    end
    writeData(key_flySteps(pid), steps)
    writeData(key_flyInt(pid),   perStep)

    local mode = self.debug.flyOffMode or "auto"
    writeStringData(key_flyMode(pid), mode)
    createEvent(perStep, self.screenplayName, "shuttleFlyStep", pPlayer, "")
    return 0
end

function GCWRankedAmbush:shuttleFlyStep(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()
    local soid = toNum(readData(key_shuttle(pid)))
    local pShuttle = (soid ~= 0) and getSceneObject(soid) or nil
    if pShuttle == nil then return 0 end

    local remaining = toNum(readData(key_flySteps(pid)))
    local interval  = toNum(readData(key_flyInt(pid)))
    if remaining <= 0 then self:removeShuttle(pPlayer) return 0 end

    local planet = SceneObject(pPlayer):getZoneName()
    local hdg   = tonumber(readData(key_hdg(pid))) or 0
    local rad   = math.rad(hdg)
    local totalD = tonumber(self.flyOffTotalDistance) or 120
    local totalH = tonumber(self.flyOffTotalAltitude) or 50
    local steps  = tonumber(self.flyOffSteps) or 10
    local dStep  = totalD / math.max(1, steps)
    local hStep  = totalH / math.max(1, steps)

    local so = SceneObject(pShuttle)
    local x  = so:getPositionX()
    local z  = so:getPositionZ()
    local y  = so:getPositionY()

    local nx = x + math.cos(rad) * dStep
    local nz = z + math.sin(rad) * dStep
    local ny = y + hStep

    local mode = readStringData(key_flyMode(pid))
    local used = nil

    if mode == "static" then
        used = "static"
    elseif mode == "teleport" then
        local res = tryMoveShuttle(planet, pShuttle, nx, ny, nz)
        if res == "teleport" then used = res end
    elseif mode == "ai" then
        local res = tryMoveShuttle(planet, pShuttle, nx, ny, nz)
        if res == "ai" then used = res end
    else
        used = tryMoveShuttle(planet, pShuttle, nx, ny, nz)
        if not used then used = "static" end
    end

    if used ~= "static" then
        msg(self, pPlayer, "Shuttle moving via " .. used)
    else
        msg(self, pPlayer, "Shuttle move tick (no motion API; static countdown)")
    end

    writeData(key_flySteps(pid), math.max(0, remaining - 1))
    createEvent(interval, self.screenplayName, "shuttleFlyStep", pPlayer, "")
    return 0
end

function GCWRankedAmbush:removeShuttle(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()
    local soid = toNum(readData(key_shuttle(pid)))
    if soid ~= 0 then
        local pShuttle = getSceneObject(soid)
        if pShuttle ~= nil then
            local so = SceneObject(pShuttle)
            if so and so.destroyObjectFromWorld then so:destroyObjectFromWorld() end
        end
        writeData(key_shuttle(pid), 0)
    end
    writeStringData(key_phase(pid), "departed")
    writeData(key_active(pid), 0)
    return 0
end

-- ===== Kills, rewards, cleanup =====
function GCWRankedAmbush:onAmbusherDied(pMob, pKiller)
    if pMob == nil then return 1 end
    local pPlayer = nil
    if pKiller and SceneObject(pKiller):isPlayerCreature() then
        pPlayer = pKiller
    elseif pKiller then
        local ko = CreatureObject(pKiller)
        if ko and ko.getOwner then
            local pOwner = ko:getOwner()
            if pOwner and SceneObject(pOwner):isPlayerCreature() then pPlayer = pOwner end
        end
    end
    if not pPlayer then return 1 end

    local pid = SceneObject(pPlayer):getObjectID()
    if toNum(readData(key_active(pid))) ~= 1 then return 1 end

    local alive = math.max(0, toNum(readData(key_alive(pid))) - 1)
    writeData(key_alive(pid), alive)
    msg(self, pPlayer, ("Ambusher down. Remaining: %d"):format(alive))

    if alive <= 0 then
        self:awardFactionPoints(pPlayer)
        self:cleanupMobsOnly(pid)      -- leave shuttle to finish departure
        writeData(key_active(pid), 0)  -- allow cooldown to proceed
        local cd = randBetween(self.cooldownMinSec, self.cooldownMaxSec)
        schedule(self, pPlayer, cd, "cooldown")
    end
    return 1
end

function GCWRankedAmbush:awardFactionPoints(pPlayer)
    if pPlayer == nil then return end
    local fac = playerFactionString(pPlayer)
    if fac == "neutral" then return end

    local rank   = CreatureObject(pPlayer):getFactionRank()
    local bucket = bucketFor(self, rank)
    local points = bucket.points
    local RANGE  = 80

    local function grant(pTgt)
        if pTgt == nil or not SceneObject(pTgt):isPlayerCreature() then return end
        if not SceneObject(pTgt):isInRangeWithObject(pPlayer, RANGE) then return end
        local ghost = CreatureObject(pTgt):getPlayerObject()
        if ghost ~= nil then PlayerObject(ghost):increaseFactionStanding(fac, points) end
    end

    local co = CreatureObject(pPlayer)
    if co.isGrouped and co:isGrouped() then
        for i = 0, co:getGroupSize() - 1 do grant(co:getGroupMember(i)) end
    else
        grant(pPlayer)
    end
    msg(self, pPlayer, ("Awarded %d %s faction points."):format(points, fac))
end

function GCWRankedAmbush:timeoutCleanup(pPlayer)
    if pPlayer == nil then return 0 end
    local pid = SceneObject(pPlayer):getObjectID()
    -- Full cleanup (including shuttle) as a safety net
    self:cleanupAll(pid, "timeout")
    return 0
end

function GCWRankedAmbush:despawnMob(pMob, pidStr)
    if pMob == nil then return 0 end
    local so = SceneObject(pMob)
    if so and so.destroyObjectFromWorld then so:destroyObjectFromWorld() end
    return 0
end

-- ===== Cleanup helpers =====
function GCWRankedAmbush:cleanupMobsOnly(pid)
    local idx = toNum(readData(key_alive(pid) .. ":index"))
    for i = 1, math.max(1, idx + 2) do
        local oid = toNum(readData(key_mob(pid, i)))
        if oid ~= 0 then
            local pMob = getSceneObject(oid)
            if pMob ~= nil then
                local so = SceneObject(pMob)
                if so and so.destroyObjectFromWorld then so:destroyObjectFromWorld() end
            end
        end
    end
    writeData(key_alive(pid), 0)
    writeData(key_alive(pid) .. ":index", 0)
end

function GCWRankedAmbush:cleanupAll(pid, reason)
    local soid = toNum(readData(key_shuttle(pid)))
    if soid ~= 0 then
        local pShuttle = getSceneObject(soid)
        if pShuttle ~= nil then
            local so = SceneObject(pShuttle)
            if so and so.destroyObjectFromWorld then so:destroyObjectFromWorld() end
        end
    end
    self:cleanupMobsOnly(pid)
    clearState(pid)
    Logger:log(("[GCWA] cleaned up (%s) for pid=%s"):format(reason or "?", tostring(pid)), LT_INFO)
end