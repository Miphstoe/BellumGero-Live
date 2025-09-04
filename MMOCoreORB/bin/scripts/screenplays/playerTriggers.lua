PlayerTriggers = { }

function PlayerTriggers:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    ServerEventAutomation:playerLoggedIn(pPlayer)
    BestineElection:playerLoggedIn(pPlayer)

    local co = CreatureObject(pPlayer)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    end
    if GCWRankedAmbush and GCWRankedAmbush.onPlayerLoggedIn then
        GCWRankedAmbush:onPlayerLoggedIn(pPlayer)
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