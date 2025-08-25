-- scripts/screenplays/acklay_worldboss.lua
-- Acklay World Boss (AUTO + ONE-SHOT): engine respawn, guarded against duplicate startup spawns

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

  -- TEST value; use 43200 for 12 hours
  respawnSeconds = 10,

  -- boot guard key (prevents multi-start on the same server boot)
  bootGuardKey   = "AcklayWorldBoss:booted:v1"
}

registerScreenPlay("AcklayWorldBoss", true)
logf("FILE LOADED; screenplay registered")

-- simple helpers
local function toNum(v) local n = tonumber(v) return n or 0 end
local function getFlag(k) return (readData and toNum(readData(k)) or 0) end
local function setFlag(k, v) if writeData then writeData(k, v) end end

function AcklayWorldBoss:start()
  -- Guard so we only run once per boot, even if start() is called multiple times
  if getFlag(self.bootGuardKey) == 1 then
    logf("start(): already booted; skipping duplicate")
    return
  end
  setFlag(self.bootGuardKey, 1)
  logf("start(): boot guard set -> spawning once and letting engine handle respawns")

  self:spawnOnce()
end

function AcklayWorldBoss:spawnOnce()
  -- Try both coord orders. Pass respawnSeconds so the ENGINE auto-respawns after death.
  local x1, y1, z1 = self.x, self.y, self.z         -- X,Y,Z
  local x2, y2, z2 = self.x, self.z, self.y         -- X,Z,Y (usual)

  local pBoss = spawnMobile(self.planet, self.bossTemplate, self.respawnSeconds,
                            x2, y2, z2, self.heading, 0)
  local used  = 2
  if pBoss == nil then
    logf("order #2 (X,Z,Y) failed; trying order #1 (X,Y,Z)")
    pBoss = spawnMobile(self.planet, self.bossTemplate, self.respawnSeconds,
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

  if broadcastMessage then
    broadcastMessage("\\#FF9933A terrifying presence is felt on Yavin IV... the Acklay has emerged.")
  end

  logf("SPAWNED (order #%d) at (%.1f, %.1f, %.1f). Engine will auto-respawn every %ds on death.",
       used, lx, ly, lz, self.respawnSeconds)
end
