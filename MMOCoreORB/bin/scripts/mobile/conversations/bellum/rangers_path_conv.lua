rangersPathConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType = "Lua",
	luaClassHandler = "RangersPathConvoHandler",
	screens = {}
}

intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "The wilds do not forgive carelessness. They reward patience, discipline, and clear eyes. If you seek the Ranger's Path, speak plainly and stand ready to earn it.",
	stopConversation = "false",
	options = {
		{"I want to walk the Ranger's Path.", "accept_quest"},
		{"I am not ready for that burden.", "decline_quest"},
	}
}
rangersPathConvoTemplate:addScreen(intro)

accept_quest = ConvoScreen:new {
	id = "accept_quest",
	leftDialog = "",
	customDialogText = "Good. Then listen carefully. You will track, endure, protect, and prove that the frontier can depend on you. Take the first trail and return only when you have done the work.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(accept_quest)

decline_quest = ConvoScreen:new {
	id = "decline_quest",
	leftDialog = "",
	customDialogText = "Better an honest refusal than a false oath. Return when your feet are steady and your mind is set.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(decline_quest)

stage_1_progress = ConvoScreen:new {
	id = "stage_1_progress",
	leftDialog = "",
	customDialogText = "Tracking is more than following prints in the dirt. Read the brush, the silence, and the ground. Find the hunter and learn how it moves.",
	stopConversation = "false",
	options = {
		{"I am still working the trail.", "goodbye"},
		{"Mark the hunt area again.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_1_progress)

stage_1_ready = ConvoScreen:new {
	id = "stage_1_ready",
	leftDialog = "",
	customDialogText = "You have brought down the predator. Report what you learned, and I will set your feet on the next trail.",
	stopConversation = "false",
	options = {
		{"I am ready to report Stage 1.", "complete_stage_1"},
		{"Give me a moment.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(stage_1_ready)

complete_stage_1 = ConvoScreen:new {
	id = "complete_stage_1",
	leftDialog = "",
	customDialogText = "Good. Your eyes are opening. Move on to the next lesson.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(complete_stage_1)

stage_2_progress = ConvoScreen:new {
	id = "stage_2_progress",
	leftDialog = "",
	customDialogText = "Survival is not comfort. Find the hidden camp, inspect the cache, and endure whatever answers your touch. A ranger stays useful under pressure.",
	stopConversation = "false",
	options = {
		{"I am still working the camp site.", "goodbye"},
		{"Refresh the camp location.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_2_progress)

stage_2_ready = ConvoScreen:new {
	id = "stage_2_ready",
	leftDialog = "",
	customDialogText = "You endured the wilderness and the teeth it sent against you. Speak your report and we will continue.",
	stopConversation = "false",
	options = {
		{"I am ready to report Stage 2.", "complete_stage_2"},
		{"Not yet.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(stage_2_ready)

complete_stage_2 = ConvoScreen:new {
	id = "complete_stage_2",
	leftDialog = "",
	customDialogText = "You endured what the land demanded. Now prove you can do more than survive.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(complete_stage_2)

stage_3_progress = ConvoScreen:new {
	id = "stage_3_progress",
	leftDialog = "",
	customDialogText = "The scouts vanished for a reason. Follow their trail carefully. False certainty kills as surely as claws do.",
	stopConversation = "false",
	options = {
		{"I am still tracking the missing scouts.", "goodbye"},
		{"Refresh the trail marker.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_3_progress)

stage_3_ready = ConvoScreen:new {
	id = "stage_3_ready",
	leftDialog = "",
	customDialogText = "You found the scouts' last trail and brought back their datapad. Truth is often ugly in the wilds, but a ranger carries it cleanly.",
	stopConversation = "false",
	options = {
		{"I am ready to report Stage 3.", "complete_stage_3"},
		{"Give me another moment.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(stage_3_ready)

complete_stage_3 = ConvoScreen:new {
	id = "complete_stage_3",
	leftDialog = "",
	customDialogText = "You found the truth and carried it back. That is ranger work. Continue.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(complete_stage_3)

stage_4_progress = ConvoScreen:new {
	id = "stage_4_progress",
	leftDialog = "",
	customDialogText = "A great hunt is not won by panic. Sweep the grounds, learn the beast's rhythm, and strike when the land itself gives you the opening.",
	stopConversation = "false",
	options = {
		{"The hunt is still underway.", "goodbye"},
		{"Mark the hunt grounds again.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_4_progress)

stage_4_ready = ConvoScreen:new {
	id = "stage_4_ready",
	leftDialog = "",
	customDialogText = "So the beast is down. Good. Skill matters more than boasting. Report in.",
	stopConversation = "false",
	options = {
		{"I am ready to report Stage 4.", "complete_stage_4"},
		{"Not yet.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(stage_4_ready)

complete_stage_4 = ConvoScreen:new {
	id = "complete_stage_4",
	leftDialog = "",
	customDialogText = "A clean hunt shows patience. You will need that same patience for what comes next.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(complete_stage_4)

stage_5_progress = ConvoScreen:new {
	id = "stage_5_progress",
	leftDialog = "",
	customDialogText = "The frontier is protected by those willing to stand where danger breaks first. Hold the settler camp. If all the key settlers fall, you start again.",
	stopConversation = "false",
	options = {
		{"I am still defending the camp.", "goodbye"},
		{"Refresh the defense location.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_5_progress)

stage_5_ready = ConvoScreen:new {
	id = "stage_5_ready",
	leftDialog = "",
	customDialogText = "You held the frontier when it mattered. At least one life remained because you did your duty. One final hunt remains.",
	stopConversation = "false",
	options = {
		{"I am ready to report Stage 5.", "complete_stage_5"},
		{"Give me a moment.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(stage_5_ready)

complete_stage_5 = ConvoScreen:new {
	id = "complete_stage_5",
	leftDialog = "",
	customDialogText = "Good. Now comes the final proving hunt. Fail it, and all the earlier lessons meant nothing.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(complete_stage_5)

stage_6_progress = ConvoScreen:new {
	id = "stage_6_progress",
	leftDialog = "",
	customDialogText = "Ancient Shadowclaw waits in the proving grounds. This is no routine hunt. Enter the region, face it cleanly, and return only if you truly finish the trial.",
	stopConversation = "false",
	options = {
		{"I am still facing the Ranger Trial.", "goodbye"},
		{"Refresh the proving grounds.", "refresh_waypoint"},
	}
}
rangersPathConvoTemplate:addScreen(stage_6_progress)

final_completion = ConvoScreen:new {
	id = "final_completion",
	leftDialog = "",
	customDialogText = "You faced Ancient Shadowclaw and returned standing. That is the mark of a ranger. I can now recognize your path and grant what you have earned.",
	stopConversation = "false",
	options = {
		{"I am ready to receive my ranger's reward.", "claim_reward"},
		{"I will return in a moment.", "goodbye"},
	}
}
rangersPathConvoTemplate:addScreen(final_completion)

claim_reward = ConvoScreen:new {
	id = "claim_reward",
	leftDialog = "",
	customDialogText = "Take these credits and this creature survey tool. They are not decoration. They are responsibility. Use them like a ranger should.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(claim_reward)

already_completed = ConvoScreen:new {
	id = "already_completed",
	leftDialog = "",
	customDialogText = "You have already proven yourself on this path. Keep your senses sharp, your camp quiet, and your promises kept. The frontier always watches.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(already_completed)

refresh_waypoint = ConvoScreen:new {
	id = "refresh_waypoint",
	leftDialog = "",
	customDialogText = "Then mark the trail clearly and do not waste the guidance. A ranger who gets lost twice is not paying attention.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(refresh_waypoint)

goodbye = ConvoScreen:new {
	id = "goodbye",
	leftDialog = "",
	customDialogText = "Go carefully. The wilderness favors the prepared.",
	stopConversation = "true",
	options = {}
}
rangersPathConvoTemplate:addScreen(goodbye)

addConversationTemplate("rangersPathConvoTemplate", rangersPathConvoTemplate)
