--=====================================================================
-- Blue Shadow Virus Bunker
-- Location: Naboo (-3630, 31, 760)
-- Building: object/building/general/bunker_imperial_weapons_research_facility_01.iff
-- Facing: East (90 degrees)
-- Gating: player must have Blue Shadow Clearance item to enter
--=====================================================================

BlueShadowVirusBunkerScreenPlay = ScreenPlay:new {
    numberOfActs = 1,
    planet = "naboo",

    -- Keep a handle to the building for observers/cell ops
    pBunker = nil,

    headingDeg = 90,

    -- Use your own custom key item once you add it. For now we can reuse a quest passkey.
    clearanceTemplate = "object/tangible/mission/quest_item/warren_passkey_s01.iff"  -- TODO: swap to your own template later

    -- Option B if you prefer a flag instead of an item:
    -- clearanceFlag = "bsv:clearance" -- writeData/hasData on player
}

registerScreenPlay("BlueShadowVirusBunkerScreenPlay", true)

function BlueShadowVirusBunkerScreenPlay:start()
    if not isZoneEnabled(self.planet) then return end
    self:spawnSceneObjects()
    self:spawnMobiles()
    self:attachBuildingObservers()
end

--========================
-- Building / SceneObjects
--========================
function BlueShadowVirusBunkerScreenPlay:spawnSceneObjects()
    local x, z, y = -3630, 31, 760
    self.pBunker = spawnSceneObject(
        self.planet,
        "object/building/general/bunker_imperial_weapons_research_facility_01.iff",
        x, z, y, 0, math.rad(self.headingDeg)
    )
end

function BlueShadowVirusBunkerScreenPlay:spawnMobiles()
    -- Spawn your gate NPC outside the entrance (example placement)
    -- NOTE: Adjust coords after you stand there and /loc
    -- spawnMobile("naboo", "bsv_gate_officer", 0, -3622, 31, 760, 90, 0)
    spawnMobile("naboo", "bsv_gate_officer", 0, -3614, 30, 764, 90, 0)
end

--========================
-- Entry Gate (Warren-style)
--========================
function BlueShadowVirusBunkerScreenPlay:attachBuildingObservers()
    if self.pBunker == nil then return end
    createObserver(ENTEREDBUILDING, "BlueShadowVirusBunkerScreenPlay", "onEnteredBunker", self.pBunker)
    createObserver(EXITEDBUILDING,  "BlueShadowVirusBunkerScreenPlay", "onExitedBunker",  self.pBunker)
end

function BlueShadowVirusBunkerScreenPlay:onEnteredBunker(pBuilding, pPlayer)
    if pBuilding == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then
        return 0
    end

    -- GM bypass
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if pGhost ~= nil and PlayerObject(pGhost):isPrivileged() then
        return 0
    end

    -- Item gate (same as Warren)
    local pInv = CreatureObject(pPlayer):getSlottedObject("inventory")
    local hasClearance = (pInv ~= nil) and (getContainerObjectByTemplate(pInv, self.clearanceTemplate, true) ~= nil)

    -- Alt: flag gate
    -- local hasClearance = (readData(SceneObject(pPlayer):getObjectID() .. ":" .. (self.clearanceFlag or "")) == 1)

    if not hasClearance then
        CreatureObject(pPlayer):sendSystemMessage("ACCESS DENIED: You lack the required Blue Shadow clearance.")
        -- Kick them just outside the front (east-facing => +X direction)
        local wx = -3630 + 12
        local wz = 31
        local wy = 760
        SceneObject(pPlayer):teleport(wx, wz, wy, 0)
        return 0
    end

    -- (Optional) set up additional observers like Warren does, e.g. PARENTCHANGED
    return 0
end

function BlueShadowVirusBunkerScreenPlay:onExitedBunker(pBuilding, pPlayer)
    return 0
end
