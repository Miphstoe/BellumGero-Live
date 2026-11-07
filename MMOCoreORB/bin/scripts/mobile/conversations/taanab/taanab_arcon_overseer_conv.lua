-- Arcon Farm Overseer (hex farms, Taanab). Texts are filled in by TaanabArconOverseerConvoHandler.
taanabArconOverseerConvoTemplate = ConvoTemplate:new {
	initialScreen = "overseer_hub",
	templateType = "Lua",
	luaClassHandler = "TaanabArconOverseerConvoHandler",
	screens = {}
}

overseer_hub = ConvoScreen:new {
	id = "overseer_hub",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "false",
	options = {
		{"Light the signal beacon. Let the Norulac come.", "overseer_start_raid"},
		{"How do the raids work?", "overseer_explain"},
		{"Goodbye.", "overseer_goodbye"},
	}
}
taanabArconOverseerConvoTemplate:addScreen(overseer_hub)

overseer_start_raid = ConvoScreen:new {
	id = "overseer_start_raid",
	leftDialog = "",
	customDialogText = "",
	stopConversation = "true",
	options = {}
}
taanabArconOverseerConvoTemplate:addScreen(overseer_start_raid)

overseer_explain = ConvoScreen:new {
	id = "overseer_explain",
	leftDialog = "",
	customDialogText = "When the beacon burns, Varn Kessic's raiders come for the fields. Two waves land first, then Kessic himself with four honor guards. Nothing touches him until the guards fall. He calls more raiders as he weakens, and when he's nearly beaten he starts throwing thermal detonators. Keep moving and keep spread out. If he isn't beaten within 45 minutes of landing, they pull back to their ships.",
	stopConversation = "false",
	options = {
		{"Light the signal beacon. Let the Norulac come.", "overseer_start_raid"},
		{"Goodbye.", "overseer_goodbye"},
	}
}
taanabArconOverseerConvoTemplate:addScreen(overseer_explain)

overseer_goodbye = ConvoScreen:new {
	id = "overseer_goodbye",
	leftDialog = "",
	customDialogText = "Keep your eyes on the sky.",
	stopConversation = "true",
	options = {}
}
taanabArconOverseerConvoTemplate:addScreen(overseer_goodbye)

addConversationTemplate("taanabArconOverseerConvoTemplate", taanabArconOverseerConvoTemplate)
