/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions.*/

#ifndef SERVICESAYCOMMAND_H_
#define SERVICESAYCOMMAND_H_

#include "server/chat/ChatManager.h"

class ServicesayCommand : public QueueCommand {
public:

	ServicesayCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ChatManager* chatManager = server->getZoneServer()->getChatManager();
		chatManager->handleServicesChat(creature, arguments);

		return SUCCESS;
	}

};

#endif //SERVICESAYCOMMAND_H_
