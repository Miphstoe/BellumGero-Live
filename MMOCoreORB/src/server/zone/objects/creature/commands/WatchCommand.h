/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef WATCHCOMMAND_H_
#define WATCHCOMMAND_H_

#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/director/DirectorManager.h"

class WatchCommand : public QueueCommand {
public:

	WatchCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (creature->isWatching())
			return GENERALERROR;

		ManagedReference<PlayerManager*> playerManager = server->getPlayerManager();

		if (playerManager != nullptr)
			playerManager->startWatch(creature, target);

		// EPBS V2: notify Lua after watch is established
		// Use getWatchToID() — the confirmed ID set by startWatch — not the raw command target
		uint64 confirmedWatchID = creature->getWatchToID();
		if (confirmedWatchID != 0) {
			Lua* lua = DirectorManager::instance()->getLuaInstance();
			if (lua != nullptr) {
				Reference<LuaFunction*> f = lua->createFunction("epbsOnWatchStart", 0);
				if (f != nullptr) {
					*f << creature;
					*f << confirmedWatchID;
					f->callFunction();
				}
			}
		}

		return SUCCESS;
	}

};

#endif //WATCHCOMMAND_H_
