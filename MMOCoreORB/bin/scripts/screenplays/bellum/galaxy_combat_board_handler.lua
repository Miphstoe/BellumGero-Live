GalaxyCombatBoardHandler = {
	MENU_OPTIONS = {
		{ label = "Tier 1 - Local Threat Contracts", action = "tier", tier = 1 },
		{ label = "Tier 2 - Frontier Hunt Contracts", action = "tier", tier = 2 },
		{ label = "Tier 3 - Dangerous Prey Contracts", action = "tier", tier = 3 },
		{ label = "Tier 4 - Elite Target Contracts", action = "tier", tier = 4 },
		{ label = "Tier 5 - Apex Threat Contracts", action = "tier", tier = 5 },
		{ label = "Check Progress", action = "progress" },
		{ label = "Complete Contract", action = "complete" },
		{ label = "Abandon Contract", action = "abandon" },
	},
}

function GalaxyCombatBoardHandler:openMainMenu(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiListBox.new("GalaxyCombatBoardHandler", "mainMenuCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Galaxy Combat Board")
	sui.setPrompt(GalaxyCombatBoard:getMenuPrompt(pPlayer))

	for i = 1, #self.MENU_OPTIONS, 1 do
		sui.add(self.MENU_OPTIONS[i].label, "")
	end

	sui.sendTo(pPlayer)
end

function GalaxyCombatBoardHandler:mainMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1 or args == "-1") then
		return
	end

	local selectedIndex = tonumber(args) + 1
	local option = self.MENU_OPTIONS[selectedIndex]

	if (option == nil) then
		return
	end

	if (option.action == "tier") then
		GalaxyCombatBoard:assignRandomContract(pPlayer, option.tier)
		return
	end

	if (option.action == "progress") then
		self:showInfo(pPlayer, "Contract Progress", GalaxyCombatBoard:getProgressReport(pPlayer))
		return
	end

	if (option.action == "complete") then
		GalaxyCombatBoard:completeContract(pPlayer)
		return
	end

	if (option.action == "abandon") then
		GalaxyCombatBoard:abandonContract(pPlayer)
		return
	end
end

function GalaxyCombatBoardHandler:showInfo(pPlayer, title, body)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("GalaxyCombatBoardHandler", "noCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle(title)
	sui.setPrompt(body)
	sui.sendTo(pPlayer)
end

function GalaxyCombatBoardHandler:noCallback()
	return
end

GalaxyCombatBoardTerminalMenuComponent = {}

function GalaxyCombatBoardTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(20, 3, "Access Galaxy Combat Board")
end

function GalaxyCombatBoardTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (selectedID == 20 and pPlayer ~= nil) then
		GalaxyCombatBoardHandler:openMainMenu(pPlayer)
	end

	return 0
end
