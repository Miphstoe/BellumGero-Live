-- ============================================================================
-- PADAWAN TRIALS: 5-TIER SYSTEM
-- Refactored implementation with Trivia + PvE Point Accrual
-- ============================================================================

local ObjectManager = require("managers.object.object_manager")

-- Load SUI dialog classes
require("sui.SuiListBox")
require("sui.SuiMessageBox")

-- Load separate data files
require("screenplays.jedi.padawan.padawanTrialData")
require("screenplays.jedi.padawan.PADAWAN_TRIVIA_QUESTIONS")

PadawanTrials = ScreenPlay:new {}

-- Configuration
local PADAWAN_TRIAL_SKIP_COST = 5000000  -- 5 million credits

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

-- Initialize Padawan Trials for a player
function PadawanTrials:startPadawanTrials(pObject, pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- First check if player is awaiting lightsaber crafting for Phase 3
	local awaitingCrafting = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting"))
	if awaitingCrafting == 1 then
		CreatureObject(pPlayer):sendSystemMessage("You have crafted your lightsaber! Proceeding to Phase 3 hunting...")
		-- For now, we'll automatically proceed when awaiting crafting
		-- The player has crafted and tuned a lightsaber (they told us they did)
		writeScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting", 0)
		self:startHuntingPhase(pPlayer, 3)
		return
	end

	-- First check if player is in an active trial mid-progress (has phaseStatus set)
	local phaseStatus = readScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus")

	-- If player is waiting at shrine to start next phase
	if (phaseStatus == "awaiting_shrine") then
		local nextPhase = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "nextPhase"))
		if nextPhase and nextPhase > 0 then
			self:startPhase(pPlayer, nextPhase)
			return
		end
	end

	-- If player is in the middle of trials, show status
	if (phaseStatus == "trivia" or phaseStatus == "hunting" or phaseStatus == "crafting") then
		-- If stuck in trivia, offer to reset
		if phaseStatus == "trivia" then
			local sui = SuiMessageBox.new("PadawanTrials", "triiaResetCallback")
			sui.setTitle("Padawan Trials - Reset")
			sui.setPrompt("You appear to be stuck in trivia mode. Would you like to reset the trials and start Phase 1 fresh?")
			sui.setOkButtonText("Reset and Start Over")
			sui.setCancelButtonText("Cancel")
			sui.sendTo(pPlayer)
			return
		end
		self:showPhaseStatus(pPlayer)
		return
	end

	-- Otherwise, reset any stale data
	self:resetAllPadawanTrials(pPlayer)

	-- Check eligibility
	if (not JediTrials:isEligibleForPadawanTrials(pPlayer)) then
		local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
		sui.setTitle("Padawan Trials")
		sui.setPrompt("You are not eligible for the Padawan Trials at this time.\n\nYou must:\n- Be a Jedi Novice\n- Have learned at least 6 Force abilities\n- Not already be a Padawan or higher")
		sui.setOkButtonText("Close")
		sui.sendTo(pPlayer)
		return
	end

	-- Show initial dialog with 3 options: Begin, Skip, Cancel
	local sui = SuiMessageBox.new("PadawanTrials", "padawanTrialsStartCallback")

	if (pObject ~= nil) then
		sui.setTargetNetworkId(SceneObject(pObject):getObjectID())
	end

	sui.setTitle("Padawan Trials")
	sui.setPrompt("Greetings, Initiate.\n\nYou stand at the threshold of greatness. The path to Padawan awaits those with the dedication to walk it.\n\nWould you like to begin the Padawan Trials, or pay " .. PADAWAN_TRIAL_SKIP_COST .. " credits to complete them instantly?\n\n(Credits will be taken from cash first, then bank)")

	sui.setOkButtonText("Begin Trials")
	sui.setCancelButtonText("Cancel")
	sui.setOtherButtonText("Skip - " .. PADAWAN_TRIAL_SKIP_COST)

	-- Enable the Other button (needed for 3-button dialogs)
	sui.setProperty("btnRevert", "OnPress", "RevertWasPressed=1\r\nparent.btnOk.press=t")
	sui.subscribeToPropertyForEvent(SuiEventType.SET_onClosedOk, "btnRevert", "RevertWasPressed")

	sui.sendTo(pPlayer)
end

-- Handle trivia reset dialog
function PadawanTrials:triiaResetCallback(pPlayer, pSui, eventIndex, ...)
	if (pPlayer == nil) then
		return
	end

	-- eventIndex == 1 means Cancel button was pressed
	if (eventIndex == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Reset cancelled.")
		return
	end

	-- OK button was pressed - reset and start fresh
	self:resetAllPadawanTrials(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Trials reset! Please meditate again to begin Phase 1.")
end

-- Handle initial dialog response
function PadawanTrials:padawanTrialsStartCallback(pPlayer, pSui, eventIndex, ...)
	if (pPlayer == nil) then
		return
	end

	-- eventIndex == 1 means Cancel button was pressed
	if (eventIndex == 1) then
		return
	end

	if (not JediTrials:isEligibleForPadawanTrials(pPlayer)) then
		local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
		sui.setTitle("@jedi_trials:force_shrine_title")
		sui.setPrompt("@jedi_trials:padawan_trials_started_not_eligible")
		sui.setOkButtonText("@jedi_trials:button_close")
		sui.sendTo(pPlayer)
		return
	end

	-- Check if other button was pressed (Skip option)
	local args = {...}
	local skipPressed = (args ~= nil and args[1] ~= nil)

	if (skipPressed) then
		-- Other button (Skip) was pressed
		self:tryCompletePadawanForCredits(pPlayer, PADAWAN_TRIAL_SKIP_COST)
		return
	end

	-- OK button (Begin Trials) was pressed
	self:startPhase(pPlayer, 1)
end

-- Start a specific phase
function PadawanTrials:startPhase(pPlayer, phase)
	if (pPlayer == nil or phase < 1 or phase > PADAWAN_TRIALS_TOTAL_PHASES) then
		return
	end


	-- Initialize phase data
	writeScreenPlayData(pPlayer, "PadawanTrials", "currentPhase", phase)
	writeScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints", 0)
	writeScreenPlayData(pPlayer, "PadawanTrials", "startedTrials", 1)
	writeScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus", "trivia")

	-- Pre-generate and store the 3 questions for this phase
	-- This ensures the questions don't change between question 1, 2, and 3
	local questions = getPadawanTriviaQuestions(phase)

	for i = 1, 3 do
		if questions[i] then
			writeScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. i .. "Correct", questions[i].correctAnswer)
			writeScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. i .. "Text", questions[i].question)
			-- Store all 4 answers
			for j = 1, 4 do
				writeScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. i .. "Answer" .. j, questions[i].answers[j])
			end
		end
	end

	-- Register global kill observer for PvE points
	createObserver(KILLEDCREATURE, "PadawanTrials", "notifyKilledForPoints", pPlayer)

	-- Start trivia questions
	self:presentTriviaQuestion(pPlayer, phase, 1)
end

-- Present trivia questions (3 per phase) using SUI ListBox for proper 4-answer support
function PadawanTrials:presentTriviaQuestion(pPlayer, phase, questionNumber)
	if (pPlayer == nil or phase < 1 or phase > PADAWAN_TRIALS_TOTAL_PHASES or questionNumber < 1 or questionNumber > 3) then
		return
	end


	-- Retrieve the pre-stored question data for this specific question (phase-specific keys)
	local questionText = readScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. questionNumber .. "Text")
	local correctAnswer = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. questionNumber .. "Correct"))


	if questionText == nil or correctAnswer == nil then
		CreatureObject(pPlayer):sendSystemMessage("Error retrieving trivia question for phase " .. phase .. ", question " .. questionNumber)
		return
	end

	-- Create ListBox dialog for multiple choice (supports all 4 answers)
	local sui = SuiListBox.new("PadawanTrials", "handleTriviaAnswer")
	sui.setPrompt(questionText)
	sui.setTitle("Jedi Trials - Question " .. questionNumber .. " of 3")

	-- Add all 4 answer options (pre-stored)
	local answerCount = 0
	for j = 1, 4 do
		local answerText = readScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. questionNumber .. "Answer" .. j)
		if answerText then
			answerCount = answerCount + 1
			sui.add(answerText, "")  -- Don't use data field, eventIndex will give us the list position
		end
	end

	-- Store current question number and phase for validation
	writeScreenPlayData(pPlayer, "PadawanTrials", "currentQuestion", questionNumber)
	writeScreenPlayData(pPlayer, "PadawanTrials", "phaseForQuestion", phase)

	sui.sendTo(pPlayer)
end

-- Handle trivia answer
function PadawanTrials:handleTriviaAnswer(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end


	-- args is 0-based list index (0, 1, 2, 3 for items 1, 2, 3, 4 in the list)
	-- Convert to 1-based answer number
	local playerAnswer = tonumber(args) + 1


	local questionNumber = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "currentQuestion"))
	local phase = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "phaseForQuestion"))
	-- Get the correct answer from pre-stored data (phase-specific keys)
	local correctAnswer = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. questionNumber .. "Correct"))


	if playerAnswer == correctAnswer then
		CreatureObject(pPlayer):sendSystemMessage(padawanPhaseMessages[phase].trivia_success)

		-- If all 3 questions answered correctly
		if questionNumber == 3 then
			-- Handle phase-specific requirements
			if phase == 3 then
				-- Phase 3: Requires lightsaber crafting
				-- Grant Jedi Initiate rank so they can craft lightsaber
				if not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_01") then
					awardSkill(pPlayer, "force_title_jedi_rank_01")
					CreatureObject(pPlayer):sendSystemMessage("You have been granted the rank of Jedi Initiate. You may now craft your lightsaber!")
				end
				writeScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting", 1)
				CreatureObject(pPlayer):sendSystemMessage(padawanPhaseMessages[phase].crafting_prompt)
			else
				-- Other phases: Go directly to hunting
				self:startHuntingPhase(pPlayer, phase)
			end
		else
			-- Continue to next question
			self:presentTriviaQuestion(pPlayer, phase, questionNumber + 1)
		end
	else
		-- Wrong answer - ask to retry
		CreatureObject(pPlayer):sendSystemMessage(padawanPhaseMessages[phase].trivia_failure)
		self:presentTriviaQuestion(pPlayer, phase, questionNumber)
	end
end

-- Start the hunting phase
function PadawanTrials:startHuntingPhase(pPlayer, phase)
	if (pPlayer == nil or phase < 1 or phase > PADAWAN_TRIALS_TOTAL_PHASES) then
		return
	end

	writeScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus", "hunting")
	writeScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints", 0)
	writeScreenPlayData(pPlayer, "PadawanTrials", "huntingPhase", phase)

	-- Observer already created in startPhase, so kills will be tracked
	CreatureObject(pPlayer):sendSystemMessage(padawanPhaseMessages[phase].hunting_progress)
end

-- Global kill observer for PvE points
function PadawanTrials:notifyKilledForPoints(pPlayer, pVictim)
	if (pVictim == nil or pPlayer == nil) then
		return 0
	end


	-- Check if player is on Padawan Trials
	local startedTrials = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "startedTrials"))
	if startedTrials ~= 1 then
		return 0
	end

	local phaseStatus = readScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus")

	-- Only award points during hunting phases
	if phaseStatus ~= "hunting" then
		return 0
	end


	-- Get creature level and calculate points
	local creatureLevel = CreatureObject(pVictim):getLevel()
	local pointsAwarded = self:getPointsForCreatureLevel(creatureLevel)

	if (pointsAwarded > 0) then
		-- Update current phase points
		local currentPhasePoints = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints")) or 0
		currentPhasePoints = currentPhasePoints + pointsAwarded

		writeScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints", currentPhasePoints)

		-- Update total points
		local totalPoints = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "totalPoints")) or 0
		totalPoints = totalPoints + pointsAwarded

		writeScreenPlayData(pPlayer, "PadawanTrials", "totalPoints", totalPoints)

		-- Send system message
		local pointMessage = string.format("Padawan Trials: +%d points (%d / %d)", pointsAwarded, currentPhasePoints, PADAWAN_TRIALS_PHASE_POINTS)
		CreatureObject(pPlayer):sendSystemMessage(pointMessage)

		-- Check if phase complete (10,000 points)
		if currentPhasePoints >= PADAWAN_TRIALS_PHASE_POINTS then
			self:completePhase(pPlayer, tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "huntingPhase")))
		end

		-- Check for milestone celebrations
		self:checkMilestones(pPlayer, totalPoints)
	end

	return 0
end

-- Complete a phase and advance
function PadawanTrials:completePhase(pPlayer, phase)
	if (pPlayer == nil or phase < 1 or phase > PADAWAN_TRIALS_TOTAL_PHASES) then
		return
	end


	-- Drop observer
	dropObserver(KILLEDCREATURE, "PadawanTrials", "notifyKilledForPoints", pPlayer)

	-- Message
	CreatureObject(pPlayer):sendSystemMessage(padawanPhaseMessages[phase].hunting_complete)

	if phase == PADAWAN_TRIALS_TOTAL_PHASES then
		-- Phase 5 complete - become Padawan
		self:unlockPadawan(pPlayer)
	else
		-- Move to next phase
		writeScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus", "awaiting_shrine")
		writeScreenPlayData(pPlayer, "PadawanTrials", "nextPhase", phase + 1)
		CreatureObject(pPlayer):sendSystemMessage("Return to the shrine to begin the next phase.")
	end
end

-- Unlock Padawan status
function PadawanTrials:unlockPadawan(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Drop observer
	dropObserver(KILLEDCREATURE, "PadawanTrials", "notifyKilledForPoints", pPlayer)

	-- Grant Padawan skill
	JediTrials:unlockJediPadawan(pPlayer)

	-- Give robes based on faction
	local creature = CreatureObject(pPlayer)
	local faction = creature:getFaction()

	local robeTemplate
	if faction == FACTIONREBEL then
		robeTemplate = PADAWAN_ROBE_LIGHT
	else
		robeTemplate = PADAWAN_ROBE_DARK
	end

	-- Place robes in inventory
	local inventory = creature:getSlottedObject("inventory")
	if inventory ~= nil then
		giveItem(inventory, robeTemplate, -1)
	end

	-- Send congratulation message
	CreatureObject(pPlayer):sendSystemMessage("Congratulations! You have become a Jedi Padawan!")
	CreatureObject(pPlayer):sendSystemMessage("Your Padawan robes have been placed in your inventory.")

	-- Clear trial data
	writeScreenPlayData(pPlayer, "PadawanTrials", "completedTrials", 1)
	writeScreenPlayData(pPlayer, "PadawanTrials", "startedTrials", 0)
end

-- Check for milestone celebrations
function PadawanTrials:checkMilestones(pPlayer, totalPoints)
	if (pPlayer == nil) then
		return
	end

	for _, milestone in ipairs(padawanTrialMilestones) do
		if totalPoints == milestone.points then
			CreatureObject(pPlayer):sendSystemMessage(milestone.message)
			break
		end
	end
end

-- Get points for creature level
function PadawanTrials:getPointsForCreatureLevel(creatureLevel)
	if (creatureLevel == nil) then
		return 0
	end

	for i = 1, #padawanTrialLevelPointTiers, 1 do
		local tier = padawanTrialLevelPointTiers[i]
		if (creatureLevel >= tier.minLevel and creatureLevel <= tier.maxLevel) then
			return tier.points
		end
	end

	return 0
end

-- Handle 5M credit skip
function PadawanTrials:tryCompletePadawanForCredits(pPlayer, amount)
	if (pPlayer == nil) then
		return
	end

	amount = amount or PADAWAN_TRIAL_SKIP_COST

	local creature = CreatureObject(pPlayer)

	if (creature == nil) then
		return
	end

	-- Safety check
	if (creature:hasSkill("force_title_jedi_rank_02") or creature:hasSkill("force_title_jedi_rank_03")) then
		local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
		sui.setTitle("@jedi_trials:force_shrine_title")
		sui.setPrompt("You are already a Jedi Padawan or higher.\n\nYou cannot purchase trials you have already completed.")
		sui.setOkButtonText("@jedi_trials:button_close")
		sui.sendTo(pPlayer)
		return
	end

	local cash = creature:getCashCredits() or 0
	local bank = creature:getBankCredits() or 0
	local total = cash + bank

	-- Check if player has enough credits
	if (total < amount) then
		local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
		sui.setTitle("@jedi_trials:force_shrine_title")
		sui.setPrompt("You do not have enough credits.\n\nRequired: " .. amount .. " credits\n\nYou have:\n  Cash: " .. cash .. " credits\n  Bank: " .. bank .. " credits\n  Total: " .. total .. " credits")
		sui.setOkButtonText("@jedi_trials:button_close")
		sui.sendTo(pPlayer)
		return
	end

	-- Deduct credits
	local remaining = amount
	local cashDeducted = 0
	local bankDeducted = 0

	if (cash > 0 and remaining > 0) then
		cashDeducted = math.min(cash, remaining)
		creature:subtractCashCredits(cashDeducted)
		remaining = remaining - cashDeducted
	end

	if (remaining > 0) then
		bankDeducted = remaining
		creature:subtractBankCredits(bankDeducted)
	end

	-- Unlock Padawan
	JediTrials:unlockJediPadawan(pPlayer)

	-- Give robes
	local inventory = creature:getSlottedObject("inventory")
	local faction = creature:getFaction()
	local robeTemplate = faction == FACTIONREBEL and PADAWAN_ROBE_LIGHT or PADAWAN_ROBE_DARK

	if inventory ~= nil then
		giveItem(inventory, robeTemplate, -1)
	end

	-- Send confirmation
	local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
	sui.setTitle("@jedi_trials:force_shrine_title")
	local confirmMsg = "Payment received: " .. amount .. " credits"
	if (cashDeducted > 0 and bankDeducted > 0) then
		confirmMsg = confirmMsg .. "\n  (Cash: " .. cashDeducted .. ", Bank: " .. bankDeducted .. ")"
	elseif (cashDeducted > 0) then
		confirmMsg = confirmMsg .. "\n  (From Cash)"
	else
		confirmMsg = confirmMsg .. "\n  (From Bank)"
	end
	confirmMsg = confirmMsg .. "\n\nYou have been granted the rank of Jedi Padawan!\n\nYour robes have been placed in your inventory.\n\nMay the Force be with you."
	sui.setPrompt(confirmMsg)
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.sendTo(pPlayer)

	-- Clear any trial state
	writeScreenPlayData(pPlayer, "PadawanTrials", "completedTrials", 1)
	writeScreenPlayData(pPlayer, "PadawanTrials", "startedTrials", 0)
end

-- Check if player has crafted a lightsaber (detects any lightsaber in inventory)
function PadawanTrials:checkLightsaberCrafted(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local creature = CreatureObject(pPlayer)
	if creature == nil then
		return false
	end

	local inventory = creature:getSlottedObject("inventory")

	if inventory == nil then
		return false
	end

	-- Check all items in inventory for lightsabers
	local items = inventory:getContainedObjects()

	if items == nil then
		return false
	end

	local itemCount = items:size()

	for i = 0, itemCount - 1 do
		local item = items:get(i)
		if item ~= nil then
			local template = SceneObject(item):getTemplate()
			if template ~= nil then
				local templateLower = string.lower(template)
				-- Check if item is a lightsaber (contains "lightsaber" or "saber" in template name)
				if string.find(templateLower, "lightsaber") or string.find(templateLower, "saber") then
					return true
				end
			end
		end
	end

	return false
end

-- Manual confirmation for Phase 3 lightsaber crafting
function PadawanTrials:confirmLightsaberCrafted(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local awaitingCrafting = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting"))

	if awaitingCrafting ~= 1 then
		CreatureObject(pPlayer):sendSystemMessage("You are not currently awaiting lightsaber confirmation.")
		return
	end

	-- Check if player actually has a lightsaber
	if not self:checkLightsaberCrafted(pPlayer) then
		CreatureObject(pPlayer):sendSystemMessage("I do not sense a lightsaber in your possession. You must craft one to continue.")
		return
	end

	-- Lightsaber confirmed
	writeScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting", 0)
	CreatureObject(pPlayer):sendSystemMessage("Your lightsaber is complete. Return to the shrine to continue your trials.")
	self:startHuntingPhase(pPlayer, 3)
end

-- Re-register observers on player login to persist across server restarts
function PadawanTrials:onPlayerLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local startedTrials = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "startedTrials"))
	local phaseStatus = readScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus")

	-- If player is in hunting phase, re-register the kill observer
	if (startedTrials == 1 and phaseStatus == "hunting") then
		createObserver(KILLEDCREATURE, "PadawanTrials", "notifyKilledForPoints", pPlayer)
	end
end

-- Show current phase status when player returns to shrine during trials
function PadawanTrials:showPhaseStatus(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local currentPhase = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "currentPhase")) or 0
	local phaseStatus = readScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus") or "unknown"
	local currentPhasePoints = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints")) or 0
	local totalPoints = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "totalPoints")) or 0

	local statusMsg = "Welcome back to the Padawan Trials.\n\n"
	statusMsg = statusMsg .. "Phase: " .. currentPhase .. " of 5\n"
	statusMsg = statusMsg .. "Total Progress: " .. totalPoints .. " / 50,000 points\n\n"

	if (phaseStatus == "trivia") then
		local currentQuestion = tonumber(readScreenPlayData(pPlayer, "PadawanTrials", "currentQuestion")) or 1
		statusMsg = statusMsg .. "Status: Answer trivia questions (Question " .. currentQuestion .. " of 3)"
	elseif (phaseStatus == "hunting") then
		statusMsg = statusMsg .. "Status: Hunting (" .. currentPhasePoints .. " / " .. PADAWAN_TRIALS_PHASE_POINTS .. " points)"
	elseif (phaseStatus == "crafting") then
		statusMsg = statusMsg .. "Status: Craft your lightsaber and return to continue"
	else
		statusMsg = statusMsg .. "Status: Unknown (contact an administrator)"
	end

	local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
	sui.setTitle("@jedi_trials:force_shrine_title")
	sui.setPrompt(statusMsg)
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.sendTo(pPlayer)
end

-- Reset all Padawan trial data
function PadawanTrials:resetAllPadawanTrials(pPlayer)
	if (pPlayer == nil) then
		return
	end

	deleteScreenPlayData(pPlayer, "PadawanTrials", "startedTrials")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "completedTrials")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "currentPhase")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "currentPhasePoints")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "totalPoints")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "phaseStatus")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "currentQuestion")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "correctAnswer")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "phaseForQuestion")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "awaitingCrafting")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "huntingPhase")
	deleteScreenPlayData(pPlayer, "PadawanTrials", "nextPhase")

	-- Also clear all pre-stored question data for all phases
	for phase = 1, 5 do
		for q = 1, 3 do
			deleteScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. q .. "Text")
			deleteScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. q .. "Correct")
			for a = 1, 4 do
				deleteScreenPlayData(pPlayer, "PadawanTrials", "phase" .. phase .. "Question" .. q .. "Answer" .. a)
			end
		end
	end
end

return PadawanTrials
