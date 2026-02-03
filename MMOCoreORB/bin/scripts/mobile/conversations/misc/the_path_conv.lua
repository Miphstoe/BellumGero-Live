the_path_conv_template = ConvoTemplate:new {
	initialScreen = "start",
	templateType = "Lua",
	luaClassHandler = "ThePathConvoHandler",
	screens = {}
}

start = ConvoScreen:new {
	id = "start",
	customDialogText = "Keep your voice down. I can give you a new identity, something that will throw the hunters off your trail. It's going to cost you 250,000 credits. Do you want me to do it?",
	stopConversation = "false",
	options = {
		{"Yes. Give me a new identity.", "confirm"},
		{"No thanks.", "bye"}
	}
}
the_path_conv_template:addScreen(start)

confirm = ConvoScreen:new {
	id = "confirm",
	customDialogText = "Once I do this, your trail goes cold for a while. Are you sure?",
	stopConversation = "false",
	options = {
		{"Proceed.", "do_identity"},
		{"Actually, nevermind.", "bye"}
	}
}
the_path_conv_template:addScreen(confirm)

do_identity = ConvoScreen:new {
	id = "do_identity",
	customDialogText = "…",
	stopConversation = "false",
	options = {}
}
the_path_conv_template:addScreen(do_identity)

success = ConvoScreen:new {
	id = "success",
	customDialogText = "Done. Your old identity is burned. Stay careful, you will build heat again over time.",
	stopConversation = "true",
	options = {}
}
the_path_conv_template:addScreen(success)

not_jedi = ConvoScreen:new {
	id = "not_jedi",
	customDialogText = "You are not who I am looking for. Move along.",
	stopConversation = "true",
	options = {}
}
the_path_conv_template:addScreen(not_jedi)

cooldown = ConvoScreen:new {
	id = "cooldown",
	customDialogText = "Not so fast. I can not do that again yet. Come back later.",
	stopConversation = "true",
	options = {}
}
the_path_conv_template:addScreen(cooldown)

no_money = ConvoScreen:new {
	id = "no_money",
	customDialogText = "That kind of help is not free. Come back when you have 250,000 credits.",
	stopConversation = "true",
	options = {}
}
the_path_conv_template:addScreen(no_money)

bye = ConvoScreen:new {
	id = "bye",
	customDialogText = "Smart. The less you deal with people like me, the better.",
	stopConversation = "true",
	options = {}
}
the_path_conv_template:addScreen(bye)

addConversationTemplate("the_path_conv_template", the_path_conv_template)
