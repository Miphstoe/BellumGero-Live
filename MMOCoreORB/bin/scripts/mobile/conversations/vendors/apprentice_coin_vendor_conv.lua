-- Apprentice Experience Coin Vendor Conversation

apprentice_coin_vendor_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

-- OPENING SCREEN
first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Greetings traveler! I exchange Apprentice Experience Points for Bellum Gero Tokens. I can trade 500 Experience Points for 1 Token. Would you like to make this trade?",
    stopConversation = "false",
    options = {
        {"Yes, trade my experience", "confirm_trade"},
        {"No, thanks", "bye"},
    }
}
apprentice_coin_vendor_conv:addScreen(first_screen)

-- CONFIRMATION SCREEN
confirm_trade = ConvoScreen:new {
    id = "confirm_trade",
    leftDialog = "",
    customDialogText = "Are you sure? This will permanently consume 500 of your Apprentice Experience Points in exchange for 1 Bellum Gero Token. Is that acceptable?",
    stopConversation = "false",
    options = {
        {"Yes, proceed with the trade", "give_apprentice_token"},
        {"No, cancel the trade", "first_screen"},
    }
}
apprentice_coin_vendor_conv:addScreen(confirm_trade)

-- TRADE EXECUTION SCREEN (will be updated dynamically by handler)
give_apprentice_token = ConvoScreen:new {
    id = "give_apprentice_token",
    leftDialog = "",
    customDialogText = "Excellent! I have processed your exchange. You have traded 500 Apprentice Experience Points for 1 Bellum Gero Token. Check your inventory!",
    stopConversation = "false",
    options = {
        {"Trade again", "confirm_trade"},
        {"Goodbye", "bye"},
    }
}
apprentice_coin_vendor_conv:addScreen(give_apprentice_token)

-- GOODBYE SCREEN
bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "Farewell, and may your endeavors be successful!",
    stopConversation = "true",
    options = {}
}
apprentice_coin_vendor_conv:addScreen(bye)

addConversationTemplate("apprentice_coin_vendor_conv", apprentice_coin_vendor_conv)
