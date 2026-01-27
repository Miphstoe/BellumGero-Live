myswg_vendor = ScreenPlay:new {
    numberOfActs = 1,
    questString = "myswg_vendor_task",
    states = {},
    BARK_INTERVAL = 30000  -- 30 seconds between barks
}
registerScreenPlay("myswg_vendor", true)

-- Barking function integrated into screenplay (avoids Lua context issues)
function myswg_vendor:performBark(pNpc)
    if pNpc == nil then
        print("ERROR: performBark called with nil pNpc")
        return
    end

    -- Load ad manager if needed
    if not MySwgVendorAdManager then
        local success, err = pcall(function()
            require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
        end)
        if not success then
            print("ERROR: Failed to load ad manager in performBark: " .. tostring(err))
            createEvent(self.BARK_INTERVAL, "myswg_vendor", "performBark", pNpc, "")
            return
        end
    end

    -- Check and rotate ads
    MySwgVendorAdManager:checkAndRotateAds()

    -- Get ALL active ads
    local activeAds = MySwgVendorAdManager:getActiveAds()

    if activeAds ~= nil and #activeAds > 0 then
        -- Each NPC rotates through ads over time (NPC ID + time-based cycle)
        local npcId = SceneObject(pNpc):getObjectID()
        local cycleNumber = math.floor(os.time() / (self.BARK_INTERVAL / 1000))  -- Changes every 2 minutes
        local adIndex = ((npcId + cycleNumber) % #activeAds) + 1  -- Rotates through ads over time

        local ad = activeAds[adIndex]

        if ad ~= nil and ad.adMessage ~= nil and ad.adMessage ~= "" then
            spatialChat(pNpc, ad.adMessage)
        end
    end

    -- Schedule next bark
    createEvent(self.BARK_INTERVAL, "myswg_vendor", "performBark", pNpc, "")
end
function myswg_vendor:start()
    -- Load advertisement system modules GLOBALLY
    local success, err = pcall(function()
        require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
    end)
    if not success then
        print("ERROR: Failed to load myswg_vendor_ad_manager: " .. tostring(err))
    end

    success, err = pcall(function()
        require("screenplays.tasks.naboo.myswg_vendor_barker")
    end)
    if not success then
        print("ERROR: Failed to load myswg_vendor_barker: " .. tostring(err))
    end

    success, err = pcall(function()
        require("screenplays.tasks.naboo.myswg_vendor_ad_sui")
    end)
    if not success then
        print("ERROR: Failed to load myswg_vendor_ad_sui: " .. tostring(err))
    end

    -- Spawn our character into the world, setting pLarry a pointer variable we can use to check or change his state.
    -- The first spawn (Coronet) is the MASTER NPC that stores the ad queue
    local pWeaponsmith = spawnMobile("corellia", "myswg_vendor", 1, -157, 28.0, -4724, 35, 0 )--cnet (MASTER)

    -- Initialize barking for master NPC with random delay to stagger NPCs
    if pWeaponsmith ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith, "") end
    -- Spawn and initialize other Corellia vendors
    local pWeaponsmith1 = spawnMobile("corellia", "myswg_vendor", 1, -5042, 21.0, -2297, 35, 0 )--tyrena
    if pWeaponsmith1 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith1, "") end

    local pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, -3138, 31.0, 2796, 35, 0 )--korvella
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end

    pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, 3333, 308.0, 5524, 35, 0 )--doaba
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end

    pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, -5550, 15.58, -6061, 35, 0 )--venri
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end

    pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, 6643.02,330.00,-5920.87, 35, 0 )--belav
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end  

    -- Spawn and initialize Naboo vendors
    local pWeaponsmith3 = spawnMobile("naboo", "myswg_vendor", 1, -4872, 6.0, 4151, 35, 0 )--theed
    if pWeaponsmith3 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith3, "") end

    local pWeaponsmith4 = spawnMobile("naboo", "myswg_vendor", 1, 4807, 4.0, -4705, 35, 0 )--moena
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    local pWeaponsmith5 = spawnMobile("naboo", "myswg_vendor", 1, 5200, -192.0, 6677, 35, 0 )--kaadara
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    pWeaponsmith5 = spawnMobile("naboo", "myswg_vendor", 1, 1444, 14.0, 2777, 35, 0 )--keren
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    pWeaponsmith5 = spawnMobile("naboo", "myswg_vendor", 1, 5331.16,326.95,-1576.12, 35, 0 )--deja
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    pWeaponsmith5 = spawnMobile("naboo", "myswg_vendor", 1, -5495.62,-150.00,-24.69, 35, 0 )--lake ret
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end
    
    -- Spawn and initialize Tatooine vendors
    local pWeaponsmith3 = spawnMobile("tatooine", "myswg_vendor", 1, 3522, 5.0, -4803, 35, 0 )--eisley
    if pWeaponsmith3 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith3, "") end

    local pWeaponsmith4 = spawnMobile("tatooine", "myswg_vendor", 1, -1281, 12.0, -3590, 35, 0 )--bestine
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    local pWeaponsmith5 = spawnMobile("tatooine", "myswg_vendor", 1, -2914, 5.0, 2129, 35, 0 )--espa
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    pWeaponsmith5 = spawnMobile("tatooine", "myswg_vendor", 1, 1293, 7.0, 3140, 35, 0 )--entha
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    pWeaponsmith5 = spawnMobile("tatooine", "myswg_vendor", 1, 48.33,52.00,-5340.53, 35, 0 )--anc
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

	pWeaponsmith5 = spawnMobile("tatooine", "myswg_vendor", 1, 3746.6,6.8,2300.5, -90, 0 )--taike
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

	pWeaponsmith5 = spawnMobile("tatooine", "myswg_vendor", 1, -5032.8,75.0,-6572.5, -37, 0 )--wayfar
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end
        
    -- Spawn and initialize Talus vendors
    local pWeaponsmith4 = spawnMobile("talus", "myswg_vendor", 1, -2193, 20.0, 2313, 35, 0 )--talus imp
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("talus", "myswg_vendor", 1, 4447, 2.0, 5271, 35, 0 )--nashal
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("talus", "myswg_vendor", 1, 338, 6.0, -2931, 35, 0 )--dearic
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end
    
    -- Spawn and initialize Rori vendors
    local pWeaponsmith4 = spawnMobile("rori", "myswg_vendor", 1, 5365, 80.0, 5657, 35, 0 )--restuss
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("rori", "myswg_vendor", 1, -5305, 80.0, -2228, 35, 0 )--narmle
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("rori", "myswg_vendor", 1, 3683, 96.0, -6436, 35, 0 )--reb
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end
    
    -- Spawn and initialize Endor vendors
    local pWeaponsmith4 = spawnMobile("endor", "myswg_vendor", 1, -948, 73.0, 1550, 35, 0 )--smugglers
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("endor", "myswg_vendor", 1, 3201, 24.0, -3501, 35, 0 )--research
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end
    
    -- Spawn and initialize Dantooine vendors
    local pWeaponsmith4 = spawnMobile("dantooine", "myswg_vendor", 1, -638, 3.0, 2505, 35, 0 )--mining
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("dantooine", "myswg_vendor", 1, -4209, 3.0, -2349, 35, 0 )--imp
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("dantooine", "myswg_vendor", 1, 1564, 4.0, -6415, 35, 0 )--aggro
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end
    
    -- Spawn and initialize Dathomir vendors
    local pWeaponsmith4 = spawnMobile("dathomir", "myswg_vendor", 1, 619, 3.0, 3090, 35, 0 )--trade
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("dathomir", "myswg_vendor", 1, -47, 18.0, -1586, 35, 0 )--science
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("dathomir", "myswg_vendor", 1, 5253, 78.0, -4217, 35, 0 )--Village
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

     
    -- Spawn and initialize Yavin4 vendors
    local pWeaponsmith4 = spawnMobile("yavin4", "myswg_vendor", 1, -265, 35.0, 4897, 35, 0 )--mining
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("yavin4", "myswg_vendor", 1, 4054, 37.0, -6219, 37, 0 )--imp
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    pWeaponsmith4 = spawnMobile("yavin4", "myswg_vendor", 1, -6922, 73.0, -5730, 35, 0 )--labor
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end
    
    -- Spawn and initialize Lok vendors
    local pWeaponsmith4 = spawnMobile("lok", "myswg_vendor", 1, 479, 8.0, 5512, 35, 0 )--lok
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    -- Spawn and initialize player city vendors
    pWeaponsmith4 = spawnMobile("dantooine", "myswg_vendor", 1, -512, 1, -3016, 35, 0 )--Rose Red
    if pWeaponsmith4 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith4, "") end

    --local pWeaponsmith2 = spawnMobile("lok", "myswg_vendor", 1, 5052,12,1353, 35, 0 )--Chyna Town
    local pWeaponsmith5 = spawnMobile("dantooine", "myswg_vendor", 1, -5683.33,2,6885, 35, 0 )--New Asgard
    if pWeaponsmith5 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith5, "") end

    --local pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, 3884,23,1916, 35, 0 )--Star Haven
    pWeaponsmith4 = spawnMobile("dantooine", "junk_dealer", 1, -512, 1, -3023, 35, 0 )--Rose red
    local pWeaponsmith2 = spawnMobile("corellia", "myswg_vendor", 1, -2060,23,-4540, 35, 0 ) -- Valhalla
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end

    pWeaponsmith2 = spawnMobile("tatooine", "myswg_vendor", 1, 5847,38,4432, 35, 0 ) --Mos Ender Krayt
    if pWeaponsmith2 ~= nil then local randomDelay = math.random(0, self.BARK_INTERVAL / 1000) * 1000; createEvent(randomDelay, "myswg_vendor", "performBark", pWeaponsmith2, "") end
    --junk dealers
    --local pWeaponsmith4 = spawnMobile("lok", "junk_dealer", 1, 5050, 12.0, 1353, 35, 0 )--Chyna Town
    --local pWeaponsmith4 = spawnMobile("dathomir", "junk_dealer", 1, -3947, 124.0, -54, 35, 0 )--ns    
    --local pWeaponsmith4 = spawnMobile("dantooine", "junk_dealer", 1, -615, 3.0, 2505, 35, 0 )--dant mo
    --local pWeaponsmith4 = spawnMobile("dathomir", "junk_dealer", 1, 617, 3.0, 3090, 35, 0 )--trade
    --local pWeaponsmith4 = spawnMobile("dathomir", "junk_dealer", 1, -45, 18.0, -1586, 35, 0 )--science
    --local pWeaponsmith5 = spawnMobile("tatooine", "junk_dealer", 1, 6668.33,22.00,4245.53, 35, 0 )--gy 
                
--    local pLarry = spawnMobile("naboo", "merch_crazy_larry", 1, -4881, 6.0, 4150, 35, 0 )
end
myswg_vendor_convo_handler = Object:new {
    tstring = "myconversation"
}

-- SUI callback for advertisement input - must be in this screenplay object
function myswg_vendor_convo_handler:handleAdPurchaseSui(pPlayer, pSui, eventIndex, args)
    if pPlayer == nil then
        print("ERROR: handleAdPurchaseSui called with nil pPlayer")
        return
    end

    local player = LuaCreatureObject(pPlayer)
    if player == nil then
        print("ERROR: handleAdPurchaseSui - LuaCreatureObject returned nil")
        return
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

    -- Load ad manager if needed
    if not MySwgVendorAdManager then
        require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
    end

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
function myswg_vendor_convo_handler:getNextConversationScreen(conversationTemplate, conversingPlayer, selectedOption)            
        -- Assign the player to variable creature for use inside this function.
        local creature = LuaCreatureObject(conversingPlayer)
        -- Get the last conversation to determine whether or not we’re on the first screen      
        local convosession = creature:getConversationSession()  
        lastConversation = nil      
        local conversation = LuaConversationTemplate(conversationTemplate)  
        local nextConversationScreen     
        -- If there is a conversation open, do stuff with it        
        if ( conversation ~= nil ) then  -- check to see if we have a next screen   
            if ( convosession ~= nil ) then             
                local session = LuaConversationSession(convosession)
                if ( session ~= nil ) then                  
                    lastConversationScreen = session:getLastConversationScreen()   
                end         
            end         
            -- Last conversation was nil, so get the first screen
            if ( lastConversationScreen == nil ) then          
                nextConversationScreen = conversation:getInitialScreen()
            else
                -- Start playing the rest of the conversation based on user input               
                local luaLastConversationScreen = LuaConversationScreen(lastConversationScreen) 
                -- Set variable to track what option the player picked and get the option picked                
                local optionLink = luaLastConversationScreen:getOptionLink(selectedOption)
                nextConversationScreen = conversation:getScreen(optionLink)
                -- Get some information about the player.
                -- Wallet helpers: allow spending bank if cash is short
local function canAfford(cost)
  return (creature:getCashCredits() + creature:getBankCredits()) >= cost
end

local function charge(cost)
  local cash = creature:getCashCredits()
  if cash >= cost then
    creature:subtractCashCredits(cost)
  else
    if cash > 0 then creature:subtractCashCredits(cash) end
    creature:subtractBankCredits(cost - cash)
  end
end

-- Top-level inventory scan only (no recursion)
local function playerHasTemplateTopLevel(creatureObj, templatePath)
    if creatureObj == nil then return false end
    local pInv = creatureObj:getSlottedObject("inventory")
    if pInv == nil then return false end

    local invSO = SceneObject(pInv)
    local n = invSO:getContainerObjectsSize()
    for i = 0, n - 1 do
        local pChild = invSO:getContainerObject(i)
        if pChild ~= nil then
            local child = LuaSceneObject(pChild)
            if child:getTemplateObjectPath() == templatePath then
                return true
            end
        end
    end
    return false
end

--========================================================
-- Travel destinations for mySWG Vendor "Travel" menu
--========================================================
local MySwgTravelDestinations = {
	-- Force Crystal Cave on Dantooine (FCC)
	forceCrystalCave = {
		planet = "dantooine",
		x      = -6216,
		z      = 49,
		y      = 7381,
		cell   = 0
	},

	-- Nightsister Rancor Cave on Dathomir
	rancorCave = {
		planet = "dathomir",
		x      = -4258,
		z      = 92,
		y      = -2051,
		cell   = 0
	},

	-- GCW Lost Aqualish Cave on Talus
	gcwCave = {
		planet = "talus",
		x      = -4385,
		z      = 57,
		y      = -1400,
		cell   = 0
	},

	-- Blue Shadow Virus Bunker (exitClearArea coords)
	blueShadowVirus = {
		planet = "naboo",
		x      = -3605.5,
		z      = 29.8,
		y      = 759.8,
		cell   = 0
	}
}
--========================================================
                local pInventory = creature:getSlottedObject("inventory")
                local inventory = LuaSceneObject(pInventory)
                -- Take action when the player makes a purchase.
                --if (inventory:hasFullContainerObjects() == true) then -- removed, does not work
                if (SceneObject(pInventory):isContainerFullRecursive()) then
                    -- Bail if the player doesn’t have enough space in their inventory.
                    -- Plays a chat box message from the NPC as well as a system message.
                    nextConversationScreen = conversation:getScreen("insufficient_space")
                    creature:sendSystemMessage("You do not have enough inventory space")
                    
--                if (optionLink == "buff1" and not canAfford(5000)) then
--                    -- Bail if the player doesn’t have enough cash on hand.  
--                    -- Plays a chat box message from the NPC as well as a system message.
--                      nextConversationScreen = conversation:getScreen("insufficient_funds")
--                      creature:sendSystemMessage("You have insufficient funds") 
--                elseif (optionLink == "buff1" and canAfford(5000)) then
--                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
--                    charge(5000)
--                    local pItem = 
--										CreatureObject(conversingPlayer):enhanceCharacter()
										--buffTerminalMenuComponent:logUsage(conversingPlayer, "enhanceCharacter")
                    --giveItem(pInventory, "object/tangible/deed/vehicle_deed/speederbike_deed.iff", -1)
                    --createLoot(pInventory, "junk", 1, false)
                    
--                elseif (optionLink == "buff2" and not canAfford(10000000)) then
--                    -- Bail if the player doesn’t have enough cash on hand.  
--                    -- Plays a chat box message from the NPC as well as a system message.
--                      nextConversationScreen = conversation:getScreen("insufficient_funds")
--                      creature:sendSystemMessage("You have insufficient funds") 
--                elseif (optionLink == "buff2" and canAfford(10000000)) then
--                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
--                    charge(10000000)
--                    local pItem = 
--										CreatureObject(conversingPlayer):enhanceCharacter()
--                    --giveItem(pInventory, "object/tangible/deed/vehicle_deed/speederbike_deed.iff", -1)
--                    --createLoot(pInventory, "junk", 300, false)


--WEAPONS
                elseif (optionLink == "option1" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option1" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/weapon/ranged/carbine/carbine_dh17_snubnose.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option2" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option2" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/weapon/ranged/rifle/rifle_dlt20a.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option3" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option3" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/weapon/ranged/pistol/pistol_dl44.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option4" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option4" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/melee/sword/sword_01.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option5" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option5" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/melee/2h_sword/2h_sword_battleaxe.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option6" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option6" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/melee/polearm/lance_staff_wood_s2.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option7" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option7" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/melee/special/vibroknuckler.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option8" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option8" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/ranged/rifle/rifle_lightning.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option9" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option9" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/ranged/rifle/rifle_flame_thrower.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option10" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option10" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/ranged/rifle/rifle_acid_beam.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option11" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option11" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/ranged/grenade/grenade_proton.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option55" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option55" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/weapon/ranged/heavy/heavy_rocket_launcher.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
--ARMORRRRRR
                elseif (optionLink == "option12" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option12" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
										
                    giveItem(pInventory, "object/tangible/wearables/armor/ubese/armor_ubese_pants.iff", -1)
                    --createLoot(pInventory, "composite_armor", 50, false)
                    
                elseif (optionLink == "option13" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option13" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/wearables/armor/ubese/armor_ubese_jacket.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option14" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option14" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/wearables/armor/ubese/armor_ubese_helmet.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option15" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option15" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/ubese/armor_ubese_bracer_l.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option16" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option16" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
										
                    giveItem(pInventory, "object/tangible/wearables/armor/chitin/armor_chitin_s01_leggings.iff", -1)
                    --createLoot(pInventory, "kashyyykian_hunting_armor", 50, false)
                    
                elseif (optionLink == "option17" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option17" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/chitin/armor_chitin_s01_chest_plate.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option18" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option18" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/chitin/armor_chitin_s01_helmet.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option19" and not canAfford(25000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option19" and canAfford(25000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(25000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/chitin/armor_chitin_s01_bracer_l.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option20" and not canAfford(250000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option20" and canAfford(250000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(250000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
										
                    giveItem(pInventory, "object/tangible/wearables/armor/composite/armor_composite_leggings.iff", -1)
                    --createLoot(pInventory, "ithorian_sentinel_armor", 50, false)
                    
                elseif (optionLink == "option21" and not canAfford(250000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option21" and canAfford(250000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(250000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/composite/armor_composite_chest_plate.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option22" and not canAfford(250000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option22" and canAfford(250000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(250000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/composite/armor_composite_helmet.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option23" and not canAfford(250000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option23" and canAfford(250000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(250000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/composite/armor_composite_gloves.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)

		 elseif (optionLink == "option24" and not canAfford(250000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option24" and canAfford(250000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(250000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/wearables/armor/composite/armor_composite_bracer_l.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                                       
--ARTISAN
                elseif (optionLink == "option28" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option28" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/deed/vehicle_deed/speederbike_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option26" and not canAfford(1000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option26" and canAfford(1000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(1000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/crafting/station/generic_tool.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option27" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option27" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/wearables/backpack/backpack_s01.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option29" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option29" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/harvester_deed/harvester_ore_s2_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option30" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option30" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/harvester_deed/harvester_flora_deed_medium.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option31" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option31" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/harvester_deed/harvester_gas_deed_medium.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option32" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option32" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/harvester_deed/harvester_liquid_deed_medium.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option33" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option33" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/harvester_deed/harvester_moisture_deed_medium.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option88" and not canAfford(500)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option88" and canAfford(500)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(500)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/survey_tool/survey_tool_mineral.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option25" and not canAfford(500)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option25" and canAfford(500)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(500)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/survey_tool/survey_tool_liquid.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)

                elseif (optionLink == "option89" and not canAfford(100000)) then
                    nextConversationScreen = conversation:getScreen("insufficient_funds")
                    creature:sendSystemMessage("You have insufficient funds")
                elseif (optionLink == "option89" and canAfford(100000)) then
                    charge(100000)
                    local pItem = giveItem(pInventory, "object/tangible/survey_tool/survey_tool_all.iff", -1)    

                elseif (optionLink == "option66" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option66" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/weapon_repair.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option67" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option67" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/armor_repair.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)        
                    
                elseif (optionLink == "option68" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option68" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/slicing/slicing_weapon_upgrade_kit.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option69" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option69" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/slicing/slicing_armor_upgrade_kit.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)        
                    
--TAILOR-------------------
                elseif (optionLink == "option70" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option70" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/component/clothing/reinforced_fiber_panels.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option71" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option71" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/component/clothing/synthetic_cloth.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)    
                    
                elseif (optionLink == "option76" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option76" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/component/clothing/fiberplast_panel.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
--ARCHITECT
                elseif (optionLink == "option34" and not canAfford(200000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option34" and canAfford(200000)) then
                    -- Take 200,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(200000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/deed/player_house_deed/generic_house_small_style_02_floor_02_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option35" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option35" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/deed/player_house_deed/generic_house_medium_style_02_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option36" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option36" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/deed/factory_deed/factory_clothing_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option37" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option37" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/factory_deed/factory_food_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option38" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option38" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/factory_deed/factory_item_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option39" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option39" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/deed/factory_deed/factory_structure_deed.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option72" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option72" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/clothing_station.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option73" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option73" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/food_station.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)   
                    
                elseif (optionLink == "option74" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option74" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/weapon_station.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option75" and not canAfford(50000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option75" and canAfford(50000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(50000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/crafting/station/structure_station.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)   
                    
--cheffff

                elseif (optionLink == "option40" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option40" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/food/crafted/dessert_air_cake.iff", -1)
                    --createLoot(pInventory, "food2", 300, false)--food2
                    
                elseif (optionLink == "option41" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option41" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/food/crafted/dish_crispic.iff", -1)
                    --createLoot(pInventory, "food1", 300, false)
                    
                elseif (optionLink == "option42" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option42" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacter()
                    giveItem(pInventory, "object/tangible/food/crafted/drink_vasarian_brandy.iff", -1)
                    --createLoot(pInventory, "food5", 300, false)
                    
                elseif (optionLink == "option43" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option43" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/food/crafted/drink_garrmorl.iff", -1)
                    --createLoot(pInventory, "food4", 300, false)
                    
                elseif (optionLink == "option44" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option44" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/food/crafted/drink_accarragm.iff", -1)
                    --createLoot(pInventory, "food3", 300, false)
                    
                elseif (optionLink == "option45" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option45" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/food/crafted/drink_blue_milk.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)                  


--LOOT
                elseif (optionLink == "option56" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option56" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "pistols", 20, false)
                elseif (optionLink == "option57" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option57" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "carbines", 20, false)  
                elseif (optionLink == "option58" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option58" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "rifles", 20, false)
                elseif (optionLink == "option59" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option59" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "melee_knife", 20, false)   
                 elseif (optionLink == "option60" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option60" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "melee_two_handed", 20, false)    
                 elseif (optionLink == "option61" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option61" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "melee_polearm", 20, false)                                    
                 elseif (optionLink == "option62" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option62" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "melee_unarmed", 20, false)
                 elseif (optionLink == "option63" and not canAfford(15000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option63" and canAfford(15000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(15000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "heavy_weapons_rifle", 20, false)    



                elseif (optionLink == "option46" and not canAfford(500000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option46" and canAfford(500000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(500000)
                    local pItem = 
                    giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option49" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option49" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "weapons_all", 300, false)
                    
                elseif (optionLink == "option48" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option48" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "armor_all", 300, false)
                    
                elseif (optionLink == "option47" and not canAfford(100000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option47" and canAfford(100000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(100000)
                    local pItem = 
                    --giveItem(pInventory, "object/tangible/veteran_reward/resource.iff", -1)
                    createLoot(pInventory, "wearables_all", 300, false)
                    
--DOCTOR
                    
                elseif (optionLink == "buff1" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "buff1" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                   
										CreatureObject(conversingPlayer):enhanceCharacter()
										--buffTerminalMenuComponent:logUsage(conversingPlayer, "enhanceCharacter")
                    --giveItem(pInventory, "object/tangible/deed/vehicle_deed/speederbike_deed.iff", -1)
                    --createLoot(pInventory, "junk", 1, false)
                    
                elseif (optionLink == "reset_buffs" and not canAfford(2000)) then
                    nextConversationScreen = conversation:getScreen("insufficient_funds")
                    creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "reset_buffs" and canAfford(2000)) then
                    charge(2000)
                    CreatureObject(conversingPlayer):reset_buffs()

                elseif (optionLink == "petbuff_option1" and not canAfford(10000)) then
                    -- Bail if the player doesn't have enough cash on hand.
                    nextConversationScreen = conversation:getScreen("insufficient_funds")
                    creature:sendSystemMessage("You have insufficient funds")
                elseif (optionLink == "petbuff_option1" and canAfford(10000)) then
                    -- Charge player for pet enhancement
                    charge(10000)
                    -- Apply pet enhancement
                    CreatureObject(conversingPlayer):enhancePet()

               -- elseif (optionLink == "buff3" and not canAfford(30000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                   --   nextConversationScreen = conversation:getScreen("insufficient_funds")
                   --   creature:sendSystemMessage("You have insufficient funds") 
               -- elseif (optionLink == "buff3" and canAfford(30000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                 --   charge(30000)

										--CreatureObject(conversingPlayer):enhanceCharacterDocBuffTHREE()

               -- elseif (optionLink == "buff4" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                --      nextConversationScreen = conversation:getScreen("insufficient_funds")
                --      creature:sendSystemMessage("You have insufficient funds") 
               -- elseif (optionLink == "buff4" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    
	               --   charge(10000)
	                  
									--	CreatureObject(conversingPlayer):enhanceCharacterEntBuffONE()

               -- elseif (optionLink == "buff5" and not canAfford(20000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                  --    nextConversationScreen = conversation:getScreen("insufficient_funds")
                 --     creature:sendSystemMessage("You have insufficient funds") 
               -- elseif (optionLink == "buff5" and canAfford(20000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    
	               --   charge(20000)

										--CreatureObject(conversingPlayer):enhanceCharacterEntBuffTWO()


                elseif (optionLink == "option50" and not canAfford(500)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option50" and canAfford(500)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(500)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/medicine/crafted/crafted_stimpack_sm_s1_a.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option51" and not canAfford(1000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option51" and canAfford(1000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(1000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/medicine/crafted/crafted_stimpack_sm_s1_b.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option52" and not canAfford(2000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option52" and canAfford(2000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(2000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/medicine/crafted/crafted_stimpack_sm_s1_c.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option53" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option53" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/medicine/crafted/crafted_stimpack_sm_s1_d.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)
                    
                elseif (optionLink == "option54" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option54" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/medicine/crafted/crafted_stimpack_sm_s1_e.iff", -1)
                    --createLoot(pInventory, "junk", 300, false)

--TRAVEL
elseif (optionLink == "option301") then
  local PRICE    = 25000
  local TEMPLATE = "object/tangible/item/return_ticket.iff"

  -- Resolve inventory first
  local pInventory = creature:getSlottedObject("inventory")
  if pInventory == nil then
    nextConversationScreen = conversation:getScreen("insufficient_space")
    return nextConversationScreen
  end

  -- Space gate
  if SceneObject(pInventory):isContainerFullRecursive() then
    nextConversationScreen = conversation:getScreen("insufficient_space")
    creature:sendSystemMessage("You do not have enough inventory space")
    return nextConversationScreen
  end

  -- Unique-ownership (TOP-LEVEL ONLY)
  if playerHasTemplateTopLevel(creature, TEMPLATE) then
    nextConversationScreen = conversation:getScreen("first_screen")
    creature:sendSystemMessage("You already have a Return Ticket. Use or discard it before buying another.")
    return nextConversationScreen
  end

  -- Funds
  if not canAfford(PRICE) then
    nextConversationScreen = conversation:getScreen("insufficient_funds")
    creature:sendSystemMessage("You have insufficient funds")
    return nextConversationScreen
  end

  -- Charge and deliver
  charge(PRICE)
  local pItem = giveItem(pInventory, TEMPLATE, -1)
  if pItem == nil then
    creature:addBankCredits(PRICE)                  -- refund on failure
    nextConversationScreen = conversation:getScreen("insufficient_space")
    creature:sendSystemMessage("Purchase failed. Please free inventory space and try again.")
    return nextConversationScreen
  end

  creature:sendSystemMessage("Purchased: Return Ticket (Coronet) for 25,000 credits.")
  nextConversationScreen = conversation:getScreen("first_screen")
  return nextConversationScreen

  -- Teleport: Force Crystal Cave (Dantooine)
elseif (optionLink == "travel_force_cave_teleport") then
    local PRICE = 25000
    local dest  = MySwgTravelDestinations.forceCrystalCave

    if not canAfford(PRICE) then
        nextConversationScreen = conversation:getScreen("insufficient_funds")
        creature:sendSystemMessage("You have insufficient funds")
        return nextConversationScreen
    end

    local player = CreatureObject(conversingPlayer)
    if player:isRidingMount() then
        player:dismount()
    end

    charge(PRICE)
    SceneObject(conversingPlayer):switchZone(dest.planet, dest.x, dest.z, dest.y, dest.cell or 0)
    creature:sendSystemMessage("Travelling to the Force Crystal Cave on Dantooine...")
    nextConversationScreen = conversation:getScreen("travel_complete")
    return nextConversationScreen

-- Teleport: Nightsister Rancor Cave (Dathomir)
elseif (optionLink == "travel_nightsister_cave_teleport") then
    local PRICE = 25000
    local dest  = MySwgTravelDestinations.rancorCave

    if not canAfford(PRICE) then
        nextConversationScreen = conversation:getScreen("insufficient_funds")
        creature:sendSystemMessage("You have insufficient funds")
        return nextConversationScreen
    end

    local player = CreatureObject(conversingPlayer)
    if player:isRidingMount() then
        player:dismount()
    end

    charge(PRICE)
    SceneObject(conversingPlayer):switchZone(dest.planet, dest.x, dest.z, dest.y, dest.cell or 0)
    creature:sendSystemMessage("Travelling to the Nightsister Rancor Cave on Dathomir...")
    nextConversationScreen = conversation:getScreen("travel_complete")
    return nextConversationScreen

-- Teleport: GCW Lost Aqualish Cave (Talus)
elseif (optionLink == "travel_gcw_cave_teleport") then
    local PRICE = 25000
    local dest  = MySwgTravelDestinations.gcwCave

    if not canAfford(PRICE) then
        nextConversationScreen = conversation:getScreen("insufficient_funds")
        creature:sendSystemMessage("You have insufficient funds")
        return nextConversationScreen
    end

    local player = CreatureObject(conversingPlayer)
    if player:isRidingMount() then
        player:dismount()
    end

    charge(PRICE)
    SceneObject(conversingPlayer):switchZone(dest.planet, dest.x, dest.z, dest.y, dest.cell or 0)
    creature:sendSystemMessage("Travelling to the GCW Cave on Talus...")
    nextConversationScreen = conversation:getScreen("travel_complete")
    return nextConversationScreen

-- Teleport: Blue Shadow Virus Bunker (Naboo)
elseif (optionLink == "travel_bsv_teleport") then
    local PRICE = 25000
    local dest  = MySwgTravelDestinations.blueShadowVirus

    if not canAfford(PRICE) then
        nextConversationScreen = conversation:getScreen("insufficient_funds")
        creature:sendSystemMessage("You have insufficient funds")
        return nextConversationScreen
    end

    local player = CreatureObject(conversingPlayer)
    if player:isRidingMount() then
        player:dismount()
    end

    charge(PRICE)
    SceneObject(conversingPlayer):switchZone(dest.planet, dest.x, dest.z, dest.y, dest.cell or 0)
    creature:sendSystemMessage("Travelling to the Blue Shadow Virus Bunker on Naboo...")
    nextConversationScreen = conversation:getScreen("travel_complete")
    return nextConversationScreen

-- LANGUAGES
elseif (optionLink == "learn_all_languages") then
    -- Get skill manager
    local skillManager = LuaSkillManager()

    -- Award all language skills (both comprehend and speak for each language)
    -- Pass conversingPlayer directly (raw pointer), not wrapped with CreatureObject()
    skillManager:awardSkill(conversingPlayer, "social_language_basic_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_basic_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_rodian_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_rodian_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_trandoshan_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_trandoshan_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_moncalamari_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_moncalamari_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_wookiee_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_wookiee_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_bothan_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_bothan_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_twilek_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_twilek_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_zabrak_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_zabrak_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_lekku_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_lekku_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_ithorian_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_ithorian_comprehend")
    skillManager:awardSkill(conversingPlayer, "social_language_sullustan_speak")
    skillManager:awardSkill(conversingPlayer, "social_language_sullustan_comprehend")

    creature:sendSystemMessage("You have learned all languages! You can now speak and understand all galactic languages.")
    nextConversationScreen = conversation:getScreen("learn_all_languages")
    return nextConversationScreen



--DROIDS  
                    
                elseif (optionLink == "option64" and not canAfford(5000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option64" and canAfford(5000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(5000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/mission/mission_bounty_droid_seeker.iff", -1)
                    --createLoot(pInventory, "junk", 300, false) 
                    
                elseif (optionLink == "option65" and not canAfford(10000)) then
                    -- Bail if the player doesn’t have enough cash on hand.  
                    -- Plays a chat box message from the NPC as well as a system message.
                      nextConversationScreen = conversation:getScreen("insufficient_funds")
                      creature:sendSystemMessage("You have insufficient funds") 
                elseif (optionLink == "option65" and canAfford(10000)) then
                    -- Take 10,000 credits from the player’s cash on hand and give player a speederbike.
                    charge(10000)
                    local pItem = 
										--CreatureObject(conversingPlayer):enhanceCharacterDocBuff()
                    giveItem(pInventory, "object/tangible/mission/mission_bounty_droid_probot.iff", -1)
                    --createLoot(pInventory, "junk", 300, false) 
                  -- Add this new option for Politician Master
                
               -- elseif (optionLink == "option300" and not canAfford(50000)) then
                    -- Bail if the player doesn't have enough cash on hand.  
               --     nextConversationScreen = conversation:getScreen("insufficient_funds")
               --     creature:sendSystemMessage("You have insufficient funds") 
               -- elseif (optionLink == "option300" and canAfford(50000)) then
                    -- Take 50,000 credits from the player's cash on hand and grant politician master
               --     charge(50000)
    
                    -- Grant politician master access (you can customize what this does)
                -- Grant politician skills (you'll need to find the correct skill names)
               --   CreatureObject(conversingPlayer):addSkill("social_politician_master")
                    -- or whatever the actual politician skill names are in your server
    
                -- Or if you want to give an item instead:
                -- giveItem(pInventory, "object/tangible/politician_master_token.iff", -1)
    
                -- Send confirmation message
               -- creature:sendSystemMessage("You have been granted Politician Master access!")

                -- Advertisement System Handlers
                elseif (optionLink == "ad_view_queue") then
                    -- View the current ad queue - send as system message
                    if not MySwgVendorAdManager then
                        local success, err = pcall(function()
                            require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
                        end)
                        if not success then
                            print("ERROR: Failed to load ad_manager in ad_view_queue: " .. tostring(err))
                        end
                    end

                    local queueStatus = "No advertisements currently active.\n\nPurchase your ad space now!"
                    if MySwgVendorAdManager and type(MySwgVendorAdManager.getQueueStatus) == "function" then
                        queueStatus = MySwgVendorAdManager:getQueueStatus()
                    end

                    -- Send queue status as system messages (split by newlines)
                    local lines = {}
                    for line in string.gmatch(queueStatus, "[^\n]+") do
                        table.insert(lines, line)
                    end

                    for _, line in ipairs(lines) do
                        creature:sendSystemMessage(line)
                    end

                    -- Return to main menu
                    nextConversationScreen = conversation:getScreen("intro")

                elseif (optionLink == "ad_purchase_proceed") then
                    -- Purchase advertisement - check if they can afford it first
                    if not canAfford(100000) then
                        nextConversationScreen = conversation:getScreen("insufficient_funds")
                        creature:sendSystemMessage("You need 100,000 credits to purchase advertisement space")
                    else
                        -- Load the ad modules in this context (needed for SUI callback)
                        if not MySwgVendorAdManager then
                            local success, err = pcall(function()
                                require("screenplays.tasks.naboo.myswg_vendor_ad_manager")
                            end)
                            if not success then
                                print("ERROR: Failed to load ad_manager: " .. tostring(err))
                            end
                        end

                        if not MySwgVendorAdSui then
                            local success, err = pcall(function()
                                require("screenplays.tasks.naboo.myswg_vendor_ad_sui")
                            end)
                            if not success then
                                print("ERROR: Failed to load ad_sui in conversation handler: " .. tostring(err))
                                creature:sendSystemMessage("ERROR: Advertisement system failed to load. Please contact an administrator.")
                                return nil
                            end
                        end

                        if MySwgVendorAdSui and MySwgVendorAdSui.promptForAd then
                            MySwgVendorAdSui:promptForAd(conversingPlayer)
                        else
                            print("ERROR: MySwgVendorAdSui or promptForAd is nil!")
                            creature:sendSystemMessage("ERROR: Advertisement system not available. Please contact an administrator.")
                        end

                        -- Close conversation
                        return nil
                    end

                end
            end
        end
        -- end of the conversation logic.
        return nextConversationScreen
    end
    function myswg_vendor_convo_handler:runScreenHandlers(conversationTemplate, conversingPlayer, conversingNPC, selectedOption, conversationScreen)
    -- Plays the screens of the conversation.
    return conversationScreen
end
