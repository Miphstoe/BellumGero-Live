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

  bossName = "Acklay, Devourer of Massassi"
}

registerScreenPlay("AcklayWorldBossLoot", true)
logf("FILE LOADED; screenplay registered with loot box system")

local function toNum(v) local n = tonumber(v) return n or 0 end
local function getFlag(k) return (readData and toNum(readData(k)) or 0) end
local function setFlag(k, v) if writeData then writeData(k, v) end end

function AcklayWorldBossLoot:start()
  if getFlag(self.bootGuardKey) == 1 then
    logf("start(): already booted; skipping duplicate")
    return
  end
  setFlag(self.bootGuardKey, 1)
  logf("start(): boot guard set -> spawning with loot box integration")

  self:spawnBoss()
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

  if broadcastMessage then
    broadcastMessage("\\#00FF00The Acklay has been defeated! A treasure chest appears at its feet.")
  end

  return 0
end
