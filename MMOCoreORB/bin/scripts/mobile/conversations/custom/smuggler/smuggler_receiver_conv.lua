smugglerReceiverConvoTemplate = ConvoTemplate:new {
	initialScreen = "receiver_idle",
	templateType = "Lua",
	luaClassHandler = "SmugglerReceiverConvoHandler",
	screens = {}
}

receiver_idle = ConvoScreen:new {
	id = "receiver_idle",
	leftDialog = "",
	customDialogText = "You're not the courier I'm waiting on.",
	stopConversation = "true",
	options = {}
}
smugglerReceiverConvoTemplate:addScreen(receiver_idle)

receiver_ready = ConvoScreen:new {
	id = "receiver_ready",
	leftDialog = "",
	customDialogText = "You're late. Hand it over.",
	stopConversation = "false",
	options = {
		{"I have the delivery.", "receiver_handoff"},
		{"Not now.", "receiver_idle"},
	}
}
smugglerReceiverConvoTemplate:addScreen(receiver_ready)

receiver_handoff = ConvoScreen:new {
	id = "receiver_handoff",
	leftDialog = "",
	customDialogText = "Good. No one followed you.",
	stopConversation = "true",
	options = {}
}
smugglerReceiverConvoTemplate:addScreen(receiver_handoff)

receiver_suspicious = ConvoScreen:new {
	id = "receiver_suspicious",
	leftDialog = "",
	customDialogText = "I don't know you. Say the wrong thing and this gets ugly.",
	stopConversation = "false",
	options = {
		{"I have a delivery.", "receiver_wrong"},
		{"Forget it.", "receiver_idle"},
	}
}
smugglerReceiverConvoTemplate:addScreen(receiver_suspicious)

receiver_wrong = ConvoScreen:new {
	id = "receiver_wrong",
	leftDialog = "",
	customDialogText = "Wrong contact.",
	stopConversation = "true",
	options = {}
}
smugglerReceiverConvoTemplate:addScreen(receiver_wrong)

addConversationTemplate("smugglerReceiverConvoTemplate", smugglerReceiverConvoTemplate)
