/*
 * Entertainer Paid Buff Service — /epbssetup
 * Opens the EPBS configuration menu for an actively performing entertainer.
 * Lets them enable/disable the service, set prices, and view earnings.
 */

#ifndef EPBSSETUPCOMMAND_H_
#define EPBSSETUPCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"

class EPBSSetupCommand : public QueueCommand {
public:
	EPBSSetupCommand(const String& name, ZoneProcessServer* server)
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

		Reference<LuaFunction*> f = lua->createFunction("epbsSetupRun", 0);
		if (f == nullptr) {
			creature->sendSystemMessage("[EPBS] Service not loaded. Contact staff.");
			return GENERALERROR;
		}

		*f << creature;
		f->callFunction();

		return SUCCESS;
	}
};

#endif /* EPBSSETUPCOMMAND_H_ */
