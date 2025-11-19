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

    -- Check if this is a bg_token vendor trade screen (vendor 1 or 2)
    if string.find(screenId, "give_item_") then
        print("[DEBUG] Detected bg_token vendor trade screen")
        -- Check if it's vendor 2 (75 tokens) vs vendor 1 (50 tokens)
        if string.find(screenId, "give_item_2_") then
            print("[DEBUG] Detected bg_token vendor 2 trade screen, calling handleBGTokenTrade2")
            return self:handleBGTokenTrade2(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
        else
            print("[DEBUG] Detected bg_token vendor 1 trade screen, calling handleBGTokenTrade")
            return self:handleBGTokenTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
        end
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

-- ============================= BG TOKEN VENDOR HANDLER =============================

function conv_handler:handleBGTokenTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    print("[BG-TOKEN] === ENTERED handleBGTokenTrade ===")
    print("[BG-TOKEN] screenId: " .. tostring(screenId))

    local screen = LuaConversationScreen(pConvScreen)
    local requiredTokens = 50

    -- Get reward info for this item
    local rewardInfo = self:getBGTokenReward(screenId)

    if not rewardInfo then
        print("[BG-TOKEN] ERROR: No reward info found for screenId: " .. screenId)
        screen:setCustomDialogText("Error: Invalid item selection.")
        return pConvScreen
    end

    print("[BG-TOKEN] === STARTING " .. rewardInfo.name .. " TRADE ===")
    print("[BG-TOKEN] Required tokens: " .. requiredTokens)

    -- Count bg_tokens
    print("[BG-TOKEN] About to count tokens...")
    local success, tokenCount = pcall(function()
        return self:countBGTokens(pPlayer)
    end)

    if not success then
        print("[BG-TOKEN] Error counting tokens: " .. tostring(tokenCount))
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end

    print("[BG-TOKEN] Found " .. tokenCount .. " tokens")

    if tokenCount < requiredTokens then
        screen:setCustomDialogText("You only have " .. tokenCount .. " Bellum Gero Tokens, but need " .. requiredTokens .. ". Please collect more!")
        return pConvScreen
    end

    -- Remove tokens
    print("[BG-TOKEN] About to remove tokens...")
    local removeSuccess, removedCount = pcall(function()
        return self:removeBGTokens(pPlayer, requiredTokens)
    end)

    if not removeSuccess or removedCount < requiredTokens then
        print("[BG-TOKEN] Error removing tokens. Removed: " .. (removedCount or 0))
        screen:setCustomDialogText("Error removing tokens. Trade cancelled.")
        return pConvScreen
    end

    print("[BG-TOKEN] Successfully removed " .. removedCount .. " tokens")

    -- Give reward
    print("[BG-TOKEN] About to give reward...")
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)

    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " Bellum Gero Tokens removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
        print("[BG-TOKEN] Successfully gave " .. rewardInfo.name .. " to player")
    else
        screen:setCustomDialogText("Tokens removed but error giving reward. Contact an admin.")
        print("[BG-TOKEN] Failed to give " .. rewardInfo.name)
    end

    return pConvScreen
end

-- ============================= BG TOKEN VENDOR 2 HANDLER (75 tokens) =============================

function conv_handler:handleBGTokenTrade2(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    print("[BG-TOKEN-2] === ENTERED handleBGTokenTrade2 ===")
    print("[BG-TOKEN-2] screenId: " .. tostring(screenId))

    local screen = LuaConversationScreen(pConvScreen)
    local requiredTokens = 75

    -- Get reward info for this item
    local rewardInfo = self:getBGTokenReward2(screenId)

    if not rewardInfo then
        print("[BG-TOKEN-2] ERROR: No reward info found for screenId: " .. screenId)
        screen:setCustomDialogText("Error: Invalid item selection.")
        return pConvScreen
    end

    print("[BG-TOKEN-2] === STARTING " .. rewardInfo.name .. " TRADE ===")
    print("[BG-TOKEN-2] Required tokens: " .. requiredTokens)

    -- Count bg_tokens
    print("[BG-TOKEN-2] About to count tokens...")
    local success, tokenCount = pcall(function()
        return self:countBGTokens(pPlayer)
    end)

    if not success then
        print("[BG-TOKEN-2] Error counting tokens: " .. tostring(tokenCount))
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end

    print("[BG-TOKEN-2] Found " .. tokenCount .. " tokens")

    if tokenCount < requiredTokens then
        screen:setCustomDialogText("You only have " .. tokenCount .. " Bellum Gero Tokens, but need " .. requiredTokens .. ". Please collect more!")
        return pConvScreen
    end

    -- Remove tokens
    print("[BG-TOKEN-2] About to remove tokens...")
    local removeSuccess, removedCount = pcall(function()
        return self:removeBGTokens(pPlayer, requiredTokens)
    end)

    if not removeSuccess or removedCount < requiredTokens then
        print("[BG-TOKEN-2] Error removing tokens. Removed: " .. (removedCount or 0))
        screen:setCustomDialogText("Error removing tokens. Trade cancelled.")
        return pConvScreen
    end

    print("[BG-TOKEN-2] Successfully removed " .. removedCount .. " tokens")

    -- Give reward
    print("[BG-TOKEN-2] About to give reward...")
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)

    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " Bellum Gero Tokens removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
        print("[BG-TOKEN-2] Successfully gave " .. rewardInfo.name .. " to player")
    else
        screen:setCustomDialogText("Tokens removed but error giving reward. Contact an admin.")
        print("[BG-TOKEN-2] Failed to give " .. rewardInfo.name)
    end

    return pConvScreen
end

function conv_handler:getBGTokenReward(screenId)
    -- Template mapping for 20 items - EDIT THE TEMPLATES AND NAMES BELOW
    local rewards = {
        ["give_item_01"] = {name = "LCD Screen", template = "object/tangible/furniture/all/frn_all_scrolling_screen.iff"},
        ["give_item_02"] = {name = "Imperial Banner on Pole", template = "object/tangible/gcw/flip_banner_onpole_imperial.iff"},
        ["give_item_03"] = {name = "Rebel Banner on Pole", template = "object/tangible/gcw/flip_banner_onpole_rebel.iff"},
        ["give_item_04"] = {name = "All in One Survey Tool", template = "object/tangible/survey_tool/survey_tool_all.iff"},
        ["give_item_05"] = {name = "Resource Deed", template = "object/tangible/veteran_reward/resource.iff"},
        ["give_item_06"] = {name = "2h Obsidian Sword Schematic", template = "object/tangible/loot/loot_schematic/2h_sword_obsidian_schematic.iff"},
        ["give_item_07"] = {name = "Blasterfist Schematic", template = "object/tangible/loot/loot_schematic/blasterfist_schematic.iff"},
        ["give_item_08"] = {name = "Obsidian Lance Schematic", template = "object/tangible/loot/loot_schematic/lance_obsidian_schematic.iff"},
        ["give_item_09"] = {name = "1h Obsidian Sword Schematic", template = "object/tangible/loot/loot_schematic/sword_obsidian_schematic.iff"},
        ["give_item_10"] = {name = "Spy Fang Schematic", template = "object/tangible/loot/loot_schematic/punchknuckler_schematic.iff"},
        ["give_item_11"] = {name = "DC-15 Rifle Schematic", template = "object/tangible/loot/loot_schematic/rifle_dc15_schematic.iff"},
        ["give_item_12"] = {name = "Black Falcon Pistol Schematic", template = "object/tangible/loot/loot_schematic/pistol_blackfalcon_schematic.iff"},
        ["give_item_13"] = {name = "E-5 Carbine Schematic", template = "object/tangible/loot/loot_schematic/carbine_e5_schematic.iff"},
        ["give_item_14"] = {name = "SMC Shirt", template = "object/tangible/wearables/shirt/singing_mountain_clan_shirt_s02.iff"},
        ["give_item_15"] = {name = "Rare Bestine Painting", template = "object/tangible/painting/bestine_quest_painting.iff"},
        ["give_item_16"] = {name = "Chemical Recycler", template = "object/tangible/recycler/chemical_recycler.iff"},
        ["give_item_17"] = {name = "Creature Recycler", template = "object/tangible/recycler/creature_recycler.iff"},
        ["give_item_18"] = {name = "Flora Recycler", template = "object/tangible/recycler/flora_recycler.iff"},
        ["give_item_19"] = {name = "Metal Recycler", template = "object/tangible/recycler/metal_recycler.iff"},
        ["give_item_20"] = {name = "Ore Recycler", template = "object/tangible/recycler/ore_recycler.iff"},
    }
    return rewards[screenId]
end

function conv_handler:getBGTokenReward2(screenId)
    -- Template mapping for 20 items - EDIT THE TEMPLATES AND NAMES BELOW
    -- Use "give_item_2_XX" format for this vendor
    local rewards = {
        ["give_item_2_01"] = {name = "Medium Oval Rug", template = "object/tangible/furniture/modern/rug_oval_m_s02.iff"},
        ["give_item_2_02"] = {name = "Small Oval Rug", template = "object/tangible/furniture/modern/rug_oval_sml_s01.iff"},
        ["give_item_2_03"] = {name = "Medium Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_m_s01.iff"},
        ["give_item_2_04"] = {name = "Small Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_sml_s01.iff"},
        ["give_item_2_05"] = {name = "Medium Round Rug", template = "object/tangible/furniture/modern/rug_rnd_m_s01.iff"},
        ["give_item_2_06"] = {name = "Small Round Rug", template = "object/tangible/furniture/modern/rug_rnd_sml_s01.iff"},
        ["give_item_2_07"] = {name = "Large Oval Rug", template = "object/tangible/furniture/modern/rug_oval_lg_s01.iff"},
        ["give_item_2_08"] = {name = "Large Rectugangulr Rug 01", template = "object/tangible/furniture/modern/rug_rect_lg_s01.iff"},
        ["give_item_2_09"] = {name = "Large Rectugangulr Rug 02", template = "object/tangible/furniture/modern/rug_rect_lg_s02.iff"},
        ["give_item_2_10"] = {name = "Large Round Rug", template = "object/tangible/furniture/modern/rug_rnd_lg_s01.iff"},
        ["give_item_2_11"] = {name = "Painting: Cast Wing in Flight", template = "object/tangible/veteran_reward/one_year_anniversary/painting_01.iff"},
        ["give_item_2_12"] = {name = "Painting: Decimator", template = "object/tangible/veteran_reward/one_year_anniversary/painting_02.iff"},
        ["give_item_2_13"] = {name = "Painting: Tatooine Dune Speeder", template = "object/tangible/veteran_reward/one_year_anniversary/painting_03.iff"},
        ["give_item_2_14"] = {name = "Painting: Weapon of War", template = "object/tangible/veteran_reward/one_year_anniversary/painting_04.iff"},
        ["give_item_2_15"] = {name = "Painting: Fighter Study", template = "object/tangible/veteran_reward/one_year_anniversary/painting_05.iff"},
        ["give_item_2_16"] = {name = "Painting: Hutt Greed", template = "object/tangible/veteran_reward/one_year_anniversary/painting_06.iff"},
        ["give_item_2_17"] = {name = "Painting: Smuggler's Run", template = "object/tangible/veteran_reward/one_year_anniversary/painting_07.iff"},
        ["give_item_2_18"] = {name = "Painting: Imperial Oppression (TIE Oppressor)", template = "object/tangible/veteran_reward/one_year_anniversary/painting_08.iff"},
        ["give_item_2_19"] = {name = "Painting: Emperor's Eyes (TIE Sentinel)", template = "object/tangible/veteran_reward/one_year_anniversary/painting_09.iff"},
        ["give_item_2_20"] = {name = "Large Potted Plant (Style 2)", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s2.iff"},
    }
    return rewards[screenId]
end

function conv_handler:countBGTokensInContainer(container)
    local tokenCount = 0
    if not container then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    print("[BG-TOKEN] Searching container with " .. size .. " items")

    for i = 0, size - 1 do
        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local success, displayedName = pcall(function() return object:getDisplayedName() end)
                if success and displayedName then
                    print("[BG-TOKEN] Found object: " .. displayedName)
                    if string.find(string.lower(displayedName), "bellum gero token") or
                       string.find(string.lower(displayedName), "bg_token") then
                        -- Try to get count, default to 1 if not countable
                        local countSuccess, count = pcall(function() return object:getCount() end)
                        if countSuccess and count and count > 0 then
                            print("[BG-TOKEN] Found " .. count .. " tokens in stack")
                            tokenCount = tokenCount + count
                        else
                            print("[BG-TOKEN] Found 1 token")
                            tokenCount = tokenCount + 1
                        end
                    else
                        -- Try to recursively search this object as a container
                        print("[BG-TOKEN] Checking if " .. displayedName .. " is a container...")
                        tokenCount = tokenCount + self:countBGTokensInContainer(pObject)
                    end
                end
            end
        end
    end

    return tokenCount
end

function conv_handler:countBGTokens(pPlayer)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[BG-TOKEN] Could not get LuaCreatureObject")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[BG-TOKEN] Could not get inventory")
        return 0
    end

    local tokenCount = self:countBGTokensInContainer(pInventory)

    print("[BG-TOKEN] Counted " .. tokenCount .. " tokens in inventory and containers")
    return tokenCount
end

function conv_handler:removeBGTokensFromContainer(container, count)
    local removed = 0
    if not container then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    print("[BG-TOKEN] Searching container for removal with " .. size .. " items")

    for i = size - 1, 0, -1 do
        if removed >= count then break end

        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local success, displayedName = pcall(function() return object:getDisplayedName() end)
                if success and displayedName then
                    if string.find(string.lower(displayedName), "bellum gero token") or
                       string.find(string.lower(displayedName), "bg_token") then

                        print("[BG-TOKEN] Found token to remove: " .. displayedName)
                        -- Try to get count
                        local countSuccess, itemCount = pcall(function() return object:getCount() end)
                        if countSuccess and itemCount and itemCount > 0 then
                            -- Item is countable (stackable)
                            local needToRemove = count - removed

                            if itemCount <= needToRemove then
                                -- Remove entire stack by destroying the object
                                pcall(function() object:destroyObjectFromWorld(true) end)
                                pcall(function() object:destroyObjectFromDatabase(true) end)
                                removed = removed + itemCount
                                print("[BG-TOKEN] Removed stack of " .. itemCount .. " tokens")
                            else
                                -- Remove partial stack
                                local setSuccess = pcall(function() object:setCount(itemCount - needToRemove) end)
                                if setSuccess then
                                    removed = count
                                    print("[BG-TOKEN] Removed " .. needToRemove .. " tokens from stack")
                                else
                                    -- If setCount fails, remove the entire item
                                    pcall(function() object:destroyObjectFromWorld(true) end)
                                    pcall(function() object:destroyObjectFromDatabase(true) end)
                                    removed = removed + itemCount
                                    print("[BG-TOKEN] Removed full stack due to setCount failure")
                                end
                            end
                        else
                            -- Single item (not countable)
                            pcall(function() object:destroyObjectFromWorld(true) end)
                            pcall(function() object:destroyObjectFromDatabase(true) end)
                            removed = removed + 1
                            print("[BG-TOKEN] Removed single token")
                        end
                    else
                        -- Try to recursively search this object as a container
                        if removed < count then
                            print("[BG-TOKEN] Checking if " .. displayedName .. " is a container for removal...")
                            removed = removed + self:removeBGTokensFromContainer(pObject, count - removed)
                        end
                    end
                end
            end
        end
    end

    return removed
end

function conv_handler:removeBGTokens(pPlayer, count)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[BG-TOKEN] Could not get LuaCreatureObject for removal")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[BG-TOKEN] Could not get inventory for removal")
        return 0
    end

    local removed = self:removeBGTokensFromContainer(pInventory, count)

    print("[BG-TOKEN] Successfully removed " .. removed .. " tokens from inventory and containers")
    return removed
end