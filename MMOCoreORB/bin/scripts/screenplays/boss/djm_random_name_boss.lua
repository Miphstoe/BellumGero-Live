-- ##############################################################
-- djm_random_name_boss.lua — World Boss with random name & galaxy broadcast
-- Awards Force Rank XP (force_rank_xp) to eligible players on death/loot.
-- Tracks damage participants; optionally awards nearby players.
-- Despawns automatically after 6 hours and respawns at a new location.
-- Respawn happens only by explicit timers (no early watchdog spawns).
-- ##############################################################

-- ===== Config =====
local ENABLE_REPEAT_BROADCAST            = true
local INITIAL_BROADCAST_DELAY_SECONDS    = 120        -- 2 min for testing; set 0 in prod
local DEBUG_LOGS                         = true       -- master debug toggle

-- Despawn after 6 hours and respawn elsewhere
local LIFETIME_SECONDS                   = 6 * 60 * 60

-- ===== FRS reward config =====
local FRS_REWARD_AMOUNT                  = 250
local FRS_MIN_RANK_INDEX                 = 4          -- Knight usually starts at rank_04
local ENABLE_AWARD_TO_NEARBY             = true       -- also award eligible players near boss/corpse
local NEARBY_REWARD_RADIUS               = 64         -- meters

-- Debug knobs for FRS
local FRS_DEBUG_LOGS                     = false
local FRS_DEBUG_NOTIFY_PLAYER            = false
local FRS_IGNORE_ELIGIBILITY_FOR_TEST    = false

-- ===== Name picker (fallback; your external randomBossName() takes precedence) =====
if type(randomBossName) ~= "function" then
  local POOL = {
    "Humdinger","Hellguard","Slug","Mafo","Adan","Pastorius","Udon",
    "Vinzent","Valmor","Cas-Wan","GrumpyOptimism","Chyna","EnderWookie","Chuckertons","Xydren",
  }
  if not _G.__BOSS_NAME_SEEDED then
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,9)))
    _G.__BOSS_NAME_SEEDED = true
  end
  function randomBossName()
    local p = POOL
    if type(p) ~= "table" or #p == 0 then return "Nameless Terror" end
    return p[math.random(#p)]
  end
  print(string.format("[DJM] Fallback name pool active (%d names).", #(POOL or {})))
end

-- ===== ScreenPlay =====
djm_random_name_boss = ScreenPlay:new {
  numberOfActs = 1,
  template = "dark_jedi_master",

  respawnSeconds = 60 * 60,               -- 1 hour
  broadcastIntervalSeconds = 2 * 60 * 60, -- 2 hours

  planets = { "tatooine","naboo","corellia","yavin4","endor","dantooine","lok","talus","rori" },

  spawnRects = {
    tatooine  = { {minX=-7000,maxX=7000,minY=-7000,maxY=7000} },
    naboo     = { {minX=-5000,maxX=5000,minY=-5000,maxY=5000} },
    corellia  = { {minX=-7000,maxX=7000,minY=-7000,maxY=7000} },
    yavin4    = { {minX=-7000,maxX=7000,minY=-7000,maxY=7000} },
    endor     = { {minX=-5000,maxX=5000,minY=-5000,maxY=5000} },
    dantooine = { {minX=-6000,maxX=6000,minY=-6000,maxY=6000} },
    lok       = { {minX=-5000,maxX=5000,minY=-5000,maxY=5000} },
    talus     = { {minX=-6000,maxX=6000,minY=-6000,maxY=6000} },
    rori      = { {minX=-6000,maxX=6000,minY=-6000,maxY=6000} },
  }
}
registerScreenPlay("djm_random_name_boss", true)

-- ===== Globals for resilience & participation =====
_G.__DJM_BOSS_ALIVE             = _G.__DJM_BOSS_ALIVE or false
_G.__DJM_RESPAWN_PENDING        = _G.__DJM_RESPAWN_PENDING or false
_G.__DJM_LAST_DEACTIVATED_AT    = _G.__DJM_LAST_DEACTIVATED_AT or 0
_G.__DJM_CURRENT_BOSS_OID       = _G.__DJM_CURRENT_BOSS_OID or nil  -- alive boss (if any)
_G.__DJM_LAST_BOSS_OID          = _G.__DJM_LAST_BOSS_OID or nil     -- most recently dead boss
_G.__DJM_DAMAGE_PLAYERS         = _G.__DJM_DAMAGE_PLAYERS or {}     -- mobOID -> { [playerOID]=true }
_G.__DJM_AWARDED_FOR_OID        = _G.__DJM_AWARDED_FOR_OID or {}    -- mobOID -> true (already paid)

-- ===== Utils =====
local function log(fmt, ...) if DEBUG_LOGS then print("[DJM] " .. string.format(fmt, ...)) end end
local function frs_log(fmt, ...) if FRS_DEBUG_LOGS then print("[DJM-FRS] " .. string.format(fmt, ...)) end end
local function shuffle(t) for i=#t,2,-1 do local j=math.random(i); t[i],t[j]=t[j],t[i] end end
local function safeZ(planet, x, y) local ok,h=pcall(getTerrainHeight,planet,x,y); return (ok and type(h)=="number") and h or 0 end
local function enabledPlanets(self)
  local out = {}
  for _,p in ipairs(self.planets) do
    if isZoneEnabled(p) and self.spawnRects[p] and #self.spawnRects[p]>0 then table.insert(out,p) end
  end
  return out
end

-- robust player test
local function isPlayerPtr(p)
  if p == nil then return false end
  local ok, res = pcall(function() return SceneObject(p):isPlayerCreature() end)
  return ok and res == true
end

-- distance helper (zone fallback)
local function withinRadius(planet, cx, cy, p, radius)
  if p == nil then return false end
  local so = SceneObject(p); if so == nil then return false end
  if (so:getZoneName() or "") ~= (planet or "") then return false end
  local x = so:getWorldPositionX() or 0
  local y = so:getWorldPositionY() or 0
  local dx, dy = x - cx, y - cy
  return (dx*dx + dy*dy) <= (radius*radius)
end

-- ===== Terrain safety (water & slope blacklist) =====
-- Tunables
local MAX_SLOPE_DEGREES       = 18      -- stricter: reject anything steeper than ~18°
local SLOPE_SAMPLE_METERS     = 10      -- larger gradient probe window
local FLATNESS_RING_RADIUS    = 8       -- small 16x16m patch must be fairly level
local FLATNESS_RING_STEP      = 4       -- sampling step within that patch
local FLATNESS_MAX_DELTA      = 1.5     -- max height change across the patch (meters)

local MAX_ATTEMPTS_PER_PLANET = 40      -- tries per planet before moving on
local MAX_TOTAL_ATTEMPTS      = 200     -- hard cap across all planets

-- Optional: manual rectangular masks (water/impassable zones) per planet.
local BLACKLIST_RECTS = {
  -- example:
  -- naboo = {
  --   {minX=-4000, maxX=-1000, minY=2000, maxY=5000, reason="Great Lake"},
  -- },
}

local function isInMaskedRect(planet, x, y)
  local masks = BLACKLIST_RECTS[planet]
  if not masks then return false end
  for _,m in ipairs(masks) do
    if x >= m.minX and x <= m.maxX and y >= m.minY and y <= m.maxY then
      return true
    end
  end
  return false
end

-- Water check (uses any available API; falls back to masks)
local function isWaterAt(planet, x, y, zGuess)
  if type(getWaterHeight) == "function" then
    local ok, wh = pcall(getWaterHeight, planet, x, y)
    if ok and type(wh) == "number" then
      return (zGuess or 0) <= (wh + 0.25)
    end
  end
  if type(isWater) == "function" then
    local ok, res = pcall(isWater, planet, x, y)
    if ok and res == true then return true end
  end
  return isInMaskedRect(planet, x, y)
end

-- Helper: max slope from center to 8 neighbors at distance d
local function localSlopeMax(planet, x, y, d)
  local h0 = safeZ(planet, x, y)
  local pts = {
    { d,  0}, {-d,  0}, { 0,  d}, { 0, -d},
    { d,  d}, { d, -d}, {-d,  d}, {-d, -d},
  }
  local maxAngle = 0
  for _,o in ipairs(pts) do
    local h  = safeZ(planet, x + o[1], y + o[2])
    local run = math.sqrt(o[1]*o[1] + o[2]*o[2])
    local rise = math.abs(h - h0)
    local angle = math.deg(math.atan(rise / run))
    if angle > maxAngle then maxAngle = angle end
  end
  return maxAngle
end

-- Helper: ensure a small patch around the point is fairly level
local function flatnessOK(planet, x, y, r, step, maxDelta)
  local h0 = safeZ(planet, x, y)
  for dx = -r, r, step do
    for dy = -r, r, step do
      if not (dx == 0 and dy == 0) then
        local h = safeZ(planet, x + dx, y + dy)
        if math.abs(h - h0) > maxDelta then return false end
      end
    end
  end
  return true
end

-- Final slope test used by spawner
local function slopeOK(planet, x, y)
  local angle = localSlopeMax(planet, x, y, SLOPE_SAMPLE_METERS)
  if angle > MAX_SLOPE_DEGREES then return false, angle end
  if not flatnessOK(planet, x, y, FLATNESS_RING_RADIUS, FLATNESS_RING_STEP, FLATNESS_MAX_DELTA) then
    return false, angle
  end
  return true, angle
end

-- If a chosen point fails, search nearby for a safe spot
local function findFlatNearby(planet, x, y, maxRadius, stepMeters)
  local step = stepMeters or 6
  local maxR = maxRadius or 60
  for r = step, maxR, step do
    -- sample a circle; 24 samples is fine
    for a = 0, 345, 15 do
      local rad = math.rad(a)
      local tx  = x + math.cos(rad) * r
      local ty  = y + math.sin(rad) * r
      local tz  = safeZ(planet, tx, ty)
      if not isInMaskedRect(planet, tx, ty) and not isWaterAt(planet, tx, ty, tz) then
        local ok = slopeOK(planet, tx, ty)
        if ok then return tx, ty, tz end
      end
    end
  end
  return nil
end


-- ===== Galaxy broadcast =====
local GAL_STR_FALLBACKS = { "broadcastGalaxy", "broadcastMessage", "galaxyBroadcast" }
local function doBroadcast(pBoss, msg)
  if type(broadcastToGalaxy) == "function" then
    local ok = pcall(broadcastToGalaxy, pBoss, msg)
    if ok then log("Galaxy broadcast via broadcastToGalaxy(ptr,msg)") return true end
  end
  for _,fname in ipairs(GAL_STR_FALLBACKS) do
    local fn = _G[fname]
    if type(fn)=="function" then
      if pcall(fn, msg) then log("Galaxy broadcast via %s(msg)", fname) return true end
    end
  end
  return false
end

-- ===== FRS helpers =====
local function notifyPlayer(p, msg)
  if not FRS_DEBUG_NOTIFY_PLAYER or not p then return end
  pcall(function() CreatureObject(p):sendSystemMessage(msg) end)
end

-- Prefer CreatureObject:hasSkill(); fallback to global hasSkill(p, skill)
local function coHasSkill(p, skill)
  if p == nil then return false end
  local ok, res = pcall(function() return CreatureObject(p):hasSkill(skill) end)
  if ok and res == true then return true end
  if type(hasSkill) == "function" then
    local ok2, res2 = pcall(hasSkill, p, skill)
    if ok2 and res2 == true then return true end
  end
  return false
end

-- Resolve pet/vehicle/etc. to owning player
local function resolvePlayerFromKiller(pKiller)
  if pKiller == nil then return nil end
  if isPlayerPtr(pKiller) then return pKiller end
  local try = {
    function() local co=CreatureObject(pKiller); return co and co.getPlayerOwner and co:getPlayerOwner() end,
    function() local co=CreatureObject(pKiller); return co and co.getMaster and co:getMaster() end,
    function() local co=CreatureObject(pKiller); return co and co.getLinkedCreature and co:getLinkedCreature() end,
    function() local so=SceneObject(pKiller);    return so and so.getOwner and so:getOwner() end,
  }
  for _,getter in ipairs(try) do
    local ok, owner = pcall(getter)
    if ok and owner and isPlayerPtr(owner) then return owner end
  end
  return nil
end

-- Eligibility: title path (Knight+) + FRS-rank path + numeric fallback
local function isFRSEligible(pCreature)
  if FRS_IGNORE_ELIGIBILITY_FOR_TEST then return true end
  if not isPlayerPtr(pCreature) then return false end

  -- Title skills (e.g. force_title_jedi_rank_03+)
  local TITLE_PREFIXES = { "force_title_jedi_rank_", "force_title_light_rank_", "force_title_dark_rank_" }
  for _,pref in ipairs(TITLE_PREFIXES) do
    for i = 3, 12 do
      local idx = (i < 10) and ("0"..i) or tostring(i)
      if coHasSkill(pCreature, pref .. idx) then return true end
    end
  end
  if coHasSkill(pCreature, "force_title_jedi_master") then return true end

  -- FRS rank boxes (Knight+)
  for i = FRS_MIN_RANK_INDEX, 12 do
    local idx = (i < 10) and ("0"..i) or tostring(i)
    if coHasSkill(pCreature, "force_rank_light_rank_"..idx) or coHasSkill(pCreature, "force_rank_dark_rank_"..idx) then
      return true
    end
  end
  if coHasSkill(pCreature, "force_rank_light_master") or coHasSkill(pCreature, "force_rank_dark_master") then
    return true
  end

  -- Numeric fallback
  if type(getFrsRank) == "function" then
    local ok, rank = pcall(getFrsRank, pCreature)
    if ok and type(rank)=="number" and rank >= FRS_MIN_RANK_INDEX then
      return true
    end
  end
  return false
end

-- Award FRS XP (prefer CreatureObject path)
local function grantFRSXP(pCreature, amount)
  if not isPlayerPtr(pCreature) then return false end
  local ok = pcall(function() CreatureObject(pCreature):awardExperience("force_rank_xp", amount, true) end)
  if ok then notifyPlayer(pCreature, string.format("You received %d FRS XP.", amount)); return true end
  ok = pcall(function() CreatureObject(pCreature):awardExperience("force_rank_xp", amount) end)
  if ok then notifyPlayer(pCreature, string.format("You received %d FRS XP.", amount)); return true end
  if type(awardExperience) == "function" then
    ok = pcall(awardExperience, pCreature, "force_rank_xp", amount)
    if ok then notifyPlayer(pCreature, string.format("You received %d FRS XP.", amount)); return true end
  end
  local pPO = CreatureObject(pCreature):getPlayerObject()
  if pPO ~= nil then
    ok = pcall(function() LuaPlayerObject(pPO):addExperience("force_rank_xp", amount) end)
    if ok then notifyPlayer(pCreature, string.format("You received %d FRS XP.", amount)); return true end
  end
  if JediManager and type(JediManager.awardFRSXP) == "function" then
    ok = pcall(JediManager.awardFRSXP, JediManager, pCreature, amount)
    if ok then notifyPlayer(pCreature, string.format("You received %d FRS XP.", amount)); return true end
  end
  frs_log("All award paths failed for candidate player.")
  return false
end

-- ===== Participation tracker (damage-based) =====
local function trackDamager(pBoss, pAttacker)
  if pBoss == nil or pAttacker == nil then return end
  local soBoss = SceneObject(pBoss); if soBoss == nil then return end
  local mobOID = soBoss:getObjectID(); if mobOID == nil then return end
  local pOwner = isPlayerPtr(pAttacker) and pAttacker or resolvePlayerFromKiller(pAttacker)
  if not pOwner then return end
  local pid = SceneObject(pOwner):getObjectID()
  local set = _G.__DJM_DAMAGE_PLAYERS[mobOID]
  if set == nil then set = {}; _G.__DJM_DAMAGE_PLAYERS[mobOID] = set end
  set[pid] = true
end

function djm_random_name_boss:onBossDamaged(pBoss, pAttacker, _damage)
  trackDamager(pBoss, pAttacker)
  return 0
end

-- Build recipients from killer/looter + nearby + damage participants (by boss OID)
local function collectFRSRecipients(pBossOrCorpse, pKillerOrLooter, mobOID, radius)
  local recipients, seen = {}, {}
  local function add(p) if p and not seen[p] then seen[p]=true; table.insert(recipients, p) end end

  add(pKillerOrLooter)
  if not isPlayerPtr(pKillerOrLooter) then add(resolvePlayerFromKiller(pKillerOrLooter)) end

  -- Nearby helpers
  if pBossOrCorpse ~= nil and radius and radius > 0 then
    if type(getPlayerCreaturesInRange) == "function" then
      local ok, list = pcall(getPlayerCreaturesInRange, pBossOrCorpse, radius)
      if ok and type(list)=="table" then for i=1,#list do add(list[i]) end end
    end
    local so = SceneObject(pBossOrCorpse)
    if so and type(getPlayerCreaturesInRange) == "function" then
      local planet = so:getZoneName() or ""
      local x = so:getWorldPositionX() or 0
      local y = so:getWorldPositionY() or 0
      local ok, list = pcall(getPlayerCreaturesInRange, planet, x, y, radius)
      if ok and type(list)=="table" then for i=1,#list do add(list[i]) end end
    elseif so and type(getPlayerCreaturesInZone) == "function" then
      local planet = so:getZoneName() or ""
      local cx = so:getWorldPositionX() or 0
      local cy = so:getWorldPositionY() or 0
      local ok, list = pcall(getPlayerCreaturesInZone, planet)
      if ok and type(list)=="table" then
        for i=1,#list do local p=list[i]; if withinRadius(planet,cx,cy,p,radius) then add(p) end end
      end
    end
  end

  -- Damage participants
  if mobOID ~= nil then
    local set = _G.__DJM_DAMAGE_PLAYERS[mobOID]
    if set then
      for pid,_ in pairs(set) do
        local p = getSceneObject(tonumber(pid))
        add(p)
      end
    end
  end

  -- Filter to eligible players
  local eligible = {}
  for _,p in ipairs(recipients) do
    if p and SceneObject(p):isPlayerCreature() and isFRSEligible(p) then
      table.insert(eligible, p)
    end
  end
  frs_log("collectFRSRecipients: %d candidates, %d eligible", #recipients, #eligible)
  return eligible
end

local function currentBossOID(pBossOrCorpse)
  local so = pBossOrCorpse and SceneObject(pBossOrCorpse) or nil
  local oid = (so and so:getObjectID()) or _G.__DJM_CURRENT_BOSS_OID or _G.__DJM_LAST_BOSS_OID
  return tonumber(oid)
end

function djm_random_name_boss:rewardFRS(pBossOrCorpse, pKillerOrLooter, mobOID)
  mobOID = mobOID or currentBossOID(pBossOrCorpse)
  if mobOID and _G.__DJM_AWARDED_FOR_OID[mobOID] then return end -- already paid

  local targets = collectFRSRecipients(
    pBossOrCorpse, pKillerOrLooter, mobOID,
    (ENABLE_AWARD_TO_NEARBY and NEARBY_REWARD_RADIUS) or 0
  )

  local awarded = 0
  for _,p in ipairs(targets) do
    if grantFRSXP(p, FRS_REWARD_AMOUNT) then awarded = awarded + 1 end
  end

  if mobOID then
    _G.__DJM_AWARDED_FOR_OID[mobOID] = true
    _G.__DJM_DAMAGE_PLAYERS[mobOID]  = nil
  end

  frs_log("FRS reward summary: %d player(s) paid for boss OID %s", awarded, tostring(mobOID))
end

-- ===== Despawn/marking helpers =====
local function markDeactivated(pBoss)
  _G.__DJM_BOSS_ALIVE = false
  _G.__DJM_LAST_DEACTIVATED_AT = os.time()
  -- keep __DJM_LAST_BOSS_OID and __DJM_CURRENT_BOSS_OID so loot can dedupe against death
  local so = (pBoss ~= nil) and SceneObject(pBoss) or nil
  local oid = (so and so:getObjectID()) or _G.__DJM_CURRENT_BOSS_OID
  if oid ~= nil then
    _G.__DJM_LAST_BOSS_OID = oid
    -- don't nil CURRENT here; let respawn overwrite it
  end
end

function djm_random_name_boss:safeDespawn(pBoss)
  if pBoss == nil then return end
  local so = SceneObject(pBoss)
  if so ~= nil then pcall(function() so:destroyObjectFromWorld() end) end
end

function djm_random_name_boss:scheduleRespawn(seconds)
  _G.__DJM_RESPAWN_PENDING = true
  log("Respawn scheduled in %ds", seconds)
  createEvent(seconds * 1000, "djm_random_name_boss", "onRespawn", nil, "")
end

function djm_random_name_boss:spawnOnce()
  local pool = enabledPlanets(self)
  if #pool == 0 then log("No enabled planets to spawn on."); return nil end

  shuffle(pool)
  local totalTries = 0

  for _, planet in ipairs(pool) do
    local rects = self.spawnRects[planet]
    if not rects or #rects == 0 then goto next_planet end

    for attempt = 1, MAX_ATTEMPTS_PER_PLANET do
      totalTries = totalTries + 1
      if totalTries > MAX_TOTAL_ATTEMPTS then
        log("Spawn aborted: exceeded MAX_TOTAL_ATTEMPTS (%d).", MAX_TOTAL_ATTEMPTS)
        return nil
      end

      -- random candidate
      local r = rects[math.random(#rects)]
      local x = math.random(r.minX, r.maxX)
      local y = math.random(r.minY, r.maxY)
      local z = safeZ(planet, x, y)

      -- reject masked/water
      if isInMaskedRect(planet, x, y) or isWaterAt(planet, x, y, z) then
        goto try_next
      end

      -- slope/flatness check; if it fails, try to "nudge" to a nearby flat spot
      local ok = slopeOK(planet, x, y)
      if not ok then
        local fx, fy, fz = findFlatNearby(planet, x, y, 60, 6)
        if fx then x, y, z = fx, fy, fz else goto try_next end
      end

      -- spawn
      local dir, cell = math.random(0,359), 0
      local pBoss = spawnMobile(planet, self.template, 0, x, z, y, dir, cell)
      if pBoss == nil then
        pBoss = spawnMobile(planet, self.template, 0, x, y, z, dir, cell)
      end

      if pBoss ~= nil then
        local chosenName = (randomBossName and randomBossName()) or "Nameless Terror"
        local co = CreatureObject(pBoss)
        local ok1 = pcall(function() co:setCustomObjectName(chosenName) end)
        if not ok1 then pcall(function() co:setCustomObjectName(chosenName, true) end) end

        createObserver(OBJECTDESTRUCTION, "djm_random_name_boss", "onBossDead",    pBoss)
        createObserver(LOOTCREATURE,      "djm_random_name_boss", "onBossLooted",  pBoss)
        createObserver(DAMAGERECEIVED,    "djm_random_name_boss", "onBossDamaged", pBoss)

        createEvent(LIFETIME_SECONDS * 1000, "djm_random_name_boss", "onLifetimeExpired", pBoss, chosenName)

        _G.__DJM_BOSS_ALIVE       = true
        _G.__DJM_RESPAWN_PENDING  = false
        _G.__DJM_CURRENT_BOSS_OID = SceneObject(pBoss):getObjectID()

        createEvent((INITIAL_BROADCAST_DELAY_SECONDS or 0) * 1000,
                    "djm_random_name_boss", "onInitialBroadcast", pBoss, chosenName)

        if ENABLE_REPEAT_BROADCAST then
          createEvent(self.broadcastIntervalSeconds * 1000,
                      "djm_random_name_boss", "onBroadcastTick", pBoss, chosenName)
        end

        log("Spawned on %s at (%d,%d); name=%s", tostring(planet), x, y, tostring(chosenName))
        return pBoss
      end

      ::try_next::
    end

    log("No valid spot found on %s after %d tries.", planet, MAX_ATTEMPTS_PER_PLANET)
    ::next_planet::
  end

  log("Spawn failed on all candidate planets after %d total tries.", totalTries)
  return nil
end

-- ===== Lifecycle =====
function djm_random_name_boss:start(_p, _a)
  if not _G.__DJM_BOSS_SEEDED then
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,9)))
    _G.__DJM_BOSS_SEEDED = true
  end

  -- trust an existing boss pointer if alive
  if _G.__DJM_CURRENT_BOSS_OID ~= nil then
    local p = getSceneObject(tonumber(_G.__DJM_CURRENT_BOSS_OID))
    if p ~= nil then
      local ok, deadFlag = pcall(function() return CreatureObject(p):isDead() end)
      if ok and (deadFlag == false) then
        _G.__DJM_BOSS_ALIVE = true
        log("start(): existing boss detected; skipping spawn.")
        return
      end
    end
    -- stale pointer
    _G.__DJM_BOSS_ALIVE = false
  end

  if _G.__DJM_BOSS_ALIVE then
    log("start(): boss already alive.")
    return
  end

  local last   = tonumber(_G.__DJM_LAST_DEACTIVATED_AT) or 0
  local now    = os.time()
  local remain = self.respawnSeconds - math.max(0, now - last)

  if last == 0 or remain <= 0 then
    log("start(): spawning immediately.")
    local p = self:spawnOnce()
    if p == nil then
      log("start(): spawn failed; retry in 60s")
      self:scheduleRespawn(60)
    end
  else
    log("start(): scheduling respawn in %ds.", remain)
    self:scheduleRespawn(remain)
  end
end

-- Broadcasts
function djm_random_name_boss:onInitialBroadcast(pBoss, nameFromSpawn)
  if pBoss == nil then return end
  local boss = CreatureObject(pBoss); if not boss or boss:isDead() or boss:isIncapacitated() then return end
  local so = SceneObject(pBoss)
  local planet = so and so:getZoneName() or "unknown"
  local x = math.floor(so and so:getWorldPositionX() or 0)
  local y = math.floor(so and so:getWorldPositionY() or 0)
  local name = (type(nameFromSpawn)=="string" and nameFromSpawn~="") and nameFromSpawn or "Unknown Terror"
  local msg = string.format("[The Jedi Master] %s sighted on %s at (%d, %d).", name, planet, x, y)
  local ok = doBroadcast(pBoss, msg)
  if not ok then log("No usable galaxy broadcast; msg: %s", msg) end
end

function djm_random_name_boss:onBroadcastTick(pBoss, nameFromSpawn)
  if not ENABLE_REPEAT_BROADCAST or pBoss == nil then return end
  local boss = CreatureObject(pBoss); if not boss or boss:isDead() or boss:isIncapacitated() then return end
  local so     = SceneObject(pBoss)
  local planet = so and so:getZoneName() or "unknown"
  local x      = math.floor(so and so:getWorldPositionX() or 0)
  local y      = math.floor(so and so:getWorldPositionY() or 0)
  local name   = (type(nameFromSpawn)=="string" and nameFromSpawn~="") and nameFromSpawn or "Unknown Terror"
  local msg = string.format("[The Jedi Master] %s is still up on %s at (%d, %d). Hunt it down!", name, planet, x, y)
  local ok = doBroadcast(pBoss, msg)
  if not ok then log("Repeat broadcast skipped; no usable galaxy broadcast.") end
  createEvent(djm_random_name_boss.broadcastIntervalSeconds * 1000,
              "djm_random_name_boss", "onBroadcastTick", pBoss, name)
end

-- Lifetime expiry: despawn (no XP) and respawn fresh
function djm_random_name_boss:onLifetimeExpired(pBoss, nameFromSpawn)
  if pBoss == nil then return end
  local boss = CreatureObject(pBoss); if not boss or boss:isDead() or boss:isIncapacitated() then return end
  local so = SceneObject(pBoss)
  local planet = so and so:getZoneName() or "unknown"
  local x = math.floor(so and so:getWorldPositionX() or 0)
  local y = math.floor(so and so:getWorldPositionY() or 0)
  local name = (type(nameFromSpawn)=="string" and nameFromSpawn~="") and nameFromSpawn or "Unknown Terror"
  doBroadcast(pBoss, string.format("[The Jedi Master] %s has vanished from %s at (%d, %d). A new disturbance is felt...", name, planet, x, y))
  djm_random_name_boss:safeDespawn(pBoss)
  markDeactivated(pBoss)
  djm_random_name_boss:scheduleRespawn(5)
end

-- Death observer
function djm_random_name_boss:onBossDead(pBoss, pKiller)
  local oid = currentBossOID(pBoss)
  _G.__DJM_LAST_BOSS_OID = oid
  self:rewardFRS(pBoss, pKiller, oid)
  log("Boss died; respawn in %ds", self.respawnSeconds)
  markDeactivated(pBoss)
  self:scheduleRespawn(self.respawnSeconds)
  return 1
end

-- Loot observer (fallback; guarded per-boss)
function djm_random_name_boss:onBossLooted(pCorpse, pLooter)
  if pCorpse == nil or pLooter == nil then return 0 end
  local oid = _G.__DJM_LAST_BOSS_OID or currentBossOID(pCorpse)
  if oid and _G.__DJM_AWARDED_FOR_OID[oid] then return 0 end  -- already paid at death
  self:rewardFRS(pCorpse, pLooter, oid)
  return 0
end

-- Respawn task (retry until success)
function djm_random_name_boss:onRespawn(_p, _a)
  _G.__DJM_RESPAWN_PENDING = false
  log("onRespawn(): attempting spawn...")
  local p = self:spawnOnce()
  if p == nil then
    log("onRespawn(): spawn failed; retry in 60s")
    self:scheduleRespawn(60)
  else
    log("onRespawn(): spawn succeeded.")
  end
end
