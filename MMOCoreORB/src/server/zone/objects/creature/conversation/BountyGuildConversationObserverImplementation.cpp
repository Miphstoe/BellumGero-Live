/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "server/zone/objects/creature/conversation/BountyGuildConversationObserver.h"

BountyGuildConversationObserverImplementation::BountyGuildConversationObserverImplementation(uint32 convoTemplateCRC) :
	ConversationObserverImplementation(convoTemplateCRC) {

	// Tie this conversation to our MasterBountyGuildScreenHandler.
	registerScreenHandler(MasterBountyGuildScreenHandler::STARTSCREENHANDLERID, &masterBountyGuildScreenHandler);
}
