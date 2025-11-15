-- Simple 5-question quiz conversation template.
-- You can duplicate this file and rename IDs for more quizzes.

bsv_quiz_convo = ConvoTemplate:new {
  initialScreen = "start",
  templateType = "Lua",
  luaClassHandler = "bsv_quiz_convo_handler",
  screens = {}
}

-- START SCREEN
bsv_quiz_start = ConvoScreen:new {
  id = "start",
  leftDialog = "Accessing Blue Shadow Facility auxiliary terminal...\n\nQuiz protocol online. Answer all questions correctly to receive a reward.",
  stopConversation = "false",
  options = {
    {"Begin the quiz.", "q1"},
    {"Leave the terminal alone.", "exit_no_quiz"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_start)

-- EXIT WITHOUT QUIZ
bsv_quiz_exit_no_quiz = ConvoScreen:new {
  id = "exit_no_quiz",
  leftDialog = "Quiz protocol aborted. Terminal returning to standby.",
  stopConversation = "true",
  options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_exit_no_quiz)

--------------------------------------------------
-- QUESTION 1
--------------------------------------------------
bsv_quiz_q1 = ConvoScreen:new {
  id = "q1",
  -- TODO: replace this text with your real question
  leftDialog = "Question 1:\n\n[PLACEHOLDER] What is stored in the main containment wing of this facility?",
  stopConversation = "false",
  options = {
    -- TODO: replace answers; first one is treated as 'correct' in this template
    {"[CORRECT] Highly volatile biological samples.", "q2"},
    {"Random smuggled goods.", "failed"},
    {"Old droid scrap.", "failed"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_q1)

--------------------------------------------------
-- QUESTION 2
--------------------------------------------------
bsv_quiz_q2 = ConvoScreen:new {
  id = "q2",
  leftDialog = "Question 2:\n\n[PLACEHOLDER] Which section of the bunker contains the medical lab?",
  stopConversation = "false",
  options = {
    {"[CORRECT] The lower research wing.", "q3"},
    {"The main entrance corridor.", "failed"},
    {"The exterior guard post.", "failed"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_q2)

--------------------------------------------------
-- QUESTION 3
--------------------------------------------------
bsv_quiz_q3 = ConvoScreen:new {
  id = "q3",
  leftDialog = "Question 3:\n\n[PLACEHOLDER] What hazard is active throughout most of the facility?",
  stopConversation = "false",
  options = {
    {"[CORRECT] The Blue Shadow Virus gas.", "q4"},
    {"Heavy radiation from the core.", "failed"},
    {"Loose mynocks chewing the power lines.", "failed"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_q3)

--------------------------------------------------
-- QUESTION 4
--------------------------------------------------
bsv_quiz_q4 = ConvoScreen:new {
  id = "q4",
  leftDialog = "Question 4:\n\n[PLACEHOLDER] How can personnel be cured once exposed?",
  stopConversation = "false",
  options = {
    {"[CORRECT] By reaching the medical lab cure station.", "q5"},
    {"By logging out and back in.", "failed"},
    {"By using a generic medpack anywhere.", "failed"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_q4)

--------------------------------------------------
-- QUESTION 5
--------------------------------------------------
bsv_quiz_q5 = ConvoScreen:new {
  id = "q5",
  leftDialog = "Question 5:\n\n[PLACEHOLDER] Who is responsible for maintaining quarantine protocols in this bunker?",
  stopConversation = "false",
  options = {
    {"[CORRECT] The facility's automated security systems.", "all_correct"},
    {"No one. It was abandoned.", "failed"},
    {"The nearest moisture farmer.", "failed"}
  }
}
bsv_quiz_convo:addScreen(bsv_quiz_q5)

--------------------------------------------------
-- ALL CORRECT
--------------------------------------------------
bsv_quiz_all_correct = ConvoScreen:new {
  id = "all_correct",
  leftDialog = "Quiz complete.\n\nAll answers correct. Dispensing authorized reward.",
  stopConversation = "true",  -- conversation will end here; handler will award
  options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_all_correct)

--------------------------------------------------
-- FAILED PATH
--------------------------------------------------
bsv_quiz_failed = ConvoScreen:new {
  id = "failed",
  leftDialog = "Incorrect answer detected.\n\nQuiz protocol terminated. You may attempt again later.",
  stopConversation = "true",
  options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_failed)

-- Register the conversation template
addConversationTemplate("bsv_quiz_convo", bsv_quiz_convo)
