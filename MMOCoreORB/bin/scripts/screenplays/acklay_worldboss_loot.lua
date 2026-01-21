-- scripts/screenplays/acklay_worldboss_loot.lua
-- Acklay World Boss with Loot Box System Integration
-- Uses WorldBossLootManager for per-player loot distribution

local TAG = "[ACKLAY-WB/LOOT]"
local function logf(fmt, ...)
  local s = string.format(TAG .. " " .. fmt, ...)
  if printLuaError then printLuaError(s) else print(s) end
end

-- Load the loot manager
local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

AcklayWorldBossLoot = ScreenPlay:new {
  numberOfActs   = 1,
  screenplayName = "AcklayWorldBossLoot",

  planet  = "yavin4",
  x = -7020, y = 5150, z = 72, heading = 180,

  bossTemplate   = "acklay_worldboss",
  leashRadius    = 120,

  respawnSeconds = 86400, -- 24 hours

  bootGuardKey   = "AcklayWorldBossLoot:booted:v1",

  bossName = "Acklay, Devourer of Massassi",

  -- Broadcast timing
  LOOP_INTERVAL            = 5,      -- seconds between watchLoop checks
  BCAST_BOOT_DELAY_SECONDS = 240,    -- 4 minutes after boot
  BCAST_REPEAT_SECONDS     = 10800,  -- every 3 hours

  -- Persisted keys
  DATA_BOSS_OID      = "ACKLAY_LOOT.bossOID",
  DATA_NEXT_BCAST_AT = "ACKLAY_LOOT.nextGalaxyBcastAt",
  DATA_LAST_X        = "ACKLAY_LOOT.lastX",
  DATA_LAST_Y        = "ACKLAY_LOOT.lastY",
  DATA_LOOP_STARTED  = "ACKLAY_LOOT.loopStarted"
}

registerScreenPlay("AcklayWorldBossLoot", true)
logf("FILE LOADED; screenplay registered with loot box system")

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
    end
  end

  -- Try with nil context
  local success, result = _try(broadcastToGalaxy, nil, msg)
  if success then
    logf("galaxyBroadcast SUCCESS: broadcastToGalaxy(nil, msg)")
    return true
  end

  -- Try with just message
  success, result = _try(broadcastToGalaxy, msg)
  if success then
    logf("galaxyBroadcast SUCCESS: broadcastToGalaxy(msg)")
    return true
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

function AcklayWorldBossLoot:start()
  logf("===== ACKLAY WORLD BOSS START (LOOT VERSION) =====")

  -- Start the broadcast watch loop (only once)
  if readData(self.DATA_LOOP_STARTED) ~= 1 then
    writeData(self.DATA_LOOP_STARTED, 1)
    logf("start(): Starting broadcast watch loop")
    createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBossLoot", "watchLoop", nil, "")
  end

  if getFlag(self.bootGuardKey) == 1 then
    logf("start(): already booted; skipping duplicate spawn (watch loop active)")
    return
  end
  setFlag(self.bootGuardKey, 1)
  logf("start(): boot guard set -> spawning with loot box integration")

  -- Schedule first broadcast
  local currentTime = os.time()
  local firstBcastTime = currentTime + (self.BCAST_BOOT_DELAY_SECONDS or 240)
  writeData(self.DATA_NEXT_BCAST_AT, firstBcastTime)
  logf("start(): Current time: %d", currentTime)
  logf("start(): FIRST BROADCAST scheduled at %d (in %d seconds)", firstBcastTime, self.BCAST_BOOT_DELAY_SECONDS or 240)

  self:spawnBoss()
  logf("===== ACKLAY START COMPLETE =====")
end

function AcklayWorldBossLoot:spawnBoss()
  local x2, y2, z2 = self.x, self.z, self.y

  local pBoss = spawnMobile(self.planet, self.bossTemplate, self.respawnSeconds,
                            x2, y2, z2, self.heading, 0)

  if pBoss == nil then
    logf("FATAL: spawnMobile failed. Check template name & coords.")
    return
  end

  local boss = LuaCreatureObject(pBoss)
  if boss and boss.setCustomObjectName then
    boss:setCustomObjectName(self.bossName)
  end
  if boss and boss.setHomeLocation then
    boss:setHomeLocation(x2, y2, z2, self.leashRadius)
  end

  createObserver(DAMAGERECEIVED, "AcklayWorldBossLoot", "onBossDamaged", pBoss)
  createObserver(OBJECTDESTRUCTION, "AcklayWorldBossLoot", "onBossDeath", pBoss)

  -- Save location for broadcasts (use actual world X, Y coordinates, not spawn parameters)
  writeData(self.DATA_LAST_X, self.x)  -- -7020
  writeData(self.DATA_LAST_Y, self.y)  -- 5150
  logf("spawnBoss: Saved broadcast coordinates (%.0f, %.0f)", self.x, self.y)

  -- Bind OID after a short delay to ensure object is fully initialized
  createEvent(1000, "AcklayWorldBossLoot", "bindBossOID", pBoss, "")

  if broadcastMessage then
    broadcastMessage("\\#FF9933A terrifying presence is felt on Yavin IV... the Acklay has emerged.")
  end

  logf("SPAWNED at (%.1f, %.1f, %.1f) with loot box system enabled.", x2, y2, z2)
end

function AcklayWorldBossLoot:onBossDamaged(pBoss, pAttacker, _damage)
  if pBoss == nil or pAttacker == nil then return 0 end

  -- Track damage for loot system
  WorldBossLootManager:trackDamage(pBoss, pAttacker)

  -- Check if we need to rebind OID (in case of engine respawn)
  local savedOID = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
  if savedOID == 0 then
    local oid = getOID(pBoss)
    if oid and tonumber(oid) and tonumber(oid) > 0 then
      writeData(self.DATA_BOSS_OID, tonumber(oid))
      logf("onBossDamaged: Re-bound boss OID %d after engine respawn", tonumber(oid))

      -- Save the boss position
      _try(function()
        local so = LuaSceneObject(pBoss)
        if so then
          local actualX = so:getPositionX() or self.x
          local actualY = so:getPositionY() or self.y
          writeData(self.DATA_LAST_X, actualX)
          writeData(self.DATA_LAST_Y, actualY)
          logf("onBossDamaged: Saved position (%.0f, %.0f)", actualX, actualY)
        end
      end)

      -- If no broadcast scheduled, schedule one now
      local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
      if nextBcast == 0 then
        local firstBcastTime = os.time() + (self.BCAST_BOOT_DELAY_SECONDS or 240)
        writeData(self.DATA_NEXT_BCAST_AT, firstBcastTime)
        logf("onBossDamaged: Scheduled broadcast at %d (in %d seconds)", firstBcastTime, self.BCAST_BOOT_DELAY_SECONDS or 240)
      end
    end
  end

  return 0
end

function AcklayWorldBossLoot:onBossDeath(pBoss, pKiller)
  if pBoss == nil then return 0 end

  logf("Boss died - creating loot box")

  local boss = SceneObject(pBoss)
  if boss == nil then return 0 end

  local lootGroups = {
    {
      groups = {
        {group = "acklay", chance = 3000000},
        {group = "color_crystals", chance = 3000000},
        {group = "power_crystals", chance = 2000000},
        {group = "armor_attachments", chance = 1000000},
        {group = "clothing_attachments", chance = 1000000},
      },
      lootChance = 10000000,
    },
    {
      groups = {
        {group = "power_crystals", chance = 10000000},
      },
      lootChance = 5000000,
    },
    {
      groups = {
        {group = "house_deeds", chance = 10000000}
      },
      lootChance = 2000000,
    },
    {
      groups = {
        {group = "endgame_weapon_schematics", chance = 10000000}
      },
      lootChance = 1500000,
    },
    {
      groups = {
        {group = "bg_token_group", chance = 10000000}
      },
      lootChance = 350000
    }
  }

  WorldBossLootManager:onBossDeath(pBoss, lootGroups, self.bossName)

  -- Clear broadcast data on death, schedule next broadcast after engine respawn
  logf("onBossDeath: Boss died, engine will respawn in %d seconds", self.respawnSeconds)
  writeData(self.DATA_BOSS_OID, 0)

  -- Schedule first broadcast after engine respawn
  local respawnTime = os.time() + self.respawnSeconds
  local nextBcastTime = respawnTime + (self.BCAST_BOOT_DELAY_SECONDS or 240)
  writeData(self.DATA_NEXT_BCAST_AT, nextBcastTime)
  logf("onBossDeath: Next broadcast scheduled at %d (respawn at %d + %d sec delay)", nextBcastTime, respawnTime, self.BCAST_BOOT_DELAY_SECONDS or 240)

  if broadcastMessage then
    broadcastMessage("\\#00FF00The Acklay has been defeated! A treasure chest appears at its feet.")
  end

  return 0
end

function AcklayWorldBossLoot:bindBossOID(pBoss, _)
  if pBoss == nil then
    logf("bindBossOID: pBoss is nil")
    return 0
  end

  local oid = getOID(pBoss)

  if oid and tonumber(oid) and tonumber(oid) > 0 then
    writeData(self.DATA_BOSS_OID, tonumber(oid))

    -- Also get and save the actual spawned position
    _try(function()
      local so = LuaSceneObject(pBoss)
      if so then
        local actualX = so:getPositionX() or 0
        local actualY = so:getPositionY() or 0
        writeData(self.DATA_LAST_X, actualX)
        writeData(self.DATA_LAST_Y, actualY)
        logf("bindBossOID: Saved actual boss position (%.0f, %.0f)", actualX, actualY)
      end
    end)

    local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
    logf("bindBossOID: Successfully bound OID %d", tonumber(oid))
    logf("bindBossOID: Next broadcast scheduled at %d (current time: %d)", nextBcast, os.time())
  else
    logf("bindBossOID: Failed to get valid OID, will retry in 0.5s")
    createEvent(500, "AcklayWorldBossLoot", "bindBossOID", pBoss, "")
  end

  return 0
end

function AcklayWorldBossLoot:watchLoop()
  if not readData or not writeData then
    logf("watchLoop: readData/writeData not available")
    createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBossLoot", "watchLoop", nil, "")
    return
  end

  local now = os.time()
  local savedOID = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
  local pBoss = nil

  -- Try to get the boss from saved OID
  if savedOID > 0 and type(getSceneObject) == "function" then
    pBoss = getSceneObject(savedOID)
    if not pBoss then
      -- OID is stale, might have respawned - clear it
      logf("watchLoop: saved OID %d is stale, waiting for respawn", savedOID)
      writeData(self.DATA_BOSS_OID, 0)
      savedOID = 0
    end
  end

  -- Check for broadcast if we have a boss
  if pBoss ~= nil then
    local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0

    -- Check if the boss is still alive
    local isAlive = false
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
        local bossX = so:getPositionX() or 0
        local bossY = so:getPositionY() or 0
        writeData(self.DATA_LAST_X, bossX)
        writeData(self.DATA_LAST_Y, bossY)

        -- Log position update once every 5 minutes
        if not self._lastPosLog or (now - self._lastPosLog) >= 300 then
          logf("watchLoop: Updated boss position to (%.0f, %.0f)", bossX, bossY)
          self._lastPosLog = now
        end
      end
    end)

    if isAlive and nextBcast > 0 and now >= nextBcast then
      -- Time for a broadcast
      local xRaw = readData(self.DATA_LAST_X)
      local yRaw = readData(self.DATA_LAST_Y)
      logf("watchLoop: readData returned X=%s, Y=%s", tostring(xRaw), tostring(yRaw))

      local x = tonumber(xRaw or 0) or 0
      local y = tonumber(yRaw or 0) or 0

      -- Fallback to spawn coordinates if data wasn't saved
      if x == 0 and y == 0 then
        x = self.x
        y = self.y
        logf("watchLoop: Using fallback spawn coordinates (%.0f, %.0f)", x, y)
      end

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
        logf("watchLoop: Boss alive, next broadcast in %d seconds", remaining)
        self._lastCountdownLog = now
      end
    end

    if not isAlive then
      -- Boss died (observer will handle cleanup)
      logf("watchLoop: boss detected as dead")
    end
  else
    -- No boss found - might be dead or engine respawned
    local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0

    -- If it's near broadcast time, try to find the boss at spawn location
    if nextBcast > 0 and (nextBcast - now) <= 60 then
      -- Try to find boss by scanning near spawn location
      logf("watchLoop: Broadcast time approaching, attempting to find respawned boss at spawn location")

      -- Try to spawn a probe to scan the area (will fail if boss already there)
      -- This is a hacky way to detect if something is at the spawn location
      -- Better would be to use getCreatureAt or similar if available

      if not self._lastScanLog or (now - self._lastScanLog) >= 60 then
        logf("watchLoop: Looking for respawned boss near (%.0f, %.0f)", self.x, self.y)
        self._lastScanLog = now

        -- Note: Without a proper scan API, we can't easily detect engine respawns
        -- The broadcast will just be skipped until the boss takes damage (which triggers bindBossOID via observer)
      end
    end

    if not self._lastNoOIDLog or (now - self._lastNoOIDLog) >= 600 then
      logf("watchLoop: no boss OID (savedOID=%d, nextBcast=%d)", savedOID, nextBcast)
      self._lastNoOIDLog = now
    end
  end

  -- Keep the watch loop running
  createEvent(self.LOOP_INTERVAL or 5, "AcklayWorldBossLoot", "watchLoop", nil, "")
end
