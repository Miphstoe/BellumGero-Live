-- egspider_worldboss.lua
-- Yavin IV World Boss: Enhanced Gaping Spider
-- - Single spawn (lock + adopt existing + finalize de-dup)
-- - Water-safe spawn selection in SE quadrant
-- - Waves at 75/50/25% (10x cavern_spider) with persisted, mark-before-spawn gates keyed by boss OID
-- - Respawn 12h after death (cooldown gate in spawnBoss + cooldown-aware retries)
-- - Quiet tick fallback with optional throttled logging

-- ===== single-load guard =====
if rawget(_G, "EGSPIDER_WB_LOADED") then return end
EGSPIDER_WB_LOADED = true
if readData("EGSPIDER.luaPrinted") ~= 1 then
  print("[EGSPIDER] loading screenplay: egspider_worldboss")
  writeData("EGSPIDER.luaPrinted", 1)
end

-- ===== ScreenPlay wrapper =====
EGSpiderBossScreenPlay = ScreenPlay:new{ numberOfActs = 1, screenplayName = "EGSpiderBossScreenPlay" }
registerScreenPlay("EGSpiderBossScreenPlay", true)

-- ===== helpers (terrain & objvars) =====
local function safeTerrainZ(x, y)
  local z
  if type(getTerrainHeight) == "function" then z = getTerrainHeight(x, y)
  elseif type(getWorldHeight) == "function" then z = getWorldHeight(x, y) end
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

-- ===== percent calculators =====
local function hamPercentAll9(co)
  local bestPct, have = 100, false
  for i=0,8 do
    local max = co:getMaxHAM(i) or 0
    if max > 0 then
      local pct = ((co:getHAM(i) or 0) * 100) / max
      if pct < bestPct then bestPct = pct end
      have = true
    end
  end
  return have and bestPct or 100
end
local function healthPercent(co)
  local m = co:getMaxHAM(0) or 0
  if m <= 0 then return 100 end
  return ((co:getHAM(0) or 0) * 100) / m
end

-- ===== spawn utils =====
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
  local probe = select(1, trySpawnMobile(planet, "cavern_spider", 0, x, tz, y, 0, 0))
  if probe then
    local wet=false
    pcall(function() local co=LuaCreatureObject(probe); if co and co.isSwimming and co:isSwimming() then wet=true end end)
    local so=LuaSceneObject(probe); if so then so:destroyObjectFromWorld(); so:destroyObjectFromDatabase() end
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

local function preflight(planet, x, z, y)
  local mob = select(1, trySpawnMobile(planet, "cavern_spider", 0, x+1, z, y+1, 0, 0))
  if mob then
    local so=LuaSceneObject(mob); if so then so:destroyObjectFromWorld(); so:destroyObjectFromDatabase() end
    return true
  end
  return false
end

-- ===== cooldown helper =====
local function cooldownDelay(self)
  local nextA = readData(self.DATA_NEXT_SPAWN)
  local now = os.time()
  if nextA and tonumber(nextA) and tonumber(nextA) > now then
    return tonumber(nextA) - now
  end
  return 0
end

-- ===== wave gating (persisted + ObjVar) =====
local function waveKey(oid, tag)
  return "EGSPIDER.wave." .. tostring(oid or 0) .. "." .. tostring(tag)
end
local function waveDone(oid, tag)
  local v = readData(waveKey(oid, tag))
  return v ~= nil and tonumber(v) == 1
end
local function waveMark(oid, tag) writeData(waveKey(oid, tag), 1) end
local function waveClearAll(oid)
  writeData(waveKey(oid, "75"), 0)
  writeData(waveKey(oid, "50"), 0)
  writeData(waveKey(oid, "25"), 0)
end

-- ===== controller =====
EGSpiderBoss = {
  TAG = "[EGSPIDER]",
  PLANET = "yavin4",
  BOSS_TEMPLATE = "enhanced_gaping_spider_boss",
  RESPAWN_SECONDS = 12*60*60,

  -- tick logging (quiet by default)
  VERBOSE_TICK   = false,  -- set true to see throttled % logs
  LOG_PCT_STEP   = 5,
  LOG_MIN_PERIOD = 30,
  TICK_ACTIVE_SEC= 2,
  TICK_IDLE_SEC  = 10,

  -- helpers per wave
  WAVE_COUNTS  = { cavern_spider = 10 },
  WAVE_SCATTER = { cavern_spider = 4 },

  -- SE quadrant candidate points
  SPAWN_POINTS = {
    {6100,-6750},{6800,-5200},{7350,-6100},
    {4604,-6470},{4950,-6650},{3634,-5239},
    {3441,-6564},{2550,-7450},{1500,-6200},
    {4700,-5450},{6172,-6727},{7213,-6567}
  },

  -- persisted keys
  DATA_FLAG_SPAWNED   = "EGSPIDER.spawned",      -- 0 idle, 1 alive, 2 spawning, 3 cooldown
  DATA_NEXT_SPAWN     = "EGSPIDER.nextSpawnAt",
  DATA_BOOT_SCHEDULED = "EGSPIDER.bootScheduled",
  DATA_BOSS_OID       = "EGSPIDER.bossOID",
  DATA_SPAWN_LOCK     = "EGSPIDER.spawnLock",

  -- lock config
  LOCK_TTL = 180,

  -- runtime
  bossPtr = nil, bossOID = nil, resolveMisses = 0,
  _wave75 = false, _wave50 = false, _wave25 = false,
  _lastTickPct = 999, _lastTickTime = 0
}

function EGSpiderBoss:d(m) print(self.TAG .. " " .. tostring(m)) end
function EGSpiderBoss:getState() local v=readData(self.DATA_FLAG_SPAWNED); if v==nil then return 0 end; return tonumber(v) or 0 end
function EGSpiderBoss:setState(s) writeData(self.DATA_FLAG_SPAWNED, s) end

-- ===== spawn lock =====
function EGSpiderBoss:acquireSpawnLock()
  local now = os.time()
  local untilTs = readData(self.DATA_SPAWN_LOCK)
  if untilTs and tonumber(untilTs) and tonumber(untilTs) > now then return false end
  writeData(self.DATA_SPAWN_LOCK, now + (self.LOCK_TTL or 180))
  return true
end
function EGSpiderBoss:releaseSpawnLock() writeData(self.DATA_SPAWN_LOCK, 0) end

-- ===== boot =====
function EGSpiderBossScreenPlay:start()
  if readData(EGSpiderBoss.DATA_BOOT_SCHEDULED)==1 then return end
  writeData(EGSpiderBoss.DATA_BOOT_SCHEDULED,1)
  print("[EGSPIDER] ScreenPlay registered; booting in 90s")
  createEvent(90, "EGSpiderBossScreenPlay", "boot", nil, "")
end
function EGSpiderBossScreenPlay:boot()
  print("[EGSPIDER] ScreenPlay boot -> start boss controller")
  EGSpiderBoss:start()
end

-- ===== bind OID =====
local function bindAndPersistOID(self, pBoss)
  local oid = nil
  pcall(function() local co=LuaCreatureObject(pBoss); if co then oid = co:getObjectID() end end)
  if not oid or tonumber(oid)==0 then
    pcall(function() local so=LuaSceneObject(pBoss); if so then oid = so:getObjectID() end end)
  end
  if oid and tonumber(oid) and tonumber(oid) > 0 then
    self.bossOID = tonumber(oid)
    writeData(self.DATA_BOSS_OID, self.bossOID)
    return true
  end
  return false
end

-- ===== lifecycle =====
function EGSpiderBoss:start()
  -- adopt existing boss by OID on restart
  local savedOID = readData(self.DATA_BOSS_OID)
  if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 then
    local obj = getSceneObject(tonumber(savedOID))
    if obj then
      self:d("adopt existing boss by OID")
      self.bossPtr, self.bossOID = obj, tonumber(savedOID)
      -- reset wave gates for fresh fight after restart
      self._wave75, self._wave50, self._wave25 = false,false,false
      waveClearAll(self.bossOID)
      soDelVar(self.bossPtr, "wb_wave_75"); soDelVar(self.bossPtr, "wb_wave_50"); soDelVar(self.bossPtr, "wb_wave_25")
      -- reattach observers
      local dmg = rawget(_G,"DAMAGERECEIVED") or rawget(_G,"COMBATDAMAGE") or rawget(_G,"DAMAGE")
      if type(dmg)=="number" then pcall(createObserver,dmg,"EGSpiderBoss","onDamage",self.bossPtr) end
      local death = rawget(_G,"OBJECTDESTRUCTION") or rawget(_G,"OBJECT_DESTROYED")
      if type(death)=="number" then pcall(createObserver,death,"EGSpiderBoss","onDeath",self.bossPtr) end
      self:setState(1)
      createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,"")
      return
    else
      writeData(self.DATA_BOSS_OID, 0)
    end
  end

  if self:getState()==1 then self:d("start: already alive"); return end
  local now, nextA = os.time(), readData(self.DATA_NEXT_SPAWN)
  local delay=5
  if nextA then
    local n=tonumber(nextA)
    if n and n>now then delay=math.max(5, n-now); self:d("cooldown; spawn in "..delay.."s") end
  end
  createEvent(delay,"EGSpiderBoss","spawnBoss",nil,"")
end

function EGSpiderBoss:spawnBoss()
  -- lock to prevent duplicates
  if not self:acquireSpawnLock() then
    self:d("spawnBoss: lock busy; another spawn in progress -> skip")
    return
  end

  -- COOLDOWN GATE
  local cd = cooldownDelay(self)
  if self:getState() == 3 or cd > 0 then
    self:d("spawnBoss: on cooldown; next in " .. tostring(cd) .. "s")
    self:releaseSpawnLock()
    createEvent(math.max(cd, 30), "EGSpiderBoss", "spawnBoss", nil, "")
    return
  end

  -- adopt existing boss if saved OID is valid
  local savedOID = readData(self.DATA_BOSS_OID)
  if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 then
    local existing = getSceneObject(tonumber(savedOID))
    if existing then
      self:d("spawnBoss: existing boss detected (OID "..tostring(savedOID)..") -> adopt/skip")
      self.bossPtr, self.bossOID = existing, tonumber(savedOID)
      self._wave75, self._wave50, self._wave25 = false,false,false
      self:setState(1)
      self:releaseSpawnLock()
      createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,"")
      return
    else
      writeData(self.DATA_BOSS_OID, 0)
    end
  end

  if self.bossPtr or self.bossOID then self:d("spawnBoss: already tracked; skip"); self:releaseSpawnLock(); return end
  local st=self:getState(); if st==1 or st==2 then self:d("spawnBoss: state="..st.." skip"); self:releaseSpawnLock(); return end
  self:setState(2)

  local x,y,z = pickDrySpawnPoint(self.PLANET, self.SPAWN_POINTS, 12)
  if not x then
    self:d("no dry spawn point; retry later")
    self:setState(0); self:releaseSpawnLock()
    local cd2 = cooldownDelay(self); createEvent((cd2>0) and cd2 or 300,"EGSpiderBoss","spawnBoss",nil,"")
    return
  end
  if not preflight(self.PLANET,x,z,y) then
    self:d("preflight failed; retry later")
    self:setState(0); self:releaseSpawnLock()
    local cd2 = cooldownDelay(self); createEvent((cd2>0) and cd2 or 300,"EGSpiderBoss","spawnBoss",nil,"")
    return
  end

  self:d(string.format("SPAWN LOCATION SELECTED -> (%0.0f, %0.0f, %0.0f) on %s", x, z, y, self.PLANET))

  local pBoss, sig = trySpawnMobile(self.PLANET, self.BOSS_TEMPLATE, 0, x, z, y, 0, 0)
  if not pBoss then
    self:d("spawnMobile failed; retry later")
    self:setState(0); self:releaseSpawnLock()
    local cd2 = cooldownDelay(self); createEvent((cd2>0) and cd2 or 300,"EGSpiderBoss","spawnBoss",nil,"")
    return
  end

  self:d(string.format("SPAWNED BOSS @ (%0.0f, %0.0f, %0.0f) [sig=%s]", x, z, y, sig))

  self.bossPtr = pBoss
  self.resolveMisses = 0
  self._wave75, self._wave50, self._wave25 = false,false,false
  soDelVar(pBoss, "wb_wave_75"); soDelVar(pBoss, "wb_wave_50"); soDelVar(pBoss, "wb_wave_25")

  -- attempt immediate bind; finalize will retry if needed
  pcall(function()
    local so = LuaSceneObject(pBoss)
    if so then
      local oid = so:getObjectID()
      if oid and tonumber(oid) and tonumber(oid) > 0 then
        self.bossOID = tonumber(oid)
        writeData(self.DATA_BOSS_OID, self.bossOID)
      end
    end
  end)

  self._finalizeTries = 0
  createEvent(1, "EGSpiderBoss", "finalizeBoss", nil, "")
end

function EGSpiderBoss:finalizeBoss()
  if not self.bossPtr then
    self:d("finalize: no bossPtr; release lock and retry later")
    self:setState(0)
    self:releaseSpawnLock()
    local cd = cooldownDelay(self); createEvent((cd>0) and cd or 30,"EGSpiderBoss","spawnBoss",nil,"")
    return
  end

  -- ensure OID
  if not (self.bossOID and tonumber(self.bossOID) and tonumber(self.bossOID) > 0) then
    if not bindAndPersistOID(self, self.bossPtr) then
      self._finalizeTries = (self._finalizeTries or 0) + 1
      if self._finalizeTries < 10 then
        createEvent(1, "EGSpiderBoss", "finalizeBoss", nil, "")
        return
      else
        self:d("finalize: failed to bind OID; cleaning up and retrying later")
        local so = LuaSceneObject(self.bossPtr)
        if so then so:destroyObjectFromWorld(); so:destroyObjectFromDatabase() end
        self.bossPtr, self.bossOID = nil, nil
        self:setState(0)
        self:releaseSpawnLock()
        local cd = cooldownDelay(self); createEvent((cd>0) and cd or 30,"EGSpiderBoss","spawnBoss",nil,"")
        return
      end
    end
  end

  -- de-dup vs saved OID (keep saved if alive)
  local savedOID = readData(self.DATA_BOSS_OID)
  if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 and tonumber(savedOID) ~= self.bossOID then
    local existing = getSceneObject(tonumber(savedOID))
    if existing then
      self:d("finalize: DUPLICATE -> keep existing "..tostring(savedOID)..", remove new "..tostring(self.bossOID))
      local soNew = LuaSceneObject(self.bossPtr)
      if soNew then soNew:destroyObjectFromWorld(); soNew:destroyObjectFromDatabase() end
      self.bossPtr, self.bossOID = existing, tonumber(savedOID)
      self:setState(1)
      local dmg = rawget(_G,"DAMAGERECEIVED") or rawget(_G,"COMBATDAMAGE") or rawget(_G,"DAMAGE")
      if type(dmg)=="number" then pcall(createObserver,dmg,"EGSpiderBoss","onDamage",self.bossPtr) end
      local death = rawget(_G,"OBJECTDESTRUCTION") or rawget(_G,"OBJECT_DESTROYED")
      if type(death)=="number" then pcall(createObserver,death,"EGSpiderBoss","onDeath",self.bossPtr) end
      self:releaseSpawnLock()
      createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,"")
      return
    end
  end

  -- our current boss is canonical; persist OID, reset gates
  writeData(self.DATA_BOSS_OID, self.bossOID)
  waveClearAll(self.bossOID)
  soDelVar(self.bossPtr, "wb_wave_75"); soDelVar(self.bossPtr, "wb_wave_50"); soDelVar(self.bossPtr, "wb_wave_25")
  self._wave75, self._wave50, self._wave25 = false,false,false

  -- attach observers
  local candidates = {"DAMAGERECEIVED","COMBATDAMAGE","DAMAGE"}
  for _,name in ipairs(candidates) do
    local ev = rawget(_G, name)
    if type(ev) == "number" then pcall(createObserver, ev, "EGSpiderBoss", "onDamage", self.bossPtr) end
  end
  local deathEv = rawget(_G,"OBJECTDESTRUCTION") or rawget(_G,"OBJECT_DESTROYED")
  if type(deathEv) == "number" then pcall(createObserver, deathEv, "EGSpiderBoss", "onDeath", self.bossPtr) end

  self:setState(1)
  self:d("finalize: OID bound (" .. tostring(self.bossOID) .. "); observers attached")
  self:releaseSpawnLock()
  createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,"")
end

-- ===== tick (fallback; throttled) =====
function EGSpiderBoss:tick()
  if not self.bossPtr and self.bossOID and tonumber(self.bossOID)>0 then
    local p = getSceneObject(tonumber(self.bossOID))
    if p then self.bossPtr = p; self.resolveMisses = 0 end
  end
  if not self.bossPtr then createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,""); return end

  local co = LuaCreatureObject(self.bossPtr)
  if not co then createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,""); return end

  local max0 = co:getMaxHAM(0) or 0
  if max0 <= 0 then createEvent(self.TICK_IDLE_SEC or 10,"EGSpiderBoss","tick",nil,""); return end

  local pAll  = hamPercentAll9(co)
  local pHP   = healthPercent(co)
  local percent = (pAll < pHP) and pAll or pHP

  if self.VERBOSE_TICK then
    local now = os.time()
    local pctChanged = math.abs(percent - (self._lastTickPct or 999)) >= (self.LOG_PCT_STEP or 5)
    local timeOk     = (now - (self._lastTickTime or 0)) >= (self.LOG_MIN_PERIOD or 30)
    if pctChanged or timeOk then
      self:d(string.format("tick: boss %% = %.1f (hp=%.1f, min9=%.1f)", percent, pHP, pAll))
      self._lastTickPct  = percent
      self._lastTickTime = now
    end
  end

  -- wave triggers (gated)
  local f75 = self._wave75 or waveDone(self.bossOID, "75") or soHasVar(self.bossPtr, "wb_wave_75")
  local f50 = self._wave50 or waveDone(self.bossOID, "50") or soHasVar(self.bossPtr, "wb_wave_50")
  local f25 = self._wave25 or waveDone(self.bossOID, "25") or soHasVar(self.bossPtr, "wb_wave_25")

  if (not f75) and percent <= 75 then
    self._wave75 = true; waveMark(self.bossOID, "75"); soSetVar(self.bossPtr, "wb_wave_75", 1)
    self:d("tick: threshold 75 -> spawning helpers (gated)")
    self:spawnWave(self.bossPtr, "wb_wave_75")
  end
  if (not f50) and percent <= 50 then
    self._wave50 = true; waveMark(self.bossOID, "50"); soSetVar(self.bossPtr, "wb_wave_50", 1)
    self:d("tick: threshold 50 -> spawning helpers (gated)")
    self:spawnWave(self.bossPtr, "wb_wave_50")
  end
  if (not f25) and percent <= 25 then
    self._wave25 = true; waveMark(self.bossOID, "25"); soSetVar(self.bossPtr, "wb_wave_25", 1)
    self:d("tick: threshold 25 -> spawning helpers (gated)")
    self:spawnWave(self.bossPtr, "wb_wave_25")
  end

  local inCombat = false
  pcall(function() if co.isInCombat and co:isInCombat() then inCombat = true end end)
  local delay = ((percent >= 99.9) and not inCombat) and (self.TICK_IDLE_SEC or 10) or (self.TICK_ACTIVE_SEC or 2)
  createEvent(delay, "EGSpiderBoss", "tick", nil, "")
end

-- ===== observers =====
function EGSpiderBoss:onDamage(pBoss, pAttacker, damage)
  if not pBoss then return 0 end
  local co = LuaCreatureObject(pBoss); if not co then return 0 end

  local pAll = hamPercentAll9(co)
  local pHP  = healthPercent(co)
  local percent = (pAll < pHP) and pAll or pHP

  local f75 = self._wave75 or waveDone(self.bossOID, "75") or soHasVar(pBoss, "wb_wave_75")
  local f50 = self._wave50 or waveDone(self.bossOID, "50") or soHasVar(pBoss, "wb_wave_50")
  local f25 = self._wave25 or waveDone(self.bossOID, "25") or soHasVar(pBoss, "wb_wave_25")

  if (not f75) and percent <= 75 then
    self._wave75 = true; waveMark(self.bossOID, "75"); soSetVar(pBoss,"wb_wave_75",1)
    self:d("onDamage: threshold 75 -> spawning helpers (gated)")
    self:spawnWave(pBoss, "wb_wave_75")
  end
  if (not f50) and percent <= 50 then
    self._wave50 = true; waveMark(self.bossOID, "50"); soSetVar(pBoss,"wb_wave_50",1)
    self:d("onDamage: threshold 50 -> spawning helpers (gated)")
    self:spawnWave(pBoss, "wb_wave_50")
  end
  if (not f25) and percent <= 25 then
    self._wave25 = true; waveMark(self.bossOID, "25"); soSetVar(pBoss,"wb_wave_25",1)
    self:d("onDamage: threshold 25 -> spawning helpers (gated)")
    self:spawnWave(pBoss, "wb_wave_25")
  end
  return 0
end

function EGSpiderBoss:onDeath(pBoss, pKiller)
  self:d("onDeath: schedule 12h respawn")
  self:setState(3)                      -- cooldown
  writeData(self.DATA_BOSS_OID, 0)      -- clear canonical OID
  self.bossPtr, self.bossOID = nil, nil
  local nextAt = os.time() + self.RESPAWN_SECONDS
  writeData(self.DATA_NEXT_SPAWN, nextAt)
  -- schedule a spawn attempt; spawnBoss will gate on cooldown
  createEvent(self.RESPAWN_SECONDS, "EGSpiderBoss", "spawnBoss", nil, "")
  return 0
end

-- ===== helper spawner =====
function EGSpiderBoss:spawnWave(pBoss, flagName)
  if not pBoss then return end
  local so = LuaSceneObject(pBoss); if not so then return end

  local px,py,pz = so:getPositionX(), so:getPositionY(), so:getPositionZ()
  local COUNT   = (self.WAVE_COUNTS  and self.WAVE_COUNTS.cavern_spider)  or 10
  local SCATTER = (self.WAVE_SCATTER and self.WAVE_SCATTER.cavern_spider) or 4

  local function polarAround(minR,maxR)
    local ang = math.random()*6.283185307179586
    local r   = math.random(minR*100, maxR*100)/100.0
    return px + math.cos(ang)*r, py + math.sin(ang)*r
  end

  local spawned, attempts, MAX_ATTEMPTS = 0, 0, COUNT*6
  while spawned<COUNT and attempts<MAX_ATTEMPTS do
    attempts = attempts + 1
    local sx,sy = polarAround(1.5, SCATTER)
    local ok = spotIsDryAndValid(self.PLANET, sx, sy)
    if not ok then sx,sy = polarAround(SCATTER+2, SCATTER+5); ok = spotIsDryAndValid(self.PLANET, sx, sy) end
    if ok then
      local sz = safeTerrainZ(sx, sy)
      local mob = select(1, trySpawnMobile(self.PLANET, "cavern_spider", 0, sx, sz, sy, math.random(0,359), 0))
      if mob then spawned = spawned + 1 end
    end
  end
  self:d(string.format("wave %s: spawned %d/%d cavern_spider (attempts=%d)", tostring(flagName), spawned, COUNT, attempts))
end
