--=====================================================================
-- Blue Shadow Virus Bunker — Gas + Authorization Gate + Gate Officer
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
  numberOfActs = 1,
  planet = "naboo",

  -- Static bunker building ID
  buildingID = 9895361,

  -- TEMP clearance item (swap when your BSV key .iff is ready)
  clearanceTemplate = "object/tangible/mission/quest_item/warren_passkey_s01.iff",

  -- Where to punt unauthorized players (worldcell = 0).  NOTE: (x, z, y, cell)
  outside = { x = -3601.7, z = 29.5, y = 761.2, cell = 0 },

  -- Particle templates
  P_BLUE = "object/static/particle/pt_survey_liquid_sample.iff",
  P_GRAY = "object/static/particle/pt_miasma_of_fog_gray.iff",

  -- GAS SPAWNS: (x, z, y, cell, heading) — z is vertical
  gasSpawns = {
    { cell=9895365, x= 3.6,  z=-12.0, y=22.7, template="P_BLUE" },
    { cell=9895366, x=-18.8, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x= 35.4, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x= 35.4, z=-12.0, y=86.8, template="P_BLUE" },
    { cell=9895387, x= -2.7, z=-20.0, y=71.1, template="P_GRAY" },
    { cell=9895384, x=-22.5, z=-20.0, y=105.2, template="P_BLUE" },
    { cell=9895383, x=-30.1, z=-20.0, y=47.5, template="P_GRAY" },
    { cell=9895381, x=-16.6, z=-20.0, y= 3.1, template="P_BLUE" },
    { cell=9895369, x=-63.8, z=-20.0, y=47.0, template="P_BLUE" },
    { cell=9895372, x=-74.7, z=-20.0, y=80.9, template="P_BLUE" },
    { cell=9895370, x=-67.7, z=-20.0, y=13.1, template="P_BLUE" },
    { cell=9895366, x= 3.7,  z=-12.0, y=63.1, template="P_BLUE" },
    { cell=9895375, x=60.7,  z=-12.0, y=82.8, template="P_BLUE" },
    { cell=9895376, x=60.7,  z=-12.0, y=58.7, template="P_BLUE" },
    { cell=9895379, x=37.2,  z=-12.0, y=11.2, template="P_BLUE" },
  },
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

-- Resolve short particle keys to full paths
local function resolveTemplate(self, keyOrPath)
  if keyOrPath == "P_BLUE" then return self.P_BLUE end
  if keyOrPath == "P_GRAY" then return self.P_GRAY end
  return keyOrPath
end

--==================================================
-- Startup
--==================================================
function BlueShadowVirusBunkerScreenPlay:start()
  if not isZoneEnabled(self.planet) then return end

  -- Gas
  for _, g in ipairs(self.gasSpawns) do
    local tmpl = resolveTemplate(self, g.template)
    spawnSceneObject(self.planet, tmpl, g.x, g.z, g.y, g.cell, g.heading or 0)
  end

  -- Auth gate
  self:setupAuthorizationGate()

  -- Gate Officer NPC (minimal: rely on mobile .lua to handle convo/flags)
  self:spawnMobiles()
end

--==================================================
-- Authorization Gate (Warren pattern)
--==================================================
function BlueShadowVirusBunkerScreenPlay:setupAuthorizationGate()
  if self.buildingID == nil or self.buildingID == 0 then
    printLuaError("BSV: buildingID not set; cannot arm authorization gate.")
    return
  end

  local pBunker = getSceneObject(self.buildingID)
  if pBunker == nil then
    printLuaError("BSV: could not resolve bunker building by ID " .. tostring(self.buildingID))
    return
  end

  createObserver(ENTEREDBUILDING, "BlueShadowVirusBunkerScreenPlay", "notifyEnteredBsv", pBunker)
end

function BlueShadowVirusBunkerScreenPlay:notifyEnteredBsv(pBuilding, pPlayer)
  if (pBuilding == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
    return 0
  end

  -- Admin bypass
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
-- Mobiles
--==================================================
function BlueShadowVirusBunkerScreenPlay:spawnMobiles()
  -- Gate officer outside — coords/heading from your update; worldcell 0
  local pNpc = spawnMobile(self.planet, "bsv_gate_officer", 0, -3614, 30, 764, 90, 0)
  if pNpc == nil then
    printLuaError("BSV: failed to spawn gate officer at (-3614,30,764).")
  end
end

-- -------------------------------------------------------------------
-- Live particle preview helper (optional)
-- /lua bsv_gas(cell, x, z, y, "P_GRAY")
-- -------------------------------------------------------------------
function bsv_gas(cell, x, z, y, template)
  local sp = BlueShadowVirusBunkerScreenPlay
  if not isZoneEnabled(sp.planet) then return end
  spawnSceneObject(sp.planet, resolveTemplate(sp, template), x, z, y, cell, 0)
end
