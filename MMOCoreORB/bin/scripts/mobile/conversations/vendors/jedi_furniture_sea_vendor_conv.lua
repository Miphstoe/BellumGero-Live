jedi_furniture_sea_vendor_conv = ConvoTemplate:new {
	initialScreen = "jfs_first_screen",
	templateType = "Lua",
	luaClassHandler = "conv_handler",
	screens = {}
}

jfs_first_screen = ConvoScreen:new {
	id = "jfs_first_screen",
	leftDialog = "",
	customDialogText = "I trade Jedi furniture for Skill Enhancement Attachments. Each item costs 50 eligible attachments. I accept Clothing Attachments and Armor Attachments from your inventory and backpacks; mixed Clothing and Armor Attachments are accepted.",
	stopConversation = "false",
	options = {
		{"Browse Jedi furniture", "jfs_menu_1"},
		{"Goodbye", "jfs_bye"},
	}
}
jedi_furniture_sea_vendor_conv:addScreen(jfs_first_screen)

jfs_menu_1 = ConvoScreen:new {
	id = "jfs_menu_1",
	leftDialog = "",
	customDialogText = "Jedi Furniture - 50 Clothing or Armor Attachments each:",
	stopConversation = "false",
	options = {
		{"Dark Banner", "jfs_confirm_01"},
		{"Light Banner", "jfs_confirm_02"},
		{"Dark Chair (Style 1)", "jfs_confirm_03"},
		{"Dark Chair (Style 2)", "jfs_confirm_04"},
		{"Dark Throne", "jfs_confirm_05"},
		{"More items...", "jfs_menu_2"},
		{"Back", "jfs_first_screen"},
	}
}
jedi_furniture_sea_vendor_conv:addScreen(jfs_menu_1)

jfs_menu_2 = ConvoScreen:new {
	id = "jfs_menu_2",
	leftDialog = "",
	customDialogText = "Jedi Furniture - 50 Clothing or Armor Attachments each:",
	stopConversation = "false",
	options = {
		{"Light Chair (Style 1)", "jfs_confirm_06"},
		{"Light Chair (Style 2)", "jfs_confirm_07"},
		{"Light Throne", "jfs_confirm_08"},
		{"Dark Table (Style 1)", "jfs_confirm_09"},
		{"Dark Table (Style 2)", "jfs_confirm_10"},
		{"More items...", "jfs_menu_3"},
		{"Previous", "jfs_menu_1"},
	}
}
jedi_furniture_sea_vendor_conv:addScreen(jfs_menu_2)

jfs_menu_3 = ConvoScreen:new {
	id = "jfs_menu_3",
	leftDialog = "",
	customDialogText = "Jedi Furniture - 50 Clothing or Armor Attachments each:",
	stopConversation = "false",
	options = {
		{"Light Table (Style 1)", "jfs_confirm_11"},
		{"Light Table (Style 2)", "jfs_confirm_12"},
		{"Jedi Council Seat", "jfs_confirm_13"},
		{"Previous", "jfs_menu_2"},
		{"Back", "jfs_first_screen"},
	}
}
jedi_furniture_sea_vendor_conv:addScreen(jfs_menu_3)

jfs_confirm_01 = ConvoScreen:new { id = "jfs_confirm_01", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Banner?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_01"}, {"No, go back", "jfs_menu_1"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_01)
jfs_confirm_02 = ConvoScreen:new { id = "jfs_confirm_02", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Banner?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_02"}, {"No, go back", "jfs_menu_1"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_02)
jfs_confirm_03 = ConvoScreen:new { id = "jfs_confirm_03", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Chair (Style 1)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_03"}, {"No, go back", "jfs_menu_1"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_03)
jfs_confirm_04 = ConvoScreen:new { id = "jfs_confirm_04", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Chair (Style 2)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_04"}, {"No, go back", "jfs_menu_1"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_04)
jfs_confirm_05 = ConvoScreen:new { id = "jfs_confirm_05", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Throne?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_05"}, {"No, go back", "jfs_menu_1"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_05)
jfs_confirm_06 = ConvoScreen:new { id = "jfs_confirm_06", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Chair (Style 1)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_06"}, {"No, go back", "jfs_menu_2"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_06)
jfs_confirm_07 = ConvoScreen:new { id = "jfs_confirm_07", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Chair (Style 2)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_07"}, {"No, go back", "jfs_menu_2"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_07)
jfs_confirm_08 = ConvoScreen:new { id = "jfs_confirm_08", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Throne?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_08"}, {"No, go back", "jfs_menu_2"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_08)
jfs_confirm_09 = ConvoScreen:new { id = "jfs_confirm_09", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Table (Style 1)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_09"}, {"No, go back", "jfs_menu_2"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_09)
jfs_confirm_10 = ConvoScreen:new { id = "jfs_confirm_10", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Dark Table (Style 2)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_10"}, {"No, go back", "jfs_menu_2"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_10)
jfs_confirm_11 = ConvoScreen:new { id = "jfs_confirm_11", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Table (Style 1)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_11"}, {"No, go back", "jfs_menu_3"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_11)
jfs_confirm_12 = ConvoScreen:new { id = "jfs_confirm_12", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Light Table (Style 2)?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_12"}, {"No, go back", "jfs_menu_3"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_12)
jfs_confirm_13 = ConvoScreen:new { id = "jfs_confirm_13", leftDialog = "", customDialogText = "Confirm: Trade 50 Clothing or Armor Attachments for Jedi Council Seat?", stopConversation = "false", options = {{"Yes, make the trade", "give_t2_13"}, {"No, go back", "jfs_menu_3"}} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_confirm_13)

jfs_give_01 = ConvoScreen:new { id = "give_t2_01", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_01)
jfs_give_02 = ConvoScreen:new { id = "give_t2_02", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_02)
jfs_give_03 = ConvoScreen:new { id = "give_t2_03", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_03)
jfs_give_04 = ConvoScreen:new { id = "give_t2_04", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_04)
jfs_give_05 = ConvoScreen:new { id = "give_t2_05", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_05)
jfs_give_06 = ConvoScreen:new { id = "give_t2_06", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_06)
jfs_give_07 = ConvoScreen:new { id = "give_t2_07", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_07)
jfs_give_08 = ConvoScreen:new { id = "give_t2_08", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_08)
jfs_give_09 = ConvoScreen:new { id = "give_t2_09", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_09)
jfs_give_10 = ConvoScreen:new { id = "give_t2_10", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_10)
jfs_give_11 = ConvoScreen:new { id = "give_t2_11", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_11)
jfs_give_12 = ConvoScreen:new { id = "give_t2_12", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_12)
jfs_give_13 = ConvoScreen:new { id = "give_t2_13", leftDialog = "", customDialogText = "Processing trade...", stopConversation = "true", options = {} }
jedi_furniture_sea_vendor_conv:addScreen(jfs_give_13)

jfs_bye = ConvoScreen:new {
	id = "jfs_bye",
	leftDialog = "",
	customDialogText = "Come back with 50 Clothing or Armor Attachments when you want Jedi furniture.",
	stopConversation = "true",
	options = {}
}
jedi_furniture_sea_vendor_conv:addScreen(jfs_bye)

addConversationTemplate("jedi_furniture_sea_vendor_conv", jedi_furniture_sea_vendor_conv)
