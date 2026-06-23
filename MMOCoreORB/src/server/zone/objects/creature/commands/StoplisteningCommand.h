/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef STOPLISTENINGCOMMAND_H_
#define STOPLISTENINGCOMMAND_H_

#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/director/DirectorManager.h"

class StoplisteningCommand : public QueueCommand {
public:

	StoplisteningCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isListening())
			return GENERALERROR;

		// EPBS V2: notify Lua BEFORE stop executes (checks session readiness)
		{
			Lua* lua = DirectorManager::instance()->getLuaInstance();
			if (lua != nullptr) {
				Reference<LuaFunction*> f = lua->createFunction("epbsOnStopListen", 0);
				if (f != nullptr) {
					*f << creature;
					f->callFunction();
				}
			}
		}

		ManagedReference<PlayerManager*> playerManager = server->getPlayerManager();

		if (playerManager != nullptr)
			playerManager->stopListen(creature, target);

		return SUCCESS;
	}

};

#endif //STOPLISTENINGCOMMAND_H_
