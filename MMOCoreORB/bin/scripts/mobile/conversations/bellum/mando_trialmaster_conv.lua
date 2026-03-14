-- Mandalorian Trialmaster Conversation Template
-- Handles Chapter 0 entry (recruiter) and Chapters 1-4 chapter gate access
-- Handler: MandoTrialmasterConvoHandler (in bellum/convos/)

mandoTrialmasterConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType  = "Lua",
	luaClassHandler = "MandoTrialmasterConvoHandler",
	screens = {}
}

-- --------------------------------------------------------
-- INTRO: branch point — prereqs not met / arc in progress /
--        arc complete (ready for ch1+) / already clanbound
-- --------------------------------------------------------
intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "You're quick to chase a legend. Slower to earn it. What do you want?",
	stopConversation = "false",
	options = {
		{"Tell me about the Mandalorian way.", "explain"},
		{"I am ready to prove myself.", "check_prereqs"},
		{"Nothing.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(intro)

-- --------------------------------------------------------
-- EXPLAIN: lore screen, no gate logic
-- --------------------------------------------------------
explain = ConvoScreen:new {
	id = "explain",
	leftDialog = "",
	customDialogText = "This is not the Guild. Not yet. This is the trial. Scout the wilds, patch your wounds, shoot straight. Prove you can survive before you claim the name. Come back when you are ready.",
	stopConversation = "false",
	options = {
		{"I am ready to prove myself.", "check_prereqs"},
		{"I understand.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(explain)

-- --------------------------------------------------------
-- PREREQS NOT MET
-- --------------------------------------------------------
prereqs_missing = ConvoScreen:new {
	id = "prereqs_missing",
	leftDialog = "",
	customDialogText = "You want plates? Earn the right to wear them. Scout the terrain. Learn to shoot. Carry your own medpac. Come back when you have mastered all three.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(prereqs_missing)

-- --------------------------------------------------------
-- ARC ALREADY STARTED (player has been sent to a planet)
-- --------------------------------------------------------
arc_in_progress = ConvoScreen:new {
	id = "arc_in_progress",
	leftDialog = "",
	customDialogText = "You have your orders. Find the contact on your current planet and complete the work. Do not come back to me until it is done.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(arc_in_progress)

-- --------------------------------------------------------
-- ARC ACCEPT: prereqs met, arc not yet started
-- --------------------------------------------------------
arc_accept = ConvoScreen:new {
	id = "arc_accept",
	leftDialog = "",
	customDialogText = "Ten worlds. Each one will test a different part of you. Complete the work your contact assigns on each planet. Destroy contracts. Deliver contracts. No bounty terminal work — this is not the Guild's business. When the last planet is done, come find me.",
	stopConversation = "false",
	options = {
		{"I accept.", "arc_start"},
		{"Not yet.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(arc_accept)

-- --------------------------------------------------------
-- ARC START: triggers MandoWayOfLife:startFoundlingArc()
-- --------------------------------------------------------
arc_start = ConvoScreen:new {
	id = "arc_start",
	leftDialog = "",
	customDialogText = "Your first contact is on Tatooine. The suns will teach you patience whether you want the lesson or not. Move.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(arc_start)

-- --------------------------------------------------------
-- ARC COMPLETE: Foundling arc done, ready for ch1+ gate
-- (Handler checks Novice BH separately)
-- --------------------------------------------------------
arc_complete_no_bh = ConvoScreen:new {
	id = "arc_complete_no_bh",
	leftDialog = "",
	customDialogText = "You have seen the galaxy. Good. Now train your craft. Come back when you have earned Novice Bounty Hunter through the Guild's terminals.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(arc_complete_no_bh)

-- --------------------------------------------------------
-- CHAPTER GATE: Foundling + Novice BH confirmed
-- Sends player to Operative for 5+1 gate cycle
-- --------------------------------------------------------
chapter_gate_ready = ConvoScreen:new {
	id = "chapter_gate_ready",
	leftDialog = "",
	customDialogText = "The helmet means something now. Find the private network operative. Five spynet contracts through the standard bounty terminals, then one trial only you can pass. The operative will brief you.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(chapter_gate_ready)

-- --------------------------------------------------------
-- CLANBOUND: Chapter 4 complete — endgame gate
-- --------------------------------------------------------
clanbound = ConvoScreen:new {
	id = "clanbound",
	leftDialog = "",
	customDialogText = "The Resol'nare isn't recited. It's lived. Today you lived a piece of it. When you have mastered the bounty hunter craft completely, the alignment choice is yours to make.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(clanbound)

-- --------------------------------------------------------
-- BYE
-- --------------------------------------------------------
bye = ConvoScreen:new {
	id = "bye",
	leftDialog = "",
	customDialogText = "A contract is your word. Break it, and you are no better than your quarry.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(bye)

addConversationTemplate("mandoTrialmasterConvoTemplate", mandoTrialmasterConvoTemplate)
