-- Holocron Village Rewards Vendor Conversation
print("[HOLOCRON-VENDOR] Loading conversation template...")

holocron_village_vendor_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

-- OPENING SCREEN
first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Greetings, traveler. I trade rare village quest rewards for Holocrons of Destiny. Each item costs 2 Holocrons of Destiny. I have 10 authentic village quest reward items - decorations and sculptures that were once only available through the old village quests. Browse my collection!",
    stopConversation = "false",
    options = {
        {"View Available Items", "items_menu"},
        {"How much do items cost?", "cost_info"},
        {"Goodbye", "bye"},
    }
}
holocron_village_vendor_conv:addScreen(first_screen)

-- INFO SCREEN
cost_info = ConvoScreen:new {
    id = "cost_info",
    leftDialog = "",
    customDialogText = "All items in my inventory cost exactly 2 Holocrons of Destiny each. Simply choose an item, confirm the trade, and it's yours!",
    stopConversation = "false",
    options = {
        {"Show me the items", "items_menu"},
        {"Back", "first_screen"},
    }
}
holocron_village_vendor_conv:addScreen(cost_info)

-- ITEMS MENU (showing 9 village quest reward items)
items_menu = ConvoScreen:new {
    id = "items_menu",
    leftDialog = "",
    customDialogText = "Choose an item (2 Holocrons of Destiny each):\n\nItems 1-5:",
    stopConversation = "false",
    options = {
        {"Item 1 - [Bacta Tank]", "trade_holo_03"},
        {"Item 2 - [Village Banner Pole]", "trade_holo_04"},
        {"Item 3 - [FS Buff Item]", "trade_holo_05"},
        {"Item 4 - [Village Sculpture 1]", "trade_holo_06"},
        {"Item 5 - [Village Sculpture 2]", "trade_holo_07"},
        {"More items...", "items_menu_2"},
        {"Back", "first_screen"},
    }
}
holocron_village_vendor_conv:addScreen(items_menu)

-- ITEMS MENU PAGE 2
items_menu_2 = ConvoScreen:new {
    id = "items_menu_2",
    leftDialog = "",
    customDialogText = "Choose an item (2 Holocrons of Destiny each):\n\nItems 6-10:",
    stopConversation = "false",
    options = {
        {"Item 6 - [Village Sculpture 3]", "trade_holo_08"},
        {"Item 7 - [Village Sculpture 4]", "trade_holo_09"},
        {"Item 8 - [Dark Banner]", "trade_holo_12"},
        {"Item 9 - [Light Banner]", "trade_holo_13"},
        {"Item 10 - [Radar Topography Screen]", "trade_holo_10"},
        {"Previous", "items_menu"},
        {"Back", "first_screen"},
    }
}
holocron_village_vendor_conv:addScreen(items_menu_2)

-- TRADE SCREENS FOR EACH ITEM (Items 1-9)
-- Item 1 (Bacta Tank)
trade_holo_03 = ConvoScreen:new {
    id = "trade_holo_03",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Bacta Tank?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_03"},
        {"No, go back", "items_menu"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_03)

give_holo_03 = ConvoScreen:new {
    id = "give_holo_03",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_03)

-- Item 4
trade_holo_04 = ConvoScreen:new {
    id = "trade_holo_04",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Village Banner Pole?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_04"},
        {"No, go back", "items_menu"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_04)

give_holo_04 = ConvoScreen:new {
    id = "give_holo_04",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_04)

-- Item 5
trade_holo_05 = ConvoScreen:new {
    id = "trade_holo_05",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for FS Buff Item?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_05"},
        {"No, go back", "items_menu"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_05)

give_holo_05 = ConvoScreen:new {
    id = "give_holo_05",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_05)

-- Item 6
trade_holo_06 = ConvoScreen:new {
    id = "trade_holo_06",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Village Sculpture 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_06"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_06)

give_holo_06 = ConvoScreen:new {
    id = "give_holo_06",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_06)

-- Item 7
trade_holo_07 = ConvoScreen:new {
    id = "trade_holo_07",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Village Sculpture 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_07"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_07)

give_holo_07 = ConvoScreen:new {
    id = "give_holo_07",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_07)

-- Item 8
trade_holo_08 = ConvoScreen:new {
    id = "trade_holo_08",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Village Sculpture 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_08"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_08)

give_holo_08 = ConvoScreen:new {
    id = "give_holo_08",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_08)

-- Item 9
trade_holo_09 = ConvoScreen:new {
    id = "trade_holo_09",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Village Sculpture 4?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_09"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_09)

give_holo_09 = ConvoScreen:new {
    id = "give_holo_09",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_09)

-- Item 8 (Dark Banner)
trade_holo_12 = ConvoScreen:new {
    id = "trade_holo_12",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Dark Banner?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_12"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_12)

give_holo_12 = ConvoScreen:new {
    id = "give_holo_12",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_12)

-- Item 9 (Light Banner)
trade_holo_13 = ConvoScreen:new {
    id = "trade_holo_13",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Light Banner?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_13"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_13)

give_holo_13 = ConvoScreen:new {
    id = "give_holo_13",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_13)

-- Item 10 (Radar Topography Screen)
trade_holo_10 = ConvoScreen:new {
    id = "trade_holo_10",
    leftDialog = "",
    customDialogText = "Confirm: Trade 2 Holocrons of Destiny for Radar Topography Screen?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_holo_10"},
        {"No, go back", "items_menu_2"}
    }
}
holocron_village_vendor_conv:addScreen(trade_holo_10)

give_holo_10 = ConvoScreen:new {
    id = "give_holo_10",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(give_holo_10)

-- BYE SCREEN
bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "May the Force be with you!",
    stopConversation = "true",
    options = { }
}
holocron_village_vendor_conv:addScreen(bye)

addConversationTemplate("holocron_village_vendor_conv", holocron_village_vendor_conv)

print("[HOLOCRON-VENDOR] Conversation template loaded successfully")
