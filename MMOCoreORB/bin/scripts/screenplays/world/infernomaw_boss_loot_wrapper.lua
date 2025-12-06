-- ##############################################################
-- infernomaw_boss_loot_wrapper.lua
-- Wraps the existing Infernomaw boss with WorldBossLootManager
-- Adds damage tracking and automatic loot distribution
-- ##############################################################

local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

-- Store original functions
local originalOnDamage = PekoBoss.onDamage
local originalOnDeath = PekoBoss.onDeath

-- Infernomaw loot groups (from peko_peko_infernomaw.lua)
local INFERNOMAW_LOOT_GROUPS = {
  {
    groups = {
      { group = "peko_albatross", chance = 3500000 },
      { group = "clothing_attachments", chance = 3500000 },
      { group = "armor_attachments", chance = 3000000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "peko_albatross", chance = 3500000 },
      { group = "holocron_dark", chance = 3000000 },
      { group = "holocron_light", chance = 3500000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "peko_albatross", chance = 3000000 },
      { group = "power_crystals", chance = 3500000 },
      { group = "color_crystals", chance = 3500000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "chemistry_component_advanced", chance = 2500000 },
      { group = "armor_component_advanced", chance = 2500000 },
      { group = "weapon_component_advanced", chance = 2500000 },
      { group = "crafting_component_advanced", chance = 2500000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "component_enhancement", chance = 10000000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "sea_removal_tool_1x", chance = 2500000 },
      { group = "clothing_attachments", chance = 3750000 },
      { group = "armor_attachments", chance = 3750000 }
    },
    lootChance = 10000000
  },
  {
    groups = {
      { group = "bg_token_group", chance = 10000000 }
    },
    lootChance = 350000
  }
}

-- Wrap onDamage to add tracking
function PekoBoss:onDamage(pBoss, pAttacker, damage)
  -- Track damage for loot eligibility
  WorldBossLootManager:trackDamage(pBoss, pAttacker)

  -- Call original damage handler
  if originalOnDamage then
    return originalOnDamage(self, pBoss, pAttacker, damage)
  end
  return 0
end

-- Wrap onDeath to add loot distribution
function PekoBoss:onDeath(pBoss, pKiller)
  -- Distribute loot to eligible players
  WorldBossLootManager:onBossDeath(pBoss, INFERNOMAW_LOOT_GROUPS, "Infernomaw")

  -- Call original death handler
  if originalOnDeath then
    return originalOnDeath(self, pBoss, pKiller)
  end
  return 0
end

print("[INFERNOMAW-LOOT] Loot wrapper loaded - automatic distribution enabled")
