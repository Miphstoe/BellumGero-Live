----------------------------------------
-- Scheduled Event with Force Rank XP Rewards
-- Awards Force-Rank XP on event mob kills to eligible players
----------------------------------------

ScheduledEventFRS = ScreenPlay:new{
  numberOfActs   = 1,
  screenplayName = "ScheduledEventFRS"
}
registerScreenPlay("ScheduledEventFRS", true)

-- ============================= CONFIG =============================
ScheduledEventFRS.MODE = "ABSOLUTE"            -- "ABSOLUTE" | "WEEKLY"
ScheduledEventFRS.RESPAWN_SECONDS = 5          -- 0 = no engine respawn, we track everything
ScheduledEventFRS.EVENT_RESPAWN_DELAY = 5      -- our event respawn delay in seconds (check every 5 seconds)
ScheduledEventFRS.RESPAWN_CUTOFF_BUFFER = 15   -- cutoff fires at (END_TIME - buffer)

-- Absolute start and end times (server local time)
ScheduledEventFRS.START_TIME = { year = 2025, month = 11, day = 02, hour = 18, min = 00, sec = 0 }
ScheduledEventFRS.END_TIME   = { year = 2025, month = 11, day = 02, hour = 19, min = 00, sec = 0 }

-- Weekly schedule (alternative to absolute times)
ScheduledEventFRS.WEEKLY = { dow = "sunday", hour = 3, min = 0, sec = 0 }
ScheduledEventFRS.WEEKLY_LIST = {
  { dow = "saturday", hour = 23, min = 0, sec = 0 },
  { dow = "sunday",   hour = 16, min = 27, sec = 0 },
}

-- Catch-up if server boots while the window should be active
ScheduledEventFRS.CATCH_UP_IF_MISSED = true

-- NPCs
ScheduledEventFRS.NPCS = {
  { planet = "corellia", template = "mutant_crazed_geonosian_guard", x = -172, y = -4723, heading = 0 },
  { planet = "corellia", template = "mutant_crazed_geonosian_guard", x = -174, y = -4725, heading = 0 },
  { planet = "corellia", template = "mutant_crazed_geonosian_guard", x = -176, y = -4727, heading = 0 },
  { planet = "corellia", template = "mutant_crazed_geonosian_guard", x = -175, y = -4726, heading = 0 },
}

-- FRS Reward Configuration
ScheduledEventFRS.FRS_XP_AMOUNT = 150          -- Force Rank XP awarded per kill
ScheduledEventFRS.FRS_RANGE_METERS = 64        -- Range for group members to receive credit

-- Messages
ScheduledEventFRS.START_MSG = "An event has begun! Hostiles have arrived for a limited time."
ScheduledEventFRS.END_MSG   = "The event window has closed. All hostiles have been removed."

-- ============================= INTERNALS =============================
local KEY_ACTIVE_UNTIL = "ScheduledEventFRS:active_until"
local KEY_ARMED_UNTIL  = "ScheduledEventFRS:armed_until"
local KEY_EVENT_ENDED = "ScheduledEventFRS:event_ended"
local KEY_EVENT_START_TIME = "ScheduledEventFRS:start_time"

local DOW_MAP = { sunday=0, monday=1, tuesday=2, wednesday=3, thursday=4, friday=5, saturday=6 }

ScheduledEventFRS._active = false

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

function ScheduledEventFRS:getStartTime()
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

function ScheduledEventFRS:getEndTime()
  if self.MODE == "ABSOLUTE" then
    local et = self.END_TIME or {}
    return osTimeFromParts(et.year, et.month, et.day, et.hour, et.min, et.sec)
  end
  -- For weekly mode, this would need additional logic
  -- For now, return start time + some default duration
  return self:getStartTime() + 3600  -- 1 hour default
end

function ScheduledEventFRS:secondsUntilStart()
  local tnow = now()
  local startTime = self:getStartTime()
  local diff = startTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function ScheduledEventFRS:secondsUntilEnd()
  local tnow = now()
  local endTime = self:getEndTime()
  local diff = endTime - tnow
  if diff < 0 then diff = 0 end
  return diff
end

function ScheduledEventFRS:isEventTimeActive()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  return tnow >= startTime and tnow < endTime
end

function ScheduledEventFRS:lastScheduledStartAtOrBefore(tnow)
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

-- ============================= FRS REWARD SYSTEM =============================

function ScheduledEventFRS:onEventMobDied(pMob, pKiller)
  -- resolve the *player* responsible (handle pets)
  if pKiller == nil then return 0 end

  local pPlayer = nil
  if SceneObject(pKiller):isPlayerCreature() then
    pPlayer = pKiller
  else
    -- if the killer is a pet/vehicle/etc, try to credit the owner
    local ko = CreatureObject(pKiller)
    if ko and ko.getOwner then
      local pOwner = ko:getOwner()
      if pOwner ~= nil and SceneObject(pOwner):isPlayerCreature() then
        pPlayer = pOwner
      end
    end
  end
  if pPlayer == nil then return 0 end

  local mobSO = SceneObject(pMob)

  local function grantIfEligible(pTarget)
    if pTarget == nil or not SceneObject(pTarget):isPlayerCreature() then return end
    -- must be within range of the mob that died
    if mobSO and not SceneObject(pTarget):isInRangeWithObject(pMob, self.FRS_RANGE_METERS) then return end

    local c = CreatureObject(pTarget)
    if c and c.hasSkill and c:hasSkill("force_title_jedi_rank_03") then
      c:awardExperience("force_rank_xp", self.FRS_XP_AMOUNT, true)
    end
  end

  local killerCO = CreatureObject(pPlayer)
  if killerCO and killerCO.isGrouped and killerCO:isGrouped() then
    local size = killerCO:getGroupSize()
    for i = 0, size - 1 do
      local pMember = killerCO:getGroupMember(i)
      grantIfEligible(pMember)
    end
  else
    -- not grouped: just grant to the solo killer if eligible
    grantIfEligible(pPlayer)
  end

  return 0
end

-- ============================= CORE FUNCTIONS =============================

function ScheduledEventFRS:spawnAll()
  
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
        
        -- Store the OID globally so we can find it later
        writeData("ScheduledEventFRS:npc_" .. i .. "_oid", tostring(oid))
        writeData("ScheduledEventFRS:npc_" .. i .. "_template", spec.template)
        
        -- CRITICAL: Add observer for FRS XP rewards on kill
        createObserver(OBJECTDESTRUCTION,
                       "ScheduledEventFRS",
                       "onEventMobDied",
                       pMob)
      end
    else
    end
  end
  
  -- Start our event respawn system
  self:scheduleEventRespawn()
end

function ScheduledEventFRS:scheduleEventRespawn()
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEventFRS:cutoff_reached") == "1")

  -- Only schedule respawn if event is still active and cutoff not reached
  if not eventEnded and not cutoffReached and tnow < endTime then
    local delay = self.EVENT_RESPAWN_DELAY * 1000
    createEvent(delay, self.screenplayName, "checkRespawns", 0, "event_respawn")
  else
  end
end

function ScheduledEventFRS:checkRespawns(pCreatureObject, pPlayer)
  local tnow = now()
  local endTime = self:getEndTime()
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEventFRS:cutoff_reached") == "1")


  -- STOP respawning if event ended OR cutoff reached
  if eventEnded or cutoffReached or tnow >= endTime then
    return 0
  end


  local respawnedAny = false
  for i, spec in ipairs(self.NPCS) do
    -- Use stored OID instead of spec.oid since that gets cleared somehow
    local storedOidStr = readData("ScheduledEventFRS:npc_" .. i .. "_oid")
    local storedOid = tonumber(storedOidStr)


    if storedOid then
      local obj = getSceneObject(storedOid)
      if not obj then
        -- NPC is dead, respawn it
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
            writeData("ScheduledEventFRS:npc_" .. i .. "_oid", tostring(newOid))

            -- Re-add the FRS XP observer
            createObserver(OBJECTDESTRUCTION,
                           "ScheduledEventFRS",
                           "onEventMobDied",
                           pMob)
            respawnedAny = true
          end
        else
        end
      else
        -- Check if the NPC is actually alive (has health > 0)
        local so = LuaSceneObject(obj)
        if so then
          local creature = LuaCreatureObject(obj)
          if creature then
            local health = creature:getHAM(0)  -- Get health
            if health <= 0 then

              -- Respawn (corpse will disappear when looted automatically)
              local z = safeTerrainZ(spec.planet, spec.x, spec.y)
              local hdg = spec.heading or 0
              local cell = spec.cell or 0

              local pMob = spawnMobile(spec.planet, spec.template, 0, spec.x, z, spec.y, hdg, cell)
              if pMob ~= nil then
                local newSo = LuaSceneObject(pMob)
                if newSo ~= nil then
                  local newOid = newSo:getObjectID()
                  spec.oid = newOid
                  writeData("ScheduledEventFRS:npc_" .. i .. "_oid", tostring(newOid))

                  -- Re-add the FRS XP observer
                  createObserver(OBJECTDESTRUCTION,
                                 "ScheduledEventFRS",
                                 "onEventMobDied",
                                 pMob)
                  respawnedAny = true
                end
              end
            else
            end
          else
          end
        else
        end
        -- Make sure spec.oid is in sync with stored OID
        spec.oid = storedOid
      end
    else
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
          writeData("ScheduledEventFRS:npc_" .. i .. "_oid", tostring(newOid))

          -- Add the FRS XP observer
          createObserver(OBJECTDESTRUCTION,
                         "ScheduledEventFRS",
                         "onEventMobDied",
                         pMob)
          respawnedAny = true
        end
      end
    end
  end

  if respawnedAny then
  else
  end

  -- Schedule next respawn check ONLY if event is still active
  self:scheduleEventRespawn()
  return 0
end

function ScheduledEventFRS:monitorEvent(pCreatureObject, pPlayer)
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")

  if eventEnded then
    return 0
  end

  if tnow >= activeUntil then
    self:endEventNow()
    return 0
  end

  -- Still active, check again in 5 seconds
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
  return 0
end

function ScheduledEventFRS:attemptCleanup()
  
  -- Try multiple approaches to find and destroy NPCs
  local destroyedCount = 0
  
  -- Method 1: Use stored OIDs from spawn
  for i, spec in ipairs(self.NPCS) do
    local storedOid = readData("ScheduledEventFRS:npc_" .. i .. "_oid")
    local template = readData("ScheduledEventFRS:npc_" .. i .. "_template")
    
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
          if not success then
          end
        else
        end
      end
    end
    
    -- Also try the spec.oid if it exists
    if spec.oid and spec.oid ~= tonumber(storedOid) then
      local obj = getSceneObject(spec.oid)
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

function ScheduledEventFRS:endEventNow()
  
  -- Mark event as definitively ended
  writeData(KEY_EVENT_ENDED, "true")
  self._active = false
  
  -- Attempt to remove all NPCs
  self:attemptCleanup()
  
  -- Clean up all data
  deleteData(KEY_ACTIVE_UNTIL)
  deleteData(KEY_EVENT_START_TIME)
  deleteData("ScheduledEventFRS:cutoff_reached")
  
  -- Clean up NPC tracking data
  for i, spec in ipairs(self.NPCS) do
    deleteData("ScheduledEventFRS:npc_" .. i .. "_oid")
    deleteData("ScheduledEventFRS:npc_" .. i .. "_template")
  end
  
  local endTime = self:getEndTime()
  
  if self.END_MSG and self.END_MSG ~= "" then
    broadcastAllPlayers(self.END_MSG)
  end
  
  -- If using weekly mode, arm the next event
  if self.MODE == "WEEKLY" then
    self:armNext()
  end
end

-- ============================= MAIN ENTRY POINTS =============================

function ScheduledEventFRS:start()
  local tnow = now()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0

  if activeUntil > tnow then
    self._active = true
    createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
    return
  end

  if self.CATCH_UP_IF_MISSED then
    local lastStart = self:lastScheduledStartAtOrBefore(tnow)
    local endTime = self:getEndTime()
    local durationSeconds = endTime - self:getStartTime()
    if lastStart and (tnow - lastStart) < durationSeconds then
      local remain = durationSeconds - (tnow - lastStart)
      self:beginEvent()
      return
    end
  end

  self:armNext()
end

function ScheduledEventFRS:armNext()
  local secs = self:secondsUntilStart()
  local fireAt = now() + secs
  writeData(KEY_ARMED_UNTIL, fireAt)
  createEvent(toMillis(secs), self.screenplayName, "beginEvent", 0, "")
end

function ScheduledEventFRS:beginEvent(pCreatureObject, pPlayer)
  local tnow = now()
  local endTime = self:getEndTime()
  
  -- Clear any previous state
  deleteData(KEY_EVENT_ENDED)
  deleteData("ScheduledEventFRS:cutoff_reached")
  writeData(KEY_ACTIVE_UNTIL, endTime)
  self._active = true
  
  
  if self.START_MSG and self.START_MSG ~= "" then
    broadcastAllPlayers(self.START_MSG)
  end
  
  -- Spawn NPCs with FRS observers
  self:spawnAll()
  
  -- Start simple monitoring
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
  
end

function ScheduledEventFRS:manualStart()
  local tnow = now()
  local endTime = self:getEndTime()
  
  -- Clear any previous state
  deleteData(KEY_EVENT_ENDED)
  deleteData("ScheduledEventFRS:cutoff_reached")
  writeData(KEY_ACTIVE_UNTIL, endTime)
  self._active = true
  
  
  if self.START_MSG and self.START_MSG ~= "" then
    broadcastAllPlayers(self.START_MSG)
  end
  
  -- Spawn NPCs with FRS observers
  self:spawnAll()
  
  -- Start simple monitoring
  createEvent(5000, self.screenplayName, "monitorEvent", 0, "")
  
end

function ScheduledEventFRS:forceEnd()
  self:endEventNow()
end

function ScheduledEventFRS:status()
  local tnow = now()
  local startTime = self:getStartTime()
  local endTime = self:getEndTime()
  local activeUntil = tonumber(readData(KEY_ACTIVE_UNTIL)) or 0
  local eventEnded = (readData(KEY_EVENT_ENDED) == "true")
  local cutoffReached = (readData("ScheduledEventFRS:cutoff_reached") == "1")
  
  
  if self:isEventTimeActive() and not eventEnded then
  else
  end
  
  -- Show NPC tracking info
  for i, spec in ipairs(self.NPCS) do
    local storedOid = readData("ScheduledEventFRS:npc_" .. i .. "_oid")
    local template = readData("ScheduledEventFRS:npc_" .. i .. "_template")
  end
end

-- Convenience function to set new absolute times
function ScheduledEventFRS:setAbsoluteTimes(startYear, startMonth, startDay, startHour, startMin, endYear, endMonth, endDay, endHour, endMin)
  self.MODE = "ABSOLUTE"
  self.START_TIME = {
    year = startYear, month = startMonth, day = startDay,
    hour = startHour, min = startMin or 0, sec = 0
  }
  self.END_TIME = {
    year = endYear, month = endMonth, day = endDay,
    hour = endHour, min = endMin or 0, sec = 0
  }
  
end