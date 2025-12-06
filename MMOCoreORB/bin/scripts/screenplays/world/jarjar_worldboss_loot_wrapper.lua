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
  if pBoss and pAttacker then
    WorldBossLootManager:trackDamage(pBoss, pAttacker)
  end
  return 0
end

-- Helper function to attach observers
local function attachObservers(pBoss)
  if not pBoss then return end

  local bossOID = SceneObject(pBoss):getObjectID()
  if observersAttached[bossOID] then
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

  observersAttached[bossOID] = true
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
    local bossOID = SceneObject(pBoss):getObjectID()

    -- Attach observers if not already done (handles bosses that were alive before wrapper loaded)
    if not observersAttached[bossOID] then
      attachObservers(pBoss)
    end

    -- Check for death
    local co = LuaCreatureObject(pBoss)
    if co and co:isDead() then
      -- Check if this is the first time we detected death
      if lastKnownHP[bossOID] then
        WorldBossLootManager:onBossDeath(pBoss, JARJAR_LOOT_GROUPS, "Jar Jar Binks")
        lastKnownHP[bossOID] = nil
        observersAttached[bossOID] = nil
      end
    elseif co then
      -- Store HP to detect death on next iteration
      lastKnownHP[bossOID] = co:getHAM(0) or 0
    end
  end

  -- Call original watchLoop
  if originalWatchLoop then
    return originalWatchLoop(self, _, _)
  end
  return 0
end

print("[JARJAR-LOOT] Loot wrapper loaded - automatic distribution enabled")
