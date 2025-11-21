----------------------------------------------------------------------
-- Player Bounty System
-- Allows players to place bounties on their killers
----------------------------------------------------------------------

local ObjectManager = require("managers.object.object_manager")

PlayerBountySystem = ScreenPlay:new {
	-- Configuration (can be overridden in mission_manager.lua)
	minimumBounty = 1000,           -- 1,000 credits minimum
	maximumBounty = 1000000,        -- 1,000,000 credits maximum
	pvpOnly = true,                 -- Only allow bounties on PvP kills (not duels)
	cooldownTime = 3600000,         -- 1 hour cooldown per killer (milliseconds)
	notifyTarget = true,            -- Notify killer when bounty is placed
	preventDuelBounties = true,     -- Prevent bounties from duel kills
	preventSameGuild = false,       -- Prevent guild members from placing bounties on each other
	enabled = true,                 -- Master enable/disable switch
}

registerScreenPlay("PlayerBountySystem", true)

function PlayerBountySystem:start()
	if not self.enabled then
		return
	end

	-- Load configuration from mission_manager.lua if available
	self:loadConfiguration()

	-- Register player observers
	self:registerPlayerObservers()
end

function PlayerBountySystem:loadConfiguration()
	-- Load configuration from mission_manager.lua if available
	if playerPlacedBounties ~= nil then
		self.enabled = playerPlacedBounties.enabled
		self.minimumBounty = playerPlacedBounties.minimumBounty
		self.maximumBounty = playerPlacedBounties.maximumBounty
		self.pvpOnly = playerPlacedBounties.pvpOnly
		self.cooldownTime = playerPlacedBounties.cooldownPerKiller
		self.notifyTarget = playerPlacedBounties.notifyTarget
		self.preventDuelBounties = playerPlacedBounties.preventDuelBounties
		self.preventSameGuild = playerPlacedBounties.preventSameGuild
	end
end

function PlayerBountySystem:registerPlayerObservers()
	-- This will be called when players log in via screenplays.lua
	-- We register the PLAYERKILLED observer for all players
end

function PlayerBountySystem:onPlayerLoggedIn(pPlayer)
	if pPlayer == nil or not self.enabled then
		return
	end

	-- Register PLAYERKILLED observer
	createObserver(PLAYERKILLED, "PlayerBountySystem", "onPlayerKilled", pPlayer)
end

function PlayerBountySystem:onPlayerKilled(pVictim, pKiller)
	if pVictim == nil or pKiller == nil or not self.enabled then
		return 0
	end

	-- Validation: Killer must be a player
	if not SceneObject(pKiller):isPlayerCreature() then
		return 0
	end

	local victimID = SceneObject(pVictim):getObjectID()
	local killerID = SceneObject(pKiller):getObjectID()

	-- Validation: No bounties on suicide
	if killerID == victimID then
		return 0
	end

	-- Validation: Check if this was a duel kill (optional)
	if self.preventDuelBounties then
		-- If victim and killer were in a duel, don't show popup
		-- The duel system clears duel list on death, so we can't easily check this
		-- This would need to be tracked separately if desired
	end

	-- Validation: Check cooldown (prevent spam)
	local cooldownKey = victimID .. ":bounty_cooldown:" .. killerID
	local cooldownExpiry = readData(cooldownKey)

	if cooldownExpiry ~= nil and cooldownExpiry > os.time() then
		-- Still on cooldown for this specific killer
		return 0
	end

	-- Validation: Check if same guild (optional)
	if self.preventSameGuild then
		local victimGuildID = CreatureObject(pVictim):getGuildID()
		local killerGuildID = CreatureObject(pKiller):getGuildID()

		if victimGuildID ~= 0 and victimGuildID == killerGuildID then
			-- Same guild, don't allow bounty
			return 0
		end
	end

	-- All validations passed, show bounty placement popup
	self:showBountyConfirmationPopup(pVictim, pKiller)

	return 0
end

function PlayerBountySystem:showBountyConfirmationPopup(pVictim, pKiller)
	if pVictim == nil or pKiller == nil then
		return
	end

	local sui = SuiMessageBox.new("PlayerBountySystem", "confirmBountyCallback")

	sui.setTitle("Place Bounty")

	local killerName = CreatureObject(pKiller):getFirstName()
	local promptText = "You were killed by " .. killerName .. ".\n\n"
	promptText = promptText .. "Would you like to place a bounty on their head?\n\n"
	promptText = promptText .. "Bounty hunters will be able to hunt them down for a reward."

	sui.setPrompt(promptText)
	sui.setOkButtonText("Yes")
	sui.setCancelButtonText("No")

	-- Store killer ID for callback
	sui.setTargetNetworkId(SceneObject(pKiller):getObjectID())

	sui.sendTo(pVictim)
end

function PlayerBountySystem:confirmBountyCallback(pVictim, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if cancelPressed or pVictim == nil then
		return
	end

	-- Get killer ID from stored data
	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()
	if pPageData == nil then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local killerID = suiPageData:getTargetNetworkId()
	local pKiller = getSceneObject(killerID)

	if pKiller == nil or not SceneObject(pKiller):isPlayerCreature() then
		CreatureObject(pVictim):sendSystemMessage("Target is no longer available.")
		return
	end

	-- Show amount input popup
	self:showBountyAmountInput(pVictim, pKiller)
end

function PlayerBountySystem:showBountyAmountInput(pVictim, pKiller)
	if pVictim == nil or pKiller == nil then
		return
	end

	local victimID = SceneObject(pVictim):getObjectID()
	local killerID = SceneObject(pKiller):getObjectID()

	-- Store killer ID in shared memory for callback to retrieve
	writeData(victimID .. ":bounty_target", killerID)

	local sui = SuiInputBox.new("PlayerBountySystem", "bountyAmountCallback")

	sui.setTitle("Bounty Amount")

	local killerName = CreatureObject(pKiller):getFirstName()
	local victimCash = CreatureObject(pVictim):getCashCredits()
	local victimBank = CreatureObject(pVictim):getBankCredits()
	local totalCredits = victimCash + victimBank

	local promptText = "Enter the bounty amount to place on " .. killerName .. ".\n\n"
	promptText = promptText .. "Your Available Credits: " .. totalCredits .. " cr\n"
	promptText = promptText .. "Minimum Bounty: " .. self.minimumBounty .. " cr\n"
	promptText = promptText .. "Maximum Bounty: " .. self.maximumBounty .. " cr\n\n"
	promptText = promptText .. "Credits will be deducted from your inventory first, then from your bank."

	sui.setPrompt(promptText)
	sui.setOkButtonText("Place Bounty")
	sui.setCancelButtonText("Cancel")

	sui.sendTo(pVictim)
end

function PlayerBountySystem:bountyAmountCallback(pVictim, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if cancelPressed or pVictim == nil or args == nil or args == "" then
		return
	end

	-- Get killer ID from shared memory
	local victimID = SceneObject(pVictim):getObjectID()
	local killerID = readData(victimID .. ":bounty_target")

	if killerID == nil or killerID == 0 then
		CreatureObject(pVictim):sendSystemMessage("Error: Bounty target not found.")
		return
	end

	-- Clean up stored data
	deleteData(victimID .. ":bounty_target")

	local pKiller = getSceneObject(killerID)

	if pKiller == nil or not SceneObject(pKiller):isPlayerCreature() then
		CreatureObject(pVictim):sendSystemMessage("Target is no longer available.")
		return
	end

	-- Validate amount is a number
	local bountyAmount = tonumber(args)

	if bountyAmount == nil then
		CreatureObject(pVictim):sendSystemMessage("Invalid amount entered. Please enter a numeric value.")
		return
	end

	-- Validate minimum amount
	if bountyAmount < self.minimumBounty then
		CreatureObject(pVictim):sendSystemMessage("Bounty must be at least " .. self.minimumBounty .. " credits.")
		return
	end

	-- Validate maximum amount
	if bountyAmount > self.maximumBounty then
		CreatureObject(pVictim):sendSystemMessage("Bounty cannot exceed " .. self.maximumBounty .. " credits.")
		return
	end

	-- Check if victim has enough credits (cash + bank)
	local cash = CreatureObject(pVictim):getCashCredits()
	local bank = CreatureObject(pVictim):getBankCredits()
	local totalCredits = cash + bank

	if totalCredits < bountyAmount then
		CreatureObject(pVictim):sendSystemMessage("You do not have enough credits to place this bounty.")
		return
	end

	-- All validations passed, process bounty placement
	self:placeBounty(pVictim, pKiller, bountyAmount)
end

function PlayerBountySystem:placeBounty(pVictim, pKiller, bountyAmount)
	if pVictim == nil or pKiller == nil or bountyAmount == nil or bountyAmount <= 0 then
		return
	end

	local victimID = SceneObject(pVictim):getObjectID()
	local killerID = SceneObject(pKiller):getObjectID()
	local killerName = CreatureObject(pKiller):getFirstName()
	local victimName = CreatureObject(pVictim):getFirstName()

	-- Deduct credits using smart wallet pattern (prefer cash, then bank)
	local cash = CreatureObject(pVictim):getCashCredits()

	if cash >= bountyAmount then
		-- Take from cash only
		CreatureObject(pVictim):subtractCashCredits(bountyAmount)
	else
		-- Take what's available from cash, rest from bank
		if cash > 0 then
			CreatureObject(pVictim):subtractCashCredits(cash)
		end
		CreatureObject(pVictim):subtractBankCredits(bountyAmount - cash)
	end

	-- Place the bounty using the global Lua function
	-- This function is registered in DirectorManager and has access to MissionManager
	placePlayerBounty(killerID, victimID, bountyAmount)

	-- Send messages
	CreatureObject(pVictim):sendSystemMessage("Bounty of " .. bountyAmount .. " credits has been placed on " .. killerName .. ".")

	-- Notify the killer (optional)
	if self.notifyTarget and pKiller ~= nil then
		local warningMsg = "A bounty of " .. bountyAmount .. " credits has been placed on your head by " .. victimName .. "!"
		CreatureObject(pKiller):sendSystemMessage(warningMsg)
	end

	-- Set cooldown to prevent spam
	local cooldownKey = victimID .. ":bounty_cooldown:" .. killerID
	local cooldownExpiry = os.time() + (self.cooldownTime / 1000)
	writeData(cooldownKey, cooldownExpiry)

	-- Log for debugging
	print("PLAYER BOUNTY: " .. victimName .. " placed " .. bountyAmount .. " credits on " .. killerName)
end

return PlayerBountySystem
