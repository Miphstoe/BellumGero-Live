bgForceHermitConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType = "Lua",
	luaClassHandler = "BgForceHermitConversationHandler",
	screens = {}
}

intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "You seek the Path of Awakening. Meditate at three shrines in order: Naboo, then Corellia, then Dantooine. Remain within 10 meters for 30 seconds at each. When all three are complete, return to me.",
	stopConversation = "false",
	options = {
		{"I will seek the shrines.", "accept"},
		{"Not now.", "bye"},
	}
}

temp = bgForceHermitConvoTemplate:addScreen(intro)

accept = ConvoScreen:new {
	id = "accept",
	leftDialog = "",
	customDialogText = "Do not rush. Breathe. Remain within the shrine's calm for a full meditation. I have uploaded the locations of the three shrines to your datapad.",
	stopConversation = "true",
	options = {}
}

temp = bgForceHermitConvoTemplate:addScreen(accept)

choice = ConvoScreen:new {
	id = "choice",
	leftDialog = "",
	customDialogText = "You have heard the call. Choose the path that guides your steps, and I will place a crystal in your hands.",
	stopConversation = "false",
	options = {
		{"I will walk in the light.", "choose_light"},
		{"I will walk in the dark.", "choose_dark"},
	}
}

temp = bgForceHermitConvoTemplate:addScreen(choice)

choose_light = ConvoScreen:new {
	id = "choose_light",
	leftDialog = "",
	customDialogText = "Then let compassion be your compass. Use the crystal to open the way.",
	stopConversation = "true",
	options = {}
}

temp = bgForceHermitConvoTemplate:addScreen(choose_light)

choose_dark = ConvoScreen:new {
	id = "choose_dark",
	leftDialog = "",
	customDialogText = "Then let resolve guide you. Use the crystal to open the way.",
	stopConversation = "true",
	options = {}
}

temp = bgForceHermitConvoTemplate:addScreen(choose_dark)

completed = ConvoScreen:new {
	id = "completed",
	leftDialog = "",
	customDialogText = "The path is open. Walk it with purpose.",
	stopConversation = "true",
	options = {}
}

temp = bgForceHermitConvoTemplate:addScreen(completed)

bye = ConvoScreen:new {
	id = "bye",
	leftDialog = "",
	customDialogText = "Very well. You may return when you seek the guidance of the Force.",
	stopConversation = "true",
	options = {}
}

temp = bgForceHermitConvoTemplate:addScreen(bye)

addConversationTemplate("bgForceHermitConvoTemplate", bgForceHermitConvoTemplate)
