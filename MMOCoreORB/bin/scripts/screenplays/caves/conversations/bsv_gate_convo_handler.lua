bsv_gate_convo_handler = conv_handler:new {}

function bsv_gate_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    local screen = LuaConversationScreen(pConvScreen)
    local screenID = screen:getScreenID()

    if screenID == "grant" then
        local pInv = CreatureObject(pPlayer):getSlottedObject("inventory")
        if pInv ~= nil then
            -- Give the clearance item (match the screenplay’s clearanceTemplate)
            giveItem(pInv, "object/tangible/mission/quest_item/warren_passkey_s01.iff", -1)
            CreatureObject(pPlayer):sendSystemMessage("You received: Blue Shadow Clearance.")
        end

        -- Alt: set a flag instead of an item
        -- writeData(SceneObject(pPlayer):getObjectID() .. ":bsv:clearance", 1)
    end

    return pConvScreen
end

function bsv_gate_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    local convoTemplate = LuaConversationTemplate(pConvTemplate)
    -- If player already has clearance, you could branch here
    return convoTemplate:getScreen("intro")
end
