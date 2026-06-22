/*
 * Entertainer Paid Buff Service — /epbspetpay
 * Player pays for their active combat pet to receive a mind buff from the
 * entertainer they are currently watching/listening to.
 */

#ifndef EPBSPETPAYCOMMAND_H_
#define EPBSPETPAYCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"

class EPBSPetPayCommand : public QueueCommand {
public:
	EPBSPetPayCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		Lua* lua = DirectorManager::instance()->getLuaInstance();
		if (lua == nullptr) {
			creature->sendSystemMessage("[EPBS] Service unavailable. Try again shortly.");
			return GENERALERROR;
		}

		Reference<LuaFunction*> f = lua->createFunction("epbsPetPayRun", 0);
		if (f == nullptr) {
			creature->sendSystemMessage("[EPBS] Service not loaded. Contact staff.");
			return GENERALERROR;
		}

		// Use the command-queue target if set; otherwise fall back to the
		// creature's server-side selected target (client chat commands send targetID=0).
		uint64 effectiveTarget = (target != 0) ? target : creature->getTargetID();

		*f << creature;
		*f << effectiveTarget;
		f->callFunction();

		return SUCCESS;
	}
};

#endif /* EPBSPETPAYCOMMAND_H_ */
