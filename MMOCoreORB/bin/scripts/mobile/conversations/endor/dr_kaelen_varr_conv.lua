dr_kaelen_varr_convo_template = ConvoTemplate:new {
	initialScreen = "intro",
	templateType = "Lua",
	luaClassHandler = "dr_kaelen_varr_convo_handler",
	screens = {}
}

intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "The galaxy fears what it does not understand. Creatures, DNA, evolution itself. These are the tools of a true Bio-Engineer.",
	stopConversation = "false",
	options = {
		{"What do you need?", "offer_quest"},
		{"Another time.", "decline"}
	}
}
dr_kaelen_varr_convo_template:addScreen(intro)

offer_quest = ConvoScreen:new {
	id = "offer_quest",
	leftDialog = "",
	customDialogText = "I require fresh genetic material from Endor's wildlife. Bring me viable DNA from five suitable creatures, and we will see whether your instincts match your profession.",
	stopConversation = "false",
	options = {
		{"I'll gather the samples.", "accept_quest"},
		{"Not right now.", "decline"}
	}
}
dr_kaelen_varr_convo_template:addScreen(offer_quest)

accept_quest = ConvoScreen:new {
	id = "accept_quest",
	leftDialog = "",
	customDialogText = "Good. I need DNA from bordoks, gurrecks, lantern birds, venom-filled arachne, or squalls. Return once you have five usable samples.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(accept_quest)

decline = ConvoScreen:new {
	id = "decline",
	leftDialog = "",
	customDialogText = "Then do not waste my instruments.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(decline)

not_bio_engineer = ConvoScreen:new {
	id = "not_bio_engineer",
	leftDialog = "",
	customDialogText = "These protocols are reserved for Bio-Engineers. Come back when you understand the language of living matter.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(not_bio_engineer)

in_progress = ConvoScreen:new {
	id = "in_progress",
	leftDialog = "",
	customDialogText = "You are still in the middle of my assignment.",
	stopConversation = "false",
	options = {
		{"Remind me of the objective.", "objective_reminder"},
		{"I'll get back to work.", "decline"}
	}
}
dr_kaelen_varr_convo_template:addScreen(in_progress)

objective_reminder = ConvoScreen:new {
	id = "objective_reminder",
	leftDialog = "",
	customDialogText = "Stay focused. Finish the current objective and return when the work is complete.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(objective_reminder)

stage1_turnin = ConvoScreen:new {
	id = "stage1_turnin",
	leftDialog = "",
	customDialogText = "These samples are usable. Now take them to the research terminal outside and run a full genetic stability scan.",
	stopConversation = "false",
	options = {
		{"Understood.", "stage1_reward"}
	}
}
dr_kaelen_varr_convo_template:addScreen(stage1_turnin)

stage1_reward = ConvoScreen:new {
	id = "stage1_reward",
	leftDialog = "",
	customDialogText = "Your first field collection meets my standards. I have transferred your payment.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(stage1_reward)

stage2_turnin = ConvoScreen:new {
	id = "stage2_turnin",
	leftDialog = "",
	customDialogText = "The stability scan confirms what I suspected. Now craft an experimental defensive tissue component from the data.",
	stopConversation = "false",
	options = {
		{"I'll craft it.", "stage2_reward"}
	}
}
dr_kaelen_varr_convo_template:addScreen(stage2_turnin)

stage2_reward = ConvoScreen:new {
	id = "stage2_reward",
	leftDialog = "",
	customDialogText = "Efficient work. The next step is yours alone at the crafting station.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(stage2_reward)

stage3_turnin = ConvoScreen:new {
	id = "stage3_turnin",
	leftDialog = "",
	customDialogText = "Promising craftsmanship. Unfortunately, the prototype destabilized and a gurreck alpha broke containment. Hunt it down before it reaches the settlement.",
	stopConversation = "false",
	options = {
		{"Where did it go?", "stage3_reward"}
	}
}
dr_kaelen_varr_convo_template:addScreen(stage3_turnin)

stage3_reward = ConvoScreen:new {
	id = "stage3_reward",
	leftDialog = "",
	customDialogText = "I have marked the last reliable readings. Terminate the mutation and return to me.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(stage3_reward)

final_turnin = ConvoScreen:new {
	id = "final_turnin",
	leftDialog = "",
	customDialogText = "Containment is restored. More importantly, the corpse yielded something extraordinary.",
	stopConversation = "false",
	options = {
		{"I'm ready for the reward.", "final_reward"}
	}
}
dr_kaelen_varr_convo_template:addScreen(final_turnin)

final_reward = ConvoScreen:new {
	id = "final_reward",
	leftDialog = "",
	customDialogText = "Take these credits and this Rare Mutation DNA Sample. Guard it carefully. Very few Bio-Engineers ever see material like this outside a laboratory disaster.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(final_reward)

completed = ConvoScreen:new {
	id = "completed",
	leftDialog = "",
	customDialogText = "You handled live-field genetics better than most of my peers. That is worth remembering.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(completed)

on_cooldown = ConvoScreen:new {
	id = "on_cooldown",
	leftDialog = "",
	customDialogText = "My instruments are still recalibrating from your last run. Return in an hour.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(on_cooldown)

repeat_stage4 = ConvoScreen:new {
	id = "repeat_stage4",
	leftDialog = "",
	customDialogText = "Then track it again. I have refreshed the last known location.",
	stopConversation = "true",
	options = {}
}
dr_kaelen_varr_convo_template:addScreen(repeat_stage4)

addConversationTemplate("dr_kaelen_varr_convo_template", dr_kaelen_varr_convo_template)
