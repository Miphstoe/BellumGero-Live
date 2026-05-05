paintingExchangeCuratorConvoTemplate = ConvoTemplate:new {
	initialScreen = "pec_hub",
	templateType = "Lua",
	luaClassHandler = "PaintingExchangeConvoHandler",
	screens = {}
}

pec_hub = ConvoScreen:new {
	id = "pec_hub",
	leftDialog = "",
	customDialogText = "Greetings, collector. I offer two exchange programs. For 10 paintings I will give you a rare painting of your choice. For 50 paintings I can offer something far more extraordinary — a Holocron of Destiny or a Resource Deed. Only paintings carried in your main inventory are eligible.",
	stopConversation = "false",
	options = {
		{"I would like to exchange 10 paintings for a painting.", "pec_start_exchange"},
		{"I would like to exchange 50 paintings for a rare item.", "pec_start_premium_exchange"},
		{"What paintings do you accept?", "pec_accepted_list"},
		{"Never mind.", "pec_goodbye"},
	}
}
paintingExchangeCuratorConvoTemplate:addScreen(pec_hub)

pec_start_exchange = ConvoScreen:new {
	id = "pec_start_exchange",
	leftDialog = "",
	customDialogText = "Checking your inventory for eligible paintings.",
	stopConversation = "false",
	options = {
		{"Back", "pec_hub"},
		{"Goodbye", "pec_goodbye"},
	}
}
paintingExchangeCuratorConvoTemplate:addScreen(pec_start_exchange)

pec_start_premium_exchange = ConvoScreen:new {
	id = "pec_start_premium_exchange",
	leftDialog = "",
	customDialogText = "Checking your inventory for eligible paintings.",
	stopConversation = "false",
	options = {
		{"Back", "pec_hub"},
		{"Goodbye", "pec_goodbye"},
	}
}
paintingExchangeCuratorConvoTemplate:addScreen(pec_start_premium_exchange)

pec_accepted_list = ConvoScreen:new {
	id = "pec_accepted_list",
	leftDialog = "",
	customDialogText = "I accept any standard painting from your main inventory. This includes Bestine portraits, wanted posters, schematics, landscapes, species portraits, and similar works. Paintings stored in houses, banks, containers, or datapad slots are not counted — they must be in your carried inventory.\n\n10 paintings: choose one rare painting.\n50 paintings: choose a Holocron of Destiny or a Resource Deed.",
	stopConversation = "false",
	options = {
		{"Back", "pec_hub"},
		{"Goodbye", "pec_goodbye"},
	}
}
paintingExchangeCuratorConvoTemplate:addScreen(pec_accepted_list)

pec_goodbye = ConvoScreen:new {
	id = "pec_goodbye",
	leftDialog = "",
	customDialogText = "Return when you have assembled a worthy collection.",
	stopConversation = "true",
	options = {}
}
paintingExchangeCuratorConvoTemplate:addScreen(pec_goodbye)

addConversationTemplate("paintingExchangeCuratorConvoTemplate", paintingExchangeCuratorConvoTemplate)
