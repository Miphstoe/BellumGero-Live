-- Mandalorian Spynet Operative Conversation Handler
-- Routes based on chapter gate state for Chapters 1-4

MandoSpynetOperativeConvoHandler = conv_handler:new {}

function MandoSpynetOperativeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- Player who never started the Mandalorian arc: send them to the recruiter, not here.
	if (MandoWayOfLife:readInt(pPlayer, "chapter0Started") ~= 1 and not MandoWayOfLife:isArcComplete(pPlayer)) then
		return convoTemplate:getScreen("go_away")
	end

	-- Helmet check first
	if (not MandoWayOfLife:hasFoundlingHelmet(pPlayer)) then
		return convoTemplate:getScreen("no_helmet")
	end

	-- Arc must be complete
	if (not MandoWayOfLife:isArcComplete(pPlayer)) then
		return convoTemplate:getScreen("no_foundling")
	end

	-- Novice BH required
	if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
		return convoTemplate:getScreen("no_bh")
	end

	-- Chapter 4 complete — point to recruiter for Clanbound/FRS
	if (MandoWayOfLife:readInt(pPlayer, "chapter4Complete") == 1) then
		return convoTemplate:getScreen("clanbound")
	end

	-- Private contract currently active
	if (MandoWayOfLife:readInt(pPlayer, "privateContractActive") == 1) then
		return convoTemplate:getScreen("trial_active")
	end

	-- C++ may already show 5/5 before the 15s gateProgressEvent flips Lua flags; sync so dialogue matches.
	-- When this transitions 5/5 -> trial_ready, unlockPrivateTrialGateIfEligible already sends
	-- sendChapterGateProgressFooter; calling it again here duplicated the system line at convo open.
	local transitionedTrialGate = MandoWayOfLife:unlockPrivateTrialGateIfEligible(pPlayer)

	-- Gate A done (5 BH) — trial available
	if (MandoWayOfLife:readInt(pPlayer, "needsCustomContract") == 1) then
		if (not transitionedTrialGate) then
			MandoWayOfLife:sendChapterGateProgressFooter(pPlayer, 5)
		end
		return convoTemplate:getScreen("trial_ready")
	end

	-- Gate A in progress (counting > 0 but < 5)
	if (MandoWayOfLife:readInt(pPlayer, "countingEnabled") == 1) then
		MandoWayOfLife:sendChapterGateProgressFooter(pPlayer, nil)
		return convoTemplate:getScreen("gate_in_progress")
	end

	-- Not yet started this gate cycle — offer explanation
	MandoWayOfLife:sendChapterGateOperativeStatusIfRelevant(pPlayer)
	return convoTemplate:getScreen("gate_explain")
end

function MandoSpynetOperativeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then return pConvScreen end

	local screen   = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "gate_start") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Spynet operative convo: gate_start (BH terminal 0/5 cycle).")
		MandoWayOfLife:startChapterGate(pPlayer)
		MandoWayOfLife:startGateProgressPoll(pPlayer)

	elseif (screenID == "trial_start") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Spynet operative convo: trial_start (private contract).")
		local ok = MandoWayOfLife:beginPrivateContract(pPlayer)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Spynet operative convo: trial_start beginPrivateContract returned %s", tostring(ok)))
		if (not ok) then
			MandoWayOfLife:logDiagPlayer(pPlayer, "Spynet operative convo: trial_start aborted (preconditions failed).")
			-- beginPrivateContract already sent a system message; close the convo
			local convoTemplate = LuaConversationTemplate(pConvTemplate)
			return convoTemplate:getScreen("bye")
		end

	elseif (screenID == "trial_refresh_hint") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Spynet operative convo: trial_refresh_hint.")
		MandoWayOfLife:refreshSpynetTrialSupportFromOperative(pPlayer)
	end

	return pConvScreen
end
