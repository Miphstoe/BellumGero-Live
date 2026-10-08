--[[
    Bellum Gero Hub - Character Name Change Service (1,000,000 credits, bank)

    Sequential SUI flow (the stock client input box has a single text field):
        1. First Name input   (required)
        2. Last Name input    (optional, blank = no surname)
        3. Confirmation list  (Confirm / Back / Cancel)

    All validation, the name claim, the rename and the payment are performed in
    C++ (CharacterRenameManager) by creature:purchaseCharacterRename(), which
    revalidates everything server-side. Lua only collects input and shows results.

    Stale/duplicate callback protection: every flow gets a nonce stored in the
    player's screenplay data and in each SUI page's server-side stored data. A
    callback whose nonce does not match the current one is ignored, and the
    nonce is cleared before the purchase call, so a second Confirm does nothing.
]]--

BgCharacterRename = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "BgCharacterRename",
	FEE = 1000000,

	RESULT_SUCCESS = 0,
	RESULT_INVALID = 1,
	RESULT_UNAVAILABLE = 2,
	RESULT_INSUFFICIENT_FUNDS = 3,
	RESULT_UNSAFE_STATE = 4,
	RESULT_FAILED = 5,
	RESULT_SAME_NAME = 6,
}

local SP = "BgCharacterRename"

function BgCharacterRename:newSession(pPlayer)
	local nonce = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
	writeScreenPlayData(pPlayer, SP, "nonce", nonce)
	return nonce
end

function BgCharacterRename:endSession(pPlayer)
	deleteScreenPlayData(pPlayer, SP, "nonce")
end

-- Returns the page's stored data table accessor if the callback belongs to the live session
function BgCharacterRename:getValidPageData(pPlayer, pSui)
	if pPlayer == nil or pSui == nil then
		return nil
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()
	if pPageData == nil then
		return nil
	end

	local pageData = LuaSuiPageData(pPageData)
	local nonce = pageData:getStoredData("nonce")
	local current = readScreenPlayData(pPlayer, SP, "nonce")

	if nonce == nil or nonce == "" or current == nil or current == "" or nonce ~= current then
		return nil
	end

	return pageData
end

function BgCharacterRename:trim(value)
	if value == nil then
		return ""
	end
	return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Entry point from the Bellum Gero Hub conversation
function BgCharacterRename:start(pPlayer)
	if pPlayer == nil then
		return
	end

	local player = CreatureObject(pPlayer)

	if player:getBankCredits() < self.FEE then
		player:sendSystemMessage("You need 1,000,000 credits in your bank account to change your character's name.")
		return
	end

	-- An empty request only reports state problems (combat, logging out, etc.)
	local code, message = player:checkCharacterRename("", "")
	if code == self.RESULT_UNSAFE_STATE then
		player:sendSystemMessage(message)
		return
	end

	local nonce = self:newSession(pPlayer)
	self:showFirstNameInput(pPlayer, nonce, "", "", nil)
end

function BgCharacterRename:showFirstNameInput(pPlayer, nonce, firstName, lastName, errorMessage)
	local player = CreatureObject(pPlayer)

	local prompt = ""
	if errorMessage ~= nil and errorMessage ~= "" then
		prompt = "\\#FF4444" .. errorMessage .. "\\#.\n\n"
	end

	prompt = prompt ..
		"Current Name: " .. SceneObject(pPlayer):getCustomObjectName() .. "\n\n" ..
		"Step 1 of 3 - Enter your new FIRST name (required).\n\n" ..
		"Letters only, with at most one ' or - inside the name. No spaces, numbers or symbols. " ..
		"Your first name must not be used by any other character.\n\n" ..
		"Service Fee: 1,000,000 credits (bank). Credits are only deducted after your name change has been successfully completed."

	local sui = SuiInputBox.new(SP, "firstNameCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Bellum Gero Hub - Character Name Change")
	sui.setPrompt(prompt)
	sui.setOkButtonText("Next")
	sui.setCancelButtonText("Cancel")
	sui.setProperty("txtInput", "MaxLength", "24")
	if firstName ~= nil and firstName ~= "" then
		sui.setProperty("txtInput", "Text", firstName)
	end
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("lastName", lastName or "")
	sui.sendTo(pPlayer)
end

function BgCharacterRename:firstNameCallback(pPlayer, pSui, eventIndex, args)
	local pageData = self:getValidPageData(pPlayer, pSui)
	if pageData == nil then
		return
	end

	local player = CreatureObject(pPlayer)
	local nonce = pageData:getStoredData("nonce")

	if eventIndex == 1 then
		self:endSession(pPlayer)
		player:sendSystemMessage("Character name change cancelled. No credits have been charged.")
		return
	end

	local firstName = self:trim(args)
	local lastName = pageData:getStoredData("lastName") or ""

	-- Validate the first name on its own (no surname) so errors are reported at this step
	local code, message = player:checkCharacterRename(firstName, "")

	if code == self.RESULT_UNSAFE_STATE or code == self.RESULT_INSUFFICIENT_FUNDS then
		self:endSession(pPlayer)
		player:sendSystemMessage(message)
		return
	end

	if code == self.RESULT_INVALID or code == self.RESULT_UNAVAILABLE or code == self.RESULT_FAILED then
		self:showFirstNameInput(pPlayer, nonce, firstName, lastName, message)
		return
	end

	-- RESULT_SUCCESS, or RESULT_SAME_NAME (same first name is fine if the surname changes)
	self:showLastNameInput(pPlayer, nonce, firstName, lastName, nil)
end

function BgCharacterRename:showLastNameInput(pPlayer, nonce, firstName, lastName, errorMessage)
	local prompt = ""
	if errorMessage ~= nil and errorMessage ~= "" then
		prompt = "\\#FF4444" .. errorMessage .. "\\#.\n\n"
	end

	prompt = prompt ..
		"Current Name: " .. SceneObject(pPlayer):getCustomObjectName() .. "\n" ..
		"Requested First Name: " .. firstName .. "\n\n" ..
		"Step 2 of 3 - Enter your new LAST name.\n\n" ..
		"The last name is optional. Leave the field blank and press Next if you do not want a last name. " ..
		"Some species do not permit last names."

	local sui = SuiInputBox.new(SP, "lastNameCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Bellum Gero Hub - Character Name Change")
	sui.setPrompt(prompt)
	sui.setOkButtonText("Next")
	sui.setCancelButtonText("Cancel")
	sui.setProperty("txtInput", "MaxLength", "24")
	if lastName ~= nil and lastName ~= "" then
		sui.setProperty("txtInput", "Text", lastName)
	end
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("firstName", firstName)
	sui.sendTo(pPlayer)
end

function BgCharacterRename:lastNameCallback(pPlayer, pSui, eventIndex, args)
	local pageData = self:getValidPageData(pPlayer, pSui)
	if pageData == nil then
		return
	end

	local player = CreatureObject(pPlayer)
	local nonce = pageData:getStoredData("nonce")

	if eventIndex == 1 then
		self:endSession(pPlayer)
		player:sendSystemMessage("Character name change cancelled. No credits have been charged.")
		return
	end

	local firstName = pageData:getStoredData("firstName") or ""
	local lastName = self:trim(args)

	local code, message, fullName = player:checkCharacterRename(firstName, lastName)

	if code == self.RESULT_UNSAFE_STATE or code == self.RESULT_INSUFFICIENT_FUNDS then
		self:endSession(pPlayer)
		player:sendSystemMessage(message)
		return
	end

	if code == self.RESULT_UNAVAILABLE then
		-- Availability depends on the first name only
		self:showFirstNameInput(pPlayer, nonce, firstName, lastName, message)
		return
	end

	if code ~= self.RESULT_SUCCESS then
		self:showLastNameInput(pPlayer, nonce, firstName, lastName, message)
		return
	end

	self:showConfirmation(pPlayer, nonce, firstName, lastName, fullName)
end

function BgCharacterRename:showConfirmation(pPlayer, nonce, firstName, lastName, fullName)
	local currentName = SceneObject(pPlayer):getCustomObjectName()
	local displayLast = lastName
	if displayLast == nil or displayLast == "" then
		displayLast = "(none)"
	end

	local sui = SuiListBox.new(SP, "confirmCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Bellum Gero Hub - Confirm Name Change")
	sui.setPrompt(
		"Step 3 of 3 - Are you sure you want to change your character's name to " .. fullName ..
		"? This action will cost 1,000,000 credits.\n\n" ..
		"Credits are deducted from your bank only after the name change has been successfully completed.\n\n" ..
		"Press Confirm to proceed, Back to edit the name, or Cancel to stop."
	)
	sui.add("Current Name: " .. currentName, "")
	sui.add("Requested First Name: " .. firstName, "")
	sui.add("Requested Last Name: " .. displayLast, "")
	sui.add("New Character Name: " .. fullName, "")
	sui.add("Service Fee: 1,000,000 Credits (bank)", "")
	sui.showOtherButton()
	sui.setOtherButtonText("Back")
	sui.setOkButtonText("Confirm")
	sui.setCancelButtonText("Cancel")
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("firstName", firstName)
	sui.setStoredData("lastName", lastName or "")
	sui.sendTo(pPlayer)
end

function BgCharacterRename:confirmCallback(pPlayer, pSui, eventIndex, rowIndex, otherPressed)
	local pageData = self:getValidPageData(pPlayer, pSui)
	if pageData == nil then
		return
	end

	local player = CreatureObject(pPlayer)
	local nonce = pageData:getStoredData("nonce")
	local firstName = pageData:getStoredData("firstName") or ""
	local lastName = pageData:getStoredData("lastName") or ""

	-- otherPressed is sent by the client as a string
	if otherPressed == "true" then
		self:showFirstNameInput(pPlayer, nonce, firstName, lastName, nil)
		return
	end

	if eventIndex == 1 then
		self:endSession(pPlayer)
		player:sendSystemMessage("Character name change cancelled. No credits have been charged.")
		return
	end

	-- Consume the session before the purchase: any duplicate/stale Confirm is ignored
	self:endSession(pPlayer)

	-- Names come from server-side SUI page data, and C++ revalidates everything
	local code, message = player:purchaseCharacterRename(firstName, lastName)

	if code == self.RESULT_SUCCESS then
		player:sendSystemMessage(message)

		local sui = SuiMessageBox.new(SP, "noCallback")
		sui.setTitle("Bellum Gero Hub - Name Changed")
		sui.setPrompt(message .. "\n\n" ..
			"Your new name is active on the server now. Please log out and back in at your convenience so " ..
			"your own client (chat identity, friends list and character select screen) fully refreshes.")
		sui.hideCancelButton()
		sui.sendTo(pPlayer)
		return
	end

	if code == self.RESULT_INVALID or code == self.RESULT_UNAVAILABLE or code == self.RESULT_SAME_NAME then
		-- Let the player try again with a fresh session; nothing was charged
		local newNonce = self:newSession(pPlayer)
		self:showFirstNameInput(pPlayer, newNonce, firstName, lastName, message)
		return
	end

	-- Insufficient funds, unsafe state or failure: nothing was charged
	player:sendSystemMessage(message)
end

function BgCharacterRename:noCallback(pPlayer, pSui, eventIndex, args)
end
