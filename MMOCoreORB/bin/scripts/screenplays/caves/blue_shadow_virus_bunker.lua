--=====================================================================
-- Blue Shadow Virus Bunker (STATIC snapshot building version)
-- Bare-minimum: ONLY static props; no tangibles, no observers/events
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
    numberOfActs = 1,
    planet = "naboo",
    buildingID = 9895361, -- static building from snapshot

    -- Gas (static particle)
    GAS_TEMPLATE = "object/static/particle/pt_green_hanging_smoke.iff",
    GAS_CELL     = 9895365,
    GAS_POS      = { x = 3.6, z = -12.0, y = 22.7, heading = 0.0 },

    -- Three STATIC crate meshes (no scripts attached)
    crates = {
        { template = "object/static/structure/general/cargo_crate_s01.iff", cell = 9895372, pos = { x = -76.9, z = -20.0, y =  88.4, heading = 0.0 } },
        { template = "object/static/structure/general/cargo_crate_s02.iff", cell = 9895381, pos = { x = -16.5, z = -20.0, y =  -5.2, heading = 0.0 } },
        { template = "object/static/structure/general/cargo_crate_s03.iff", cell = 9895384, pos = { x = -38.7, z = -20.0, y = 117.1, heading = 0.0 } },
    },
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

function BlueShadowVirusBunkerScreenPlay:start()
    if not isZoneEnabled(self.planet) then return end
    if getSceneObject(self.buildingID) == nil then return end

    -- Gas
    local g = self.GAS_POS
    spawnSceneObject(self.planet, self.GAS_TEMPLATE, g.x, g.z, g.y, self.GAS_CELL, g.heading or 0)

    -- Static crates (no scripts)
    for _, c in ipairs(self.crates) do
        spawnSceneObject(self.planet, c.template, c.pos.x, c.pos.z, c.pos.y, c.cell, c.pos.heading or 0)
    end
end
