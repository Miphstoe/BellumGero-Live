-- Master Bounty Hunter Guild Contractor Conversation

print("[BH-GUILD] Loading master_bounty_guild_conv.lua")

master_bounty_guild_convo_template = ConvoTemplate:new {
    initialScreen = "bounty_guild_start",
    templateType  = "BountyGuildNPC",  -- mapped in ConversationTemplate.cpp
    screens       = {}
}

-- OPENING SCREEN
bounty_guild_start = ConvoScreen:new {
    id               = "bounty_guild_start",
    leftDialog       = "You've proven yourself as a hunter. Are you interested in taking on Guild contracts?",
    customDialogText = "You've proven yourself as a hunter. Are you interested in taking on Guild contracts?",
    stopConversation = "false",
    options = {
        {"Yes, give me a Guild contract.", "give_mission"},
        {"Not right now.", "bye"}
    }
}
master_bounty_guild_convo_template:addScreen(bounty_guild_start)

-- MISSION REQUEST SCREEN (handled by C++)
give_mission = ConvoScreen:new {
    id               = "give_mission",
    leftDialog       = "",   -- will be filled in by C++ handler
    customDialogText = "",
    stopConversation = "true",
    options          = {}
}
master_bounty_guild_convo_template:addScreen(give_mission)

-- GOODBYE
bye = ConvoScreen:new {
    id               = "bye",
    leftDialog       = "Very well. Come back when you're ready for serious work.",
    customDialogText = "Very well. Come back when you're ready for serious work.",
    stopConversation = "true",
    options          = {}
}
master_bounty_guild_convo_template:addScreen(bye)

addConversationTemplate("master_bounty_guild", master_bounty_guild_convo_template)
