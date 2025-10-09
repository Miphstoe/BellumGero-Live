-- GCW Cave Daily Conversation (template only; handler in screenplays)
gcwCaveDailyConvoTemplate = ConvoTemplate:new {
  initialScreen = "",  -- handler chooses the first screen
  templateType   = "Lua",
  luaClassHandler = "gcwCaveDailyConvoHandler",
  screens = {}
}

local function opt(txt, scr) return { txt, scr } end

-- Use customDialogText (raw strings) and ASCII punctuation
local start = ConvoScreen:new{
  id = "start",
  customDialogText = "Field report, soldier. This sector is crawling with defectors. Command is issuing a daily suppression order.",
  stopConversation = "false",
  options = {
    opt("I want today's assignment.", "accept"),
    opt("What's my current progress?", "status"),
    opt("I'm ready to turn in.", "turnin"),
    opt("Nevermind.", "bye")
  }
}
gcwCaveDailyConvoTemplate:addScreen(start)

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "accept",
  customDialogText = "Acknowledged. Suppress 25 defectors within the cave. Return here for debrief.",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "already_active",
  customDialogText = "You already have today's assignment. Suppress 25 defectors in the cave and report back.",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "status",
  customDialogText = "Transmitting your current progress now.",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "turnin",
  customDialogText = "Submitting your report...",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "cooldown",
  customDialogText = "You have already completed today's order. Return after the next cycle.",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "not_faction",
  customDialogText = "You are not cleared to take this assignment from our command.",
  stopConversation = "true",
  options = {}
})

gcwCaveDailyConvoTemplate:addScreen(ConvoScreen:new{
  id = "bye",
  customDialogText = "Move along.",
  stopConversation = "true",
  options = {}
})

addConversationTemplate("gcwCaveDailyConvoTemplate", gcwCaveDailyConvoTemplate)