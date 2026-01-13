-- Bellum Gero Token Vendor 2 Conversation (75 tokens per item)
print("[BG-TOKEN-VENDOR-2] Loading conversation template...")

bg_token_vendor_2_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

-- OPENING SCREEN
first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Welcome to the Bellum Gero Token Exchange! I have many fine items available for trade. Each item costs 75 Bellum Gero Tokens. Browse my wares!",
    stopConversation = "false",
    options = {
        {"View Available Items", "items_menu"},
        {"How much do items cost?", "cost_info"},
        {"Goodbye", "bye"},
    }
}
bg_token_vendor_2_conv:addScreen(first_screen)

-- INFO SCREEN
cost_info = ConvoScreen:new {
    id = "cost_info",
    leftDialog = "",
    customDialogText = "All items in my inventory cost exactly 75 Bellum Gero Tokens each. Simply choose an item, confirm the trade, and it's yours!",
    stopConversation = "false",
    options = {
        {"Show me the items", "items_menu"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_2_conv:addScreen(cost_info)

-- ITEMS MENU (showing all 20 items)
items_menu = ConvoScreen:new {
    id = "items_menu",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 1-5:",
    stopConversation = "false",
    options = {
        {"Item 1 - [Medium Oval Rug]", "trade_item_01"},
        {"Item 2 - [Small Oval Rug]", "trade_item_02"},
        {"Item 3 - [Medium Rectangular Rug]", "trade_item_03"},
        {"Item 4 - [Small Rectagular Rug]", "trade_item_04"},
        {"Item 5 - [Medium Round Rug]", "trade_item_05"},
        {"More items...", "items_menu_2"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_2_conv:addScreen(items_menu)

-- ITEMS MENU PAGE 2
items_menu_2 = ConvoScreen:new {
    id = "items_menu_2",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 6-10:",
    stopConversation = "false",
    options = {
        {"Item 6 - [Small Round Rug]", "trade_item_06"},
        {"Item 7 - [Large Oval Rug]", "trade_item_07"},
        {"Item 8 - [Large Rectugangular Rug 01]", "trade_item_08"},
        {"Item 9 - [Large Rectugangular Rug 02]", "trade_item_09"},
        {"Item 10 - [Large Round Rug]", "trade_item_10"},
        {"More items...", "items_menu_3"},
        {"Previous", "items_menu"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_2_conv:addScreen(items_menu_2)

-- ITEMS MENU PAGE 3
items_menu_3 = ConvoScreen:new {
    id = "items_menu_3",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 11-15:",
    stopConversation = "false",
    options = {
        {"Item 11 - [Painting: Cast Wing in Flight]", "trade_item_11"},
        {"Item 12 - [Painting: Decimator]", "trade_item_12"},
        {"Item 13 - [Painting: Tatooine Dune Speeder]", "trade_item_13"},
        {"Item 14 - [Painting: Weapon of War]", "trade_item_14"},
        {"Item 15 - [Painting: Fighter Study]", "trade_item_15"},
        {"More items...", "items_menu_4"},
        {"Previous", "items_menu_2"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_2_conv:addScreen(items_menu_3)

-- ITEMS MENU PAGE 4
items_menu_4 = ConvoScreen:new {
    id = "items_menu_4",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 16-20:",
    stopConversation = "false",
    options = {
        {"Item 16 - [Painting: Hutt Greed]", "trade_item_16"},
        {"Item 17 - [Painting: Smuggler's Run]", "trade_item_17"},
        {"Item 18 - [Painting: Imperial Oppression (TIE Oppressor)]", "trade_item_18"},
        {"Item 19 - [Painting: Emperor's Eyes (TIE Sentinel)]", "trade_item_19"},
        {"Item 20 - [Large Potted Plant (Style 3)]", "trade_item_20"},
        {"Previous", "items_menu_3"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_2_conv:addScreen(items_menu_4)

-- TRADE SCREENS FOR EACH ITEM
-- Item 1
trade_item_01 = ConvoScreen:new {
    id = "trade_item_01",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_01"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_01)

give_item_2_01 = ConvoScreen:new {
    id = "give_item_2_01",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_01)

-- Item 2
trade_item_02 = ConvoScreen:new {
    id = "trade_item_02",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_02"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_02)

give_item_2_02 = ConvoScreen:new {
    id = "give_item_2_02",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_02)

-- Item 3
trade_item_03 = ConvoScreen:new {
    id = "trade_item_03",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_03"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_03)

give_item_2_03 = ConvoScreen:new {
    id = "give_item_2_03",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_03)

-- Item 4
trade_item_04 = ConvoScreen:new {
    id = "trade_item_04",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 4?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_04"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_04)

give_item_2_04 = ConvoScreen:new {
    id = "give_item_2_04",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_04)

-- Item 5
trade_item_05 = ConvoScreen:new {
    id = "trade_item_05",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 5?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_05"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_05)

give_item_2_05 = ConvoScreen:new {
    id = "give_item_2_05",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_05)

-- Item 6
trade_item_06 = ConvoScreen:new {
    id = "trade_item_06",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 6?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_06"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_06)

give_item_2_06 = ConvoScreen:new {
    id = "give_item_2_06",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_06)

-- Item 7
trade_item_07 = ConvoScreen:new {
    id = "trade_item_07",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 7?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_07"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_07)

give_item_2_07 = ConvoScreen:new {
    id = "give_item_2_07",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_07)

-- Item 8
trade_item_08 = ConvoScreen:new {
    id = "trade_item_08",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 8?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_08"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_08)

give_item_2_08 = ConvoScreen:new {
    id = "give_item_2_08",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_08)

-- Item 9
trade_item_09 = ConvoScreen:new {
    id = "trade_item_09",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 9?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_09"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_09)

give_item_2_09 = ConvoScreen:new {
    id = "give_item_2_09",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_09)

-- Item 10
trade_item_10 = ConvoScreen:new {
    id = "trade_item_10",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 10?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_10"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_10)

give_item_2_10 = ConvoScreen:new {
    id = "give_item_2_10",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_10)

-- Item 11
trade_item_11 = ConvoScreen:new {
    id = "trade_item_11",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 11?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_11"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_11)

give_item_2_11 = ConvoScreen:new {
    id = "give_item_2_11",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_11)

-- Item 12
trade_item_12 = ConvoScreen:new {
    id = "trade_item_12",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 12?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_12"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_12)

give_item_2_12 = ConvoScreen:new {
    id = "give_item_2_12",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_12)

-- Item 13
trade_item_13 = ConvoScreen:new {
    id = "trade_item_13",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 13?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_13"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_13)

give_item_2_13 = ConvoScreen:new {
    id = "give_item_2_13",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_13)

-- Item 14
trade_item_14 = ConvoScreen:new {
    id = "trade_item_14",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 14?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_14"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_14)

give_item_2_14 = ConvoScreen:new {
    id = "give_item_2_14",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_14)

-- Item 15
trade_item_15 = ConvoScreen:new {
    id = "trade_item_15",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 15?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_15"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_15)

give_item_2_15 = ConvoScreen:new {
    id = "give_item_2_15",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_15)

-- Item 16
trade_item_16 = ConvoScreen:new {
    id = "trade_item_16",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 16?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_16"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_16)

give_item_2_16 = ConvoScreen:new {
    id = "give_item_2_16",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_16)

-- Item 17
trade_item_17 = ConvoScreen:new {
    id = "trade_item_17",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 17?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_17"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_17)

give_item_2_17 = ConvoScreen:new {
    id = "give_item_2_17",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_17)

-- Item 18
trade_item_18 = ConvoScreen:new {
    id = "trade_item_18",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 18?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_18"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_18)

give_item_2_18 = ConvoScreen:new {
    id = "give_item_2_18",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_18)

-- Item 19
trade_item_19 = ConvoScreen:new {
    id = "trade_item_19",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 19?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_19"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_19)

give_item_2_19 = ConvoScreen:new {
    id = "give_item_2_19",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_19)

-- Item 20
trade_item_20 = ConvoScreen:new {
    id = "trade_item_20",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for Item 20?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_2_20"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_2_conv:addScreen(trade_item_20)

give_item_2_20 = ConvoScreen:new {
    id = "give_item_2_20",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(give_item_2_20)

-- BYE SCREEN
bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "Thank you for visiting the Bellum Gero Token Exchange!",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_2_conv:addScreen(bye)

addConversationTemplate("bg_token_vendor_2_conv", bg_token_vendor_2_conv)

print("[BG-TOKEN-VENDOR-2] Conversation template loaded successfully")
