-- ##############################################################
-- jarjar_worldboss_loot_wrapper.lua
-- Adds damage tracking and loot distribution to Jar Jar world boss
-- Since Jar Jar uses observerless polling, we hook into watchLoop
-- ##############################################################

local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

-- Jar Jar loot groups (from jarjar_boss.lua)
local JARJAR_LOOT_GROUPS = {
  {
    groups = {
      {group = "power_crystals", chance = 6000000},
      {group = "holocron_light", chance = 2000000},
      {group = "holocron_dark", chance = 2000000}
    },
    lootChance = 10000000
  },
  {
    groups = {
      {group = "clothing_attachments", chance = 6000000},
      {group = "potted_plants_sml_s02_schematic", chance = 2000000},
      {group = "sea_removal_tool", chance = 2000000}
    },
    lootChance = 5000000
  },
  {
    groups = {
      {group = "color_crystals", chance = 6000000},
      {group = "potted_plants_sml_s02_schematic", chance = 2000000},
      {group = "sea_removal_tool", chance = 2000000}
    },
    lootChance = 2500000
  },
  {
    groups = {
      {group = "armor_attachments", chance = 6000000},
      {group = "potted_plants_sml_s02_schematic", chance = 2000000},
      {group = "sea_removal_tool", chance = 2000000}
    },
    lootChance = 1250000
  },
  {
    groups = {
      {group = "house_deeds", chance = 10000000}
    },
    lootChance = 600000
  },
  {
    groups = {
      {group = "bg_token_group", chance = 10000000}
    },
    lootChance = 350000
  }
}

-- Prevent double-wrapping
if rawget(_G, "JARJAR_LOOT_WRAPPER_LOADED") then
  print("[JARJAR-LOOT] Wrapper already loaded, skipping duplicate load")
  return
end
_G.JARJAR_LOOT_WRAPPER_LOADED = true

-- Store original spawnBoss and watchLoop functions
local originalSpawnBoss = JarJarWorldBossSimple.spawnBoss
local originalWatchLoop = JarJarWorldBossSimple.watchLoop
local lastKnownHP = {}
local observersAttached = {}

-- Create a screenplay object for damage tracking
JarJarLootObserver = ScreenPlay:new {
  numberOfActs = 1,
  screenplayName = "JarJarLootObserver"
}
registerScreenPlay("JarJarLootObserver", true)

-- Damage handler - called by observer
function JarJarLootObserver:onDamage(pBoss, pAttacker, damage)
  if not pBoss or not pAttacker then
    return 0
  end

  -- Safely track damage with error handling
  pcall(function()
    WorldBossLootManager:trackDamage(pBoss, pAttacker)
  end)

  return 0
end

-- Helper function to attach observers
local function attachObservers(pBoss)
  if not pBoss then return end

  local bossOID = 0
  local success = pcall(function()
    local so = SceneObject(pBoss)
    if so and so.getObjectID then
      bossOID = so:getObjectID()
    end
  end)

  if not success or not bossOID or bossOID == 0 then
    print("[JARJAR-LOOT] Failed to get boss OID, skipping observer attach")
    return
  end

  -- Check if already attached (local table)
  if observersAttached[bossOID] then
    return
  end

  -- Check if already attached (persistent storage to survive script reloads)
  local attachedKey = "jarjar_observers_attached_" .. tostring(bossOID)
  if readData(attachedKey) == "1" then
    observersAttached[bossOID] = true
    return
  end

  print("[JARJAR-LOOT] Attaching damage observers to Jar Jar OID " .. tostring(bossOID))

  -- Try damage observers
  local dmgCands = {"DAMAGERECEIVED", "COMBATDAMAGE", "DAMAGE"}
  for _, nm in ipairs(dmgCands) do
    local ev = rawget(_G, nm)
    if type(ev) == "number" then
      pcall(createObserver, ev, "JarJarLootObserver", "onDamage", pBoss)
    end
  end

  -- Mark as attached in both local table and persistent storage
  observersAttached[bossOID] = true
  writeData(attachedKey, "1")
end

-- Wrap spawnBoss to attach observers after spawn
function JarJarWorldBossSimple:spawnBoss(_, _)
  -- Call original spawn
  local result = 0
  if originalSpawnBoss then
    result = originalSpawnBoss(self, _, _)
  end

  -- Attach observers to the spawned boss
  local pBoss = self.bossPtr
  if pBoss then
    attachObservers(pBoss)
  end

  return result
end

-- Wrap watchLoop to detect death AND attach observers for already-spawned bosses
function JarJarWorldBossSimple:watchLoop(_, _)
  local pBoss = self.bossPtr

  if pBoss then
    local bossOID = 0
    local oidSuccess = pcall(function()
      local so = SceneObject(pBoss)
      if so and so.getObjectID then
        bossOID = so:getObjectID()
      end
    end)

    if oidSuccess and bossOID and bossOID > 0 then
      -- Attach observers if not already done (handles bosses that were alive before wrapper loaded)
      if not observersAttached[bossOID] then
        attachObservers(pBoss)
      end

      -- Check for death
      local isDead = false
      local currentHP = 0
      pcall(function()
        local co = LuaCreatureObject(pBoss)
        if co then
          isDead = co:isDead()
          if not isDead then
            currentHP = co:getHAM(0) or 0
          end
        end
      end)

      if isDead then
        -- Check if this is the first time we detected death
        if lastKnownHP[bossOID] then
          WorldBossLootManager:onBossDeath(pBoss, JARJAR_LOOT_GROUPS, "Jar Jar Binks")
          lastKnownHP[bossOID] = nil
          observersAttached[bossOID] = nil
          -- Clean up persistent observer flag
          local attachedKey = "jarjar_observers_attached_" .. tostring(bossOID)
          deleteData(attachedKey)
        end
      else
        -- Store HP to detect death on next iteration
        lastKnownHP[bossOID] = currentHP
      end
    end
  end

  -- Call original watchLoop
  if originalWatchLoop then
    return originalWatchLoop(self, _, _)
  end
  return 0
end

print("[JARJAR-LOOT] Loot wrapper loaded - automatic distribution enabled")
