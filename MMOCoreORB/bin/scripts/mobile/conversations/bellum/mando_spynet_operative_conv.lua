-- Mandalorian Spynet Operative Conversation Template
-- Chapters 1-4: manages the 5+1 gate cycle
-- Requires Foundling Helmet equipped (hat or helmet slot) + gate state
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
-- GO AWAY: player has not started the Mandalorian arc.
-- Send them to the recruiter in the Mos Eisley cantina on Tatooine.
-- --------------------------------------------------------
go_away = ConvoScreen:new {
	id = "go_away",
	leftDialog = "",
	customDialogText = "Spynet has no file on you, and I don't deal with outsiders. If you want this work, go to the Mandalorian Recruiter in the Mos Eisley cantina on Tatooine and earn your way in. Until then, you were never here.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(go_away)

-- --------------------------------------------------------
-- HELMET NOT EQUIPPED
-- --------------------------------------------------------
no_helmet = ConvoScreen:new {
	id = "no_helmet",
	leftDialog = "",
	customDialogText = "No helm. No chain code. No work.",
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
	customDialogText = "I will open your Spynet count. You must then complete five NPC bounty missions accepted from Bounty Hunter mission terminals. Those boards list bounties on NPC marks, not generic destroy or deliver work. When your datapad shows five confirmed, come back for one private trial: solo, Foundling helmet on, no group. Break the rules and you start over. Ready?",
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
	customDialogText = "Spynet count is open. Pull five NPC bounties from Bounty Hunter mission terminals and finish them. Watch your system messages for Spynet contracts x/5.",
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
	customDialogText = "Keep clearing NPC bounties from Bounty Hunter mission terminals until you see five Spynet contracts confirmed. A purple datapad waypoint will mark this spot when you are ready to return for the trial.",
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
	customDialogText = "Five confirmed. Follow the purple waypoint on your datapad if you need to find me again. Now the real work: one private contract, solo, helmet on. Leave your group, or the trial is void the moment you accept. You have one chance.",
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
	customDialogText = "Good. A yellow Spynet bounty camp waypoint is on your datapad under the Quest tab (task waypoint), not the regular Waypoints list. Activate it there, travel to it, and enter the marked area. The camp appears when you arrive. Eliminate the marked outlaw. Stay alone. Stay armed. Helmet on until it is done.",
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
	customDialogText = "Your trial is already running. Finish it. The yellow Spynet bounty camp waypoint is under your datapad Quest tab. Activate it there, then enter that area to load the camp.",
	stopConversation = "false",
	options = {
		{"Remind me how the waypoint works.", "trial_refresh_hint"},
		{"Understood.", "bye"},
	}
}
mandoSpynetOperativeConvoTemplate:addScreen(trial_active)

trial_refresh_hint = ConvoScreen:new {
	id = "trial_refresh_hint",
	leftDialog = "",
	customDialogText = "Open your datapad Quest tab (mission waypoints). Select and activate the yellow Spynet bounty camp waypoint. Go there on foot or speeder, cross into the highlighted radius, and the camp will spawn. Kill the marked outlaw to close the contract. Solo. Helmet on.",
	stopConversation = "true",
	options = {}
}
mandoSpynetOperativeConvoTemplate:addScreen(trial_refresh_hint)

-- --------------------------------------------------------
-- CLANBOUND (Chapter 4 complete)
-- --------------------------------------------------------
clanbound = ConvoScreen:new {
	id = "clanbound",
	leftDialog = "",
	customDialogText = "You have done the work. Return to the Mandalorian Recruiter in the Mos Eisley cantina on Tatooine. They will set your next path when you are ready.",
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
