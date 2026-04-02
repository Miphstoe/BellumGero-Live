GalacticTourConvoHandler = conv_handler:new {}

function GalacticTourConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen("gt_hub")
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)

	if (not GalacticTour:isEligibleEntertainer(pPlayer)) then
		cloned:setCustomDialogText("This tour is reserved for entertainers only. You must hold entertainer, dancer, or musician training to begin the Galactic Tour.")
	elseif (GalacticTour:isOnCooldown(pPlayer) and not GalacticTour:isActive(pPlayer)) then
		cloned:setCustomDialogText("You have already completed your latest Galactic Tour.\n\n" .. GalacticTour:getCooldownStatusText(pPlayer))
	elseif (GalacticTour:isReadyToTurnIn(pPlayer)) then
		cloned:setCustomDialogText("Your 5-stop Galactic Tour is complete. Return your route log and I will issue your reward.\n\n" .. GalacticTour:getProgressReportText(pPlayer))
	elseif (GalacticTour:isActive(pPlayer)) then
		cloned:setCustomDialogText("Your Galactic Tour is already underway.\n\n" .. GalacticTour:getProgressReportText(pPlayer))
	else
		cloned:setCustomDialogText("I coordinate the Galactic Tour. Perform inside valid NPC city cantinas on 5 different planets, 10 continuous minutes each, with at least 10 flourishes per stop. Choose the worlds in any order and return to me when you finish.")
	end

	return pCloned
end

function GalacticTourConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "gt_start_tour") then
		local success, message = GalacticTour:startTour(pPlayer)
		return self:buildResponseScreen(pConvTemplate, "gt_response", message)
	elseif (screenID == "gt_progress_report") then
		return self:buildResponseScreen(pConvTemplate, "gt_response", GalacticTour:getProgressReportText(pPlayer))
	elseif (screenID == "gt_turn_in") then
		local success, message = GalacticTour:turnIn(pPlayer)
		return self:buildResponseScreen(pConvTemplate, "gt_response", message)
	elseif (screenID == "gt_cooldown_status") then
		return self:buildResponseScreen(pConvTemplate, "gt_response", GalacticTour:getCooldownStatusText(pPlayer))
	elseif (screenID == "gt_rules") then
		return self:buildResponseScreen(pConvTemplate, "gt_response", GalacticTour:getRulesText())
	end

	return pConvScreen
end

function GalacticTourConvoHandler:buildResponseScreen(pConvTemplate, screenName, text)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen(screenName)
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(text)
	return pCloned
end
