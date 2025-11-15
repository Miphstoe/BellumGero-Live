bsv_quiz_convo_handler = Object:new {
  tstring = "bsv_quiz_convo_handler"
}

-- conversationTemplate, conversingPlayer, selectedOption, conversingNPC
function bsv_quiz_convo_handler:getNextConversationScreen(conversationTemplate, conversingPlayer, selectedOption, conversingNPC)
  local convosession = CreatureObject(conversingPlayer):getConversationSession()
  local lastConversationScreen = nil

  if (convosession ~= nil) then
    local session = LuaConversationSession(convosession)
    lastConversationScreen = session:getLastConversationScreen()
  end

  local conversation = LuaConversationTemplate(conversationTemplate)

  -- First time opening the conversation
  if lastConversationScreen == nil then
    local first = conversation:getInitialScreen()
    printLuaError("BSV QUIZ: opening initial screen.")
    return first
  end

  -- Follow the selected option link from the last screen
  local luaLast = LuaConversationScreen(lastConversationScreen)
  local optionLink = luaLast:getOptionLink(selectedOption)
  local nextScreen = conversation:getScreen(optionLink)

  if nextScreen == nil then
    printLuaError("BSV QUIZ: nextScreen nil for optionLink '" .. tostring(optionLink) .. "'; falling back to initial.")
    nextScreen = conversation:getInitialScreen()
  end

  return nextScreen
end

-- conversationTemplate, conversingPlayer, conversingNPC, selectedOption, conversationScreen
function bsv_quiz_convo_handler:runScreenHandlers(conversationTemplate, conversingPlayer, conversingNPC, selectedOption, conversationScreen)
  if conversationScreen == nil or conversingPlayer == nil then
    return conversationScreen
  end

  local screen = LuaConversationScreen(conversationScreen)
  local screenId = screen:getScreenID()

  printLuaError("BSV QUIZ: runScreenHandlers on screen '" .. tostring(screenId) .. "'.")

  -- You can plug reward logic back in here later, e.g. when screenId == "all_correct".
  -- For now we just let the conversation flow normally.

  return conversationScreen
end
