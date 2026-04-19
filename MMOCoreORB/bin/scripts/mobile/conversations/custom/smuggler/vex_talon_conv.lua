vexTalonConvoTemplate = ConvoTemplate:new {
	initialScreen = "vex_hub",
	templateType = "Lua",
	luaClassHandler = "VexTalonConvoHandler",
	screens = {}
}

vex_hub = ConvoScreen:new {
	id = "vex_hub",
	leftDialog = "",
	customDialogText = "Take the disk. Make the drop. No questions.",
	stopConversation = "false",
	options = {
		{"I want a job.", "vex_job"},
		{"Low risk.", "vex_low"},
		{"Medium risk.", "vex_medium"},
		{"High risk.", "vex_high"},
		{"Where is my delivery?", "vex_status"},
		{"Never mind.", "vex_goodbye"},
	}
}
vexTalonConvoTemplate:addScreen(vex_hub)

vex_job = ConvoScreen:new {
	id = "vex_job",
	leftDialog = "",
	customDialogText = "You get paid for silence.",
	stopConversation = "false",
	options = {
		{"Low risk.", "vex_low"},
		{"Medium risk.", "vex_medium"},
		{"High risk.", "vex_high"},
		{"Back.", "vex_hub"},
	}
}
vexTalonConvoTemplate:addScreen(vex_job)

vex_low = ConvoScreen:new {
	id = "vex_low",
	leftDialog = "",
	customDialogText = "Low risk contract selected.",
	stopConversation = "true",
	options = {}
}
vexTalonConvoTemplate:addScreen(vex_low)

vex_medium = ConvoScreen:new {
	id = "vex_medium",
	leftDialog = "",
	customDialogText = "Medium risk contract selected.",
	stopConversation = "true",
	options = {}
}
vexTalonConvoTemplate:addScreen(vex_medium)

vex_high = ConvoScreen:new {
	id = "vex_high",
	leftDialog = "",
	customDialogText = "High risk contract selected.",
	stopConversation = "true",
	options = {}
}
vexTalonConvoTemplate:addScreen(vex_high)

vex_status = ConvoScreen:new {
	id = "vex_status",
	leftDialog = "",
	customDialogText = "Checking your current delivery.",
	stopConversation = "true",
	options = {}
}
vexTalonConvoTemplate:addScreen(vex_status)

vex_goodbye = ConvoScreen:new {
	id = "vex_goodbye",
	leftDialog = "",
	customDialogText = "Then stay quiet and stay invisible.",
	stopConversation = "true",
	options = {}
}
vexTalonConvoTemplate:addScreen(vex_goodbye)

addConversationTemplate("vexTalonConvoTemplate", vexTalonConvoTemplate)
