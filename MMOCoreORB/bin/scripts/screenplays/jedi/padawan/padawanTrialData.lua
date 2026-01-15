-- ============================================================================
-- PADAWAN TRIALS: 5-TIER SYSTEM DATA
-- Separate data file for Padawan Trials (does not modify main trialData.lua)
-- ============================================================================

-- Padawan Trials Phase Configuration
-- Each phase requires 5,000 PvE points
-- Plus: Trivia questions and special requirements (Phase 3: lightsaber crafting)

PADAWAN_TRIALS_PHASE_POINTS = 5000
PADAWAN_TRIALS_TOTAL_PHASES = 5
PADAWAN_TRIALS_TOTAL_REQUIRED_POINTS = 25000  -- 5 phases × 5,000 points

-- Milestone notifications for player progress
padawanTrialMilestones = {
	{ phase = 1, points = 5000, message = "Phase 1 complete! Hunt and grow stronger." },
	{ phase = 2, points = 10000, message = "Phase 2 complete! You are 40% of the way to Padawan status." },
	{ phase = 3, points = 15000, message = "Phase 3 complete! You are halfway to Padawan status." },
	{ phase = 4, points = 20000, message = "Phase 4 complete! One final phase remains." },
	{ phase = 5, points = 25000, message = "All phases complete! You are ready to claim your Padawan status!" }
}

-- Phase-specific messages
padawanPhaseMessages = {
	[1] = {
		trivia_intro = "Demonstrate your knowledge of the Jedi path. Answer three questions correctly.",
		trivia_success = "You have proven your knowledge. Now go forth and test yourself in battle.",
		trivia_failure = "Your answer was incorrect. Meditate and try again.",
		hunting_progress = "Continue your hunt. You need 5,000 points to advance.",
		hunting_complete = "You have gathered sufficient strength. Return to the shrine for the next trial."
	},
	[2] = {
		trivia_intro = "Your knowledge must grow deeper. Answer three more questions correctly.",
		trivia_success = "Your understanding of the Jedi path expands. Continue your hunt.",
		trivia_failure = "Your answer was incorrect. Meditate and try again.",
		hunting_progress = "Continue hunting. Gather 5,000 more points.",
		hunting_complete = "Your progression is evident. Return to the shrine for the next trial."
	},
	[3] = {
		trivia_intro = "Prove your mental discipline with three more questions.",
		trivia_success = "You have demonstrated mastery. Now you must craft your lightsaber.",
		trivia_failure = "Your answer was incorrect. Meditate and try again.",
		crafting_prompt = "You must craft a lightsaber and tune a Force crystal. Return when complete.",
		hunting_progress = "With your lightsaber complete, continue your hunt for 5,000 more points.",
		hunting_complete = "You have proven yourself in combat. Return to the shrine for the final trials."
	},
	[4] = {
		trivia_intro = "Your understanding of the Force deepens. Answer three more questions.",
		trivia_success = "Your wisdom grows. Complete the final hunt.",
		trivia_failure = "Your answer was incorrect. Meditate and try again.",
		hunting_progress = "Nearly there. Gather 5,000 more points.",
		hunting_complete = "One final trial awaits. Return to the shrine."
	},
	[5] = {
		trivia_intro = "This is your final test of knowledge. Answer three questions correctly.",
		trivia_success = "You are nearly ready. Complete your final hunt to claim your place as a Padawan.",
		trivia_failure = "Your answer was incorrect. Meditate and try again.",
		hunting_progress = "The final stretch. Gather 5,000 more points and claim your destiny.",
		hunting_complete = "You have completed the Padawan Trials! Return to the shrine to claim your rank."
	}
}

-- Padawan robe templates (placed in inventory upon completion)
PADAWAN_ROBE_LIGHT = "object/tangible/wearables/robe/robe_jedi_padawan.iff"
PADAWAN_ROBE_DARK = "object/tangible/wearables/robe/robe_jedi_padawan_dark.iff"

-- Level-based point tiers (same as Knight Trials)
padawanTrialLevelPointTiers = {
	{ minLevel = 0, maxLevel = 29, points = 1 },
	{ minLevel = 30, maxLevel = 59, points = 2 },
	{ minLevel = 60, maxLevel = 89, points = 5 },
	{ minLevel = 90, maxLevel = 129, points = 10 },
	{ minLevel = 130, maxLevel = 169, points = 15 },
	{ minLevel = 170, maxLevel = 209, points = 20 },
	{ minLevel = 210, maxLevel = 249, points = 25 },
	{ minLevel = 250, maxLevel = 289, points = 30 },
	{ minLevel = 290, maxLevel = 350, points = 35 }
}
