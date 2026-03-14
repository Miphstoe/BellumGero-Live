-- Mandalorian Foundling Informant Conversation Template
-- Per-player NPC spawned on each planet during Chapter 0 arc
-- Two states: accept assignment / turn in after quota met
-- Handler: MandoFoundlingInformantConvoHandler (in bellum/convos/)

mandoFoundlingInformantConvoTemplate = ConvoTemplate:new {
	initialScreen = "intro",
	templateType  = "Lua",
	luaClassHandler = "MandoFoundlingInformantConvoHandler",
	screens = {}
}

-- --------------------------------------------------------
-- INTRO: handler routes to assign or turnin based on state
-- --------------------------------------------------------
intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "",
	customDialogText = "You found me. That is a start.",
	stopConversation = "false",
	options = {
		{"What is my assignment?", "assign"},
		{"I have completed the work.", "check_turnin"},
		{"Nothing.", "bye"},
	}
}
mandoFoundlingInformantConvoTemplate:addScreen(intro)

-- --------------------------------------------------------
-- ASSIGN: player accepts the planet mission quota
-- Handler calls MandoWayOfLife:acceptPlanetAssignment()
-- --------------------------------------------------------
assign = ConvoScreen:new {
	id = "assign",
	leftDialog = "",
	customDialogText = "Destroy contracts. Deliver contracts. Use the mission terminals. No bounty work — that is Guild business, not ours. I will know when you have done enough. Return to this spot when you are finished.",
	stopConversation = "false",
	options = {
		{"Understood. I will begin.", "assign_confirm"},
		{"Not yet.", "bye"},
	}
}
mandoFoundlingInformantConvoTemplate:addScreen(assign)

assign_confirm = ConvoScreen:new {
	id = "assign_confirm",
	leftDialog = "",
	customDialogText = "Your target count has been set. A waypoint to my location is in your datapad. Do not lose it.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(assign_confirm)

-- --------------------------------------------------------
-- ASSIGNMENT ALREADY ACTIVE (player reopens before done)
-- --------------------------------------------------------
already_assigned = ConvoScreen:new {
	id = "already_assigned",
	leftDialog = "",
	customDialogText = "You have your orders. Finish the work before you come back to me.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(already_assigned)

-- --------------------------------------------------------
-- TURN IN CHECK: quota not yet met
-- --------------------------------------------------------
not_done = ConvoScreen:new {
	id = "not_done",
	leftDialog = "",
	customDialogText = "Not enough. Keep working the terminals. Come back when the job is finished.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(not_done)

-- --------------------------------------------------------
-- TURN IN: quota met — handler calls MandoWayOfLife:turnInPlanet()
-- Parting line is delivered by the screenplay as a system message.
-- This screen sends the player to the next planet.
-- --------------------------------------------------------
turnin = ConvoScreen:new {
	id = "turnin",
	leftDialog = "",
	customDialogText = "Done. The next contact is already waiting. You will find them on your next planet. Keep moving.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(turnin)

-- --------------------------------------------------------
-- FINAL TURN IN (planet 10 — Yavin IV)
-- Handler calls MandoWayOfLife:turnInPlanet() which then calls completeFoundlingArc()
-- --------------------------------------------------------
turnin_final = ConvoScreen:new {
	id = "turnin_final",
	leftDialog = "",
	customDialogText = "Ten worlds. Every one of them left a mark on you, whether you noticed or not. Return to the recruiter on Tatooine. What you have earned is waiting.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(turnin_final)

-- --------------------------------------------------------
-- BYE
-- --------------------------------------------------------
bye = ConvoScreen:new {
	id = "bye",
	leftDialog = "",
	customDialogText = "Do not take long.",
	stopConversation = "true",
	options = {}
}
mandoFoundlingInformantConvoTemplate:addScreen(bye)

addConversationTemplate("mandoFoundlingInformantConvoTemplate", mandoFoundlingInformantConvoTemplate)
