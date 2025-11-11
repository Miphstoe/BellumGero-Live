bsv_gate_convo_template = ConvoTemplate:new {
    initialScreen   = "intro",
    templateType    = "Lua",
    luaClassHandler = "bsv_gate_convo_handler",
    screens         = {}
}

local intro = ConvoScreen:new{
    id = "intro",
    leftDialog = "",
    customDialogText = "Halt. State your clearance.",
    stopConversation = "false",
    options = {
        {"I was sent to investigate the Blue Shadow Virus bunker. Intelligence suggests they may be developing the pathogen again.", "claim_clearance"},
        {"Nevermind.", "bye"}
    }
}
bsv_gate_convo_template:addScreen(intro)

local claim = ConvoScreen:new{
    id = "claim_clearance",
    leftDialog = "",
    customDialogText = "This facility has been overrun by droids and sealed since the last outbreak. Are you prepared to enter?",
    stopConversation = "false",
    options = {
        {"I am prepared.", "grant"},
        {"On second thought, not yet.", "deny"}
    }
}
bsv_gate_convo_template:addScreen(claim)

local grant = ConvoScreen:new{
    id = "grant",
    leftDialog = "",
    customDialogText = "Proceed with caution. Good luck.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(grant)

local deny = ConvoScreen:new{
    id = "deny",
    leftDialog = "",
    customDialogText = "Very well. Return when you are ready.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(deny)

local bye = ConvoScreen:new{
    id = "bye",
    leftDialog = "",
    customDialogText = "Move along.",
    stopConversation = "true",
    options = {}
}
bsv_gate_convo_template:addScreen(bye)

addConversationTemplate("bsv_gate_convo", bsv_gate_convo_template)
