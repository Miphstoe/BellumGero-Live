-- Mandalorian Trialmaster Conversation Handler
-- Routes player to the correct screen based on progression state

MandoTrialmasterConvoHandler = conv_handler:new {}

function MandoTrialmasterConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local ch = MandoWayOfLife:getChapter(pPlayer)

	-- Chapter 4 complete — Clanbound
	if (MandoWayOfLife:readInt(pPlayer, "chapter4Complete") == 1) then
		return convoTemplate:getScreen("clanbound")
	end

	-- Arc complete + Novice BH: ready for chapter gate cycle
	if (MandoWayOfLife:isArcComplete(pPlayer)) then
		if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
			return convoTemplate:getScreen("arc_complete_no_bh")
		end
		return convoTemplate:getScreen("chapter_gate_ready")
	end

	-- Arc started but not complete: player is mid-arc
	if (MandoWayOfLife:readInt(pPlayer, "chapter0Started") == 1) then
		return convoTemplate:getScreen("arc_in_progress")
	end

	-- Prerequisites not met
	if (not MandoWayOfLife:meetsPrerequisites(pPlayer)) then
		return convoTemplate:getScreen("prereqs_missing")
	end

	-- Ready to start arc
	return convoTemplate:getScreen("arc_accept")
end

function MandoTrialmasterConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then return pConvScreen end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "arc_start") then
		MandoWayOfLife:startFoundlingArc(pPlayer)

	elseif (screenID == "chapter_gate_ready") then
		-- Direct player to the operative — no action needed here,
		-- gate is started at the operative conversation
	end

	return pConvScreen
end
