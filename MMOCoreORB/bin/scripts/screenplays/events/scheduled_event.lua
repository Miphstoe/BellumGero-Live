-- Absolute Time Scheduled Event - Uses specific start and end times
-- This version uses absolute timestamps for precise event control
print("[SCHEDULED] loading screenplay: scheduled_event")

ScheduledEvent = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "ScheduledEvent"
}
registerScreenPlay("ScheduledEvent", true)

-- ============================= CONFIG =============================
ScheduledEvent.MODE = "ABSOLUTE"            -- "ABSOLUTE" | "WEEKLY"
ScheduledEvent.RESPAWN_SECONDS = 5          -- 0 = no engine respawn, we track everything
ScheduledEvent.EVENT_RESPAWN_DELAY = 10     -- our event respawn delay in seconds  
ScheduledEvent.RESPAWN_CUTOFF_BUFFER = 15   -- cutoff fires at (END_TIME - buffer)

-- Absolute start and end times (server local time)
ScheduledEvent.START_TIME = { year = 2025, month = 11, day = 09, hour = 19, min = 00, sec = 0 }
ScheduledEvent.END_TIME   = { year = 2025, month = 11, day = 09, hour = 20, min = 00, sec = 0 }

-- Weekly schedule (alternative to absolute times)
ScheduledEvent.WEEKLY = { dow = "sunday", hour = 3, min = 0, sec = 0 }
ScheduledEvent.WEEKLY_LIST = {
  { dow = "saturday", hour = 23, min = 0, sec = 0 },
  { dow = "sunday",   hour = 16, min = 27, sec = 0 },
}

-- Catch-up if server boots while the window should be active
ScheduledEvent.CATCH_UP_IF_MISSED = true

-- NPCs
ScheduledEvent.NPCS = {
  { planet = "corellia", template = "giant_ewok_warchief", x = -172, y = -4723, heading = 0 },
  --{ planet = "corellia", template = "r2_d2_event", x = -174, y = -4725, heading = 0 },
}

-- Messages
ScheduledEvent.START_MSG = "An event has begun! Hostiles have arrived for a limited time."
ScheduledEvent.END_MSG   = "The event window has closed. All hostiles have been removed."

-- ============================= INTERNALS =============================
local KEY_ACTIVE_UNTIL = "ScheduledEvent:active_until"
local KEY_ARMED_UNTIL  = "ScheduledEvent:armed_until"
local KEY_EVENT_ENDED = "ScheduledEvent:event_ended"
local KEY_EVENT_START_TIME = "ScheduledEvent:start_time"

local DOW_MAP = { sunday=0, monday=1, tuesday=2, wednesday=3, thursday=4, friday=5, saturday=6 }

ScheduledEvent._active = false

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

function ScheduledEvent:getStartTime()
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

function ScheduledEvent:getEndTime()
  if self.MODE == "ABSOLUTE" then
    local et = self.END_TIME or {}
    return osTimeFromParts(et.year, et.month, et.day, et.hour, et.min, et.sec)
  end
  -- For weekly mode, this would need additional logic
  -- For now, return start time + some default duration
  return self:getStartTime() + 3600  -- 1 hour default
end

function ScheduledEvent:secondsUntilStart()
  local tnow = now()
  local startTime = self:getStartTime()
  local diff = startTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function ScheduledEvent:secondsUntilEnd()
  local tnow = now()
  local endTime = self:getEndTime()
  local diff = endTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function ScheduledEvent:isEventTimeActive()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  return tnow >= startTime and tnow < endTime
end

function ScheduledEvent:lastScheduledStartAtOrBefore(tnow)
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

-- ============================= CORE FUNCTIONS =============================

function ScheduledEvent:spawnAll()
  print("[SCHEDULED] Spawning all NPCs with NO engine respawn - full script control")
  
  for i, spec in ipairs(self.NPCS) do
    local z = safeTerrainZ(spec.planet, spec.x, spec.y)
    local hdg = spec.heading or 0
    local cell = spec.cell or 0

    -- CRITICAL: Use 0 for respawn timer - NO engine respawn
    local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
    if pMob ~= nil then
      local so = LuaSceneObject(pMob)
      if so ~= nil then
        local oid = so:getObjectID()
        spec.oid = oid
        print("[SCHEDULED] Spawned " .. spec.template .. " (oid=" .. oid .. ") with script respawn control")
        
        -- Store the OID globally so we can find it later
        writeData("ScheduledEvent:npc_" .. i .. "_oid", tostring(oid))
        writeData("ScheduledEvent:npc_" .. i .. "_template", spec.template)
        print("[SCHEDULED] Stored OID " .. oid .. " for cleanup tracking")
      end
    else
      print("[SCHEDULED] FAILED to spawn " .. spec.template)
    end
  end
  
  -- Start our event respawn system
  self:scheduleEventRespawn()
  print("[SCHEDULED] Script respawn system STARTED - we control everything")
end

function ScheduledEvent:scheduleEventRespawn()
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEvent:cutoff_reached") == "1")
  
  -- Only schedule respawn if event is still active and cutoff not reached
  if not eventEnded and not cutoffReached and tnow < endTime then
    local delay = self.EVENT_RESPAWN_DELAY * 1000
    print("[SCHEDULED] [RESPAWN] Scheduling event respawn check in " .. self.EVENT_RESPAWN_DELAY .. " seconds")
    createEvent(delay, self.screenplayName, "checkEventRespawns", 0, "event_respawn")
  else
    print("[SCHEDULED] [RESPAWN] Event ended or cutoff reached - NO MORE RESPAWN SCHEDULING")
  end
end

function ScheduledEvent:checkEventRespawns(pCreatureObject, pPlayer)
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEvent:cutoff_reached") == "1")
  
  print("[SCHEDULED] [RESPAWN] Event respawn check - now=" .. tnow .. ", endTime=" .. endTime)
  
  -- STOP respawning if event ended OR cutoff reached
  if eventEnded or cutoffReached or tnow >= endTime then
    print("[SCHEDULED] [RESPAWN] Event ended or cutoff reached - STOPPING ALL RESPAWNS")
    return
  end
  
  print("[SCHEDULED] [RESPAWN] Checking for dead NPCs to respawn during event")
  
  local respawnedAny = false
  for i, spec in ipairs(self.NPCS) do
    -- Use stored OID instead of spec.oid since that gets cleared somehow
    local storedOidStr = readData("ScheduledEvent:npc_" .. i .. "_oid")
    local storedOid = tonumber(storedOidStr)
    
    print("[SCHEDULED] [RESPAWN] Checking " .. spec.template .. " - stored OID: " .. tostring(storedOid) .. ", spec OID: " .. tostring(spec.oid))
    
    if storedOid then
      local obj = getSceneObject(storedOid)
      if not obj then
        -- NPC is dead, respawn it
        print("[SCHEDULED] [RESPAWN] " .. spec.template .. " (oid=" .. storedOid .. ") is dead, respawning...")
        local z = safeTerrainZ(spec.planet, spec.x, spec.y)
        local hdg = spec.heading or 0
        local cell = spec.cell or 0
        
        -- Spawn with 0 respawn timer - we control everything
        local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
        if pMob ~= nil then
          local so = LuaSceneObject(pMob)
          if so ~= nil then
            local newOid = so:getObjectID()
            spec.oid = newOid
            -- Update stored OID
            writeData("ScheduledEvent:npc_" .. i .. "_oid", tostring(newOid))
            print("[SCHEDULED] [RESPAWN] Successfully respawned " .. spec.template .. " (new oid=" .. newOid .. ")")
            respawnedAny = true
          end
        else
          print("[SCHEDULED] [RESPAWN] FAILED to spawn " .. spec.template)
        end
      else
        -- Check if the NPC is actually alive (has health > 0)
        local so = LuaSceneObject(obj)
        if so then
          local creature = LuaCreatureObject(obj)
          if creature then
            local health = creature:getHAM(0)  -- Get health
            if health <= 0 then
              print("[SCHEDULED] [RESPAWN] " .. spec.template .. " (oid=" .. storedOid .. ") has no health, respawning...")
              -- Destroy the corpse first
              so:destroyObjectFromWorld()
              
              -- Respawn
              local z = safeTerrainZ(spec.planet, spec.x, spec.y)
              local hdg = spec.heading or 0
              local cell = spec.cell or 0
              
              local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
              if pMob ~= nil then
                local newSo = LuaSceneObject(pMob)
                if newSo ~= nil then
                  local newOid = newSo:getObjectID()
                  spec.oid = newOid
                  writeData("ScheduledEvent:npc_" .. i .. "_oid", tostring(newOid))
                  print("[SCHEDULED] [RESPAWN] Successfully respawned dead " .. spec.template .. " (new oid=" .. newOid .. ")")
                  respawnedAny = true
                end
              end
            else
              print("[SCHEDULED] [RESPAWN] " .. spec.template .. " (oid=" .. storedOid .. ") is still alive with health=" .. health)
            end
          else
            print("[SCHEDULED] [RESPAWN] " .. spec.template .. " (oid=" .. storedOid .. ") is not a creature object")
          end
        else
          print("[SCHEDULED] [RESPAWN] " .. spec.template .. " (oid=" .. storedOid .. ") could not be converted to SceneObject")
        end
        -- Make sure spec.oid is in sync with stored OID
        spec.oid = storedOid
      end
    else
      print("[SCHEDULED] [RESPAWN] " .. spec.template .. " has no stored OID - spawning new one")
      -- No stored OID, spawn a new one
      local z = safeTerrainZ(spec.planet, spec.x, spec.y)
      local hdg = spec.heading or 0
      local cell = spec.cell or 0
      
      local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
      if pMob ~= nil then
        local so = LuaSceneObject(pMob)
        if so ~= nil then
          local newOid = so:getObjectID()
          spec.oid = newOid
          writeData("ScheduledEvent:npc_" .. i .. "_oid", tostring(newOid))
          print("[SCHEDULED] [RESPAWN] Spawned new " .. spec.template .. " (oid=" .. newOid .. ")")
          respawnedAny = true
        end
      end
    end
  end
  
  if respawnedAny then
    print("[SCHEDULED] [RESPAWN] Respawned some NPCs")
  else
    print("[SCHEDULED] [RESPAWN] No NPCs needed respawning")
  end
  
  -- Schedule next respawn check ONLY if event is still active
  self:scheduleEventRespawn()
end

-- Simplified monitoring - just watch for cutoff
function ScheduledEvent:monitorEvent()
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  
  print("[SCHEDULED] [MONITOR] now=" .. tnow .. ", activeUntil=" .. activeUntil .. ", ended=" .. tostring(eventEnded))
  
  if eventEnded then
    print("[SCHEDULED] [MONITOR] Event already ended, no further monitoring")
    return
  end
  
  if tnow >= activeUntil then
    print("[SCHEDULED] [MONITOR] Event time reached - ending event NOW")
    self:endEventNow()
    return
  end
  
  -- Check if we should do cutoff
  local cutoffTime = activeUntil - 20  -- Cutoff 20 seconds before end
  if tnow >= cutoffTime then
    print("[SCHEDULED] [MONITOR] Cutoff time reached - attempting NPC cleanup")
    self:attemptCleanup()
  end
  
  -- Schedule next check
  local remaining = activeUntil - tnow
  local nextCheck = math.min(10000, remaining * 1000)  -- Check every 10s
  print("[SCHEDULED] [MONITOR] Next check in " .. (nextCheck/1000) .. "s")
  createEvent(nextCheck, self.screenplayName, "monitorEvent", 0, "")
end

-- Attempt to find and remove NPCs using stored OIDs
function ScheduledEvent:attemptCleanup()
  print("[SCHEDULED] [CLEANUP] Attempting to find and remove event NPCs")
  
  -- Set cutoff flag FIRST to prevent respawns during cleanup
  writeData("ScheduledEvent:cutoff_reached", "1")
  print("[SCHEDULED] [CLEANUP] Set cutoff flag - no more respawning")
  
  -- Try multiple approaches to find and destroy NPCs
  local destroyedCount = 0
  
  -- Method 1: Use stored OIDs from spawn
  for i, spec in ipairs(self.NPCS) do
    local storedOid = readData("ScheduledEvent:npc_" .. i .. "_oid")
    local template = readData("ScheduledEvent:npc_" .. i .. "_template")
    
    if storedOid and storedOid ~= "" then
      local oid = tonumber(storedOid)
      if oid then
        local obj = getSceneObject(oid)
        if obj then
          print("[SCHEDULED] [CLEANUP] Found " .. (template or spec.template) .. " (oid=" .. oid .. ") - destroying")
          local success = pcall(function()
            local so = LuaSceneObject(obj)
            if so then
              so:destroyObjectFromWorld()
              destroyedCount = destroyedCount + 1
              print("[SCHEDULED] [CLEANUP] Successfully destroyed " .. (template or spec.template))
            end
          end)
          if not success then
            print("[SCHEDULED] [CLEANUP] Failed to destroy " .. (template or spec.template))
          end
        else
          print("[SCHEDULED] [CLEANUP] Stored OID " .. oid .. " not found in world")
        end
      end
    end
    
    -- Also try the spec.oid if it exists
    if spec.oid and spec.oid ~= tonumber(storedOid) then
      local obj = getSceneObject(spec.oid)
      if obj then
        print("[SCHEDULED] [CLEANUP] Found " .. spec.template .. " (spec oid=" .. spec.oid .. ") - destroying")
        local success = pcall(function()
          local so = LuaSceneObject(obj)
          if so then
            so:destroyObjectFromWorld()
            destroyedCount = destroyedCount + 1
            print("[SCHEDULED] [CLEANUP] Successfully destroyed " .. spec.template .. " via spec OID")
          end
        end)
      end
    end
  end
  
  print("[SCHEDULED] [CLEANUP] Destroyed " .. destroyedCount .. " NPCs")
end

function ScheduledEvent:endEventNow()
  print("[SCHEDULED] [END] Event ending NOW - final cleanup")
  
  -- Mark event as definitively ended
  writeData(KEY_EVENT_ENDED, "true")
  self._active = false
  
  -- Attempt to remove all NPCs
  self:attemptCleanup()
  
  -- Clean up all data
  deleteData(KEY_ACTIVE_UNTIL)
  deleteData(KEY_EVENT_START_TIME)
  deleteData("ScheduledEvent:cutoff_reached")
  
  -- Clean up NPC tracking data
  for i, spec in ipairs(self.NPCS) do
    deleteData("ScheduledEvent:npc_" .. i .. "_oid")
    deleteData("ScheduledEvent:npc_" .. i .. "_template")
  end
  
  local endTime = self:getEndTime()
  print("[SCHEDULED] Event END " .. os.date("%Y-%m-%d %H:%M:%S", endTime) .. " - ALL NPCs REMOVED")
  
  if self.END_MSG and self.END_MSG ~= "" then
    broadcastAllPlayers(self.END_MSG)
  end
  
  -- If using weekly mode, arm the next event
  if self.MODE == "WEEKLY" then
    print("[SCHEDULED] Weekly mode - arming next event")
    self:armNext()
  end
end

-- ============================= MAIN ENTRY POINTS =============================

function ScheduledEvent:start()
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  print("[SCHEDULED] [START] called, activeUntil=" .. activeUntil .. ", now=" .. tnow)
  
  if activeUntil > tnow then
    print("[SCHEDULED] Server boot during active window. Resuming; ends in " .. (activeUntil - tnow) .. " sec.")
    self._active = true
    createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
    return
  end

  if self.CATCH_UP_IF_MISSED then
    local lastStart = self:lastScheduledStartAtOrBefore(tnow)
    if lastStart and (tnow - lastStart) < self.DURATION_SECONDS then
      local remain = self.DURATION_SECONDS - (tnow - lastStart)
      print("[SCHEDULED] Missed start at " .. os.date("%Y-%m-%d %H:%M:%S", lastStart) .. "; starting now with " .. remain .. " sec remaining.")
      self:beginEvent()
      return
    end
  end

  print("[SCHEDULED] [START] arming next event")
  self:armNext()
end

function ScheduledEvent:armNext()
  local secs = self:secondsUntilStart()
  local fireAt = now() + secs
  writeData(KEY_ARMED_UNTIL, fireAt)
  print("[SCHEDULED] Armed next event in " .. secs .. " sec (fires at local " .. os.date("%Y-%m-%d %H:%M:%S", fireAt) .. ")")
  createEvent(toMillis(secs), self.screenplayName, "beginEvent", 0, "")
end

function ScheduledEvent:beginEvent(pCreatureObject, pPlayer)
  print("[SCHEDULED] ===== BEGIN EVENT =====")
  local tnow = now()
  local endTime = self:getEndTime()
  
  -- Clear any previous state
  deleteData(KEY_EVENT_ENDED)
  deleteData("ScheduledEvent:cutoff_reached")
  writeData(KEY_ACTIVE_UNTIL, endTime)
  self._active = true
  
  print("[SCHEDULED] Event START " .. os.date("%Y-%m-%d %H:%M:%S", tnow) .. "; ends " .. os.date("%Y-%m-%d %H:%M:%S", endTime))
  
  if self.START_MSG and self.START_MSG ~= "" then
    broadcastAllPlayers(self.START_MSG)
  end
  
  -- Spawn NPCs
  self:spawnAll()
  
  -- Start simple monitoring
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
  
  print("[SCHEDULED] Event begin complete")
end

function ScheduledEvent:manualStart()
  print("[SCHEDULED] ===== MANUAL START =====")
  local tnow = now()
  local endTime = self:getEndTime()
  
  -- Clear any previous state
  deleteData(KEY_EVENT_ENDED)
  deleteData("ScheduledEvent:cutoff_reached")
  writeData(KEY_ACTIVE_UNTIL, endTime)
  self._active = true
  
  print("[SCHEDULED] Event START " .. os.date("%Y-%m-%d %H:%M:%S", tnow) .. "; ends " .. os.date("%Y-%m-%d %H:%M:%S", endTime))
  
  if self.START_MSG and self.START_MSG ~= "" then
    broadcastAllPlayers(self.START_MSG)
  end
  
  -- Spawn NPCs
  self:spawnAll()
  
  -- Start simple monitoring
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
  
  print("[SCHEDULED] Manual start complete")
end

function ScheduledEvent:forceEnd()
  print("[SCHEDULED] ===== FORCE END =====")
  self:endEventNow()
end

function ScheduledEvent:status()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEvent:cutoff_reached") == "1")
  
  print("[SCHEDULED] ===== STATUS =====")
  print("[SCHEDULED] Now: " .. os.date("%Y-%m-%d %H:%M:%S", tnow))
  print("[SCHEDULED] Start time: " .. os.date("%Y-%m-%d %H:%M:%S", startTime))
  print("[SCHEDULED] End time: " .. os.date("%Y-%m-%d %H:%M:%S", endTime))
  print("[SCHEDULED] Active until: " .. os.date("%Y-%m-%d %H:%M:%S", activeUntil))
  print("[SCHEDULED] Event ended: " .. tostring(eventEnded))
  print("[SCHEDULED] Cutoff reached: " .. tostring(cutoffReached))
  print("[SCHEDULED] _active flag: " .. tostring(self._active))
  
  if self:isEventTimeActive() and not eventEnded then
    print("[SCHEDULED] Event is ACTIVE (" .. (endTime - tnow) .. " sec remaining)")
  else
    print("[SCHEDULED] Event is INACTIVE")
  end
  
  -- Show NPC tracking info
  for i, spec in ipairs(self.NPCS) do
    local storedOid = readData("ScheduledEvent:npc_" .. i .. "_oid")
    local template = readData("ScheduledEvent:npc_" .. i .. "_template")
    print("[SCHEDULED] NPC " .. i .. ": " .. (template or spec.template) .. " - stored OID: " .. (storedOid or "none"))
  end
end

-- Convenience function to set new absolute times
function ScheduledEvent:setAbsoluteTimes(startYear, startMonth, startDay, startHour, startMin, endYear, endMonth, endDay, endHour, endMin)
  self.MODE = "ABSOLUTE"
  self.START_TIME = {
    year = startYear, month = startMonth, day = startDay,
    hour = startHour, min = startMin or 0, sec = 0
  }
  self.END_TIME = {
    year = endYear, month = endMonth, day = endDay,
    hour = endHour, min = endMin or 0, sec = 0
  }
  
  print("[SCHEDULED] Set absolute times:")
  print("[SCHEDULED] Start: " .. os.date("%Y-%m-%d %H:%M:%S", self:getStartTime()))
  print("[SCHEDULED] End:   " .. os.date("%Y-%m-%d %H:%M:%S", self:getEndTime()))
end