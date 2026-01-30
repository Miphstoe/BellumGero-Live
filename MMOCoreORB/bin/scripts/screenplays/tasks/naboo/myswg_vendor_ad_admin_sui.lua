--[[
    Bellum Gero Hub Advertisement System - Admin SUI Interface
    Provides admin-only SUI for viewing and managing advertisements
]]--

-- Load the ad manager module
if not MySwgVendorAdManager then
    require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
end

MySwgVendorAdAdminSui = {}

--[[
    Show admin advertisement management SUI
    @param pPlayer Player object pointer (must be privileged admin level 7+)
]]--
function MySwgVendorAdAdminSui:showAdminMenu(pPlayer)
    if pPlayer == nil then
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        return
    end

    -- Check if player is privileged admin (level 7+)
    local pGhost = player:getPlayerObject()
    if pGhost == nil then
        player:sendSystemMessage("ERROR: Could not access player ghost.")
        return
    end

    if not PlayerObject(pGhost):isPrivileged() then
        player:sendSystemMessage("You must be a privileged admin (level 7+) to access advertisement management.")
        return
    end

    -- Get active ads
    local activeAds = MySwgVendorAdManager:getActiveAdsDetailed()

    if #activeAds == 0 then
        player:sendSystemMessage("No active advertisements to manage.")
        return
    end

    -- Build listbox - use myswg_vendor screenplay for callback
    local sui = SuiListBox.new("myswg_vendor", "adAdminCallback")

    sui.setTitle("Advertisement Management (Admin)")
    sui.setPrompt("Select an advertisement to delete:\n\nTotal Active Ads: " .. #activeAds)

    sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())

    -- Add each ad to the list
    for i, ad in ipairs(activeAds) do
        local currentTime = os.time()
        local timeLeft = ad.endTime - currentTime
        local daysLeft = math.floor(timeLeft / 86400)
        local hoursLeft = math.floor((timeLeft % 86400) / 3600)

        -- Truncate message for display
        local displayMessage = string.sub(ad.adMessage, 1, 60)
        if string.len(ad.adMessage) > 60 then
            displayMessage = displayMessage .. "..."
        end

        local listEntry = "[" .. ad.playerName .. "] " .. displayMessage .. " (" .. daysLeft .. "d " .. hoursLeft .. "h left)"

        sui.add(listEntry, "" .. ad.queueIndex)
    end

    sui.setOkButtonText("Delete Selected")
    sui.setCancelButtonText("Cancel")

    sui.sendTo(pPlayer)
end

--[[
    Callback when admin selects an ad to delete
    @param pPlayer Player object pointer
    @param pSui SUI window pointer
    @param eventIndex Button pressed (0 = OK, 1 = Cancel)
    @param args Additional arguments (selected row index)
]]--
function MySwgVendorAdAdminSui:adminMenuCallback(pPlayer, pSui, eventIndex, args)
    if pPlayer == nil then
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        return
    end

    -- Check if player is privileged admin again (level 7+)
    local pGhost = player:getPlayerObject()
    if pGhost == nil then
        player:sendSystemMessage("ERROR: Could not access player ghost.")
        return
    end

    if not PlayerObject(pGhost):isPrivileged() then
        player:sendSystemMessage("You must be a privileged admin (level 7+) to delete advertisements.")
        return
    end

    -- Cancel button pressed
    if eventIndex == 1 then
        player:sendSystemMessage("Advertisement management cancelled.")
        return
    end

    -- Wrap the SUI with Lua wrapper
    local listBox = LuaSuiListBox(pSui)
    if listBox == nil then
        player:sendSystemMessage("ERROR: Could not access SUI listbox.")
        return
    end

    -- Get selected row (args contains the row index)
    local selectedRow = args
    if selectedRow == nil or selectedRow < 0 then
        player:sendSystemMessage("No advertisement selected.")
        return
    end

    player:sendSystemMessage("DEBUG: Selected row: " .. tostring(selectedRow))

    -- Get the queue index string stored with this row
    local queueIndexStr = listBox:getMenuItemObject(selectedRow)
    player:sendSystemMessage("DEBUG: Queue index string: " .. tostring(queueIndexStr))

    if queueIndexStr == nil or queueIndexStr == "" then
        player:sendSystemMessage("Error: Could not determine advertisement index.")
        return
    end

    local queueIndex = tonumber(queueIndexStr)
    if queueIndex == nil then
        player:sendSystemMessage("Error: Invalid advertisement index.")
        return
    end

    player:sendSystemMessage("DEBUG: Attempting to delete ad at queue index: " .. tostring(queueIndex))

    -- Delete the ad
    local success, message = MySwgVendorAdManager:deleteAd(queueIndex)

    if success then
        player:sendSystemMessage("SUCCESS: " .. message)
    else
        player:sendSystemMessage("ERROR: " .. message)
    end
end

--[[
    Show all active ads in a SUI popup (for regular players)
    @param pPlayer Player object pointer
]]--
function MySwgVendorAdAdminSui:showAdsPopup(pPlayer)
    if pPlayer == nil then
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        return
    end

    -- Get active ads
    local activeAds = MySwgVendorAdManager:getActiveAdsDetailed()

    if #activeAds == 0 then
        player:sendSystemMessage("No active advertisements at this time.")
        return
    end

    -- Build message box with all ads
    local sui = SuiMessageBox.new("MySwgVendorAdAdminSui", "adsPopupCallback")

    sui.setTitle("Active Advertisements")

    -- Build the ad list
    local message = "Current advertisements running on Bellum Gero Hub:\n\n"
    message = message .. "Total Ads: " .. #activeAds .. "\n"
    message = message .. "================================\n\n"

    for i, ad in ipairs(activeAds) do
        local currentTime = os.time()
        local timeLeft = ad.endTime - currentTime
        local daysLeft = math.floor(timeLeft / 86400)
        local hoursLeft = math.floor((timeLeft % 86400) / 3600)

        message = message .. "[" .. i .. "] Advertiser: " .. ad.playerName .. "\n"
        message = message .. "Message: " .. ad.adMessage .. "\n"
        message = message .. "Expires: " .. daysLeft .. " days, " .. hoursLeft .. " hours\n\n"
    end

    sui.setPrompt(message)
    sui.setOkButtonText("Close")

    sui.sendTo(pPlayer)
end

--[[
    Callback for ads popup (does nothing, just closes)
]]--
function MySwgVendorAdAdminSui:adsPopupCallback(pPlayer, pSui, eventIndex)
    -- Nothing to do, just close the window
end

return MySwgVendorAdAdminSui
