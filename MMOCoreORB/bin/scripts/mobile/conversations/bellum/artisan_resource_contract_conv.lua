artisanResourceContractConvoTemplate = ConvoTemplate:new {
	initialScreen = "arc_hub",
	templateType = "Lua",
	luaClassHandler = "ArtisanResourceContractConvoHandler",
	screens = {}
}

arc_hub = ConvoScreen:new {
	id = "arc_hub",
	leftDialog = "",
	customDialogText = "I have an active procurement contract for rare industrial resources. Bring me 5,000 units each of five requested materials, and I will compensate you well for your effort.",
	stopConversation = "false",
	options = {
		{"Request a new contract", "arc_request_contract"},
		{"View my current contract", "arc_view_contract"},
		{"Submit all valid resources", "arc_submit_all"},
		{"Submit a specific objective", "arc_submit_menu"},
		{"Reset my contract", "arc_reset_contract"},
		{"Reset status", "arc_reset_status"},
		{"Explain the rules", "arc_rules"},
		{"I will return later.", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_hub)

arc_request_contract = ConvoScreen:new {
	id = "arc_request_contract",
	leftDialog = "",
	customDialogText = "Preparing your contract.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_request_contract)

arc_view_contract = ConvoScreen:new {
	id = "arc_view_contract",
	leftDialog = "",
	customDialogText = "Reviewing your contract.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_view_contract)

arc_submit_all = ConvoScreen:new {
	id = "arc_submit_all",
	leftDialog = "",
	customDialogText = "Inspecting your shipment.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_all)

arc_submit_menu = ConvoScreen:new {
	id = "arc_submit_menu",
	leftDialog = "",
	customDialogText = "Choose which contract objective shipment you want me to inspect.",
	stopConversation = "false",
	options = {
		{"Submit objective 1", "arc_submit_obj_1"},
		{"Submit objective 2", "arc_submit_obj_2"},
		{"Submit objective 3", "arc_submit_obj_3"},
		{"Submit objective 4", "arc_submit_obj_4"},
		{"Submit objective 5", "arc_submit_obj_5"},
		{"Back", "arc_hub"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_menu)

arc_submit_obj_1 = ConvoScreen:new {
	id = "arc_submit_obj_1",
	leftDialog = "",
	customDialogText = "Inspecting objective 1 materials.",
	stopConversation = "false",
	options = {
		{"Back", "arc_submit_menu"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_obj_1)

arc_submit_obj_2 = ConvoScreen:new {
	id = "arc_submit_obj_2",
	leftDialog = "",
	customDialogText = "Inspecting objective 2 materials.",
	stopConversation = "false",
	options = {
		{"Back", "arc_submit_menu"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_obj_2)

arc_submit_obj_3 = ConvoScreen:new {
	id = "arc_submit_obj_3",
	leftDialog = "",
	customDialogText = "Inspecting objective 3 materials.",
	stopConversation = "false",
	options = {
		{"Back", "arc_submit_menu"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_obj_3)

arc_submit_obj_4 = ConvoScreen:new {
	id = "arc_submit_obj_4",
	leftDialog = "",
	customDialogText = "Inspecting objective 4 materials.",
	stopConversation = "false",
	options = {
		{"Back", "arc_submit_menu"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_obj_4)

arc_submit_obj_5 = ConvoScreen:new {
	id = "arc_submit_obj_5",
	leftDialog = "",
	customDialogText = "Inspecting objective 5 materials.",
	stopConversation = "false",
	options = {
		{"Back", "arc_submit_menu"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_submit_obj_5)

arc_rules = ConvoScreen:new {
	id = "arc_rules",
	leftDialog = "",
	customDialogText = "Contract rules follow.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_rules)

arc_reset_contract = ConvoScreen:new {
	id = "arc_reset_contract",
	leftDialog = "",
	customDialogText = "Voiding and replacing your contract.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_reset_contract)

arc_reset_status = ConvoScreen:new {
	id = "arc_reset_status",
	leftDialog = "",
	customDialogText = "Checking contract reset availability.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_reset_status)

arc_response = ConvoScreen:new {
	id = "arc_response",
	leftDialog = "",
	customDialogText = "Contract status updated.",
	stopConversation = "false",
	options = {
		{"Back", "arc_hub"},
		{"Goodbye", "arc_goodbye"},
	}
}
artisanResourceContractConvoTemplate:addScreen(arc_response)

arc_goodbye = ConvoScreen:new {
	id = "arc_goodbye",
	leftDialog = "",
	customDialogText = "Return when you are ready to fulfill another procurement contract.",
	stopConversation = "true",
	options = {}
}
artisanResourceContractConvoTemplate:addScreen(arc_goodbye)

addConversationTemplate("artisanResourceContractConvoTemplate", artisanResourceContractConvoTemplate)
