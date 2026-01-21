-- scripts/screenplays/acklay_worldboss.lua
-- Acklay World Boss: Manual respawn with galaxy broadcasts
-- - Spawns once per server boot at fixed location
-- - Respawns automatically after death (managed by watchLoop)
-- - Galaxy broadcasts every 3 hours starting 5 minutes after spawn

local TAG = "[ACKLAY-WB/AUTO-ONE]"
local function logf(fmt, ...)
  local s = string.format(TAG .. " " .. fmt, ...)
  if printLuaError then printLuaError(s) else print(s) end
end

AcklayWorldBoss = ScreenPlay:new {
  numberOfActs   = 1,
  screenplayName = "AcklayWorldBoss",

  planet  = "yavin4",
  -- /loc gives X,Y,Z (Y=elevation); spawnMobile commonly wants X,Z,Y.
  x = -7020, y = 5150, z = 72, heading = 180,

  bossTemplate   = "acklay_worldboss",
  leashRadius    = 120,

  --TEST value; use 43200 for 12 hours
  respawnSeconds = 86400,

  -- Loop and broadcast timing
  LOOP_INTERVAL            = 5,      -- seconds between watchLoop checks
  BCAST_BOOT_DELAY_SECONDS = 240,    -- 4 minutes after boot
  BCAST_REPEAT_SECONDS     = 10800,  -- every 3 hours

  -- Persisted keys
  DATA_BOSS_OID      = "ACKLAY.bossOID",
  DATA_NEXT_BCAST_AT = "ACKLAY.nextGalaxyBcastAt",
  DATA_LAST_X        = "ACKLAY.lastX",
  DATA_LAST_Y        = "ACKLAY.lastY",
  DATA_NEXT_SPAWN    = "ACKLAY.nextSpawnAt"
}

registerScreenPlay("AcklayWorldBoss", true)
logf("FILE LOADED; screenplay registered")

-- Runtime boot guard (does not persist across server restarts)
_G.ACKLAY_BOOT_GUARD = _G.ACKLAY_BOOT_GUARD or false

-- simple helpers
local function toNum(v) local n = tonumber(v) return n or 0 end
local function getFlag(k) return (readData and toNum(readData(k)) or 0) end
local function setFlag(k, v) if writeData then writeData(k, v) end end
local function _try(f, ...) return pcall(f, ...) end

-- Galaxy broadcast helper
local function galaxyBroadcast(msg, ctx)
  msg = tostring(msg or "")
  logf("galaxyBroadcast: attempting to broadcast: %s", msg)

  if type(broadcastToGalaxy) ~= "function" then
    logf("galaxyBroadcast FAILED: broadcastToGalaxy function not available")
    return false
  end

  -- Try with context
  if ctx then
    local success, result = _try(broadcastToGalaxy, ctx, msg)
    if success then
      logf("galaxyBroadcast SUCCESS: broadcastToGalaxy(ctx, msg)")
      return true
    else
      logf("galaxyBroadcast: broadcastToGalaxy(ctx, msg) failed: %s", tostring(result))
    end
  end

  -- Try with nil context
  local success, result = _try(broadcastToGalaxy, nil, msg)
  if success then
    logf("galaxyBroadcast SUCCESS: broadcastToGalaxy(nil, msg)")
    return true
  else
    logf("galaxyBroadcast: broadcastToGalaxy(nil, msg) failed: %s", tostring(result))
  end

  -- Try with just message
  success, result = _try(broadcastToGalaxy, msg)
  if success then
    logf("galaxyBroadcast SUCCESS: broadcastToGalaxy(msg)")
    return true
  else
    logf("galaxyBroadcast: broadcastToGalaxy(msg) failed: %s", tostring(result))
  end

  logf("galaxyBroadcast FAILED: all methods exhausted")
  return false
end

local function getOID(pObj)
  local oid = 0
  _try(function()
    local co = LuaCreatureObject(pObj)
    if co and co.getObjectID then oid = co:getObjectID() end
  end)
  if oid == 0 then
    _try(function()
      local so = LuaSceneObject(pObj)
      if so and so.getObjectID then oid = so:getObjectID() end
    end)
  end
  return tonumber(oid) or 0
end

function AcklayWorldBoss:start()
  logf("===== ACKLAY WORLD BOSS START =====")
  logf("start(): initializing broadcast system")
  logf("start(): current time is %d", os.time())

  -- Always ensure watch loop is running for broadcasts
  if createEvent then
    createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBoss", "watchLoop", nil, "")
    logf("start(): watchLoop scheduled in %d seconds", self.LOOP_INTERVAL or 5)
  end

  -- Guard so we only spawn once per boot, even if start() is called multiple times
  if _G.ACKLAY_BOOT_GUARD == true then
    logf("start(): already spawned this boot; skipping duplicate spawn (watchLoop still active)")
    local existingBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
    logf("start(): existing broadcast scheduled at %d", existingBcast)
    return
  end
  _G.ACKLAY_BOOT_GUARD = true
  logf("start(): boot guard set -> spawning boss (watchLoop will handle respawns)")

  -- Seed the next broadcast time (first broadcast 4 minutes after boot)
  if writeData then
    local firstBcastTime = os.time() + (self.BCAST_BOOT_DELAY_SECONDS or 240)
    writeData(self.DATA_NEXT_BCAST_AT, firstBcastTime)
    logf("start(): FIRST BROADCAST scheduled at %d (in %d seconds from now=%d)", firstBcastTime, self.BCAST_BOOT_DELAY_SECONDS or 240, os.time())
  end

  self:spawnOnce()
  logf("===== ACKLAY START COMPLETE =====")
end

function AcklayWorldBoss:spawnOnce()
  -- Try both coord orders. Use 0 for respawn so we manage it manually in watchLoop.
  local x1, y1, z1 = self.x, self.y, self.z         -- X,Y,Z
  local x2, y2, z2 = self.x, self.z, self.y         -- X,Z,Y (usual)

  local pBoss = spawnMobile(self.planet, self.bossTemplate, 0,
                            x2, y2, z2, self.heading, 0)
  local used  = 2
  if pBoss == nil then
    logf("order #2 (X,Z,Y) failed; trying order #1 (X,Y,Z)")
    pBoss = spawnMobile(self.planet, self.bossTemplate, 0,
                        x1, y1, z1, self.heading, 0)
    used  = (pBoss ~= nil) and 1 or 0
  end

  if pBoss == nil then
    logf("FATAL: spawnMobile failed (template/coords/blocked). Check template name & coords.")
    return
  end

  local lx, ly, lz = (used==1) and x1 or x2, (used==1) and y1 or y2, (used==1) and z1 or z2
  local boss = LuaCreatureObject(pBoss)
  if boss and boss.setCustomObjectName then boss:setCustomObjectName("Acklay, Devourer of Massassi") end
  if boss and boss.setHomeLocation then boss:setHomeLocation(lx, ly, lz, self.leashRadius) end

  -- Save location for broadcasts
  if writeData then
    writeData(self.DATA_LAST_X, lx)
    writeData(self.DATA_LAST_Y, ly)
  end

  if broadcastMessage then
    broadcastMessage("\\#FF9933A terrifying presence is felt on Yavin IV... the Acklay has emerged.")
  end

  logf("SPAWNED (order #%d) at (%.1f, %.1f, %.1f). Will manually respawn %ds after death.",
       used, lx, ly, lz, self.respawnSeconds)

  -- Bind OID after a short delay to ensure object is fully initialized
  if createEvent then
    createEvent(1000, "AcklayWorldBoss", "bindBossOID", pBoss, "")
  end
end

function AcklayWorldBoss:bindBossOID(pBoss, _)
  if pBoss == nil then
    logf("bindBossOID: pBoss is nil")
    return 0
  end

  local oid = 0
  _try(function()
    local so = LuaSceneObject(pBoss)
    if so and so.getObjectID then
      oid = so:getObjectID()
    end
  end)

  if oid == 0 then
    _try(function()
      local co = LuaCreatureObject(pBoss)
      if co and co.getObjectID then
        oid = co:getObjectID()
      end
    end)
  end

  if oid and tonumber(oid) and tonumber(oid) > 0 then
    if writeData then
      writeData(self.DATA_BOSS_OID, tonumber(oid))
      local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
      logf("bindBossOID: Successfully bound OID %d", tonumber(oid))
      logf("bindBossOID: Next broadcast scheduled at %d (current time: %d)", nextBcast, os.time())
    end
  else
    logf("bindBossOID: Failed to get valid OID, will retry in 0.5s")
    if createEvent then
      createEvent(500, "AcklayWorldBoss", "bindBossOID", pBoss, "")
    end
  end

  return 0
end

function AcklayWorldBoss:watchLoop()
  if not readData or not writeData then
    logf("watchLoop: readData/writeData not available")
    if createEvent then
      createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBoss", "watchLoop", nil, "")
    end
    return
  end

  local now = os.time()
  local savedOID = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
  local pBoss = nil

  -- Try to get the boss from saved OID
  if savedOID > 0 and type(getSceneObject) == "function" then
    pBoss = getSceneObject(savedOID)
    if pBoss then
      -- Only log every 60 ticks (5 minutes) to reduce spam
      if not self._lastWatchLog or (now - self._lastWatchLog) >= 300 then
        logf("watchLoop: monitoring boss with OID %d", savedOID)
        self._lastWatchLog = now
      end
    else
      -- OID is stale, clear it
      logf("watchLoop: saved OID %d is stale, clearing", savedOID)
      writeData(self.DATA_BOSS_OID, 0)
      savedOID = 0
    end
  elseif savedOID == 0 then
    -- No OID saved, log occasionally
    if not self._lastNoOIDLog or (now - self._lastNoOIDLog) >= 300 then
      logf("watchLoop: no boss OID saved (savedOID=0)")
      self._lastNoOIDLog = now
    end
  end

  -- Check for broadcast if we have a boss
  if pBoss ~= nil then
    local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0

    -- Check if the boss is still alive
    local isAlive = false
    local bossX, bossY = 0, 0

    _try(function()
      local co = LuaCreatureObject(pBoss)
      if co and not co:isDead() then
        isAlive = true
      end
    end)

    -- Update location
    _try(function()
      local so = LuaSceneObject(pBoss)
      if so then
        bossX = so:getPositionX() or 0
        bossY = so:getPositionY() or 0
        writeData(self.DATA_LAST_X, bossX)
        writeData(self.DATA_LAST_Y, bossY)
      end
    end)

    if isAlive and nextBcast > 0 and now >= nextBcast then
      -- Time for a broadcast
      local x = tonumber(readData(self.DATA_LAST_X) or 0) or 0
      local y = tonumber(readData(self.DATA_LAST_Y) or 0) or 0
      local msg = string.format("[NOTICE] The Acklay, Devourer of Massassi is located near (%.0f, %.0f) on Yavin IV.", x, y)

      logf("===== BROADCAST TIME =====")
      logf("Sending galaxy broadcast: %s", msg)
      logf("Boss OID: %d, Location: (%.0f, %.0f)", savedOID, x, y)
      galaxyBroadcast(msg, pBoss)

      -- Schedule next broadcast
      writeData(self.DATA_NEXT_BCAST_AT, now + (self.BCAST_REPEAT_SECONDS or 10800))
      logf("Next broadcast scheduled for %d (%d seconds from now)", now + (self.BCAST_REPEAT_SECONDS or 10800), self.BCAST_REPEAT_SECONDS or 10800)
      logf("==========================")
    elseif isAlive and nextBcast > 0 then
      -- Log countdown every 5 minutes
      if not self._lastCountdownLog or (now - self._lastCountdownLog) >= 300 then
        local remaining = nextBcast - now
        logf("watchLoop: Next broadcast in %d seconds (at %d)", remaining, nextBcast)
        self._lastCountdownLog = now
      end
    end

    if not isAlive then
      -- Boss died, schedule manual respawn
      logf("===== BOSS DEATH DETECTED =====")
      logf("watchLoop: boss died, scheduling respawn in %d seconds", self.respawnSeconds)
      writeData(self.DATA_BOSS_OID, 0)
      local respawnTime = now + self.respawnSeconds
      writeData(self.DATA_NEXT_SPAWN, respawnTime)
      -- Schedule next broadcast for after respawn + delay
      local nextBcastAfterRespawn = respawnTime + (self.BCAST_BOOT_DELAY_SECONDS or 240)
      writeData(self.DATA_NEXT_BCAST_AT, nextBcastAfterRespawn)
      logf("Respawn scheduled at %d (in %d seconds)", respawnTime, self.respawnSeconds)
      logf("First broadcast after respawn at %d", nextBcastAfterRespawn)
      logf("===============================")
    end
  else
    -- No boss found, check if we need to respawn
    local nextSpawn = tonumber(readData(self.DATA_NEXT_SPAWN) or 0) or 0
    if nextSpawn > 0 and now >= nextSpawn then
      logf("===== RESPAWN TIME =====")
      logf("watchLoop: time to respawn (scheduled=%d, now=%d)", nextSpawn, now)
      writeData(self.DATA_NEXT_SPAWN, 0)
      self:spawnOnce()
      logf("========================")
    elseif nextSpawn > 0 then
      -- Log respawn countdown every 30 minutes
      if not self._lastRespawnLog or (now - self._lastRespawnLog) >= 1800 then
        local remaining = nextSpawn - now
        logf("watchLoop: Boss is dead. Respawn in %d seconds (at %d)", remaining, nextSpawn)
        self._lastRespawnLog = now
      end
    end
  end

  -- Keep the watch loop running
  if createEvent then
    createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBoss", "watchLoop", nil, "")
  end
end
