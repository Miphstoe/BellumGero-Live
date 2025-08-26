-- =====================================================================
--  File: scripts/custom_scripts/screenplays/world/gorax_nw_endor.lua
-- One-at-a-time Gorax spawn, randomized within NW corridor of Endor.
-- - No engine auto-respawn; we handle respawn to re-randomize location.
-- - Duplicate-guarded so you never get two from double startup.
-- - Tweak respawnSeconds and spawnAreas as you like.
-- =====================================================================

local TAG = "[GORAX_NW_ENDOR] "

GoraxNWEndor = ScreenPlay:new {
    numberOfActs = 1,

    planet = "endor",

    -- How long after death to bring it back somewhere else (seconds)
    respawnSeconds = 3600, -- 1 hour; set smaller while testing

    -- Data key to remember the current Gorax object id
    dataKey = "gorax_nw_endor:oid",

    -- Randomized anchor zones across the NW corridor.
    -- Each entry is { x, z, radiusMeters } and we’ll pick a random point in the circle.
    -- Coords are intentionally spread along NW forest “corridor”; adjust to taste.
    spawnAreas = {
        {-7600, 5400, 250},
        {-7350, 5650, 250},
        {-7100, 5900, 250},
        {-6900, 6150, 250},
        {-6650, 6350, 250},
        {-6425, 6600, 250},
        {-6200, 6850, 250},
        {-5975, 7100, 250},
        {-5750, 7325, 250},
        {-5525, 7550, 250},
        {-5300, 7400, 250},
        {-5050, 7175, 250},
        {-4825, 6950, 250},
        {-4600, 6725, 250},
        {-4375, 6525, 250},
        {-4150, 6325, 250},
        {-3925, 6125, 250},
        {-3700, 5950, 250},
        {-7000, 5200, 250},
        {-7250, 5200, 250}
    }
}

registerScreenPlay("GoraxNWEndor", true)

-- ========== Lifecycle ==========

function GoraxNWEndor:start()
    if not isZoneEnabled(self.planet) then
        print(TAG .. "Zone not enabled; skipping.")
        return
    end
    self:ensureOneAlive()
end

-- If one is already alive, do nothing; otherwise spawn one.
function GoraxNWEndor:ensureOneAlive()
    local existingOID = readData(self.dataKey)
    if existingOID ~= 0 then
        local pExisting = getSceneObject(existingOID)
        if pExisting ~= nil and not SceneObject(pExisting):isDestroyed() then
            -- Already alive
            return
        end
    end
    self:spawnAtRandomPoint()
end

-- ========== Spawning & Respawn ==========

function GoraxNWEndor:spawnAtRandomPoint()
    -- Try a few different random points in case one fails (bad terrain etc.)
    for attempt = 1, 15 do
        local x, y, z, heading = self:getRandomGroundPoint()
        if x ~= nil then
            local pMob = spawnMobile(self.planet, "gorax", 0, x, y, z, heading, 0)
            if pMob ~= nil then
                local oid = SceneObject(pMob):getObjectID()
                writeData(self.dataKey, oid)
                createObserver(OBJECTDESTRUCTION, "GoraxNWEndor", "onGoraxDestroyed", pMob)
                print(string.format(TAG .. "Spawned Gorax at (%.1f, %.1f, %.1f), oid=%d", x, y, z, oid))
                return
            end
        end
    end
    print(TAG .. "WARNING: Failed to spawn Gorax after multiple attempts.")
end

function GoraxNWEndor:onGoraxDestroyed(pVictim, pAttacker)
    -- Clear the saved oid so ensureOneAlive won’t think it still exists
    writeData(self.dataKey, 0)
    -- Schedule a fresh spawn somewhere else
    createEvent(self.respawnSeconds * 1800, "GoraxNWEndor", "delayedRespawn", nil, "")
    return 0
end

function GoraxNWEndor:delayedRespawn(pDummy)
    self:spawnAtRandomPoint()
end

-- ========== Random location helpers ==========

-- Picks a random anchor circle and then a random point inside it.
function GoraxNWEndor:getRandomGroundPoint()
    if #self.spawnAreas == 0 then return nil end

    -- Pick a random circle
    local idx = getRandomNumber(1, #self.spawnAreas)
    local sx, sz, r = self.spawnAreas[idx][1], self.spawnAreas[idx][2], self.spawnAreas[idx][3]

    -- Random polar coordinates inside the circle
    local angleDeg = getRandomNumber(0, 359)
    local angleRad = math.rad(angleDeg)
    -- Bias radius toward center uniformly over area (sqrt of random)
    local rr = math.sqrt(math.random()) * r
    local dx = rr * math.cos(angleRad)
    local dz = rr * math.sin(angleRad)

    local x = sx + dx
    local z = sz + dz

    -- Figure out ground height (y). Prefer engine helper if present.
    local y = self:safeTerrainHeight(self.planet, x, z)

    -- Random facing
    local heading = getRandomNumber(0, 359)

    return x, y, z, heading
end

-- Tries to get terrain height robustly, with fallbacks.
function GoraxNWEndor:safeTerrainHeight(planetName, x, z)
    -- Many cores expose getTerrainHeight(name, x, z)
    local ok, h = pcall(function() return getTerrainHeight(planetName, x, z) end)
    if ok and h ~= nil then return h end

    -- Some shards bind getWorldFloor(name, x, z)
    ok, h = pcall(function() return getWorldFloor(planetName, x, z) end)
    if ok and h ~= nil then return h end

    -- Last resort: 0 (engine may snap to floor; if not, adjust your anchors to include known y)
    return 0
end
