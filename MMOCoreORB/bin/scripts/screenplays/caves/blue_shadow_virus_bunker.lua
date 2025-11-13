--=====================================================================
-- Blue Shadow Virus Bunker — Gas + Auth Gate + Gate Officer + Infection/Cure
-- Uses engine DoTs (POISONED for ticking + DISEASED for infection state).
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
  numberOfActs = 1,
  planet = "naboo",

  -- Building objectID (used for exit observer)
  buildingID = 9895361,

  -- TEMP clearance item (swap when your BSV key .iff is ready)
  clearanceTemplate = "object/tangible/mission/quest_item/warren_passkey_s01.iff",

  -- Where to punt unauthorized players (worldcell = 0).  NOTE: (x, z, y, cell)
  outside = { x = -3601.7, z = 29.5, y = 761.2, cell = 0 },

  -- Infection trigger (down the initial ramp) — coords are (x, z, y) LOCAL TO CELL
  infectionArea = {
    cell   = 9895365,
    x      = 3.6,
    z      = -12.0,
    y      = 20.3,
    radius = 12.0,
  },

  -- Cure trigger (medical lab) — coords LOCAL TO CELL
  cureArea = {
    cell   = 9895377,
    x      = 35.6,
    z      = -20.0,
    y      = 142.5,
    radius = 6.0,
  },

  -- Engine DoT parameters (Geonosian Lab pattern)
  -- addDotState(attacker, STATE, strength, POOL, duration, potency, sourceID, defense)
  infection = {
    -- POISONED: provides the actual periodic damage via engine DoT manager
    poison_strength = 120,      -- tick intensity (tune)
    poison_pool     = HEALTH,   -- damage pool for poison (health)
    poison_duration = 7200,     -- seconds
    poison_potency  = 100,
    poison_defense  = 0,

    -- DISEASED: visual state / interaction flag
    disease_strength = 1,       -- tiny; we rely on POISONED for damage
    disease_pool     = HEALTH,
    disease_duration = 7200,
    disease_potency  = 0,
    disease_defense  = 0,
  },

  -- Particle templates
  P_BLUE = "object/static/particle/pt_survey_liquid_sample.iff",
  P_GRAY = "object/static/particle/pt_miasma_of_fog_gray.iff",

  -- Your GAS SPAWNS (coords are x, z, y; z = vertical)
  gasSpawns = {
    { cell=9895365, x= 3.6,  z=-12.0, y=22.7, template="P_BLUE" },
    { cell=9895366, x=-18.8, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x=35.4,  z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x=35.4,  z=-12.0, y=86.8, template="P_BLUE" },
    { cell=9895387, x=-2.7,  z=-20.0, y=71.1, template="P_GRAY" },
    { cell=9895384, x=-22.5, z=-20.0, y=105.2, template="P_BLUE" },
    { cell=9895383, x=-30.1, z=-20.0, y=47.5, template="P_GRAY" },
    { cell=9895381, x=-16.6, z=-20.0, y= 3.1, template="P_BLUE" },
    { cell=9895369, x=-63.8, z=-20.0, y=47.0, template="P_BLUE" },
    { cell=9895372, x=-74.7, z=-20.0, y=80.9, template="P_BLUE" },
    { cell=9895370, x=-67.7, z=-20.0, y=13.1, template="P_BLUE" },
    { cell=9895366, x= 3.7,  z=-12.0, y=63.1, template="P_BLUE" },
    { cell=9895375, x=60.7,  z=-12.0, y=82.8, template="P_BLUE" },
    { cell=9895375, x=60.7,  z=-12.0, y=58.7, template="P_BLUE" },
  },
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

-- Resolve shorthand particle keys
local function resolveTemplate(self, keyOrPath)
  if keyOrPath == "P_BLUE" then return self.P_BLUE end
  if keyOrPath == "P_GRAY" then return self.P_GRAY end
  return keyOrPath
end

-- Per-player visit flags
local function oid(p) return tostring(SceneObject(p):getObjectID()) end
local function keyInfected(p) return oid(p) .. ":bsv:infected" end
local function keyImmune(p)   return oid(p) .. ":bsv:immune" end

--==================================================
-- Startup
--==================================================
function BlueShadowVirusBunkerScreenPlay:start()
  if not isZoneEnabled(self.planet) then return end

  -- Gas
  for _, g in ipairs(self.gasSpawns) do
    spawnSceneObject(self.planet, resolveTemplate(self, g.template), g.x, g.z, g.y, g.cell, g.heading or 0)
  end

  -- Infection/Cure areas + exit reset + auth gate
  self:setupInfectionArea()
  self:setupCureArea()
  self:setupExitObserver()
  self:setupAuthorizationGate()

  -- Gate Officer (mobile .lua handles its own behavior)
  self:spawnMobiles()
end

--==================================================
-- Authorization Gate (Warren pattern)
--==================================================
function BlueShadowVirusBunkerScreenPlay:setupAuthorizationGate()
  local id = self.buildingID
  if not id or id == 0 then return end
  local pBunker = getSceneObject(id)
  if pBunker ~= nil then
    createObserver(ENTEREDBUILDING, "BlueShadowVirusBunkerScreenPlay", "notifyEnteredBsv", pBunker)
  end
end

function BlueShadowVirusBunkerScreenPlay:notifyEnteredBsv(pBuilding, pPlayer)
  if (pBuilding == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
    return 0
  end

  -- Admin bypass for AUTH ONLY (infection does not bypass)
  local pGhost = CreatureObject(pPlayer):getPlayerObject()
  local isAdmin = (pGhost ~= nil and PlayerObject(pGhost):isPrivileged())

  local hasClearance = false
  local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
  if pInventory ~= nil then
    local pKey = getContainerObjectByTemplate(pInventory, self.clearanceTemplate, true)
    hasClearance = (pKey ~= nil)
  end

  if isAdmin or hasClearance then
    CreatureObject(pPlayer):sendSystemMessage("Authorization accepted. Welcome to the Blue Shadow Facility.")
  else
    CreatureObject(pPlayer):sendSystemMessage("ACCESS DENIED: You do not have the proper authorization to enter.")
    SceneObject(pPlayer):teleport(self.outside.x, self.outside.z, self.outside.y, self.outside.cell)
  end

  return 0
end

--==================================================
-- Infection & Cure — convert local (cell) coords to world, then spawn areas
--==================================================
local function spawnAreaFromLocalCoords(planet, cell, x, z, y, radius)
  local pMarker = spawnSceneObject(planet, "object/tangible/theme_park/invisible_object.iff", x, z, y, cell, 0)
  if pMarker == nil then return nil end
  local sx = SceneObject(pMarker):getWorldPositionX()
  local sz = SceneObject(pMarker):getWorldPositionZ()
  local sy = SceneObject(pMarker):getWorldPositionY()
  local parent = SceneObject(pMarker):getParentID()
  local pArea = spawnActiveArea(planet, "object/active_area.iff", sx, sz, sy, radius or 5.0, parent)
  SceneObject(pMarker):destroyObjectFromWorld(); SceneObject(pMarker):destroyObjectFromDatabase()
  return pArea
end

function BlueShadowVirusBunkerScreenPlay:setupInfectionArea()
  local a = self.infectionArea
  if not a or not a.cell then return end
  local pArea = spawnAreaFromLocalCoords(self.planet, a.cell, a.x, a.z, a.y, a.radius or 5.0)
  if pArea ~= nil then
    createObserver(ENTEREDAREA, "BlueShadowVirusBunkerScreenPlay", "onEnterInfectionArea", pArea)
    print("BSV: Infection area armed (cell->world)")
  else
    printLuaError("BSV: Failed to spawn infection active area.")
  end
end

function BlueShadowVirusBunkerScreenPlay:setupCureArea()
  local a = self.cureArea
  if not a or not a.cell then return end
  local pArea = spawnAreaFromLocalCoords(self.planet, a.cell, a.x, a.z, a.y, a.radius or 5.0)
  if pArea ~= nil then
    createObserver(ENTEREDAREA, "BlueShadowVirusBunkerScreenPlay", "onEnterCureArea", pArea)
    print("BSV: Cure area armed (cell->world)")
  else
    printLuaError("BSV: Failed to spawn cure active area.")
  end
end

--==================================================
-- Infection apply (engine DoTs only; no manual damage calls)
--==================================================
function BlueShadowVirusBunkerScreenPlay:onEnterInfectionArea(pArea, pMoving)
  if pArea == nil or pMoving == nil or not SceneObject(pMoving):isPlayerCreature() then return 0 end

  if readData(keyImmune(pMoving)) == 1 then return 0 end
  if readData(keyInfected(pMoving)) == 1 then return 0 end

  local cfg = self.infection
  local src = SceneObject(pArea):getObjectID()

  -- Apply POISONED for ticking damage (Geo Lab proven)
  CreatureObject(pMoving):addDotState(pMoving, POISONED, cfg.poison_strength, cfg.poison_pool, cfg.poison_duration, cfg.poison_potency, src, cfg.poison_defense)
  -- Apply DISEASED for the infection state/icon
  CreatureObject(pMoving):addDotState(pMoving, DISEASED, cfg.disease_strength, cfg.disease_pool, cfg.disease_duration, cfg.disease_potency, src, cfg.disease_defense)

  writeData(keyInfected(pMoving), 1)
  CreatureObject(pMoving):sendSystemMessage("\\#FF5555You have been infected with the Blue Shadow Virus! Seek the cure in the medical lab.")
  return 0
end

--==================================================
-- Cure (clear BOTH states; grant visit immunity)
--==================================================
function BlueShadowVirusBunkerScreenPlay:onEnterCureArea(pArea, pMoving)
  if pArea == nil or pMoving == nil or not SceneObject(pMoving):isPlayerCreature() then return 0 end

  if readData(keyInfected(pMoving)) ~= 1 and CreatureObject(pMoving):hasState(DISEASED) ~= 1 and CreatureObject(pMoving):hasState(POISONED) ~= 1 then
    return 0
  end

  CreatureObject(pMoving):clearState(DISEASED)
  CreatureObject(pMoving):clearState(POISONED)
  deleteData(keyInfected(pMoving))
  writeData(keyImmune(pMoving), 1)

  CreatureObject(pMoving):sendSystemMessage("\\#55FF55You have been cured of the Blue Shadow Virus.")
  return 0
end

--==================================================
-- Reset flags on bunker exit so next visit can re-infect
--==================================================
function BlueShadowVirusBunkerScreenPlay:setupExitObserver()
  local id = self.buildingID
  if not id or id == 0 then return end
  local pBunker = getSceneObject(id)
  if pBunker ~= nil then
    createObserver(EXITEDBUILDING, "BlueShadowVirusBunkerScreenPlay", "onExitBunker", pBunker)
  end
end

function BlueShadowVirusBunkerScreenPlay:onExitBunker(pBuilding, pPlayer)
  if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then return 0 end
  deleteData(keyInfected(pPlayer))
  deleteData(keyImmune(pPlayer))
  print("BSV: Cleared visit flags for " .. oid(pPlayer))
  return 0
end

--==================================================
-- Mobiles (minimal; let mobile .lua handle convo/flags)
--==================================================
function BlueShadowVirusBunkerScreenPlay:spawnMobiles()
  local pNpc = spawnMobile(self.planet, "bsv_gate_officer", 0, -3614, 30, 764, 90, 0)
  if pNpc == nil then
    printLuaError("BSV: failed to spawn gate officer at (-3614,30,764).")
  end
end

-- ---------------------------------------------------------------
-- Optional: live particle preview helper
-- ---------------------------------------------------------------
function bsv_gas(cell, x, z, y, template)
  local sp = BlueShadowVirusBunkerScreenPlay
  if not isZoneEnabled(sp.planet) then return end
  spawnSceneObject(sp.planet, resolveTemplate(sp, template), x, z, y, cell, 0)
end
