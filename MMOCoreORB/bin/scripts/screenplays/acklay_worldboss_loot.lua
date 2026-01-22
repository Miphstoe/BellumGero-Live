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

  -- Galaxy broadcast configuration
  FIRST_BROADCAST_DELAY = 240,      -- 4 minutes after spawn
  REPEAT_EVERY_SECONDS  = 10800,    -- every 3 hours
  DATA_BOSS_OID         = "AcklayWorldBossLoot:bossOID",
  DATA_NEXT_BCAST_AT    = "AcklayWorldBossLoot:nextBcastAt",
  DATA_LOOP_STARTED     = "AcklayWorldBossLoot:loopStarted",

  bossPtr = nil
}

registerScreenPlay("AcklayWorldBossLoot", true)
logf("FILE LOADED; screenplay registered with loot box system")

local function toNum(v) local n = tonumber(v) return n or 0 end
local function getFlag(k) return (readData and toNum(readData(k)) or 0) end
local function setFlag(k, v) if writeData then writeData(k, v) end end

-- Galaxy broadcast helper function
local function galaxyBroadcast(msg, ctx)
  msg = tostring(msg or "")
  if type(broadcastToGalaxy) == "function" then
    local function _try(f, ...) return pcall(f, ...) end
    if ctx and _try(broadcastToGalaxy, ctx, msg) then
      logf("[BCAST] broadcastToGalaxy(ctx,msg)")
      return true
    end
    if _try(broadcastToGalaxy, nil, msg) then
      logf("[BCAST] broadcastToGalaxy(nil,msg)")
      return true
    end
    if _try(broadcastToGalaxy, msg) then
      logf("[BCAST] broadcastToGalaxy(msg)")
      return true
    end
  end
  logf("[BCAST-FAIL] " .. msg)
  return false
end

function AcklayWorldBossLoot:start()
  if getFlag(self.bootGuardKey) == 1 then
    logf("start(): already booted; skipping duplicate")
    return
  end
  setFlag(self.bootGuardKey, 1)
  logf("start(): boot guard set -> spawning with loot box integration")

  self:spawnBoss()

  -- Start broadcast loop if not already running
  if readData and readData(self.DATA_LOOP_STARTED) ~= 1 then
    if writeData then writeData(self.DATA_LOOP_STARTED, 1) end
    logf("start(): starting broadcast loop")
    createEvent(5, "AcklayWorldBossLoot", "broadcastLoop", nil, "")
  end
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

  if broadcastMessage then
    broadcastMessage("\\#FF9933A terrifying presence is felt on Yavin IV... the Acklay has emerged.")
  end

  -- Store boss pointer and OID for broadcast loop
  self.bossPtr = pBoss
  local boss = LuaCreatureObject(pBoss)
  if boss and boss.getObjectID then
    local oid = boss:getObjectID()
    if writeData then writeData(self.DATA_BOSS_OID, oid) end
  end

  -- Schedule first galaxy broadcast
  if writeData then
    writeData(self.DATA_NEXT_BCAST_AT, os.time() + self.FIRST_BROADCAST_DELAY)
  end

  logf("SPAWNED at (%.1f, %.1f, %.1f) with loot box system enabled.", x2, y2, z2)
end

function AcklayWorldBossLoot:onBossDamaged(pBoss, pAttacker, _damage)
  if pBoss == nil or pAttacker == nil then return 0 end

  WorldBossLootManager:trackDamage(pBoss, pAttacker)

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

  -- Stop galaxy broadcasts
  if writeData then
    writeData(self.DATA_NEXT_BCAST_AT, 0)
    writeData(self.DATA_BOSS_OID, 0)
  end
  self.bossPtr = nil

  if broadcastMessage then
    broadcastMessage("\\#00FF00The Acklay has been defeated! A treasure chest appears at its feet.")
  end

  return 0
end

function AcklayWorldBossLoot:broadcastLoop()
  -- Re-acquire pointer if we know the OID
  if not self.bossPtr and readData then
    local savedOID = readData(self.DATA_BOSS_OID)
    if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 then
      local obj = getSceneObject(tonumber(savedOID))
      if obj then self.bossPtr = obj end
    end
  end

  -- Check if it's time to broadcast
  if self.bossPtr and readData then
    local now = os.time()
    local nextBcast = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0

    if nextBcast > 0 and now >= nextBcast then
      -- Broadcast boss location
      local msg = string.format("[NOTICE] %s is located (%.0f, %.0f) on Yavin IV.",
                                self.bossName, self.x, self.y)
      galaxyBroadcast(msg, self.bossPtr)

      -- Schedule next broadcast
      if writeData then
        writeData(self.DATA_NEXT_BCAST_AT, now + self.REPEAT_EVERY_SECONDS)
      end
    end
  end

  -- Continue the loop
  createEvent(5, "AcklayWorldBossLoot", "broadcastLoop", nil, "")
  return 0
end
