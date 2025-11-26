local ObjectManager = require("managers.object.object_manager")

KnightTrials = ScreenPlay:new {}

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
		CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:council_choice_delayed")
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

	JediTrials:resetTrialData(pPlayer, "knight")
	self:unsetTrialShrine(pPlayer)
end

function KnightTrials:showCurrentTrial(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local trialNumber = JediTrials:getCurrentTrial(pPlayer)

	local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer)

	if (trialsCompleted == trialNumber) then
		return
	end

	local trialData = knightTrialQuests[trialNumber]

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

	-- Always register points observer for any player with Padawan rank who hasn't gotten Knight rank
	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02") and not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		printLuaError("KnightTrials:onPlayerLoggedIn - Registering observer for player: " .. SceneObject(pPlayer):getCustomObjectName())
		createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
	else
		printLuaError("KnightTrials:onPlayerLoggedIn - NOT registering observer. Has rank_02: " .. tostring(CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) .. ", Has rank_03: " .. tostring(CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")))
	end

	if (JediTrials:isEligibleForKnightTrials(pPlayer) and not JediTrials:isOnKnightTrials(pPlayer)) then
		KnightTrials:startKnightTrials(pPlayer)
	elseif (JediTrials:isOnKnightTrials(pPlayer)) then
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

function KnightTrials:resetCompletedTrialsToStart(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Drop the global points observer
	dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)

	JediTrials:resetTrialData(pPlayer, "knight")
	deleteScreenPlayData(pPlayer, "KnightTrials", "completedTrials")

	JediTrials:setStartedTrials(pPlayer)
	JediTrials:setTrialsCompleted(pPlayer, 0)
	JediTrials:setCurrentTrial(pPlayer, 0)
end

-- Global kill observer for PvE points (awards points for ANY creature killed, independent of trials)
function KnightTrials:notifyKilledForPoints(pKiller, pVictim)
	if (pVictim == nil or pKiller == nil) then
		printLuaError("KnightTrials:notifyKilledForPoints - nil killer or victim")
		return 0
	end

	-- pKiller might be a pet or NPC, so resolve the actual player
	local pPlayer = pKiller
	if (not SceneObject(pKiller):isPlayerCreature()) then
		-- If killer is not a player, try to get the owner
		local ko = CreatureObject(pKiller)
		if (ko ~= nil and ko.getOwner ~= nil) then
			pPlayer = ko:getOwner()
		end

		-- If still not a player, return
		if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
			printLuaError("KnightTrials:notifyKilledForPoints - killer is not a player and has no player owner")
			return 0
		end
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
