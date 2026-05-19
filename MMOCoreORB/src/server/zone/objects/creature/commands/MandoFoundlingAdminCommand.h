/*
 * Bellum / Mando Way of Life — privileged admin: inspect Foundling mission-quota state.
 */

#ifndef MANDOFOUNDLINGADMINCOMMAND_H_
#define MANDOFOUNDLINGADMINCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/player/PlayerObject.h"

class MandoFoundlingAdminCommand : public QueueCommand {
public:

	MandoFoundlingAdminCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr || !ghost->isPrivileged()) {
			creature->sendSystemMessage("Only privileged admins may use this command.");
			return GENERALERROR;
		}

		Lua* lua = DirectorManager::instance()->getLuaInstance();

		Reference<LuaFunction*> f = lua->createFunction("mandoFoundlingAdminRun", 0);
		*f << creature;
		*f << arguments.toString();

		f->callFunction();

		return SUCCESS;
	}
};

#endif /* MANDOFOUNDLINGADMINCOMMAND_H_ */
