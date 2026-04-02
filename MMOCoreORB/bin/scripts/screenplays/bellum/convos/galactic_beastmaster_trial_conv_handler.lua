GalacticBeastmasterTrialConvoHandler = conv_handler:new {}

function GalacticBeastmasterTrialConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen("hub")
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)

	if (not GalacticBeastmasterTrial:isEligibleCreatureHandler(pPlayer)) then
		cloned:setCustomDialogText("This trial is reserved for Creature Handlers. You must hold at least Novice Creature Handler training to begin or progress the Galactic Beastmaster Trial.")
	elseif (GalacticBeastmasterTrial:isActive(pPlayer)) then
		cloned:setCustomDialogText("The trial is already underway. Personally tame one baby creature from each required world, then return for your reward.\n\n" .. GalacticBeastmasterTrial:getProgressReportText(pPlayer))
	elseif (GalacticBeastmasterTrial:isOnCooldown(pPlayer)) then
		cloned:setCustomDialogText("You have already completed the Galactic Beastmaster Trial.\n\n" .. GalacticBeastmasterTrial:getCooldownStatusText(pPlayer))
	else
		cloned:setCustomDialogText("I am Jorvik Tal. If you seek to prove yourself as a true Creature Handler, begin the Galactic Beastmaster Trial and tame one baby creature from each of the ten required worlds.")
	end

	return pCloned
end

function GalacticBeastmasterTrialConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "start_trial") then
		local success, message = GalacticBeastmasterTrial:startTrial(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage(message)
		return self:buildResponseScreen(pConvTemplate, "response", message)
	elseif (screenID == "progress_report") then
		return self:buildResponseScreen(pConvTemplate, "response", GalacticBeastmasterTrial:getProgressReportText(pPlayer))
	elseif (screenID == "completion_check") then
		local success, message = GalacticBeastmasterTrial:completeTrial(pPlayer)
		if (success) then
			CreatureObject(pPlayer):sendSystemMessage("Reward granted: 150,000 credits and 1 Holocron of Destiny.")
		end
		return self:buildResponseScreen(pConvTemplate, "response", message)
	elseif (screenID == "cooldown_status") then
		return self:buildResponseScreen(pConvTemplate, "response", GalacticBeastmasterTrial:getCooldownStatusText(pPlayer))
	elseif (screenID == "rules") then
		return self:buildResponseScreen(pConvTemplate, "response", GalacticBeastmasterTrial:getRulesText())
	end

	return pConvScreen
end

function GalacticBeastmasterTrialConvoHandler:buildResponseScreen(pConvTemplate, screenName, text)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen(screenName)
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(text)
	return pCloned
end
