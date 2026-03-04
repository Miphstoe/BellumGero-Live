lostHolocronCartographerConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType = "Lua",
	luaClassHandler = "LostHolocronCartographerConvoHandler",
	screens = {}
}

intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "I map Force anomalies fractured across the galaxy. Survey six of them, survive the guardians, and bring me the completed record.",
	stopConversation = "false",
	options = {
		{"I will begin the survey route.", "accept_quest"},
		{"Not right now.", "goodbye"},
	}
}
lostHolocronCartographerConvoTemplate:addScreen(intro)

accept_quest = ConvoScreen:new {
	id = "accept_quest",
	leftDialog = "",
	customDialogText = "Your first anomaly waypoint has been transmitted. Use the survey stone's radial option to begin each survey.",
	stopConversation = "true",
	options = {}
}
lostHolocronCartographerConvoTemplate:addScreen(accept_quest)

in_progress = ConvoScreen:new {
	id = "in_progress",
	leftDialog = "",
	customDialogText = "Your cartography is in progress. Continue surveying anomaly stones in order, or ask me to refresh your current waypoint.",
	stopConversation = "false",
	options = {
		{"Refresh my active anomaly waypoint.", "refresh_waypoint"},
		{"I will continue the surveys.", "goodbye"},
	}
}
lostHolocronCartographerConvoTemplate:addScreen(in_progress)

refresh_waypoint = ConvoScreen:new {
	id = "refresh_waypoint",
	leftDialog = "",
	customDialogText = "Waypoint refreshed. Return when all six anomaly surveys are complete.",
	stopConversation = "true",
	options = {}
}
lostHolocronCartographerConvoTemplate:addScreen(refresh_waypoint)

reward_pending = ConvoScreen:new {
	id = "reward_pending",
	leftDialog = "",
	customDialogText = "Your anomaly ledger is complete. I can now award exactly one Holocron of Destiny.",
	stopConversation = "false",
	options = {
		{"Grant me the Holocron of Destiny.", "claim_reward"},
		{"I need a moment.", "goodbye"},
	}
}
lostHolocronCartographerConvoTemplate:addScreen(reward_pending)

claim_reward = ConvoScreen:new {
	id = "claim_reward",
	leftDialog = "",
	customDialogText = "Take this Holocron of Destiny and follow where it leads.",
	stopConversation = "true",
	options = {}
}
lostHolocronCartographerConvoTemplate:addScreen(claim_reward)

cooldown = ConvoScreen:new {
	id = "cooldown",
	leftDialog = "",
	customDialogText = "The anomaly lattice needs time to recover. Return after your cooldown expires.",
	stopConversation = "true",
	options = {}
}
lostHolocronCartographerConvoTemplate:addScreen(cooldown)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "I will remain in Bestine when you are ready.",
	stopConversation = "true",
	options = {}
}
lostHolocronCartographerConvoTemplate:addScreen(goodbye)

addConversationTemplate("lostHolocronCartographerConvoTemplate", lostHolocronCartographerConvoTemplate)
