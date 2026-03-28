acklay_instance_keeper_conv = ConvoTemplate:new {
	initialScreen = "intro",
	templateType = "Lua",
	luaClassHandler = "acklay_instance_keeper_conv_handler",
	screens = {}
}

intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "I control access to the private Acklay challenge. If a room is available, I can send you into a solo run reserved to you alone.",
	stopConversation = "false",
	options = {
		{"I want to enter the Acklay instance.", "enter_instance"},
		{"Not right now.", "goodbye"}
	}
}
acklay_instance_keeper_conv:addScreen(intro)

enter_instance = ConvoScreen:new {
	id = "enter_instance",
	leftDialog = "",
	customDialogText = "Preparing your private Acklay challenge.",
	stopConversation = "true",
	options = {}
}
acklay_instance_keeper_conv:addScreen(enter_instance)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Return when you are ready to face the Acklay alone.",
	stopConversation = "true",
	options = {}
}
acklay_instance_keeper_conv:addScreen(goodbye)

addConversationTemplate("acklay_instance_keeper_conv", acklay_instance_keeper_conv)
