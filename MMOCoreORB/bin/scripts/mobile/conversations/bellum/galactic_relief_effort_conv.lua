galacticReliefEffortConvoTemplate = ConvoTemplate:new {
	initialScreen = "hub",
	templateType = "Lua",
	luaClassHandler = "GalacticReliefEffortConvoHandler",
	screens = {}
}

hub = ConvoScreen:new {
	id = "hub",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "false",
	options = {
		{"Begin a relief assignment.", "start_assignment"},
		{"Give me my current progress report.", "progress_report"},
		{"Review the relief protocols.", "rules"},
		{"I will return shortly.", "goodbye"},
	}
}
galacticReliefEffortConvoTemplate:addScreen(hub)

start_assignment = ConvoScreen:new {
	id = "start_assignment",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(start_assignment)

progress_report = ConvoScreen:new {
	id = "progress_report",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(progress_report)

rules = ConvoScreen:new {
	id = "rules",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(rules)

claim_reward = ConvoScreen:new {
	id = "claim_reward",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(claim_reward)

cooldown_status = ConvoScreen:new {
	id = "cooldown_status",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(cooldown_status)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Then go where the wounded need you.",
	stopConversation = "true",
	options = {}
}
galacticReliefEffortConvoTemplate:addScreen(goodbye)

addConversationTemplate("galacticReliefEffortConvoTemplate", galacticReliefEffortConvoTemplate)
