local ObjectManager = require("managers.object.object_manager")

RecruiterConvoHandler = conv_handler:new {}

-- ===== GCW Ambush opt-in/out (per-faction) =====
local AMBUSH_OPT_TAG = { rebel = "GCW_Ambush_Rebels", imperial = "GCW_Ambush_Imperials" }

function RecruiterConvoHandler:isAmbushOptedIn(pPlayer, factionStr)
	if factionStr ~= "rebel" and factionStr ~= "imperial" then return false end
	return CreatureObject(pPlayer):hasScreenPlayState(1, AMBUSH_OPT_TAG[factionStr])
end

function RecruiterConvoHandler:setAmbushOpt(pPlayer, factionStr, enabled)
	if factionStr ~= "rebel" and factionStr ~= "imperial" then return end
	if enabled then
		CreatureObject(pPlayer):setScreenPlayState(1, AMBUSH_OPT_TAG[factionStr])
	else
		CreatureObject(pPlayer):removeScreenPlayState(1, AMBUSH_OPT_TAG[factionStr])
	end
	CreatureObject(pPlayer):sendSystemMessage(enabled and "Ambush Encounters: ENABLED." or "Ambush Encounters: DISABLED.")
end

function RecruiterConvoHandler:addAmbushToggleOption(pPlayer, pNpc, screen)
	local fac = recruiterScreenplay:getRecruiterFaction(pNpc) -- "rebel" or "imperial"
	if fac ~= "rebel" and fac ~= "imperial" then return end
	if self:isAmbushOptedIn(pPlayer, fac) then
		screen:addOption("Disable GCW Ambush Encounters", "ambush_disable")
	else
		screen:addOption("Enable GCW Ambush Encounters", "ambush_enable")
	end
end

function RecruiterConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local clonedConversation = LuaConversationScreen(pConvScreen)

	if (screenID == "greet_neutral_start") then
		if (recruiterScreenplay:isEligibleForJoin(pPlayer, pNpc)) then
			if (recruiterScreenplay:getRecruiterFaction(pNpc) == "imperial") then
				clonedConversation:addOption("@conversation/faction_recruiter_imperial:s_306", "accept_join")
			else
				clonedConversation:addOption("@conversation/faction_recruiter_rebel:s_462", "accept_join")
			end
		end

	elseif (screenID == "greet_member_start_covert" or screenID == "stay_covert" or screenID == "dont_resign_covert") then
		self:updateScreenWithPromotions(pPlayer, pConvTemplate, pConvScreen, recruiterScreenplay:getRecruiterFaction(pNpc))

		if (recruiterScreenplay:getFactionFromHashCode(CreatureObject(pPlayer):getFaction()) == "rebel") then
			clonedConversation:addOption("@conversation/faction_recruiter_rebel:s_480", "faction_purchase")
		else
			clonedConversation:addOption("@conversation/faction_recruiter_imperial:s_324", "faction_purchase")
		end
		-- Add Ambush toggle on covert member screens
		self:addAmbushToggleOption(pPlayer, pNpc, clonedConversation)

	elseif (screenID == "greet_member_start_overt" or screenID == "stay_overt" or screenID == "dont_resign_overt") then
		self:updateScreenWithPromotions(pPlayer, pConvTemplate, pConvScreen, recruiterScreenplay:getRecruiterFaction(pNpc))
		self:updateScreenWithBribe(pPlayer, pNpc, pConvTemplate, pConvScreen, recruiterScreenplay:getRecruiterFaction(pNpc))

		if (recruiterScreenplay:getFactionFromHashCode(CreatureObject(pPlayer):getFaction()) == "rebel") then
			clonedConversation:addOption("@conversation/faction_recruiter_rebel:s_480", "faction_purchase")
		else
			clonedConversation:addOption("@conversation/faction_recruiter_imperial:s_324", "faction_purchase")
		end
		-- Add Ambush toggle on overt member screens
		self:addAmbushToggleOption(pPlayer, pNpc, clonedConversation)

	elseif (screenID == "accept_join") then
		CreatureObject(pPlayer):setFaction(recruiterScreenplay:getRecruiterFactionHashCode(pNpc))
		CreatureObject(pPlayer):setFactionStatus(1)

	elseif (screenID == "accepted_go_overt") then
		CreatureObject(pPlayer):setFutureFactionStatus(2)

	elseif (screenID == "accepted_resign") then
		if (CreatureObject(pPlayer):hasSkill("force_rank_light_novice") or CreatureObject(pPlayer):hasSkill("force_rank_dark_novice")) then
			CreatureObject(pPlayer):sendSystemMessage("@faction_recruiter:jedi_cant_resign")
			return
		end

		CreatureObject(pPlayer):setFutureFactionStatus(0)
		writeData(CreatureObject(pPlayer):getObjectID() .. ":changingFactionStatus", 1)
		createEvent(300000, "recruiterScreenplay", "handleResign", pPlayer, "")
		return pConvScreen

	elseif (screenID == "accepted_resume_duties") then
		CreatureObject(pPlayer):setFutureFactionStatus(1)
		createEvent(30000, "recruiterScreenplay", "handleGoCovert", pPlayer, "")
		writeData(CreatureObject(pPlayer):getObjectID() .. ":changingFactionStatus", 1)

	elseif (screenID == "confirm_promotion") then
		local rank = CreatureObject(pPlayer):getFactionRank() + 1

		if rank > 12 or recruiterScreenplay:getBonusFactionPoints(pPlayer, rank) <= 0 then
			return
		end

		SceneObject(pPlayer):addPendingTask(10000, "recruiterScreenplay", "handlePromotion", tonumber(rank))
		writeData(CreatureObject(pPlayer):getObjectID() .. ":confirm_promotion", rank)
		return pConvScreen

	elseif (screenID == "confirm_overt") then
		writeData(CreatureObject(pPlayer):getObjectID() .. ":confirm_overt", 1)
		return pConvScreen

	elseif (screenID == "confirm_resign") then
		writeData(CreatureObject(pPlayer):getObjectID() .. ":confirm_resign", 1)
		return pConvScreen

	elseif (screenID == "cancel_resign") then
		deleteData(CreatureObject(pPlayer):getObjectID() .. ":changingFactionStatus")
		SceneObject(pPlayer):cancelPendingTask("recruiterScreenplay", "handleResign")

	elseif (screenID == "declare_complete") then
		CreatureObject(pPlayer):setFutureFactionStatus(2)
		writeData(CreatureObject(pPlayer):getObjectID() .. ":changingFactionStatus", 1)
		createEvent(1000, "recruiterScreenplay", "handleGoOvert", pPlayer, "")

	elseif (screenID == "covert_complete") then
		if (CreatureObject(pPlayer):hasSkill("force_rank_light_novice") or CreatureObject(pPlayer):hasSkill("force_rank_dark_novice")) then
			CreatureObject(pPlayer):sendSystemMessage("@faction_recruiter:jedi_cant_go_covert")
			return
		end

		if (SceneObject(pPlayer):hasPendingTask("recruiterScreenplay", "handleGoCovert")) then
			SceneObject(pPlayer):cancelPendingTask("recruiterScreenplay", "handleGoCovert")
		end

		local timer = recruiterScreenplay.covertOvertResignTime * 60 * 1000 -- Minutes

		SceneObject(pPlayer):addPendingTask(timer, "recruiterScreenplay", "handleGoCovert")

	elseif (screenID == "ambush_enable") then
		self:setAmbushOpt(pPlayer, recruiterScreenplay:getRecruiterFaction(pNpc), true)

	elseif (screenID == "ambush_disable") then
		self:setAmbushOpt(pPlayer, recruiterScreenplay:getRecruiterFaction(pNpc), false)
	end

	return pConvScreen
end

function RecruiterConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("greet_neutral_start")
	end

	local changingStatus = readData(CreatureObject(pPlayer):getObjectID() .. ":changingFactionStatus")
	local rank = CreatureObject(pPlayer):getFactionRank()
	local faction = CreatureObject(pPlayer):getFaction()

	-- getFutureFactionStatus() isn't bound in Lua on this core; synthesize it using pending tasks + current status
	local futureFactionStatus = -1
	local factionStatus = CreatureObject(pPlayer):getFactionStatus()
	if CreatureObject(pPlayer):isChangingFactionStatus() then
		if SceneObject(pPlayer):hasPendingTask("recruiterScreenplay", "handleResign") then
			futureFactionStatus = 0
		elseif SceneObject(pPlayer):hasPendingTask("recruiterScreenplay", "handleGoCovert") then
			futureFactionStatus = 1
		elseif SceneObject(pPlayer):hasPendingTask("recruiterScreenplay", "handleGoOvert") then
			futureFactionStatus = 2
		else
			-- infer by current status if no task has been queued yet
			if (factionStatus == 1) then
				futureFactionStatus = 2 -- currently covert -> going overt
			elseif (factionStatus == 2) then
				futureFactionStatus = 1 -- currently overt -> going covert
			end
		end
	end
	-- factionStatus already set above

	if (futureFactionStatus == 0) then
		return convoTemplate:getScreen("resign_complete")
	end

	if (futureFactionStatus == 1 and factionStatus == 2) then
		return convoTemplate:getScreen("covert_complete")
	end

	if (futureFactionStatus == 2 and factionStatus == 1) then
		return convoTemplate:getScreen("declare_complete")
	end

	if (changingStatus ~= 0) then
		local conv
		if (factionStatus == 1) then
			conv = "greet_member_start_covert"
		elseif (factionStatus == 2) then
			conv = "greet_member_start_overt"
		else
			conv = "greet_neutral_start"
		end

		return convoTemplate:getScreen(conv)
	end

	if (faction == 0) then
		return convoTemplate:getScreen("greet_neutral_start")
	elseif (factionStatus == 2) then
		return convoTemplate:getScreen("greet_member_start_overt")
	else
		return convoTemplate:getScreen("greet_member_start_covert")
	end
end

function RecruiterConvoHandler:addRankReviewOption(faction, screenObject)
	local pGhost = CreatureObject(screenObject:getPlayer()):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local rank = CreatureObject(screenObject:getPlayer()):getFactionRank()

	if rank < 0 or isHighestRank(rank) == true then
		return
	end

	local requiredPoints = getRankCost(rank + 1)
	local currentPoints = PlayerObject(pGhost):getFactionStanding(faction)

	if (currentPoints < requiredPoints + recruiterScreenplay:getMinimumFactionStanding()) then
		return
	end

	self:addRankReviewOption(faction, screenObject)
end

function RecruiterConvoHandler:updateScreenWithBribe(pPlayer, pNpc, pConvTemplate, pConvScreen, faction)
	local screenObject = LuaConversationScreen(pConvScreen)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (recruiterScreenplay:getFactionFromHashCode(CreatureObject(pPlayer):getFaction()) == faction) then
		local currentStanding = PlayerObject(pGhost):getFactionStanding(faction)
		local maxStanding = 200000

		if (currentStanding >= recruiterScreenplay:getMinimumFactionStanding() and currentStanding < maxStanding) then
			if (faction == "imperial") then
				screenObject:addOption("@conversation/faction_recruiter_imperial:s_395", "bribe")
			else
				screenObject:addOption("@conversation/faction_recruiter_rebel:s_695", "bribe")
			end
		end
	end
end

function RecruiterConvoHandler:updateScreenWithPromotions(pPlayer, pConvTemplate, pConvScreen, faction)
	local screenObject = LuaConversationScreen(pConvScreen)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local rank = CreatureObject(pPlayer):getFactionRank()
	local currentPoints = PlayerObject(pGhost):getFactionStanding(faction)

	if (recruiterScreenplay:canReviewRank(pPlayer, rank + 1) and currentPoints >= getRankCost(rank + 1) + recruiterScreenplay:getMinimumFactionStanding()) then
		screenObject:addOption("@conversation/faction_recruiter_imperial:s_398", "confirm_promotion")
	end
end