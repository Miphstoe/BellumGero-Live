--[[
    Bellum Gero Hub Advertisement System - Queue Manager
    Manages the advertisement queue stored on the master NPC object
]]--

MySwgVendorAdManager = {}

-- Configuration
MySwgVendorAdManager.AD_COST = 100000              -- 100k credits
MySwgVendorAdManager.AD_DURATION = 604800          -- 1 week in seconds (7 * 24 * 60 * 60)
MySwgVendorAdManager.MAX_AD_LENGTH = 255           -- Maximum ad message length
MySwgVendorAdManager.MAX_QUEUE_SIZE = 50           -- Maximum number of queued ads
MySwgVendorAdManager.CLEANUP_AFTER = 86400         -- Delete expired ads after 1 day
MySwgVendorAdManager.QUEUE_FILE = "custom_scripts/ad_queue.lua"  -- Persistent file storage


--[[
    Serialize a Lua table to a string
    @param tbl Table to serialize
    @param indent Current indentation level (internal use)
    @return String representation of the table
]]--
function MySwgVendorAdManager:serializeTable(tbl, indent)
    indent = indent or ""
    local result = "{\n"

    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format('["%s"]', k)
        else
            key = string.format('[%d]', k)
        end

        if type(v) == "table" then
            result = result .. indent .. "  " .. key .. " = " .. self:serializeTable(v, indent .. "  ") .. ",\n"
        elseif type(v) == "string" then
            -- Escape quotes and newlines in strings
            local escaped = v:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
            result = result .. indent .. "  " .. key .. ' = "' .. escaped .. '",\n'
        elseif type(v) == "number" or type(v) == "boolean" then
            result = result .. indent .. "  " .. key .. " = " .. tostring(v) .. ",\n"
        end
    end

    result = result .. indent .. "}"
    return result
end

--[[
    Load the ad queue from persistent file storage
    @return Table containing the queue, or empty queue if none exists
]]--
function MySwgVendorAdManager:loadQueue()
    -- Try to load from file
    local success, queue = pcall(function()
        local chunk, err = loadfile(self.QUEUE_FILE)
        if chunk then
            return chunk()  -- Execute the chunk to get the return value
        else
            print("ERROR: Failed to load ad queue file: " .. tostring(err))
            return nil
        end
    end)

    if success and queue ~= nil and type(queue) == "table" and queue.ads ~= nil then
        return queue
    end

    -- File doesn't exist or is corrupted, return empty queue
    return {ads = {}}
end

--[[
    Save the ad queue to persistent file storage
    @param queue Table containing the ad queue
    @return Boolean success status
]]--
function MySwgVendorAdManager:saveQueue(queue)
    local serialized = "return " .. self:serializeTable(queue)

    -- Write to file
    local file = io.open(self.QUEUE_FILE, "w")
    if file == nil then
        print("ERROR: Failed to open ad queue file for writing: " .. self.QUEUE_FILE)
        return false
    end

    file:write(serialized)
    file:close()

    return true
end

--[[
    Get all currently active advertisements
    @return Table of active ads, or empty table if none
]]--
function MySwgVendorAdManager:getActiveAds()
    local queue = self:loadQueue()

    if queue == nil or queue.ads == nil or #queue.ads == 0 then
        return {}
    end


    local currentTime = os.time()
    local activeAds = {}

    -- Find all active ads that haven't expired
    for i, ad in ipairs(queue.ads) do
        if ad ~= nil then
            if ad.active == true then
                -- Check if it's expired
                if ad.endTime ~= nil and currentTime <= ad.endTime then
                    table.insert(activeAds, ad)
                else
                end
            end
        end
    end

    return activeAds
end

--[[
    Check and rotate ads - expire old ads and activate queued ones
    Called periodically by the barking system
]]--
function MySwgVendorAdManager:checkAndRotateAds()
    local queue = self:loadQueue()

    if queue == nil or queue.ads == nil or #queue.ads == 0 then
        return
    end

    local currentTime = os.time()
    local queueChanged = false
    local activeAdExpired = false

    -- Check if current active ad has expired; attempt auto-renewal if enabled
    for i, ad in ipairs(queue.ads) do
        if ad ~= nil and ad.active == true and ad.endTime ~= nil and currentTime >= ad.endTime then
            if ad.autoRenew == true and ad.playerObjectId ~= nil and ad.playerObjectId ~= 0 then
                -- Try to charge the player for another week
                local charged = self:chargePlayerForRenewal(ad.playerObjectId)
                if charged then
                    -- Extend the ad by one more week
                    ad.endTime = ad.endTime + self.AD_DURATION
                    queueChanged = true
                    print("INFO: Auto-renewed ad for player " .. tostring(ad.playerName))
                else
                    -- Can't afford renewal - cancel and flag for notification
                    ad.active = false
                    ad.renewalFailed = true
                    activeAdExpired = true
                    queueChanged = true
                    print("INFO: Auto-renewal failed for player " .. tostring(ad.playerName) .. " (insufficient credits)")
                end
            else
                ad.active = false
                activeAdExpired = true
                queueChanged = true
            end
        end
    end

    -- If active ad expired, activate the next queued ad
    if activeAdExpired then
        for i, ad in ipairs(queue.ads) do
            if ad ~= nil and ad.active == false and ad.startTime ~= nil and ad.endTime ~= nil and currentTime >= ad.startTime and currentTime < ad.endTime then
                ad.active = true
                queueChanged = true
                break
            end
        end
    end

    -- Clean up very old expired ads (older than CLEANUP_AFTER)
    local cleanupTime = currentTime - self.CLEANUP_AFTER
    local newAds = {}
    for i, ad in ipairs(queue.ads) do
        if ad ~= nil and ad.endTime ~= nil and ad.endTime > cleanupTime then
            table.insert(newAds, ad)
        else
            queueChanged = true
        end
    end
    queue.ads = newAds

    -- Save if queue changed
    if queueChanged then
        self:saveQueue(queue)
    end
end

--[[
    Attempt to charge a player for auto-renewal (cash first, bank second).
    @param playerObjectId  SceneObject ID of the player
    @return Boolean - true if charge succeeded, false otherwise
]]--
function MySwgVendorAdManager:chargePlayerForRenewal(playerObjectId)
    if playerObjectId == nil or playerObjectId == 0 then
        return false
    end

    local pCreature = getSceneObject(playerObjectId)
    if pCreature == nil then
        return false
    end

    local creature = LuaCreatureObject(pCreature)
    if creature == nil then
        return false
    end

    local cost = self.AD_COST
    local cash = creature:getCashCredits()
    local bank = creature:getBankCredits()

    if (cash + bank) < cost then
        return false
    end

    -- Deduct cash first, then bank for the remainder
    if cash >= cost then
        creature:subtractCashCredits(cost)
    else
        if cash > 0 then
            creature:subtractCashCredits(cash)
        end
        creature:subtractBankCredits(cost - cash)
    end

    return true
end

--[[
    Get all ads that failed auto-renewal for a given player (by first name).
    @param playerName  Player's first name
    @return Table of matching ads
]]--
function MySwgVendorAdManager:getFailedRenewalsForPlayer(playerName)
    local queue = self:loadQueue()
    local failed = {}

    if queue.ads == nil then
        return failed
    end

    for i, ad in ipairs(queue.ads) do
        if ad ~= nil and ad.renewalFailed == true and ad.playerName == playerName then
            table.insert(failed, ad)
        end
    end

    return failed
end

--[[
    Clear the renewalFailed flag for all ads belonging to a player.
    @param playerName  Player's first name
]]--
function MySwgVendorAdManager:clearFailedRenewalsForPlayer(playerName)
    local queue = self:loadQueue()

    if queue.ads == nil then
        return
    end

    local changed = false
    for i, ad in ipairs(queue.ads) do
        if ad ~= nil and ad.renewalFailed == true and ad.playerName == playerName then
            ad.renewalFailed = false
            changed = true
        end
    end

    if changed then
        self:saveQueue(queue)
    end
end

--[[
    Purchase a new advertisement slot
    @param playerName       Name of the player purchasing the ad
    @param adMessage        The advertisement message
    @param adMood           Optional mood for animation
    @param adAnimation      Optional animation name
    @param autoRenew        Boolean - enable weekly auto-renewal
    @param playerObjectId   SceneObject ID used to charge credits on renewal
    @return Boolean success, String error message
]]--
function MySwgVendorAdManager:purchaseAd(playerName, adMessage, adMood, adAnimation, autoRenew, playerObjectId)
    -- Validate message
    if adMessage == nil or adMessage == "" then
        print("ERROR: adMessage is nil or empty in purchaseAd")
        return false, "Advertisement message cannot be empty"
    end

    if string.len(adMessage) > self.MAX_AD_LENGTH then
        print("ERROR: adMessage too long in purchaseAd: " .. string.len(adMessage))
        return false, "Advertisement message is too long (max " .. self.MAX_AD_LENGTH .. " characters)"
    end

    local queue = self:loadQueue()

    -- Check queue size
    if queue.ads == nil then
        queue.ads = {}
    end

    if #queue.ads >= self.MAX_QUEUE_SIZE then
        return false, "Advertisement queue is full. Please try again later."
    end

    local currentTime = os.time()
    local startTime = currentTime
    local endTime = currentTime + self.AD_DURATION

    -- All ads are active immediately and run concurrently
    local isActive = true

    -- Create the new ad entry
    local newAd = {
        playerName = playerName,
        adMessage = adMessage,
        adMood = adMood or "",
        adAnimation = adAnimation or "",
        purchaseTime = currentTime,
        startTime = startTime,
        endTime = endTime,
        active = isActive,
        autoRenew = autoRenew or false,
        playerObjectId = playerObjectId or 0,
        renewalFailed = false,
    }

    -- Add to queue
    table.insert(queue.ads, newAd)

    -- Save queue
    local success = self:saveQueue(queue)

    if success then
        -- Calculate how many days the ad will run
        local daysRemaining = math.floor(self.AD_DURATION / 86400)

        local resultMsg = "Advertisement purchased! Your ad is now active and will run for " .. daysRemaining .. " days alongside other active ads."
        return true, resultMsg
    else
        print("ERROR: Failed to save queue in purchaseAd")
        return false, "Failed to save advertisement. Please contact an administrator."
    end
end

--[[
    Get formatted queue status for display
    @return String formatted queue status
]]--
function MySwgVendorAdManager:getQueueStatus()
    local queue = self:loadQueue()

    if queue.ads == nil or #queue.ads == 0 then
        return "No advertisements currently active.\n\nPurchase your ad space now!"
    end

    local currentTime = os.time()
    local result = ""
    local activeAds = {}

    -- Get all active ads
    for i, ad in ipairs(queue.ads) do
        if ad.active == true and currentTime <= ad.endTime then
            table.insert(activeAds, ad)
        end
    end

    -- Show all active ads
    if #activeAds > 0 then
        result = result .. "=== ACTIVE ADVERTISEMENTS (" .. #activeAds .. ") ===\n"
        result = result .. "All ads run concurrently and rotate every 2 minutes.\n\n"

        for i, ad in ipairs(activeAds) do
            local timeLeft = ad.endTime - currentTime
            local daysLeft = math.floor(timeLeft / 86400)
            local hoursLeft = math.floor((timeLeft % 86400) / 3600)

            result = result .. i .. ". " .. ad.playerName .. "\n"
            result = result .. '   "' .. string.sub(ad.adMessage, 1, 50)
            if string.len(ad.adMessage) > 50 then
                result = result .. "..."
            end
            result = result .. '"\n'
            result = result .. "   Expires in: " .. daysLeft .. " days, " .. hoursLeft .. " hours\n\n"
        end
    else
        result = result .. "No advertisements currently active.\n\nBe the first to advertise!"
    end

    return result
end

--[[
    Get all active ads with full details (for admin SUI)
    @return Table of active ads with all fields
]]--
function MySwgVendorAdManager:getActiveAdsDetailed()
    local queue = self:loadQueue()

    if queue.ads == nil or #queue.ads == 0 then
        return {}
    end

    local currentTime = os.time()
    local activeAds = {}

    -- Find all active ads
    for i, ad in ipairs(queue.ads) do
        if ad ~= nil and ad.active == true and ad.endTime ~= nil and currentTime <= ad.endTime then
            -- Add index for deletion reference
            ad.queueIndex = i
            table.insert(activeAds, ad)
        end
    end

    return activeAds
end

--[[
    Delete an advertisement by queue index (Admin only)
    @param queueIndex The index in the queue to delete
    @return Boolean success, String message
]]--
function MySwgVendorAdManager:deleteAd(queueIndex)
    local queue = self:loadQueue()

    if queue.ads == nil or #queue.ads == 0 then
        return false, "No advertisements to delete"
    end

    if queueIndex < 1 or queueIndex > #queue.ads then
        return false, "Invalid advertisement index"
    end

    local deletedAd = queue.ads[queueIndex]
    table.remove(queue.ads, queueIndex)

    local success = self:saveQueue(queue)

    if success then
        return true, "Advertisement by " .. (deletedAd.playerName or "Unknown") .. " has been deleted"
    else
        return false, "Failed to save changes"
    end
end

return MySwgVendorAdManager
