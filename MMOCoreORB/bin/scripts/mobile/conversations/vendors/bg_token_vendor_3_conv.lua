-- Bellum Gero Token Vendor 3 - Veteran Rewards Conversation (75 tokens per item)
print("[BG-TOKEN-VENDOR-3] Loading conversation template...")

bg_token_vendor_3_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

-- OPENING SCREEN
first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Welcome to the Bellum Gero Veteran Rewards Exchange! I carry every Veteran Reward item. Each item costs 75 Bellum Gero Tokens. Browse my wares!",
    stopConversation = "false",
    options = {
        {"View Available Items", "items_menu"},
        {"How much do items cost?", "cost_info"},
        {"Goodbye", "bye"},
    }
}
bg_token_vendor_3_conv:addScreen(first_screen)

-- INFO SCREEN
cost_info = ConvoScreen:new {
    id = "cost_info",
    leftDialog = "",
    customDialogText = "All Veteran Reward items in my inventory cost exactly 75 Bellum Gero Tokens each. Simply choose an item, confirm the trade, and it's yours!",
    stopConversation = "false",
    options = {
        {"Show me the items", "items_menu"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(cost_info)

-- PAGE 1: Items 2-5
items_menu = ConvoScreen:new {
    id = "items_menu",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\n2-Day Veteran Rewards:",
    stopConversation = "false",
    options = {
        {"Item 02 - [Data Terminal Style 1]", "trade_item_3_02"},
        {"Item 03 - [Data Terminal Style 2]", "trade_item_3_03"},
        {"Item 04 - [Data Terminal Style 3]", "trade_item_3_04"},
        {"Item 05 - [Data Terminal Style 4]", "trade_item_3_05"},
        {"More items...", "items_menu_2"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu)

-- PAGE 2: Items 6-10
items_menu_2 = ConvoScreen:new {
    id = "items_menu_2",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\n2/4-Day Veteran Rewards:",
    stopConversation = "false",
    options = {
        {"Item 06 - [Protocol Droid Toy]", "trade_item_3_06"},
        {"Item 07 - [R2 Unit Toy]", "trade_item_3_07"},
        {"Item 09 - [Falcon Couch Corner]", "trade_item_3_09"},
        {"Item 10 - [Falcon Couch Section]", "trade_item_3_10"},
        {"More items...", "items_menu_3"},
        {"Previous", "items_menu"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_2)

-- PAGE 3: Items 11-15
items_menu_3 = ConvoScreen:new {
    id = "items_menu_3",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\n4/8-Day Veteran Rewards:",
    stopConversation = "false",
    options = {
        {"Item 11 - [TIE Fighter Toy]", "trade_item_3_11"},
        {"Item 12 - [X-Wing Toy]", "trade_item_3_12"},
        {"Item 15 - [SE Goggles Style 1]", "trade_item_3_15"},
        {"More items...", "items_menu_4"},
        {"Previous", "items_menu_2"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_3)

-- PAGE 4: Items 16-20
items_menu_4 = ConvoScreen:new {
    id = "items_menu_4",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 16-20 (8-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 16 - [SE Goggles Style 2]", "trade_item_3_16"},
        {"Item 17 - [SE Goggles Style 3]", "trade_item_3_17"},
        {"Item 18 - [SE Goggles Style 4]", "trade_item_3_18"},
        {"Item 19 - [SE Goggles Style 5]", "trade_item_3_19"},
        {"Item 20 - [SE Goggles Style 6]", "trade_item_3_20"},
        {"More items...", "items_menu_5"},
        {"Previous", "items_menu_3"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_4)

-- PAGE 5: Items 21-25
items_menu_5 = ConvoScreen:new {
    id = "items_menu_5",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 21-25 (8/12-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 21 - [Darth Vader Toy]", "trade_item_3_21"},
        {"Item 22 - [Tech Console Sectional A]", "trade_item_3_22"},
        {"Item 23 - [Tech Console Sectional B]", "trade_item_3_23"},
        {"Item 24 - [Tech Console Sectional C]", "trade_item_3_24"},
        {"Item 25 - [Tech Console Sectional D]", "trade_item_3_25"},
        {"More items...", "items_menu_6"},
        {"Previous", "items_menu_4"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_5)

-- PAGE 6: Items 26-30
items_menu_6 = ConvoScreen:new {
    id = "items_menu_6",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 26-30 (12/16-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 26 - [Jabba Toy]", "trade_item_3_26"},
        {"Item 27 - [Stormtrooper Toy]", "trade_item_3_27"},
        {"Item 28 - [Camp Center (Small)]", "trade_item_3_28"},
        {"Item 29 - [Camp Center (Large)]", "trade_item_3_29"},
        {"Item 30 - [Gold Ornamental Vase Style 1]", "trade_item_3_30"},
        {"More items...", "items_menu_7"},
        {"Previous", "items_menu_5"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_6)

-- PAGE 7: Items 31-35
items_menu_7 = ConvoScreen:new {
    id = "items_menu_7",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 31-35 (16/20-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 31 - [Gold Ornamental Vase Style 2]", "trade_item_3_31"},
        {"Item 32 - [Foodcart]", "trade_item_3_32"},
        {"Item 33 - [Park Bench]", "trade_item_3_33"},
        {"Item 34 - [Professor Desk]", "trade_item_3_34"},
        {"Item 35 - [Diagnostic Screen]", "trade_item_3_35"},
        {"More items...", "items_menu_8"},
        {"Previous", "items_menu_6"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_7)

-- PAGE 8: Items 36-40
items_menu_8 = ConvoScreen:new {
    id = "items_menu_8",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 36-40 (20/30-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 36 - [Large Potted Plant Style 2]", "trade_item_3_36"},
        {"Item 37 - [Large Potted Plant Style 3]", "trade_item_3_37"},
        {"Item 38 - [Large Potted Plant Style 4]", "trade_item_3_38"},
        {"Item 39 - [Bar Countertop]", "trade_item_3_39"},
        {"Item 40 - [Bar Countertop (Curved, Style 1)]", "trade_item_3_40"},
        {"More items...", "items_menu_9"},
        {"Previous", "items_menu_7"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_8)

-- PAGE 9: Items 41-45
items_menu_9 = ConvoScreen:new {
    id = "items_menu_9",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 41-45 (30/45-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 41 - [Bar Countertop (Curved, Style 2)]", "trade_item_3_41"},
        {"Item 42 - [Bar Countertop (Straight, Style 1)]", "trade_item_3_42"},
        {"Item 43 - [Bar Countertop (Straight, Style 2)]", "trade_item_3_43"},
        {"Item 44 - [Round Cantina Table Style 1]", "trade_item_3_44"},
        {"Item 45 - [Round Cantina Table Style 2]", "trade_item_3_45"},
        {"More items...", "items_menu_10"},
        {"Previous", "items_menu_8"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_9)

-- PAGE 10: Items 46-50
items_menu_10 = ConvoScreen:new {
    id = "items_menu_10",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 46-50 (45/60-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 46 - [Round Cantina Table Style 3]", "trade_item_3_46"},
        {"Item 47 - [Large Cantina Sofa]", "trade_item_3_47"},
        {"Item 48 - [Cafe Parasol]", "trade_item_3_48"},
        {"Item 49 - [Medium Oval Rug]", "trade_item_3_49"},
        {"Item 50 - [Small Oval Rug]", "trade_item_3_50"},
        {"More items...", "items_menu_11"},
        {"Previous", "items_menu_9"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_10)

-- PAGE 11: Items 51-55
items_menu_11 = ConvoScreen:new {
    id = "items_menu_11",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 51-55 (60/75-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 51 - [Medium Rectangular Rug]", "trade_item_3_51"},
        {"Item 52 - [Small Rectangular Rug]", "trade_item_3_52"},
        {"Item 53 - [Medium Round Rug]", "trade_item_3_53"},
        {"Item 54 - [Small Round Rug]", "trade_item_3_54"},
        {"Item 55 - [Bith Skull]", "trade_item_3_55"},
        {"More items...", "items_menu_12"},
        {"Previous", "items_menu_10"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_11)

-- PAGE 12: Items 56-60
items_menu_12 = ConvoScreen:new {
    id = "items_menu_12",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 56-60 (75-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 56 - [Human Skull]", "trade_item_3_56"},
        {"Item 57 - [Ithorian Skull]", "trade_item_3_57"},
        {"Item 58 - [Thune Skull]", "trade_item_3_58"},
        {"Item 59 - [Voritor Lizard Skull]", "trade_item_3_59"},
        {"Item 60 - [Rebel Endor Helmet]", "trade_item_3_60"},
        {"More items...", "items_menu_13"},
        {"Previous", "items_menu_11"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_12)

-- PAGE 13: Items 61-65
items_menu_13 = ConvoScreen:new {
    id = "items_menu_13",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 61-65 (90-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 61 - [Large Rectangular Rug Style 1]", "trade_item_3_61"},
        {"Item 62 - [Large Rectangular Rug Style 2]", "trade_item_3_62"},
        {"Item 63 - [Large Oval Rug]", "trade_item_3_63"},
        {"Item 64 - [Large Round Rug]", "trade_item_3_64"},
        {"Item 65 - [Round Data Terminal]", "trade_item_3_65"},
        {"More items...", "items_menu_14"},
        {"Previous", "items_menu_12"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_13)

-- PAGE 14: Items 66-70
items_menu_14 = ConvoScreen:new {
    id = "items_menu_14",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 66-70 (90/105-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 66 - [Nightsister Melee Armguard]", "trade_item_3_66"},
        {"Item 67 - [Painting: Cast Wing in Flight]", "trade_item_3_67"},
        {"Item 68 - [Painting: Decimator]", "trade_item_3_68"},
        {"Item 69 - [Painting: Tatooine Dune Speeder]", "trade_item_3_69"},
        {"Item 70 - [Painting: Weapon of War]", "trade_item_3_70"},
        {"More items...", "items_menu_15"},
        {"Previous", "items_menu_13"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_14)

-- PAGE 15: Items 71-75
items_menu_15 = ConvoScreen:new {
    id = "items_menu_15",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nItems 71-75 (105-Day Veteran Rewards):",
    stopConversation = "false",
    options = {
        {"Item 71 - [Painting: Fighter Study]", "trade_item_3_71"},
        {"Item 72 - [Painting: Hutt Greed]", "trade_item_3_72"},
        {"Item 73 - [Painting: Smuggler's Run]", "trade_item_3_73"},
        {"Item 74 - [Painting: Imperial Oppression]", "trade_item_3_74"},
        {"Item 75 - [Painting: Emperor's Eyes]", "trade_item_3_75"},
        {"More items...", "items_menu_16"},
        {"Previous", "items_menu_14"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_15)

-- PAGE 16: Item 76
items_menu_16 = ConvoScreen:new {
    id = "items_menu_16",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nSpace Veteran Rewards:",
    stopConversation = "false",
    options = {
        {"Item 76 - [SoroSuub Luxury Yacht Deed]", "trade_item_3_76"},
        {"More items...", "items_menu_17"},
        {"Previous", "items_menu_15"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_16)

-- TRADE SCREENS FOR EACH ITEM
-- Item 02
trade_item_3_02 = ConvoScreen:new {
    id = "trade_item_3_02",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Data Terminal Style 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_02"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_02)
give_item_3_02 = ConvoScreen:new { id = "give_item_3_02", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_02)

-- Item 03
trade_item_3_03 = ConvoScreen:new {
    id = "trade_item_3_03",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Data Terminal Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_03"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_03)
give_item_3_03 = ConvoScreen:new { id = "give_item_3_03", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_03)

-- Item 04
trade_item_3_04 = ConvoScreen:new {
    id = "trade_item_3_04",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Data Terminal Style 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_04"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_04)
give_item_3_04 = ConvoScreen:new { id = "give_item_3_04", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_04)

-- Item 05
trade_item_3_05 = ConvoScreen:new {
    id = "trade_item_3_05",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Data Terminal Style 4?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_05"},
        {"No, go back", "items_menu"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_05)
give_item_3_05 = ConvoScreen:new { id = "give_item_3_05", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_05)

-- Item 06
trade_item_3_06 = ConvoScreen:new {
    id = "trade_item_3_06",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Protocol Droid Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_06"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_06)
give_item_3_06 = ConvoScreen:new { id = "give_item_3_06", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_06)

-- Item 07
trade_item_3_07 = ConvoScreen:new {
    id = "trade_item_3_07",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the R2 Unit Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_07"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_07)
give_item_3_07 = ConvoScreen:new { id = "give_item_3_07", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_07)

-- Item 09
trade_item_3_09 = ConvoScreen:new {
    id = "trade_item_3_09",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Falcon Couch Corner?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_09"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_09)
give_item_3_09 = ConvoScreen:new { id = "give_item_3_09", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_09)

-- Item 10
trade_item_3_10 = ConvoScreen:new {
    id = "trade_item_3_10",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Falcon Couch Section?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_10"},
        {"No, go back", "items_menu_2"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_10)
give_item_3_10 = ConvoScreen:new { id = "give_item_3_10", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_10)

-- Item 11
trade_item_3_11 = ConvoScreen:new {
    id = "trade_item_3_11",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the TIE Fighter Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_11"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_11)
give_item_3_11 = ConvoScreen:new { id = "give_item_3_11", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_11)

-- Item 12
trade_item_3_12 = ConvoScreen:new {
    id = "trade_item_3_12",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the X-Wing Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_12"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_12)
give_item_3_12 = ConvoScreen:new { id = "give_item_3_12", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_12)

-- Item 15
trade_item_3_15 = ConvoScreen:new {
    id = "trade_item_3_15",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_15"},
        {"No, go back", "items_menu_3"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_15)
give_item_3_15 = ConvoScreen:new { id = "give_item_3_15", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_15)

-- Item 16
trade_item_3_16 = ConvoScreen:new {
    id = "trade_item_3_16",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_16"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_16)
give_item_3_16 = ConvoScreen:new { id = "give_item_3_16", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_16)

-- Item 17
trade_item_3_17 = ConvoScreen:new {
    id = "trade_item_3_17",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_17"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_17)
give_item_3_17 = ConvoScreen:new { id = "give_item_3_17", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_17)

-- Item 18
trade_item_3_18 = ConvoScreen:new {
    id = "trade_item_3_18",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 4?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_18"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_18)
give_item_3_18 = ConvoScreen:new { id = "give_item_3_18", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_18)

-- Item 19
trade_item_3_19 = ConvoScreen:new {
    id = "trade_item_3_19",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 5?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_19"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_19)
give_item_3_19 = ConvoScreen:new { id = "give_item_3_19", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_19)

-- Item 20
trade_item_3_20 = ConvoScreen:new {
    id = "trade_item_3_20",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SE Goggles Style 6?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_20"},
        {"No, go back", "items_menu_4"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_20)
give_item_3_20 = ConvoScreen:new { id = "give_item_3_20", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_20)

-- Item 21
trade_item_3_21 = ConvoScreen:new {
    id = "trade_item_3_21",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Darth Vader Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_21"},
        {"No, go back", "items_menu_5"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_21)
give_item_3_21 = ConvoScreen:new { id = "give_item_3_21", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_21)

-- Item 22
trade_item_3_22 = ConvoScreen:new {
    id = "trade_item_3_22",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Tech Console Sectional A?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_22"},
        {"No, go back", "items_menu_5"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_22)
give_item_3_22 = ConvoScreen:new { id = "give_item_3_22", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_22)

-- Item 23
trade_item_3_23 = ConvoScreen:new {
    id = "trade_item_3_23",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Tech Console Sectional B?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_23"},
        {"No, go back", "items_menu_5"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_23)
give_item_3_23 = ConvoScreen:new { id = "give_item_3_23", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_23)

-- Item 24
trade_item_3_24 = ConvoScreen:new {
    id = "trade_item_3_24",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Tech Console Sectional C?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_24"},
        {"No, go back", "items_menu_5"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_24)
give_item_3_24 = ConvoScreen:new { id = "give_item_3_24", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_24)

-- Item 25
trade_item_3_25 = ConvoScreen:new {
    id = "trade_item_3_25",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Tech Console Sectional D?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_25"},
        {"No, go back", "items_menu_5"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_25)
give_item_3_25 = ConvoScreen:new { id = "give_item_3_25", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_25)

-- Item 26
trade_item_3_26 = ConvoScreen:new {
    id = "trade_item_3_26",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Jabba Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_26"},
        {"No, go back", "items_menu_6"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_26)
give_item_3_26 = ConvoScreen:new { id = "give_item_3_26", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_26)

-- Item 27
trade_item_3_27 = ConvoScreen:new {
    id = "trade_item_3_27",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Stormtrooper Toy?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_27"},
        {"No, go back", "items_menu_6"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_27)
give_item_3_27 = ConvoScreen:new { id = "give_item_3_27", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_27)

-- Item 28
trade_item_3_28 = ConvoScreen:new {
    id = "trade_item_3_28",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Camp Center (Small)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_28"},
        {"No, go back", "items_menu_6"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_28)
give_item_3_28 = ConvoScreen:new { id = "give_item_3_28", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_28)

-- Item 29
trade_item_3_29 = ConvoScreen:new {
    id = "trade_item_3_29",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Camp Center (Large)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_29"},
        {"No, go back", "items_menu_6"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_29)
give_item_3_29 = ConvoScreen:new { id = "give_item_3_29", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_29)

-- Item 30
trade_item_3_30 = ConvoScreen:new {
    id = "trade_item_3_30",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Gold Ornamental Vase Style 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_30"},
        {"No, go back", "items_menu_6"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_30)
give_item_3_30 = ConvoScreen:new { id = "give_item_3_30", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_30)

-- Item 31
trade_item_3_31 = ConvoScreen:new {
    id = "trade_item_3_31",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Gold Ornamental Vase Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_31"},
        {"No, go back", "items_menu_7"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_31)
give_item_3_31 = ConvoScreen:new { id = "give_item_3_31", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_31)

-- Item 32
trade_item_3_32 = ConvoScreen:new {
    id = "trade_item_3_32",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Foodcart?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_32"},
        {"No, go back", "items_menu_7"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_32)
give_item_3_32 = ConvoScreen:new { id = "give_item_3_32", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_32)

-- Item 33
trade_item_3_33 = ConvoScreen:new {
    id = "trade_item_3_33",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Park Bench?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_33"},
        {"No, go back", "items_menu_7"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_33)
give_item_3_33 = ConvoScreen:new { id = "give_item_3_33", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_33)

-- Item 34
trade_item_3_34 = ConvoScreen:new {
    id = "trade_item_3_34",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Professor Desk?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_34"},
        {"No, go back", "items_menu_7"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_34)
give_item_3_34 = ConvoScreen:new { id = "give_item_3_34", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_34)

-- Item 35
trade_item_3_35 = ConvoScreen:new {
    id = "trade_item_3_35",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Diagnostic Screen?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_35"},
        {"No, go back", "items_menu_7"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_35)
give_item_3_35 = ConvoScreen:new { id = "give_item_3_35", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_35)

-- Item 36
trade_item_3_36 = ConvoScreen:new {
    id = "trade_item_3_36",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Potted Plant Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_36"},
        {"No, go back", "items_menu_8"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_36)
give_item_3_36 = ConvoScreen:new { id = "give_item_3_36", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_36)

-- Item 37
trade_item_3_37 = ConvoScreen:new {
    id = "trade_item_3_37",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Potted Plant Style 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_37"},
        {"No, go back", "items_menu_8"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_37)
give_item_3_37 = ConvoScreen:new { id = "give_item_3_37", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_37)

-- Item 38
trade_item_3_38 = ConvoScreen:new {
    id = "trade_item_3_38",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Potted Plant Style 4?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_38"},
        {"No, go back", "items_menu_8"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_38)
give_item_3_38 = ConvoScreen:new { id = "give_item_3_38", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_38)

-- Item 39
trade_item_3_39 = ConvoScreen:new {
    id = "trade_item_3_39",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bar Countertop?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_39"},
        {"No, go back", "items_menu_8"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_39)
give_item_3_39 = ConvoScreen:new { id = "give_item_3_39", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_39)

-- Item 40
trade_item_3_40 = ConvoScreen:new {
    id = "trade_item_3_40",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bar Countertop (Curved, Style 1)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_40"},
        {"No, go back", "items_menu_8"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_40)
give_item_3_40 = ConvoScreen:new { id = "give_item_3_40", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_40)

-- Item 41
trade_item_3_41 = ConvoScreen:new {
    id = "trade_item_3_41",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bar Countertop (Curved, Style 2)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_41"},
        {"No, go back", "items_menu_9"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_41)
give_item_3_41 = ConvoScreen:new { id = "give_item_3_41", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_41)

-- Item 42
trade_item_3_42 = ConvoScreen:new {
    id = "trade_item_3_42",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bar Countertop (Straight, Style 1)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_42"},
        {"No, go back", "items_menu_9"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_42)
give_item_3_42 = ConvoScreen:new { id = "give_item_3_42", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_42)

-- Item 43
trade_item_3_43 = ConvoScreen:new {
    id = "trade_item_3_43",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bar Countertop (Straight, Style 2)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_43"},
        {"No, go back", "items_menu_9"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_43)
give_item_3_43 = ConvoScreen:new { id = "give_item_3_43", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_43)

-- Item 44
trade_item_3_44 = ConvoScreen:new {
    id = "trade_item_3_44",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Round Cantina Table Style 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_44"},
        {"No, go back", "items_menu_9"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_44)
give_item_3_44 = ConvoScreen:new { id = "give_item_3_44", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_44)

-- Item 45
trade_item_3_45 = ConvoScreen:new {
    id = "trade_item_3_45",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Round Cantina Table Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_45"},
        {"No, go back", "items_menu_9"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_45)
give_item_3_45 = ConvoScreen:new { id = "give_item_3_45", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_45)

-- Item 46
trade_item_3_46 = ConvoScreen:new {
    id = "trade_item_3_46",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Round Cantina Table Style 3?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_46"},
        {"No, go back", "items_menu_10"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_46)
give_item_3_46 = ConvoScreen:new { id = "give_item_3_46", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_46)

-- Item 47
trade_item_3_47 = ConvoScreen:new {
    id = "trade_item_3_47",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Cantina Sofa?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_47"},
        {"No, go back", "items_menu_10"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_47)
give_item_3_47 = ConvoScreen:new { id = "give_item_3_47", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_47)

-- Item 48
trade_item_3_48 = ConvoScreen:new {
    id = "trade_item_3_48",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Cafe Parasol?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_48"},
        {"No, go back", "items_menu_10"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_48)
give_item_3_48 = ConvoScreen:new { id = "give_item_3_48", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_48)

-- Item 49
trade_item_3_49 = ConvoScreen:new {
    id = "trade_item_3_49",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Medium Oval Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_49"},
        {"No, go back", "items_menu_10"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_49)
give_item_3_49 = ConvoScreen:new { id = "give_item_3_49", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_49)

-- Item 50
trade_item_3_50 = ConvoScreen:new {
    id = "trade_item_3_50",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Small Oval Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_50"},
        {"No, go back", "items_menu_10"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_50)
give_item_3_50 = ConvoScreen:new { id = "give_item_3_50", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_50)

-- Item 51
trade_item_3_51 = ConvoScreen:new {
    id = "trade_item_3_51",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Medium Rectangular Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_51"},
        {"No, go back", "items_menu_11"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_51)
give_item_3_51 = ConvoScreen:new { id = "give_item_3_51", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_51)

-- Item 52
trade_item_3_52 = ConvoScreen:new {
    id = "trade_item_3_52",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Small Rectangular Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_52"},
        {"No, go back", "items_menu_11"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_52)
give_item_3_52 = ConvoScreen:new { id = "give_item_3_52", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_52)

-- Item 53
trade_item_3_53 = ConvoScreen:new {
    id = "trade_item_3_53",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Medium Round Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_53"},
        {"No, go back", "items_menu_11"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_53)
give_item_3_53 = ConvoScreen:new { id = "give_item_3_53", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_53)

-- Item 54
trade_item_3_54 = ConvoScreen:new {
    id = "trade_item_3_54",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Small Round Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_54"},
        {"No, go back", "items_menu_11"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_54)
give_item_3_54 = ConvoScreen:new { id = "give_item_3_54", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_54)

-- Item 55
trade_item_3_55 = ConvoScreen:new {
    id = "trade_item_3_55",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Bith Skull?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_55"},
        {"No, go back", "items_menu_11"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_55)
give_item_3_55 = ConvoScreen:new { id = "give_item_3_55", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_55)

-- Item 56
trade_item_3_56 = ConvoScreen:new {
    id = "trade_item_3_56",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Human Skull?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_56"},
        {"No, go back", "items_menu_12"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_56)
give_item_3_56 = ConvoScreen:new { id = "give_item_3_56", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_56)

-- Item 57
trade_item_3_57 = ConvoScreen:new {
    id = "trade_item_3_57",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Ithorian Skull?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_57"},
        {"No, go back", "items_menu_12"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_57)
give_item_3_57 = ConvoScreen:new { id = "give_item_3_57", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_57)

-- Item 58
trade_item_3_58 = ConvoScreen:new {
    id = "trade_item_3_58",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Thune Skull?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_58"},
        {"No, go back", "items_menu_12"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_58)
give_item_3_58 = ConvoScreen:new { id = "give_item_3_58", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_58)

-- Item 59
trade_item_3_59 = ConvoScreen:new {
    id = "trade_item_3_59",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Voritor Lizard Skull?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_59"},
        {"No, go back", "items_menu_12"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_59)
give_item_3_59 = ConvoScreen:new { id = "give_item_3_59", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_59)

-- Item 60
trade_item_3_60 = ConvoScreen:new {
    id = "trade_item_3_60",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Rebel Endor Helmet?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_60"},
        {"No, go back", "items_menu_12"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_60)
give_item_3_60 = ConvoScreen:new { id = "give_item_3_60", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_60)

-- Item 61
trade_item_3_61 = ConvoScreen:new {
    id = "trade_item_3_61",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Rectangular Rug Style 1?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_61"},
        {"No, go back", "items_menu_13"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_61)
give_item_3_61 = ConvoScreen:new { id = "give_item_3_61", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_61)

-- Item 62
trade_item_3_62 = ConvoScreen:new {
    id = "trade_item_3_62",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Rectangular Rug Style 2?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_62"},
        {"No, go back", "items_menu_13"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_62)
give_item_3_62 = ConvoScreen:new { id = "give_item_3_62", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_62)

-- Item 63
trade_item_3_63 = ConvoScreen:new {
    id = "trade_item_3_63",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Oval Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_63"},
        {"No, go back", "items_menu_13"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_63)
give_item_3_63 = ConvoScreen:new { id = "give_item_3_63", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_63)

-- Item 64
trade_item_3_64 = ConvoScreen:new {
    id = "trade_item_3_64",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Large Round Rug?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_64"},
        {"No, go back", "items_menu_13"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_64)
give_item_3_64 = ConvoScreen:new { id = "give_item_3_64", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_64)

-- Item 65
trade_item_3_65 = ConvoScreen:new {
    id = "trade_item_3_65",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Round Data Terminal?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_65"},
        {"No, go back", "items_menu_13"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_65)
give_item_3_65 = ConvoScreen:new { id = "give_item_3_65", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_65)

-- Item 66
trade_item_3_66 = ConvoScreen:new {
    id = "trade_item_3_66",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Nightsister Melee Armguard?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_66"},
        {"No, go back", "items_menu_14"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_66)
give_item_3_66 = ConvoScreen:new { id = "give_item_3_66", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_66)

-- Item 67
trade_item_3_67 = ConvoScreen:new {
    id = "trade_item_3_67",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Cast Wing in Flight?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_67"},
        {"No, go back", "items_menu_14"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_67)
give_item_3_67 = ConvoScreen:new { id = "give_item_3_67", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_67)

-- Item 68
trade_item_3_68 = ConvoScreen:new {
    id = "trade_item_3_68",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Decimator?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_68"},
        {"No, go back", "items_menu_14"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_68)
give_item_3_68 = ConvoScreen:new { id = "give_item_3_68", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_68)

-- Item 69
trade_item_3_69 = ConvoScreen:new {
    id = "trade_item_3_69",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Tatooine Dune Speeder?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_69"},
        {"No, go back", "items_menu_14"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_69)
give_item_3_69 = ConvoScreen:new { id = "give_item_3_69", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_69)

-- Item 70
trade_item_3_70 = ConvoScreen:new {
    id = "trade_item_3_70",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Weapon of War?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_70"},
        {"No, go back", "items_menu_14"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_70)
give_item_3_70 = ConvoScreen:new { id = "give_item_3_70", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_70)

-- Item 71
trade_item_3_71 = ConvoScreen:new {
    id = "trade_item_3_71",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Fighter Study?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_71"},
        {"No, go back", "items_menu_15"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_71)
give_item_3_71 = ConvoScreen:new { id = "give_item_3_71", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_71)

-- Item 72
trade_item_3_72 = ConvoScreen:new {
    id = "trade_item_3_72",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Hutt Greed?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_72"},
        {"No, go back", "items_menu_15"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_72)
give_item_3_72 = ConvoScreen:new { id = "give_item_3_72", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_72)

-- Item 73
trade_item_3_73 = ConvoScreen:new {
    id = "trade_item_3_73",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Smuggler's Run?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_73"},
        {"No, go back", "items_menu_15"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_73)
give_item_3_73 = ConvoScreen:new { id = "give_item_3_73", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_73)

-- Item 74
trade_item_3_74 = ConvoScreen:new {
    id = "trade_item_3_74",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Imperial Oppression?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_74"},
        {"No, go back", "items_menu_15"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_74)
give_item_3_74 = ConvoScreen:new { id = "give_item_3_74", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_74)

-- Item 75
trade_item_3_75 = ConvoScreen:new {
    id = "trade_item_3_75",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Painting: Emperor's Eyes?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_75"},
        {"No, go back", "items_menu_15"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_75)
give_item_3_75 = ConvoScreen:new { id = "give_item_3_75", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_75)

-- Item 76
trade_item_3_76 = ConvoScreen:new {
    id = "trade_item_3_76",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the SoroSuub Luxury Yacht Deed?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_76"},
        {"No, go back", "items_menu_16"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_76)
give_item_3_76 = ConvoScreen:new { id = "give_item_3_76", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_76)

-- PAGE 17: Items 77-81
items_menu_17 = ConvoScreen:new {
    id = "items_menu_17",
    leftDialog = "",
    customDialogText = "Choose an item (75 Bellum Gero Tokens each):\n\nFine Woven Rugs:",
    stopConversation = "false",
    options = {
        {"Item 77 - [Fine Woven Rug (Style 1)]", "trade_item_3_77"},
        {"Item 78 - [Fine Woven Rug (Style 2)]", "trade_item_3_78"},
        {"Item 79 - [Fine Woven Rug (Style 3)]", "trade_item_3_79"},
        {"Item 80 - [Fine Woven Rug (Style 4)]", "trade_item_3_80"},
        {"Item 81 - [Fine Woven Rug (Style 5)]", "trade_item_3_81"},
        {"Previous", "items_menu_16"},
        {"Back", "first_screen"},
    }
}
bg_token_vendor_3_conv:addScreen(items_menu_17)

-- Item 77
trade_item_3_77 = ConvoScreen:new {
    id = "trade_item_3_77",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Fine Woven Rug (Style 1)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_77"},
        {"No, go back", "items_menu_17"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_77)
give_item_3_77 = ConvoScreen:new { id = "give_item_3_77", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_77)

-- Item 78
trade_item_3_78 = ConvoScreen:new {
    id = "trade_item_3_78",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Fine Woven Rug (Style 2)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_78"},
        {"No, go back", "items_menu_17"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_78)
give_item_3_78 = ConvoScreen:new { id = "give_item_3_78", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_78)

-- Item 79
trade_item_3_79 = ConvoScreen:new {
    id = "trade_item_3_79",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Fine Woven Rug (Style 3)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_79"},
        {"No, go back", "items_menu_17"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_79)
give_item_3_79 = ConvoScreen:new { id = "give_item_3_79", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_79)

-- Item 80
trade_item_3_80 = ConvoScreen:new {
    id = "trade_item_3_80",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Fine Woven Rug (Style 4)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_80"},
        {"No, go back", "items_menu_17"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_80)
give_item_3_80 = ConvoScreen:new { id = "give_item_3_80", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_80)

-- Item 81
trade_item_3_81 = ConvoScreen:new {
    id = "trade_item_3_81",
    leftDialog = "",
    customDialogText = "Confirm: Trade 75 Bellum Gero Tokens for the Fine Woven Rug (Style 5)?",
    stopConversation = "false",
    options = {
        {"Yes, make the trade", "give_item_3_81"},
        {"No, go back", "items_menu_17"}
    }
}
bg_token_vendor_3_conv:addScreen(trade_item_3_81)
give_item_3_81 = ConvoScreen:new { id = "give_item_3_81", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = { } }
bg_token_vendor_3_conv:addScreen(give_item_3_81)

-- BYE SCREEN
bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "Thank you for visiting the Bellum Gero Veteran Rewards Exchange!",
    stopConversation = "true",
    options = { }
}
bg_token_vendor_3_conv:addScreen(bye)

addConversationTemplate("bg_token_vendor_3_conv", bg_token_vendor_3_conv)

print("[BG-TOKEN-VENDOR-3] Conversation template loaded successfully")
