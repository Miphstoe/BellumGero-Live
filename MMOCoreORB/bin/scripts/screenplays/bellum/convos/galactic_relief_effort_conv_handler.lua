GalacticReliefEffortConvoHandler = conv_handler:new {}

function GalacticReliefEffortConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen("hub")
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	local state = GalacticReliefEffort:conversationState(pPlayer)
	local text = GalacticReliefEffort.COORDINATOR_INTRO

	if (state == "ineligible") then
		text = "This network is not a sightseeing charter. Only medics trained to use both /tendDamage and /tendWound may undertake a relief circuit."
	elseif (state == "reward_pending") then
		text = "Your relief circuit is complete. I have your compensation ready.\n\n" .. GalacticReliefEffort:buildProgressReportText(pPlayer) .. "\n\nSelect the assignment option and I will process your debrief and reward."

		if (GalacticReliefEffort:shouldGrantBonusReward(pPlayer)) then
			text = text .. "\n\nYour one-time doctor buff droid deed is also ready for issue."
		end
	elseif (state == "in_progress") then
		text = "Your relief circuit remains active.\n\n" .. GalacticReliefEffort:buildProgressReportText(pPlayer) .. "\n\nIf you lost the route, ask for a progress report and I will refresh your waypoint."
	elseif (state == "cooldown") then
		text = "Your last circuit is on record. You must wait " .. GalacticReliefEffort:formatDurationWords(GalacticReliefEffort:getRemainingCooldown(pPlayer)) .. " before undertaking another relief assignment."
	end

	cloned:setCustomDialogText(text)
	return pCloned
end

function GalacticReliefEffortConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "start_assignment") then
		if (GalacticReliefEffort:isRewardPending(pPlayer)) then
			local shouldGrantBonusReward = GalacticReliefEffort:shouldGrantBonusReward(pPlayer)
			local success, message = GalacticReliefEffort:grantReward(pPlayer)
			if (success) then
				local summaryMessage = "Reward granted: 150,000 credits and 1 Holocron of Destiny."

				if (shouldGrantBonusReward) then
					summaryMessage = "Reward granted: 150,000 credits, 1 Holocron of Destiny, and your one-time doctor buff droid deed."
				end

				CreatureObject(pPlayer):sendSystemMessage(summaryMessage)
			end
			return self:buildScreen(pConvTemplate, "claim_reward", message)
		end

		local success, message = GalacticReliefEffort:startAssignment(pPlayer)
		if (success) then
			CreatureObject(pPlayer):sendSystemMessage("Galactic Relief Effort accepted. First waypoint uploaded.")
		end
		return self:buildScreen(pConvTemplate, "start_assignment", message)
	elseif (screenID == "progress_report") then
		if (GalacticReliefEffort:isActive(pPlayer) and not GalacticReliefEffort:isRewardPending(pPlayer)) then
			GalacticReliefEffort:ensureCurrentCityPatients(pPlayer)
			GalacticReliefEffort:updateWaypoint(pPlayer)
			return self:buildScreen(pConvTemplate, "progress_report", GalacticReliefEffort:buildProgressReportText(pPlayer))
		end

		if (GalacticReliefEffort:isRewardPending(pPlayer)) then
			return self:buildScreen(pConvTemplate, "progress_report", GalacticReliefEffort:buildProgressReportText(pPlayer) .. "\n\nReturn to Teren Vahl and claim your reward.")
		end

		return self:buildScreen(pConvTemplate, "progress_report", "You do not have an active relief assignment.\n\n" .. GalacticReliefEffort.COORDINATOR_INTRO)
	elseif (screenID == "rules") then
		return self:buildScreen(pConvTemplate, "rules", GalacticReliefEffort:getRulesText())
	end

	return pConvScreen
end

function GalacticReliefEffortConvoHandler:buildScreen(pConvTemplate, screenName, text)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen(screenName)
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(text)
	return pCloned
end
