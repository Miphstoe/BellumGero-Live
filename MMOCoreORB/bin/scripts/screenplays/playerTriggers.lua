PlayerTriggers = { }

function PlayerTriggers:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    -- PLAYERKILLED is the only entry point for the player-placed bounty UI.
    -- Register it before unrelated login hooks so an error in another
    -- screenplay cannot leave this player without the death observer for the
    -- rest of the session.
    if PlayerBountySystem and PlayerBountySystem.onPlayerLoggedIn then
        PlayerBountySystem:onPlayerLoggedIn(pPlayer)
    end
    -- Bellum Gero: retroactively teach the RIS full-suit schematic to quest completers.
    self:awardCompletedRISFullSuit(pPlayer)
    ServerEventAutomation:playerLoggedIn(pPlayer)
    BestineElection:playerLoggedIn(pPlayer)
    if MandoWayOfLife and MandoWayOfLife.onPlayerLoggedIn then
        MandoWayOfLife:onPlayerLoggedIn(pPlayer)
    end

    local co = CreatureObject(pPlayer)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    end
    if GCWRankedAmbushRebels and GCWRankedAmbushRebels.onPlayerLoggedIn then
        GCWRankedAmbushRebels:onPlayerLoggedIn(pPlayer)
    end
    if GCWRankedAmbushImperials and GCWRankedAmbushImperials.onPlayerLoggedIn then
        GCWRankedAmbushImperials:onPlayerLoggedIn(pPlayer)
    end
    if GalaxyCombatBoard and GalaxyCombatBoard.onPlayerLoggedIn then
        GalaxyCombatBoard:onPlayerLoggedIn(pPlayer)
    end
    if GeonosianCaveAntiCampingHybrid and GeonosianCaveAntiCampingHybrid.onPlayerLoggedIn then
        GeonosianCaveAntiCampingHybrid:onPlayerLoggedIn(pPlayer)
    end
    if AcklayPrivateInstance and AcklayPrivateInstance.handlePlayerLogin then
        AcklayPrivateInstance:handlePlayerLogin(pPlayer)
    end
    if DroidFoundry and DroidFoundry.handlePlayerLogin then
        DroidFoundry:handlePlayerLogin(pPlayer)
    end
end

function PlayerTriggers:awardCompletedRISFullSuit(pPlayer)
    local creature = CreatureObject(pPlayer)
    if creature == nil or not creature:hasScreenPlayState(64, "ris_armor_quest") then
        return
    end

    local ghostPointer = creature:getPlayerObject()
    if ghostPointer == nil then
        return
    end

    local ghost = PlayerObject(ghostPointer)
    local path = "object/draft_schematic/clothing/clothing_armor_ris_suit.iff"
    if not ghost:hasSchematic(path) then
        -- Same permanent QUEST reward parameters used by the existing RIS quest.
        ghost:addRewardedSchematic(path, 2, -1, true)
    end
end

function PlayerTriggers:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then return end
    ServerEventAutomation:playerLoggedOut(pPlayer)

    local co = CreatureObject(pPlayer)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    end
    if GeonosianCaveAntiCampingHybrid and GeonosianCaveAntiCampingHybrid.onPlayerLoggedOut then
        GeonosianCaveAntiCampingHybrid:onPlayerLoggedOut(pPlayer)
    end
    if AcklayPrivateInstance and AcklayPrivateInstance.onPlayerLoggedOut then
        AcklayPrivateInstance:onPlayerLoggedOut(pPlayer)
    end
    if DroidFoundry and DroidFoundry.onPlayerLoggedOut then
        DroidFoundry:onPlayerLoggedOut(pPlayer)
    end
    if PlayerBountySystem and PlayerBountySystem.onPlayerLoggedOut then
        PlayerBountySystem:onPlayerLoggedOut(pPlayer)
    end
end
