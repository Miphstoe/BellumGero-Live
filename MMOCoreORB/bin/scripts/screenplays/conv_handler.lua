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
        local screenId = luaLastConvScreen:getScreenID()

        -- Check if this is the apprentice vendor confirm_trade screen
        if screenId == "confirm_trade" then
            local optionLink = luaLastConvScreen:getOptionLink(selectedOption)

            -- Only process if they selected "Yes, proceed with the trade"
            if optionLink == "give_apprentice_token" then
                local success, result = pcall(function()
                    return self:handleApprenticeXpTrade(pConvTemplate, pPlayer, pNpc, selectedOption, lastConvScreen)
                end)
                if success and result ~= nil then
                    return result
                else
                    if not success then
                    else
                    end
                    -- Fall through to normal flow if handler fails
                end
            end
        end

        -- Normal flow
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


    -- Check if this is an attachment vendor trade screen (give_ screens are where we process)
    if string.find(screenId, "give_t1_") or string.find(screenId, "give_t2_") or string.find(screenId, "give_t3_") then
        return self:handleAttachmentTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    end

    -- Check if this is a bg_token vendor trade screen (vendor 1, 2, or 3)
    if string.find(screenId, "give_item_") then
        if string.find(screenId, "give_item_3_") then
            return self:handleBGTokenTrade3(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
        elseif string.find(screenId, "give_item_2_") then
            return self:handleBGTokenTrade2(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
        else
            return self:handleBGTokenTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
        end
    end

    -- Check if this is a holocron vendor trade screen
    if string.find(screenId, "give_holo_") then
        return self:handleHolocronTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    end

    if screenId == "procurement_contract_status" then
        return self:handleArtisanProcurementStatus(pConvScreen, pPlayer)
    end

    if screenId == "procurement_submit_contract" then
        return self:handleArtisanProcurementTurnIn(pConvScreen, pPlayer)
    end

    return pConvScreen
end

function conv_handler:handleAttachmentTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
   
    local screen = LuaConversationScreen(pConvScreen)
   
    -- Determine tier and required attachments
    local requiredAttachments = 0
    local rewardInfo = nil
   
    if string.find(screenId, "give_t1_") then
        requiredAttachments = 25
        rewardInfo = self:getTier1Reward(screenId)
    elseif string.find(screenId, "give_t2_") then
        requiredAttachments = 50
        rewardInfo = self:getTier2Reward(screenId)
    elseif string.find(screenId, "give_t3_") then
        requiredAttachments = 75
        rewardInfo = self:getTier3Reward(screenId)
    end
   
    if rewardInfo then
    end
   
    if not rewardInfo then
        screen:setCustomDialogText("Error: Invalid reward selection.")
        return pConvScreen
    end
   
   
    -- Count attachments
    local success, attachmentCount = pcall(function() 
        return self:countAttachments(pPlayer) 
    end)
   
   
    if not success then
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end
   
   
    if attachmentCount < requiredAttachments then
        screen:setCustomDialogText("You only have " .. attachmentCount .. " attachments, but need " .. requiredAttachments .. ". Please collect more!")
        return pConvScreen
    end
   
    -- Remove attachments
    local removeSuccess, removedCount = pcall(function()
        return self:removeAttachments(pPlayer, requiredAttachments)
    end)
   
    if not removeSuccess or removedCount < requiredAttachments then
        screen:setCustomDialogText("Error removing attachments. Trade cancelled.")
        return pConvScreen
    end
   
   
    -- Give reward
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)
   
    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " attachments removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
    else
        screen:setCustomDialogText("Attachments removed but error giving reward. Contact an admin.")
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
        ["give_t3_02"] = {name = "Data Terminal (Style 1)", template = "object/tangible/veteran_reward/data_terminal_s1.iff"},
        ["give_t3_03"] = {name = "Data Terminal (Style 2)", template = "object/tangible/veteran_reward/data_terminal_s2.iff"},
        ["give_t3_04"] = {name = "Data Terminal (Style 3)", template = "object/tangible/veteran_reward/data_terminal_s3.iff"},
        ["give_t3_05"] = {name = "Data Terminal (Style 4)", template = "object/tangible/veteran_reward/data_terminal_s4.iff"},
        ["give_t3_06"] = {name = "Protocol Droid Toy", template = "object/tangible/veteran_reward/frn_vet_protocol_droid_toy.iff"},
        ["give_t3_07"] = {name = "R2 Unit Toy", template = "object/tangible/veteran_reward/frn_vet_r2_toy.iff"},
        ["give_t3_09"] = {name = "Falcon Couch Corner", template = "object/tangible/veteran_reward/frn_couch_falcon_corner_s01.iff"},
        ["give_t3_10"] = {name = "Falcon Couch Section", template = "object/tangible/veteran_reward/frn_couch_falcon_section_s01.iff"},
        ["give_t3_11"] = {name = "TIE Fighter Toy", template = "object/tangible/veteran_reward/frn_vet_tie_fighter_toy.iff"},
        ["give_t3_12"] = {name = "X-Wing Toy", template = "object/tangible/veteran_reward/frn_vet_x_wing_toy.iff"},
        ["give_t3_15"] = {name = "SE Goggles (Style 1)", template = "object/tangible/wearables/goggles/goggles_s01.iff"},
        ["give_t3_16"] = {name = "SE Goggles (Style 2)", template = "object/tangible/wearables/goggles/goggles_s02.iff"},
        ["give_t3_17"] = {name = "SE Goggles (Style 3)", template = "object/tangible/wearables/goggles/goggles_s03.iff"},
        ["give_t3_18"] = {name = "SE Goggles (Style 4)", template = "object/tangible/wearables/goggles/goggles_s04.iff"},
        ["give_t3_19"] = {name = "SE Goggles (Style 5)", template = "object/tangible/wearables/goggles/goggles_s05.iff"},
        ["give_t3_20"] = {name = "SE Goggles (Style 6)", template = "object/tangible/wearables/goggles/goggles_s06.iff"},
        ["give_t3_21"] = {name = "Darth Vader Toy", template = "object/tangible/veteran_reward/frn_vet_darth_vader_toy.iff"},
        ["give_t3_22"] = {name = "Tech Console Sectional A", template = "object/tangible/veteran_reward/frn_tech_console_sectional_a.iff"},
        ["give_t3_23"] = {name = "Tech Console Sectional B", template = "object/tangible/veteran_reward/frn_tech_console_sectional_b.iff"},
        ["give_t3_24"] = {name = "Tech Console Sectional C", template = "object/tangible/veteran_reward/frn_tech_console_sectional_c.iff"},
        ["give_t3_25"] = {name = "Tech Console Sectional D", template = "object/tangible/veteran_reward/frn_tech_console_sectional_d.iff"},
        ["give_t3_26"] = {name = "Jabba Toy", template = "object/tangible/veteran_reward/frn_vet_jabba_toy.iff"},
        ["give_t3_27"] = {name = "Stormtrooper Toy", template = "object/tangible/veteran_reward/frn_vet_stormtrooper_toy.iff"},
        ["give_t3_28"] = {name = "Camp Center (Small)", template = "object/tangible/camp/camp_spit_s2.iff"},
        ["give_t3_29"] = {name = "Camp Center (Large)", template = "object/tangible/camp/camp_spit_s3.iff"},
        ["give_t3_30"] = {name = "Gold Ornamental Vase (Style 1)", template = "object/tangible/furniture/tatooine/frn_tato_vase_style_01.iff"},
        ["give_t3_31"] = {name = "Gold Ornamental Vase (Style 2)", template = "object/tangible/furniture/tatooine/frn_tato_vase_style_02.iff"},
        ["give_t3_32"] = {name = "Foodcart", template = "object/tangible/furniture/decorative/foodcart.iff"},
        ["give_t3_33"] = {name = "Park Bench", template = "object/tangible/furniture/all/frn_bench_generic.iff"},
        ["give_t3_34"] = {name = "Professor Desk", template = "object/tangible/furniture/decorative/professor_desk.iff"},
        ["give_t3_35"] = {name = "Diagnostic Screen", template = "object/tangible/furniture/decorative/diagnostic_screen.iff"},
        ["give_t3_36"] = {name = "Large Potted Plant (Style 2)", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s2.iff"},
        ["give_t3_37"] = {name = "Large Potted Plant (Style 3)", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s3.iff"},
        ["give_t3_38"] = {name = "Large Potted Plant (Style 4)", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s4.iff"},
        ["give_t3_39"] = {name = "Bar Countertop", template = "object/tangible/furniture/modern/bar_counter_s1.iff"},
        ["give_t3_40"] = {name = "Bar Countertop (Curved, Style 1)", template = "object/tangible/furniture/modern/bar_piece_curve_s1.iff"},
        ["give_t3_41"] = {name = "Bar Countertop (Curved, Style 2)", template = "object/tangible/furniture/modern/bar_piece_curve_s2.iff"},
        ["give_t3_42"] = {name = "Bar Countertop (Straight, Style 1)", template = "object/tangible/furniture/modern/bar_piece_straight_s1.iff"},
        ["give_t3_43"] = {name = "Bar Countertop (Straight, Style 2)", template = "object/tangible/furniture/modern/bar_piece_straight_s2.iff"},
        ["give_t3_44"] = {name = "Round Cantina Table (Style 1)", template = "object/tangible/furniture/all/frn_all_table_s01.iff"},
        ["give_t3_45"] = {name = "Round Cantina Table (Style 2)", template = "object/tangible/furniture/all/frn_all_table_s02.iff"},
        ["give_t3_46"] = {name = "Round Cantina Table (Style 3)", template = "object/tangible/furniture/all/frn_all_table_s03.iff"},
        ["give_t3_47"] = {name = "Large Cantina Sofa", template = "object/tangible/furniture/tatooine/frn_tatt_chair_cantina_seat_2.iff"},
        ["give_t3_48"] = {name = "Cafe Parasol", template = "object/tangible/furniture/tatooine/frn_tato_cafe_parasol.iff"},
        ["give_t3_49"] = {name = "Medium Oval Rug", template = "object/tangible/furniture/modern/rug_oval_m_s02.iff"},
        ["give_t3_50"] = {name = "Small Oval Rug", template = "object/tangible/furniture/modern/rug_oval_sml_s01.iff"},
        ["give_t3_51"] = {name = "Medium Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_m_s01.iff"},
        ["give_t3_52"] = {name = "Small Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_sml_s01.iff"},
        ["give_t3_53"] = {name = "Medium Round Rug", template = "object/tangible/furniture/modern/rug_rnd_m_s01.iff"},
        ["give_t3_54"] = {name = "Small Round Rug", template = "object/tangible/furniture/modern/rug_rnd_sml_s01.iff"},
        ["give_t3_55"] = {name = "Bith Skull", template = "object/tangible/loot/misc/loot_skull_bith.iff"},
        ["give_t3_56"] = {name = "Human Skull", template = "object/tangible/loot/misc/loot_skull_human.iff"},
        ["give_t3_57"] = {name = "Ithorian Skull", template = "object/tangible/loot/misc/loot_skull_ithorian.iff"},
        ["give_t3_58"] = {name = "Thune Skull", template = "object/tangible/loot/misc/loot_skull_thune.iff"},
        ["give_t3_59"] = {name = "Voritor Lizard Skull", template = "object/tangible/loot/misc/loot_skull_voritor.iff"},
        ["give_t3_60"] = {name = "Rebel Endor Helmet", template = "object/tangible/wearables/helmet/helmet_s06.iff"},
        ["give_t3_61"] = {name = "Large Rectangular Rug (Style 1)", template = "object/tangible/furniture/modern/rug_rect_lg_s01.iff"},
        ["give_t3_62"] = {name = "Large Rectangular Rug (Style 2)", template = "object/tangible/furniture/modern/rug_rect_lg_s02.iff"},
        ["give_t3_63"] = {name = "Large Oval Rug", template = "object/tangible/furniture/modern/rug_oval_lg_s01.iff"},
        ["give_t3_64"] = {name = "Large Round Rug", template = "object/tangible/furniture/modern/rug_rnd_lg_s01.iff"},
        ["give_t3_65"] = {name = "Round Data Terminal", template = "object/tangible/furniture/all/frn_all_desk_map_table.iff"},
        ["give_t3_66"] = {name = "Nightsister Melee Armguard", template = "object/tangible/wearables/armor/nightsister/armor_nightsister_bicep_r_s01.iff"},
        ["give_t3_67"] = {name = "Painting: Cast Wing in Flight", template = "object/tangible/veteran_reward/one_year_anniversary/painting_01.iff"},
        ["give_t3_68"] = {name = "Painting: Decimator", template = "object/tangible/veteran_reward/one_year_anniversary/painting_02.iff"},
        ["give_t3_69"] = {name = "Painting: Tatooine Dune Speeder", template = "object/tangible/veteran_reward/one_year_anniversary/painting_03.iff"},
        ["give_t3_70"] = {name = "Painting: Weapon of War", template = "object/tangible/veteran_reward/one_year_anniversary/painting_04.iff"},
        ["give_t3_71"] = {name = "Painting: Fighter Study", template = "object/tangible/veteran_reward/one_year_anniversary/painting_05.iff"},
        ["give_t3_72"] = {name = "Painting: Hutt Greed", template = "object/tangible/veteran_reward/one_year_anniversary/painting_06.iff"},
        ["give_t3_73"] = {name = "Painting: Smuggler's Run", template = "object/tangible/veteran_reward/one_year_anniversary/painting_07.iff"},
        ["give_t3_74"] = {name = "Painting: Imperial Oppression", template = "object/tangible/veteran_reward/one_year_anniversary/painting_08.iff"},
        ["give_t3_75"] = {name = "Painting: Emperor's Eyes", template = "object/tangible/veteran_reward/one_year_anniversary/painting_09.iff"},
    }
    return rewards[screenId]
end

function conv_handler:countAttachments(pPlayer)
    local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then return 0 end

    local function isAttachment(pItem)
        if pItem == nil then return false end
        local ok, path = pcall(function() return SceneObject(pItem):getTemplateObjectPath() end)
        if not ok or path == nil then return false end
        local lp = string.lower(path)
        return string.find(lp, "tangible/gem/clothing") ~= nil
            or string.find(lp, "tangible/gem/armor") ~= nil
    end

    local count = 0

    for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
        local pItem = SceneObject(pInventory):getContainerObject(i)
        if pItem ~= nil then
            if isAttachment(pItem) then
                count = count + 1
            elseif SceneObject(pItem):getContainerObjectsSize() > 0 then
                -- Scan inside containers (backpacks)
                for j = 0, SceneObject(pItem):getContainerObjectsSize() - 1, 1 do
                    local pSubItem = SceneObject(pItem):getContainerObject(j)
                    if pSubItem ~= nil and isAttachment(pSubItem) then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

function conv_handler:removeAttachments(pPlayer, count)
    local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then return 0 end

    local function isAttachment(pItem)
        if pItem == nil then return false end
        local ok, path = pcall(function() return SceneObject(pItem):getTemplateObjectPath() end)
        if not ok or path == nil then return false end
        local lp = string.lower(path)
        return string.find(lp, "tangible/gem/clothing") ~= nil
            or string.find(lp, "tangible/gem/armor") ~= nil
    end

    -- Collect all attachment pointers first (inventory + backpacks)
    local toRemove = {}
    for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
        local pItem = SceneObject(pInventory):getContainerObject(i)
        if pItem ~= nil then
            if isAttachment(pItem) then
                toRemove[#toRemove + 1] = pItem
            elseif SceneObject(pItem):getContainerObjectsSize() > 0 then
                for j = 0, SceneObject(pItem):getContainerObjectsSize() - 1, 1 do
                    local pSubItem = SceneObject(pItem):getContainerObject(j)
                    if pSubItem ~= nil and isAttachment(pSubItem) then
                        toRemove[#toRemove + 1] = pSubItem
                    end
                end
            end
        end
    end

    local removed = 0
    for _, pItem in ipairs(toRemove) do
        if removed >= count then break end
        local ok = pcall(function()
            SceneObject(pItem):destroyObjectFromWorld()
            SceneObject(pItem):destroyObjectFromDatabase()
        end)
        if ok then removed = removed + 1 end
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
        ["give_item_2_20"] = {name = "Large Potted Plant (Style 3)", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s3.iff"},
    }
    return rewards[screenId]
end

-- ============================= BG TOKEN VENDOR 3 HANDLER (75 tokens - Veteran Rewards) =============================

function conv_handler:handleBGTokenTrade3(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    print("[BG-TOKEN-3] === ENTERED handleBGTokenTrade3 ===")
    print("[BG-TOKEN-3] screenId: " .. tostring(screenId))

    local screen = LuaConversationScreen(pConvScreen)
    local requiredTokens = 75

    -- Get reward info for this item
    local rewardInfo = self:getBGTokenReward3(screenId)

    if not rewardInfo then
        print("[BG-TOKEN-3] ERROR: No reward info found for screenId: " .. screenId)
        screen:setCustomDialogText("Error: Invalid item selection.")
        return pConvScreen
    end

    print("[BG-TOKEN-3] === STARTING " .. rewardInfo.name .. " TRADE ===")
    print("[BG-TOKEN-3] Required tokens: " .. requiredTokens)

    -- Count bg_tokens
    print("[BG-TOKEN-3] About to count tokens...")
    local success, tokenCount = pcall(function()
        return self:countBGTokens(pPlayer)
    end)

    if not success then
        print("[BG-TOKEN-3] Error counting tokens: " .. tostring(tokenCount))
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end

    print("[BG-TOKEN-3] Found " .. tokenCount .. " tokens")

    if tokenCount < requiredTokens then
        screen:setCustomDialogText("You only have " .. tokenCount .. " Bellum Gero Tokens, but need " .. requiredTokens .. ". Please collect more!")
        return pConvScreen
    end

    -- Remove tokens
    print("[BG-TOKEN-3] About to remove tokens...")
    local removeSuccess, removedCount = pcall(function()
        return self:removeBGTokens(pPlayer, requiredTokens)
    end)

    if not removeSuccess or removedCount < requiredTokens then
        print("[BG-TOKEN-3] Error removing tokens. Removed: " .. (removedCount or 0))
        screen:setCustomDialogText("Error removing tokens. Trade cancelled.")
        return pConvScreen
    end

    print("[BG-TOKEN-3] Successfully removed " .. removedCount .. " tokens")

    -- Give reward
    print("[BG-TOKEN-3] About to give reward...")
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)

    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " Bellum Gero Tokens removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
        print("[BG-TOKEN-3] Successfully gave " .. rewardInfo.name .. " to player")
    else
        screen:setCustomDialogText("Tokens removed but error giving reward. Contact an admin.")
        print("[BG-TOKEN-3] Failed to give " .. rewardInfo.name)
    end

    return pConvScreen
end

function conv_handler:getBGTokenReward3(screenId)
    -- Template mapping for 75 veteran reward items
    local rewards = {
        ["give_item_3_02"] = {name = "Data Terminal Style 1", template = "object/tangible/veteran_reward/data_terminal_s1.iff"},
        ["give_item_3_03"] = {name = "Data Terminal Style 2", template = "object/tangible/veteran_reward/data_terminal_s2.iff"},
        ["give_item_3_04"] = {name = "Data Terminal Style 3", template = "object/tangible/veteran_reward/data_terminal_s3.iff"},
        ["give_item_3_05"] = {name = "Data Terminal Style 4", template = "object/tangible/veteran_reward/data_terminal_s4.iff"},
        ["give_item_3_06"] = {name = "Protocol Droid Toy", template = "object/tangible/veteran_reward/frn_vet_protocol_droid_toy.iff"},
        ["give_item_3_07"] = {name = "R2 Unit Toy", template = "object/tangible/veteran_reward/frn_vet_r2_toy.iff"},
        ["give_item_3_09"] = {name = "Falcon Couch Corner", template = "object/tangible/veteran_reward/frn_couch_falcon_corner_s01.iff"},
        ["give_item_3_10"] = {name = "Falcon Couch Section", template = "object/tangible/veteran_reward/frn_couch_falcon_section_s01.iff"},
        ["give_item_3_11"] = {name = "TIE Fighter Toy", template = "object/tangible/veteran_reward/frn_vet_tie_fighter_toy.iff"},
        ["give_item_3_12"] = {name = "X-Wing Toy", template = "object/tangible/veteran_reward/frn_vet_x_wing_toy.iff"},
        ["give_item_3_15"] = {name = "SE Goggles Style 1", template = "object/tangible/wearables/goggles/goggles_s01.iff"},
        ["give_item_3_16"] = {name = "SE Goggles Style 2", template = "object/tangible/wearables/goggles/goggles_s02.iff"},
        ["give_item_3_17"] = {name = "SE Goggles Style 3", template = "object/tangible/wearables/goggles/goggles_s03.iff"},
        ["give_item_3_18"] = {name = "SE Goggles Style 4", template = "object/tangible/wearables/goggles/goggles_s04.iff"},
        ["give_item_3_19"] = {name = "SE Goggles Style 5", template = "object/tangible/wearables/goggles/goggles_s05.iff"},
        ["give_item_3_20"] = {name = "SE Goggles Style 6", template = "object/tangible/wearables/goggles/goggles_s06.iff"},
        ["give_item_3_21"] = {name = "Darth Vader Toy", template = "object/tangible/veteran_reward/frn_vet_darth_vader_toy.iff"},
        ["give_item_3_22"] = {name = "Tech Console Sectional A", template = "object/tangible/veteran_reward/frn_tech_console_sectional_a.iff"},
        ["give_item_3_23"] = {name = "Tech Console Sectional B", template = "object/tangible/veteran_reward/frn_tech_console_sectional_b.iff"},
        ["give_item_3_24"] = {name = "Tech Console Sectional C", template = "object/tangible/veteran_reward/frn_tech_console_sectional_c.iff"},
        ["give_item_3_25"] = {name = "Tech Console Sectional D", template = "object/tangible/veteran_reward/frn_tech_console_sectional_d.iff"},
        ["give_item_3_26"] = {name = "Jabba Toy", template = "object/tangible/veteran_reward/frn_vet_jabba_toy.iff"},
        ["give_item_3_27"] = {name = "Stormtrooper Toy", template = "object/tangible/veteran_reward/frn_vet_stormtrooper_toy.iff"},
        ["give_item_3_28"] = {name = "Camp Center (Small)", template = "object/tangible/camp/camp_spit_s2.iff"},
        ["give_item_3_29"] = {name = "Camp Center (Large)", template = "object/tangible/camp/camp_spit_s3.iff"},
        ["give_item_3_30"] = {name = "Gold Ornamental Vase Style 1", template = "object/tangible/furniture/tatooine/frn_tato_vase_style_01.iff"},
        ["give_item_3_31"] = {name = "Gold Ornamental Vase Style 2", template = "object/tangible/furniture/tatooine/frn_tato_vase_style_02.iff"},
        ["give_item_3_32"] = {name = "Foodcart", template = "object/tangible/furniture/decorative/foodcart.iff"},
        ["give_item_3_33"] = {name = "Park Bench", template = "object/tangible/furniture/all/frn_bench_generic.iff"},
        ["give_item_3_34"] = {name = "Professor Desk", template = "object/tangible/furniture/decorative/professor_desk.iff"},
        ["give_item_3_35"] = {name = "Diagnostic Screen", template = "object/tangible/furniture/decorative/diagnostic_screen.iff"},
        ["give_item_3_36"] = {name = "Large Potted Plant Style 2", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s2.iff"},
        ["give_item_3_37"] = {name = "Large Potted Plant Style 3", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s3.iff"},
        ["give_item_3_38"] = {name = "Large Potted Plant Style 4", template = "object/tangible/furniture/all/frn_all_plant_potted_lg_s4.iff"},
        ["give_item_3_39"] = {name = "Bar Countertop", template = "object/tangible/furniture/modern/bar_counter_s1.iff"},
        ["give_item_3_40"] = {name = "Bar Countertop (Curved, Style 1)", template = "object/tangible/furniture/modern/bar_piece_curve_s1.iff"},
        ["give_item_3_41"] = {name = "Bar Countertop (Curved, Style 2)", template = "object/tangible/furniture/modern/bar_piece_curve_s2.iff"},
        ["give_item_3_42"] = {name = "Bar Countertop (Straight, Style 1)", template = "object/tangible/furniture/modern/bar_piece_straight_s1.iff"},
        ["give_item_3_43"] = {name = "Bar Countertop (Straight, Style 2)", template = "object/tangible/furniture/modern/bar_piece_straight_s2.iff"},
        ["give_item_3_44"] = {name = "Round Cantina Table Style 1", template = "object/tangible/furniture/all/frn_all_table_s01.iff"},
        ["give_item_3_45"] = {name = "Round Cantina Table Style 2", template = "object/tangible/furniture/all/frn_all_table_s02.iff"},
        ["give_item_3_46"] = {name = "Round Cantina Table Style 3", template = "object/tangible/furniture/all/frn_all_table_s03.iff"},
        ["give_item_3_47"] = {name = "Large Cantina Sofa", template = "object/tangible/furniture/tatooine/frn_tatt_chair_cantina_seat_2.iff"},
        ["give_item_3_48"] = {name = "Cafe Parasol", template = "object/tangible/furniture/tatooine/frn_tato_cafe_parasol.iff"},
        ["give_item_3_49"] = {name = "Medium Oval Rug", template = "object/tangible/furniture/modern/rug_oval_m_s02.iff"},
        ["give_item_3_50"] = {name = "Small Oval Rug", template = "object/tangible/furniture/modern/rug_oval_sml_s01.iff"},
        ["give_item_3_51"] = {name = "Medium Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_m_s01.iff"},
        ["give_item_3_52"] = {name = "Small Rectangular Rug", template = "object/tangible/furniture/modern/rug_rect_sml_s01.iff"},
        ["give_item_3_53"] = {name = "Medium Round Rug", template = "object/tangible/furniture/modern/rug_rnd_m_s01.iff"},
        ["give_item_3_54"] = {name = "Small Round Rug", template = "object/tangible/furniture/modern/rug_rnd_sml_s01.iff"},
        ["give_item_3_55"] = {name = "Bith Skull", template = "object/tangible/loot/misc/loot_skull_bith.iff"},
        ["give_item_3_56"] = {name = "Human Skull", template = "object/tangible/loot/misc/loot_skull_human.iff"},
        ["give_item_3_57"] = {name = "Ithorian Skull", template = "object/tangible/loot/misc/loot_skull_ithorian.iff"},
        ["give_item_3_58"] = {name = "Thune Skull", template = "object/tangible/loot/misc/loot_skull_thune.iff"},
        ["give_item_3_59"] = {name = "Voritor Lizard Skull", template = "object/tangible/loot/misc/loot_skull_voritor.iff"},
        ["give_item_3_60"] = {name = "Rebel Endor Helmet", template = "object/tangible/wearables/helmet/helmet_s06.iff"},
        ["give_item_3_61"] = {name = "Large Rectangular Rug Style 1", template = "object/tangible/furniture/modern/rug_rect_lg_s01.iff"},
        ["give_item_3_62"] = {name = "Large Rectangular Rug Style 2", template = "object/tangible/furniture/modern/rug_rect_lg_s02.iff"},
        ["give_item_3_63"] = {name = "Large Oval Rug", template = "object/tangible/furniture/modern/rug_oval_lg_s01.iff"},
        ["give_item_3_64"] = {name = "Large Round Rug", template = "object/tangible/furniture/modern/rug_rnd_lg_s01.iff"},
        ["give_item_3_65"] = {name = "Round Data Terminal", template = "object/tangible/furniture/all/frn_all_desk_map_table.iff"},
        ["give_item_3_66"] = {name = "Nightsister Melee Armguard", template = "object/tangible/wearables/armor/nightsister/armor_nightsister_bicep_r_s01.iff"},
        ["give_item_3_67"] = {name = "Painting: Cast Wing in Flight", template = "object/tangible/veteran_reward/one_year_anniversary/painting_01.iff"},
        ["give_item_3_68"] = {name = "Painting: Decimator", template = "object/tangible/veteran_reward/one_year_anniversary/painting_02.iff"},
        ["give_item_3_69"] = {name = "Painting: Tatooine Dune Speeder", template = "object/tangible/veteran_reward/one_year_anniversary/painting_03.iff"},
        ["give_item_3_70"] = {name = "Painting: Weapon of War", template = "object/tangible/veteran_reward/one_year_anniversary/painting_04.iff"},
        ["give_item_3_71"] = {name = "Painting: Fighter Study", template = "object/tangible/veteran_reward/one_year_anniversary/painting_05.iff"},
        ["give_item_3_72"] = {name = "Painting: Hutt Greed", template = "object/tangible/veteran_reward/one_year_anniversary/painting_06.iff"},
        ["give_item_3_73"] = {name = "Painting: Smuggler's Run", template = "object/tangible/veteran_reward/one_year_anniversary/painting_07.iff"},
        ["give_item_3_74"] = {name = "Painting: Imperial Oppression (TIE Oppressor)", template = "object/tangible/veteran_reward/one_year_anniversary/painting_08.iff"},
        ["give_item_3_75"] = {name = "Painting: Emperor's Eyes (TIE Sentinel)", template = "object/tangible/veteran_reward/one_year_anniversary/painting_09.iff"},
    }
    return rewards[screenId]
end

local BG_TOKEN_TEMPLATES = {
    ["object/tangible/component/clothing/jewelry_setting.iff"] = true,
    ["object/tangible/component/clothing/shared_jewelry_setting.iff"] = true,
    ["object/token/token.iff"] = true,
    ["object/token/shared_token.iff"] = true
}

local function isBellumGeroToken(sceneObject)
    if not sceneObject then
        return false
    end

    local nameSuccess, displayedName = pcall(function() return sceneObject:getDisplayedName() end)
    local customSuccess, customName = pcall(function() return sceneObject:getCustomObjectName() end)
    local objectSuccess, objectName = pcall(function() return sceneObject:getObjectName() end)

    local name = displayedName
    if not nameSuccess or name == nil or name == "" then
        name = customSuccess and customName or nil
    end
    if name == nil or name == "" then
        name = objectSuccess and objectName or nil
    end

    if name == nil or name == "" then
        return false
    end

    local templateSuccess, template = pcall(function() return sceneObject:getTemplateObjectPath() end)
    if not templateSuccess or not template then
        templateSuccess, template = pcall(function() return sceneObject:getTemplate() end)
    end
    if not templateSuccess or not template then
        return false
    end

    local nameLower = string.lower(name)
    if not (string.find(nameLower, "bellum gero token") or string.find(nameLower, "bg_token")) then
        return false
    end

    local templateLower = string.lower(template)
    local hasTemplate = BG_TOKEN_TEMPLATES[templateLower] == true

    if not hasTemplate then
        return false
    end

    -- Guard: renamed containers should never count as tokens
    local isContainer = string.find(templateLower, "container/") or
        string.find(templateLower, "backpack/") or
        string.find(templateLower, "wearables/backpack")

    return not isContainer
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
                    if isBellumGeroToken(object) then
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
                    if isBellumGeroToken(object) then

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

-- Crystal Tuning Functions
function conv_handler:countUntunedCrystals(pPlayer)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[CRYSTAL-TUNE] Could not get LuaCreatureObject")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[CRYSTAL-TUNE] Could not get inventory")
        return 0
    end

    local crystalCount = self:countUntunedCrystalsInContainer(pInventory)
    print("[CRYSTAL-TUNE] Counted " .. crystalCount .. " untuned crystals")
    return crystalCount
end

function conv_handler:countUntunedCrystalsInContainer(container)
    local count = 0
    if not container then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    for i = 0, size - 1, 1 do
        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                -- Get the template path to check what type of object this is
                local templateSuccess, template = pcall(function() return object:getTemplateObjectPath() end)
                local templatePath = ""
                if templateSuccess and template then
                    templatePath = string.lower(template)
                end

                -- Check if this is a container (bag, backpack, etc) by template path
                local isContainer = string.find(templatePath, "container/") or
                                   string.find(templatePath, "backpack/") or
                                   string.find(templatePath, "wearables/backpack")

                if isContainer then
                    -- This is a container, recurse into it but don't count the container itself
                    count = count + self:countUntunedCrystalsInContainer(pObject)
                else
                    -- Check if it's a crystal by template path (most reliable check)
                    local isCrystal = false

                    -- Crystals have templates containing "lightsaber_module" or in component/weapon/lightsaber path
                    if string.find(templatePath, "lightsaber_module") or
                       string.find(templatePath, "component/weapon/lightsaber") then
                        -- It's a lightsaber crystal component - check if untuned
                        local success, displayedName = pcall(function() return object:getDisplayedName() end)
                        if success and displayedName then
                            displayedName = displayedName:gsub("^%s+", ""):gsub("%s+$", "")
                            -- Only count if NOT tuned
                            if not displayedName:find("Tuned") then
                                isCrystal = true
                            end
                        else
                            -- If we can't get the name, still count it as a crystal based on template
                            isCrystal = true
                        end
                    end

                    if isCrystal then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

function conv_handler:removeUntunedCrystals(pPlayer, count)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[CRYSTAL-TUNE] Could not get LuaCreatureObject for removal")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[CRYSTAL-TUNE] Could not get inventory for removal")
        return 0
    end

    local removed = self:removeUntunedCrystalsFromContainer(pInventory, count)
    print("[CRYSTAL-TUNE] Successfully removed " .. removed .. " untuned crystals")
    return removed
end

function conv_handler:removeUntunedCrystalsFromContainer(container, count)
    local removed = 0
    if not container or count <= 0 then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    for i = size - 1, 0, -1 do
        if removed >= count then break end

        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                -- Get the template path to check what type of object this is
                local templateSuccess, template = pcall(function() return object:getTemplateObjectPath() end)
                local templatePath = ""
                if templateSuccess and template then
                    templatePath = string.lower(template)
                end

                -- Check if this is a container (bag, backpack, etc) by template path
                local isContainer = string.find(templatePath, "container/") or
                                   string.find(templatePath, "backpack/") or
                                   string.find(templatePath, "wearables/backpack")

                if isContainer then
                    -- This is a container, recurse into it to find crystals inside
                    removed = removed + self:removeUntunedCrystalsFromContainer(pObject, count - removed)
                else
                    -- Check if it's a crystal by template path (most reliable check)
                    local isCrystal = false

                    -- Crystals have templates containing "lightsaber_module" or in component/weapon/lightsaber path
                    if string.find(templatePath, "lightsaber_module") or
                       string.find(templatePath, "component/weapon/lightsaber") then
                        -- It's a lightsaber crystal component - check if untuned
                        local success, displayedName = pcall(function() return object:getDisplayedName() end)
                        if success and displayedName then
                            displayedName = displayedName:gsub("^%s+", ""):gsub("%s+$", "")
                            -- Only remove if NOT tuned
                            if not displayedName:find("Tuned") then
                                isCrystal = true
                            end
                        else
                            -- If we can't get the name, still treat it as a crystal based on template
                            isCrystal = true
                        end
                    end

                    if isCrystal then
                        local destroySuccess = pcall(function() object:destroyObjectFromWorld(true) end)
                        if destroySuccess then
                            removed = removed + 1
                        end
                    end
                end
            end
        end
    end

    return removed
end

function conv_handler:tuneCrystals(pPlayer, crystalsToTune)
    -- Validate input
    if crystalsToTune <= 0 then
        CreatureObject(pPlayer):sendSystemMessage("Invalid crystal count.")
        return false
    end

    -- Count untuned crystals
    local crystalCount = self:countUntunedCrystals(pPlayer)
    if crystalCount < (crystalsToTune * 15) then
        CreatureObject(pPlayer):sendSystemMessage("You need " .. (crystalsToTune * 15) .. " untuned crystals. You have " .. crystalCount .. ".")
        return false
    end

    -- Remove untuned crystals
    local removed = self:removeUntunedCrystals(pPlayer, crystalsToTune * 15)
    if removed < (crystalsToTune * 15) then
        CreatureObject(pPlayer):sendSystemMessage("Error removing crystals. Tuning cancelled.")
        return false
    end

    -- Create tuned crystals
    local pCreatureObject = LuaCreatureObject(pPlayer)
    local pInventory = pCreatureObject:getSlottedObject("inventory")
    local created = 0

    if pInventory then
        for i = 1, crystalsToTune do
            local crystalID = createLoot(pInventory, "force_color_crystal_special", 1, true)
            if crystalID ~= 0 then
                created = created + 1
            end
        end
    end

    if created > 0 then
        CreatureObject(pPlayer):sendSystemMessage("Successfully tuned " .. created .. " crystal(s)!")
        return true
    else
        CreatureObject(pPlayer):sendSystemMessage("Error creating tuned crystals.")
        return false
    end
end

-- Apprentice Experience to Token Exchange Handler
function conv_handler:handleApprenticeXpTrade(pConvTemplate, pPlayer, pNpc, selectedOption, lastConvScreen)

    if pPlayer == nil then
        return nil
    end

    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        return nil
    end

    local XP_REQUIRED = 500
    local XP_TYPE = "apprenticeship"

    -- Get player object to access experience system
    local pGhost = pCreatureObject:getPlayerObject()
    if pGhost == nil then
        pCreatureObject:sendSystemMessage("Error accessing player data.")
        return nil
    end

    -- Wrap it with LuaPlayerObject to access Lua methods
    local ghost = LuaPlayerObject(pGhost)
    if ghost == nil then
        pCreatureObject:sendSystemMessage("Error accessing player data.")
        return nil
    end

    -- Get current apprentice experience
    local success, xpAmount = pcall(function()
        return ghost:getExperience(XP_TYPE)
    end)

    if not success then
        pCreatureObject:sendSystemMessage("Error reading your apprentice experience.")
        return nil
    end

    if not xpAmount then
        xpAmount = 0
    end


    -- Check if player has enough apprentice XP
    if xpAmount < XP_REQUIRED then
        pCreatureObject:sendSystemMessage("You need " .. XP_REQUIRED .. " Apprentice Experience Points. You have " .. xpAmount .. ".")
        return nil
    end


    -- Check inventory space
    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if pInventory == nil then
        pCreatureObject:sendSystemMessage("You do not have an inventory!")
        return nil
    end

    local pInvObject = LuaSceneObject(pInventory)
    if pInvObject:isContainerFullRecursive() then
        pCreatureObject:sendSystemMessage("Your inventory is full.")
        return nil
    end


    -- Give Bellum Gero Token using the loot item system
    local tokenID = createLoot(pInventory, "bg_token", 1, true)

    if tokenID ~= 0 then
        -- Deduct the XP using awardExperience with negative amount
        local xpSuccess, xpResult = pcall(function()
            return pCreatureObject:awardExperience(XP_TYPE, -XP_REQUIRED, false)
        end)

        pCreatureObject:sendSystemMessage("You have exchanged 500 Apprentice Experience Points for 1 Bellum Gero Token!")

        -- Get the give_apprentice_token screen from the conversation template
        local convTemplate = LuaConversationTemplate(pConvTemplate)
        local nextScreen = convTemplate:getScreen("give_apprentice_token")

        if nextScreen ~= nil then

            -- Just return the screen as-is from the template
            -- The template already has stopConversation=false and the proper options defined

            return nextScreen
        else
            return nil
        end
    else
        pCreatureObject:sendSystemMessage("Failed to create token. Please try again.")
        return nil
    end
end

-- ============================= HOLOCRON VILLAGE VENDOR HANDLER =============================

function conv_handler:handleHolocronTrade(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, screenId)
    print("[HOLOCRON-VENDOR] === ENTERED handleHolocronTrade ===")
    print("[HOLOCRON-VENDOR] screenId: " .. tostring(screenId))

    local screen = LuaConversationScreen(pConvScreen)
    local requiredHolocrons = 2

    -- Get reward info for this item
    local rewardInfo = self:getHolocronReward(screenId)

    if not rewardInfo then
        print("[HOLOCRON-VENDOR] ERROR: No reward info found for screenId: " .. screenId)
        screen:setCustomDialogText("Error: Invalid item selection.")
        return pConvScreen
    end

    print("[HOLOCRON-VENDOR] === STARTING " .. rewardInfo.name .. " TRADE ===")
    print("[HOLOCRON-VENDOR] Required holocrons: " .. requiredHolocrons)

    -- Count holocrons
    print("[HOLOCRON-VENDOR] About to count holocrons...")
    local success, holocronCount = pcall(function()
        return self:countHolocrons(pPlayer)
    end)

    if not success then
        print("[HOLOCRON-VENDOR] Error counting holocrons: " .. tostring(holocronCount))
        screen:setCustomDialogText("Error reading your inventory. Please try again later.")
        return pConvScreen
    end

    print("[HOLOCRON-VENDOR] Found " .. holocronCount .. " holocrons")

    if holocronCount < requiredHolocrons then
        screen:setCustomDialogText("You only have " .. holocronCount .. " Holocrons of Destiny, but need " .. requiredHolocrons .. ". Please collect more!")
        return pConvScreen
    end

    -- Remove holocrons
    print("[HOLOCRON-VENDOR] About to remove holocrons...")
    local removeSuccess, removedCount = pcall(function()
        return self:removeHolocrons(pPlayer, requiredHolocrons)
    end)

    if not removeSuccess or removedCount < requiredHolocrons then
        print("[HOLOCRON-VENDOR] Error removing holocrons. Removed: " .. (removedCount or 0))
        screen:setCustomDialogText("Error removing holocrons. Trade cancelled.")
        return pConvScreen
    end

    print("[HOLOCRON-VENDOR] Successfully removed " .. removedCount .. " holocrons")

    -- Give reward
    print("[HOLOCRON-VENDOR] About to give reward...")
    local rewardSuccess = self:giveReward(pPlayer, rewardInfo.template, rewardInfo.name)

    if rewardSuccess then
        screen:setCustomDialogText("Trade successful!\n\n" .. removedCount .. " Holocrons of Destiny removed.\n\nYou received: " .. rewardInfo.name .. "\n\nCheck your inventory!")
        print("[HOLOCRON-VENDOR] Successfully gave " .. rewardInfo.name .. " to player")
    else
        screen:setCustomDialogText("Holocrons removed but error giving reward. Contact an admin.")
        print("[HOLOCRON-VENDOR] Failed to give " .. rewardInfo.name)
    end

    return pConvScreen
end

function conv_handler:getHolocronReward(screenId)
    -- Template mapping for 10 village quest reward items (2 Holocrons of Destiny each)
    local rewards = {
        ["give_holo_03"] = {name = "Bacta Tank", template = "object/tangible/item/quest/force_sensitive/bacta_tank.iff"},
        ["give_holo_04"] = {name = "Village Banner Pole", template = "object/tangible/item/quest/force_sensitive/fs_village_bannerpole_s01.iff"},
        ["give_holo_05"] = {name = "FS Buff Item", template = "object/tangible/item/quest/force_sensitive/fs_buff_item.iff"},
        ["give_holo_06"] = {name = "Village Sculpture 1", template = "object/tangible/item/quest/force_sensitive/fs_sculpture_1.iff"},
        ["give_holo_07"] = {name = "Village Sculpture 2", template = "object/tangible/item/quest/force_sensitive/fs_sculpture_2.iff"},
        ["give_holo_08"] = {name = "Village Sculpture 3", template = "object/tangible/item/quest/force_sensitive/fs_sculpture_3.iff"},
        ["give_holo_09"] = {name = "Village Sculpture 4", template = "object/tangible/item/quest/force_sensitive/fs_sculpture_4.iff"},
        ["give_holo_10"] = {name = "Radar Topography Screen", template = "object/tangible/furniture/all/frn_all_desk_radar_topology_screen.iff"},
        ["give_holo_12"] = {name = "Dark Banner", template = "object/tangible/furniture/jedi/frn_all_banner_dark.iff"},
        ["give_holo_13"] = {name = "Light Banner", template = "object/tangible/furniture/jedi/frn_all_banner_light.iff"},
    }
    return rewards[screenId]
end

function conv_handler:countHolocrons(pPlayer)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[HOLOCRON-VENDOR] Could not get LuaCreatureObject")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[HOLOCRON-VENDOR] Could not get inventory")
        return 0
    end

    local holocronCount = self:countHolocronsInContainer(pInventory)

    print("[HOLOCRON-VENDOR] Counted " .. holocronCount .. " holocrons in inventory and containers")
    return holocronCount
end

function conv_handler:countHolocronsInContainer(container)
    local holocronCount = 0
    if not container then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    print("[HOLOCRON-VENDOR] Searching container with " .. size .. " items")

    for i = 0, size - 1 do
        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local templateSuccess, template = pcall(function() return object:getTemplateObjectPath() end)
                if templateSuccess and template then
                    local templateLower = string.lower(template)

                    -- Check if it's a Holocron of Destiny
                    if string.find(templateLower, "holocron_of_destiny") then
                        holocronCount = holocronCount + 1
                        print("[HOLOCRON-VENDOR] Found Holocron of Destiny")
                    else
                        -- Check if it's a container and recurse
                        local isContainer = string.find(templateLower, "container/") or
                                           string.find(templateLower, "backpack/") or
                                           string.find(templateLower, "wearables/backpack")

                        if isContainer then
                            print("[HOLOCRON-VENDOR] Checking container recursively...")
                            holocronCount = holocronCount + self:countHolocronsInContainer(pObject)
                        end
                    end
                end
            end
        end
    end

    return holocronCount
end

function conv_handler:removeHolocrons(pPlayer, count)
    local pCreatureObject = LuaCreatureObject(pPlayer)
    if not pCreatureObject then
        print("[HOLOCRON-VENDOR] Could not get LuaCreatureObject for removal")
        return 0
    end

    local pInventory = pCreatureObject:getSlottedObject("inventory")
    if not pInventory then
        print("[HOLOCRON-VENDOR] Could not get inventory for removal")
        return 0
    end

    local removed = self:removeHolocronsFromContainer(pInventory, count)

    print("[HOLOCRON-VENDOR] Successfully removed " .. removed .. " holocrons from inventory and containers")
    return removed
end

function conv_handler:removeHolocronsFromContainer(container, count)
    local removed = 0
    if not container then return 0 end

    local containerObj = LuaSceneObject(container)
    if not containerObj then return 0 end

    local sizeSuccess, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeSuccess or not size then return 0 end

    print("[HOLOCRON-VENDOR] Searching container for removal with " .. size .. " items")

    for i = size - 1, 0, -1 do
        if removed >= count then break end

        local pObject = containerObj:getContainerObject(i)
        if pObject then
            local object = LuaSceneObject(pObject)
            if object then
                local templateSuccess, template = pcall(function() return object:getTemplateObjectPath() end)
                if templateSuccess and template then
                    local templateLower = string.lower(template)

                    -- Check if it's a Holocron of Destiny
                    if string.find(templateLower, "holocron_of_destiny") then
                        print("[HOLOCRON-VENDOR] Found holocron to remove")

                        -- Remove the holocron
                        pcall(function() object:destroyObjectFromWorld(true) end)
                        pcall(function() object:destroyObjectFromDatabase(true) end)
                        removed = removed + 1
                        print("[HOLOCRON-VENDOR] Removed holocron")
                    else
                        -- Check if it's a container and recurse
                        local isContainer = string.find(templateLower, "container/") or
                                           string.find(templateLower, "backpack/") or
                                           string.find(templateLower, "wearables/backpack")

                        if isContainer and removed < count then
                            print("[HOLOCRON-VENDOR] Checking container for removal...")
                            removed = removed + self:removeHolocronsFromContainer(pObject, count - removed)
                        end
                    end
                end
            end
        end
    end

    return removed
end

function conv_handler:getArtisanProcurementScreenplay()
    if ArtisanProcurementVendor ~= nil then
        return ArtisanProcurementVendor
    end

    return nil
end

function conv_handler:handleArtisanProcurementStatus(pConvScreen, pPlayer)
    if pConvScreen == nil then
        if pPlayer ~= nil then
            CreatureObject(pPlayer):sendSystemMessage("Unable to open contract screen. Please try again.")
        end
        return pConvScreen
    end
    local screen = LuaConversationScreen(pConvScreen)
    local pClonedScreen = screen:cloneScreen()
    local cloned = LuaConversationScreen(pClonedScreen)
    local screenplay = self:getArtisanProcurementScreenplay()

    if screenplay == nil then
        cloned:setCustomDialogText("Artisan Procurement is currently unavailable.")
        if pPlayer ~= nil then
            CreatureObject(pPlayer):sendSystemMessage("Artisan Procurement is currently unavailable.")
        end
        return pClonedScreen
    end

    local ok, text = pcall(function()
        return screenplay:getStatusDialogText(pPlayer)
    end)

    if not ok or text == nil or text == "" then
        text = "Unable to read current contract status. Please try again."
    end
    cloned:setCustomDialogText(text)

    if pPlayer ~= nil then
        CreatureObject(pPlayer):sendSystemMessage(text)
    end

    return pClonedScreen
end

function conv_handler:handleArtisanProcurementTurnIn(pConvScreen, pPlayer)
    if pConvScreen == nil then
        if pPlayer ~= nil then
            CreatureObject(pPlayer):sendSystemMessage("Unable to open contract turn-in screen. Please try again.")
        end
        return pConvScreen
    end
    local screen = LuaConversationScreen(pConvScreen)
    local pClonedScreen = screen:cloneScreen()
    local cloned = LuaConversationScreen(pClonedScreen)
    local screenplay = self:getArtisanProcurementScreenplay()

    if screenplay == nil then
        cloned:setCustomDialogText("Artisan Procurement is currently unavailable.")
        if pPlayer ~= nil then
            CreatureObject(pPlayer):sendSystemMessage("Artisan Procurement is currently unavailable.")
        end
        return pClonedScreen
    end

    local ok, success, message = pcall(function()
        local turnInSuccess, turnInMessage = screenplay:handleTurnIn(pPlayer)
        return turnInSuccess, turnInMessage
    end)

    if not ok then
        message = "Error while processing contract turn-in. Please try again."
        cloned:setCustomDialogText(message)
        if pPlayer ~= nil then
            CreatureObject(pPlayer):sendSystemMessage(message)
        end
        return pClonedScreen
    end

    if message == nil or message == "" then
        if success then
            message = "Contract completed."
        else
            message = "Contract turn-in failed."
        end
    end
    cloned:setCustomDialogText(message)
    if pPlayer ~= nil then
        CreatureObject(pPlayer):sendSystemMessage(message)
    end
    return pClonedScreen
end
