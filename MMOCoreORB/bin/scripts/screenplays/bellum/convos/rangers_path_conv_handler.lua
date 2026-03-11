--[[
	The Ranger's Path conversation handler

	This handler delegates quest state and rewards to the screenplay so that:
	- stage progression stays authoritative in one place
	- the final reward cannot be duplicated
	- final completion remains gated behind Talren Voss
]]

RangersPathConvoHandler = conv_handler:new {}

function RangersPathConvoHandler:getScreenForPlayer(pPlayer)
	if (pPlayer == nil) then
		return "intro"
	end

	if (RangersPath:isRewarded(pPlayer)) then
		return "already_completed"
	end

	if (RangersPath:hasFinalObjectiveComplete(pPlayer) or RangersPath:isCompleted(pPlayer)) then
		return "final_completion"
	end

	if (not RangersPath:hasStarted(pPlayer)) then
		return "intro"
	end

	local stage = RangersPath:getStage(pPlayer)

	if (stage < 1 or stage > RangersPath.MAX_STAGE) then
		return "intro"
	end

	if (RangersPath:isStageReady(pPlayer, stage)) then
		return "stage_" .. tostring(stage) .. "_ready"
	end

	return "stage_" .. tostring(stage) .. "_progress"
end

function RangersPathConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	return convoTemplate:getScreen(self:getScreenForPlayer(pPlayer))
end

function RangersPathConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "accept_quest") then
		RangersPath:startQuest(pPlayer)
		return pConvScreen
	end

	if (screenID == "refresh_waypoint") then
		RangersPath:refreshQuestWaypoint(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("Your Ranger's Path waypoint has been refreshed.")
		return pConvScreen
	end

	if (screenID == "complete_stage_1") then
		self:tryCompleteStage(pPlayer, 1)
		return pConvScreen
	end

	if (screenID == "complete_stage_2") then
		self:tryCompleteStage(pPlayer, 2)
		return pConvScreen
	end

	if (screenID == "complete_stage_3") then
		self:tryCompleteStage(pPlayer, 3)
		return pConvScreen
	end

	if (screenID == "complete_stage_4") then
		self:tryCompleteStage(pPlayer, 4)
		return pConvScreen
	end

	if (screenID == "complete_stage_5") then
		self:tryCompleteStage(pPlayer, 5)
		return pConvScreen
	end

	if (screenID == "claim_reward") then
		self:tryGiveReward(pPlayer)
		return pConvScreen
	end

	return pConvScreen
end

function RangersPathConvoHandler:tryCompleteStage(pPlayer, stage)
	if (pPlayer == nil) then
		return false
	end

	if (RangersPath:isRewarded(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already completed The Ranger's Path.")
		return false
	end

	if (RangersPath:getStage(pPlayer) ~= stage) then
		CreatureObject(pPlayer):sendSystemMessage("You are not on that stage of The Ranger's Path.")
		return false
	end

	if (not RangersPath:isStageReady(pPlayer, stage)) then
		CreatureObject(pPlayer):sendSystemMessage("You have not completed that stage's objective yet.")
		return false
	end

	return RangersPath:completeStage(pPlayer, stage)
end

function RangersPathConvoHandler:tryGiveReward(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (RangersPath:isRewarded(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already claimed the Ranger's Path reward.")
		return false
	end

	if (not RangersPath:hasFinalObjectiveComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have not yet completed the Ranger Trial.")
		return false
	end

	return RangersPath:giveFinalReward(pPlayer)
end
