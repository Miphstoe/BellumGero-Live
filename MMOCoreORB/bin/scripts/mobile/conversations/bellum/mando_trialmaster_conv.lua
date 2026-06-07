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
	customDialogText = "You want plates? Earn the right to wear them. Scout the terrain. Learn to shoot. Carry your own medpac. Or train Novice Bounty Hunter if you already walk the hunt. Come back when one path is complete.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(prereqs_missing)

-- --------------------------------------------------------
-- ARC ALREADY STARTED (player has been sent to a planet)
-- Options: status in system chat; forced resync respawns private informant + waypoints (Lua handlers).
-- --------------------------------------------------------
arc_in_progress = ConvoScreen:new {
	id = "arc_in_progress",
	leftDialog = "",
	customDialogText = "You have your orders. Find the contact on your current planet and complete the work. If your datapad or contact failed, use the options below. I will not repeat the full briefing.",
	stopConversation = "false",
	options = {
		{"What is my status?", "foundling_status"},
		{"My contact or waypoint is broken. Reset them.", "foundling_resync"},
		{"Understood.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(arc_in_progress)

foundling_status = ConvoScreen:new {
	id = "foundling_status",
	leftDialog = "",
	customDialogText = "I have sent a status report to your system messages. Read it and move.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(foundling_status)

-- Post–Foundling arc + Spynet: same Lua handler as !foundling in Say (no client slash command needed).
mando_way_status = ConvoScreen:new {
	id = "mando_way_status",
	leftDialog = "",
	customDialogText = "I have sent your chapter and Spynet gate lines to system messages. Read them.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(mando_way_status)

foundling_resync = ConvoScreen:new {
	id = "foundling_resync",
	leftDialog = "",
	customDialogText = "Done. Your contact has been placed again and your datapad waypoint refreshed for this world's state. Do not waste my time again.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(foundling_resync)

-- --------------------------------------------------------
-- ARC ACCEPT: prereqs met, arc not yet started
-- --------------------------------------------------------
arc_accept = ConvoScreen:new {
	id = "arc_accept",
	leftDialog = "",
	customDialogText = "Ten worlds. Each one will test a different part of you. Your contact on each planet will give you work. Destroy missions. Delivery runs. Standard terminals only. This is Mandalorian proving, not Guild business. When the last planet is done, come find me.",
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
	stopConversation = "false",
	options = {
		{"What is my Mandalorian Way status?", "mando_way_status"},
		{"Understood.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(arc_complete_no_bh)

-- --------------------------------------------------------
-- CHAPTER GATE: Foundling + Novice BH confirmed
-- Sends player to Operative for 5+1 gate cycle
-- --------------------------------------------------------
chapter_gate_ready = ConvoScreen:new {
	id = "chapter_gate_ready",
	leftDialog = "",
	customDialogText = "The helmet means something now, and the next gate is exacting. On Corellia, speak with the Mandalorian Operative at the blue datapad waypoint I am giving you; they must open your Spynet count before anything tracks. Then complete five NPC bounty missions from Bounty Hunter mission terminals (yellow waypoint: Tyrena guild; any valid BH terminal works once the count is live). Return to the same operative for one private trial contract, solo, Foundling helmet on. Your system message lists the order again. Do not skip steps.",
	stopConversation = "false",
	options = {
		{"What is my Mandalorian Way status?", "mando_way_status"},
		{"Understood.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(chapter_gate_ready)

-- --------------------------------------------------------
-- CLANBOUND: Chapter 4 complete — endgame gate
-- --------------------------------------------------------
clanbound = ConvoScreen:new {
	id = "clanbound",
	leftDialog = "",
	customDialogText = "The Resol'nare isn't recited. It's lived. Today you lived a piece of it. When you have mastered the bounty hunter craft completely, the alignment choice is yours to make.",
	stopConversation = "false",
	options = {
		{"What's next?", "clanbound_whats_next"},
		{"What is my Mandalorian Way status?", "mando_way_status"},
		{"Understood.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(clanbound)

clanbound_whats_next = ConvoScreen:new {
	id = "clanbound_whats_next",
	leftDialog = "",
	customDialogText = "Listen.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(clanbound_whats_next)

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

-- Mandalorian Way armory: loot schematics (weaponsmith master required to use), sold after matching chapter trial.
mando_armory_shop = ConvoScreen:new {
	id = "mando_armory_shop",
	leftDialog = "",
	customDialogText = "I keep sealed clan armory schematics for those on the Way. You already received the gift weapon when you passed each trial; buy these for a weaponsmith to experiment for better assemblies. Initiate: Geo blaster pistol. Hunter: Nym slugthrower carbine. Verd'ika: light lightning cannon. Cash only.",
	stopConversation = "false",
	options = {
		{"Mandalorian Geo blaster schematic (125000 credits).", "buy_mando_armory_1"},
		{"Mandalorian slugthrower schematic (125000 credits).", "buy_mando_armory_2"},
		{"Mandalorian lightning cannon schematic (125000 credits).", "buy_mando_armory_3"},
		{"Back.", "tribesman_hub"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(mando_armory_shop)

-- Tribesman hub: landing screen for a finished Mandalorian Tribesman (e.g. "Back" out of the armory).
-- Only reachable from the armory shop, which itself is gated to chapter5Complete, so the armory option here never leaks.
tribesman_hub = ConvoScreen:new {
	id = "tribesman_hub",
	leftDialog = "",
	customDialogText = "Anything else, Tribesman? You have walked the whole Way.",
	stopConversation = "false",
	options = {
		{"What is my Mandalorian Way status?", "mando_way_status"},
		{"Armory schematics.", "mando_armory_shop"},
		{"Nothing.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(tribesman_hub)

buy_mando_armory_1 = ConvoScreen:new {
	id = "buy_mando_armory_1",
	leftDialog = "",
	customDialogText = "Processing.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(buy_mando_armory_1)

buy_mando_armory_2 = ConvoScreen:new {
	id = "buy_mando_armory_2",
	leftDialog = "",
	customDialogText = "Processing.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(buy_mando_armory_2)

buy_mando_armory_3 = ConvoScreen:new {
	id = "buy_mando_armory_3",
	leftDialog = "",
	customDialogText = "Processing.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(buy_mando_armory_3)

-- Recruiter-only (handler): one-time per login account reissue of all chapter armor sets.
mando_armor_retro = ConvoScreen:new {
	id = "mando_armor_retro",
	leftDialog = "",
	customDialogText = "For veterans of the Way: I can reissue every rank armor set once per login account — Foundling helmet through the full Tribesman panoply — using today's resist values. You need twenty free inventory slots. Another character on your account cannot claim this again.",
	stopConversation = "false",
	options = {
		{"Grant the armor sets.", "mando_armor_retro_grant"},
		{"Not now.", "bye"},
	}
}
mandoTrialmasterConvoTemplate:addScreen(mando_armor_retro)

mando_armor_retro_grant = ConvoScreen:new {
	id = "mando_armor_retro_grant",
	leftDialog = "",
	customDialogText = "Processing.",
	stopConversation = "true",
	options = {}
}
mandoTrialmasterConvoTemplate:addScreen(mando_armor_retro_grant)

addConversationTemplate("mandoTrialmasterConvoTemplate", mandoTrialmasterConvoTemplate)
