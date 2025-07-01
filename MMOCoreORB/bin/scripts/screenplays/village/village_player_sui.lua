local Logger = require("utils.logger")

VillagePlayerSui = ScreenPlay:new {
}

function VillagePlayerSui:showMainPage(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	-- CHANGE: Removed access check - anyone can use this command now

	-- CHANGE: Only get current phase and time information
	local curPhase = VillageJediManagerTownship:getCurrentPhase()
	local nextPhaseChange = VillageJediManagerTownship.getNextPhaseChangeTime()
	local phaseTimeLeft = self:getPhaseDuration()

	-- CHANGE: Simplified prompt with only phase and time information
	local suiPrompt = " \\#pcontrast1 " .. "Current Phase:" .. " \\#pcontrast2 " .. curPhase .. "\n"
	suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Next Phase Change: " .. " \\#pcontrast2 " .. os.date("%c", nextPhaseChange)  .. "\n"
	suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Phase Time Left: " .. " \\#pcontrast2 " .. phaseTimeLeft

	-- CHANGE: Simple message box instead of list box (no menu options)
	local sui = SuiMessageBox.new("VillagePlayerSui", "closeCallback")
	sui.setTitle("Village Information")
	sui.setPrompt(suiPrompt)
	sui.setOkButtonText("Close")

	sui.sendTo(pPlayer)
end

-- CHANGE: Simple callback that just closes the window
function VillagePlayerSui:closeCallback(pPlayer, pSui, eventIndex, args)
	-- Just close the window, no additional functionality needed
	return
end

-- CHANGE: Keep the helper functions for time calculation
function VillagePlayerSui:getPhaseDuration()
	local eventID = getServerEventID("VillagePhaseChange")

	if (eventID == nil) then
		return "Unknown"
	end

	return self:getTimeString(getServerEventTimeLeft(eventID))
end

function VillagePlayerSui:getTimeString(miliTime)
	local timeLeft = miliTime / 1000
	local daysLeft = math.floor(timeLeft / (24 * 60 * 60))
	local hoursLeft = math.floor((timeLeft / 3600) % 24)
	local minutesLeft = math.floor((timeLeft / 60) % 60)
	local secondsLeft = math.floor(timeLeft % 60)

	return daysLeft .. "d " .. hoursLeft .. "h " .. minutesLeft .. "m " .. secondsLeft .. "s"
end