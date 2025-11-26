-- Master Bounty Hunter Guild Contractor Conversation

print("[BH-GUILD] Loading master_bounty_guild_convo.lua")

master_bounty_guild_convo_template = ConvoTemplate:new {
    initialScreen = "bounty_guild_start",
    templateType  = "BountyGuildNPC",  -- mapped in ConversationTemplate.cpp
    screens       = {}
}

-- OPENING SCREEN (static text; offers to request a Guild contract)
bounty_guild_start = ConvoScreen:new {
    id               = "bounty_guild_start",
    leftDialog       = "You've proven yourself as a hunter. Are you interested in taking on Guild contracts?",
    customDialogText = "You've proven yourself as a hunter. Are you interested in taking on Guild contracts?",
    stopConversation = "false",
    options          = {
        {"Yes, give me a Guild contract.", "give_mission"},
    }
}
master_bounty_guild_convo_template:addScreen(bounty_guild_start)

-- MISSION REQUEST SCREEN (handled by C++; text is filled in there)
give_mission = ConvoScreen:new {
    id               = "give_mission",
    leftDialog       = "",   -- will be filled in by C++ handler
    customDialogText = "",
    stopConversation = "true",
    options          = {}
}
master_bounty_guild_convo_template:addScreen(give_mission)

addConversationTemplate("master_bounty_guild", master_bounty_guild_convo_template)
