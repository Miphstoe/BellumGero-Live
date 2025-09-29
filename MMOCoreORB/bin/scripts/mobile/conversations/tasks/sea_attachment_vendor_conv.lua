sea_attachment_vendor_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

sea_attachment_vendor_first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Bring me your unwanted Clothing/Armor Attachments and I'll trade them for goodies!",
    stopConversation = "false",
    options = { 
        {"What items qualify?", "info1"},
        {"I'm ready to trade", "trade_menu"},
        {"Goodbye", "bye"},
    }
}
sea_attachment_vendor_conv:addScreen(sea_attachment_vendor_first_screen);

trade_menu = ConvoScreen:new {    
    id = "trade_menu",
    leftDialog = "",
    customDialogText = "How many qualifying attachments do you have? Choose your tier:",
    stopConversation = "false",
    options = { 
        {"25 attachments (Tier I - Paintings)", "tier_1_menu"},
        {"50 attachments (Tier II - Jedi Furniture)", "tier_2_menu"},
        {"75 attachments (Tier III - Rare Items)", "tier_3_menu"},
        {"I don't have enough yet", "not_enough"},
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(trade_menu);

not_enough = ConvoScreen:new {    
    id = "not_enough",
    leftDialog = "",
    customDialogText = "You need at least 25 attachments to qualify for rewards. Keep collecting!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(not_enough);

-- TIER 1 MENU (25 Attachments)
tier_1_menu = ConvoScreen:new {    
    id = "tier_1_menu",
    leftDialog = "",
    customDialogText = "Tier I Rewards (25 attachments) - Paintings & Art:\n\nChoose your reward:",
    stopConversation = "false",
    options = { 
        {"Star Map", "trade_t1_01"},
        {"Waterfall", "trade_t1_02"},
        {"Bestine Painting 1", "trade_t1_03"},
        {"Bestine Painting 2", "trade_t1_04"},
        {"More options...", "tier_1_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_1_menu);

tier_1_menu_2 = ConvoScreen:new {    
    id = "tier_1_menu_2",
    leftDialog = "",
    customDialogText = "Tier I Rewards (continued):",
    stopConversation = "false",
    options = { 
        {"Tatooine Tapestry", "trade_t1_05"},
        {"Bestine House", "trade_t1_06"},
        {"Krayt Dragon Skeleton", "trade_t1_07"},
        {"Stormtrooper", "trade_t1_08"},
        {"More options...", "tier_1_menu_3"},
        {"Previous page", "tier_1_menu"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_1_menu_2);

tier_1_menu_3 = ConvoScreen:new {    
    id = "tier_1_menu_3",
    leftDialog = "",
    customDialogText = "Tier I Rewards (continued):",
    stopConversation = "false",
    options = { 
        {"Schematic (Droid)", "trade_t1_09"},
        {"Schematic (Transport Ship)", "trade_t1_10"},
        {"Schematic (Weapon)", "trade_t1_11"},
        {"Schematic (Weapon) 3", "trade_t1_12"},
        {"Previous page", "tier_1_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_1_menu_3);

-- TIER 2 MENU (50 Attachments)
tier_2_menu = ConvoScreen:new {    
    id = "tier_2_menu",
    leftDialog = "",
    customDialogText = "Tier II Rewards (50 attachments) - Jedi Furniture:\n\nChoose your reward:",
    stopConversation = "false",
    options = { 
        {"Dark Banner", "trade_t2_01"},
        {"Light Banner", "trade_t2_02"},
        {"Dark Chair (Style 1)", "trade_t2_03"},
        {"Dark Chair (Style 2)", "trade_t2_04"},
        {"More options...", "tier_2_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_2_menu);

tier_2_menu_2 = ConvoScreen:new {    
    id = "tier_2_menu_2",
    leftDialog = "",
    customDialogText = "Tier II Rewards (continued):",
    stopConversation = "false",
    options = { 
        {"Dark Throne", "trade_t2_05"},
        {"Light Chair (Style 1)", "trade_t2_06"},
        {"Light Chair (Style 2)", "trade_t2_07"},
        {"Light Throne", "trade_t2_08"},
        {"More options...", "tier_2_menu_3"},
        {"Previous page", "tier_2_menu"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_2_menu_2);

tier_2_menu_3 = ConvoScreen:new {    
    id = "tier_2_menu_3",
    leftDialog = "",
    customDialogText = "Tier II Rewards (continued):",
    stopConversation = "false",
    options = { 
        {"Dark Table (Style 1)", "trade_t2_09"},
        {"Dark Table (Style 2)", "trade_t2_10"},
        {"Light Table (Style 1)", "trade_t2_11"},
        {"Light Table (Style 2)", "trade_t2_12"},
        {"Jedi Council Seat", "trade_t2_13"},
        {"Previous page", "tier_2_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_2_menu_3);

-- TIER 3 MENU (75 Attachments)
tier_3_menu = ConvoScreen:new {    
    id = "tier_3_menu",
    leftDialog = "",
    customDialogText = "Tier III Rewards (75 attachments) - Rare Items:\n\nChoose your reward:",
    stopConversation = "false",
    options = { 
        {"Bacta Tank", "trade_t3_01"},
        {"Hanging Planter", "trade_t3_02"},
        {"Stuffed Fish", "trade_t3_03"},
        {"Blowfish", "trade_t3_04"},
        {"More options...", "tier_3_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_3_menu);

tier_3_menu_2 = ConvoScreen:new {    
    id = "tier_3_menu_2",
    leftDialog = "",
    customDialogText = "Tier III Rewards (continued):",
    stopConversation = "false",
    options = { 
        {"Decorative Campfire", "trade_t3_05"},
        {"Microphone", "trade_t3_06"},
        {"VR: Cast Wing in Flight", "trade_t3_07"},
        {"VR: Decimator", "trade_t3_08"},
        {"More options...", "tier_3_menu_3"},
        {"Previous page", "tier_3_menu"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_3_menu_2);

tier_3_menu_3 = ConvoScreen:new {    
    id = "tier_3_menu_3",
    leftDialog = "",
    customDialogText = "Tier III Rewards (Veteran Rewards continued):",
    stopConversation = "false",
    options = { 
        {"VR: Weapon of War", "trade_t3_09"},
        {"VR: Tatooine Dune Speeder", "trade_t3_10"},
        {"VR: Fighter Study", "trade_t3_11"},
        {"VR: Hutt Greed", "trade_t3_12"},
        {"More options...", "tier_3_menu_4"},
        {"Previous page", "tier_3_menu_2"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_3_menu_3);

tier_3_menu_4 = ConvoScreen:new {    
    id = "tier_3_menu_4",
    leftDialog = "",
    customDialogText = "Tier III Rewards (Veteran Rewards final):",
    stopConversation = "false",
    options = { 
        {"VR: Smuggler's Run", "trade_t3_13"},
        {"VR: Imperial TIE Oppressor", "trade_t3_14"},
        {"VR: Emperor's Eyes TIE", "trade_t3_15"},
        {"Previous page", "tier_3_menu_3"},
        {"Back", "trade_menu"},
    }
}
sea_attachment_vendor_conv:addScreen(tier_3_menu_4);

-- TIER 1 TRADE CONFIRMATION SCREENS
trade_t1_01 = ConvoScreen:new {    
    id = "trade_t1_01",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Star Map?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_01"},
        {"No, go back", "tier_1_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_01);

give_t1_01 = ConvoScreen:new {    
    id = "give_t1_01",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_01);

trade_t1_02 = ConvoScreen:new {    
    id = "trade_t1_02",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Waterfall?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_02"},
        {"No, go back", "tier_1_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_02);

give_t1_02 = ConvoScreen:new {    
    id = "give_t1_02",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_02);

trade_t1_03 = ConvoScreen:new {    
    id = "trade_t1_03",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Bestine Painting 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_03"},
        {"No, go back", "tier_1_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_03);

give_t1_03 = ConvoScreen:new {    
    id = "give_t1_03",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_03);

trade_t1_04 = ConvoScreen:new {    
    id = "trade_t1_04",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Bestine Painting 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_04"},
        {"No, go back", "tier_1_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_04);

give_t1_04 = ConvoScreen:new {    
    id = "give_t1_04",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_04);

trade_t1_05 = ConvoScreen:new {    
    id = "trade_t1_05",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Tatooine Tapestry?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_05"},
        {"No, go back", "tier_1_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_05);

give_t1_05 = ConvoScreen:new {    
    id = "give_t1_05",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_05);

trade_t1_06 = ConvoScreen:new {    
    id = "trade_t1_06",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Bestine House?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_06"},
        {"No, go back", "tier_1_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_06);

give_t1_06 = ConvoScreen:new {    
    id = "give_t1_06",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_06);

trade_t1_07 = ConvoScreen:new {    
    id = "trade_t1_07",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Krayt Dragon Skeleton?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_07"},
        {"No, go back", "tier_1_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_07);

give_t1_07 = ConvoScreen:new {    
    id = "give_t1_07",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_07);

trade_t1_08 = ConvoScreen:new {    
    id = "trade_t1_08",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Stormtrooper?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_08"},
        {"No, go back", "tier_1_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_08);

give_t1_08 = ConvoScreen:new {    
    id = "give_t1_08",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_08);

trade_t1_09 = ConvoScreen:new {    
    id = "trade_t1_09",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Schematic (Droid)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_09"},
        {"No, go back", "tier_1_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_09);

give_t1_09 = ConvoScreen:new {    
    id = "give_t1_09",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_09);

trade_t1_10 = ConvoScreen:new {    
    id = "trade_t1_10",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Schematic (Transport Ship)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_10"},
        {"No, go back", "tier_1_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_10);

give_t1_10 = ConvoScreen:new {    
    id = "give_t1_10",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_10);

trade_t1_11 = ConvoScreen:new {    
    id = "trade_t1_11",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Schematic (Weapon)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_11"},
        {"No, go back", "tier_1_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_11);

give_t1_11 = ConvoScreen:new {    
    id = "give_t1_11",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_11);

trade_t1_12 = ConvoScreen:new {    
    id = "trade_t1_12",
    leftDialog = "",
    customDialogText = "Confirm: Trade 25 attachments for Schematic (Weapon) 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t1_12"},
        {"No, go back", "tier_1_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t1_12);

give_t1_12 = ConvoScreen:new {    
    id = "give_t1_12",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t1_12);

trade_t2_01 = ConvoScreen:new {    
    id = "trade_t2_01",
    leftDialog = "",
    customDialogText = "Confirm: Trade 50 attachments for Dark Banner?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t2_01"},
        {"No, go back", "tier_2_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t2_01);

give_t2_01 = ConvoScreen:new {    
    id = "give_t2_01",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_02 = ConvoScreen:new {    
    id = "trade_t2_02",
    leftDialog = "",
    customDialogText = "Confirm: Trade 50 attachments for Dark Banner?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t2_01"},
        {"No, go back", "tier_2_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t2_01);

give_t2_03 = ConvoScreen:new {    
    id = "give_t2_02",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_03 = ConvoScreen:new {    
    id = "trade_t2_02",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_04 = ConvoScreen:new {    
    id = "give_t2_04",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_04 = ConvoScreen:new {    
    id = "trade_t2_04",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_05 = ConvoScreen:new {    
    id = "give_t2_05",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_05 = ConvoScreen:new {    
    id = "trade_t2_05",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_06 = ConvoScreen:new {    
    id = "give_t2_06",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_06 = ConvoScreen:new {    
    id = "trade_t2_06",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_07 = ConvoScreen:new {    
    id = "give_t2_07",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_07 = ConvoScreen:new {    
    id = "trade_t2_07",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_08 = ConvoScreen:new {    
    id = "give_t2_08",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_08 = ConvoScreen:new {    
    id = "trade_t2_08",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_09 = ConvoScreen:new {    
    id = "give_t2_09",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_09 = ConvoScreen:new {    
    id = "trade_t2_09",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_10 = ConvoScreen:new {    
    id = "give_t2_10",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_10 = ConvoScreen:new {    
    id = "trade_t2_10",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_11 = ConvoScreen:new {    
    id = "give_t2_11",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_11 = ConvoScreen:new {    
    id = "trade_t2_11",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_12 = ConvoScreen:new {    
    id = "give_t2_12",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_12 = ConvoScreen:new {    
    id = "trade_t2_12",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

give_t2_13 = ConvoScreen:new {    
    id = "give_t2_13",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t2_01);

trade_t2_13 = ConvoScreen:new {    
    id = "trade_t2_13",
    leftDialog = "",
    customDialogText = "I accept:\n\n- Clothing Attachments (CA)\n- Armor Attachments (AA)\n- Any item with 'attachment' in the name\n\nCheck your inventory!",
    stopConversation = "false",
    options = { 
        {"Back", "first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(info1);

-- TIER 3 TRADE CONFIRMATION SCREENS (15 items)
trade_t3_01 = ConvoScreen:new {    
    id = "trade_t3_01",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Bacta Tank?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_01"},
        {"No, go back", "tier_3_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_01);

give_t3_01 = ConvoScreen:new {    
    id = "give_t3_01",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_01);

trade_t3_02 = ConvoScreen:new {    
    id = "trade_t3_02",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Hanging Planter?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_02"},
        {"No, go back", "tier_3_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_02);

give_t3_02 = ConvoScreen:new {    
    id = "give_t3_02",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_02);

trade_t3_03 = ConvoScreen:new {    
    id = "trade_t3_03",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Stuffed Fish?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_03"},
        {"No, go back", "tier_3_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_03);

give_t3_03 = ConvoScreen:new {    
    id = "give_t3_03",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_03);

trade_t3_04 = ConvoScreen:new {    
    id = "trade_t3_04",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Blowfish?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_04"},
        {"No, go back", "tier_3_menu"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_04);

give_t3_04 = ConvoScreen:new {    
    id = "give_t3_04",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_04);

trade_t3_05 = ConvoScreen:new {    
    id = "trade_t3_05",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Decorative Campfire?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_05"},
        {"No, go back", "tier_3_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_05);

give_t3_05 = ConvoScreen:new {    
    id = "give_t3_05",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_05);

trade_t3_06 = ConvoScreen:new {    
    id = "trade_t3_06",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for Microphone?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_06"},
        {"No, go back", "tier_3_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_06);

give_t3_06 = ConvoScreen:new {    
    id = "give_t3_06",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_06);

trade_t3_07 = ConvoScreen:new {    
    id = "trade_t3_07",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Cast Wing in Flight?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_07"},
        {"No, go back", "tier_3_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_07);

give_t3_07 = ConvoScreen:new {    
    id = "give_t3_07",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_07);

trade_t3_08 = ConvoScreen:new {    
    id = "trade_t3_08",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Decimator?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_08"},
        {"No, go back", "tier_3_menu_2"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_08);

give_t3_08 = ConvoScreen:new {    
    id = "give_t3_08",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_08);

trade_t3_09 = ConvoScreen:new {    
    id = "trade_t3_09",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Weapon of War?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_09"},
        {"No, go back", "tier_3_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_09);

give_t3_09 = ConvoScreen:new {    
    id = "give_t3_09",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_09);

trade_t3_10 = ConvoScreen:new {    
    id = "trade_t3_10",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Tatooine Dune Speeder?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_10"},
        {"No, go back", "tier_3_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_10);

give_t3_10 = ConvoScreen:new {    
    id = "give_t3_10",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_10);

trade_t3_11 = ConvoScreen:new {    
    id = "trade_t3_11",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Fighter Study?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_11"},
        {"No, go back", "tier_3_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_11);

give_t3_11 = ConvoScreen:new {    
    id = "give_t3_11",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_11);

trade_t3_12 = ConvoScreen:new {    
    id = "trade_t3_12",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Hutt Greed?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_12"},
        {"No, go back", "tier_3_menu_3"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_12);

give_t3_12 = ConvoScreen:new {    
    id = "give_t3_12",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_12);

trade_t3_13 = ConvoScreen:new {    
    id = "trade_t3_13",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Smuggler's Run?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_13"},
        {"No, go back", "tier_3_menu_4"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_13);

give_t3_13 = ConvoScreen:new {    
    id = "give_t3_13",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_13);

trade_t3_14 = ConvoScreen:new {    
    id = "trade_t3_14",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Imperial TIE Oppressor?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_14"},
        {"No, go back", "tier_3_menu_4"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_14);

give_t3_14 = ConvoScreen:new {    
    id = "give_t3_14",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_14);

trade_t3_15 = ConvoScreen:new {    
    id = "trade_t3_15",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 attachments for VR: Emperor's Eyes TIE?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_t3_15"},
        {"No, go back", "tier_3_menu_4"}
    }
}
sea_attachment_vendor_conv:addScreen(trade_t3_15);

give_t3_15 = ConvoScreen:new {    
    id = "give_t3_15",
    leftDialog = "",
    customDialogText = "Processing trade...",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(give_t3_15);

bye = ConvoScreen:new {    
    id = "bye",
    leftDialog = "",
    customDialogText = "Come back when you have attachments to trade!",
    stopConversation = "true",
    options = { }
}
sea_attachment_vendor_conv:addScreen(bye);

addConversationTemplate("sea_attachment_vendor_conv", sea_attachment_vendor_conv);