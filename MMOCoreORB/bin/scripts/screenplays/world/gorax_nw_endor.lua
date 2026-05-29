-- =====================================================================
--  File: scripts/custom_scripts/screenplays/world/gorax_nw_endor.lua
-- One-at-a-time Gorax spawn, randomized within NW corridor of Endor.
-- - No engine auto-respawn; we handle respawn to re-randomize location.
-- - Duplicate-guarded so you never get two from double startup.
-- - Slope-checks candidate spawns; rejects terrain too steep to fight on.
-- =====================================================================

local TAG = "[GORAX_NW_ENDOR] "

GoraxNWEndor = ScreenPlay:new {
    numberOfActs = 1,

    planet = "endor",

    -- How long after death to bring it back somewhere else (seconds)
    respawnSeconds = 3600, -- 1 hour

    -- Data key to remember the current Gorax object id
    dataKey = "gorax_nw_endor:oid",

    -- Max terrain height delta (meters) sampled 30m out in 4 directions.
    -- 8m over 30m ≈ 15° slope — Gorax-sized creatures become unattackable above this.
    slopeThreshold = 8,

    -- Anchor zones across the NW corridor: { worldX, worldZ, radiusMeters }
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

function GoraxNWEndor:ensureOneAlive()
    local existingOID = readData(self.dataKey)
    if existingOID ~= 0 then
        local pExisting = getSceneObject(existingOID)
        if pExisting ~= nil and not SceneObject(pExisting):isDestroyed() then
            return
        end
    end
    self:spawnAtRandomPoint()
end

-- ========== Spawning & Respawn ==========

function GoraxNWEndor:spawnAtRandomPoint()
    for attempt = 1, 15 do
        local worldX, worldZ, heading = self:getRandomHorizontalPoint()

        -- spawnMobile arg order: (planet, template, respawnTimer, worldX, worldZ, worldY, heading, parentID)
        -- Spawn at worldY=0 first; we use the spawned creature to sample real terrain height below.
        local pMob = spawnMobile(self.planet, "gorax", 0, worldX, worldZ, 0, heading, 0)
        if pMob ~= nil then
            -- getTerrainHeight(creatureObject, worldX, worldZ) -> worldY elevation
            local terrainY = getTerrainHeight(pMob, worldX, worldZ)
            if terrainY == nil then terrainY = 0 end

            if self:isTooSteep(pMob, worldX, worldZ, terrainY) then
                -- Reject: terrain here is too hilly; clean up and try another point
                SceneObject(pMob):destroyObjectFromWorld()
            else
                -- Flat enough: move to correct elevation and register
                -- teleport(worldX, worldZ, worldY, parentID)
                SceneObject(pMob):teleport(worldX, worldZ, terrainY, 0)
                local oid = SceneObject(pMob):getObjectID()
                writeData(self.dataKey, oid)
                createObserver(OBJECTDESTRUCTION, "GoraxNWEndor", "onGoraxDestroyed", pMob)
                print(string.format(TAG .. "Spawned Gorax at (%.1f, %.1f, %.1f) attempt=%d oid=%d",
                    worldX, terrainY, worldZ, attempt, oid))
                return
            end
        end
    end
    print(TAG .. "WARNING: Failed to spawn Gorax after 15 attempts (terrain too steep or spawn blocked).")
end

function GoraxNWEndor:onGoraxDestroyed(pVictim, pAttacker)
    writeData(self.dataKey, 0)
    -- createEvent takes milliseconds; respawnSeconds * 1000 = correct delay
    createEvent(self.respawnSeconds * 1000, "GoraxNWEndor", "delayedRespawn", nil, "")
    return 0
end

function GoraxNWEndor:delayedRespawn(pDummy)
    self:spawnAtRandomPoint()
end

-- ========== Location helpers ==========

-- Returns a random (worldX, worldZ, heading) from the spawn area circles.
function GoraxNWEndor:getRandomHorizontalPoint()
    local idx = getRandomNumber(1, #self.spawnAreas)
    local sx, sz, r = self.spawnAreas[idx][1], self.spawnAreas[idx][2], self.spawnAreas[idx][3]
    local angleDeg = getRandomNumber(0, 359)
    local angleRad = math.rad(angleDeg)
    local rr = math.sqrt(math.random()) * r
    local worldX = sx + rr * math.cos(angleRad)
    local worldZ = sz + rr * math.sin(angleRad)
    local heading = getRandomNumber(0, 359)
    return worldX, worldZ, heading
end

-- Samples terrain height 30m out in 4 cardinal directions.
-- Returns true if any delta from h0 exceeds slopeThreshold.
function GoraxNWEndor:isTooSteep(pMob, worldX, worldZ, h0)
    local d = 30
    local limit = self.slopeThreshold
    local offsets = {{d, 0}, {-d, 0}, {0, d}, {0, -d}}
    for _, o in ipairs(offsets) do
        local h = getTerrainHeight(pMob, worldX + o[1], worldZ + o[2])
        if h ~= nil and math.abs(h - h0) > limit then
            return true
        end
    end
    return false
end
