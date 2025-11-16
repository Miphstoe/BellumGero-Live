-- bin/scripts/screenplays/caves/conversations/bsv_quiz_convo_handler.lua

bsv_quiz_convo_handler = conv_handler:new {}

-- Called when the conversation first starts
function bsv_quiz_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    if pConvTemplate == nil then
        printLuaError("BSV QUIZ: getInitialScreen called with nil pConvTemplate.")
        return nil
    end

    local convoTemplate = LuaConversationTemplate(pConvTemplate)
    if convoTemplate == nil then
        printLuaError("BSV QUIZ: LuaConversationTemplate is nil in getInitialScreen.")
        return nil
    end

    local first = convoTemplate:getScreen("start")
    if first == nil then
        printLuaError("BSV QUIZ: 'start' screen not found in template.")
    else
        printLuaError("BSV QUIZ: getInitialScreen -> 'start'.")
    end

    return first
end

-- Called for each screen transition (after next screen is chosen)
-- pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen
function bsv_quiz_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    if pConvScreen == nil or pPlayer == nil then
        printLuaError("BSV QUIZ: runScreenHandlers called with nil screen or player.")
        return pConvScreen
    end

    local screen   = LuaConversationScreen(pConvScreen)
    local screenId = screen:getScreenID()

    printLuaError("BSV QUIZ: runScreenHandlers on screen '" .. tostring(screenId) .. "'.")

    -- Example reward hook when they clear the quiz
    if screenId == "all_correct" then
        CreatureObject(pPlayer):sendSystemMessage("You answered all questions correctly!")
        printLuaError("BSV QUIZ: player reached all_correct; (reward hook goes here).")
        -- TODO: add whatever reward logic you want here (cure flag, token, etc.)
    end

    return pConvScreen
end
