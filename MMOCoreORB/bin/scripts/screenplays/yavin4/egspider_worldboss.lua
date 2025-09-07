-- egspider_worldboss.lua
-- Yavin IV World Boss: Enhanced Gaping Spider (single-instance controller)
--  • Single main loop controls spawn/cooldown (no duplicate timers)
--  • Water-safe spawn selection in SE quadrant
--  • Helper waves at 75/50/25% (10x cavern_spider) with hard gates (persisted + objvar)
--  • Respawn after cooldown (set RESPAWN_SECONDS)
--  • Robust galaxy broadcast with zone fallback so players see it in-game

-- ===================== one-time load guard =====================
if rawget(_G, "EGSPIDER_WB_LOADED") then return end
EGSPIDER_WB_LOADED = true
print("[EGSPIDER] loading screenplay: egspider_worldboss")

-- ===================== ScreenPlay wrapper =====================
EGSpiderBossScreenPlay = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "EGSpiderBossScreenPlay"
}
registerScreenPlay("EGSpiderBossScreenPlay", true)

-- ===================== helpers =====================
local function safeTerrainZ(x, y)
  local z
  if type(getTerrainHeight) == "function" then
    z = getTerrainHeight(x, y)
  elseif type(getWorldHeight) == "function" then
    z = getWorldHeight(x, y)
  end
  if type(z) ~= "number" then z = 0 end
  return z
end

-- ObjVar helpers (handle both SceneObject methods and global helpers)
local function soHasVar(p, k)
  local ok, res = pcall(function()
    local so = LuaSceneObject(p)
    if so and so.hasObjVar then return so:hasObjVar(k) end
    if hasObjVar then return hasObjVar(p, k) end
    return false
  end)
  return ok and res or false
end
local function soSetVar(p, k, v)
  pcall(function()
    local so = LuaSceneObject(p)
    if so and so.setObjVar then so:setObjVar(k, v); return end
    if setObjVar then setObjVar(p, k, v) end
  end)
end
local function soDelVar(p, k)
  pcall(function()
    local so = LuaSceneObject(p)
    if so and so.removeObjVar then so:removeObjVar(k); return end
    if removeObjVar then removeObjVar(p, k) end
  end)
end

-- percent calculators
local function hamPercentAll9(co)
  local best, have = 100, false
  for i=0,8 do
    local m = co:getMaxHAM(i) or 0
    if m > 0 then
      have = true
      local p = ((co:getHAM(i) or 0) * 100) / m
      if p < best then best = p end
    end
  end
  return have and best or 100
end
local function healthPercent(co)
  local m = co:getMaxHAM(0) or 0
  if m <= 0 then return 100 end
  return ((co:getHAM(0) or 0) * 100) / m
end

-- ===== Robust broadcast helpers (v3) =====

-- Try/catch wrapper
local function _try(func, ...) return pcall(func, ...) end

-- --- Low-level: send a system message to a list of player creature pointers ---
local function _sendToPlayerList(list, msg)
  if type(list) ~= "table" then return false end
  local sent = false
  for i = 1, #list do
    local p = list[i]
    if p then
      _try(function()
        local co = LuaCreatureObject(p)
        if co and co.sendSystemMessage then
          co:sendSystemMessage(msg)
          sent = true
        end
      end)
    end
  end
  return sent
end

-- --- Try a bunch of zone-scoped enumerators (cross-fork) ---
local function _getZonePlayers(planet)
  -- These are tried in order; any missing ones are skipped safely.
  local try = {
    function(pl) return _try(getPlayerCreaturesInZone, pl) end,
    function(pl) return _try(getPlayersInZone, pl) end,
    function(pl) return _try(getPlayerObjectsInZone, pl) end,
  }
  for _,fn in ipairs(try) do
    local ok, list = fn(planet)
    if ok and type(list) == "table" then return list end
  end
  return {}
end

-- --- Try a bunch of *galaxy-wide* enumerators (cross-fork) ---
local function _getAllPlayers()
  -- Add anything your fork supports here
  local try = {
    function() return _try(getOnlinePlayerList) end,
    function() return _try(getOnlinePlayers) end,
    function() return _try(getAllPlayers) end,
    function() return _try(getConnectedPlayers) end,
    function() return _try(getAllPlayerCreatures) end,
    function() return _try(getAllPlayerObjects) end,
    function() return _try(getPlayerCreatures) end,
  }
  for _,fn in ipairs(try) do
    local ok, list = fn()
    if ok and type(list) == "table" and #list > 0 then
      return list
    end
  end
  return nil
end

-- Zone broadcast (returns true if at least one player was messaged)
local function zonecast(planet, msg)
  local list = _getZonePlayers(planet)
  return _sendToPlayerList(list, msg)
end

-- Try to execute the admin slash command as a last resort
local function _trySlashBroadcast(msg)
  local line = "/broadcastgalaxy " .. tostring(msg or "")
  local tryExec = {
    function(cmd) return _try(executeConsoleCommand, cmd) end,
    function(cmd) return _try(runConsoleCommand, cmd) end,
    function(cmd) return _try(executeCommand, cmd) end,
    function(cmd) return _try(processCommand, cmd) end,
    function(cmd) return _try(adminCommand, cmd) end,
  }
  for _,fn in ipairs(tryExec) do
    local ok = fn(line)
    if ok then return true end
  end
  return false
end

-- Galaxy broadcast:
-- 1) Try native galaxy APIs
-- 2) Try slash command execution
-- 3) Try enumerating *all* players and DMing them
-- 4) Fallback: print
local _ALL_PLANETS = {
  "tatooine","naboo","corellia","rori","lok","dantooine",
  "talus","dathomir","yavin4","endor" -- trim/add for your server
}

local function galaxycast(msg)
  msg = tostring(msg or "")

  -- (1) Native galaxy-level calls (many forks)
  if type(sendSystemMessageAll) == "function" and _try(sendSystemMessageAll, msg) then
    print("[EGSPIDER][BCAST] used sendSystemMessageAll"); return true
  end
  if type(broadcastGalaxy) == "function" then
    if _try(broadcastGalaxy, msg) then print("[EGSPIDER][BCAST] used broadcastGalaxy(msg)"); return true end
    if _try(broadcastGalaxy, nil, msg) then print("[EGSPIDER][BCAST] used broadcastGalaxy(nil,msg)"); return true end
  end
  if type(broadcastMessage) == "function" then
    if _try(broadcastMessage, msg) then print("[EGSPIDER][BCAST] used broadcastMessage(msg)"); return true end
    if _try(broadcastMessage, nil, msg) then print("[EGSPIDER][BCAST] used broadcastMessage(nil,msg)"); return true end
  end
  if type(sendBroadcastMessage) == "function" and _try(sendBroadcastMessage, msg) then
    print("[EGSPIDER][BCAST] used sendBroadcastMessage"); return true
  end
  if type(galaxyBroadcast) == "function" and _try(galaxyBroadcast, msg) then
    print("[EGSPIDER][BCAST] used galaxyBroadcast"); return true
  end

  -- (2) Last-ditch: try to invoke the admin slash command itself
  if _trySlashBroadcast(msg) then
    print("[EGSPIDER][BCAST] executed /broadcastgalaxy via console bridge")
    return true
  end

  -- (3) Enumerate all players (if the core exposes any list) and DM them
  local all = _getAllPlayers()
  if all and _sendToPlayerList(all, msg) then
    print("[EGSPIDER][BCAST] messaged all players via enumerator")
    return true
  end

  -- (4) Planet sweep (if any zone enumerator exists)
  local any = false
  for i = 1, #_ALL_PLANETS do
    any = zonecast(_ALL_PLANETS[i], msg) or any
  end
  if any then
    print("[EGSPIDER][BCAST] messaged players by planet sweep")
    return true
  end

  -- (5) Last fallback: console only
  print("[EGSPIDER][BCAST-FAIL] "..msg)
  return false
end

-- ===================== spawn utils =====================
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

-- Water/invalid spot check
local function spotIsDryAndValid(planet, x, y)
  local tz = safeTerrainZ(x, y)
  if type(getWaterHeight) == "function" then
    local wz = getWaterHeight(x, y)
    if type(wz)=="number" and wz > tz + 0.05 then return false end
  end
  local probe = select(1, trySpawnMobile(planet, "cavern_spider", 0, x, tz, y, 0, 0))
  if probe then
    local wet=false
    pcall(function()
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

-- Persisted wave gates (by OID)
local function waveKey(oid, tag) return "EGSPIDER.wave."..tostring(oid or 0).."."..tostring(tag) end
local function waveDone(oid, tag) local v=readData(waveKey(oid,tag)); return v and tonumber(v)==1 end
local function waveMark(oid, tag) writeData(waveKey(oid,tag),1) end
local function waveClearAll(oid) writeData(waveKey(oid,"75"),0); writeData(waveKey(oid,"50"),0); writeData(waveKey(oid,"25"),0) end

-- ===================== controller (single main loop) =====================
EGSpiderBoss = {
  TAG = "[EGSPIDER]",
  PLANET = "yavin4",
  BOSS_TEMPLATE = "enhanced_gaping_spider_boss",

  -- >>> Change this for respawn time (seconds). Use 60 for tests, 12*60*60 for prod.
  RESPAWN_SECONDS = 12*60*60,

  LOOP_INTERVAL   = 5,     -- seconds; main loop cadence (quiet)
  VERBOSE_TICK    = false, -- set true to see occasional % logs

  WAVE_COUNTS  = { cavern_spider = 10 },
  WAVE_SCATTER = { cavern_spider = 4 },

  SPAWN_POINTS = {
    {6100,-6750},{6800,-5200},{7350,-6100},
    {4604,-6470},{4950,-6650},{3634,-5239},
    {3441,-6564},{2550,-7450},{1500,-6200},
    {4700,-5450},{6172,-6727},{7213,-6567}
  },

  -- persisted keys
  DATA_STATE        = "EGSPIDER.state",       -- 0 idle, 1 alive, 3 cooldown
  DATA_NEXT_SPAWN   = "EGSPIDER.nextSpawnAt",
  DATA_BOSS_OID     = "EGSPIDER.bossOID",
  DATA_LOOP_STARTED = "EGSPIDER.loopStarted",

  -- runtime
  bossPtr = nil, bossOID = nil,
  _wave75 = false, _wave50 = false, _wave25 = false,
  _lastPctLogAt = 0, _lastPct = 999
}

function EGSpiderBoss:d(m) print(self.TAG.." "..tostring(m)) end
function EGSpiderBoss:getState() local v=readData(self.DATA_STATE); if v==nil then return 0 end; return tonumber(v) or 0 end
function EGSpiderBoss:setState(s) writeData(self.DATA_STATE, s) end

-- boot screenplay -> start single main loop
function EGSpiderBossScreenPlay:start()
  if readData(EGSpiderBoss.DATA_LOOP_STARTED)==1 then return end
  writeData(EGSpiderBoss.DATA_LOOP_STARTED,1)
  print("[EGSPIDER] ScreenPlay boot -> starting main loop in 10s")
  createEvent(10, "EGSpiderBoss", "loop", nil, "")
end

-- helper: bind OID
local function bindOID(self, pBoss)
  local oid=nil
  pcall(function() local co=LuaCreatureObject(pBoss); if co then oid=co:getObjectID() end end)
  if not oid or tonumber(oid)==0 then
    pcall(function() local so=LuaSceneObject(pBoss); if so then oid=so:getObjectID() end end)
  end
  if oid and tonumber(oid) and tonumber(oid) > 0 then
    self.bossOID = tonumber(oid)
    writeData(self.DATA_BOSS_OID, self.bossOID)
    return true
  end
  return false
end

-- helper: attach observers (damage + death variants)
local function attachObservers(self, pBoss)
  local dmgCands = {"DAMAGERECEIVED","COMBATDAMAGE","DAMAGE"}
  for _,nm in ipairs(dmgCands) do
    local ev=rawget(_G,nm)
    if type(ev)=="number" then pcall(createObserver,ev,"EGSpiderBoss","onDamage",pBoss) end
  end
  local deathCands = {"CREATUREDEATH","OBJECTDESTRUCTION","OBJECT_DESTROYED"}
  for _,nm in ipairs(deathCands) do
    local ev=rawget(_G,nm)
    if type(ev)=="number" then pcall(createObserver,ev,"EGSpiderBoss","onDeath",pBoss) end
  end
end

-- spawn boss once; returns true on success
function EGSpiderBoss:doSpawn()
  local x,y,z = pickDrySpawnPoint(self.PLANET, self.SPAWN_POINTS, 12)
  if not x then self:d("spawn: no dry point found"); return false end

  local pBoss, sig = trySpawnMobile(self.PLANET, self.BOSS_TEMPLATE, 0, x, z, y, 0, 0)
  if not pBoss then self:d("spawn: spawnMobile failed"); return false end

  self.bossPtr = pBoss
  self._wave75, self._wave50, self._wave25 = false,false,false
  soDelVar(pBoss,"wb_wave_75"); soDelVar(pBoss,"wb_wave_50"); soDelVar(pBoss,"wb_wave_25")

  bindOID(self, pBoss)
  waveClearAll(self.bossOID)
  attachObservers(self, pBoss)
  self:setState(1)

  self:d(string.format("SPAWNED BOSS @ (%0.0f, %0.0f, %0.0f) [sig=%s]", x, z, y, sig))

  local announce = string.format(
    "A terrifying World Boss stirs on Yavin IV! Coordinates: (%.0f, %.0f).",
    x, y
  )
  galaxycast(announce) -- robust broadcast; falls back to zone-by-zone

  -- optional local emote for nearby players
  pcall(function()
    local so = LuaSceneObject(self.bossPtr)
    if so and so.spatialChat then so:spatialChat("Hsssshhhh... The nest awakens!") end
  end)

  return true
end

-- main loop: the *only* scheduler
function EGSpiderBoss:loop()
  -- re-acquire pointer if we know the OID
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
    -- alive: optional low-noise % logging and wave fallback
    local co = LuaCreatureObject(self.bossPtr)
    if co then
      local pAll, pHP = hamPercentAll9(co), healthPercent(co)
      local pct = (pAll < pHP) and pAll or pHP
      if self.VERBOSE_TICK then
        if (now - self._lastPctLogAt >= 30) or (math.abs(pct - self._lastPct) >= 10) then
          self:d(string.format("tick: boss %% = %.1f", pct))
          self._lastPctLogAt = now; self._lastPct = pct
        end
      end

      -- fallback wave triggers (gated) in case damage observer misses
      local f75 = self._wave75 or waveDone(self.bossOID,"75") or soHasVar(self.bossPtr,"wb_wave_75")
      local f50 = self._wave50 or waveDone(self.bossOID,"50") or soHasVar(self.bossPtr,"wb_wave_50")
      local f25 = self._wave25 or waveDone(self.bossOID,"25") or soHasVar(self.bossPtr,"wb_wave_25")
      if (not f75) and pct <= 75 then self._wave75=true; waveMark(self.bossOID,"75"); soSetVar(self.bossPtr,"wb_wave_75",1); self:spawnWave(self.bossPtr,"wb_wave_75") end
      if (not f50) and pct <= 50 then self._wave50=true; waveMark(self.bossOID,"50"); soSetVar(self.bossPtr,"wb_wave_50",1); self:spawnWave(self.bossPtr,"wb_wave_50") end
      if (not f25) and pct <= 25 then self._wave25=true; waveMark(self.bossOID,"25"); soSetVar(self.bossPtr,"wb_wave_25",1); self:spawnWave(self.bossPtr,"wb_wave_25") end
    end

  else
    -- no boss in world
    if state == 1 then
      -- we *thought* it was alive → arm cooldown
      local when = now + (self.RESPAWN_SECONDS or 60)
      writeData(self.DATA_NEXT_SPAWN, when)
      self:setState(3)
      writeData(self.DATA_BOSS_OID, 0)
      self:d("loop: boss missing -> cooldown armed for "..tostring(self.RESPAWN_SECONDS or 60).."s")
    elseif state ~= 3 then
      -- idle (first boot) → spawn immediately
      self:doSpawn()
    else
      -- cooldown state
      if cd <= 0 then
        if self:doSpawn() then
          writeData(self.DATA_NEXT_SPAWN, 0)
        else
          -- spawn failed; retry in 60s without spamming
          writeData(self.DATA_NEXT_SPAWN, now + 60)
          self:d("loop: spawn failed; retry in 60s")
        end
      end
    end
  end

  createEvent(self.LOOP_INTERVAL or 5, "EGSpiderBoss", "loop", nil, "")
end

-- ===================== observers =====================
function EGSpiderBoss:onDamage(pBoss, pAttacker, damage)
  if not pBoss then return 0 end
  local co = LuaCreatureObject(pBoss); if not co then return 0 end
  local pAll, pHP = hamPercentAll9(co), healthPercent(co)
  local pct = (pAll < pHP) and pAll or pHP

  local f75 = self._wave75 or waveDone(self.bossOID,"75") or soHasVar(pBoss,"wb_wave_75")
  local f50 = self._wave50 or waveDone(self.bossOID,"50") or soHasVar(pBoss,"wb_wave_50")
  local f25 = self._wave25 or waveDone(self.bossOID,"25") or soHasVar(pBoss,"wb_wave_25")

  if (not f75) and pct <= 75 then self._wave75=true; waveMark(self.bossOID,"75"); soSetVar(pBoss,"wb_wave_75",1); self:spawnWave(pBoss,"wb_wave_75") end
  if (not f50) and pct <= 50 then self._wave50=true; waveMark(self.bossOID,"50"); soSetVar(pBoss,"wb_wave_50",1); self:spawnWave(pBoss,"wb_wave_50") end
  if (not f25) and pct <= 25 then self._wave25=true; waveMark(self.bossOID,"25"); soSetVar(pBoss,"wb_wave_25",1); self:spawnWave(pBoss,"wb_wave_25") end
  return 0
end

function EGSpiderBoss:onDeath(pBoss, pKiller)
  local when = os.time() + (self.RESPAWN_SECONDS or 60)
  writeData(self.DATA_NEXT_SPAWN, when)
  writeData(self.DATA_BOSS_OID, 0)
  self.bossPtr, self.bossOID = nil, nil
  self:setState(3)
  self:d("onDeath: cooldown armed for "..tostring(self.RESPAWN_SECONDS or 60).."s (until "..tostring(when)..")")
  return 0
end

-- ===================== helper spawner =====================
function EGSpiderBoss:spawnWave(pBoss, tag)
  if not pBoss then return end
  local so = LuaSceneObject(pBoss); if not so then return end

  local px,py,pz = so:getPositionX(), so:getPositionY(), so:getPositionZ()
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
