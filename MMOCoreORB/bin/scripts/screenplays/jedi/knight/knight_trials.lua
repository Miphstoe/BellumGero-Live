local ObjectManager = require("managers.object.object_manager")

KnightTrials = ScreenPlay:new {}

-- Check if a player participated in a creature's death
-- To prevent passive point gain from group members far away, we check if the player was close
local function playerParticipatedInKill(pPlayer, pCreature)
	if pPlayer == nil or pCreature == nil then
		return false
	end

	-- Check if player is within interaction range (32 meters)
	-- This prevents passive point gain from distant group members
	-- Group members must be actively fighting nearby to earn credit
	local PARTICIPATION_RANGE = 32
	local isInRange = SceneObject(pPlayer):isInRangeWithObject(pCreature, PARTICIPATION_RANGE)

	printLuaError("KnightTrials:playerParticipatedInKill - Player: " .. SceneObject(pPlayer):getCustomObjectName() ..
		", Creature: " .. SceneObject(pCreature):getObjectName() .. ", InRange(32m): " .. tostring(isInRange))

	return isInRange
end

function KnightTrials:showKnightTrialsActivationDialog(pObject, pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Show activation dialog
	local sui = SuiMessageBox.new("KnightTrials", "knightTrialsActivationCallback")

	if (pObject ~= nil) then
		sui.setTargetNetworkId(SceneObject(pObject):getObjectID())
	end

	sui.setTitle("Knight Trials")
	sui.setPrompt("Greetings, Padawan.\n\nYou have grown strong in the Force, mastering multiple disciplines and honing your skills. The path to Knighthood now beckons.\n\nThe Knight Trials await you. By hunting creatures across the galaxy and proving your strength in combat, you will earn the respect of the Jedi Council.\n\nYou must earn 50,000 PvE points through battle. Stronger foes grant more points.\n\nWould you like to begin the Knight Trials?")

	sui.setOkButtonText("Begin Knight Trials")
	sui.setCancelButtonText("Not Yet")

	sui.sendTo(pPlayer)
end

function KnightTrials:knightTrialsActivationCallback(pPlayer, pSui, eventIndex, ...)
	if (pPlayer == nil) then
		return
	end

	-- eventIndex == 1 means Cancel button was pressed
	if (eventIndex == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You have chosen to delay your Knight Trials. Return to any Force Shrine when you are ready.")
		return
	end

	-- Player chose to begin - verify eligibility one more time
	if (not JediTrials:isEligibleForKnightTrials(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You are no longer eligible for Knight Trials.")
		return
	end

	-- Activate the Knight Trials
	KnightTrials:startKnightTrials(pPlayer)

	-- Set the shrine activation flag (separate from startedTrials)
	writeScreenPlayData(pPlayer, "KnightTrials", "activatedAtShrine", 1)

	CreatureObject(pPlayer):sendSystemMessage("Knight Trials activated! You will now earn PvE points for hunting creatures. Check your progress at any Force Shrine.")
end

function KnightTrials:startKnightTrials(pPlayer)
	local randomShrinePlanet = JediTrials:getRandomDifferentShrinePlanet(pPlayer)
	local pRandShrine = JediTrials:getRandomShrineOnPlanet(randomShrinePlanet)

	if (pRandShrine == nil) then
		return
	end

	JediTrials:setStartedTrials(pPlayer)
	JediTrials:setTrialsCompleted(pPlayer, 0)
	JediTrials:setCurrentTrial(pPlayer, 0)
	self:setTrialShrine(pPlayer, pRandShrine)

	-- Register global kill observer for PvE points (independent of trial targets)
	-- First drop any existing observer to prevent duplicates
	dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
	-- Now register the observer
	createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)

	local suiPrompt = getStringId("@jedi_trials:knight_trials_intro_msg") .. " " .. getStringId("@jedi_trials:" .. randomShrinePlanet) .. " " .. getStringId("@jedi_trials:knight_trials_intro_msg_end")

	local sui = SuiMessageBox.new("KnightTrials", "noCallback")
	sui.setTitle("@jedi_trials:knight_trials_title")
	sui.setPrompt(suiPrompt)
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.hideCancelButton()
	sui.sendTo(pPlayer)
end

function KnightTrials:noCallback(pPlayer, pSui, eventIndex, ...)
end

function KnightTrials:startNextKnightTrial(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerFaction = CreatureObject(pPlayer):getFaction()
	local playerCouncil = JediTrials:getJediCouncil(pPlayer)

	if ((playerFaction == FACTIONIMPERIAL and playerCouncil == JediTrials.COUNCIL_LIGHT) or (playerFaction == FACTIONREBEL and playerCouncil == JediTrials.COUNCIL_DARK)) then
		self:giveWrongFactionWarning(pPlayer, playerCouncil)
		return
	end

	local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer)

	if (trialsCompleted >= #knightTrialQuests) then
		dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledHuntTarget", pPlayer)
		deleteScreenPlayData(pPlayer, "JediTrials", "huntTarget")
		deleteScreenPlayData(pPlayer, "JediTrials", "huntTargetCount")
		deleteScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal")
		JediTrials:unlockJediKnight(pPlayer)
		return
	end

	-- Display only PvE point progression
	local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
	local shrinePrompt = string.format("PvE Progression: %d / 50000 points\n\nContinue hunting creatures to progress toward Knight status.", currentPoints)

	local sui = SuiMessageBox.new("KnightTrials", "noCallback")
	sui.setTitle("@jedi_trials:knight_trials_title")
	sui.setPrompt(shrinePrompt)
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.hideCancelButton()
	sui.sendTo(pPlayer)
end

function KnightTrials:sendCouncilChoiceSui(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("KnightTrials", "handleCouncilChoice")
	sui.setPrompt("@jedi_trials:council_choice_msg")
	sui.setTitle("@jedi_trials:knight_trials_title")
	sui.setCancelButtonText("@jedi_trials:button_cancel") -- Cancel
	sui.setOtherButtonText("@jedi_trials:button_lightside") -- 	Light Jedi Council
	sui.setOkButtonText("@jedi_trials:button_darkside") -- Dark Jedi Council
	sui.hideCancelButton()
	-- Other Button setup subscribe
	sui.setProperty("btnRevert", "OnPress", "RevertWasPressed=1\r\nparent.btnOk.press=t")
	sui.subscribeToPropertyForEvent(SuiEventType.SET_onClosedOk, "btnRevert", "RevertWasPressed")

	sui.sendTo(pPlayer)
end

function KnightTrials:handleCouncilChoice(pPlayer, pSui, eventIndex, ...)
	if (pPlayer == nil) then
		return
	end

	local cancelPressed = (eventIndex == 1)
	local args = {...}
	local lightSide = args[1]

	if (cancelPressed) then
		if (JediTrials:getJediCouncil(pPlayer) == nil or JediTrials:getJediCouncil(pPlayer) == 0) then
			CreatureObject(pPlayer):sendSystemMessage("You must choose a Jedi council to continue your Knight Trials.")
			self:sendCouncilChoiceSui(pPlayer)
		end
		return
	elseif (lightSide ~= nil) then -- Chose Light Side
		KnightTrials:doCouncilDecision(pPlayer, JediTrials.COUNCIL_LIGHT)
	elseif (eventIndex == 0) then -- Chose Dark Side
		KnightTrials:doCouncilDecision(pPlayer, JediTrials.COUNCIL_DARK)
	end
end

function KnightTrials:doCouncilDecision(pPlayer, choice)
	if (pPlayer == nil) then
		return
	end

	if (not JediTrials:isEligibleForKnightTrials(pPlayer)) then
		self:failTrialsIneligible(pPlayer)
		return
	end

	local playerFaction = CreatureObject(pPlayer):getFaction()
	local musicFile
	local successMsg

	if (choice == JediTrials.COUNCIL_LIGHT) then
		if (playerFaction == FACTIONIMPERIAL) then
			local sui = SuiMessageBox.new("KnightTrials", "noCallback")
			sui.setTitle("@jedi_trials:knight_trials_title")
			sui.setPrompt("@jedi_trials:faction_wrong_choice_light")
			sui.setOkButtonText("@jedi_trials:button_close")
			sui.hideCancelButton()
			sui.sendTo(pPlayer)
			return
		end

		musicFile = "sound/music_themequest_victory_rebel.snd"
		successMsg = "@jedi_trials:council_chosen_light"
	elseif (choice == JediTrials.COUNCIL_DARK) then
		if (playerFaction == FACTIONREBEL) then
			local sui = SuiMessageBox.new("KnightTrials", "noCallback")
			sui.setTitle("@jedi_trials:knight_trials_title")
			sui.setPrompt("@jedi_trials:faction_wrong_choice_dark")
			sui.setOkButtonText("@jedi_trials:button_close")
			sui.hideCancelButton()
			sui.sendTo(pPlayer)
			return
		end

		musicFile = "sound/music_themequest_victory_imperial.snd"
		successMsg = "@jedi_trials:council_chosen_dark"
	end

	JediTrials:setJediCouncil(pPlayer, choice)
	CreatureObject(pPlayer):playMusicMessage(musicFile)
	CreatureObject(pPlayer):sendSystemMessage(successMsg)
	local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer) + 1
	JediTrials:setTrialsCompleted(pPlayer, trialsCompleted)
	self:startNextKnightTrial(pPlayer)
end

function KnightTrials:notifyKilledHuntTarget(pPlayer, pVictim)
	if (pVictim == nil or pPlayer == nil) then
		return 0
	end

	local trialNumber = JediTrials:getCurrentTrial(pPlayer)

	if (trialNumber <= 0) then
		printLuaError("KnightTrials:notifyKilledHuntTarget, invalid trial for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber)
		return 1
	end

	local trialData = knightTrialQuests[trialNumber]

	if (trialData.trialType ~= TRIAL_HUNT and trialData.trialType ~= TRIAL_HUNT_FACTION) then
		return 1
	end

	local playerFaction = CreatureObject(pPlayer):getFaction()
	local playerCouncil = JediTrials:getJediCouncil(pPlayer)

	if ((playerFaction == FACTIONIMPERIAL and playerCouncil == JediTrials.COUNCIL_LIGHT) or (playerFaction == FACTIONREBEL and playerCouncil == JediTrials.COUNCIL_DARK)) then
		self:giveWrongFactionWarning(pPlayer, playerCouncil)
		return 0
	end

	local huntTarget = readScreenPlayData(pPlayer, "JediTrials", "huntTarget")
	local targetCount = tonumber(readScreenPlayData(pPlayer, "JediTrials", "huntTargetCount"))
	local targetGoal = tonumber(readScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal"))

	if (targetCount == nil) then
		printLuaError("KnightTrials:notifyKilledHuntTarget, nil targetCount for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. " (player killed target: " .. SceneObject(pVictim):getObjectName() .. "). Setting to 0.")
		writeScreenPlayData(pPlayer, "JediTrials", "huntTargetCount", 0)
		targetCount = 0
	end

	if (targetGoal == nil) then
		printLuaError("KnightTrials:notifyKilledHuntTarget, nil targetGoal for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. " (player killed target: " .. SceneObject(pVictim):getObjectName() .. "). Setting to " .. trialData.huntGoal .. ".")
		writeScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal", trialData.huntGoal)
		targetGoal = trialData.huntGoal
	end

	if (huntTarget == nil or huntTarget == "") then
		local newTarget = ""
		if (trialData.trialType == TRIAL_HUNT) then
			writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.huntTarget)
			newTarget = trialData.huntTarget
		else
			local councilChoice = JediTrials:getJediCouncil(pPlayer)

			if (councilChoice == JediTrials.COUNCIL_LIGHT) then
				writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.rebelTarget)
				newTarget = trialData.rebelTarget
			else
				writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.imperialTarget)
				newTarget = trialData.imperialTarget
			end
		end

		printLuaError("KnightTrials:notifyKilledHuntTarget, nil huntTarget for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. " (player killed target: " .. SceneObject(pVictim):getObjectName() .. "). Setting to " .. newTarget .. ".")
		huntTarget = newTarget
	end

	if (SceneObject(pVictim):getZoneName() ~= SceneObject(pPlayer):getZoneName() or not CreatureObject(pPlayer):isInRangeWithObject(pVictim, 80)) then
		return 0
	end

	local targetList = HelperFuncs:splitString(huntTarget, ";")

	if (huntTarget == SceneObject(pVictim):getObjectName() or HelperFuncs:tableContainsValue(targetList, SceneObject(pVictim):getObjectName())) then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:knight_trials_progress")
		targetCount = targetCount + 1
		writeScreenPlayData(pPlayer, "JediTrials", "huntTargetCount", targetCount)

		-- Award points for creature kill in PvE system (based on creature level)
		local creatureLevel = CreatureObject(pVictim):getLevel()
		local pointsAwarded = JediTrials:getPointsForCreatureLevel(creatureLevel)
		if (pointsAwarded > 0) then
			JediTrials:addKnightTrialPoints(pPlayer, pointsAwarded)
			-- Show point gain message to player
			local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
			local pointMessage = string.format("Knight Trials: +%d points (%d / 50000)", pointsAwarded, currentPoints)
			CreatureObject(pPlayer):sendSystemMessage(pointMessage)
		end

		if (targetCount >= targetGoal) then
			if (not JediTrials:isEligibleForKnightTrials(pPlayer)) then
				self:failTrialsIneligible(pPlayer)
				return 1
			end
			local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer) + 1
			JediTrials:setTrialsCompleted(pPlayer, trialsCompleted)
			self:startNextKnightTrial(pPlayer)
			return 1
		end
	end

	return 0
end

function KnightTrials:failTrialsIneligible(pPlayer)
	if (pPlayer == nil or JediTrials:isEligibleForKnightTrials(pPlayer)) then
		return
	end

	local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
	sui.setTitle("@jedi_trials:knight_trials_title")
	sui.setPrompt("@jedi_trials:knight_trials_being_removed")
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.sendTo(pPlayer)

	self:resetKnightTrialProgression(pPlayer)
end

function KnightTrials:showCurrentTrial(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local trialNumber = JediTrials:getCurrentTrial(pPlayer)

	local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer)

	local trialData = knightTrialQuests[trialNumber]

	-- If trialNumber is 0 or trialData is nil, just show PvE points progress
	-- This happens when Knight Trials are first activated (currentTrial = 0)
	if (trialNumber == 0 or trialData == nil) then
		local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
		local pointProgress = string.format("Knight Trials - PvE Progression\n\nYour Progress: %d / %d points\n\nHunt creatures across the galaxy to earn points. Stronger foes grant more points.\n\nAt 25,000 points, you will choose your Jedi Council (Light or Dark).\n\nAt 50,000 points, you will become a Jedi Knight!", currentPoints, KNIGHT_TRIALS_REQUIRED_POINTS)

		local sui = SuiMessageBox.new("KnightTrials", "noCallback")
		sui.setTitle("@jedi_trials:knight_trials_title")
		sui.setPrompt(pointProgress)
		sui.setOkButtonText("@jedi_trials:button_close")
		sui.hideCancelButton()
		sui.sendTo(pPlayer)
		return
	end

	-- Only skip if it's not the council choice trial
	-- Council choice trial (TRIAL_COUNCIL) should always show the council dialog when first encountered
	if (trialData.trialType ~= TRIAL_COUNCIL and trialsCompleted == trialNumber) then
		return
	end

	if (trialData.trialType == TRIAL_COUNCIL) then
		self:sendCouncilChoiceSui(pPlayer)
		return
	end

	local playerFaction = CreatureObject(pPlayer):getFaction()
	local playerCouncil = JediTrials:getJediCouncil(pPlayer)

	if (trialData.trialType == TRIAL_HUNT or trialData.trialType == TRIAL_HUNT_FACTION) then
		if ((playerFaction == FACTIONIMPERIAL and playerCouncil == JediTrials.COUNCIL_LIGHT) or (playerFaction == FACTIONREBEL and playerCouncil == JediTrials.COUNCIL_DARK)) then
			self:giveWrongFactionWarning(pPlayer, playerCouncil)
			return
		end
	end

	local huntTarget = readScreenPlayData(pPlayer, "JediTrials", "huntTarget")
	local targetCount = tonumber(readScreenPlayData(pPlayer, "JediTrials", "huntTargetCount"))
	local targetGoal = tonumber(readScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal"))

	if (targetCount == nil) then
		printLuaError("KnightTrials:showCurrentTrial, nil targetCount for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. ". Setting to 0.")
		writeScreenPlayData(pPlayer, "JediTrials", "huntTargetCount", 0)
		targetCount = 0
	end

	if (targetGoal == nil) then
		printLuaError("KnightTrials:showCurrentTrial, nil targetGoal for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. ". Setting to " .. trialData.huntGoal .. ".")
		writeScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal", trialData.huntGoal)
		targetGoal = trialData.huntGoal
	end

	if (huntTarget == nil or huntTarget == "") then
		local newTarget = ""
		if (trialData.trialType == TRIAL_HUNT) then
			writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.huntTarget)
			newTarget = trialData.huntTarget
		else
			local councilChoice = JediTrials:getJediCouncil(pPlayer)

			if (councilChoice == JediTrials.COUNCIL_LIGHT) then
				writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.rebelTarget)
				newTarget = trialData.rebelTarget
			else
				writeScreenPlayData(pPlayer, "JediTrials", "huntTarget", trialData.imperialTarget)
				newTarget = trialData.imperialTarget
			end
		end

		printLuaError("KnightTrials:showCurrentTrial, nil huntTarget for player: " .. SceneObject(pPlayer):getCustomObjectName() .. " on trial " .. trialNumber .. ". Setting to " .. newTarget .. ".")
		huntTarget = newTarget
	end

	local shrinePrompt = "@jedi_trials:" .. trialData.trialName

	if (trialData.trialType == TRIAL_HUNT_FACTION) then
		local councilChoice = JediTrials:getJediCouncil(pPlayer)

		if (councilChoice == JediTrials.COUNCIL_LIGHT) then
			shrinePrompt = shrinePrompt .. "_light"
		else
			shrinePrompt = shrinePrompt .. "_dark"
		end
	end

	-- Don't show the old quest message, just show PvE points progress
	-- shrinePrompt = getStringId(shrinePrompt)
	-- if (trialData.huntGoal ~= nil and trialData.huntGoal > 1) then
	--	shrinePrompt = shrinePrompt .. " " .. targetCount .. " of " .. trialData.huntGoal
	-- end

	-- Show only PvE point progress
	local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
	local pointProgress = string.format("PvE Progression: %d / %d points", currentPoints, KNIGHT_TRIALS_REQUIRED_POINTS)
	shrinePrompt = pointProgress

	local sui = SuiMessageBox.new("KnightTrials", "noCallback")
	sui.setTitle("@jedi_trials:knight_trials_title")
	sui.setPrompt(shrinePrompt)
	sui.setOkButtonText("@jedi_trials:button_close")
	sui.hideCancelButton()
	sui.sendTo(pPlayer)
end

function KnightTrials:setTrialShrine(pPlayer, pShrine)
	writeScreenPlayData(pPlayer, "JediTrials", "trialShrineID", SceneObject(pShrine):getObjectID())
end

function KnightTrials:unsetTrialShrine(pPlayer, pShrine)
	deleteScreenPlayData(pPlayer, "JediTrials", "trialShrineID")
end

function KnightTrials:getTrialShrine(pPlayer)
	local shrineID = tonumber(readScreenPlayData(pPlayer, "JediTrials", "trialShrineID"))

	if (shrineID == nil or shrineID == 0) then
		return nil
	end

	local pShrine = getSceneObject(shrineID)

	return pShrine
end

function KnightTrials:onPlayerLoggedIn(pPlayer)
	printLuaError("KnightTrials:onPlayerLoggedIn called!")

	if (pPlayer == nil) then
		printLuaError("KnightTrials:onPlayerLoggedIn - pPlayer is nil!")
		return
	end

	printLuaError("KnightTrials:onPlayerLoggedIn - Player: " .. SceneObject(pPlayer):getCustomObjectName())

	-- Register points observer only for eligible players (Padawan rank + meets skill point requirements)
	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02") and not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03") and JediTrials:isEligibleForKnightTrials(pPlayer)) then
		printLuaError("KnightTrials:onPlayerLoggedIn - Registering observer for player: " .. SceneObject(pPlayer):getCustomObjectName())
		-- First drop any existing observer to prevent duplicates
		dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
		-- Now register the observer
		createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
	else
		printLuaError("KnightTrials:onPlayerLoggedIn - NOT registering observer. Has rank_02: " .. tostring(CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) .. ", Has rank_03: " .. tostring(CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) .. ", Eligible: " .. tostring(JediTrials:isEligibleForKnightTrials(pPlayer)))
	end

	-- Don't auto-start Knight Trials on login - player must activate at shrine
	-- if (JediTrials:isEligibleForKnightTrials(pPlayer) and not JediTrials:isOnKnightTrials(pPlayer)) then
	-- 	KnightTrials:startKnightTrials(pPlayer)
	-- elseif (JediTrials:isOnKnightTrials(pPlayer)) then
	if (JediTrials:isOnKnightTrials(pPlayer)) then
		local trialNumber = JediTrials:getCurrentTrial(pPlayer)

		if (trialNumber <= 0) then
			return
		end

		local trialData = knightTrialQuests[trialNumber]

		if (trialData.trialType == TRIAL_HUNT or trialData.trialType == TRIAL_HUNT_FACTION) then
			dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledHuntTarget", pPlayer)
			createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledHuntTarget", pPlayer)
		end
	end
end

function KnightTrials:giveWrongFactionWarning(pPlayer, councilType)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("KnightTrials", "noCallback")
	sui.setTitle("@jedi_trials:knight_trials_title")

	if (councilType == JediTrials.COUNCIL_LIGHT) then
		sui.setPrompt("@jedi_trials:faction_wrong_light") -- To become a Light Jedi, you cannot be a member of the Empire. You must revoke your status as an Imperial in order to continue.
	else
		sui.setPrompt("@jedi_trials:faction_wrong_dark") -- To become a Dark Jedi, you cannot be a member of the Rebel Alliance. You must revoke your status as a Rebel in order to continue.
	end

	sui.setOkButtonText("@jedi_trials:button_close")
	sui.hideCancelButton()
	sui.sendTo(pPlayer)
end

-- Single authoritative reset for Knight Trial progression. Wipes every piece of
-- Knight Trial state (PvE points, council/alignment choice, trial phase, hunt
-- target, shrine assignment, kill observers) so the next Knight attempt is a
-- fresh run that must begin again at the normal starting point (activating at
-- a Force Shrine).
--
-- Called whenever a player's current Knight Trial attempt must be abandoned:
--   - Voluntarily surrendering Jedi Knight rank (VillageJediManager:onSkillRevoked)
--     in order to switch Force alignment.
--   - Losing Knight Trial eligibility mid-attempt (failTrialsIneligible).
--   - The Force Shrine "meditate" safety net catching a player who still has
--     completedTrials set but no longer holds force_title_jedi_rank_03
--     (ForceShrineMenuComponent:doMeditate).
--
-- Idempotent: safe to call on a player with no trial state, with partial or
-- corrupted trial data, or more than once in a row - later calls are no-ops
-- other than re-confirming observers are dropped. Returns true if the player
-- actually had Knight Trial progression to clear (used by callers to decide
-- whether a "you have been reset" message is warranted).
function KnightTrials:resetKnightTrialProgression(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local playerName = SceneObject(pPlayer):getCustomObjectName()
	local playerID = SceneObject(pPlayer):getObjectID()

	local previousCouncil = JediTrials:getJediCouncil(pPlayer)
	local previousPhase = JediTrials:getCurrentTrial(pPlayer)
	local previousPoints = JediTrials:getKnightTrialPoints(pPlayer)
	local wasStarted = tonumber(readScreenPlayData(pPlayer, "KnightTrials", "startedTrials")) == 1
	local wasCompleted = tonumber(readScreenPlayData(pPlayer, "KnightTrials", "completedTrials")) == 1

	local hadProgression = wasStarted or wasCompleted or (previousPoints ~= nil and previousPoints > 0)
		or (previousCouncil ~= nil and previousCouncil ~= 0)

	-- Drop any leftover kill observers first so a kill landing mid-reset can't
	-- award points or hunt credit toward the attempt we're about to erase.
	dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
	dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledHuntTarget", pPlayer)

	-- PvE points are a Knight Trial-specific progression counter, not a shared
	-- lifetime PvE/PvP statistic, so it's safe to zero out here without
	-- touching any other player statistics.
	deleteScreenPlayData(pPlayer, "KnightTrials", "accruedPoints")

	-- Clears KnightTrials trialsCompleted/startedTrials/activatedAtShrine, the
	-- JediTrials council (Light/Dark alignment) choice, the current trial
	-- index, and the trial failure count.
	JediTrials:resetTrialData(pPlayer, "knight")
	deleteScreenPlayData(pPlayer, "KnightTrials", "completedTrials")

	-- Clear any in-progress hunt target and the assigned trial shrine so a
	-- fresh attempt starts clean rather than resuming the old hunt/shrine.
	self:unsetTrialShrine(pPlayer)
	deleteScreenPlayData(pPlayer, "JediTrials", "huntTarget")
	deleteScreenPlayData(pPlayer, "JediTrials", "huntTargetCount")
	deleteScreenPlayData(pPlayer, "JediTrials", "huntTargetGoal")

	-- Defensive: clear any leftover FRS council/rank tied to the old Knight
	-- alignment. The native FRS system (FrsManagerImplementation::
	-- handleSkillRevoked) already does this whenever the player actually
	-- holds an FRS rank skill; this covers a Knight who never engaged the FRS
	-- ladder, where that native cleanup has nothing to surrender and never runs.
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil and not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		PlayerObject(pGhost):setFrsCouncil(0)
		PlayerObject(pGhost):setFrsRank(-1)
	end

	printLuaError("KnightTrials:resetKnightTrialProgression - Player: " .. playerName .. " (" .. playerID ..
		"), previous council: " .. tostring(previousCouncil) .. ", previous phase: " .. tostring(previousPhase) ..
		", previous points: " .. tostring(previousPoints) .. ", hadProgression: " .. tostring(hadProgression) ..
		" - Knight Trial state reset complete.")

	return hadProgression
end

-- Global kill observer for PvE points (awards points for ANY creature killed, independent of trials)
-- Note: pPlayer parameter is actually the player this observer was registered on
function KnightTrials:notifyKilledForPoints(pPlayer, pVictim)
	if (pVictim == nil or pPlayer == nil) then
		printLuaError("KnightTrials:notifyKilledForPoints - nil player or victim")
		return 0
	end

	-- The observer fires for the registered player only - so pPlayer should always be the intended player
	-- Double-check that pPlayer is actually a player creature (not a pet or NPC)
	if (not SceneObject(pPlayer):isPlayerCreature()) then
		printLuaError("KnightTrials:notifyKilledForPoints - registered observer object is not a player")
		return 0
	end

	-- Only award points if player has Padawan rank and hasn't gotten Knight rank
	if (not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) then
		printLuaError("KnightTrials:notifyKilledForPoints - player doesn't have Padawan rank")
		return 0
	end

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		printLuaError("KnightTrials:notifyKilledForPoints - player already completed Knight Trials (has rank_03)")
		return 0
	end

	-- Check if player meets Knight Trial eligibility requirements (206+ Jedi skill points)
	if (not JediTrials:isEligibleForKnightTrials(pPlayer)) then
		printLuaError("KnightTrials:notifyKilledForPoints - player not eligible for Knight Trials (insufficient Jedi skill points)")
		return 0
	end

	-- Check if player has activated Knight Trials at a Force Shrine
	local activatedAtShrine = tonumber(readScreenPlayData(pPlayer, "KnightTrials", "activatedAtShrine"))
	if (activatedAtShrine ~= 1) then
		printLuaError("KnightTrials:notifyKilledForPoints - player has not activated Knight Trials at a shrine")
		return 0
	end

	-- Verify the player participated in the kill (was within 80 meters of the creature)
	-- This ensures points are only awarded for creatures the player helped kill
	if (not playerParticipatedInKill(pPlayer, pVictim)) then
		printLuaError("KnightTrials:notifyKilledForPoints - player did not participate in kill of creature: " .. SceneObject(pVictim):getObjectName())
		return 0
	end

	-- Award points for creature kill in PvE system (based on creature level)
	local creatureLevel = CreatureObject(pVictim):getLevel()
	printLuaError("KnightTrials:notifyKilledForPoints - creature level: " .. creatureLevel .. ", victim: " .. SceneObject(pVictim):getObjectName())

	local pointsAwarded = JediTrials:getPointsForCreatureLevel(creatureLevel)
	printLuaError("KnightTrials:notifyKilledForPoints - points awarded: " .. pointsAwarded)

	if (pointsAwarded > 0) then
		local creatureName = SceneObject(pVictim):getObjectName()

		-- Get current points before adding
		local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
		printLuaError("KnightTrials:notifyKilledForPoints - current points: " .. currentPoints)

		-- Award the points
		JediTrials:addKnightTrialPoints(pPlayer, pointsAwarded)

		-- Get new points after adding
		local newPoints = JediTrials:getKnightTrialPoints(pPlayer)
		printLuaError("KnightTrials:notifyKilledForPoints - new points: " .. newPoints)

		-- Send detailed system message with point gain and total
		local pointMessage = string.format("Knight Trials: +%d points (%d / %d)", pointsAwarded, newPoints, KNIGHT_TRIALS_REQUIRED_POINTS)
		CreatureObject(pPlayer):sendSystemMessage(pointMessage)
	else
		printLuaError("KnightTrials:notifyKilledForPoints - no points awarded for this creature level")
	end

	return 0
end

-- Player: /ktStatus (CheckForceStatusCommand-style slash command, C++ KtStatusCommand -> here).
function ktStatusRun(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		CreatureObject(pPlayer):sendSystemMessage("You have completed the Knight Trials and hold the rank of Jedi Knight.")
		return
	end

	-- Consider the player "on trial" if the state machine says so, OR they've activated at a shrine,
	-- OR they've already accrued points -- covers players whose startedTrials flag didn't get set
	-- by whatever activation path they came through, so points aren't silently hidden.
	local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
	local activatedAtShrine = tonumber(readScreenPlayData(pPlayer, "KnightTrials", "activatedAtShrine")) == 1

	if (JediTrials:isOnKnightTrials(pPlayer) or activatedAtShrine or currentPoints > 0) then
		local statusMsg = string.format("Knight Trials PvE Progression: %d / %d points", currentPoints, KNIGHT_TRIALS_REQUIRED_POINTS)

		local council = JediTrials:getJediCouncil(pPlayer)
		if (council == JediTrials.COUNCIL_LIGHT) then
			statusMsg = statusMsg .. " (Light Council)"
		elseif (council == JediTrials.COUNCIL_DARK) then
			statusMsg = statusMsg .. " (Dark Council)"
		end

		CreatureObject(pPlayer):sendSystemMessage(statusMsg)
		return
	end

	if (JediTrials:isEligibleForKnightTrials(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You are eligible for the Knight Trials. Seek out a Force Shrine to begin.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("You are not currently on the Knight Trials.")
end
