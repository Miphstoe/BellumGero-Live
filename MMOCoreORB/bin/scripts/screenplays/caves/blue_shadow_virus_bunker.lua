--=====================================================================
-- Blue Shadow Virus Bunker — Gas placement only (simple & safe)
-- Edit the gasSpawns list below to add/remove placements.
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
  numberOfActs = 1,
  planet = "naboo",

  -- Static bunker ID (not strictly required here; kept for reference)
  buildingID = 9895361,

  -- Particle templates you liked
  P_BLUE = "object/static/particle/pt_survey_liquid_sample.iff", -- shimmering/rainbow with blue
  P_GRAY = "object/static/particle/pt_miasma_of_fog_gray.iff",   -- toxic gray fog

  -- ---------------------------------------------------------------
  -- ADD / REMOVE GAS SPAWNS HERE
  -- Each entry: { cell=<cellId>, x=..., z=..., y=..., template=<P_BLUE|P_GRAY or full path>, heading=0 }
  -- NOTE: coords are (x, z, y) — z is Vertical in SWG scripts.
  -- ---------------------------------------------------------------
  gasSpawns = {
    -- Door/vent room (your original one):
    { cell=9895365, x= 3.6, z=-12.0, y=22.7, template="P_BLUE" },  -- main puff
    { cell=9895366, x= -18.8, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x= 35.4, z=-12.0, y=47.0, template="P_GRAY" },
    { cell=9895374, x= 35.4, z=-12.0, y=86.8, template="P_BLUE" },
    { cell=9895387, x= -2.7, z=-20.0, y=71.1, template="P_GRAY" },
    { cell=9895384, x= -22.5, z=-20.0, y=105.2, template="P_BLUE" },
    { cell=9895383, x= -30.1, z=-20.0, y=47.5, template="P_GRAY" },
    { cell=9895381, x= -16.6, z=-20.0, y=3.1, template="P_BLUE" },
    { cell=9895369, x= -63.8, z=-20.0, y=47.0, template="P_BLUE" },
    { cell=9895372, x= -74.7, z=-20.0, y=80.9, template="P_BLUE" },
    { cell=9895370, x= -67.7, z=-20.0, y=13.1, template="P_BLUE" },
    { cell=9895366, x= 3.7, z=-12.0, y=63.1, template="P_BLUE" },
    { cell=9895375, x= 60.7, z=-12.0, y=82.8, template="P_BLUE" },
    { cell=9895375, x= 60.7, z=-12.0, y=58.7, template="P_BLUE" },
  },
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

-- Internal: resolve "P_BLUE"/"P_GRAY" to actual paths so you can
-- write template="P_BLUE" instead of the full path every time.
local function resolveTemplate(self, keyOrPath)
  if keyOrPath == "P_BLUE" then return self.P_BLUE end
  if keyOrPath == "P_GRAY" then return self.P_GRAY end
  return keyOrPath -- treat as a full path if not a key
end

function BlueShadowVirusBunkerScreenPlay:start()
  if not isZoneEnabled(self.planet) then return end

  -- Spawn every gas entry exactly as listed
  for _, g in ipairs(self.gasSpawns) do
    local tmpl = resolveTemplate(self, g.template)
    spawnSceneObject(self.planet, tmpl, g.x, g.z, g.y, g.cell, g.heading or 0)
  end
end

-- -------------------------------------------------------------------
-- Optional: live preview helper (no restart needed).
-- Use in-game (privileged): /lua bsv_gas(cell, x, z, y, "P_GRAY")
-- Or: /lua bsv_gas(9895366, 0.3, -20, 19.8, "object/static/particle/pt_miasma_of_fog_gray.iff")
-- -------------------------------------------------------------------
function bsv_gas(cell, x, z, y, template)
  local sp = BlueShadowVirusBunkerScreenPlay
  if not isZoneEnabled(sp.planet) then return end
  spawnSceneObject(sp.planet, resolveTemplate(sp, template), x, z, y, cell, 0)
end
