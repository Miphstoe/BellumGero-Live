bsv_gate_convo_template = ConvoTemplate:new {
    initialScreen = "intro",
    templateType = "Lua",
    luaClassHandler = "bsv_gate_convo_handler",
    screens = {}
}

local intro = ConvoScreen:new {
    id = "intro",
    leftDialog = "",
    customDialogText = "Halt. State your clearance.",
    stopConversation = "false",
    options = {
        {"I was sent to investigate the Blue Shadow Virus bunker, to ensure it is not once again developing the deadly virus.", "claim_clearance"},
        {"Nevermind.", "bye"}
    }
}
bsv_gate_convo_template:addScreen(intro)

local claim = ConvoScreen:new {
    id = "claim_clearance",
    leftDialog = "",
    customDialogText = "This place has been overrun by Droids and worse since the last outbreak. Are you sure you're prepared to enter?,
    stopConversation = "false",
    options = {
        {"I am well prepared.", "grant"},
        {"Actually I think I better not.", "deny"}
    }
}
bsv_gate_convo_template:addScreen(claim)

local grant = ConvoScreen:new {
    id = "grant",
    leftDialog = "",
    customDialogText = "Proceed with caution. Good luck.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(grant)

local deny = ConvoScreen:new {
    id = "deny",
    leftDialog = "",
    customDialogText = "That's probably for the best.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(deny)

local bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "Move along.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(bye)

addConversationTemplate("bsv_gate_convo", bsv_gate_convo_template)
