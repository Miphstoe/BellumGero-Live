-- ##############################################################
-- world_boss_loot_manager.lua - Manages loot distribution for world bosses
-- Tracks eligible players who damage the boss
-- Each eligible player gets one guaranteed item directly in inventory
-- Automatic loot distribution on boss death
-- ##############################################################

local Logger = require("utils.logger")

-- ===== Config =====
local LOOT_BOX_TEMPLATE = "object/tangible/container/loot/placable_loot_crate_tech_chest.iff"
local ELIGIBILITY_RADIUS = 64  -- meters - players must be within this range when boss dies (fallback: all damagers if proximity APIs unavailable)
local BOX_LIFETIME_SECONDS = 30 * 60  -- 30 minutes
local DEBUG_LOGS = true  -- Set to true for detailed debugging (ENABLED to verify level scaling)
local CREDITS_PER_PLAYER = 5000  -- Credits awarded to each eligible player

-- ===== Globals for tracking =====
_G.__WB_LOOT_BOXES = _G.__WB_LOOT_BOXES or {}  -- boxOID -> { bossOID, eligiblePlayers{[playerOID]=true}, lootedPlayers{[playerOID]=true}, lootGroups, spawnTime }
_G.__WB_DAMAGE_TRACKING = _G.__WB_DAMAGE_TRACKING or {}  -- bossOID -> { [playerOID]=true }

-- ===== Utils =====
local function log(fmt, ...)
  if DEBUG_LOGS then
    print("[WBLootMgr] " .. string.format(fmt, ...))
  end
end

local function isPlayerPtr(p)
  if p == nil then return false end
  local ok, res = pcall(function() return SceneObject(p):isPlayerCreature() end)
  return ok and res == true
end

local function getPlayerOID(pPlayer)
  if not isPlayerPtr(pPlayer) then return nil end
  local ok, oid = pcall(function() return SceneObject(pPlayer):getObjectID() end)
  return ok and oid or nil
end

local function notifyPlayer(pPlayer, msg)
  if not isPlayerPtr(pPlayer) then return end
  pcall(function() CreatureObject(pPlayer):sendSystemMessage(msg) end)
end

local function resolvePlayerFromKiller(pKiller)
  if pKiller == nil then return nil end
  if isPlayerPtr(pKiller) then return pKiller end

  local ok, pet = pcall(function() return CreatureObject(pKiller) end)
  if ok and pet and type(pet.getLinkedCreature) == "function" then
    local owner = pet:getLinkedCreature()
    if owner and isPlayerPtr(owner) then return owner end
  end

  if ok and pet and type(pet.getOwner) == "function" then
    local owner = pet:getOwner()
    if owner and isPlayerPtr(owner) then return owner end
  end

  return nil
end

local function getNearbyPlayers(pBoss, radius)
  local players = {}
  local seen = {}

  if pBoss == nil then
    log("ERROR: pBoss is nil in getNearbyPlayers")
    return players
  end
  if radius == nil then
    log("ERROR: radius is nil in getNearbyPlayers")
    return players
  end

  log("Starting proximity check with radius %dm", radius)

  -- Try method 1: getPlayerCreaturesInRange with pBoss directly
  log("Trying method 1: getPlayerCreaturesInRange(pBoss, radius)")
  if type(getPlayerCreaturesInRange) == "function" then
    local ok, list = pcall(getPlayerCreaturesInRange, pBoss, radius)
    log("Method 1 - ok=%s, list type=%s", tostring(ok), type(list))
    if ok and type(list) == "table" then
      log("Method 1 returned %d entries", #list)
      for i = 1, #list do
        local p = list[i]
        if isPlayerPtr(p) then
          local oid = getPlayerOID(p)
          if oid and not seen[oid] then
            seen[oid] = true
            table.insert(players, p)
            log("Found nearby player OID %s (method 1)", tostring(oid))
          end
        end
      end
    else
      log("Method 1 failed or returned non-table: %s", tostring(list))
    end
  else
    log("Method 1 skipped: getPlayerCreaturesInRange not a function")
  end

  -- Try method 2: getPlayerCreaturesInRange with planet coords
  log("Trying method 2: getPlayerCreaturesInRange(planet, x, y, radius)")
  local so = SceneObject(pBoss)
  if so then
    local planet = so:getZoneName()
    local x = so:getWorldPositionX()
    local y = so:getWorldPositionY()
    log("Boss location: %s (%.1f, %.1f)", tostring(planet), x, y)

    if type(getPlayerCreaturesInRange) == "function" then
      local ok, list = pcall(getPlayerCreaturesInRange, planet, x, y, radius)
      log("Method 2 - ok=%s, list type=%s", tostring(ok), type(list))
      if ok and type(list) == "table" then
        log("Method 2 returned %d entries", #list)
        for i = 1, #list do
          local p = list[i]
          if isPlayerPtr(p) then
            local oid = getPlayerOID(p)
            if oid and not seen[oid] then
              seen[oid] = true
              table.insert(players, p)
              log("Found nearby player OID %s (method 2)", tostring(oid))
            end
          end
        end
      else
        log("Method 2 failed or returned non-table: %s", tostring(list))
      end
    end
  else
    log("Method 2 skipped: SceneObject(pBoss) is nil")
  end

  -- Try method 3: getPlayerCreaturesInZone with manual distance check
  log("Trying method 3: getPlayerCreaturesInZone with manual distance")
  if so and type(getPlayerCreaturesInZone) == "function" then
    local planet = so:getZoneName()
    local x = so:getWorldPositionX()
    local y = so:getWorldPositionY()
    local ok, list = pcall(getPlayerCreaturesInZone, planet)
    log("Method 3 - ok=%s, list type=%s", tostring(ok), type(list))
    if ok and type(list) == "table" then
      log("Method 3 returned %d players in zone", #list)
      for i = 1, #list do
        local p = list[i]
        if isPlayerPtr(p) then
          local pSo = SceneObject(p)
          if pSo then
            local px = pSo:getWorldPositionX()
            local py = pSo:getWorldPositionY()
            local dx = px - x
            local dy = py - y
            local dist = math.sqrt(dx * dx + dy * dy)
            log("Player at distance %.1fm (threshold: %dm)", dist, radius)
            if dist <= radius then
              local oid = getPlayerOID(p)
              if oid and not seen[oid] then
                seen[oid] = true
                table.insert(players, p)
                log("Found nearby player OID %s at distance %.1fm (method 3)", tostring(oid), dist)
              end
            end
          end
        end
      end
    else
      log("Method 3 failed or returned non-table: %s", tostring(list))
    end
  else
    log("Method 3 skipped: so=%s, getPlayerCreaturesInZone=%s", tostring(so), type(getPlayerCreaturesInZone))
  end

  log("Total nearby players found: %d (within %dm radius)", #players, radius)
  return players
end

-- ===== Damage Tracking =====
local function trackDamager(pBoss, pAttacker)
  if pBoss == nil or pAttacker == nil then return end

  local soBoss = SceneObject(pBoss)
  if soBoss == nil then return end

  local bossOID = soBoss:getObjectID()
  if bossOID == nil then return end

  local pOwner = isPlayerPtr(pAttacker) and pAttacker or resolvePlayerFromKiller(pAttacker)
  if not pOwner then return end

  local playerOID = getPlayerOID(pOwner)
  if not playerOID then return end

  local set = _G.__WB_DAMAGE_TRACKING[bossOID]
  if set == nil then
    set = {}
    _G.__WB_DAMAGE_TRACKING[bossOID] = set
  end

  -- Only log if this is the first time tracking this player
  local wasNew = not set[playerOID]
  set[playerOID] = true

  if wasNew then
    log("Player OID %s is now eligible for loot from boss OID %s", tostring(playerOID), tostring(bossOID))
  end
end

-- ===== Eligibility Collection =====
local function collectEligiblePlayers(pBoss, bossOID)
  local eligible = {}
  local seen = {}

  local damagers = _G.__WB_DAMAGE_TRACKING[bossOID] or {}

  -- Try to get nearby players
  local nearby = getNearbyPlayers(pBoss, ELIGIBILITY_RADIUS)
  local nearbyCount = #nearby

  local damagerCount = 0
  for _ in pairs(damagers) do damagerCount = damagerCount + 1 end

  log("Boss OID %s - Checking eligibility: %d damagers tracked, %d nearby players",
      tostring(bossOID), damagerCount, nearbyCount)

  -- If proximity detection works, use it
  if nearbyCount > 0 then
    log("Using proximity-based eligibility (damaged AND nearby)")
    for _, pPlayer in ipairs(nearby) do
      local playerOID = getPlayerOID(pPlayer)
      if playerOID and damagers[playerOID] and not seen[playerOID] then
        eligible[playerOID] = true
        seen[playerOID] = true
        log("Player OID %s is eligible (damaged boss AND nearby)", tostring(playerOID))
      end
    end
  else
    -- Fallback: proximity APIs not available, give loot to all damagers
    log("FALLBACK: Proximity detection unavailable - giving loot to all damagers")
    for playerOID, _ in pairs(damagers) do
      if playerOID and not seen[playerOID] then
        eligible[playerOID] = true
        seen[playerOID] = true
        log("Player OID %s is eligible (damaged boss - proximity check unavailable)", tostring(playerOID))
      end
    end
  end

  local count = 0
  for _ in pairs(eligible) do count = count + 1 end
  log("Total eligible players: %d", count)

  return eligible
end

-- ===== Loot Box Creation =====
local function createLootBox(pBoss, bossOID, eligiblePlayers, lootGroups, bossName, bossLevel)
  if pBoss == nil then
    log("ERROR: Cannot create loot box - pBoss is nil")
    return nil
  end

  local soBoss = SceneObject(pBoss)
  if soBoss == nil then
    log("ERROR: Cannot create loot box - boss SceneObject is nil")
    return nil
  end

  local planet = soBoss:getZoneName()
  local x = soBoss:getWorldPositionX()
  local y = soBoss:getWorldPositionY()
  local z = soBoss:getWorldPositionZ()

  log("Creating loot box at boss location: %s (%.1f, %.1f, %.1f)", planet, x, y, z)

  local pBox = spawnSceneObject(planet, LOOT_BOX_TEMPLATE, x, y, z, 0, 0)

  if pBox == nil then
    log("ERROR: Failed to spawn loot box")
    return nil
  end

  local soBox = SceneObject(pBox)
  if soBox then
    local customName = bossName and (bossName .. "'s Treasure") or "World Boss Treasure"
    soBox:setCustomObjectName(customName)
    log("Loot box created with custom name: %s", customName)
  end

  local boxOID = soBox:getObjectID()

  _G.__WB_LOOT_BOXES[boxOID] = {
    bossOID = bossOID,
    eligiblePlayers = eligiblePlayers,
    lootedPlayers = {},
    lootGroups = lootGroups,
    bossName = bossName,
    bossLevel = bossLevel or 1,
    spawnTime = os.time(),
    planet = planet,
    x = x,
    y = y,
    z = z
  }

  log("Loot box OID %s created for boss OID %s (level %d) with %d eligible players",
      tostring(boxOID),
      tostring(bossOID),
      bossLevel or 1,
      (function() local c=0; for _ in pairs(eligiblePlayers) do c=c+1 end return c end)())

  createEvent(BOX_LIFETIME_SECONDS * 1000, "WorldBossLootManager", "despawnLootBox", pBox, "")

  return pBox
end

-- ===== Loot Generation =====
local function generateLootForPlayer(pPlayer, lootGroups, bossName, bossLevel)
  if not isPlayerPtr(pPlayer) then
    log("Player is not valid")
    return false
  end

  if not lootGroups or #lootGroups == 0 then
    log("No loot groups available")
    return false
  end

  -- Default to level 1 if not provided (backward compatibility)
  local lootLevel = tonumber(bossLevel) or 1
  log("Generating loot at level %d for player", lootLevel)

  -- Select a random loot group from the boss's loot tables
  local selectedGroup = lootGroups[math.random(#lootGroups)]

  if not selectedGroup or not selectedGroup.groups then
    log("Invalid loot group structure")
    return false
  end

  -- Calculate total weight and select a loot group
  local totalWeight = 0
  for _, entry in ipairs(selectedGroup.groups) do
    totalWeight = totalWeight + (entry.chance or 0)
  end

  if totalWeight <= 0 then
    log("No valid loot weights")
    return false
  end

  local roll = math.random(totalWeight)
  local cumulative = 0
  local selectedLootGroup = nil

  for _, entry in ipairs(selectedGroup.groups) do
    cumulative = cumulative + (entry.chance or 0)
    if roll <= cumulative then
      selectedLootGroup = entry.group
      break
    end
  end

  if not selectedLootGroup then
    log("Failed to select loot group from roll")
    return false
  end

  log("Selected loot group: %s for player", selectedLootGroup)

  -- Get player's inventory
  local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
  if pInventory == nil then
    notifyPlayer(pPlayer, "ERROR: Could not access your inventory.")
    log("Failed to get player inventory")
    return false
  end

  -- Give credits first
  local creditsGiven = false
  local creature = CreatureObject(pPlayer)
  if creature then
    pcall(function()
      creature:addCashCredits(CREDITS_PER_PLAYER, true)
      creditsGiven = true
      log("Gave %d credits to player", CREDITS_PER_PLAYER)
    end)
  end

  -- Use createLoot to generate item from the loot group
  -- Syntax: createLoot(container, lootGroup, level, true)
  -- Use boss level for proper loot scaling
  local itemOID = createLoot(pInventory, selectedLootGroup, lootLevel, true)
  log("createLoot called with level %d, group: %s", lootLevel, selectedLootGroup)

  if itemOID and itemOID ~= 0 then
    local pItem = getSceneObject(itemOID)
    local itemName = "an item"
    if pItem then
      local itemSO = SceneObject(pItem)
      if itemSO then
        itemName = itemSO:getDisplayedName() or "an item"
      end
    end

    -- Build reward message
    local rewardMsg = "\\#00FF00You received: " .. itemName
    if creditsGiven then
      rewardMsg = rewardMsg .. " and " .. CREDITS_PER_PLAYER .. " credits"
    end
    rewardMsg = rewardMsg .. " from " .. (bossName or "the World Boss") .. "!"

    notifyPlayer(pPlayer, rewardMsg)
    log("Successfully created loot from group %s (OID: %s) and gave %d credits", selectedLootGroup, tostring(itemOID), CREDITS_PER_PLAYER)
    return true
  else
    -- Even if item creation failed, credits might have been given
    if creditsGiven then
      notifyPlayer(pPlayer, "\\#00FF00You received " .. CREDITS_PER_PLAYER .. " credits from " .. (bossName or "the World Boss") .. "!")
      log("Credits given but item creation failed for group: %s", selectedLootGroup)
      return true
    else
      notifyPlayer(pPlayer, "ERROR: Failed to create loot. Your inventory may be full or the loot group is invalid.")
      log("createLoot failed for group: %s", selectedLootGroup)
      return false
    end
  end
end

-- ===== Player Interaction =====
local function onPlayerOpenLootBox(pBox, pPlayer)
  if not isPlayerPtr(pPlayer) then return end

  local soBox = SceneObject(pBox)
  if soBox == nil then return end

  local boxOID = soBox:getObjectID()
  local boxData = _G.__WB_LOOT_BOXES[boxOID]

  if not boxData then
    notifyPlayer(pPlayer, "This loot box is no longer valid.")
    log("Player tried to open invalid loot box OID %s", tostring(boxOID))
    return
  end

  local playerOID = getPlayerOID(pPlayer)
  if not playerOID then return end

  if not boxData.eligiblePlayers[playerOID] then
    notifyPlayer(pPlayer, "You are not eligible to loot this box. You must have damaged the boss and been nearby when it died.")
    log("Player OID %s not eligible for loot box OID %s", tostring(playerOID), tostring(boxOID))
    return
  end

  if boxData.lootedPlayers[playerOID] then
    notifyPlayer(pPlayer, "You have already looted this box.")
    log("Player OID %s already looted box OID %s", tostring(playerOID), tostring(boxOID))
    return
  end

  local bossName = boxData.bossName or "the World Boss"
  local bossLevel = boxData.bossLevel or 1

  if generateLootForPlayer(pPlayer, boxData.lootGroups, bossName, bossLevel) then
    boxData.lootedPlayers[playerOID] = true
    log("Player OID %s successfully looted box OID %s (level %d loot)", tostring(playerOID), tostring(boxOID), bossLevel)

    local totalEligible = 0
    local totalLooted = 0
    for _ in pairs(boxData.eligiblePlayers) do totalEligible = totalEligible + 1 end
    for _ in pairs(boxData.lootedPlayers) do totalLooted = totalLooted + 1 end

    log("Loot box OID %s: %d/%d players have looted", tostring(boxOID), totalLooted, totalEligible)

    if totalLooted >= totalEligible then
      log("All eligible players have looted box OID %s - despawning", tostring(boxOID))
      createEvent(1000, "WorldBossLootManager", "despawnLootBox", pBox, "")
    end
  end
end

-- ===== Despawn Handler =====
local function despawnLootBox(pBox)
  if pBox == nil then return end

  local soBox = SceneObject(pBox)
  if soBox == nil then return end

  local boxOID = soBox:getObjectID()

  log("Despawning loot box OID %s", tostring(boxOID))

  _G.__WB_LOOT_BOXES[boxOID] = nil

  pcall(function() soBox:destroyObjectFromWorld() end)
  pcall(function() soBox:destroyObjectFromDatabase() end)
end

-- ===== Public API =====
WorldBossLootManager = {}

function WorldBossLootManager:trackDamage(pBoss, pAttacker)
  trackDamager(pBoss, pAttacker)
end

function WorldBossLootManager:onBossDeath(pBoss, lootGroups, bossName)
  if pBoss == nil then
    log("ERROR: onBossDeath called with nil pBoss")
    return nil
  end

  local soBoss = SceneObject(pBoss)
  if soBoss == nil then
    log("ERROR: Cannot get SceneObject for boss")
    return nil
  end

  local bossOID = soBoss:getObjectID()
  if not bossOID then
    log("ERROR: Cannot get boss OID")
    return nil
  end

  -- Get the boss level for proper loot scaling
  local bossLevel = 1
  pcall(function()
    local coBoss = CreatureObject(pBoss)
    if coBoss and coBoss.getLevel then
      bossLevel = coBoss:getLevel() or 1
    end
  end)

  log("Boss died - OID %s, Name: %s, Level: %d", tostring(bossOID), bossName or "Unknown", bossLevel)

  local eligiblePlayers = collectEligiblePlayers(pBoss, bossOID)

  local count = 0
  for playerOID, _ in pairs(eligiblePlayers) do
    count = count + 1
  end

  if count == 0 then
    log("No eligible players for loot")
    _G.__WB_DAMAGE_TRACKING[bossOID] = nil
    return nil
  end

  log("Distributing loot to %d eligible players at level %d", count, bossLevel)

  -- Give loot directly to each eligible player
  for playerOID, _ in pairs(eligiblePlayers) do
    local pPlayer = getSceneObject(tonumber(playerOID))
    if pPlayer and isPlayerPtr(pPlayer) then
      if generateLootForPlayer(pPlayer, lootGroups, bossName, bossLevel) then
        log("Successfully gave level %d loot to player OID %s", bossLevel, tostring(playerOID))
      else
        log("Failed to give loot to player OID %s", tostring(playerOID))
      end
    else
      log("Could not find player object for OID %s", tostring(playerOID))
    end
  end

  -- Clear the boss corpse's loot to prevent double-looting
  if pBoss then
    local corpse = SceneObject(pBoss)
    if corpse then
      -- Remove all items from the corpse
      local containerSize = corpse:getContainerObjectsSize()
      log("Clearing %d items from boss corpse to prevent double-looting", containerSize)

      for i = containerSize - 1, 0, -1 do
        local pItem = corpse:getContainerObject(i)
        if pItem then
          local item = SceneObject(pItem)
          if item then
            item:destroyObjectFromWorld()
            item:destroyObjectFromDatabase()
          end
        end
      end

      -- Clear cash from the corpse using subtractCashCredits (method 4)
      pcall(function()
        local creatureCorpse = CreatureObject(pBoss)
        if creatureCorpse then
          local currentCash = creatureCorpse:getCashCredits()
          if currentCash and currentCash > 0 then
            creatureCorpse:subtractCashCredits(currentCash)
            log("Cleared %d credits from corpse", currentCash)
          end
        end
      end)

      log("Boss corpse cleared - no traditional looting available")
    end
  end

  _G.__WB_DAMAGE_TRACKING[bossOID] = nil

  log("Loot distribution complete for boss OID %s", tostring(bossOID))
  return nil
end

function WorldBossLootManager:onPlayerInteract(pBox, pPlayer)
  onPlayerOpenLootBox(pBox, pPlayer)
end

function WorldBossLootManager:despawnLootBox(pBox)
  despawnLootBox(pBox)
end

-- ===== Events =====
function WorldBossLootManager.despawnLootBox(pBox, _)
  despawnLootBox(pBox)
end

return WorldBossLootManager
