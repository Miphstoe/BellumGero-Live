dr_kaelen_varr_convo_handler = conv_handler:new {}

function dr_kaelen_varr_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (pPlayer == nil or not GeneticistsFailedExperiment:isBioEngineer(pPlayer)) then
		return convoTemplate:getScreen("not_bio_engineer")
	end

	GeneticistsFailedExperiment:checkAndResetCooldown(pPlayer)

	local state = GeneticistsFailedExperiment:getState(pPlayer)

	if (state == GeneticistsFailedExperiment.QUEST_NOT_STARTED) then
		return convoTemplate:getScreen("intro")
	elseif (state == GeneticistsFailedExperiment.STAGE_1_COMPLETE) then
		return convoTemplate:getScreen("stage1_turnin")
	elseif (state == GeneticistsFailedExperiment.STAGE_2_COMPLETE) then
		return convoTemplate:getScreen("stage2_turnin")
	elseif (state == GeneticistsFailedExperiment.STAGE_3_COMPLETE) then
		return convoTemplate:getScreen("stage3_turnin")
	elseif (state == GeneticistsFailedExperiment.STAGE_4_HUNT_EXPERIMENT and GeneticistsFailedExperiment:getDataNumber(pPlayer, "mutationKilled") == 1) then
		return convoTemplate:getScreen("final_turnin")
	elseif (state == GeneticistsFailedExperiment.QUEST_COMPLETE) then
		return convoTemplate:getScreen("on_cooldown")
	end

	return convoTemplate:getScreen("in_progress")
end

function dr_kaelen_varr_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()
	local clonedScreen = screen:cloneScreen()
	local conversation = LuaConversationScreen(clonedScreen)

	if (screenID == "in_progress" and GeneticistsFailedExperiment:getState(pPlayer) == GeneticistsFailedExperiment.STAGE_4_HUNT_EXPERIMENT and GeneticistsFailedExperiment:getDataNumber(pPlayer, "mutationKilled") == 0) then
		conversation:addOption("Refresh the mutation's last known location.", "repeat_stage4")
	end

	if (screenID == "objective_reminder") then
		local state = GeneticistsFailedExperiment:getState(pPlayer)
		local text

		if (state == GeneticistsFailedExperiment.STAGE_1_COLLECT_DNA) then
			local collected = GeneticistsFailedExperiment:getDataNumber(pPlayer, "dnaCount")
			text = "You need DNA samples from Endor wildlife — bordoks, gurrecks, lantern birds, venom-filled arachne, or squalls. You have collected " .. collected .. " of 5 samples."
		elseif (state == GeneticistsFailedExperiment.STAGE_1_COMPLETE) then
			text = "Bring me the DNA samples you have collected. I am waiting here."
		elseif (state == GeneticistsFailedExperiment.STAGE_2_ANALYZE_DNA) then
			text = "Use the research terminal outside and run a full genetic stability scan on the samples."
		elseif (state == GeneticistsFailedExperiment.STAGE_2_COMPLETE) then
			text = "Return to me with the results of the genetic stability scan."
		elseif (state == GeneticistsFailedExperiment.STAGE_3_CRAFT_COMPONENT) then
			text = "Craft an experimental defensive tissue component at a crafting station and bring it to me."
		elseif (state == GeneticistsFailedExperiment.STAGE_3_COMPLETE) then
			text = "Bring me the experimental component you crafted."
		elseif (state == GeneticistsFailedExperiment.STAGE_4_HUNT_EXPERIMENT and GeneticistsFailedExperiment:getDataNumber(pPlayer, "mutationKilled") == 0) then
			text = "The mutated gurreck alpha is still out there. Hunt it down before it reaches the settlement."
		elseif (state == GeneticistsFailedExperiment.STAGE_4_HUNT_EXPERIMENT) then
			text = "The mutation has been neutralized. Return to me."
		else
			text = "Stay focused. Finish the current objective and return when the work is complete."
		end

		conversation:setCustomDialogText(text)
		GeneticistsFailedExperiment:sendObjective(pPlayer)
		return clonedScreen
	end

	if (screenID == "accept_quest") then
		GeneticistsFailedExperiment:beginQuest(pPlayer)
	elseif (screenID == "stage1_reward") then
		GeneticistsFailedExperiment:completeStage1TurnIn(pPlayer)
	elseif (screenID == "stage2_reward") then
		GeneticistsFailedExperiment:completeStage2TurnIn(pPlayer)
	elseif (screenID == "stage3_reward") then
		GeneticistsFailedExperiment:completeStage3TurnIn(pPlayer)
	elseif (screenID == "final_reward") then
		GeneticistsFailedExperiment:completeQuest(pPlayer)
	elseif (screenID == "repeat_stage4") then
		GeneticistsFailedExperiment:ensureStage4Spawn(pPlayer)
		GeneticistsFailedExperiment:sendObjective(pPlayer)
	end

	return clonedScreen
end
