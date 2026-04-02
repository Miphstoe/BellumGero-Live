galacticTourConvoTemplate = ConvoTemplate:new {
	initialScreen = "gt_hub",
	templateType = "Lua",
	luaClassHandler = "GalacticTourConvoHandler",
	screens = {}
}

-- Hub: inactive, no cooldown — show all options
gt_hub = ConvoScreen:new {
	id = "gt_hub",
	leftDialog = "",
	customDialogText = "I coordinate the Galactic Tour. Perform inside valid NPC city cantinas on 5 different planets, 10 continuous minutes each, with at least 10 flourishes per stop. Choose the worlds in any order and return to me when you finish.",
	stopConversation = "false",
	options = {
		{"Start Galactic Tour", "gt_start_tour"},
		{"Show my progress", "gt_progress_report"},
		{"Turn in my completed tour", "gt_turn_in"},
		{"Cooldown status", "gt_cooldown_status"},
		{"Explain the rules", "gt_rules"},
		{"I will return later.", "gt_goodbye"},
	}
}
galacticTourConvoTemplate:addScreen(gt_hub)

-- Hub: tour already active
gt_hub_active = ConvoScreen:new {
	id = "gt_hub_active",
	leftDialog = "",
	customDialogText = "Your Galactic Tour is already underway. Perform in valid cantinas on the remaining planets, then return to turn in your route log.",
	stopConversation = "false",
	options = {
		{"Show my progress", "gt_progress_report"},
		{"Turn in my completed tour", "gt_turn_in"},
		{"Explain the rules", "gt_rules"},
		{"I will return later.", "gt_goodbye"},
	}
}
galacticTourConvoTemplate:addScreen(gt_hub_active)

-- Hub: ready to turn in
gt_hub_ready = ConvoScreen:new {
	id = "gt_hub_ready",
	leftDialog = "",
	customDialogText = "Your 5-stop Galactic Tour is complete. Return your route log and I will issue your reward.",
	stopConversation = "false",
	options = {
		{"Turn in my completed tour", "gt_turn_in"},
		{"Show my progress", "gt_progress_report"},
		{"I will return later.", "gt_goodbye"},
	}
}
galacticTourConvoTemplate:addScreen(gt_hub_ready)

-- Hub: not an eligible entertainer
gt_hub_ineligible = ConvoScreen:new {
	id = "gt_hub_ineligible",
	leftDialog = "",
	customDialogText = "This tour is reserved for entertainers only. You must hold entertainer, dancer, or musician training to begin the Galactic Tour.",
	stopConversation = "false",
	options = {
		{"I will return later.", "gt_goodbye"},
	}
}
galacticTourConvoTemplate:addScreen(gt_hub_ineligible)

-- Hub: on cooldown
gt_hub_cooldown = ConvoScreen:new {
	id = "gt_hub_cooldown",
	leftDialog = "",
	customDialogText = "You have already completed your latest Galactic Tour. Check your cooldown status below.",
	stopConversation = "false",
	options = {
		{"Cooldown status", "gt_cooldown_status"},
		{"I will return later.", "gt_goodbye"},
	}
}
galacticTourConvoTemplate:addScreen(gt_hub_cooldown)

-- Action screens — these are navigated to by option links and processed by runScreenHandlers
gt_start_tour = ConvoScreen:new {
	id = "gt_start_tour",
	leftDialog = "",
	customDialogText = "Starting your tour.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_start_tour)

gt_progress_report = ConvoScreen:new {
	id = "gt_progress_report",
	leftDialog = "",
	customDialogText = "Reviewing your route log.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_progress_report)

gt_turn_in = ConvoScreen:new {
	id = "gt_turn_in",
	leftDialog = "",
	customDialogText = "Checking your completed tour.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_turn_in)

gt_cooldown_status = ConvoScreen:new {
	id = "gt_cooldown_status",
	leftDialog = "",
	customDialogText = "Checking cooldown status.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_cooldown_status)

gt_rules = ConvoScreen:new {
	id = "gt_rules",
	leftDialog = "",
	customDialogText = "Tour rules follow.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_rules)

gt_response = ConvoScreen:new {
	id = "gt_response",
	leftDialog = "",
	customDialogText = "Route update complete.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_response)

gt_goodbye = ConvoScreen:new {
	id = "gt_goodbye",
	leftDialog = "",
	customDialogText = "The galaxy will still be waiting when you are ready to perform.",
	stopConversation = "true",
	options = {}
}
galacticTourConvoTemplate:addScreen(gt_goodbye)

addConversationTemplate("galacticTourConvoTemplate", galacticTourConvoTemplate)
