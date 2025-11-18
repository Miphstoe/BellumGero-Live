-- bsv_quiz_convo.lua
-- Randomized 5-question quiz using static ConvoScreens.
-- Handler: bsv_quiz_convo_handler.lua

bsv_quiz_convo = ConvoTemplate:new {
    initialScreen = "intro",
    templateType = "Lua",
    luaClassHandler = "bsv_quiz_convo_handler",
    screens = {}
}

---------------------------------------------------------
-- COOLDOWN SCREEN
---------------------------------------------------------

bsv_quiz_on_cooldown = ConvoScreen:new {
    id = "on_cooldown",
    leftDialog = "",
    customDialogText = "This unit has recently administered an assessment to you.\n\nCooldown protocol is still in effect. Please return once the waiting period has elapsed.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_on_cooldown)

---------------------------------------------------------
-- INTRO SCREEN
---------------------------------------------------------

bsv_quiz_intro = ConvoScreen:new {
    id = "intro",
    leftDialog = "",
    customDialogText = "Diagnostic systems online.\n\nThis unit is authorized to administer a randomized galactic knowledge assessment.\n\nAnswer five questions correctly in succession to receive a reward.",
    stopConversation = "false",
    options = {
        {"Begin the assessment.", "q_correct"}
    }
}
bsv_quiz_convo:addScreen(bsv_quiz_intro)

---------------------------------------------------------
-- CONTROL SCREENS (never actually shown; handler uses them as markers)
---------------------------------------------------------

bsv_quiz_q_correct = ConvoScreen:new {
    id = "q_correct",
    leftDialog = "",
    customDialogText = "Input accepted. Proceeding.",
    stopConversation = "false",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_q_correct)

bsv_quiz_q_failed = ConvoScreen:new {
    id = "q_failed",
    leftDialog = "",
    customDialogText = "Input rejected. Assessment terminated.",
    stopConversation = "false",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_q_failed)

---------------------------------------------------------
-- FINAL RESULT SCREENS
---------------------------------------------------------

bsv_quiz_success = ConvoScreen:new {
    id = "quiz_success",
    leftDialog = "",
    customDialogText = "Assessment complete.\n\nAll responses verified as correct. Dispensing authorized reward.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_success)

bsv_quiz_failure = ConvoScreen:new {
    id = "quiz_failed",
    leftDialog = "",
    customDialogText = "Assessment failed.\n\nYou may attempt another evaluation at your discretion.",
    stopConversation = "true",
    options = {}
}
bsv_quiz_convo:addScreen(bsv_quiz_failure)

---------------------------------------------------------
-- QUESTION SCREENS (q001 .. q020)
-- Correct answers -> "q_correct"
-- Incorrect answers -> "q_failed"
---------------------------------------------------------

-- 001
q001 = ConvoScreen:new {
    id = "q001",
    leftDialog = "",
    customDialogText = "Who recreated the legendary Blue Shadow Virus during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Count Dooku", "q_failed"},
        {"Dr. Nuvo Vindi", "q_correct"},  -- correct (middle)
        {"General Grievous", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q001)

-- 002
q002 = ConvoScreen:new {
    id = "q002",
    leftDialog = "",
    customDialogText = "On which world does Padme discover Dr. Vindi's underground virus laboratory?",
    stopConversation = "false",
    options = {
        {"Tatooine", "q_failed"},
        {"Felucia", "q_failed"},
        {"Naboo", "q_correct"}            -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(q002)

-- 003
q003 = ConvoScreen:new {
    id = "q003",
    leftDialog = "",
    customDialogText = "Which Gungan accompanies Padme into the Blue Shadow Virus lab and causes chaos almost immediately?",
    stopConversation = "false",
    options = {
        {"Jar Jar Binks", "q_correct"},   -- correct (top)
        {"Captain Tarpals", "q_failed"},
        {"Boss Nass", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q003)

-- 004
q004 = ConvoScreen:new {
    id = "q004",
    leftDialog = "",
    customDialogText = "Before Dr. Vindi's experiments, how was the Blue Shadow Virus primarily transmitted?",
    stopConversation = "false",
    options = {
        {"Through droid circuitry", "q_failed"},
        {"Through contaminated water sources", "q_correct"}, -- correct (middle)
        {"Through sound waves", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q004)

-- 005
q005 = ConvoScreen:new {
    id = "q005",
    leftDialog = "",
    customDialogText = "What deadly improvement does Dr. Vindi make to the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"He makes it glow in the dark", "q_failed"},
        {"He makes it airborne", "q_correct"},               -- correct (middle)
        {"He turns it into a truth serum", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q005)

-- 006
q006 = ConvoScreen:new {
    id = "q006",
    leftDialog = "",
    customDialogText = "Which Jedi Padawan becomes trapped inside the infected lab with the clones and Padme?",
    stopConversation = "false",
    options = {
        {"Barriss Offee", "q_failed"},
        {"Ahsoka Tano", "q_correct"},                        -- correct (middle)
        {"Shaak Ti", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q006)

-- 007
q007 = ConvoScreen:new {
    id = "q007",
    leftDialog = "",
    customDialogText = "Where do Anakin and Obi-Wan travel to obtain the cure for the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"Iego", "q_correct"},                               -- correct (top)
        {"Mustafar", "q_failed"},
        {"Coruscant", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q007)

-- 008
q008 = ConvoScreen:new {
    id = "q008",
    leftDialog = "",
    customDialogText = "What dangerous plant on Iego contains the ingredient needed for the antidote?",
    stopConversation = "false",
    options = {
        {"The Sarlacc bloom", "q_failed"},
        {"The carnivorous Reeksa plant", "q_correct"},       -- correct (middle)
        {"The Malastare poppy", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q008)

-- 009
q009 = ConvoScreen:new {
    id = "q009",
    leftDialog = "",
    customDialogText = "What threat destroys ships that try to leave Iego during the Blue Shadow Virus arc?",
    stopConversation = "false",
    options = {
        {"A Republic blockade", "q_failed"},
        {"A living space creature around the planet", "q_failed"},
        {"An automated Separatist laser defense grid", "q_correct"} -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(q009)

-- 010
q010 = ConvoScreen:new {
    id = "q010",
    leftDialog = "",
    customDialogText = "Who is the young tinkerer on Iego surrounded by reprogrammed droids?",
    stopConversation = "false",
    options = {
        {"Kitster Banai", "q_failed"},
        {"Jaybo Hood", "q_correct"},                         -- correct (middle)
        {"Hondo Ohnaka", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q010)

-- 011
q011 = ConvoScreen:new {
    id = "q011",
    leftDialog = "",
    customDialogText = "Without a cure, how long do victims of the Blue Shadow Virus have before death?",
    stopConversation = "false",
    options = {
        {"Several weeks", "q_failed"},
        {"Only a few hours", "q_correct"},                   -- correct (middle)
        {"Many years", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q011)

-- 012
q012 = ConvoScreen:new {
    id = "q012",
    leftDialog = "",
    customDialogText = "Who secretly employs Dr. Nuvo Vindi to weaponize the Blue Shadow Virus?",
    stopConversation = "false",
    options = {
        {"The Jedi Council", "q_failed"},
        {"The Separatists", "q_correct"},                    -- correct (middle)
        {"The Hutt Cartel", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q012)

-- 013
q013 = ConvoScreen:new {
    id = "q013",
    leftDialog = "",
    customDialogText = "Which clone captain frequently fights alongside Anakin Skywalker during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Commander Cody", "q_failed"},
        {"Commander Fox", "q_failed"},
        {"Captain Rex", "q_correct"}                         -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(q013)

-- 014
q014 = ConvoScreen:new {
    id = "q014",
    leftDialog = "",
    customDialogText = "What is the traditional Mandalorian armor called in their own language?",
    stopConversation = "false",
    options = {
        {"Beskar'gam", "q_correct"},                         -- correct (top)
        {"Kar'taylur", "q_failed"},
        {"Ne'tra Beskad", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q014)

-- 015
q015 = ConvoScreen:new {
    id = "q015",
    leftDialog = "",
    customDialogText = "Which weapon symbolizes leadership over Mandalore?",
    stopConversation = "false",
    options = {
        {"The Beskar Pike", "q_failed"},
        {"The Darksaber", "q_correct"},                      -- correct (middle)
        {"The Mythosaur Axe", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q015)

-- 016
q016 = ConvoScreen:new {
    id = "q016",
    leftDialog = "",
    customDialogText = "What is the designation of the standard Separatist battle droids seen throughout the Clone Wars?",
    stopConversation = "false",
    options = {
        {"IG-88 Assassin Droids", "q_failed"},
        {"B1 Battle Droids", "q_correct"},                   -- correct (middle)
        {"R2 Astromech Droids", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q016)

-- 017
q017 = ConvoScreen:new {
    id = "q017",
    leftDialog = "",
    customDialogText = "What type of droid is a Droideka?",
    stopConversation = "false",
    options = {
        {"Destroyer Droid", "q_correct"},                    -- correct (top)
        {"Protocol Droid", "q_failed"},
        {"Medical Droid", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q017)

-- 018
q018 = ConvoScreen:new {
    id = "q018",
    leftDialog = "",
    customDialogText = "Which starfighter is commonly used by the Republic during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"X-wing starfighter", "q_failed"},
        {"ARC-170 starfighter", "q_correct"},                -- correct (middle)
        {"TIE Interceptor", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q018)

-- 019
q019 = ConvoScreen:new {
    id = "q019",
    leftDialog = "",
    customDialogText = "What color lightsaber blade is most often associated with Jedi Consulars?",
    stopConversation = "false",
    options = {
        {"Red", "q_failed"},
        {"Green", "q_correct"},                              -- correct (middle)
        {"Yellow", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q019)

-- 020
q020 = ConvoScreen:new {
    id = "q020",
    leftDialog = "",
    customDialogText = "Who trained Obi-Wan Kenobi as a Jedi Padawan?",
    stopConversation = "false",
    options = {
        {"Mace Windu", "q_failed"},
        {"Qui-Gon Jinn", "q_correct"},                       -- correct (middle)
        {"Plo Koon", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q020)

-- 021
q021 = ConvoScreen:new {
    id = "q021",
    leftDialog = "",
    customDialogText = "What is Captain Rex's official clone designation?",
    stopConversation = "false",
    options = {
        {"CT-7567", "q_correct"},          -- correct (top)
        {"CC-2224", "q_failed"},
        {"CT-9904", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q021)

-- 022
q022 = ConvoScreen:new {
    id = "q022",
    leftDialog = "",
    customDialogText = "Which Jedi General does Captain Rex primarily serve under?",
    stopConversation = "false",
    options = {
        {"General Plo Koon", "q_failed"},
        {"Anakin Skywalker", "q_correct"}, -- correct (middle)
        {"Aayla Secura", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q022)

-- 023
q023 = ConvoScreen:new {
    id = "q023",
    leftDialog = "",
    customDialogText = "Which clone trooper served as Rex's second-in-command for much of the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Fives", "q_failed"},
        {"Jesse", "q_failed"},
        {"Sergeant Appo", "q_correct"}     -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(q023)

-- 024
q024 = ConvoScreen:new {
    id = "q024",
    leftDialog = "",
    customDialogText = "What is Commander Cody's official clone designation?",
    stopConversation = "false",
    options = {
        {"CC-3636", "q_failed"},
        {"CC-2224", "q_correct"},          -- correct (middle)
        {"CT-411", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q024)

-- 025
q025 = ConvoScreen:new {
    id = "q025",
    leftDialog = "",
    customDialogText = "Commander Cody famously serves which Jedi General?",
    stopConversation = "false",
    options = {
        {"Ki-Adi-Mundi", "q_failed"},
        {"Obi-Wan Kenobi", "q_correct"},   -- correct (middle)
        {"Yoda", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q025)

-- 026
q026 = ConvoScreen:new {
    id = "q026",
    leftDialog = "",
    customDialogText = "Which elite clone squad does Fives serve in before joining the 501st?",
    stopConversation = "false",
    options = {
        {"Clone Force 99", "q_failed"},
        {"Domino Squad", "q_correct"},      -- correct (middle)
        {"Wolfpack Squad", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q026)

-- 027
q027 = ConvoScreen:new {
    id = "q027",
    leftDialog = "",
    customDialogText = "Which Clone Wars battle features Cody and Obi-Wan fighting against General Grievous on his homeworld?",
    stopConversation = "false",
    options = {
        {"Battle of Utapau", "q_correct"},  -- correct (top)
        {"Battle of Kamino", "q_failed"},
        {"Battle of Geonosis", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q027)

-- 028
q028 = ConvoScreen:new {
    id = "q028",
    leftDialog = "",
    customDialogText = "What color is Captain Rex's Phase II helmet pattern?",
    stopConversation = "false",
    options = {
        {"Blue markings", "q_correct"},     -- correct (top)
        {"Orange markings", "q_failed"},
        {"Green markings", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q028)

-- 029
q029 = ConvoScreen:new {
    id = "q029",
    leftDialog = "",
    customDialogText = "Which clone battalion is Commander Cody in charge of?",
    stopConversation = "false",
    options = {
        {"501st Legion", "q_failed"},
        {"212th Attack Battalion", "q_correct"}, -- correct (middle)
        {"104th Battalion", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q029)

-- 030
q030 = ConvoScreen:new {
    id = "q030",
    leftDialog = "",
    customDialogText = "What regiment does Captain Rex lead within the 501st?",
    stopConversation = "false",
    options = {
        {"The Torrent Company", "q_correct"},    -- correct (top)
        {"The Bad Batch", "q_failed"},
        {"The Wolfpack", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q030)

-- 031
q031 = ConvoScreen:new {
    id = "q031",
    leftDialog = "",
    customDialogText = "Which Jedi served as the Grand Master of the Jedi Order during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Mace Windu", "q_failed"},
        {"Yoda", "q_correct"},             -- correct (middle)
        {"Ki-Adi-Mundi", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q031)

-- 032
q032 = ConvoScreen:new {
    id = "q032",
    leftDialog = "",
    customDialogText = "What is the preferred lightsaber form of Mace Windu?",
    stopConversation = "false",
    options = {
        {"Form VII – Vaapad", "q_correct"}, -- correct (top)
        {"Form IV – Ataru", "q_failed"},
        {"Form II – Makashi", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q032)

-- 033
q033 = ConvoScreen:new {
    id = "q033",
    leftDialog = "",
    customDialogText = "Which Sith Lord was once a Jedi Master and historian named Dooku?",
    stopConversation = "false",
    options = {
        {"Darth Tenebrous", "q_failed"},
        {"Darth Tyranus", "q_correct"},    -- correct (middle)
        {"Darth Ruin", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q033)

-- 034
q034 = ConvoScreen:new {
    id = "q034",
    leftDialog = "",
    customDialogText = "Which Jedi Master was known for her ability to heal using the Force?",
    stopConversation = "false",
    options = {
        {"Luminara Unduli", "q_correct"},   -- correct (top)
        {"Aayla Secura", "q_failed"},
        {"Barriss Offee", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q034)

-- 035
q035 = ConvoScreen:new {
    id = "q035",
    leftDialog = "",
    customDialogText = "What rare kyber crystal color is most associated with Jedi Temple Guards?",
    stopConversation = "false",
    options = {
        {"Yellow", "q_correct"},            -- correct (top)
        {"Blue", "q_failed"},
        {"Purple", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q035)

-- 036
q036 = ConvoScreen:new {
    id = "q036",
    leftDialog = "",
    customDialogText = "Which Sith apprentice wielded a double-bladed lightsaber during the Clone Wars era?",
    stopConversation = "false",
    options = {
        {"Savage Opress", "q_correct"},     -- correct (top)
        {"Darth Malak", "q_failed"},
        {"Darth Bane", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q036)

-- 037
q037 = ConvoScreen:new {
    id = "q037",
    leftDialog = "",
    customDialogText = "Which ancient Sith Lord's holocron was sought after by both Jedi and Sith?",
    stopConversation = "false",
    options = {
        {"Darth Revan", "q_failed"},
        {"Darth Sidious", "q_failed"},
        {"Darth Bane", "q_correct"}         -- correct (bottom)
    }
}
bsv_quiz_convo:addScreen(q037)

-- 038
q038 = ConvoScreen:new {
    id = "q038",
    leftDialog = "",
    customDialogText = "Which Jedi Master was famous for his mastery of Form II lightsaber combat?",
    stopConversation = "false",
    options = {
        {"Count Dooku", "q_correct"},       -- correct (top)
        {"Plo Koon", "q_failed"},
        {"Saesee Tiin", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q038)

-- 039
q039 = ConvoScreen:new {
    id = "q039",
    leftDialog = "",
    customDialogText = "Who was Anakin Skywalker's Jedi Padawan during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Ahsoka Tano", "q_correct"},       -- correct (top)
        {"Ezra Bridger", "q_failed"},
        {"Barriss Offee", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q039)

-- 040
q040 = ConvoScreen:new {
    id = "q040",
    leftDialog = "",
    customDialogText = "Which Sith Lord orchestrated the Clone Wars from behind the scenes?",
    stopConversation = "false",
    options = {
        {"Darth Sidious", "q_correct"},     -- correct (top)
        {"Darth Maul", "q_failed"},
        {"Darth Traya", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q040)

-- 041
q041 = ConvoScreen:new {
    id = "q041",
    leftDialog = "",
    customDialogText = "Which bounty hunter trained the young Boba Fett after Jango's death?",
    stopConversation = "false",
    options = {
        {"Aurra Sing", "q_correct"},        -- correct (top)
        {"Cad Bane", "q_failed"},
        {"Embo", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q041)

-- 042
q042 = ConvoScreen:new {
    id = "q042",
    leftDialog = "",
    customDialogText = "What species is Cad Bane, the infamous bounty hunter seen throughout the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Duros", "q_correct"},             -- correct (top)
        {"Devaronian", "q_failed"},
        {"Rodian", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q042)

-- 043
q043 = ConvoScreen:new {
    id = "q043",
    leftDialog = "",
    customDialogText = "What is the name of the Mandalorian warrior who leads Death Watch during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"Bo-Katan Kryze", "q_failed"},
        {"Pre Vizsla", "q_correct"},        -- correct (middle)
        {"Rook Kast", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q043)

-- 044
q044 = ConvoScreen:new {
    id = "q044",
    leftDialog = "",
    customDialogText = "Which legendary bounty hunter is the genetic template for the Republic Clone Troopers?",
    stopConversation = "false",
    options = {
        {"Jango Fett", "q_correct"},        -- correct (top)
        {"Bossk", "q_failed"},
        {"Dengar", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q044)

-- 045
q045 = ConvoScreen:new {
    id = "q045",
    leftDialog = "",
    customDialogText = "What is the traditional weapon carried by many Mandalorians, capable of piercing even armor?",
    stopConversation = "false",
    options = {
        {"The Beskad sword", "q_correct"},  -- correct (top)
        {"The Vibro-lance", "q_failed"},
        {"The Zakkeg cleaver", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q045)

-- 046
q046 = ConvoScreen:new {
    id = "q046",
    leftDialog = "",
    customDialogText = "Which bounty hunter is known for his iconic wide-brimmed hat and dual LL-30 pistols?",
    stopConversation = "false",
    options = {
        {"Embo", "q_failed"},
        {"Cad Bane", "q_correct"},          -- correct (middle)
        {"Latts Razzi", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q046)

-- 047
q047 = ConvoScreen:new {
    id = "q047",
    leftDialog = "",
    customDialogText = "Which creature do Trandoshan hunters, such as Bossk, traditionally hunt as a rite of passage?",
    stopConversation = "false",
    options = {
        {"Wookiees", "q_correct"},          -- correct (top)
        {"Gundarks", "q_failed"},
        {"Krayt Dragons", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q047)

-- 048
q048 = ConvoScreen:new {
    id = "q048",
    leftDialog = "",
    customDialogText = "Which Mandalorian faction opposed the pacifist rule of Duchess Satine Kryze?",
    stopConversation = "false",
    options = {
        {"Death Watch", "q_correct"},       -- correct (top)
        {"The Journeyman Protectors", "q_failed"},
        {"The Nite Owls", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q048)

-- 049
q049 = ConvoScreen:new {
    id = "q049",
    leftDialog = "",
    customDialogText = "Which underworld organization frequently employs bounty hunters during the Clone Wars?",
    stopConversation = "false",
    options = {
        {"The Banking Clan", "q_failed"},
        {"The Hutt Cartel", "q_correct"},   -- correct (middle)
        {"The Trade Federation", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q049)

-- 050
q050 = ConvoScreen:new {
    id = "q050",
    leftDialog = "",
    customDialogText = "What is the Mandalorian term for a traditional clan banner or symbol?",
    stopConversation = "false",
    options = {
        {"Krybes", "q_correct"},            -- correct (top)
        {"Beskaryc", "q_failed"},
        {"Mandalorec", "q_failed"}
    }
}
bsv_quiz_convo:addScreen(q050)



---------------------------------------------------------
-- REGISTER TEMPLATE
---------------------------------------------------------

addConversationTemplate("bsv_quiz_convo", bsv_quiz_convo)
