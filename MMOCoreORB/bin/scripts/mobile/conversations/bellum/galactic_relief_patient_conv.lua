galacticReliefPatientConvoTemplate = ConvoTemplate:new {
	initialScreen = "patient_hub",
	templateType = "Lua",
	luaClassHandler = "GalacticReliefPatientConvoHandler",
	screens = {}
}

patient_hub = ConvoScreen:new {
	id = "patient_hub",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "false",
	options = {
		{"I can treat your wounds.", "treat_wounds"},
		{"I can treat your damage.", "treat_damage"},
		{"Hold on a little longer.", "goodbye"},
	}
}
galacticReliefPatientConvoTemplate:addScreen(patient_hub)

treat_wounds = ConvoScreen:new {
	id = "treat_wounds",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefPatientConvoTemplate:addScreen(treat_wounds)

treat_damage = ConvoScreen:new {
	id = "treat_damage",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
galacticReliefPatientConvoTemplate:addScreen(treat_damage)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Please hurry. Others still need help.",
	stopConversation = "true",
	options = {}
}
galacticReliefPatientConvoTemplate:addScreen(goodbye)

addConversationTemplate("galacticReliefPatientConvoTemplate", galacticReliefPatientConvoTemplate)
