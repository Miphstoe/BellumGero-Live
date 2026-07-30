/*
 * Bellum / Knight Trials — player-accessible PvE point status check.
 * Usage: /ktStatus            → your own Knight Trials PvE point progress
 */

#ifndef KTSTATUSCOMMAND_H_
#define KTSTATUSCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"

class KtStatusCommand : public QueueCommand {
public:

	KtStatusCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		Lua* lua = DirectorManager::instance()->getLuaInstance();

		if (lua == nullptr) {
			creature->sendSystemMessage("[KtStatus] Lua unavailable. Try again.");
			return GENERALERROR;
		}

		Reference<LuaFunction*> f = lua->createFunction("ktStatusRun", 0);

		if (f != nullptr) {
			*f << creature;
			f->callFunction();
		} else {
			creature->sendSystemMessage("[KtStatus] Status system not loaded.");
		}

		return SUCCESS;
	}
};

#endif /* KTSTATUSCOMMAND_H_ */
