-- infernomaw_worldboss.lua
-- Naboo World Boss: Infernomaw (Peko) - single-instance controller
-- • SW quadrant spawnpoints shifted north (drier band) + inland nudge if shoreline
-- • Helper waves at 75/50/25% (giant_peko_peko) with persisted gates + lock (no double spawns)
-- • Random respawn after cooldown (12–15h)
-- • Robust galaxy broadcast with zone fallback
-- • Forced fire-breath loop to guarantee flamethrower visuals/attacks
-- • Single main loop; quiet & resilient between core forks

-- ===================== one-time load guard =====================
if rawget(_G, "PEKO_WB_LOADED") then return end
PEKO_WB_LOADED = true
print("[PEKO] loading screenplay: infernomaw_worldboss")

-- ===================== ScreenPlay wrapper =====================
PekoBossScreenPlay = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "PekoBossScreenPlay"
}
registerScreenPlay("PekoBossScreenPlay", true)

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

-- ObjVar helpers (cross-fork safe)
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

-- ===== Robust broadcast helpers =====
local function _try(func, ...) return pcall(func, ...) end

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

local function _getZonePlayers(planet)
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

local function _getAllPlayers()
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

local function zonecast(planet, msg)
  local list = _getZonePlayers(planet)
  return _sendToPlayerList(list, msg)
end

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

local _ALL_PLANETS = {
  "tatooine","naboo","corellia","rori","lok","dantooine",
  "talus","dathomir","yavin4","endor"
}

local function galaxycast(msg)
  msg = tostring(msg or "")

  if type(sendSystemMessageAll) == "function" and _try(sendSystemMessageAll, msg) then
    print("[PEKO][BCAST] used sendSystemMessageAll"); return true
  end
  if type(broadcastGalaxy) == "function" then
    if _try(broadcastGalaxy, msg) then print("[PEKO][BCAST] used broadcastGalaxy(msg)"); return true end
    if _try(broadcastGalaxy, nil, msg) then print("[PEKO][BCAST] used broadcastGalaxy(nil,msg)"); return true end
  end
  if type(broadcastMessage) == "function" then
    if _try(broadcastMessage, msg) then print("[PEKO][BCAST] used broadcastMessage(msg)"); return true end
    if _try(broadcastMessage, nil, msg) then print("[PEKO][BCAST] used broadcastMessage(nil,msg)"); return true end
  end
  if type(sendBroadcastMessage) == "function" and _try(sendBroadcastMessage, msg) then
    print("[PEKO][BCAST] used sendBroadcastMessage"); return true
  end
  if type(galaxyBroadcast) == "function" and _try(galaxyBroadcast, msg) then
    print("[PEKO][BCAST] used galaxyBroadcast"); return true
  end

  if _trySlashBroadcast(msg) then
    print("[PEKO][BCAST] executed /broadcastgalaxy via console bridge"); return true
  end

  local all = _getAllPlayers()
  if all and _sendToPlayerList(all, msg) then
    print("[PEKO][BCAST] messaged all players via enumerator")
    return true
  end

  local any = false
  for i = 1, #_ALL_PLANETS do
    any = zonecast(_ALL_PLANETS[i], msg) or any
  end
  if any then
    print("[PEKO][BCAST] messaged players by planet sweep")
    return true
  end

  print("[PEKO][BCAST-FAIL] "..msg)
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

-- Water/invalid spot check (uses a probe of the same family as helpers)
local function spotIsDryAndValid(planet, x, y)
  local tz = safeTerrainZ(x, y)
  if type(getWaterHeight) == "function" then
    local wz = getWaterHeight(x, y)
    if type(wz)=="number" and wz > tz + 0.05 then return false end
  end
  local probe = select(1, trySpawnMobile(planet, "giant_peko_peko", 0, x, tz, y, 0, 0))
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

-- >>> New: inland nudge (march north until dry)
local function inlandNudge(planet, x, y, step, maxSteps)
  step = step or 60       -- ~60m per step
  maxSteps = maxSteps or 15
  for _=1,maxSteps do
    y = y + step          -- north = less negative Y
    if spotIsDryAndValid(planet, x, y) then
      return x, y, safeTerrainZ(x, y)
    end
  end
  return nil,nil,nil
end

-- >>> Updated: try candidate; if wet, nudge inland before giving up
local function pickDrySpawnPoint(planet, points, tries)
  tries = tries or 20
  for _=1,tries do
    local pt = points[math.random(#points)]
    local x,y = tonumber(pt[1]) or 0, tonumber(pt[2]) or 0
    if spotIsDryAndValid(planet, x, y) then
      return x, y, safeTerrainZ(x, y)
    end
    local nx, ny, nz = inlandNudge(planet, x, y, 80, 12)
    if nx then return nx, ny, nz end
  end
  return nil,nil,nil
end

-- Persisted wave gates + locks (by OID)
local function waveKey(oid, tag) return "PEKO.wave."..tostring(oid or 0).."."..tostring(tag) end
local function waveDone(oid, tag) local v=readData(waveKey(oid,tag)); return v and tonumber(v)==1 end
local function waveMark(oid, tag) writeData(waveKey(oid,tag),1) end
local function waveClearAll(oid) writeData(waveKey(oid,"75"),0); writeData(waveKey(oid,"50"),0); writeData(waveKey(oid,"25"),0) end

local function waveLockKey(oid, tag) return "PEKO.waveLock."..tostring(oid).."."..tostring(tag) end
local function waveUnlockAll(oid) writeData(waveLockKey(oid,"75"),0); writeData(waveLockKey(oid,"50"),0); writeData(waveLockKey(oid,"25"),0) end

-- ===== Forced Fire-Breath helpers =====
local function _crc(name)
  if type(getCommandCrc) == "function" then return getCommandCrc(name) end
  if type(getStringCrc) == "function" then return getStringCrc(name) end
  if type(hashCode)     == "function" then return hashCode(name) end
  return 0
end
local _CMD_FLAMECONE2 = _crc("flamecone2")
local _CMD_FLAMECONE1 = _crc("flamecone1")
local _CMD_FLAMES2    = _crc("flamesingle2")
local _CMD_FLAMES1    = _crc("flamesingle1")

local function _playFlameFX(planet, x, z, y)
  local fx = "clienteffect/commando_special_flamethrower.cef"
  pcall(function() playClientEffectLoc(fx, planet, x, z, y, 0) end)
  pcall(function() broadcastClientEffectLoc(fx, planet, x, z, y, 0) end)
end

-- ===================== controller (single main loop) =====================
PekoBoss = {
  TAG = "[PEKO]",
  PLANET = "naboo",
  -- Try names in order (keeps tolerance if a different id was used)
  BOSS_TEMPLATES = { "peko_peko_infernomaw" },
  BOOT_DELAY_SECONDS = 12,

  -- Random respawn window (seconds)
  RESPAWN_MIN_SECONDS = 12*60*60,
  RESPAWN_MAX_SECONDS = 15*60*60,

  LOOP_INTERVAL   = 5,     -- seconds; main loop cadence
  VERBOSE_TICK    = false, -- true to see occasional % logs
  ENABLE_LOOP_FALLBACK_WAVES = false, -- keep false to avoid duplicate triggers

  WAVE_COUNTS  = { giant_peko_peko = 10 }, -- set to 5 if you want fewer adds
  WAVE_SCATTER = { giant_peko_peko = 4 },  -- helpers ring radius max (meters)

  -- === SW Naboo spawnpoints shifted north (drier band) ===
  SPAWN_POINTS = {
    {-1500,-4550},{-2100,-4700},{-2700,-4850},
    {-3300,-4950},{-3900,-5050},{-4500,-5100},
    {-5100,-5050},{-5650,-4950},{-6150,-4850},
    {-6600,-4750},{-6950,-4650},{-7250,-4550}
  },

  -- persisted keys
  DATA_STATE        = "PEKO.state",       -- 0 idle, 1 alive, 3 cooldown
  DATA_NEXT_SPAWN   = "PEKO.nextSpawnAt",
  DATA_BOSS_OID     = "PEKO.bossOID",
  DATA_LOOP_STARTED = "PEKO.loopStarted",

  -- runtime
  bossPtr = nil, bossOID = nil,
  _wave75 = false, _wave50 = false, _wave25 = false,
  _lastPctLogAt = 0, _lastPct = 999
}

function PekoBoss:d(m) print(self.TAG.." "..tostring(m)) end
function PekoBoss:getState() local v=readData(self.DATA_STATE); if v==nil then return 0 end; return tonumber(v) or 0 end
function PekoBoss:setState(s) writeData(self.DATA_STATE, s) end

-- boot screenplay -> start single main loop
function PekoBossScreenPlay:start()
  if readData(PekoBoss.DATA_LOOP_STARTED)==1 then return end
  writeData(PekoBoss.DATA_LOOP_STARTED,1)
  print("[PEKO] ScreenPlay boot -> starting main loop in "..tostring(PekoBoss.BOOT_DELAY_SECONDS).."s")
  createEvent(PekoBoss.BOOT_DELAY_SECONDS, "PekoBoss", "loop", nil, "")
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
    if type(ev)=="number" then pcall(createObserver,ev,"PekoBoss","onDamage",pBoss) end
  end
  local deathCands = {"CREATUREDEATH","OBJECTDESTRUCTION","OBJECT_DESTROYED"}
  for _,nm in ipairs(deathCands) do
    local ev=rawget(_G,nm)
    if type(ev)=="number" then pcall(createObserver,ev,"PekoBoss","onDeath",pBoss) end
  end
end

-- wave trigger lock (idempotent)
function PekoBoss:triggerWaveOnce(pBoss, tag) -- tag = "75","50","25"
  if not pBoss then return false end
  local oid = self.bossOID or readData(self.DATA_BOSS_OID)
  if not oid or tonumber(oid)==0 then return false end

  if tag=="75" and self._wave75 then return false end
  if tag=="50" and self._wave50 then return false end
  if tag=="25" and self._wave25 then return false end
  if waveDone(oid, tag) then return false end
  if soHasVar(pBoss, "wb_wave_"..tag) then return false end

  local lk = readData(waveLockKey(oid, tag))
  if lk and tonumber(lk)==1 then return false end
  writeData(waveLockKey(oid, tag), 1)

  if tag=="75" then self._wave75 = true elseif tag=="50" then self._wave50 = true else self._wave25 = true end
  waveMark(oid, tag)
  soSetVar(pBoss, "wb_wave_"..tag, 1)

  return true
end

-- ===== Fire-breath loop =====
function PekoBoss:startBreathLoop(pBoss)
  if not pBoss then return end
  createEvent(math.random(3000, 4500), "PekoBoss", "breathTick", pBoss, "")
end

function PekoBoss:breathTick(pBoss)
  if not pBoss then return end
  local co = LuaCreatureObject(pBoss)
  local so = LuaSceneObject(pBoss)
  if not co or not so or co:isDead() then return end

  -- Force a flamethrower command; try strongest first
  local target = 0
  pcall(function()
    if co.getFollowObject then
      target = co:getFollowObject() or 0
    end
  end)

  local issued = false
  local function tryQ(crc) if crc ~= 0 then return (pcall(function() return co:queueCommand(crc, target, "") end)) and true or false end return false end
  issued = tryQ(_CMD_FLAMECONE2) or tryQ(_CMD_FLAMECONE1) or tryQ(_CMD_FLAMES2) or tryQ(_CMD_FLAMES1)

  -- Play flame FX at the bird's head height
  local x,y,z = so:getPositionX(), so:getPositionY(), so:getPositionZ()
  _playFlameFX(self.PLANET, x, z, y + 2.5)

  -- Re-schedule next breath (6–10s)
  createEvent(math.random(6000, 10000), "PekoBoss", "breathTick", pBoss, "")
end

-- spawn boss once; returns true on success
function PekoBoss:doSpawn()
  local x,y,z = pickDrySpawnPoint(self.PLANET, self.SPAWN_POINTS, 20)
  if not x then self:d("spawn: no dry point found"); return false end

  local pBoss, sig, usedName
  for _,tpl in ipairs(self.BOSS_TEMPLATES or {}) do
    pBoss, sig = trySpawnMobile(self.PLANET, tpl, 0, x, z, y, 0, 0)
    if pBoss then usedName = tpl; break end
  end
  if not pBoss then
    self:d("spawn: spawnMobile failed. Tried: "..table.concat(self.BOSS_TEMPLATES or {}, ", "))
    return false
  end

  self.bossPtr = pBoss
  self._wave75, self._wave50, self._wave25 = false,false,false
  soDelVar(pBoss,"wb_wave_75"); soDelVar(pBoss,"wb_wave_50"); soDelVar(pBoss,"wb_wave_25")

  bindOID(self, pBoss)
  waveClearAll(self.bossOID)
  waveUnlockAll(self.bossOID)
  attachObservers(self, pBoss)
  self:setState(1)

  self:d(string.format("SPAWNED BOSS (%s) @ (%0.0f, %0.0f, %0.0f) [sig=%s]", tostring(usedName), x, z, y, sig))

  local announce = string.format("A terrifying World Boss stirs on Naboo! Coordinates: (%.0f, %.0f).", x, y)
  galaxycast(announce)

  pcall(function()
    local so = LuaSceneObject(self.bossPtr)
    if so and so.spatialChat then so:spatialChat("Skreee! Flames and feathers darken the sky!") end
  end)

  -- Start forced fire-breath cycle
  self:startBreathLoop(pBoss)

  return true
end

-- main loop: the *only* scheduler
function PekoBoss:loop()
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

      if self.ENABLE_LOOP_FALLBACK_WAVES then
        local f75 = self._wave75 or waveDone(self.bossOID,"75") or soHasVar(self.bossPtr,"wb_wave_75")
        local f50 = self._wave50 or waveDone(self.bossOID,"50") or soHasVar(self.bossPtr,"wb_wave_50")
        local f25 = self._wave25 or waveDone(self.bossOID,"25") or soHasVar(self.bossPtr,"wb_wave_25")
        if (not f75) and pct <= 75 and self:triggerWaveOnce(self.bossPtr,"75") then self:spawnWave(self.bossPtr,"wb_wave_75") end
        if (not f50) and pct <= 50 and self:triggerWaveOnce(self.bossPtr,"50") then self:spawnWave(self.bossPtr,"wb_wave_50") end
        if (not f25) and pct <= 25 and self:triggerWaveOnce(self.bossPtr,"25") then self:spawnWave(self.bossPtr,"wb_wave_25") end
      end
    end

  else
    if state == 1 then
      local when = now + math.random(self.RESPAWN_MIN_SECONDS, self.RESPAWN_MAX_SECONDS)
      writeData(self.DATA_NEXT_SPAWN, when)
      self:setState(3)
      writeData(self.DATA_BOSS_OID, 0)
      self:d("loop: boss missing -> cooldown armed for "..tostring(when - now).."s")
    elseif state ~= 3 then
      self:doSpawn()
    else
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

  createEvent(self.LOOP_INTERVAL or 5, "PekoBoss", "loop", nil, "")
end

-- ===================== observers =====================
function PekoBoss:onDamage(pBoss, pAttacker, damage)
  if not pBoss then return 0 end
  local co = LuaCreatureObject(pBoss); if not co then return 0 end
  local pAll, pHP = hamPercentAll9(co), healthPercent(co)
  local pct = (pAll < pHP) and pAll or pHP

  if (not self._wave75) and pct <= 75 and self:triggerWaveOnce(pBoss,"75") then
    self:spawnWave(pBoss,"wb_wave_75")
  end
  if (not self._wave50) and pct <= 50 and self:triggerWaveOnce(pBoss,"50") then
    self:spawnWave(pBoss,"wb_wave_50")
  end
  if (not self._wave25) and pct <= 25 and self:triggerWaveOnce(pBoss,"25") then
    self:spawnWave(pBoss,"wb_wave_25")
  end
  return 0
end

function PekoBoss:onDeath(pBoss, pKiller)
  local when = os.time() + math.random(self.RESPAWN_MIN_SECONDS, self.RESPAWN_MAX_SECONDS)
  writeData(self.DATA_NEXT_SPAWN, when)
  writeData(self.DATA_BOSS_OID, 0)
  self.bossPtr, self.bossOID = nil, nil
  self:setState(3)
  waveUnlockAll(self.bossOID or 0)
  self:d("onDeath: cooldown armed (until "..tostring(when)..")")
  return 0
end

-- ===================== helper spawner (spider-style) =====================
function PekoBoss:spawnWave(pBoss, tag)
  if not pBoss then return end
  local so = LuaSceneObject(pBoss); if not so then return end

  local px,py,pz = so:getPositionX(), so:getPositionY(), so:getPositionZ()
  local COUNT   = (self.WAVE_COUNTS  and self.WAVE_COUNTS.giant_peko_peko)  or 10
  local SCATTER = (self.WAVE_SCATTER and self.WAVE_SCATTER.giant_peko_peko) or 4

  local function polar(minR,maxR)
    local ang = math.random()*6.283185307179586
    local r   = math.random(minR*100, maxR*100)/100.0
    return px + math.cos(ang)*r, py + math.sin(ang)*r
  end

  local spawned, tries, MAX_TRIES = 0, 0, COUNT*6
  while spawned < COUNT and tries < MAX_TRIES do
    tries = tries + 1
    local sx,sy = polar(1.5, SCATTER) -- tight ring near the boss
    local ok = spotIsDryAndValid(self.PLANET, sx, sy)
    if not ok then sx,sy = polar(SCATTER+2, SCATTER+5); ok = spotIsDryAndValid(self.PLANET, sx, sy) end
    if ok then
      local sz = safeTerrainZ(sx, sy)
      local mob = select(1, trySpawnMobile(self.PLANET, "giant_peko_peko", 0, sx, sz, sy, math.random(0,359), 0))
      if mob then spawned = spawned + 1 end
    end
  end
  self:d(string.format("wave %s: spawned %d/%d giant_peko_peko (attempts=%d)", tostring(tag), spawned, COUNT, tries))
end
