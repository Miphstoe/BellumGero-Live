PlayerTriggers = { }

function PlayerTriggers:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    ServerEventAutomation:playerLoggedIn(pPlayer)
    BestineElection:playerLoggedIn(pPlayer)

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
    -- Register player bounty system observer
    if PlayerBountySystem and PlayerBountySystem.onPlayerLoggedIn then
        PlayerBountySystem:onPlayerLoggedIn(pPlayer)
    end
    if GalaxyCombatBoard and GalaxyCombatBoard.onPlayerLoggedIn then
        GalaxyCombatBoard:onPlayerLoggedIn(pPlayer)
    end
end

function PlayerTriggers:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then return end
    ServerEventAutomation:playerLoggedOut(pPlayer)

    local co = CreatureObject(pPlayer)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    end
end
