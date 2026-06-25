/*
 * Entertainer Paid Buff Service — /epbspay
 * Player pays the entertainer they are watching/listening to for a mind buff.
 * All validation and payment logic lives in the Lua screenplay
 * EntertainerPaidBuffService (entertainer_paid_buff_service.lua).
 */

#ifndef EPBSPAYCOMMAND_H_
#define EPBSPAYCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"

class EPBSPayCommand : public QueueCommand {
public:
	EPBSPayCommand(const String& name, ZoneProcessServer* server)
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

		Reference<LuaFunction*> f = lua->createFunction("epbsPayRun", 0);
		if (f == nullptr) {
			creature->sendSystemMessage("[EPBS] Service not loaded. Contact staff.");
			return GENERALERROR;
		}

		// Pay the entertainer the patron is actively watching/listening to.
		// Fall back to explicit/selected targets for manual command use.
		uint64 effectiveTarget = creature->getWatchToID();
		if (effectiveTarget == 0)
			effectiveTarget = creature->getListenID();
		if (effectiveTarget == 0)
			effectiveTarget = (target != 0) ? target : creature->getTargetID();

		*f << creature;
		*f << effectiveTarget;
		f->callFunction();

		return SUCCESS;
	}
};

#endif /* EPBSPAYCOMMAND_H_ */
