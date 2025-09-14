--[[======================================================================
  Naboo World Boss: Infernomaw (Peko) - single-instance controller
  • SW quadrant spawnpoints shifted north (drier band) + inland nudge if shoreline
  • Helper waves at 75/50/25% (giant_peko_peko) with persisted gates + lock (no double spawns)
  • Random respawn after cooldown (12–15h)
  • Galaxy broadcast via broadcastToGalaxy(creatureObject, message)
      - first broadcast 60s after spawn, then hourly until death
  • Forced fire-breath loop to guarantee flamethrower visuals/attacks
  • Single main loop; quiet & resilient between core forks
========================================================================]]

if rawget(_G, "PEKO_WB_LOADED") then return end
PEKO_WB_LOADED = true
print("[PEKO] loading screenplay: infernomaw_worldboss")

PekoBossScreenPlay = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "PekoBossScreenPlay"
}
registerScreenPlay("PekoBossScreenPlay", true)

local function _try(f, ...) return pcall(f, ...) end

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

local function inlandNudge(planet, x, y, step, maxSteps)
  step = step or 60
  maxSteps = maxSteps or 15
  for _=1,maxSteps do
    y = y + step
    if spotIsDryAndValid(planet, x, y) then
      return x, y, safeTerrainZ(x, y)
    end
  end
  return nil,nil,nil
end

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

local function waveKey(oid, tag) return "PEKO.wave."..tostring(oid or 0).."."..tostring(tag) end
local function waveDone(oid, tag) local v=readData(waveKey(oid,tag)); return v and tonumber(v)==1 end
local function waveMark(oid, tag) writeData(waveKey(oid,tag),1) end
local function waveClearAll(oid) writeData(waveKey(oid,"75"),0); writeData(waveKey(oid,"50"),0); writeData(waveKey(oid,"25"),0) end

local function waveLockKey(oid, tag) return "PEKO.waveLock."..tostring(oid).."."..tostring(tag) end
local function waveUnlockAll(oid) writeData(waveLockKey(oid,"75"),0); writeData(waveLockKey(oid,"50"),0); writeData(waveLockKey(oid,"25"),0) end

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

PekoBoss = {
  TAG = "[PEKO]",
  PLANET = "naboo",
  BOSS_TEMPLATES = { "peko_peko_infernomaw" },
  BOOT_DELAY_SECONDS = 12,

  RESPAWN_MIN_SECONDS = 12*60*60,
  RESPAWN_MAX_SECONDS = 15*60*60,

  LOOP_INTERVAL   = 5,
  VERBOSE_TICK    = false,
  ENABLE_LOOP_FALLBACK_WAVES = false,

  FIRST_BROADCAST_DELAY = 60,
  REPEAT_EVERY_SECONDS  = 3600,

  WAVE_COUNTS  = { giant_peko_peko = 10 },
  WAVE_SCATTER = { giant_peko_peko = 4 },

  SPAWN_POINTS = {
    {-1500,-4550},{-2100,-4700},{-2700,-4850},
    {-3300,-4950},{-3900,-5050},{-4500,-5100},
    {-5100,-5050},{-5650,-4950},{-6150,-4850},
    {-6600,-4750},{-6950,-4650},{-7250,-4550}
  },

  DATA_STATE            = "PEKO.state",
  DATA_NEXT_SPAWN       = "PEKO.nextSpawnAt",
  DATA_BOSS_OID         = "PEKO.bossOID",
  DATA_LOOP_STARTED     = "PEKO.loopStarted",
  DATA_LAST_X           = "PEKO.lastX",
  DATA_LAST_Y           = "PEKO.lastY",
  DATA_NEXT_BCAST_AT    = "PEKO.nextGalaxyBcastAt",

  bossPtr = nil, bossOID = nil,
  _wave75 = false, _wave50 = false, _wave25 = false,
  _lastPctLogAt = 0, _lastPct = 999
}

function PekoBoss:d(m) print(self.TAG.." "..tostring(m)) end
function PekoBoss:getState() local v=readData(self.DATA_STATE); if v==nil then return 0 end; return tonumber(v) or 0 end
function PekoBoss:setState(s) writeData(self.DATA_STATE, s) end

function PekoBossScreenPlay:start()
  if readData(PekoBoss.DATA_LOOP_STARTED)==1 then return end
  writeData(PekoBoss.DATA_LOOP_STARTED,1)
  print("[PEKO] ScreenPlay boot -> starting main loop in "..tostring(PekoBoss.BOOT_DELAY_SECONDS).."s")
  createEvent(PekoBoss.BOOT_DELAY_SECONDS, "PekoBoss", "loop", nil, "")
end

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

-- only uses broadcastToGalaxy()
local function galaxyBroadcast(msg, ctx)
  msg = tostring(msg or "")
  if type(broadcastToGalaxy) == "function" then
    if ctx and _try(broadcastToGalaxy, ctx, msg) then
      print("[PEKO][BCAST] broadcastToGalaxy(ctx,msg)"); return true
    end
    if _try(broadcastToGalaxy, nil, msg) then
      print("[PEKO][BCAST] broadcastToGalaxy(nil,msg)"); return true
    end
    if _try(broadcastToGalaxy, msg) then
      print("[PEKO][BCAST] broadcastToGalaxy(msg)"); return true
    end
  end
  print("[PEKO][BCAST-FAIL] "..msg)
  return false
end

function PekoBoss:startBreathLoop(pBoss)
  if not pBoss then return end
  createEvent(math.random(3000, 4500), "PekoBoss", "breathTick", pBoss, "")
end

function PekoBoss:breathTick(pBoss)
  if not pBoss then return end
  local co = LuaCreatureObject(pBoss)
  local so = LuaSceneObject(pBoss)
  if not co or not so or co:isDead() then return end

  local target = 0
  pcall(function()
    if co.getFollowObject then
      target = co:getFollowObject() or 0
    end
  end)

  local function q(crc)
    if crc == 0 then return false end
    local ok = pcall(function() return co:queueCommand(crc, target, "") end)
    return ok and true or false
  end
  -- FIX: assign result instead of using a bare expression with 'or'
  local _issued = q(_CMD_FLAMECONE2) or q(_CMD_FLAMECONE1) or q(_CMD_FLAMES2) or q(_CMD_FLAMES1)

  local x,y,z = so:getPositionX(), so:getPositionY(), so:getPositionZ()
  _playFlameFX(self.PLANET, x, z, y + 2.5)

  createEvent(math.random(6000, 10000), "PekoBoss", "breathTick", pBoss, "")
end

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

  writeData(self.DATA_LAST_X, x); writeData(self.DATA_LAST_Y, y)
  writeData(self.DATA_NEXT_BCAST_AT, os.time() + (self.FIRST_BROADCAST_DELAY or 60))

  self:startBreathLoop(pBoss)

  return true
end

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
    local nextGal = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
    if nextGal > 0 and now >= nextGal then
      local x = tonumber(readData(self.DATA_LAST_X) or 0) or 0
      local y = tonumber(readData(self.DATA_LAST_Y) or 0) or 0
      local msg = string.format("[NOTICE] Infernomaw is located (%.0f, %.0f) on Naboo.", x, y)
      galaxyBroadcast(msg, self.bossPtr)
      writeData(self.DATA_NEXT_BCAST_AT, now + (self.REPEAT_EVERY_SECONDS or 3600))
    end

    if self.ENABLE_LOOP_FALLBACK_WAVES then
      local co = LuaCreatureObject(self.bossPtr)
      if co then
        local pAll, pHP = hamPercentAll9(co), healthPercent(co)
        local pct = (pAll < pHP) and pAll or pHP
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
      writeData(self.DATA_NEXT_BCAST_AT, 0)
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
    self:spawnWave(pBoss,"wb_wave_25")  -- FIX: pBoss (was 'poss')
  end
  return 0
end

function PekoBoss:onDeath(pBoss, pKiller)
  local when = os.time() + math.random(self.RESPAWN_MIN_SECONDS, self.RESPAWN_MAX_SECONDS)
  writeData(self.DATA_NEXT_SPAWN, when)
  writeData(self.DATA_BOSS_OID, 0)
  writeData(self.DATA_NEXT_BCAST_AT, 0)
  self.bossPtr, self.bossOID = nil, nil
  self:setState(3)
  waveUnlockAll(self.bossOID or 0)
  self:d("onDeath: cooldown armed (until "..tostring(when)..")")
  return 0
end

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
    local sx,sy = polar(1.5, SCATTER)
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

function PekoBoss:triggerWaveOnce(pBoss, tag)
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
