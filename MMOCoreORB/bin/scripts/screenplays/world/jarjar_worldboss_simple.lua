-- Jar Jar World Boss (observerless, resilient)
-- - Random Naboo spawn
-- - Taunts on real damage (rate-limited to 32s)
-- - Galaxy broadcast loop: starts 3 min after boot, repeats every 2h while alive
-- - No observers; single watch loop polls boss HP
-- - All createEvent calls use object=0

print("[JARJAR] loading screenplay: jarjar_worldboss_simple")

JarJarWorldBossSimple = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "JarJarWorldBossSimple"
}
registerScreenPlay("JarJarWorldBossSimple", true)

-- --------------- Config ---------------
JarJarWorldBossSimple.PLANET = "naboo"
JarJarWorldBossSimple.BOSS_TEMPLATES = {
  "jarjar_boss",
  "jarjar_binks_boss"  -- fallback if present
}

-- Respawn window (seconds)
JarJarWorldBossSimple.RESPAWN_MIN_SECONDS = 6 * 60 * 60
JarJarWorldBossSimple.RESPAWN_MAX_SECONDS = 6 * 60 * 60

-- Taunts
JarJarWorldBossSimple.TAUNT_INTERVAL_SECONDS = 32
JarJarWorldBossSimple.TAUNTS = {
  "How wude! Yousa hurting meesa!",
  "Mesa not going down without a fight!",
  "Yousa think yousa can beat Jar Jar?",
  "Uh oh! Big doo-doo this time!",
  "Yousa in trouble now!",
  "Ouchie! Yousa stop that!",
  "Mesa clumsy, but mesa tough!",
  "Gungans never give up!",
  "Yousa gonna regret that!",
  "This all your fault? Maybe mesa fault...",

  "Halt! Mesa no like dis!",
  "Dat smarts!",
  "Oyi oyi, dats a spicy hit!",
  "Big boomers coming!",
  "Yousa pointy stick hurts!",
  "Back off, bombad warrior here!",
  "Stop pokin meesa!",
  "Oof! Right in the gizzards!",
  "Yousa better run!",
  "Dis fight gettin bombad!",

  "Meesa call dis a strategy!",
  "Oops! That was on purpose!",
  "Yousa mess with wrong Gungan!",
  "Meesa have friends... somewhere...",
  "Step aside, meesa workin!",
  "Uh... meesa meant to do dat!",
  "Okeeday, playtime over!",
  "No more mister nice Gungan!",
  "Yousa gettin on meesa nerves!",
  "Meesa make yousa sorry!",

  "Swamp take yousa!",
  "Yousa no like when meesa trips!",
  "Meesa sees yousa!",
  "Shiny, shiny... wait, FOCUS!",
  "Wesa warriors, not pushovers!",
  "Dis one for Boss Nass!",
  "Hesa meanie!",
  "Yousa clanka-brained!",
  "Crikey, krayt brain!",
  "Meesa gonna bonk yousa!"
}

-- Broadcast timing
JarJarWorldBossSimple.BCAST_BOOT_DELAY_SECONDS = 180   -- 3 minutes after boot
JarJarWorldBossSimple.BCAST_REPEAT_SECONDS     = 7200  -- every 2 hours

-- Spawn points (X, Y)
JarJarWorldBossSimple.SPAWN_POINTS = {
  {-1500,-3000},{-2100,-3200},{-2700,-3400},{-3300,-3600},
  {-3900,-3800},{-5100,-4200},{-5650,-4400},{0,0},
  {-6150,-4600},{-6600,-4800},{-6950,-4950},{-7250,-5100}
}

-- Persisted keys
JarJarWorldBossSimple.DATA_BOSS_OID      = "JARJAR.bossOID"
JarJarWorldBossSimple.DATA_NEXT_SPAWN    = "JARJAR.nextSpawnAt"
JarJarWorldBossSimple.DATA_LAST_X        = "JARJAR.lastX"
JarJarWorldBossSimple.DATA_LAST_Y        = "JARJAR.lastY"
JarJarWorldBossSimple.DATA_LAST_TAUNT    = "JARJAR.lastTauntAt"
JarJarWorldBossSimple.DATA_LAST_HP       = "JARJAR.lastHP"
JarJarWorldBossSimple.DATA_NEXT_BCAST_AT = "JARJAR.nextGalaxyBcastAt"  -- <— NEW

-- Runtime
JarJarWorldBossSimple.bossPtr = nil

-- --------------- Utils ---------------
local function _try(f, ...) return pcall(f, ...) end
local function d(msg) print("[JARJAR] " .. tostring(msg)) end

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

local function trySpawnMobile(planet, tpl, respawn, x, z, y, dir, cell)
  local ok, mob
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir,cell)  if ok and mob then return mob,"A1" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell,dir)  if ok and mob then return mob,"A2" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir,cell)  if ok and mob then return mob,"B1" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell,dir)  if ok and mob then return mob,"B2" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir)       if ok and mob then return mob,"C1" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir)       if ok and mob then return mob,"C2" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell)      if ok and mob then return mob,"D1" end
  ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell)      if ok and mob then return mob,"D2" end
  return nil,"NONE"
end

local function pickSpawn()
  local pts = JarJarWorldBossSimple.SPAWN_POINTS
  if not pts or #pts == 0 then return nil end
  local i = math.random(1, #pts)
  local x = tonumber(pts[i][1]) or 0
  local y = tonumber(pts[i][2]) or 0
  local z = safeTerrainZ(x, y)
  local h = math.random(0, 359)
  return x, y, z, h
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

-- ------------- Broadcast helper -------------
function JarJarWorldBossSimple:galaxyBroadcast(msg, ctx)
  msg = tostring(msg or "")
  if type(broadcastToGalaxy) == "function" then
    if pcall(broadcastToGalaxy, ctx, msg) then return true end
    if pcall(broadcastToGalaxy, nil, msg) then return true end
    if pcall(broadcastToGalaxy, msg) then return true end
  end
  print("[JARJAR][BCAST-FAIL] " .. msg)
  return false
end

-- --------------- Boot ---------------
function JarJarWorldBossSimple:start()
  -- Seed the next broadcast time (first broadcast 3 minutes after boot)
  writeData(self.DATA_NEXT_BCAST_AT, os.time() + (self.BCAST_BOOT_DELAY_SECONDS or 180))

  -- Rebind boss if already present, else schedule spawn respecting cooldown
  local saved = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
  if saved > 0 then
    local p = getSceneObject(saved)
    if p ~= nil then
      self.bossPtr = p
      _try(function()
        local co = LuaCreatureObject(p)
        if co then writeData(self.DATA_LAST_HP, co:getHAM(0) or 0) end
      end)
      createEvent(1000, "JarJarWorldBossSimple", "watchLoop", 0, "")
      return
    end
  end

  local nextAt = tonumber(readData(self.DATA_NEXT_SPAWN) or 0) or 0
  local now = os.time()
  local delay = 5
  if nextAt > now then delay = (nextAt - now) end
  createEvent(delay * 1000, "JarJarWorldBossSimple", "spawnBoss", 0, "")
end

-- --------------- Spawning ---------------
function JarJarWorldBossSimple:spawnBoss(_, _)
  d("spawnBoss: enter")
  local x, y, z, heading = pickSpawn()
  if not x then d("spawnBoss: no spawn point"); return 0 end
  d(string.format("spawnBoss: picked (%d, %d, %.2f) heading=%d", x, y, z, heading))

  local pBoss, sig, usedTpl
  for _,tpl in ipairs(self.BOSS_TEMPLATES or {}) do
    pBoss, sig = trySpawnMobile(self.PLANET, tpl, 0, x, z, y, heading, 0)
    if pBoss then usedTpl = tpl; break end
  end

  if not pBoss then
    d("spawnBoss: spawnMobile failed for all templates; retrying in 60s")
    createEvent(60 * 1000, "JarJarWorldBossSimple", "spawnBoss", 0, "")
    return 0
  end

  d(string.format("spawn OK via sig=%s template=%s", tostring(sig), tostring(usedTpl)))
  writeData(self.DATA_LAST_X, x)
  writeData(self.DATA_LAST_Y, y)

  createEvent(1, "JarJarWorldBossSimple", "bindAfterSpawn", pBoss, "")
  return 0
end

function JarJarWorldBossSimple:bindAfterSpawn(pBoss, _)
  if pBoss == nil then
    d("bindAfterSpawn: pBoss is nil, aborting")
    return 0
  end

  local oid = 0
  local ok = pcall(function()
    local so = SceneObject(pBoss)
    if so and so.getObjectID then oid = so:getObjectID() end
  end)

  if not ok or (tonumber(oid) or 0) == 0 then
    -- Retry up to 5 times before giving up
    local retryCount = tonumber(readData("JARJAR.bindRetryCount") or 0) or 0
    if retryCount < 5 then
      writeData("JARJAR.bindRetryCount", retryCount + 1)
      createEvent(500, "JarJarWorldBossSimple", "bindAfterSpawn", pBoss, "")
      return 0
    else
      d("bindAfterSpawn: failed after 5 retries, giving up")
      writeData("JARJAR.bindRetryCount", 0)
      return 0
    end
  end

  -- Reset retry counter on success
  writeData("JARJAR.bindRetryCount", 0)

  writeData(self.DATA_BOSS_OID, tonumber(oid))
  self.bossPtr = pBoss

  -- Prime last HP & taunt timer
  pcall(function()
    local co = LuaCreatureObject(pBoss)
    if co and co.getHAM then
      local hp = co:getHAM(0)
      if hp and type(hp) == "number" then
        writeData(self.DATA_LAST_HP, hp)
      end
    end
  end)
  writeData(self.DATA_LAST_TAUNT, os.time() - (self.TAUNT_INTERVAL_SECONDS or 32))

  -- If no broadcast schedule exists (e.g., after a death), seed one now.
  local nextB = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
  if nextB == 0 then
    writeData(self.DATA_NEXT_BCAST_AT, os.time() + (self.BCAST_BOOT_DELAY_SECONDS or 180))
  end

  -- Save initial XY for broadcasts
  pcall(function()
    local so = SceneObject(pBoss)
    if so and so.getPositionX and so.getPositionY then
      local px = so:getPositionX()
      local py = so:getPositionY()
      if px and py then
        writeData(self.DATA_LAST_X, px)
        writeData(self.DATA_LAST_Y, py)
      end
    end
  end)

  createEvent(1000, "JarJarWorldBossSimple", "watchLoop", 0, "")
  return 0
end

-- --------------- Watch Loop ---------------
function JarJarWorldBossSimple:watchLoop(_, _)
  local oid = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
  if oid <= 0 then return 0 end

  local pBoss = getSceneObject(oid)
  if pBoss == nil then
    createEvent(2000, "JarJarWorldBossSimple", "watchLoop", 0, "")
    return 0
  end
  self.bossPtr = pBoss

  local co = nil
  local coSuccess = pcall(function()
    co = LuaCreatureObject(pBoss)
  end)

  if not coSuccess or not co then
    createEvent(2000, "JarJarWorldBossSimple", "watchLoop", 0, "")
    return 0
  end

  -- Death handling (with pcall protection)
  local isDead = false
  pcall(function()
    isDead = co:isDead()
  end)

  if isDead then
    d("watchLoop: detected death; scheduling cooldown")
    self.bossPtr = nil
    writeData(self.DATA_BOSS_OID, 0)
    writeData(self.DATA_NEXT_BCAST_AT, 0) -- <— stop further broadcasts
    local when = os.time() + math.random(self.RESPAWN_MIN_SECONDS, self.RESPAWN_MAX_SECONDS)
    writeData(self.DATA_NEXT_SPAWN, when)
    local delay = math.max(5, when - os.time())
    createEvent(delay * 1000, "JarJarWorldBossSimple", "spawnBoss", 0, "")
    return 0
  end

  -- Update location for broadcasts
  _try(function()
    local so = LuaSceneObject(pBoss)
    if so then
      writeData(self.DATA_LAST_X, so:getPositionX() or 0)
      writeData(self.DATA_LAST_Y, so:getPositionY() or 0)
    end
  end)

  local now = os.time()

  -- Due broadcast? (robust against reloads)
  local nextB = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
  if nextB > 0 and now >= nextB then
    local px = tonumber(readData(self.DATA_LAST_X) or 0) or 0
    local py = tonumber(readData(self.DATA_LAST_Y) or 0) or 0
    local planet = self.PLANET
    _try(function()
      local so = SceneObject(pBoss)
      if so and so.getZoneName then planet = so:getZoneName() or planet end
    end)
    local msg = string.format("[NOTICE] Jar Jar Binks has been sighted near (%.0f, %.0f) on %s.", px, py, planet)
    self:galaxyBroadcast(msg, pBoss)
    writeData(self.DATA_NEXT_BCAST_AT, now + (self.BCAST_REPEAT_SECONDS or 7200))
  end

  -- Damage -> taunt (rate-limited)
  local lastTaunt = tonumber(readData(self.DATA_LAST_TAUNT) or 0) or 0
  local lastHP    = tonumber(readData(self.DATA_LAST_HP)    or 0) or 0
  local curHP = lastHP

  -- Safely get current HP
  if co then
    pcall(function()
      local hp = co:getHAM(0)
      if hp and type(hp) == "number" then
        curHP = hp
      end
    end)
  end

  if curHP < lastHP and (now - lastTaunt) >= (self.TAUNT_INTERVAL_SECONDS or 32) then
    local lines = self.TAUNTS or {}
    local n = #lines
    if n > 0 then
      local idx = getRandomNumber(1, n)
      _try(spatialChat, pBoss, lines[idx])
      writeData(self.DATA_LAST_TAUNT, now)
    end
  end
  writeData(self.DATA_LAST_HP, curHP)

  -- Keep looping while alive
  createEvent(1000, "JarJarWorldBossSimple", "watchLoop", 0, "")
  return 0
end
