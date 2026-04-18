-- 4-Tiered Scheduled Event - Mobs get progressively harder every 15 minutes
-- Tier 1: 0-15 minutes (Easy)
-- Tier 2: 15-30 minutes (Medium)
-- Tier 3: 30-45 minutes (Hard)
-- Tier 4: 45-60 minutes (Boss)

print("[TIERED_EVENT] loading screenplay: tiered_scheduled_event")

TieredScheduledEvent = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "TieredScheduledEvent"
}
registerScreenPlay("TieredScheduledEvent", true)

-- ============================= CONFIG =============================
TieredScheduledEvent.MODE = "ABSOLUTE"            -- "ABSOLUTE" | "WEEKLY"
TieredScheduledEvent.RESPAWN_SECONDS = 0          -- 0 = no engine respawn, we control everything
TieredScheduledEvent.EVENT_RESPAWN_DELAY = 10     -- our event respawn delay in seconds
TieredScheduledEvent.RESPAWN_CUTOFF_BUFFER = 15   -- cutoff fires at (END_TIME - buffer)

-- Absolute start and end times (server local time)
TieredScheduledEvent.START_TIME = { year = 2026, month = 4, day = 26, hour = 18, min = 00, sec = 0 }
TieredScheduledEvent.END_TIME   = { year = 2026, month = 4, day = 26, hour = 19, min = 00, sec = 0 }

-- Weekly schedule (alternative to absolute times)
TieredScheduledEvent.WEEKLY = { dow = "sunday", hour = 3, min = 0, sec = 0 }
TieredScheduledEvent.WEEKLY_LIST = {
  { dow = "saturday", hour = 23, min = 0, sec = 0 },
  { dow = "sunday",   hour = 16, min = 27, sec = 0 },
}

-- Catch-up if server boots while the window should be active
TieredScheduledEvent.CATCH_UP_IF_MISSED = true

-- TIER CONFIGURATION - Each tier has its own mob list
-- Tier 1: 0-15 minutes (Easy mobs)
TieredScheduledEvent.TIER1_NPCS = {
  { planet = "corellia", template = "savage_rend_grak", x = -179, y = -4719, z = 28, heading = 0 },
  { planet = "corellia", template = "savage_rend_grak", x = -181, y = -4721, z = 28, heading = 0 },
  { planet = "corellia", template = "savage_rend_grak", x = -183, y = -4723, z = 28, heading = 0 },
  { planet = "corellia", template = "savage_rend_grak", x = -185, y = -4725, z = 28, heading = 0 },
}

-- Tier 2: 15-30 minutes (Medium mobs)
TieredScheduledEvent.TIER2_NPCS = {
  { planet = "corellia", template = "dreadmaw_devourer_grak", x = -179, y = -4719, z = 28, heading = 0 },
  { planet = "corellia", template = "dreadmaw_devourer_grak", x = -181, y = -4721, z = 28, heading = 0 },
  { planet = "corellia", template = "dreadmaw_devourer_grak", x = -183, y = -4723, z = 28, heading = 0 },
}

-- Tier 3: 30-45 minutes (Hard mobs)
TieredScheduledEvent.TIER3_NPCS = {
 -- { planet = "corellia", template = "meatlump_loon", x = -172, y = -4723, z = 28, heading = 0 },
  { planet = "corellia", template = "apex_ravager_grak", x = -179, y = -4719, z = 28, heading = 0 },
  { planet = "corellia", template = "apex_ravager_grak", x = -181, y = -4721, z = 28, heading = 0 },
}

-- Tier 4: 45-60 minutes (Boss mobs)
TieredScheduledEvent.TIER4_NPCS = {
 -- { planet = "corellia", template = "wookiee_jedi_event", x = -172, y = -4723, z = 28, heading = 0 },
  { planet = "corellia", template = "primordial_warlord_grak", x = -179, y = -4719, z = 28, heading = 0 },
  --{ planet = "corellia", template = "wookiee_jedi_event", x = -180, y = -4725, z = 28, heading = 0 },
}

-- Tier change times (in seconds from event start)
TieredScheduledEvent.TIER1_DURATION = 15 * 60  -- 15 minutes
TieredScheduledEvent.TIER2_DURATION = 15 * 60  -- 15 minutes
TieredScheduledEvent.TIER3_DURATION = 15 * 60  -- 15 minutes
TieredScheduledEvent.TIER4_DURATION = 15 * 60  -- 15 minutes (until event ends)

-- Messages
TieredScheduledEvent.START_MSG = "A tiered event has begun! Tier 1 enemies have arrived!"
TieredScheduledEvent.TIER2_MSG = "The enemies grow stronger! Tier 2 has begun!"
TieredScheduledEvent.TIER3_MSG = "Even more dangerous foes appear! Tier 3 has begun!"
TieredScheduledEvent.TIER4_MSG = "The bosses have arrived! Tier 4 - Final challenge!"
TieredScheduledEvent.END_MSG   = "The tiered event has ended. All hostiles have been removed."

-- ============================= INTERNALS =============================
local KEY_ACTIVE_UNTIL = "TieredScheduledEvent:active_until"
local KEY_ARMED_UNTIL  = "TieredScheduledEvent:armed_until"
local KEY_EVENT_ENDED = "TieredScheduledEvent:event_ended"
local KEY_EVENT_START_TIME = "TieredScheduledEvent:start_time"
local KEY_CURRENT_TIER = "TieredScheduledEvent:current_tier"

local DOW_MAP = { sunday=0, monday=1, tuesday=2, wednesday=3, thursday=4, friday=5, saturday=6 }

TieredScheduledEvent._active = false
TieredScheduledEvent._currentTier = 0

-- -------- helpers
local function now() return os.time() end
local function toMillis(sec)
  local n = tonumber(sec) or 1
  if n < 1 then n = 1 end
  return math.floor(n) * 1000
end
local function safeNum(v, fallback)
  local n = tonumber(v)
  if n == nil then return fallback end
  return n
end
local function safeTerrainZ(planet, x, y)
  local ok, z = pcall(getTerrainHeight, planet, x, y)
  if ok and type(z) == "number" then return z end
  return 0
end
local function parseDow(dow)
  if type(dow) == "string" then
    local d = DOW_MAP[dow:lower()]
    if d ~= nil then return d end
    return 0
  end
  if type(dow) == "number" then
    local n = math.floor(dow)
    if n < 0 then n = 0 end
    if n > 6 then n = 6 end
    return n
  end
  return 0
end

local DAY = 24 * 60 * 60
local function osTimeFromParts(year, month, day, hour, min, sec)
  return os.time{
    year  = safeNum(year, 1970),
    month = safeNum(month, 1),
    day   = safeNum(day, 1),
    hour  = safeNum(hour, 0),
    min   = safeNum(min, 0),
    sec   = safeNum(sec, 0)
  }
end

local function nextForEntry(e, tnow)
  local dt = os.date("*t", tnow)
  local ttarget = osTimeFromParts(dt.year, dt.month, dt.day, e.hour, e.min, e.sec)
  local want = parseDow(e.dow)
  local today = tonumber(os.date("%w", ttarget)) or 0
  local ahead = (want - today) % 7
  if ahead == 0 and ttarget <= tnow then ahead = 7 end
  if ahead > 0 then ttarget = ttarget + ahead * DAY end
  return ttarget
end

local function prevForEntry(e, tnow)
  local dt = os.date("*t", tnow)
  local ttarget = osTimeFromParts(dt.year, dt.month, dt.day, e.hour, e.min, e.sec)
  local want = parseDow(e.dow)
  local today = tonumber(os.date("%w", ttarget)) or 0
  local behind = (today - want) % 7
  if behind == 0 and ttarget > tnow then behind = 7 end
  if behind > 0 then ttarget = ttarget - behind * DAY end
  return ttarget
end

function TieredScheduledEvent:getStartTime()
  if self.MODE == "ABSOLUTE" then
    local st = self.START_TIME or {}
    return osTimeFromParts(st.year, st.month, st.day, st.hour, st.min, st.sec)
  end
  -- For weekly mode, calculate next occurrence
  local tnow = now()
  local best = nil
  if self.WEEKLY_LIST and #self.WEEKLY_LIST > 0 then
    for _, e in ipairs(self.WEEKLY_LIST) do
      local cand = nextForEntry(e, tnow)
      if not best or cand < best then best = cand end
    end
  else
    best = nextForEntry(self.WEEKLY, tnow)
  end
  return best
end

function TieredScheduledEvent:getEndTime()
  if self.MODE == "ABSOLUTE" then
    local et = self.END_TIME or {}
    return osTimeFromParts(et.year, et.month, et.day, et.hour, et.min, et.sec)
  end
  return self:getStartTime() + 3600  -- 1 hour default
end

function TieredScheduledEvent:secondsUntilStart()
  local tnow = now()
  local startTime = self:getStartTime()
  local diff = startTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function TieredScheduledEvent:secondsUntilEnd()
  local tnow = now()
  local endTime = self:getEndTime()
  local diff = endTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function TieredScheduledEvent:isEventTimeActive()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  return tnow >= startTime and tnow < endTime
end

function TieredScheduledEvent:lastScheduledStartAtOrBefore(tnow)
  if self.MODE == "ABSOLUTE" then
    local startTime = self:getStartTime()
    if startTime <= tnow then return startTime else return nil end
  end
  local best = nil
  if self.WEEKLY_LIST and #self.WEEKLY_LIST > 0 then
    for _, e in ipairs(self.WEEKLY_LIST) do
      local cand = prevForEntry(e, tnow)
      if cand <= tnow and (not best or cand > best) then best = cand end
    end
  else
    best = prevForEntry(self.WEEKLY, tnow)
  end
  return best
end

local function broadcastAllPlayers(msg)
  if not msg or msg == "" then return end
  if type(broadcastToGalaxy) == "function" then
    local ok = pcall(broadcastToGalaxy, msg)
    if not ok then pcall(broadcastToGalaxy, 0, msg) end
  end
end

-- Get the NPC list for a specific tier
function TieredScheduledEvent:getNPCsForTier(tier)
  if tier == 1 then return self.TIER1_NPCS
  elseif tier == 2 then return self.TIER2_NPCS
  elseif tier == 3 then return self.TIER3_NPCS
  elseif tier == 4 then return self.TIER4_NPCS
  end
  return {}
end

-- Calculate which tier should be active based on elapsed time
function TieredScheduledEvent:calculateCurrentTier()
  local eventStartTime = tonumber(readData(KEY_EVENT_START_TIME)) or now()
  local elapsed = now() - eventStartTime

  if elapsed < self.TIER1_DURATION then
    return 1
  elseif elapsed < (self.TIER1_DURATION + self.TIER2_DURATION) then
    return 2
  elseif elapsed < (self.TIER1_DURATION + self.TIER2_DURATION + self.TIER3_DURATION) then
    return 3
  else
    return 4
  end
end

-- Get tier transition times
function TieredScheduledEvent:getTierTransitionTime(tier)
  local eventStartTime = tonumber(readData(KEY_EVENT_START_TIME)) or now()

  if tier == 1 then
    return eventStartTime
  elseif tier == 2 then
    return eventStartTime + self.TIER1_DURATION
  elseif tier == 3 then
    return eventStartTime + self.TIER1_DURATION + self.TIER2_DURATION
  elseif tier == 4 then
    return eventStartTime + self.TIER1_DURATION + self.TIER2_DURATION + self.TIER3_DURATION
  end
  return eventStartTime
end

-- ============================= CORE FUNCTIONS =============================

function TieredScheduledEvent:spawnTier(tier)
  print("[TIERED_EVENT] Spawning Tier " .. tier .. " NPCs with NO engine respawn")

  local npcs = self:getNPCsForTier(tier)

  for i, spec in ipairs(npcs) do
    local z = spec.z or safeTerrainZ(spec.planet, spec.x, spec.y)
    local hdg = spec.heading or 0
    local cell = spec.cell or 0

    local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
    if pMob ~= nil then
      local so = LuaSceneObject(pMob)
      if so ~= nil then
        local oid = so:getObjectID()
        spec.oid = oid
        print("[TIERED_EVENT] Spawned " .. spec.template .. " (oid=" .. oid .. ") for Tier " .. tier)

        -- Store the OID globally so we can find it later
        writeData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_oid", tostring(oid))
        writeData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_template", spec.template)
      end
    else
      print("[TIERED_EVENT] FAILED to spawn " .. spec.template)
    end
  end

  print("[TIERED_EVENT] Tier " .. tier .. " spawn complete")
end

function TieredScheduledEvent:despawnTier(tier)
  print("[TIERED_EVENT] Despawning Tier " .. tier .. " NPCs")

  local npcs = self:getNPCsForTier(tier)
  local despawnedCount = 0

  for i, spec in ipairs(npcs) do
    local storedOid = readData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_oid")

    if storedOid and storedOid ~= "" then
      local oid = tonumber(storedOid)
      if oid then
        local obj = getSceneObject(oid)
        if obj then
          local success = pcall(function()
            local so = LuaSceneObject(obj)
            if so then
              so:destroyObjectFromWorld()
              despawnedCount = despawnedCount + 1
              print("[TIERED_EVENT] Destroyed " .. spec.template .. " (oid=" .. oid .. ") from Tier " .. tier)
            end
          end)
          if not success then
            print("[TIERED_EVENT] Failed to destroy " .. (spec.template or "unknown") .. " (oid=" .. oid .. ")")
          end
        else
          print("[TIERED_EVENT] NPC already gone (oid=" .. oid .. ")")
        end
      end
    end

    -- Clean up stored data immediately
    deleteData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_oid")
    deleteData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_template")
  end

  print("[TIERED_EVENT] Despawned " .. despawnedCount .. " NPCs from Tier " .. tier)
end

function TieredScheduledEvent:despawnAllPreviousTiers(currentTier)
  print("[TIERED_EVENT] Cleaning up ALL tiers before Tier " .. currentTier)

  -- Clean up all tiers from 1 to currentTier-1
  for tier = 1, currentTier - 1 do
    self:despawnTier(tier)
  end

  print("[TIERED_EVENT] All previous tiers cleaned up")
end

function TieredScheduledEvent:changeTier(newTier)
  -- Re-read current tier from storage to ensure we have the latest value
  local storedTier = tonumber(readData(KEY_CURRENT_TIER)) or 0
  if storedTier > 0 then
    self._currentTier = storedTier
  end

  local oldTier = self._currentTier

  if oldTier == newTier then
    print("[TIERED_EVENT] Already in Tier " .. newTier .. ", skipping change")
    return
  end

  -- Check if we're trying to skip tiers (indicates a problem)
  if newTier > oldTier + 1 and oldTier > 0 then
    print("[TIERED_EVENT] WARNING: Attempting to skip from Tier " .. oldTier .. " to Tier " .. newTier)
  end

  print("[TIERED_EVENT] ===== CHANGING FROM TIER " .. oldTier .. " TO TIER " .. newTier .. " =====")

  -- Update tier tracking FIRST to prevent double-execution
  self._currentTier = newTier
  writeData(KEY_CURRENT_TIER, newTier)

  -- CRITICAL: Clean up ALL previous tiers to ensure no stragglers
  -- This handles any mobs that survived from earlier tiers
  if newTier > 1 then
    self:despawnAllPreviousTiers(newTier)
  end

  -- Spawn new tier
  self:spawnTier(newTier)

  -- Broadcast tier change message
  if newTier == 2 and self.TIER2_MSG then
    broadcastAllPlayers(self.TIER2_MSG)
  elseif newTier == 3 and self.TIER3_MSG then
    broadcastAllPlayers(self.TIER3_MSG)
  elseif newTier == 4 and self.TIER4_MSG then
    broadcastAllPlayers(self.TIER4_MSG)
  end

  print("[TIERED_EVENT] Tier change complete - now in Tier " .. newTier)
end

function TieredScheduledEvent:scheduleEventRespawn()
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("TieredScheduledEvent:cutoff_reached") == "1")

  if not eventEnded and not cutoffReached and tnow < endTime then
    local delay = self.EVENT_RESPAWN_DELAY * 1000
    createEvent(delay, self.screenplayName, "checkEventRespawns", 0, "event_respawn")
  end
end

function TieredScheduledEvent:checkEventRespawns(pCreatureObject, pPlayer)
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("TieredScheduledEvent:cutoff_reached") == "1")

  if eventEnded or cutoffReached or tnow >= endTime then
    print("[TIERED_EVENT] [RESPAWN] Stopping respawns - event ended or cutoff reached")
    return
  end

  -- CRITICAL: Read current tier from storage to ensure we have the right tier
  local currentTier = tonumber(readData(KEY_CURRENT_TIER)) or 0
  if currentTier == 0 then
    print("[TIERED_EVENT] [RESPAWN] No active tier found, skipping respawn check")
    self:scheduleEventRespawn()
    return
  end

  self._currentTier = currentTier
  print("[TIERED_EVENT] [RESPAWN] Checking respawns for Tier " .. currentTier)

  local npcs = self:getNPCsForTier(currentTier)

  local respawnedCount = 0
  local aliveCount = 0

  for i, spec in ipairs(npcs) do
    local storedOidStr = readData("TieredScheduledEvent:tier" .. currentTier .. "_npc_" .. i .. "_oid")
    local storedOid = tonumber(storedOidStr)

    if storedOid then
      local obj = getSceneObject(storedOid)
      if not obj then
        -- NPC is dead/gone, respawn it
        print("[TIERED_EVENT] [RESPAWN] Tier " .. currentTier .. " NPC #" .. i .. " (" .. spec.template .. ") is gone, respawning...")
        local z = spec.z or safeTerrainZ(spec.planet, spec.x, spec.y)
        local hdg = spec.heading or 0
        local cell = spec.cell or 0

        local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
        if pMob ~= nil then
          local so = LuaSceneObject(pMob)
          if so ~= nil then
            local newOid = so:getObjectID()
            spec.oid = newOid
            writeData("TieredScheduledEvent:tier" .. currentTier .. "_npc_" .. i .. "_oid", tostring(newOid))
            print("[TIERED_EVENT] [RESPAWN] Successfully respawned " .. spec.template .. " (new oid=" .. newOid .. ")")
            respawnedCount = respawnedCount + 1
          end
        else
          print("[TIERED_EVENT] [RESPAWN] FAILED to spawn " .. spec.template)
        end
      else
        -- Check if the NPC is actually alive or is a corpse
        local so = LuaSceneObject(obj)
        if so then
          local creature = LuaCreatureObject(obj)
          if creature then
            local health = creature:getHAM(0)
            local isDead = creature:isDead()

            if health <= 0 or isDead then
              print("[TIERED_EVENT] [RESPAWN] Tier " .. currentTier .. " NPC #" .. i .. " (" .. spec.template .. ") is corpse, respawning...")
              so:destroyObjectFromWorld()

              local z = spec.z or safeTerrainZ(spec.planet, spec.x, spec.y)
              local hdg = spec.heading or 0
              local cell = spec.cell or 0

              local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
              if pMob ~= nil then
                local newSo = LuaSceneObject(pMob)
                if newSo ~= nil then
                  local newOid = newSo:getObjectID()
                  spec.oid = newOid
                  writeData("TieredScheduledEvent:tier" .. currentTier .. "_npc_" .. i .. "_oid", tostring(newOid))
                  print("[TIERED_EVENT] [RESPAWN] Successfully respawned " .. spec.template .. " (new oid=" .. newOid .. ")")
                  respawnedCount = respawnedCount + 1
                end
              else
                print("[TIERED_EVENT] [RESPAWN] FAILED to spawn " .. spec.template)
              end
            else
              aliveCount = aliveCount + 1
            end
          end
        end
      end
    else
      print("[TIERED_EVENT] [RESPAWN] WARNING: No stored OID for Tier " .. currentTier .. " NPC #" .. i)
    end
  end

  print("[TIERED_EVENT] [RESPAWN] Tier " .. currentTier .. " status - Alive: " .. aliveCount .. ", Respawned: " .. respawnedCount)
  self:scheduleEventRespawn()
end

function TieredScheduledEvent:monitorEvent()
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")

  if eventEnded then
    return
  end

  if tnow >= activeUntil then
    self:endEventNow()
    return
  end

  -- Sync _currentTier with stored value to handle server restarts
  local storedTier = tonumber(readData(KEY_CURRENT_TIER)) or 0
  if storedTier > 0 then
    self._currentTier = storedTier
  end

  -- Check if we need to change tiers
  local shouldBeTier = self:calculateCurrentTier()
  print("[TIERED_EVENT] [MONITOR] Current tier: " .. self._currentTier .. ", Should be tier: " .. shouldBeTier)

  if shouldBeTier ~= self._currentTier then
    self:changeTier(shouldBeTier)
  end

  -- Check if we should do cutoff
  local cutoffTime = activeUntil - self.RESPAWN_CUTOFF_BUFFER
  if tnow >= cutoffTime then
    self:attemptCleanup()
  end

  -- Schedule next check
  local remaining = activeUntil - tnow
  local nextCheck = math.min(10000, remaining * 1000)
  createEvent(nextCheck, self.screenplayName, "monitorEvent", 0, "")
end

function TieredScheduledEvent:attemptCleanup()
  print("[TIERED_EVENT] [CLEANUP] Attempting to find and remove all event NPCs")

  writeData("TieredScheduledEvent:cutoff_reached", "1")

  local destroyedCount = 0

  -- Clean up all tiers
  for tier = 1, 4 do
    local npcs = self:getNPCsForTier(tier)
    for i, spec in ipairs(npcs) do
      local storedOid = readData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_oid")

      if storedOid and storedOid ~= "" then
        local oid = tonumber(storedOid)
        if oid then
          local obj = getSceneObject(oid)
          if obj then
            local success = pcall(function()
              local so = LuaSceneObject(obj)
              if so then
                so:destroyObjectFromWorld()
                destroyedCount = destroyedCount + 1
              end
            end)
          end
        end
      end
    end
  end

  print("[TIERED_EVENT] [CLEANUP] Destroyed " .. destroyedCount .. " NPCs")
end

function TieredScheduledEvent:endEventNow()
  print("[TIERED_EVENT] [END] Event ending NOW - final cleanup")

  writeData(KEY_EVENT_ENDED, "true")
  self._active = false

  self:attemptCleanup()

  -- Clean up all data
  deleteData(KEY_ACTIVE_UNTIL)
  deleteData(KEY_EVENT_START_TIME)
  deleteData(KEY_CURRENT_TIER)
  deleteData("TieredScheduledEvent:cutoff_reached")

  -- Clean up NPC tracking data for all tiers
  for tier = 1, 4 do
    local npcs = self:getNPCsForTier(tier)
    for i, spec in ipairs(npcs) do
      deleteData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_oid")
      deleteData("TieredScheduledEvent:tier" .. tier .. "_npc_" .. i .. "_template")
    end
  end

  local endTime = self:getEndTime()
  print("[TIERED_EVENT] Event END " .. os.date("%Y-%m-%d %H:%M:%S", endTime) .. " - ALL NPCs REMOVED")

  if self.END_MSG and self.END_MSG ~= "" then
    broadcastAllPlayers(self.END_MSG)
  end

  if self.MODE == "WEEKLY" then
    print("[TIERED_EVENT] Weekly mode - arming next event")
    self:armNext()
  end
end

-- ============================= MAIN ENTRY POINTS =============================

function TieredScheduledEvent:start()
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0

  if activeUntil > tnow then
    print("[TIERED_EVENT] Server boot during active window. Resuming...")
    self._active = true
    self._currentTier = tonumber(readData(KEY_CURRENT_TIER)) or 1
    createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
    return
  end

  if self.CATCH_UP_IF_MISSED then
    local lastStart = self:lastScheduledStartAtOrBefore(tnow)
    local eventDuration = self.TIER1_DURATION + self.TIER2_DURATION + self.TIER3_DURATION + self.TIER4_DURATION
    if lastStart and (tnow - lastStart) < eventDuration then
      local remain = eventDuration - (tnow - lastStart)
      print("[TIERED_EVENT] Missed start; starting now with " .. remain .. " sec remaining.")
      self:beginEvent()
      return
    end
  end

  self:armNext()
end

function TieredScheduledEvent:armNext()
  local secs = self:secondsUntilStart()
  local fireAt = now() + secs
  writeData(KEY_ARMED_UNTIL, fireAt)
  print("[TIERED_EVENT] Armed next event in " .. secs .. " sec (fires at " .. os.date("%Y-%m-%d %H:%M:%S", fireAt) .. ")")
  createEvent(toMillis(secs), self.screenplayName, "beginEvent", 0, "")
end

function TieredScheduledEvent:beginEvent(pCreatureObject, pPlayer)
  print("[TIERED_EVENT] ===== BEGIN EVENT =====")
  local tnow = now()
  local endTime = self:getEndTime()

  -- Clear any previous state
  deleteData(KEY_EVENT_ENDED)
  deleteData("TieredScheduledEvent:cutoff_reached")
  writeData(KEY_ACTIVE_UNTIL, endTime)
  writeData(KEY_EVENT_START_TIME, tnow)
  self._active = true
  self._currentTier = 0

  print("[TIERED_EVENT] Event START " .. os.date("%Y-%m-%d %H:%M:%S", tnow) .. "; ends " .. os.date("%Y-%m-%d %H:%M:%S", endTime))

  if self.START_MSG and self.START_MSG ~= "" then
    broadcastAllPlayers(self.START_MSG)
  end

  -- Start with Tier 1
  self:changeTier(1)

  -- Start respawn system
  self:scheduleEventRespawn()

  -- Start monitoring
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")

  print("[TIERED_EVENT] Event begin complete")
end

function TieredScheduledEvent:manualStart()
  print("[TIERED_EVENT] ===== MANUAL START =====")
  self:beginEvent(nil, nil)
end

function TieredScheduledEvent:forceEnd()
  print("[TIERED_EVENT] ===== FORCE END =====")
  self:endEventNow()
end

function TieredScheduledEvent:status()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("TieredScheduledEvent:cutoff_reached") == "1")
  local currentTier = tonumber(readData(KEY_CURRENT_TIER)) or 0

  print("[TIERED_EVENT] ===== STATUS =====")
  print("[TIERED_EVENT] Now: " .. os.date("%Y-%m-%d %H:%M:%S", tnow))
  print("[TIERED_EVENT] Start time: " .. os.date("%Y-%m-%d %H:%M:%S", startTime))
  print("[TIERED_EVENT] End time: " .. os.date("%Y-%m-%d %H:%M:%S", endTime))
  print("[TIERED_EVENT] Active until: " .. os.date("%Y-%m-%d %H:%M:%S", activeUntil))
  print("[TIERED_EVENT] Event ended: " .. tostring(eventEnded))
  print("[TIERED_EVENT] Cutoff reached: " .. tostring(cutoffReached))
  print("[TIERED_EVENT] Current Tier: " .. currentTier)
  print("[TIERED_EVENT] _active flag: " .. tostring(self._active))

  if self:isEventTimeActive() and not eventEnded then
    print("[TIERED_EVENT] Event is ACTIVE (" .. (endTime - tnow) .. " sec remaining)")

    -- Show tier progression
    local eventStartTime = tonumber(readData(KEY_EVENT_START_TIME)) or tnow
    local elapsed = tnow - eventStartTime
    print("[TIERED_EVENT] Event elapsed: " .. elapsed .. " seconds")

    for tier = 1, 4 do
      local tierTime = self:getTierTransitionTime(tier)
      if tnow >= tierTime then
        print("[TIERED_EVENT] Tier " .. tier .. " active")
      else
        print("[TIERED_EVENT] Tier " .. tier .. " starts in " .. (tierTime - tnow) .. " seconds")
      end
    end
  else
    print("[TIERED_EVENT] Event is INACTIVE")
  end
end

-- Convenience function to set new absolute times
function TieredScheduledEvent:setAbsoluteTimes(startYear, startMonth, startDay, startHour, startMin, endYear, endMonth, endDay, endHour, endMin)
  self.MODE = "ABSOLUTE"
  self.START_TIME = {
    year = startYear, month = startMonth, day = startDay,
    hour = startHour, min = startMin or 0, sec = 0
  }
  self.END_TIME = {
    year = endYear, month = endMonth, day = endDay,
    hour = endHour, min = endMin or 0, sec = 0
  }

  print("[TIERED_EVENT] Set absolute times:")
  print("[TIERED_EVENT] Start: " .. os.date("%Y-%m-%d %H:%M:%S", self:getStartTime()))
  print("[TIERED_EVENT] End:   " .. os.date("%Y-%m-%d %H:%M:%S", self:getEndTime()))
end
