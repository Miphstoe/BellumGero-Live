heavyOrdinanceTrialConvoTemplate = ConvoTemplate:new {
	initialScreen = "hub",
	templateType = "Lua",
	luaClassHandler = "HeavyOrdinanceTrialConvoHandler",
	screens = {}
}

hub = ConvoScreen:new {
	id = "hub",
	leftDialog = "",
	customDialogText = "State your business.",
	stopConversation = "false",
	options = {
		{"Authorize a siege operation.", "start_assignment"},
		{"Give me the battlefield report.", "progress_report"},
		{"Process my debrief.", "claim_reward"},
		{"Check my cooldown.", "cooldown_status"},
		{"Review the operational doctrine.", "rules"},
		{"Stand down my current operation.", "abort_assignment"},
		{"Dismissed.", "goodbye"},
	}
}
heavyOrdinanceTrialConvoTemplate:addScreen(hub)

start_assignment = ConvoScreen:new {
	id = "start_assignment",
	leftDialog = "",
	customDialogText = "Transmitting assault package.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(start_assignment)

progress_report = ConvoScreen:new {
	id = "progress_report",
	leftDialog = "",
	customDialogText = "Compiling field report.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(progress_report)

claim_reward = ConvoScreen:new {
	id = "claim_reward",
	leftDialog = "",
	customDialogText = "Reviewing your debrief.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(claim_reward)

cooldown_status = ConvoScreen:new {
	id = "cooldown_status",
	leftDialog = "",
	customDialogText = "Checking operational lockout.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(cooldown_status)

rules = ConvoScreen:new {
	id = "rules",
	leftDialog = "",
	customDialogText = "Heavy assault doctrine follows.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(rules)

abort_assignment = ConvoScreen:new {
	id = "abort_assignment",
	leftDialog = "",
	customDialogText = "Standing down the operation.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(abort_assignment)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Then clear the lane for someone who can carry the gun line forward.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(goodbye)

response = ConvoScreen:new {
	id = "response",
	leftDialog = "",
	customDialogText = "Operation log updated.",
	stopConversation = "true",
	options = {}
}
heavyOrdinanceTrialConvoTemplate:addScreen(response)

addConversationTemplate("heavyOrdinanceTrialConvoTemplate", heavyOrdinanceTrialConvoTemplate)
