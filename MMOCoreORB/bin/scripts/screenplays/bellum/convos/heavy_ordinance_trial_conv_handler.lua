HeavyOrdinanceTrialConvoHandler = conv_handler:new {}

function HeavyOrdinanceTrialConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen("hub")
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(HeavyOrdinanceTrial:getIntroText(pPlayer))
	return pCloned
end

function HeavyOrdinanceTrialConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "start_assignment") then
		local success, message = HeavyOrdinanceTrial:startAssignmentFromNpc(pPlayer)
		if (success) then
			CreatureObject(pPlayer):sendSystemMessage("Heavy Ordinance Trial accepted. Assault waypoint uploaded.")
		end
		return self:buildScreen(pConvTemplate, "response", message)
	elseif (screenID == "progress_report") then
		return self:buildScreen(pConvTemplate, "response", HeavyOrdinanceTrial:getProgressText(pPlayer, true))
	elseif (screenID == "claim_reward") then
		local success, message = HeavyOrdinanceTrial:claimReward(pPlayer)
		if (success) then
			CreatureObject(pPlayer):sendSystemMessage("Reward granted: credits, 1 Holocron of Destiny, and 1 attachment.")
		end
		return self:buildScreen(pConvTemplate, "response", message)
	elseif (screenID == "cooldown_status") then
		return self:buildScreen(pConvTemplate, "response", HeavyOrdinanceTrial:getCooldownText(pPlayer))
	elseif (screenID == "rules") then
		return self:buildScreen(pConvTemplate, "response", HeavyOrdinanceTrial:getRulesText())
	elseif (screenID == "abort_assignment") then
		local success, message = HeavyOrdinanceTrial:abortAssignment(pPlayer)
		return self:buildScreen(pConvTemplate, "response", message)
	end

	return pConvScreen
end

function HeavyOrdinanceTrialConvoHandler:buildScreen(pConvTemplate, screenName, text)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen(screenName)
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(text)
	return pCloned
end
