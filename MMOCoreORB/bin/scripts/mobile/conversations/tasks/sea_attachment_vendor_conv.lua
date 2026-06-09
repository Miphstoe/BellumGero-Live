sea_attachment_vendor_conv = ConvoTemplate:new {
    initialScreen = "sav_first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

sav_first_screen = ConvoScreen:new {
    id = "sav_first_screen",
    leftDialog = "",
    customDialogText = "Bring me 75 of your unwanted Clothing or Armor Attachments and I'll trade them for rare veteran reward items! I accept attachments from your inventory and backpacks.",
    stopConversation = "false",
    options = {
        {"Browse available items", "sav_menu_1"},
        {"I'm ready to trade", "sav_menu_1"},
        {"Goodbye", "sav_bye"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_first_screen)

-- ===== PAGE MENUS (5 items per page, 15 pages) =====

sav_menu_1 = ConvoScreen:new {
    id = "sav_menu_1",
    leftDialog = "",
    customDialogText = "Veteran Rewards (75 Clothing/Armor Attachments each):\n\nData Terminals & Droid Toys:",
    stopConversation = "false",
    options = {
        {"Data Terminal (Style 1)", "sav_tc_02"},
        {"Data Terminal (Style 2)", "sav_tc_03"},
        {"Data Terminal (Style 3)", "sav_tc_04"},
        {"Data Terminal (Style 4)", "sav_tc_05"},
        {"Protocol Droid Toy", "sav_tc_06"},
        {"More items...", "sav_menu_2"},
        {"Back", "sav_first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_1)

sav_menu_2 = ConvoScreen:new {
    id = "sav_menu_2",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nShip Toys & Furniture:",
    stopConversation = "false",
    options = {
        {"R2 Unit Toy", "sav_tc_07"},
        {"Falcon Couch Corner", "sav_tc_09"},
        {"Falcon Couch Section", "sav_tc_10"},
        {"TIE Fighter Toy", "sav_tc_11"},
        {"X-Wing Toy", "sav_tc_12"},
        {"More items...", "sav_menu_3"},
        {"Previous", "sav_menu_1"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_2)

sav_menu_3 = ConvoScreen:new {
    id = "sav_menu_3",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nSE Goggles (Part 1):",
    stopConversation = "false",
    options = {
        {"SE Goggles (Style 1)", "sav_tc_15"},
        {"SE Goggles (Style 2)", "sav_tc_16"},
        {"SE Goggles (Style 3)", "sav_tc_17"},
        {"SE Goggles (Style 4)", "sav_tc_18"},
        {"SE Goggles (Style 5)", "sav_tc_19"},
        {"More items...", "sav_menu_4"},
        {"Previous", "sav_menu_2"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_3)

sav_menu_4 = ConvoScreen:new {
    id = "sav_menu_4",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nGoggles & Tech Consoles:",
    stopConversation = "false",
    options = {
        {"SE Goggles (Style 6)", "sav_tc_20"},
        {"Darth Vader Toy", "sav_tc_21"},
        {"Tech Console Sectional A", "sav_tc_22"},
        {"Tech Console Sectional B", "sav_tc_23"},
        {"Tech Console Sectional C", "sav_tc_24"},
        {"More items...", "sav_menu_5"},
        {"Previous", "sav_menu_3"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_4)

sav_menu_5 = ConvoScreen:new {
    id = "sav_menu_5",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nToys & Camp Items:",
    stopConversation = "false",
    options = {
        {"Tech Console Sectional D", "sav_tc_25"},
        {"Jabba Toy", "sav_tc_26"},
        {"Stormtrooper Toy", "sav_tc_27"},
        {"Camp Center (Small)", "sav_tc_28"},
        {"Camp Center (Large)", "sav_tc_29"},
        {"More items...", "sav_menu_6"},
        {"Previous", "sav_menu_4"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_5)

sav_menu_6 = ConvoScreen:new {
    id = "sav_menu_6",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nDecorative Furniture:",
    stopConversation = "false",
    options = {
        {"Gold Ornamental Vase (Style 1)", "sav_tc_30"},
        {"Gold Ornamental Vase (Style 2)", "sav_tc_31"},
        {"Foodcart", "sav_tc_32"},
        {"Park Bench", "sav_tc_33"},
        {"Professor Desk", "sav_tc_34"},
        {"More items...", "sav_menu_7"},
        {"Previous", "sav_menu_5"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_6)

sav_menu_7 = ConvoScreen:new {
    id = "sav_menu_7",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nMore Furniture:",
    stopConversation = "false",
    options = {
        {"Diagnostic Screen", "sav_tc_35"},
        {"Large Potted Plant (Style 2)", "sav_tc_36"},
        {"Large Potted Plant (Style 3)", "sav_tc_37"},
        {"Large Potted Plant (Style 4)", "sav_tc_38"},
        {"Bar Countertop", "sav_tc_39"},
        {"More items...", "sav_menu_8"},
        {"Previous", "sav_menu_6"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_7)

sav_menu_8 = ConvoScreen:new {
    id = "sav_menu_8",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nBar & Cantina Furniture:",
    stopConversation = "false",
    options = {
        {"Bar Countertop (Curved, Style 1)", "sav_tc_40"},
        {"Bar Countertop (Curved, Style 2)", "sav_tc_41"},
        {"Bar Countertop (Straight, Style 1)", "sav_tc_42"},
        {"Bar Countertop (Straight, Style 2)", "sav_tc_43"},
        {"Round Cantina Table (Style 1)", "sav_tc_44"},
        {"More items...", "sav_menu_9"},
        {"Previous", "sav_menu_7"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_8)

sav_menu_9 = ConvoScreen:new {
    id = "sav_menu_9",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nMore Cantina & Rugs:",
    stopConversation = "false",
    options = {
        {"Round Cantina Table (Style 2)", "sav_tc_45"},
        {"Round Cantina Table (Style 3)", "sav_tc_46"},
        {"Large Cantina Sofa", "sav_tc_47"},
        {"Cafe Parasol", "sav_tc_48"},
        {"Medium Oval Rug", "sav_tc_49"},
        {"More items...", "sav_menu_10"},
        {"Previous", "sav_menu_8"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_9)

sav_menu_10 = ConvoScreen:new {
    id = "sav_menu_10",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nSmall & Medium Rugs:",
    stopConversation = "false",
    options = {
        {"Small Oval Rug", "sav_tc_50"},
        {"Medium Rectangular Rug", "sav_tc_51"},
        {"Small Rectangular Rug", "sav_tc_52"},
        {"Medium Round Rug", "sav_tc_53"},
        {"Small Round Rug", "sav_tc_54"},
        {"More items...", "sav_menu_11"},
        {"Previous", "sav_menu_9"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_10)

sav_menu_11 = ConvoScreen:new {
    id = "sav_menu_11",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nSkulls & Trophies:",
    stopConversation = "false",
    options = {
        {"Bith Skull", "sav_tc_55"},
        {"Human Skull", "sav_tc_56"},
        {"Ithorian Skull", "sav_tc_57"},
        {"Thune Skull", "sav_tc_58"},
        {"Voritor Lizard Skull", "sav_tc_59"},
        {"More items...", "sav_menu_12"},
        {"Previous", "sav_menu_10"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_11)

sav_menu_12 = ConvoScreen:new {
    id = "sav_menu_12",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nHelmet & Large Rugs:",
    stopConversation = "false",
    options = {
        {"Rebel Endor Helmet", "sav_tc_60"},
        {"Large Rectangular Rug (Style 1)", "sav_tc_61"},
        {"Large Rectangular Rug (Style 2)", "sav_tc_62"},
        {"Large Oval Rug", "sav_tc_63"},
        {"Large Round Rug", "sav_tc_64"},
        {"More items...", "sav_menu_13"},
        {"Previous", "sav_menu_11"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_12)

sav_menu_13 = ConvoScreen:new {
    id = "sav_menu_13",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nTerminals, Armor & Paintings:",
    stopConversation = "false",
    options = {
        {"Round Data Terminal", "sav_tc_65"},
        {"Nightsister Melee Armguard", "sav_tc_66"},
        {"Painting: Cast Wing in Flight", "sav_tc_67"},
        {"Painting: Decimator", "sav_tc_68"},
        {"Painting: Tatooine Dune Speeder", "sav_tc_69"},
        {"More items...", "sav_menu_14"},
        {"Previous", "sav_menu_12"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_13)

sav_menu_14 = ConvoScreen:new {
    id = "sav_menu_14",
    leftDialog = "",
    customDialogText = "Veteran Rewards (continued):\n\nMore Paintings:",
    stopConversation = "false",
    options = {
        {"Painting: Weapon of War", "sav_tc_70"},
        {"Painting: Fighter Study", "sav_tc_71"},
        {"Painting: Hutt Greed", "sav_tc_72"},
        {"Painting: Smuggler's Run", "sav_tc_73"},
        {"Painting: Imperial Oppression", "sav_tc_74"},
        {"More items...", "sav_menu_15"},
        {"Previous", "sav_menu_13"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_14)

sav_menu_15 = ConvoScreen:new {
    id = "sav_menu_15",
    leftDialog = "",
    customDialogText = "Veteran Rewards (final page):",
    stopConversation = "false",
    options = {
        {"Painting: Emperor's Eyes", "sav_tc_75"},
        --{"Fish Tank", "sav_tc_76"}, -- TRE pending fix
        {"Previous", "sav_menu_14"},
        {"Back", "sav_first_screen"},
    }
}
sea_attachment_vendor_conv:addScreen(sav_menu_15)

-- ===== CONFIRMATION SCREENS =====
-- Each links "Yes" to give_t3_XX (handler key) and "No" back to its menu page

sav_tc_02 = ConvoScreen:new { id="sav_tc_02", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Data Terminal (Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_02"},{"No, go back","sav_menu_1"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_02)

sav_tc_03 = ConvoScreen:new { id="sav_tc_03", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Data Terminal (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_03"},{"No, go back","sav_menu_1"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_03)

sav_tc_04 = ConvoScreen:new { id="sav_tc_04", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Data Terminal (Style 3)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_04"},{"No, go back","sav_menu_1"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_04)

sav_tc_05 = ConvoScreen:new { id="sav_tc_05", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Data Terminal (Style 4)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_05"},{"No, go back","sav_menu_1"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_05)

sav_tc_06 = ConvoScreen:new { id="sav_tc_06", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Protocol Droid Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_06"},{"No, go back","sav_menu_1"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_06)

sav_tc_07 = ConvoScreen:new { id="sav_tc_07", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for R2 Unit Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_07"},{"No, go back","sav_menu_2"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_07)

sav_tc_09 = ConvoScreen:new { id="sav_tc_09", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Falcon Couch Corner?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_09"},{"No, go back","sav_menu_2"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_09)

sav_tc_10 = ConvoScreen:new { id="sav_tc_10", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Falcon Couch Section?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_10"},{"No, go back","sav_menu_2"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_10)

sav_tc_11 = ConvoScreen:new { id="sav_tc_11", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for TIE Fighter Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_11"},{"No, go back","sav_menu_2"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_11)

sav_tc_12 = ConvoScreen:new { id="sav_tc_12", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for X-Wing Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_12"},{"No, go back","sav_menu_2"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_12)

sav_tc_15 = ConvoScreen:new { id="sav_tc_15", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_15"},{"No, go back","sav_menu_3"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_15)

sav_tc_16 = ConvoScreen:new { id="sav_tc_16", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_16"},{"No, go back","sav_menu_3"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_16)

sav_tc_17 = ConvoScreen:new { id="sav_tc_17", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 3)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_17"},{"No, go back","sav_menu_3"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_17)

sav_tc_18 = ConvoScreen:new { id="sav_tc_18", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 4)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_18"},{"No, go back","sav_menu_3"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_18)

sav_tc_19 = ConvoScreen:new { id="sav_tc_19", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 5)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_19"},{"No, go back","sav_menu_3"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_19)

sav_tc_20 = ConvoScreen:new { id="sav_tc_20", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for SE Goggles (Style 6)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_20"},{"No, go back","sav_menu_4"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_20)

sav_tc_21 = ConvoScreen:new { id="sav_tc_21", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Darth Vader Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_21"},{"No, go back","sav_menu_4"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_21)

sav_tc_22 = ConvoScreen:new { id="sav_tc_22", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Tech Console Sectional A?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_22"},{"No, go back","sav_menu_4"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_22)

sav_tc_23 = ConvoScreen:new { id="sav_tc_23", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Tech Console Sectional B?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_23"},{"No, go back","sav_menu_4"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_23)

sav_tc_24 = ConvoScreen:new { id="sav_tc_24", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Tech Console Sectional C?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_24"},{"No, go back","sav_menu_4"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_24)

sav_tc_25 = ConvoScreen:new { id="sav_tc_25", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Tech Console Sectional D?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_25"},{"No, go back","sav_menu_5"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_25)

sav_tc_26 = ConvoScreen:new { id="sav_tc_26", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Jabba Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_26"},{"No, go back","sav_menu_5"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_26)

sav_tc_27 = ConvoScreen:new { id="sav_tc_27", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Stormtrooper Toy?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_27"},{"No, go back","sav_menu_5"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_27)

sav_tc_28 = ConvoScreen:new { id="sav_tc_28", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Camp Center (Small)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_28"},{"No, go back","sav_menu_5"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_28)

sav_tc_29 = ConvoScreen:new { id="sav_tc_29", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Camp Center (Large)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_29"},{"No, go back","sav_menu_5"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_29)

sav_tc_30 = ConvoScreen:new { id="sav_tc_30", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Gold Ornamental Vase (Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_30"},{"No, go back","sav_menu_6"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_30)

sav_tc_31 = ConvoScreen:new { id="sav_tc_31", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Gold Ornamental Vase (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_31"},{"No, go back","sav_menu_6"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_31)

sav_tc_32 = ConvoScreen:new { id="sav_tc_32", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Foodcart?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_32"},{"No, go back","sav_menu_6"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_32)

sav_tc_33 = ConvoScreen:new { id="sav_tc_33", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Park Bench?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_33"},{"No, go back","sav_menu_6"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_33)

sav_tc_34 = ConvoScreen:new { id="sav_tc_34", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Professor Desk?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_34"},{"No, go back","sav_menu_6"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_34)

sav_tc_35 = ConvoScreen:new { id="sav_tc_35", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Diagnostic Screen?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_35"},{"No, go back","sav_menu_7"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_35)

sav_tc_36 = ConvoScreen:new { id="sav_tc_36", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Potted Plant (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_36"},{"No, go back","sav_menu_7"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_36)

sav_tc_37 = ConvoScreen:new { id="sav_tc_37", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Potted Plant (Style 3)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_37"},{"No, go back","sav_menu_7"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_37)

sav_tc_38 = ConvoScreen:new { id="sav_tc_38", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Potted Plant (Style 4)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_38"},{"No, go back","sav_menu_7"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_38)

sav_tc_39 = ConvoScreen:new { id="sav_tc_39", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bar Countertop?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_39"},{"No, go back","sav_menu_7"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_39)

sav_tc_40 = ConvoScreen:new { id="sav_tc_40", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bar Countertop (Curved, Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_40"},{"No, go back","sav_menu_8"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_40)

sav_tc_41 = ConvoScreen:new { id="sav_tc_41", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bar Countertop (Curved, Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_41"},{"No, go back","sav_menu_8"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_41)

sav_tc_42 = ConvoScreen:new { id="sav_tc_42", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bar Countertop (Straight, Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_42"},{"No, go back","sav_menu_8"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_42)

sav_tc_43 = ConvoScreen:new { id="sav_tc_43", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bar Countertop (Straight, Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_43"},{"No, go back","sav_menu_8"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_43)

sav_tc_44 = ConvoScreen:new { id="sav_tc_44", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Round Cantina Table (Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_44"},{"No, go back","sav_menu_8"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_44)

sav_tc_45 = ConvoScreen:new { id="sav_tc_45", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Round Cantina Table (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_45"},{"No, go back","sav_menu_9"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_45)

sav_tc_46 = ConvoScreen:new { id="sav_tc_46", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Round Cantina Table (Style 3)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_46"},{"No, go back","sav_menu_9"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_46)

sav_tc_47 = ConvoScreen:new { id="sav_tc_47", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Cantina Sofa?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_47"},{"No, go back","sav_menu_9"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_47)

sav_tc_48 = ConvoScreen:new { id="sav_tc_48", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Cafe Parasol?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_48"},{"No, go back","sav_menu_9"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_48)

sav_tc_49 = ConvoScreen:new { id="sav_tc_49", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Medium Oval Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_49"},{"No, go back","sav_menu_9"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_49)

sav_tc_50 = ConvoScreen:new { id="sav_tc_50", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Small Oval Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_50"},{"No, go back","sav_menu_10"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_50)

sav_tc_51 = ConvoScreen:new { id="sav_tc_51", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Medium Rectangular Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_51"},{"No, go back","sav_menu_10"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_51)

sav_tc_52 = ConvoScreen:new { id="sav_tc_52", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Small Rectangular Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_52"},{"No, go back","sav_menu_10"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_52)

sav_tc_53 = ConvoScreen:new { id="sav_tc_53", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Medium Round Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_53"},{"No, go back","sav_menu_10"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_53)

sav_tc_54 = ConvoScreen:new { id="sav_tc_54", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Small Round Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_54"},{"No, go back","sav_menu_10"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_54)

sav_tc_55 = ConvoScreen:new { id="sav_tc_55", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Bith Skull?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_55"},{"No, go back","sav_menu_11"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_55)

sav_tc_56 = ConvoScreen:new { id="sav_tc_56", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Human Skull?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_56"},{"No, go back","sav_menu_11"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_56)

sav_tc_57 = ConvoScreen:new { id="sav_tc_57", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Ithorian Skull?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_57"},{"No, go back","sav_menu_11"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_57)

sav_tc_58 = ConvoScreen:new { id="sav_tc_58", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Thune Skull?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_58"},{"No, go back","sav_menu_11"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_58)

sav_tc_59 = ConvoScreen:new { id="sav_tc_59", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Voritor Lizard Skull?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_59"},{"No, go back","sav_menu_11"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_59)

sav_tc_60 = ConvoScreen:new { id="sav_tc_60", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Rebel Endor Helmet?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_60"},{"No, go back","sav_menu_12"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_60)

sav_tc_61 = ConvoScreen:new { id="sav_tc_61", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Rectangular Rug (Style 1)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_61"},{"No, go back","sav_menu_12"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_61)

sav_tc_62 = ConvoScreen:new { id="sav_tc_62", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Rectangular Rug (Style 2)?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_62"},{"No, go back","sav_menu_12"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_62)

sav_tc_63 = ConvoScreen:new { id="sav_tc_63", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Oval Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_63"},{"No, go back","sav_menu_12"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_63)

sav_tc_64 = ConvoScreen:new { id="sav_tc_64", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Large Round Rug?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_64"},{"No, go back","sav_menu_12"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_64)

sav_tc_65 = ConvoScreen:new { id="sav_tc_65", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Round Data Terminal?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_65"},{"No, go back","sav_menu_13"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_65)

sav_tc_66 = ConvoScreen:new { id="sav_tc_66", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Nightsister Melee Armguard?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_66"},{"No, go back","sav_menu_13"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_66)

sav_tc_67 = ConvoScreen:new { id="sav_tc_67", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Cast Wing in Flight?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_67"},{"No, go back","sav_menu_13"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_67)

sav_tc_68 = ConvoScreen:new { id="sav_tc_68", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Decimator?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_68"},{"No, go back","sav_menu_13"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_68)

sav_tc_69 = ConvoScreen:new { id="sav_tc_69", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Tatooine Dune Speeder?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_69"},{"No, go back","sav_menu_13"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_69)

sav_tc_70 = ConvoScreen:new { id="sav_tc_70", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Weapon of War?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_70"},{"No, go back","sav_menu_14"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_70)

sav_tc_71 = ConvoScreen:new { id="sav_tc_71", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Fighter Study?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_71"},{"No, go back","sav_menu_14"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_71)

sav_tc_72 = ConvoScreen:new { id="sav_tc_72", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Hutt Greed?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_72"},{"No, go back","sav_menu_14"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_72)

sav_tc_73 = ConvoScreen:new { id="sav_tc_73", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Smuggler's Run?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_73"},{"No, go back","sav_menu_14"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_73)

sav_tc_74 = ConvoScreen:new { id="sav_tc_74", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Imperial Oppression?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_74"},{"No, go back","sav_menu_14"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_74)

sav_tc_75 = ConvoScreen:new { id="sav_tc_75", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Painting: Emperor's Eyes?", stopConversation="false",
    options={{"Yes, make the trade","give_t3_75"},{"No, go back","sav_menu_15"}} }
sea_attachment_vendor_conv:addScreen(sav_tc_75)

--sav_tc_76 = ConvoScreen:new { id="sav_tc_76", leftDialog="", customDialogText="Confirm: Trade 75 Attachments for Fish Tank?", stopConversation="false",
--    options={{"Yes, make the trade","give_t3_76"},{"No, go back","sav_menu_15"}} }
--sea_attachment_vendor_conv:addScreen(sav_tc_76)

-- ===== GIVE (PROCESSING) SCREENS =====
-- These are caught by conv_handler:handleAttachmentTrade via "give_t3_" prefix

sav_give_02 = ConvoScreen:new { id="give_t3_02", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_02)
sav_give_03 = ConvoScreen:new { id="give_t3_03", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_03)
sav_give_04 = ConvoScreen:new { id="give_t3_04", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_04)
sav_give_05 = ConvoScreen:new { id="give_t3_05", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_05)
sav_give_06 = ConvoScreen:new { id="give_t3_06", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_06)
sav_give_07 = ConvoScreen:new { id="give_t3_07", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_07)
sav_give_09 = ConvoScreen:new { id="give_t3_09", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_09)
sav_give_10 = ConvoScreen:new { id="give_t3_10", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_10)
sav_give_11 = ConvoScreen:new { id="give_t3_11", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_11)
sav_give_12 = ConvoScreen:new { id="give_t3_12", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_12)
sav_give_15 = ConvoScreen:new { id="give_t3_15", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_15)
sav_give_16 = ConvoScreen:new { id="give_t3_16", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_16)
sav_give_17 = ConvoScreen:new { id="give_t3_17", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_17)
sav_give_18 = ConvoScreen:new { id="give_t3_18", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_18)
sav_give_19 = ConvoScreen:new { id="give_t3_19", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_19)
sav_give_20 = ConvoScreen:new { id="give_t3_20", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_20)
sav_give_21 = ConvoScreen:new { id="give_t3_21", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_21)
sav_give_22 = ConvoScreen:new { id="give_t3_22", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_22)
sav_give_23 = ConvoScreen:new { id="give_t3_23", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_23)
sav_give_24 = ConvoScreen:new { id="give_t3_24", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_24)
sav_give_25 = ConvoScreen:new { id="give_t3_25", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_25)
sav_give_26 = ConvoScreen:new { id="give_t3_26", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_26)
sav_give_27 = ConvoScreen:new { id="give_t3_27", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_27)
sav_give_28 = ConvoScreen:new { id="give_t3_28", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_28)
sav_give_29 = ConvoScreen:new { id="give_t3_29", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_29)
sav_give_30 = ConvoScreen:new { id="give_t3_30", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_30)
sav_give_31 = ConvoScreen:new { id="give_t3_31", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_31)
sav_give_32 = ConvoScreen:new { id="give_t3_32", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_32)
sav_give_33 = ConvoScreen:new { id="give_t3_33", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_33)
sav_give_34 = ConvoScreen:new { id="give_t3_34", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_34)
sav_give_35 = ConvoScreen:new { id="give_t3_35", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_35)
sav_give_36 = ConvoScreen:new { id="give_t3_36", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_36)
sav_give_37 = ConvoScreen:new { id="give_t3_37", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_37)
sav_give_38 = ConvoScreen:new { id="give_t3_38", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_38)
sav_give_39 = ConvoScreen:new { id="give_t3_39", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_39)
sav_give_40 = ConvoScreen:new { id="give_t3_40", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_40)
sav_give_41 = ConvoScreen:new { id="give_t3_41", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_41)
sav_give_42 = ConvoScreen:new { id="give_t3_42", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_42)
sav_give_43 = ConvoScreen:new { id="give_t3_43", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_43)
sav_give_44 = ConvoScreen:new { id="give_t3_44", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_44)
sav_give_45 = ConvoScreen:new { id="give_t3_45", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_45)
sav_give_46 = ConvoScreen:new { id="give_t3_46", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_46)
sav_give_47 = ConvoScreen:new { id="give_t3_47", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_47)
sav_give_48 = ConvoScreen:new { id="give_t3_48", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_48)
sav_give_49 = ConvoScreen:new { id="give_t3_49", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_49)
sav_give_50 = ConvoScreen:new { id="give_t3_50", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_50)
sav_give_51 = ConvoScreen:new { id="give_t3_51", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_51)
sav_give_52 = ConvoScreen:new { id="give_t3_52", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_52)
sav_give_53 = ConvoScreen:new { id="give_t3_53", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_53)
sav_give_54 = ConvoScreen:new { id="give_t3_54", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_54)
sav_give_55 = ConvoScreen:new { id="give_t3_55", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_55)
sav_give_56 = ConvoScreen:new { id="give_t3_56", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_56)
sav_give_57 = ConvoScreen:new { id="give_t3_57", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_57)
sav_give_58 = ConvoScreen:new { id="give_t3_58", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_58)
sav_give_59 = ConvoScreen:new { id="give_t3_59", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_59)
sav_give_60 = ConvoScreen:new { id="give_t3_60", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_60)
sav_give_61 = ConvoScreen:new { id="give_t3_61", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_61)
sav_give_62 = ConvoScreen:new { id="give_t3_62", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_62)
sav_give_63 = ConvoScreen:new { id="give_t3_63", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_63)
sav_give_64 = ConvoScreen:new { id="give_t3_64", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_64)
sav_give_65 = ConvoScreen:new { id="give_t3_65", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_65)
sav_give_66 = ConvoScreen:new { id="give_t3_66", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_66)
sav_give_67 = ConvoScreen:new { id="give_t3_67", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_67)
sav_give_68 = ConvoScreen:new { id="give_t3_68", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_68)
sav_give_69 = ConvoScreen:new { id="give_t3_69", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_69)
sav_give_70 = ConvoScreen:new { id="give_t3_70", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_70)
sav_give_71 = ConvoScreen:new { id="give_t3_71", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_71)
sav_give_72 = ConvoScreen:new { id="give_t3_72", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_72)
sav_give_73 = ConvoScreen:new { id="give_t3_73", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_73)
sav_give_74 = ConvoScreen:new { id="give_t3_74", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_74)
sav_give_75 = ConvoScreen:new { id="give_t3_75", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
sea_attachment_vendor_conv:addScreen(sav_give_75)
--sav_give_76 = ConvoScreen:new { id="give_t3_76", leftDialog="", customDialogText="Processing trade...", stopConversation="true", options={} }
--sea_attachment_vendor_conv:addScreen(sav_give_76)

sav_bye = ConvoScreen:new {
    id = "sav_bye",
    leftDialog = "",
    customDialogText = "Come back when you have 75 attachments to trade!",
    stopConversation = "true",
    options = {}
}
sea_attachment_vendor_conv:addScreen(sav_bye)

addConversationTemplate("sea_attachment_vendor_conv", sea_attachment_vendor_conv)
