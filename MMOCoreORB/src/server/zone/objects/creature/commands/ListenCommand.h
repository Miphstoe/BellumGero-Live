/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef LISTENCOMMAND_H_
#define LISTENCOMMAND_H_

#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/director/DirectorManager.h"

class ListenCommand : public QueueCommand {
public:

	ListenCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (creature->isListening())
			return GENERALERROR;

		ManagedReference<PlayerManager*> playerManager = server->getPlayerManager();

		if (playerManager != nullptr)
			playerManager->startListen(creature, target);

		// EPBS V2: notify Lua after listen is established
		// Use getListenID() — the confirmed ID set by startListen — not the raw command target
		uint64 confirmedListenID = creature->getListenID();
		if (confirmedListenID != 0) {
			Lua* lua = DirectorManager::instance()->getLuaInstance();
			if (lua != nullptr) {
				Reference<LuaFunction*> f = lua->createFunction("epbsOnListenStart", 0);
				if (f != nullptr) {
					*f << creature;
					*f << confirmedListenID;
					f->callFunction();
				}
			}
		}

		return SUCCESS;
	}

};

#endif //LISTENCOMMAND_H_
