--[[======================================================================
  Yavin IV World Boss: Searing Broodwarden (Enhanced Gaping Spider)
  - Single controller loop (no duplicate timers)
  - Water-safe spawn selection in SE quadrant
  - Helper waves at 75/50/25% (10x cavern_spider)
  - Respawn after cooldown (RESPAWN_SECONDS)
  - **Galaxy broadcast** via broadcastToGalaxy(creatureObject, message)
    • first broadcast 60s after spawn (configurable)
    • then hourly until the boss dies
========================================================================]]

-- ===================== one-time load guard =====================
if rawget(_G, "EGSPIDER_WB_LOADED") then return end
EGSPIDER_WB_LOADED = true
print("[EGSPIDER] loading screenplay: egspider_worldboss (broadcastToGalaxy)")

-- ===================== ScreenPlay wrapper =====================
EGSpiderBossScreenPlay = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "EGSpiderBossScreenPlay"
}
registerScreenPlay("EGSpiderBossScreenPlay", true)

-- ===================== small helpers =====================
local function _try(f, ...) return pcall(f, ...) end

local function safeTerrainZ(x, y)
  local z
  if type(getTerrainHeight) == "function" then z = getTerrainHeight(x, y)
  elseif type(getWorldHeight)  == "function" then z = getWorldHeight(x, y) end
  if type(z) ~= "number" then z = 0 end
  return z
end

-- Flexible spawnMobile (handles arg orders across forks)
local function trySpawnMobile(planet, tpl, respawn, x, z, y, dir, cell)
  local ok, mob
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir,cell)  if ok and mob then return mob,"A" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell,dir)  if ok and mob then return mob,"B" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir,cell)  if ok and mob then return mob,"C" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell,dir)  if ok and mob then return mob,"D" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir)       if ok and mob then return mob,"E" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir)       if ok and mob then return mob,"F" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell)      if ok and mob then return mob,"G" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell)      if ok and mob then return mob,"H" end
  return nil,"NONE"
end

-- Water/invalid-spot check
local function spotIsDryAndValid(planet, x, y)
  local tz = safeTerrainZ(x, y)
  if type(getWaterHeight) == "function" then
    local wz = getWaterHeight(x, y)
    if type(wz)=="number" and wz > tz + 0.05 then return false end
  end
  local probe = select(1, trySpawnMobile(planet, "cavern_spider", 0, x, tz, y, 0, 0))
  if probe then
    local wet=false
    _try(function()
      local co=LuaCreatureObject(probe)
      if co and co.isSwimming and co:isSwimming() then wet=true end
    end)
    local so=LuaSceneObject(probe)
    if so then so:destroyObjectFromWorld(); so:destroyObjectFromDatabase() end
    return not wet
  end
  return true
end

local function pickDrySpawnPoint(planet, points, tries)
  tries = tries or 12
  for _=1,tries do
    local pt = points[math.random(#points)]
    local x,y = tonumber(pt[1]) or 0, tonumber(pt[2]) or 0
    if spotIsDryAndValid(planet, x, y) then return x,y,safeTerrainZ(x,y) end
  end
  return nil,nil,nil
end

-- ===================== controller =====================
EGSpiderBoss = {
  TAG = "[EGSPIDER]",
  PLANET = "yavin4",
  BOSS_TEMPLATE = "enhanced_gaping_spider_boss",
  BOSS_NAME = "Searing Broodwarden",

  RESPAWN_SECONDS       = 12*60*60,   -- 12h (use 60 for tests)
  LOOP_INTERVAL         = 5,          -- seconds
  FIRST_BROADCAST_DELAY = 300,        -- 5 minutes after spawn
  REPEAT_EVERY_SECONDS  = 10800,      -- every 3 hours

  WAVE_COUNTS  = { cavern_spider = 10 },
  WAVE_SCATTER = { cavern_spider = 4 },

  SPAWN_POINTS = {
    {6100,-6750},{6800,-5200},{7350,-6100},
    {4604,-6470},{4950,-6650},{3634,-5239},
    {3441,-6564},{2550,-7450},{1500,-6200},
    {4700,-5450},{6172,-6727},{7213,-6567}
  },

  -- persisted keys
  DATA_STATE            = "EGSPIDER.state",          -- 0 idle, 1 alive, 3 cooldown
  DATA_NEXT_SPAWN       = "EGSPIDER.nextSpawnAt",
  DATA_BOSS_OID         = "EGSPIDER.bossOID",
  DATA_LOOP_STARTED     = "EGSPIDER.loopStarted",
  DATA_LAST_X           = "EGSPIDER.lastX",
  DATA_LAST_Y           = "EGSPIDER.lastY",
  DATA_NEXT_BCAST_AT    = "EGSPIDER.nextGalaxyBcastAt",

  -- runtime
  bossPtr = nil, bossOID = nil,
  _lastPctLogAt = 0, _lastPct = 999,
  VERBOSE_TICK = false
}

function EGSpiderBoss:d(m) print(self.TAG.." "..tostring(m)) end
function EGSpiderBoss:getState() local v=readData(self.DATA_STATE); if v==nil then return 0 end; return tonumber(v) or 0 end
function EGSpiderBoss:setState(s) writeData(self.DATA_STATE, s) end

-- ===================== ScreenPlay boot =====================
function EGSpiderBossScreenPlay:start()
  if readData(EGSpiderBoss.DATA_LOOP_STARTED)==1 then return end
  writeData(EGSpiderBoss.DATA_LOOP_STARTED,1)
  print("[EGSPIDER] ScreenPlay boot -> starting main loop in 10s")
  createEvent(10, "EGSpiderBoss", "loop", nil, "")
end

-- ===================== observers attach =====================
local function attachObservers(self, pBoss)
  local dmgCands   = {"DAMAGERECEIVED","COMBATDAMAGE","DAMAGE"}
  local deathCands = {"CREATUREDEATH","OBJECTDESTRUCTION","OBJECT_DESTROYED"}
  for _,nm in ipairs(dmgCands) do
    local ev=rawget(_G,nm)
    if type(ev)=="number" then pcall(createObserver,ev,"EGSpiderBoss","onDamage",pBoss) end
  end
  for _,nm in ipairs(deathCands) do
    local ev=rawget(_G,nm)
    if type(ev)=="number" then pcall(createObserver,ev,"EGSpiderBoss","onDeath",pBoss) end
  end
end

-- ===================== galaxy broadcast helper =====================
-- Uses your fork's broadcastToGalaxy(creatureObject, message).
-- Tries with boss pointer (preferred), then nil, then 1-arg form.
local function galaxyBroadcast(msg, ctx)
  msg = tostring(msg or "")
  if type(broadcastToGalaxy) == "function" then
    if ctx and _try(broadcastToGalaxy, ctx, msg) then
      print("[EGSPIDER][BCAST] broadcastToGalaxy(ctx,msg)"); return true
    end
    if _try(broadcastToGalaxy, nil, msg) then
      print("[EGSPIDER][BCAST] broadcastToGalaxy(nil,msg)"); return true
    end
    if _try(broadcastToGalaxy, msg) then
      print("[EGSPIDER][BCAST] broadcastToGalaxy(msg)"); return true
    end
  end
  print("[EGSPIDER][BCAST-FAIL] "..msg)
  return false
end

-- ===================== spawn & loop =====================
local function bindOID(self, pBoss)
  local oid=nil
  _try(function() local co=LuaCreatureObject(pBoss); if co then oid=co:getObjectID() end end)
  if not oid or tonumber(oid)==0 then
    _try(function() local so=LuaSceneObject(pBoss); if so then oid=so:getObjectID() end end)
  end
  if oid and tonumber(oid) and tonumber(oid) > 0 then
    self.bossOID = tonumber(oid)
    writeData(self.DATA_BOSS_OID, self.bossOID)
    return true
  end
  return false
end

function EGSpiderBoss:doSpawn()
  local x,y,z = pickDrySpawnPoint(self.PLANET, self.SPAWN_POINTS, 12)
  if not x then self:d("spawn: no dry point found"); return false end

  local pBoss, sig = trySpawnMobile(self.PLANET, self.BOSS_TEMPLATE, 0, x, z, y, 0, 0)
  if not pBoss then self:d("spawn: spawnMobile failed"); return false end

  self.bossPtr = pBoss
  bindOID(self, pBoss)
  attachObservers(self, pBoss)
  self:setState(1)

  self:d(string.format("SPAWNED BOSS @ (%0.0f, %0.0f, %0.0f) [sig=%s]", x, z, y, sig))

  -- Save location and schedule first galaxy broadcast
  writeData(self.DATA_LAST_X, x); writeData(self.DATA_LAST_Y, y)
  writeData(self.DATA_NEXT_BCAST_AT, os.time() + (self.FIRST_BROADCAST_DELAY or 60))

  -- Optional flavor local emote near the boss
  _try(function()
    local so = LuaSceneObject(self.bossPtr)
    if so and so.spatialChat then so:spatialChat("Hsssshhhh... The nest awakens!") end
  end)

  return true
end

function EGSpiderBoss:loop()
  -- Re-acquire pointer if we know the OID
  if (not self.bossPtr) then
    local savedOID = readData(self.DATA_BOSS_OID)
    if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 then
      local obj = getSceneObject(tonumber(savedOID))
      if obj then self.bossPtr = obj end
    end
  end

  local state = self:getState()
  local now   = os.time()
  local nextA = readData(self.DATA_NEXT_SPAWN)
  local cd    = (nextA and tonumber(nextA) and (tonumber(nextA) - now)) or 0

  if self.bossPtr then
    -- Hourly galaxy broadcast while alive
    local nextGal = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
    if nextGal > 0 and now >= nextGal then
      local x = tonumber(readData(self.DATA_LAST_X) or 0) or 0
      local y = tonumber(readData(self.DATA_LAST_Y) or 0) or 0
      local msg = string.format("[NOTICE] %s is located (%.0f, %.0f) on Yavin4.", self.BOSS_NAME, x, y)
      galaxyBroadcast(msg, self.bossPtr)
      writeData(self.DATA_NEXT_BCAST_AT, now + (self.REPEAT_EVERY_SECONDS or 3600))
    end

  else
    if state == 1 then
      -- We thought it was alive → arm cooldown
      local when = now + (self.RESPAWN_SECONDS or 60)
      writeData(self.DATA_NEXT_SPAWN, when)
      self:setState(3)
      writeData(self.DATA_BOSS_OID, 0)
      writeData(self.DATA_NEXT_BCAST_AT, 0)
      self:d("loop: boss missing -> cooldown armed for "..tostring(self.RESPAWN_SECONDS or 60).."s")
    elseif state ~= 3 then
      -- Idle (first boot) → spawn immediately
      self:doSpawn()
    else
      -- Cooldown state
      if cd <= 0 then
        if self:doSpawn() then
          writeData(self.DATA_NEXT_SPAWN, 0)
        else
          writeData(self.DATA_NEXT_SPAWN, now + 60)
          self:d("loop: spawn failed; retry in 60s")
        end
      end
    end
  end

  createEvent(self.LOOP_INTERVAL or 5, "EGSpiderBoss", "loop", nil, "")
end

-- ===================== observers =====================
function EGSpiderBoss:onDamage(pBoss, pAttacker, damage) return 0 end

function EGSpiderBoss:onDeath(pBoss, pKiller)
  -- Stop hourly galaxy pings on death and arm respawn
  writeData(self.DATA_NEXT_BCAST_AT, 0)
  self.bossPtr, self.bossOID = nil, nil
  self:setState(3)
  local when = os.time() + (self.RESPAWN_SECONDS or 60)
  writeData(self.DATA_NEXT_SPAWN, when)
  writeData(self.DATA_BOSS_OID, 0)
  self:d("onDeath: cooldown armed for "..tostring(self.RESPAWN_SECONDS or 60).."s (until "..tostring(when)..")")
  return 0
end

-- ===================== helper wave spawner (optional) =====================
function EGSpiderBoss:spawnWave(pBoss, tag)
  if not pBoss then return end
  local so = LuaSceneObject(pBoss); if not so then return end

  local px,py = so:getPositionX(), so:getPositionY()
  local COUNT   = (self.WAVE_COUNTS  and self.WAVE_COUNTS.cavern_spider)  or 10
  local SCATTER = (self.WAVE_SCATTER and self.WAVE_SCATTER.cavern_spider) or 4

  local function polar(minR,maxR)
    local ang = math.random()*6.283185307179586
    local r   = math.random(minR*100, maxR*100)/100.0
    return px + math.cos(ang)*r, py + math.sin(ang)*r
  end

  local spawned, tries, MAX_TRIES = 0, 0, COUNT*6
  while spawned < COUNT and tries < MAX_TRIES do
    tries = tries + 1
    local sx,sy = polar(1.5, SCATTER)
    local ok = spotIsDryAndValid(self.PLANET, sx, sy)
    if not ok then sx,sy = polar(SCATTER+2, SCATTER+5); ok = spotIsDryAndValid(self.PLANET, sx, sy) end
    if ok then
      local sz = safeTerrainZ(sx, sy)
      local mob = select(1, trySpawnMobile(self.PLANET, "cavern_spider", 0, sx, sz, sy, math.random(0,359), 0))
      if mob then spawned = spawned + 1 end
    end
  end

  self:d(string.format("wave %s: spawned %d/%d cavern_spider (attempts=%d)", tostring(tag), spawned, COUNT, tries))
end
