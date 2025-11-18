--=====================================================================
-- Blue Shadow Virus Bunker — Gas + Auth Gate + Gate Officer + Infection/Cure
-- Uses engine DoTs (POISONED for ticking + DISEASED for infection state).
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
  numberOfActs = 1,
  planet = "naboo",

  -- Building objectID (used for auth observer)
  buildingID = 9895361,

  -- TEMP clearance item (swap when your BSV key .iff is ready)
  clearanceTemplate = "object/tangible/mission/quest_item/bsv_entry_passkey.iff",

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

  -- Exit clear trigger (just outside the bunker door, world coords)
  exitClearArea = {
    x      = -3615.5,  -- match outside.x
    z      = 30.4,     -- match outside.z
    y      = 759.8,    -- match outside.y
    radius = 2.0,      -- adjust as needed
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

  -- Which template to use for each quiz droid type
  quizDroidTypes = {
    ["3po"] = { real = "bsv_quiz_3po",  dummy = "bsv_quiz_3po_dummy"  },
    ["21b"] = { real = "bsv_quiz_21b",  dummy = "bsv_quiz_21b_dummy"  },
    ["ra7"] = { real = "bsv_quiz_ra7",  dummy = "bsv_quiz_ra7_dummy"  }
  },

  -- Spawn points for potential quiz MSE droids (FILL THESE IN)
  -- Each entry: {cell = <cellId>, x = <x>, z = <z>, y = <y>, heading = <h>}
  quizDroidSpawns = {
    -- Examples / placeholders:
    {cell = 9895366, x = 5.0,   z = -12.0, y = 52.7, heading = -36, droidType = "3po"},
    {cell = 9895369, x = -75.9, z = -20.0, y = 47.0, heading = 85,  droidType = "ra7"},
    {cell = 9895369, x = -57.0, z = -20.0, y = 23.9, heading = 49,  droidType = "ra7"},
    {cell = 9895369, x = -61.1, z = -20.0, y = 37.9, heading = 105, droidType = "ra7"},
    {cell = 9895370, x = -74.8, z = -20.0, y = 13.0, heading = 86,  droidType = "ra7"},
    {cell = 9895379, x = 16.7,  z = -12.0, y = 15.2, heading = 85,  droidType = "3po"},
    {cell = 9895384, x = -22.5, z = -20.0, y = 124,  heading = 177, droidType = "ra7"},
    {cell = 9895387, x = -9.2,  z = -20.0, y = 63.9, heading = 34,  droidType = "ra7"},
    {cell = 9895377, x = 19.5,  z = -20.0, y = 115.9,heading = 175, droidType = "21b"},
    {cell = 9895377, x = 40.9,  z = -20.0, y = 126.6,heading = -42,droidType = "21b"},
    {cell = 9895372, x = -53.1, z = -20.0, y = 88.5, heading = -142,droidType = "3po"},
  },

  -- Particle templates
  P_BLUE = "object/static/particle/pt_survey_liquid_sample.iff",
  P_GRAY = "object/static/particle/pt_miasma_of_fog_gray.iff",

  -- GAS SPAWNS (coords are x, z, y; z = vertical)
  gasSpawns = {
    { cell=9895365, x= 3.6,  z=-12.0, y=22.7, template="P_BLUE" },
    { cell=9895366, x=-18.8, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x=35.4,  z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x=35.4,  z=-12.0, y=86.8, template="P_BLUE" },
    { cell=9895387, x=-2.7,  z=-20.0, y=71.1, template="P_GRAY" },
    { cell=9895384, x=-22.5, z=-20.0, y=105.2,template="P_BLUE" },
    { cell=9895383, x=-30.1, z=-20.0, y=47.5, template="P_GRAY" },
    { cell=9895381, x=-16.6, z=-20.0, y= 3.1, template="P_BLUE" },
    { cell=9895369, x=-63.8, z=-20.0, y=47.0, template="P_BLUE" },
    { cell=9895372, x=-74.7, z=-20.0, y=80.9, template="P_BLUE" },
    { cell=9895370, x=-67.7, z=-20.0, y=13.1, template="P_BLUE" },
    { cell=9895366, x= 3.7,  z=-12.0, y=63.1, template="P_BLUE" },
    { cell=9895375, x=60.7,  z=-12.0, y=82.8, template="P_BLUE" },
    { cell=9895375, x=60.7,  z=-12.0, y=58.7, template="P_BLUE" },
  },

  -- ============================
  -- Lab door locking (Geo-style)
  -- ============================

  -- Lab cell that should be locked behind a passkey
  labCell = 9895377,

  -- Active area on the hallway side of the lab door (between 9895374 and 9895377)
  -- NOTE: x/z/y here are LOCAL TO CELL 9895374 — adjust to match your door.
  labDoorArea = {
    cell   = 9895374,
    x      = 35.4,   -- tweak to your actual door X
    z      = -12.0,  -- tweak to your actual door Z
    y      = 90.0,   -- tweak to your actual door Y
    radius = 4.0,
  },

  -- Permission group name used to allow WALKIN into the lab cell
  labPermissionGroup = "BSV_LAB_ACCESS",

  -- Template for the lab passkey item that drops from your droid (100% drop)
  -- Create this .iff and update the path if needed.
  labKeyTemplate = "object/tangible/mission/quest_item/bsv_lab_passkey_s01.iff",

  -- Template for the medical droid in the lab
  medDroidTemplate = "surgical_droid_21b",
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

-- Resolve shorthand particle keys
local function resolveTemplate(self, keyOrPath)
  if keyOrPath == "P_BLUE" then return self.P_BLUE end
  if keyOrPath == "P_GRAY" then return self.P_GRAY end
  return keyOrPath
end

-- Per-player flags
local function oid(p)          return tostring(SceneObject(p):getObjectID()) end
local function keyInfected(p)  return oid(p) .. ":bsv:infected" end
local function keyImmune(p)    return oid(p) .. ":bsv:immune" end
-- per-character auth cache for bunker entry
local function keyAuthed(p)    return oid(p) .. ":bsv:authed" end
-- infection heartbeat flag
local function keyHeartbeat(p) return oid(p) .. ":bsv:hb" end

-- global key for lab medical droid OID
local MED_DROID_KEY = "bsv:med_droid_oid"

--==================================================
-- Startup
--==================================================
function BlueShadowVirusBunkerScreenPlay:start()
  if not isZoneEnabled(self.planet) then return end

  -- Gas
  for _, g in ipairs(self.gasSpawns) do
    spawnSceneObject(self.planet, resolveTemplate(self, g.template), g.x, g.z, g.y, g.cell, g.heading or 0)
  end

  -- Infection/Cure areas + auth gate + exit clear area
  self:setupInfectionArea()
  self:setupCureArea()
  self:setupAuthorizationGate()
  self:setupExitClearArea()

  -- Lab door lock (Geo-like permission group)
  self:setupLabPermissionGroup()
  self:setupLabDoorArea()

  -- Gate Officer + Medical Droid + Combat Droids + Quiz Droids
  self:spawnMobiles()
end

--==================================================
-- Authorization Gate (Warren-ish) + auth cache
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

  -- If this player has already been authorized on this character,
  -- don't re-run the gate logic (helps avoid rubberband spam).
  local authKey = keyAuthed(pPlayer)
  if readData(authKey) == 1 then
    return 0
  end

  -- Admin bypass for AUTH ONLY
  local pGhost = CreatureObject(pPlayer):getPlayerObject()
  local isAdmin = (pGhost ~= nil and PlayerObject(pGhost):isPrivileged())

  local hasClearance = false
  local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
  if pInventory ~= nil then
    local pKey = getContainerObjectByTemplate(pInventory, self.clearanceTemplate, true)
    hasClearance = (pKey ~= nil)
  end

  if isAdmin or hasClearance then
    -- Mark this character as authorized so we don't re-check on exits / bouncing
    writeData(authKey, 1)
    CreatureObject(pPlayer):sendSystemMessage("Authorization accepted. Welcome to the Blue Shadow Virus Facility.")
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
  SceneObject(pMarker):destroyObjectFromWorld()
  SceneObject(pMarker):destroyObjectFromDatabase()
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

  -- Apply POISONED for ticking damage (Geo Lab style)
  CreatureObject(pMoving):addDotState(
    pMoving,
    POISONED,
    cfg.poison_strength,
    cfg.poison_pool,
    cfg.poison_duration,
    cfg.poison_potency,
    src,
    cfg.poison_defense
  )

  -- Apply DISEASED for the infection state/icon
  CreatureObject(pMoving):addDotState(
    pMoving,
    DISEASED,
    cfg.disease_strength,
    cfg.disease_pool,
    cfg.disease_duration,
    cfg.disease_potency,
    src,
    cfg.disease_defense
  )

  writeData(keyInfected(pMoving), 1)
  CreatureObject(pMoving):sendSystemMessage("\\#FF5555You have been infected with the Blue Shadow Virus! Seek the cure in the medical lab.")

  -- Start heartbeat enforcing that normal cures don’t permanently remove it
  self:startInfectionHeartbeat(pMoving)

  return 0
end

--==================================================
-- Infection heartbeat — re-applies states if cured by normal means
--==================================================
function BlueShadowVirusBunkerScreenPlay:startInfectionHeartbeat(pPlayer)
  if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then return end

  -- Avoid double-scheduling for the same player
  if readData(keyHeartbeat(pPlayer)) == 1 then
    return
  end

  writeData(keyHeartbeat(pPlayer), 1)
  -- 5 seconds is a nice balance; tweak as desired
  createEvent(5 * 1000, "BlueShadowVirusBunkerScreenPlay", "infectionHeartbeat", pPlayer, "")
end

function BlueShadowVirusBunkerScreenPlay:infectionHeartbeat(pPlayer, args)
  if pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then
    return 0
  end

  -- If they are no longer infected or have become immune, stop enforcing.
  if readData(keyInfected(pPlayer)) ~= 1 or readData(keyImmune(pPlayer)) == 1 then
    deleteData(keyHeartbeat(pPlayer))
    return 0
  end

  local cfg = self.infection

  -- If DISEASED/POISONED were cleared by normal means, reapply them.
  if CreatureObject(pPlayer):hasState(DISEASED) ~= 1 then
    CreatureObject(pPlayer):addDotState(
      pPlayer,
      DISEASED,
      cfg.disease_strength,
      cfg.disease_pool,
      cfg.disease_duration,
      cfg.disease_potency,
      SceneObject(pPlayer):getObjectID(),
      cfg.disease_defense
    )
  end

  if CreatureObject(pPlayer):hasState(POISONED) ~= 1 then
    CreatureObject(pPlayer):addDotState(
      pPlayer,
      POISONED,
      cfg.poison_strength,
      cfg.poison_pool,
      cfg.poison_duration,
      cfg.poison_potency,
      SceneObject(pPlayer):getObjectID(),
      cfg.poison_defense
    )
  end

  -- Reschedule as long as they’re marked infected
  createEvent(5 * 1000, "BlueShadowVirusBunkerScreenPlay", "infectionHeartbeat", pPlayer, "")

  return 0
end

--==================================================
-- Cure (clear BOTH states; grant immunity flag, stop heartbeat)
--==================================================
function BlueShadowVirusBunkerScreenPlay:onEnterCureArea(pArea, pMoving)
  if pArea == nil or pMoving == nil or not SceneObject(pMoving):isPlayerCreature() then return 0 end

  if readData(keyInfected(pMoving)) ~= 1
    and CreatureObject(pMoving):hasState(DISEASED) ~= 1
    and CreatureObject(pMoving):hasState(POISONED) ~= 1 then
    return 0
  end

  CreatureObject(pMoving):clearState(DISEASED)
  CreatureObject(pMoving):clearState(POISONED)
  deleteData(keyInfected(pMoving))
  writeData(keyImmune(pMoving), 1)
  deleteData(keyHeartbeat(pMoving)) -- stop the infection heartbeat

  CreatureObject(pMoving):sendSystemMessage("\\#55FF55You have been cured of the Blue Shadow Virus.")

  -- Have the medical droid announce the cure in a chat bubble
  local medID = readData(MED_DROID_KEY)
  if medID ~= nil then
    local pMed = getSceneObject(medID)
    if pMed ~= nil then
      spatialChat(pMed, "Patient stabilized. Blue Shadow Virus neutralized. You are no longer contagious.")
    end
  end

  return 0
end

--==================================================
-- Exit clear area (worldspace) — clears infection/immune when safely outside
--==================================================
function BlueShadowVirusBunkerScreenPlay:setupExitClearArea()
  local e = self.exitClearArea
  if not e then return end
  local pArea = spawnActiveArea(self.planet, "object/active_area.iff", e.x, e.z, e.y, e.radius or 10.0, 0)
  if pArea ~= nil then
    createObserver(ENTEREDAREA, "BlueShadowVirusBunkerScreenPlay", "onEnterExitClearArea", pArea)
    print("BSV: Exit clear area armed (world)")
  else
    printLuaError("BSV: Failed to spawn exit clear active area.")
  end
end

function BlueShadowVirusBunkerScreenPlay:onEnterExitClearArea(pArea, pMoving)
  if pArea == nil or pMoving == nil or not SceneObject(pMoving):isPlayerCreature() then
    return 0
  end

  -- 1) Clear infection-related flags (what you already had)
  deleteData(keyInfected(pMoving))
  deleteData(keyImmune(pMoving))
  deleteData(keyHeartbeat(pMoving)) -- ensure heartbeat stops

  -- 2) Clear bunker auth cache so the gate behaves like "fresh" again
  --    (they still need the physical key item, just like now)
  deleteData(keyAuthed(pMoving))

  -- 3) Remove lab access permission group so the lab door relocks
  local pGhost = CreatureObject(pMoving):getPlayerObject()
  if pGhost ~= nil and PlayerObject(pGhost):hasPermissionGroup(self.labPermissionGroup) then
    PlayerObject(pGhost):removePermissionGroup(self.labPermissionGroup, true)
  end

  -- 4) Optional flavor message, mirroring DWB/Geo "systems reset"
  --    (You can swap this to an STF entry later.)
  CreatureObject(pMoving):sendSystemMessage(
    "Security and containment systems in the Blue Shadow Virus Facility have been cycled and reset."
  )

  return 0
end

--==================================================
-- Lab door permission groups (Geo-style) + door AA
--==================================================
function BlueShadowVirusBunkerScreenPlay:setupLabPermissionGroup()
  local labCellId = self.labCell
  if not labCellId or labCellId == 0 then return end

  local pCell = getSceneObject(labCellId)
  if pCell == nil then
    printLuaError("BSV: Failed to find lab cell " .. tostring(labCellId) .. " for permission group.")
    return
  end

  -- Lock this cell so only the labPermissionGroup can WALKIN
  SceneObject(pCell):setContainerInheritPermissionsFromParent(false)
  SceneObject(pCell):clearContainerDefaultDenyPermission(WALKIN)
  SceneObject(pCell):clearContainerDefaultAllowPermission(WALKIN)
  SceneObject(pCell):setContainerAllowPermission(self.labPermissionGroup, WALKIN)
  SceneObject(pCell):setContainerDenyPermission(self.labPermissionGroup, MOVEIN)
end

function BlueShadowVirusBunkerScreenPlay:giveLabAccess(pPlayer)
  if pPlayer == nil then return end
  local pGhost = CreatureObject(pPlayer):getPlayerObject()
  if pGhost == nil then return end

  if not PlayerObject(pGhost):hasPermissionGroup(self.labPermissionGroup) then
    PlayerObject(pGhost):addPermissionGroup(self.labPermissionGroup, true)
  end
end

function BlueShadowVirusBunkerScreenPlay:hasLabAccess(pPlayer)
  local pGhost = CreatureObject(pPlayer):getPlayerObject()
  if pGhost == nil then
    return false
  end
  return PlayerObject(pGhost):hasPermissionGroup(self.labPermissionGroup)
end

function BlueShadowVirusBunkerScreenPlay:setupLabDoorArea()
  local a = self.labDoorArea
  if not a then return end

  -- NEW: use local cell coords -> world coords helper
  local pArea = spawnAreaFromLocalCoords(
    self.planet,
    a.cell,
    a.x,
    a.z,
    a.y,
    a.radius or 4.0
  )

  if pArea ~= nil then
    createObserver(ENTEREDAREA, "BlueShadowVirusBunkerScreenPlay", "onEnterLabDoorArea", pArea)
    print("BSV: Lab door active area armed (cell " .. tostring(a.cell) .. ").")
  else
    printLuaError("BSV: Failed to spawn lab door active area.")
  end
end

function BlueShadowVirusBunkerScreenPlay:onEnterLabDoorArea(pArea, pMoving)
  if pArea == nil or pMoving == nil or not SceneObject(pMoving):isPlayerCreature() then
    return 0
  end

  -- If they already have permission, nothing to do.
  if self:hasLabAccess(pMoving) then
    return 0
  end

  -- Check for the lab passkey in inventory
  local hasKey = false
  local pKey = nil
  local pInventory = CreatureObject(pMoving):getSlottedObject("inventory")
  if pInventory ~= nil then
    pKey = getContainerObjectByTemplate(pInventory, self.labKeyTemplate, true)
    hasKey = (pKey ~= nil)
  end

  if hasKey then
    -- Grant permanent lab access (permission group), Geo-style
    self:giveLabAccess(pMoving)

    -- Consume the lab passkey item (one-time use)
    if pKey ~= nil then
      SceneObject(pKey):destroyObjectFromWorld()
      SceneObject(pKey):destroyObjectFromDatabase()
    end

    CreatureObject(pMoving):sendSystemMessage("Your lab passkey unlocks the medical lab door. The passkey has been destroyed in the process.")
  else
    CreatureObject(pMoving):sendSystemMessage("The medical lab door is sealed. You need a lab passkey to enter.")
  end

  return 0
end

--==================================================
-- FRS XP on bunker droid kills (Jedi Knights only, +50 FRS XP)
--==================================================
function BlueShadowVirusBunkerScreenPlay:onCaveMobDied(pVictim, pKiller)
  if pVictim == nil or pKiller == nil then
    return 0
  end

  -- Resolve actual player (handles pet/vehicle killers too)
  local pPlayer = nil

  if SceneObject(pKiller):isPlayerCreature() then
    pPlayer = pKiller
  else
    local ko = CreatureObject(pKiller)
    if ko and ko.getOwner then
      local pOwner = ko:getOwner()
      if pOwner ~= nil and SceneObject(pOwner):isPlayerCreature() then
        pPlayer = pOwner
      end
    end
  end

  if pPlayer == nil then
    return 0
  end

  local RANGE_METERS = 80
  local victimSO = SceneObject(pVictim)

  local function grantIfEligible(pTarget)
    if pTarget == nil or not SceneObject(pTarget):isPlayerCreature() then
      return
    end

    -- Must be within range of the mob that died
    if victimSO and not SceneObject(pTarget):isInRangeWithObject(pVictim, RANGE_METERS) then
      return
    end

    local c = CreatureObject(pTarget)
    if c and c.hasSkill and c:hasSkill("force_title_jedi_rank_03") then
      -- Easier mobs than Force Crystal / Nightsister caves, so only +50
      c:awardExperience("force_rank_xp", 50, true)
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
    grantIfEligible(pPlayer)
  end

  return 0
end

--==================================================
-- Mobiles (Gate Officer + Medical Droid + COMBAT DROIDS + Quiz Droids)
--==================================================
function BlueShadowVirusBunkerScreenPlay:spawnMobiles()
  -- Gate officer outside bunker
  local pNpc = spawnMobile(self.planet, "bsv_gate_officer", 0, -3614, 30, 764, 90, 0)
  if pNpc == nil then
    printLuaError("BSV: failed to spawn gate officer at (-3614,30,764).")
  end

  -- Medical droid inside the lab (coords are local to lab cell 9895377)
  local pMed = spawnMobile(self.planet, self.medDroidTemplate, 0, 33.0, -20.0, 145.0, 180, 9895377)
  if pMed ~= nil then
    writeData(MED_DROID_KEY, SceneObject(pMed):getObjectID())
  else
    printLuaError("BSV: failed to spawn medical droid in lab (cell 9895377).")
  end

  -- Lab key guard droid: random spawn from multiple possible locations
  -- Format: { cellId, x, z, y, heading, respawnSeconds }
  local labKeySpawns = {
    -- EXAMPLES – replace/expand with the real spots you want:
    { 9895372,   -62.7,  -20.0,  87.6,  180, 1800 },
    { 9895370, -62.4,  -20.0,  7.5,  0, 1800 },
    { 9895379, -39.1,  -12.0,  -4.7, -36, 1800 },
    { 9895384, -37.4,  -20.0,  123.7, 131, 1800 },
  }

  if #labKeySpawns > 0 then
    local idx = getRandomNumber(#labKeySpawns - 1) + 1
    local s   = labKeySpawns[idx]

    local tpl     = "bsv_lab_guard_droid"
    local cell    = s[1]
    local x       = s[2]
    local z       = s[3]
    local y       = s[4]
    local heading = s[5] or 0
    local respawn = s[6] or 1800

    local pKeyMob = spawnMobile(self.planet, tpl, respawn, x, z, y, heading, cell)
    if pKeyMob ~= nil then
      -- Also grant FRS XP from this guy using the same handler as other bunker mobs
      createObserver(
        OBJECTDESTRUCTION,
        "BlueShadowVirusBunkerScreenPlay",
        "onCaveMobDied",
        pKeyMob
      )
    else
      printLuaError("BSV: failed to spawn lab guard droid at random location index " .. idx .. ".")
    end
  end

  ------------------------------------------------------------------
  -- COMBAT DROIDS (FRS XP enabled) — ONE-LINE CLEAN FORMAT
  --
  -- Format for each entry:
  -- { "templateName", cellId, x, z, y, heading, respawnSeconds }
  --
  -- Example:
  -- { "bsv_battle_droid", 9895366, 5.0, -12.0, 45.0, 0, 1800 },
  --
  ------------------------------------------------------------------
  local combatSpawns = {
    -- Add your spawns here on ONE LINE each, ex:
    { "bsv_battle_droid",       9895363,  -4.0,  0.3,  3.3,  84,   1800 },
    { "bsv_battle_droid",       9895363,  -3.7,  0.3,  -4.0,  0,   1800 },
    { "bsv_battle_droid",       9895364,  3.7,  0.3,  -4.2,  -90,   1800 },
    { "bsv_super_battle_droid", 9895366, 3.4, -12.0,  33.1, -180, 1800 },
    { "bsv_battle_droid",       9895366,  1.8,  -12.0,  33.8,  -180,   1800 },
    { "bsv_battle_droid",       9895366,  5.2,  -12.0,  33.8,  -180,   1800 },
    { "bsv_battle_droid",       9895366,  3.6,  -12.0,  65.6,  180,   1800 },
    { "bsv_battle_droid",       9895366,  2.1,  -12.0,  64.9,  137,   1800 },
    { "bsv_battle_droid",       9895366,  5.0,  -12.0,  64.9,  -134,   1800 },
    { "bsv_battle_droid",       9895366,  19.5,  -12.0,  51.2,  180,   1800 },
    { "bsv_battle_droid",       9895366,  23.4,  -12.0,  42.0,  -90,   1800 },
    { "bsv_super_battle_droid", 9895366, 25.3, -12.0,  47.1, -90, 1800 },
    { "bsv_battle_droid",       9895366,  -12.5,  -12.0,  51.3,  -180,   1800 },
    { "bsv_battle_droid",       9895366,  -18.5,  -12.0,  40.8,  45,   1800 },
    { "bsv_super_battle_droid", 9895366, -19.3, -12.0,  46.8, 90, 1800 },
    { "bsv_battle_droid",       9895368,  -42.5,  -20.0,  46.9,  90,   1800 },
    { "bsv_droideka",           9895370, -50.6, -20.0,  9.3,   -65, 1800 },
    { "bsv_droideka",           9895370, -50.6, -20.0,  17.0,   -135, 1800 },
    { "bsv_battle_droid",       9895370,  -56.6,  -20.0,  12.9,  -90,   1800 },
    { "bsv_battle_droid",       9895370,  -74.3,  -20.0,  8.9,  55,   1800 },
    { "bsv_battle_droid",       9895370,  -74.3,  -20.0,  16.5,  120,   1800 },
    { "bsv_super_battle_droid", 9895370, -64.4, -20.0,  12.9, 90, 1800 },
    { "bsv_droideka",           9895372, -49.5, -20.0,  84.5,   -120, 1800 },
    { "bsv_droideka",           9895372, -49.5, -20.0,  77.6,   -60, 1800 },
    { "bsv_battle_droid",       9895372,  -71.3,  -20.0,  82.4,  90,   1800 },
    { "bsv_battle_droid",       9895372,  -71.3,  -20.0,  80.9,  90,   1800 },
    { "bsv_battle_droid",       9895372,  -71.3,  -20.0,  79.4,  90,   1800 },
    { "bsv_super_battle_droid", 9895369, -61.8, -12.0,  47.1, 90, 1800 },
    { "bsv_battle_droid",       9895369,  -59.6,  -20.0,  44.8,  90,   1800 },
    { "bsv_battle_droid",       9895369,  -59.6,  -20.0,  49.0,  90,   1800 },
    { "bsv_super_battle_droid", 9895369, -73.3, -12.0,  30.5, 45, 1800 },
    { "bsv_battle_droid",       9895369,  -73.6,  -20.0,  28.2,  45,   1800 },
    { "bsv_battle_droid",       9895369,  -75.8,  -20.0,  31.4,  45,   1800 },
    { "bsv_super_battle_droid", 9895369, -58.9, -12.0,  64.6, -140, 1800 },
    { "bsv_battle_droid",       9895369,  -59.4,  -20.0,  66.5,  -140,   1800 },
    { "bsv_battle_droid",       9895369,  -57.0,  -20.0,  64.2,  -140,   1800 },
    { "bsv_droideka",           9895374, 35.5, -12.0,  83.4,   180, 1800 },
    { "bsv_battle_droid",       9895375,  45.2,  -12.0,  76.3,  0,   1800 },
    { "bsv_battle_droid",       9895375,  45.2,  -12.0,  89.0,  180,   1800 },
    { "bsv_super_battle_droid", 9895375, 72.7, -12.0,  82.9, 90, 1800 },
    { "bsv_battle_droid",       9895376,  45.2,  -12.0,  52.6,  0,   1800 },
    { "bsv_battle_droid",       9895376,  45.2,  -12.0,  65.0,  180,   1800 },
    { "bsv_super_battle_droid", 9895376, 72.7, -12.0,  58.6, 90, 1800 },
    { "bsv_battle_droid",       9895374,  35.5,  -12.0,  47.0,  -90,   1800 },
    { "bsv_battle_droid",       9895374,  35.5,  -12.0,  35.3,  0,   1800 },
    { "bsv_super_battle_droid", 9895379, 23.5, -12.0,  15.2, 0, 1800 },
    { "bsv_battle_droid",       9895379,  25.3,  -12.0,  12.9,  0,   1800 },
    { "bsv_battle_droid",       9895379,  21.4,  -12.0,  12.9,  0,   1800 },
    { "bsv_droideka",           9895379, 60.6, -12.0,  21.1,   -90, 1800 },
    { "bsv_droideka",           9895379, 60.6, -12.0,  11.3,   -90, 1800 },
    { "bsv_droideka",           9895379, 60.6, -12.0,  1.2,   -90, 1800 },
    { "bsv_battle_droid",       9895380,  -6.9,  -20.0,  2.9, 90,   1800 },
    { "bsv_battle_droid",       9895381,  -21.2,  -20.0,  8.4, 90,   1800 },
    { "bsv_battle_droid",       9895381,  -11.8,  -20.0,  8.4, -90,   1800 },
    { "bsv_battle_droid",       9895381,  -11.8,  -20.0,  -2.4, -90,   1800 },
    { "bsv_battle_droid",       9895381,  -21.2,  -20.0,  -2.4, 90,   1800 },
    { "bsv_super_battle_droid", 9895383, -30.6, -20.0,  33.1, 180, 1800 },
    { "bsv_super_battle_droid", 9895383, -30.6, -20.0,  73.0, 0, 1800 },
    { "bsv_droideka",           9895384, -27.6, -20.0,  115.7,   180, 1800 },
    { "bsv_droideka",           9895384, -17.6, -20.0,  115.7,   180, 1800 },
    { "bsv_battle_droid",       9895384,  -8.1,  -20.0,  102.7, -145,   1800 },
    { "bsv_battle_droid",       9895384,  -37.4,  -20.0,  102.7, 115,   1800 },
    { "bsv_battle_droid",       9895386,  -14.7,  -20.0,  85.0, 90,   1800 },
    { "bsv_battle_droid",       9895386,  -2.5,  -20.0,  85.0, -90,   1800 },
    { "bsv_super_battle_droid", 9895387, -8.2, -20.0,  76.2, 130, 1800 },
    { "bsv_super_battle_droid", 9895387, -7.5, -20.0,  65.9, 35, 1800 },
    { "bsv_super_battle_droid", 9895377, 41.2, -20.0,  140.0, -145, 1800 },
    { "bsv_super_battle_droid", 9895377, 23.0, -20.0,  144.6, 90, 1800 },
    { "bsv_super_battle_droid", 9895377, 23.0, -20.0,  131.3, 90, 1800 },
    { "bsv_super_battle_droid", 9895377, 23.0, -20.0,  118.1, 90, 1800 },
  }

  for i, data in ipairs(combatSpawns) do
    local tpl, cell, x, z, y, hdg, respawn = data[1], data[2], data[3], data[4], data[5], data[6], data[7] or 1800

    if tpl and cell and x and z and y then
      local pMob = spawnMobile(self.planet, tpl, respawn, x, z, y, hdg or 0, cell)
      if pMob ~= nil then
        createObserver(OBJECTDESTRUCTION, "BlueShadowVirusBunkerScreenPlay", "onCaveMobDied", pMob)
      else
        printLuaError("BSV: failed to spawn combat droid '" .. tostring(tpl) .. "' at index " .. i)
      end
    else
      printLuaError("BSV: invalid combatSpawns entry at index " .. i)
    end
  end


  ------------------------------------------------------------------
  -- QUIZ DROIDS
  -- Randomly choose ONE spawn index to be the real quiz droid.
  -- The rest are dummy droids of the appropriate type for that room.
  ------------------------------------------------------------------
  if self.quizDroidSpawns ~= nil and #self.quizDroidSpawns > 0 then
    local quizIndex = getRandomNumber(1, #self.quizDroidSpawns)
    printLuaError("BSV: quiz droid index " .. quizIndex .. " of " .. #self.quizDroidSpawns .. " chosen for conversation.")

    for i, data in ipairs(self.quizDroidSpawns) do
      local cell    = data.cell
      local x       = data.x
      local z       = data.z
      local y       = data.y
      local heading = data.heading
      local dtype   = data.droidType or "3po"  -- default if somebody forgets the field

      local typeInfo = self.quizDroidTypes[dtype]
      if typeInfo == nil then
        printLuaError("BSV: quiz droid spawn with unknown droidType '" .. tostring(dtype) .. "' at index " .. i .. ", skipping.")
      else
        local template
        if i == quizIndex then
          template = typeInfo.real
        else
          template = typeInfo.dummy
        end

        local pDroid = spawnMobile(self.planet, template, 0, x, z, y, heading, cell)
        if pDroid == nil then
          printLuaError("BSV: failed to spawn quiz droid '" .. template .. "' at index " .. i .. ".")
        end
      end
    end
  else
    printLuaError("BSV: quizDroidSpawns not configured; no quiz droids spawned.")
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
