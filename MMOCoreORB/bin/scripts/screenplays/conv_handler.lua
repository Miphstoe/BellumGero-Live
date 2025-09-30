conv_handler = Object:new {}

function conv_handler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
    local convsession = CreatureObject(pPlayer):getConversationSession()
    local lastConvScreen = nil
    if (convsession ~= nil) then
        local session = LuaConversationSession(convsession)
        lastConvScreen = session:getLastConversationScreen()
    end
    local conv = LuaConversationTemplate(pConvTemplate)
    local nextConvScreen
    if (lastConvScreen ~= nil) then
        local luaLastConvScreen = LuaConversationScreen(lastConvScreen)
        local optionLink = luaLastConvScreen:getOptionLink(selectedOption)
        nextConvScreen = conv:getScreen(optionLink)
        if nextConvScreen == nil then
            nextConvScreen = self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
        end
    else
        nextConvScreen = self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    end
    return nextConvScreen
end

function conv_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    local convTemplate = LuaConversationTemplate(pConvTemplate)
    return convTemplate:getInitialScreen()
end

function conv_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    local screen = LuaConversationScreen(pConvScreen)
    local screenId = screen:getScreenID()
    
    print("[DEBUG] runScreenHandlers called with screenId: " .. tostring(screenId))
    
    -- Check if this is an attachment vendor trade screen (give_ screens are where we process)
    if string.find(screenId, "give_t1_") or string.find(screenId, "give_t2_") or string.find(screenId, "give_t3_") then
        print("[DEBUG] Detected attachment trade screen, calling handleAttachmentTrade")
        return self:handleAttachmentTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    end
    
    print("[DEBUG] Not a trade screen, returning pConvScreen")
    return pConvScreen
end

function conv_handler:handleAttachmentTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    print("[DEBUG] === ENTERED handleAttachmentTrade ===")
    print("[DEBUG] screenId parameter: " .. tostring(screenId))
   
    local screen = LuaConversationScreen(pConvScreen)
    print("[DEBUG] Created LuaConversationScreen")
   
    -- Determine tier and required attachments
    local requiredAttachments = 0
    local rewardInfo = nil
   
    if string.find(screenId, "give_t1_") then
        print("[DEBUG] Detected Tier 1 trade")
        requiredAttachments = 25
        rewardInfo = self:getTier1Reward(screenId)
    elseif string.find(screenId, "give_t2_") then
        print("[DEBUG] Detected Tier 2 trade")
        requiredAttachments = 50
        rewardInfo = self:getTier2Reward(screenId)
    elseif string.find(screenId, "give_t3_") then
        print("[DEBUG] Detected Tier 3 trade")
        requiredAttachments = 75
        rewardInfo = self:getTier3Reward(screenId)
    end
   
    print("[DEBUG] rewardInfo: " .. tostring(rewardInfo))
    if rewardInfo then
        print("[DEBUG] Reward name: " .. rewardInfo.name)
        print("[DEBUG] Reward template: " .. rewardInfo.template)
    end
   
    if not rewardInfo then
        print("[DEBUG] ERROR: No reward info found for screenId: " .. screenId)
        screen:setCustomDialogText("Error: Invalid reward selection.")
        return pConvScreen
    end
   
    print("[DEBUG] === STARTING " .. rewardInfo.name .. " TRADE ===")
    print("[DEBUG] Required attachments: " .. requiredAttachments)
   
    -- Count attachments
    print("[DEBUG] About to count attachments...")
    local success, attachmentCount = pcall(function() 
        return self:countAttachments(pPlayer) 
    end)
   
    print("[DEBUG] Count pcall returned - success: " .. tostring(success) .. ", result: " .. tostring(attachmentCount))
   
    if not success then
        print("[DEBUG] Error counting attachments: " .. tostring(attachmentCount))
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end
   
    print("[DEBUG] Found " .. attachmentCount .. " attachments")
   
    if attachmentCount < requiredAttachments then
        screen:setCustomDialogText("You only have " .. attachmentCount .. " attachments, but need " .. requiredAttachments .. ". Please collect more!")
        return pConvScreen
    end
   
    -- Remove attachments
    print("[DEBUG] About to remove attachments...")
    local removeSuccess, removedCount = pcall(function()
        return self:removeAttachments(pPlayer, requiredAttachments)
    end)
   
    if not removeSuccess or removedCount < requiredAttachments then
        print("[DEBUG] Error removing attachments. Removed: " .. (removedCount or 0))
        screen:setCustomDialogText("Error removing attachments. Trade cancelled.")
        return pConvScreen
    end
   
    print("[DEBUG] Successfully removed " .. removedCount .. " attachments")
   
    -- Give reward
    print("[DEBUG] About to give reward...")
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)
   
    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " attachments removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
        print("[DEBUG] Successfully gave " .. rewardInfo.name .. " to player")
    else
        screen:setCustomDialogText("Attachments removed but error giving reward. Contact an admin.")
        print("[DEBUG] Failed to give " .. rewardInfo.name)
    end
   
    return pConvScreen
end

function conv_handler:getTier1Reward(screenId)
    local rewards = {
        ["give_t1_01"] = {name = "Star Map", template = "object/tangible/painting/painting_starmap.iff"},
        ["give_t1_02"] = {name = "Waterfall", template = "object/tangible/painting/painting_waterfall.iff"},
        ["give_t1_03"] = {name = "Bestine Painting 1", template = "object/tangible/painting/bestine_history_quest_painting.iff"},
        ["give_t1_04"] = {name = "Bestine Painting 2", template = "object/tangible/painting/bestine_quest_painting.iff"},
        ["give_t1_05"] = {name = "Tatooine Tapestry", template = "object/tangible/furniture/decorative/tatooine_tapestry.iff"},
        ["give_t1_06"] = {name = "Bestine House", template = "object/tangible/painting/painting_bestine_house.iff"},
        ["give_t1_07"] = {name = "Krayt Dragon Skeleton", template = "object/tangible/painting/painting_bestine_krayt_skeleton.iff"},
        ["give_t1_08"] = {name = "Stormtrooper", template = "object/tangible/painting/painting_bw_stormtrooper.iff"},
        ["give_t1_09"] = {name = "Schematic (Droid)", template = "object/tangible/painting/painting_schematic_droid.iff"},
        ["give_t1_10"] = {name = "Schematic (Transport Ship)", template = "object/tangible/painting/painting_schematic_transport_ship.iff"},
        ["give_t1_11"] = {name = "Schematic (Weapon)", template = "object/tangible/painting/painting_schematic_weapon.iff"},
        ["give_t1_12"] = {name = "Schematic (Weapon) 3", template = "object/tangible/painting/painting_schematic_weapon_s03.iff"},
    }
    return rewards[screenId]
end

function conv_handler:getTier2Reward(screenId)
    local rewards = {
        ["give_t2_01"] = {name = "Dark Banner", template = "object/tangible/furniture/jedi/frn_all_banner_dark.iff"},
        ["give_t2_02"] = {name = "Light Banner", template = "object/tangible/furniture/jedi/frn_all_banner_light.iff"},
        ["give_t2_03"] = {name = "Dark Chair (Style 1)", template = "object/tangible/furniture/jedi/frn_all_dark_chair_s01.iff"},
        ["give_t2_04"] = {name = "Dark Chair (Style 2)", template = "object/tangible/furniture/jedi/frn_all_dark_chair_s02.iff"},
        ["give_t2_05"] = {name = "Dark Throne", template = "object/tangible/furniture/jedi/frn_all_dark_throne.iff"},
        ["give_t2_06"] = {name = "Light Chair (Style 1)", template = "object/tangible/furniture/jedi/frn_all_light_chair_s01.iff"},
        ["give_t2_07"] = {name = "Light Chair (Style 2)", template = "object/tangible/furniture/jedi/frn_all_light_chair_s02.iff"},
        ["give_t2_08"] = {name = "Light Throne", template = "object/tangible/furniture/jedi/frn_all_light_throne.iff"},
        ["give_t2_09"] = {name = "Dark Table (Style 1)", template = "object/tangible/furniture/jedi/frn_all_table_dark_01.iff"},
        ["give_t2_10"] = {name = "Dark Table (Style 2)", template = "object/tangible/furniture/jedi/frn_all_table_dark_02.iff"},
        ["give_t2_11"] = {name = "Light Table (Style 1)", template = "object/tangible/furniture/jedi/frn_all_table_light_01.iff"},
        ["give_t2_12"] = {name = "Light Table (Style 2)", template = "object/tangible/furniture/jedi/frn_all_table_light_02.iff"},
        ["give_t2_13"] = {name = "Jedi Council Seat", template = "object/tangible/furniture/all/frn_all_jedi_council_seat.iff"},
    }
    return rewards[screenId]
end

function conv_handler:getTier3Reward(screenId)
    local rewards = {
        ["give_t3_01"] = {name = "Bacta Tank", template = "object/tangible/item/quest/force_sensitive/bacta_tank.iff"},
        ["give_t3_02"] = {name = "Hanging Planter", template = "object/tangible/furniture/decorative/hanging_planter.iff"},
        ["give_t3_03"] = {name = "Stuffed Fish", template = "object/tangible/furniture/decorative/stuffed_fish.iff"},
        ["give_t3_04"] = {name = "Blowfish", template = "object/tangible/fishing/fish/blowfish.iff"},
        ["give_t3_05"] = {name = "Decorative Campfire", template = "object/tangible/furniture/decorative/campfire.iff"},
        ["give_t3_06"] = {name = "Microphone", template = "object/tangible/furniture/decorative/microphone_s01.iff"},
        ["give_t3_07"] = {name = "VR: Cast Wing in Flight", template = "object/tangible/veteran_reward/one_year_anniversary/painting_01.iff"},
        ["give_t3_08"] = {name = "VR: Decimator", template = "object/tangible/veteran_reward/one_year_anniversary/painting_02.iff"},
        ["give_t3_09"] = {name = "VR: Weapon of War", template = "object/tangible/veteran_reward/one_year_anniversary/painting_04.iff"},
        ["give_t3_10"] = {name = "VR: Tatooine Dune Speeder", template = "object/tangible/veteran_reward/one_year_anniversary/painting_03.iff"},
        ["give_t3_11"] = {name = "VR: Fighter Study", template = "object/tangible/veteran_reward/one_year_anniversary/painting_05.iff"},
        ["give_t3_12"] = {name = "VR: Hutt Greed", template = "object/tangible/veteran_reward/one_year_anniversary/painting_06.iff"},
        ["give_t3_13"] = {name = "VR: Smuggler's Run", template = "object/tangible/veteran_reward/one_year_anniversary/painting_07.iff"},
        ["give_t3_14"] = {name = "VR: Imperial TIE Oppressor", template = "object/tangible/veteran_reward/one_year_anniversary/painting_08.iff"},
        ["give_t3_15"] = {name = "VR: Emperor's Eyes TIE", template = "object/tangible/veteran_reward/one_year_anniversary/painting_09.iff"},
    }
    return rewards[screenId]
end

function conv_handler:countAttachments(pPlayer)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then 
        print("[DEBUG] Could not get LuaCreatureObject")
        return 0 
    end
    
    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then 
        print("[DEBUG] Could not get inventory")
        return 0 
    end
    
    local inventory = LuaSceneObject(pInventory)
    if not inventory then 
        print("[DEBUG] Could not get LuaSceneObject")
        return 0 
    end
    
    local count = 0
    local size = inventory:getContainerObjectsSize()
    
    for i = 0, size - 1 do
        local pObject = inventory:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local template = nil
                local objectName = nil
                
                local success1, result1 = pcall(function() return object:getObjectTemplate() end)
                if success1 then template = result1 end
                
                local success2, result2 = pcall(function() return object:getDisplayedName() end)
                if success2 then objectName = result2 end
                
                local isAttachment = false
                
                if template then
                    local lowerTemplate = string.lower(template)
                    if string.find(lowerTemplate, "attachment") or 
                       string.find(lowerTemplate, "skill_buff") or
                       string.find(lowerTemplate, "skill_enhancement") then
                        isAttachment = true
                    end
                end
                
                if objectName then
                    local lowerName = string.lower(objectName)
                    if string.find(lowerName, "aa") or
                       string.find(lowerName, "ca") or
                       string.find(lowerName, "sea") or
                       string.find(lowerName, "armor") or
                       string.find(lowerName, "clothing") or
                       string.find(lowerName, "attachment") or
                       string.find(lowerName, "skill") then
                        isAttachment = true
                    end
                end
                
                if isAttachment then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

function conv_handler:removeAttachments(pPlayer, count)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then 
        print("[DEBUG] Could not get LuaCreatureObject for removal")
        return 0 
    end
    
    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then 
        print("[DEBUG] Could not get inventory for removal")
        return 0 
    end
    
    local inventory = LuaSceneObject(pInventory)
    if not inventory then 
        print("[DEBUG] Could not get LuaSceneObject for removal")
        return 0 
    end
    
    local removed = 0
    local size = inventory:getContainerObjectsSize()
    
    for i = size - 1, 0, -1 do
        if removed >= count then break end
        
        local pObject = inventory:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local template = nil
                local objectName = nil
                
                local success1, result1 = pcall(function() return object:getObjectTemplate() end)
                if success1 then template = result1 end
                
                local success2, result2 = pcall(function() return object:getDisplayedName() end)
                if success2 then objectName = result2 end
                
                local isAttachment = false
                
                if template then
                    local lowerTemplate = string.lower(template)
                    if string.find(lowerTemplate, "attachment") or 
                       string.find(lowerTemplate, "skill_buff") or
                       string.find(lowerTemplate, "skill_enhancement") then
                        isAttachment = true
                    end
                end
                
                if objectName then
                    local lowerName = string.lower(objectName)
                    if string.find(lowerName, "aa") or
                       string.find(lowerName, "ca") or
                       string.find(lowerName, "sea") or
                       string.find(lowerName, "armor") or
                       string.find(lowerName, "clothing") or
                       string.find(lowerName, "attachment") or
                       string.find(lowerName, "skill") then
                        isAttachment = true
                    end
                end
                
                if isAttachment then
                    local destroySuccess = pcall(function() 
                        object:destroyObjectFromWorld() 
                    end)
                    
                    if destroySuccess then
                        removed = removed + 1
                    end
                end
            end
        end
    end
    
    return removed
end

function conv_handler:giveReward(pPlayer, template, rewardName, quantity)
    quantity = quantity or 1
    
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[ERROR] Could not get LuaCreatureObject for reward")
        return false
    end
    
    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[ERROR] Could not access player inventory for reward")
        return false
    end
    
    local success = 0
    for i = 1, quantity do
        local pReward = giveItem(pInventory, template, -1)
        if pReward then
            success = success + 1
        end
    end
    
    if success == quantity then
        return true
    else
        return false
    end
end