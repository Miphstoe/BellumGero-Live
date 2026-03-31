galacticBeastmasterTrialConvoTemplate = ConvoTemplate:new {
	initialScreen = "hub",
	templateType = "Lua",
	luaClassHandler = "GalacticBeastmasterTrialConvoHandler",
	screens = {}
}

hub = ConvoScreen:new {
	id = "hub",
	leftDialog = "",
	customDialogText = "The Galactic Beastmaster Trial awaits.",
	stopConversation = "false",
	options = {
		{"Start Trial", "start_trial"},
		{"Progress Report", "progress_report"},
		{"Completion Check", "completion_check"},
		{"Cooldown Status", "cooldown_status"},
		{"Rules / Explanation", "rules"},
		{"I will return later.", "goodbye"},
	}
}
galacticBeastmasterTrialConvoTemplate:addScreen(hub)

start_trial = ConvoScreen:new {
	id = "start_trial",
	leftDialog = "",
	customDialogText = "Beginning the trial.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(start_trial)

progress_report = ConvoScreen:new {
	id = "progress_report",
	leftDialog = "",
	customDialogText = "Reviewing your field records.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(progress_report)

completion_check = ConvoScreen:new {
	id = "completion_check",
	leftDialog = "",
	customDialogText = "Verifying your mastery.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(completion_check)

cooldown_status = ConvoScreen:new {
	id = "cooldown_status",
	leftDialog = "",
	customDialogText = "Checking trial eligibility.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(cooldown_status)

rules = ConvoScreen:new {
	id = "rules",
	leftDialog = "",
	customDialogText = "Trial rules follow.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(rules)

response = ConvoScreen:new {
	id = "response",
	leftDialog = "",
	customDialogText = "Review complete.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(response)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Return when you are ready to prove your mastery.",
	stopConversation = "true",
	options = {}
}
galacticBeastmasterTrialConvoTemplate:addScreen(goodbye)

addConversationTemplate("galacticBeastmasterTrialConvoTemplate", galacticBeastmasterTrialConvoTemplate)
