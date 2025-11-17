-- Blue Shadow Virus random quiz conversation
-- Based on The Clone Wars Season 1 "Blue Shadow Virus" arc.
-- Provides multiple randomized 5-question quizzes for replayability.
-- Correct answers are NOT always the first option.

bsv_quiz_convo = ConvoTemplate:new {
    initialScreen   = "quiz1_start", -- handler will override this
    templateType    = "Lua",
    luaClassHandler = "bsv_quiz_convo_handler",
    screens         = {}
}

--------------------------------------------------
-- COOLDOWN SCREEN (shown if player is locked out)
--------------------------------------------------

bsv_quiz_on_cooldown = ConvoScreen:new {
    id = "on_cooldown",
    leftDialog = "",
    customDialogText = "Blue Shadow Virus quiz access denied.\n\nYou have already completed a quiz recently. Please return after the cooldown period has expired.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_on_cooldown)

--------------------------------------------------
-- QUIZ 1 : Characters & Roles
--------------------------------------------------

bsv_quiz1_start = ConvoScreen:new {
    id = "quiz1_start",
    leftDialog = "",
    customDialogText = "Accessing Blue Shadow Virus holo-archive.\n\nRandomized character quiz protocol initiated. Answer all questions correctly to receive a reward.",
    stopConversation = "false",
    options = {
        {"Begin the quiz.", "quiz1_q1"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_start)

bsv_quiz1_q1 = ConvoScreen:new {
    id = "quiz1_q1",
    leftDialog = "",
    customDialogText = "Question 1:\n\nWho is the mad scientist responsible for reviving the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"Count Dooku.", "quiz1_failed"},
        {"Dr. Nuvo Vindi.", "quiz1_q2"},   -- correct (middle)
        {"General Grievous.", "quiz1_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_q1)

bsv_quiz1_q2 = ConvoScreen:new {
    id = "quiz1_q2",
    leftDialog = "",
    customDialogText = "Question 2:\n\nOn which world do missing farmers lead Padmé to discover the Blue Shadow Virus threat?",
    stopConversation = "false",
    options = {
        {"Ryloth.", "quiz1_failed"},
        {"Tatooine.", "quiz1_failed"},
        {"Naboo.", "quiz1_q3"}             -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_q2)

bsv_quiz1_q3 = ConvoScreen:new {
    id = "quiz1_q3",
    leftDialog = "",
    customDialogText = "Question 3:\n\nWhich Gungan accompanies Padmé into Dr. Vindi's underground lab and causes chaos almost immediately?",
    stopConversation = "false",
    options = {
        {"Jar Jar Binks.", "quiz1_q4"},    -- correct (top)
        {"Captain Tarpals.", "quiz1_failed"},
        {"Boss Nass.", "quiz1_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_q3)

bsv_quiz1_q4 = ConvoScreen:new {
    id = "quiz1_q4",
    leftDialog = "",
    customDialogText = "Question 4:\n\nWhich Jedi Padawan fights beside the clones inside Vindi's lab and later becomes trapped with the infected?",
    stopConversation = "false",
    options = {
        {"Barriss Offee.", "quiz1_failed"},
        {"Ahsoka Tano.", "quiz1_q5"},      -- correct (middle)
        {"Shaak Ti.", "quiz1_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_q4)

bsv_quiz1_q5 = ConvoScreen:new {
    id = "quiz1_q5",
    leftDialog = "",
    customDialogText = "Question 5:\n\nDr. Nuvo Vindi secretly works for which galactic faction?",
    stopConversation = "false",
    options = {
        {"The Hutt Cartel.", "quiz1_failed"},
        {"The Galactic Republic.", "quiz1_failed"},
        {"The Confederacy of Independent Systems (Separatists).", "quiz1_all_correct"} -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(bsv_quiz1_q5)

bsv_quiz1_all_correct = ConvoScreen:new {
    id = "quiz1_all_correct",
    leftDialog = "",
    customDialogText = "Quiz complete.\n\nAll answers correct. Logging successful knowledge of Blue Shadow Virus characters.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz1_all_correct)

bsv_quiz1_failed = ConvoScreen:new {
    id = "quiz1_failed",
    leftDialog = "",
    customDialogText = "Incorrect answer detected.\n\nCharacter quiz protocol terminated. You may attempt another quiz later.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz1_failed)

--------------------------------------------------
-- QUIZ 2 : Virus Properties & Threat
--------------------------------------------------

bsv_quiz2_start = ConvoScreen:new {
    id = "quiz2_start",
    leftDialog = "",
    customDialogText = "Accessing Blue Shadow Virus holo-archive.\n\nRandomized containment quiz protocol initiated. Answer all questions correctly to receive a reward.",
    stopConversation = "false",
    options = {
        {"Begin the quiz.", "quiz2_q1"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_start)

bsv_quiz2_q1 = ConvoScreen:new {
    id = "quiz2_q1",
    leftDialog = "",
    customDialogText = "Question 1:\n\nBefore Dr. Vindi revived it, what was the status of the Blue Shadow Virus in galactic history?",
    stopConversation = "false",
    options = {
        {"It was a common but mild illness.", "quiz2_failed"},
        {"It had only just been discovered for the first time.", "quiz2_failed"},
        {"It was believed to have been eradicated long ago.", "quiz2_q2"}  -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_q1)

bsv_quiz2_q2 = ConvoScreen:new {
    id = "quiz2_q2",
    leftDialog = "",
    customDialogText = "Question 2:\n\nIn its original form, how did the Blue Shadow Virus primarily spread?",
    stopConversation = "false",
    options = {
        {"Through sound waves that damaged cells.", "quiz2_failed"},
        {"Through contaminated water sources.", "quiz2_q3"},                -- correct (middle)
        {"Through droid circuitry.", "quiz2_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_q2)

bsv_quiz2_q3 = ConvoScreen:new {
    id = "quiz2_q3",
    leftDialog = "",
    customDialogText = "Question 3:\n\nWhat is Dr. Vindi's primary \"achievement\" with the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"He turns it into a cure for other diseases.", "quiz2_failed"},
        {"He makes it glow in the dark for easy tracking.", "quiz2_failed"},
        {"He makes it airborne so it can blanket entire worlds.", "quiz2_q4"} -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_q3)

bsv_quiz2_q4 = ConvoScreen:new {
    id = "quiz2_q4",
    leftDialog = "",
    customDialogText = "Question 4:\n\nWhat does Vindi rig his underground lab with in order to disperse the virus across Naboo?",
    stopConversation = "false",
    options = {
        {"Atmospheric ion cannons.", "quiz2_failed"},
        {"Bombs and canisters tied to remote detonators.", "quiz2_q5"},      -- correct (middle)
        {"A hyperspace beacon that drags the virus across the planet.", "quiz2_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_q4)

bsv_quiz2_q5 = ConvoScreen:new {
    id = "quiz2_q5",
    leftDialog = "",
    customDialogText = "Question 5:\n\nWithout a cure, what happens to those infected with the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"They slowly turn into mindless undead.", "quiz2_failed"},
        {"They die within a few hours.", "quiz2_all_correct"},               -- correct (middle)
        {"They fall into an endless sleep but never die.", "quiz2_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz2_q5)

bsv_quiz2_all_correct = ConvoScreen:new {
    id = "quiz2_all_correct",
    leftDialog = "",
    customDialogText = "Quiz complete.\n\nAll answers correct. Logging successful knowledge of Blue Shadow Virus properties.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz2_all_correct)

bsv_quiz2_failed = ConvoScreen:new {
    id = "quiz2_failed",
    leftDialog = "",
    customDialogText = "Incorrect answer detected.\n\nContainment quiz protocol terminated. You may attempt another quiz later.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz2_failed)

--------------------------------------------------
-- QUIZ 3 : Iego & the Cure
--------------------------------------------------

bsv_quiz3_start = ConvoScreen:new {
    id = "quiz3_start",
    leftDialog = "",
    customDialogText = "Accessing Blue Shadow Virus holo-archive.\n\nRandomized antidote quiz protocol initiated. Answer all questions correctly to receive a reward.",
    stopConversation = "false",
    options = {
        {"Begin the quiz.", "quiz3_q1"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_start)

bsv_quiz3_q1 = ConvoScreen:new {
    id = "quiz3_q1",
    leftDialog = "",
    customDialogText = "Question 1:\n\nOn which remote world do Anakin and Obi-Wan search for the cure to the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"Felucia.", "quiz3_failed"},
        {"Iego.", "quiz3_q2"},                      -- correct (middle)
        {"Dathomir.", "quiz3_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_q1)

bsv_quiz3_q2 = ConvoScreen:new {
    id = "quiz3_q2",
    leftDialog = "",
    customDialogText = "Question 2:\n\nWhat deadly obstacle destroys ships that try to leave Iego?",
    stopConversation = "false",
    options = {
        {"A Republic blockade that fires on any unauthorized vessel.", "quiz3_failed"},
        {"An automated Separatist laser defense grid around the planet.", "quiz3_q3"}, -- correct (middle)
        {"A massive living space creature that feeds on starships.", "quiz3_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_q2)

bsv_quiz3_q3 = ConvoScreen:new {
    id = "quiz3_q3",
    leftDialog = "",
    customDialogText = "Question 3:\n\nWhat is the name of the young tinkerer surrounded by reprogrammed droids on Iego?",
    stopConversation = "false",
    options = {
        {"Kitster Banai.", "quiz3_failed"},
        {"Jaybo Hood.", "quiz3_q4"},                -- correct (middle)
        {"Milo Thatch.", "quiz3_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_q3)

bsv_quiz3_q4 = ConvoScreen:new {
    id = "quiz3_q4",
    leftDialog = "",
    customDialogText = "Question 4:\n\nFrom what dangerous plant do Anakin and Obi-Wan harvest the ingredient needed for the antidote?",
    stopConversation = "false",
    options = {
        {"The carnivorous Reeksa plant.", "quiz3_q5"}, -- correct (top)
        {"The legendary Sarlacc bloom.", "quiz3_failed"},
        {"The rare Malastare poppy.", "quiz3_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_q4)

bsv_quiz3_q5 = ConvoScreen:new {
    id = "quiz3_q5",
    leftDialog = "",
    customDialogText = "Question 5:\n\nWhy is Anakin desperate to escape Iego quickly with the cure?",
    stopConversation = "false",
    options = {
        {"Padmé, Ahsoka, and the clones on Naboo will die soon without it.", "quiz3_all_correct"}, -- correct (top)
        {"The Jedi Council has ordered him back to Coruscant for a promotion.", "quiz3_failed"},
        {"Iego's sun is about to go supernova.", "quiz3_failed"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz3_q5)

bsv_quiz3_all_correct = ConvoScreen:new {
    id = "quiz3_all_correct",
    leftDialog = "",
    customDialogText = "Quiz complete.\n\nAll answers correct. Logging successful knowledge of Iego and the Blue Shadow Virus cure.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz3_all_correct)

bsv_quiz3_failed = ConvoScreen:new {
    id = "quiz3_failed",
    leftDialog = "",
    customDialogText = "Incorrect answer detected.\n\nAntidote quiz protocol terminated. You may attempt another quiz later.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz3_failed)

--------------------------------------------------
-- REGISTER TEMPLATE
--------------------------------------------------
addConversationTemplate("bsv_quiz_convo", bsv_quiz_convo)
