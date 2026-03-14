-- Mandalorian Spynet Operative Conversation Template
-- Chapters 1-4: manages the 5+1 gate cycle
-- Requires Foundling Helmet equipped + countingEnabled state
-- Handler: MandoSpynetOperativeConvoHandler (in bellum/convos/)

mandoSpynetOperativeConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType  = "Lua",
	luaClassHandler = "MandoSpynetOperativeConvoHandler",
	screens = {}
}

-- --------------------------------------------------------
-- INTRO: handler routes based on arc/chapter/gate state
-- --------------------------------------------------------
intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "I do not talk to strangers.",
	stopConversation = "false",
	options = {
		{"I carry the Foundling mark.", "helmet_check"},
		{"My mistake.", "bye"},
	}
}
mandoSpynetOperativeConvoTemplate:addScreen(intro)

-- --------------------------------------------------------
-- HELMET NOT EQUIPPED
-- --------------------------------------------------------
no_helmet = ConvoScreen:new {
	id = "no_helmet",
	leftDialog = "",
	customDialogText = "No helm. No chain-code. No work.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(no_helmet)

-- --------------------------------------------------------
-- NO FOUNDLING ARC (arc not complete)
-- --------------------------------------------------------
no_foundling = ConvoScreen:new {
	id = "no_foundling",
	leftDialog = "",
	customDialogText = "That helmet does not carry your name yet. Finish the proving arc first.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(no_foundling)

-- --------------------------------------------------------
-- NO NOVICE BH
-- --------------------------------------------------------
no_bh = ConvoScreen:new {
	id = "no_bh",
	leftDialog = "",
	customDialogText = "You have the helmet. Now earn the craft to go with it. Guild terminals. Novice Bounty Hunter. Then come back.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(no_bh)

-- --------------------------------------------------------
-- GATE EXPLAIN: Foundling + Novice BH confirmed, idle state
-- Handler starts the gate cycle via MandoWayOfLife:startChapterGate()
-- --------------------------------------------------------
gate_explain = ConvoScreen:new {
	id = "gate_explain",
	leftDialog = "",
	customDialogText = "Five spynet contracts through the standard bounty terminals. When those are done, one private trial — solo, helmet on, no group. Fail either condition and you start the trial over. Understand?",
	stopConversation = "false",
	options = {
		{"I understand. Begin the count.", "gate_start"},
		{"Not yet.", "bye"},
	}
}
mandoSpynetOperativeConvoTemplate:addScreen(gate_explain)

gate_start = ConvoScreen:new {
	id = "gate_start",
	leftDialog = "",
	customDialogText = "Spynet count is open. Five bounty terminal missions. The count is live.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(gate_start)

-- --------------------------------------------------------
-- GATE IN PROGRESS: BH count not yet at 5
-- --------------------------------------------------------
gate_in_progress = ConvoScreen:new {
	id = "gate_in_progress",
	leftDialog = "",
	customDialogText = "Keep working the terminals. Come back when you have five contracts confirmed.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(gate_in_progress)

-- --------------------------------------------------------
-- READY FOR PRIVATE CONTRACT: 5 BH done, trial available
-- Handler calls MandoWayOfLife:beginPrivateContract()
-- --------------------------------------------------------
trial_ready = ConvoScreen:new {
	id = "trial_ready",
	leftDialog = "",
	customDialogText = "Five confirmed. Now the real work. One private contract — solo, helmet on. Leave your group, or the trial is void the moment you accept. You have one chance.",
	stopConversation = "false",
	options = {
		{"I am ready. Begin the trial.", "trial_start"},
		{"I need more time.", "bye"},
	}
}
mandoSpynetOperativeConvoTemplate:addScreen(trial_ready)

trial_start = ConvoScreen:new {
	id = "trial_start",
	leftDialog = "",
	customDialogText = "Good. The contract details are in your datapad. Stay alone. Stay armed. Finish it.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(trial_start)

-- --------------------------------------------------------
-- TRIAL ALREADY ACTIVE
-- --------------------------------------------------------
trial_active = ConvoScreen:new {
	id = "trial_active",
	leftDialog = "",
	customDialogText = "Your trial is already running. Finish it.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(trial_active)

-- --------------------------------------------------------
-- DAILY CAP REACHED
-- --------------------------------------------------------
daily_cap = ConvoScreen:new {
	id = "daily_cap",
	leftDialog = "",
	customDialogText = "You have reached today's contract limit. Rest. Return tomorrow.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(daily_cap)

-- --------------------------------------------------------
-- CLANBOUND (Chapter 4 complete)
-- --------------------------------------------------------
clanbound = ConvoScreen:new {
	id = "clanbound",
	leftDialog = "",
	customDialogText = "You have done the work. The alignment choice is yours when you are ready. Speak to the recruiter.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(clanbound)

-- --------------------------------------------------------
-- BYE
-- --------------------------------------------------------
bye = ConvoScreen:new {
	id = "bye",
	leftDialog = "",
	customDialogText = "Do not waste my time.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(bye)

addConversationTemplate("mandoSpynetOperativeConvoTemplate", mandoSpynetOperativeConvoTemplate)
