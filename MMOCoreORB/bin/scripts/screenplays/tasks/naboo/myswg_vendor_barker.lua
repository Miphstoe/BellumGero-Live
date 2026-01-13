--[[
    Bellum Gero Hub Advertisement System - Barking Component
    Makes NPCs bark advertisements periodically to nearby players
]]--

-- Load the ad manager module first
if not MySwgVendorAdManager then
    require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
end

-- Verify ad manager is loaded
if not MySwgVendorAdManager then
    print("CRITICAL ERROR: MySwgVendorAdManager failed to load in barker module!")
end

MySwgVendorBarker = {}

-- Configuration
MySwgVendorBarker.BARK_INTERVAL = 120  -- 2 minutes in seconds
MySwgVendorBarker.BARK_RANGE = 15      -- 15 meters

--[[
    Initialize barking for an NPC
    @param pNpc NPC object pointer
]]--
function MySwgVendorBarker:initialize(pNpc)
    if pNpc == nil then
        return
    end

    -- Schedule first bark
    self:scheduleNextBark(pNpc)
end

--[[
    Schedule the next bark event
    @param pNpc NPC object pointer
]]--
function MySwgVendorBarker:scheduleNextBark(pNpc)
    if pNpc == nil then
        return
    end

    -- Schedule bark in BARK_INTERVAL seconds
    createEvent(self.BARK_INTERVAL * 1000, "MySwgVendorBarker", "performBark", pNpc, "")
end

--[[
    Perform a bark event
    NOTE: Called by createEvent as a method, so 'self' is the first parameter
    @param self The MySwgVendorBarker table
    @param pNpc NPC object pointer
]]--
function MySwgVendorBarker:performBark(pNpc)
    -- Wrap everything in pcall to prevent crashes
    local success, errorMsg = pcall(function()
        if pNpc == nil then
            print("ERROR: performBark called with nil pNpc")
            return
        end

        -- Load the ad manager module if not already loaded
        if not MySwgVendorAdManager then
            local loadSuccess, loadErr = pcall(function()
                require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
            end)
            if not loadSuccess then
                print("ERROR: Failed to load ad manager in performBark: " .. tostring(loadErr))
                -- Still schedule next bark even if module fails to load
                MySwgVendorBarker:scheduleNextBark(pNpc)
                return
            end
        end

        local npc = LuaSceneObject(pNpc)
        if npc == nil then
            print("ERROR: LuaSceneObject(pNpc) returned nil")
            MySwgVendorBarker:scheduleNextBark(pNpc)
            return
        end

        -- Check and rotate ads (handles expiration)
        if MySwgVendorAdManager and type(MySwgVendorAdManager.checkAndRotateAds) == "function" then
            MySwgVendorAdManager:checkAndRotateAds()
        else
            print("ERROR: checkAndRotateAds function not available")
            MySwgVendorBarker:scheduleNextBark(pNpc)
            return
        end

        -- Get current active ad
        local currentAd = nil
        if MySwgVendorAdManager and type(MySwgVendorAdManager.getCurrentAd) == "function" then
            currentAd = MySwgVendorAdManager:getCurrentAd()
        else
            print("ERROR: getCurrentAd function not available")
        end

        if currentAd ~= nil and type(currentAd) == "table" and currentAd.adMessage ~= nil and currentAd.adMessage ~= "" then
            -- Bark the ad to nearby players
            MySwgVendorBarker:barkToNearbyPlayers(pNpc, currentAd.adMessage, currentAd.adMood or "", currentAd.adAnimation or "")
        end

        -- Schedule next bark
        MySwgVendorBarker:scheduleNextBark(pNpc)
    end)

    if not success then
        print("ERROR: performBark crashed: " .. tostring(errorMsg))
        -- Try to schedule next bark even if we crashed
        pcall(function()
            MySwgVendorBarker:scheduleNextBark(pNpc)
        end)
    end
end

--[[
    Bark a message to nearby players
    @param pNpc NPC object pointer
    @param message Message to bark
    @param mood Optional mood string
    @param animation Optional animation name
]]--
function MySwgVendorBarker:barkToNearbyPlayers(pNpc, message, mood, animation)
    if pNpc == nil or message == nil or message == "" then
        return
    end

    local npc = LuaSceneObject(pNpc)
    if npc == nil then
        print("ERROR: barkToNearbyPlayers - LuaSceneObject(pNpc) returned nil")
        return
    end

    -- Use spatial chat to broadcast to nearby players
    npc:spatialChat(message)

    -- Play animation if specified
    if animation ~= nil and animation ~= "" then
        local creatureNpc = LuaCreatureObject(pNpc)
        if creatureNpc ~= nil then
            creatureNpc:doAnimation(animation)
        end
    end

    -- Set mood if specified
    if mood ~= nil and mood ~= "" then
        local creatureNpc = LuaCreatureObject(pNpc)
        if creatureNpc ~= nil then
            creatureNpc:setMoodString(mood)
        end
    end
end

return MySwgVendorBarker
