--[[
    Bellum Gero Hub Advertisement System - SUI Input Handler
    Handles the SUI input box for collecting custom ad messages
]]--

if not MySwgVendorAdManager then
    require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
end

if not SuiInputBox then
    require("screenplays.sui.SuiInputBox")
end

-- Create global tables (both CamelCase for internal use and lowercase for SUI callbacks)
MySwgVendorAdSui = {}
_G.MySwgVendorAdSui = MySwgVendorAdSui

-- Holds the pending auto-renewal flag per player (keyed by player objectID) until the SUI callback fires
MySwgVendorAdSui.pendingAutoRenew = {}

-- Create lowercase version for SUI callback registration
myswg_vendor_ad_sui = {}
_G.myswg_vendor_ad_sui = myswg_vendor_ad_sui

--[[
    Show SUI input box to prompt player for advertisement message
    @param pPlayer      Player object pointer
    @param autoRenew    Boolean - whether to enable auto-renewal
]]--
function MySwgVendorAdSui:promptForAd(pPlayer, autoRenew)
    if pPlayer == nil then
        print("ERROR: promptForAd called with nil pPlayer")
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        print("ERROR: promptForAd - LuaCreatureObject returned nil")
        return
    end

    -- Store the auto-renewal flag so the SUI callback can read it
    local playerObjId = SceneObject(pPlayer):getObjectID()
    MySwgVendorAdSui.pendingAutoRenew[playerObjId] = autoRenew or false

    -- Create SUI input box - callback is in myswg_vendor_convo_handler
    local sui = SuiInputBox.new("myswg_vendor_convo_handler", "handleAdPurchaseSui")

    if sui == nil then
        print("ERROR: SuiInputBox.new returned nil")
        player:sendSystemMessage("Error: Failed to create advertisement input box. Please contact an administrator.")
        return
    end

    sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
    sui.setTitle("Bellum Gero Hub - Advertisement")
    sui.setPrompt("Enter your advertisement message (max 255 characters):\n\nYour ad will be broadcast to all players near Bellum Gero Hub vendors for 1 week.")

    sui.sendTo(pPlayer)
end

--[[
    Handle the SUI input box callback - TABLE METHOD
    This is called by the SUI system when player submits input
    @param self Table reference
    @param pPlayer Player object pointer
    @param pSui SUI object pointer
    @param eventIndex Event type (0 = OK, 1 = Cancel)
    @param args Callback arguments
]]--
function MySwgVendorAdSui:handleAdInputGlobal(pPlayer, pSui, eventIndex, args)
    if pPlayer == nil then
        print("ERROR: handleAdInputGlobal called with nil pPlayer")
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        print("ERROR: handleAdInputGlobal - LuaCreatureObject returned nil")
        return
    end

    -- Ensure ad manager is loaded in this context
    if not MySwgVendorAdManager then
        local success, err = pcall(function()
            require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
        end)
        if not success then
            print("ERROR: Failed to load ad manager in callback: " .. tostring(err))
            player:sendSystemMessage("ERROR: Advertisement system unavailable. Please contact an administrator.")
            return
        end
    end

    -- Check if player cancelled
    if eventIndex == 1 then
        player:sendSystemMessage("Advertisement purchase cancelled. No credits were charged.")
        return
    end

    -- Get the input text
    local adMessage = args

    if adMessage == nil or adMessage == "" then
        print("ERROR: adMessage is nil or empty")
        player:sendSystemMessage("Advertisement message cannot be empty. No credits were charged.")
        return
    end

    -- Trim whitespace
    adMessage = adMessage:match("^%s*(.-)%s*$")

    -- Validate message length
    if string.len(adMessage) > MySwgVendorAdManager.MAX_AD_LENGTH then
        print("ERROR: adMessage too long: " .. string.len(adMessage))
        player:sendSystemMessage("Advertisement message is too long (max " .. MySwgVendorAdManager.MAX_AD_LENGTH .. " characters). No credits were charged.")
        return
    end

    if adMessage == "" then
        print("ERROR: adMessage empty after trim")
        player:sendSystemMessage("Advertisement message cannot be empty. No credits were charged.")
        return
    end

    -- Check if player can afford it (double-check)
    local credits = player:getCashCredits()

    if credits < MySwgVendorAdManager.AD_COST then
        print("ERROR: Player cannot afford ad")
        player:sendSystemMessage("You need " .. MySwgVendorAdManager.AD_COST .. " credits to purchase advertisement space.")
        return
    end

    -- Get player name
    local playerName = player:getFirstName()

    -- Purchase the ad (this adds it to the queue)
    local success, message = MySwgVendorAdManager:purchaseAd(playerName, adMessage, "", "")

    -- Send result to player
    if success then
        -- Only charge credits AFTER successful ad purchase
        player:subtractCashCredits(MySwgVendorAdManager.AD_COST)

        player:sendSystemMessage("@base_player:prose_pay_success")  -- "You successfully make a payment"
        player:sendSystemMessage("Advertisement purchased successfully!")
        player:sendSystemMessage(message)
    else
        print("ERROR: Ad purchase failed: " .. tostring(message))
        player:sendSystemMessage("Failed to purchase advertisement: " .. message)
    end
end

return MySwgVendorAdSui
