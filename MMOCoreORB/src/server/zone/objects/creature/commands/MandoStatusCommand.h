/*
 * Bellum / Mando Way of Life — player-accessible status check.
 * Usage: /mandoStatus            → your own quest/gate status
 *        /mandoStatus <name>     → target player's status (privileged only)
 */

#ifndef MANDOSTATUSCOMMAND_H_
#define MANDOSTATUSCOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/player/PlayerObject.h"

class MandoStatusCommand : public QueueCommand {
public:

	MandoStatusCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		Lua* lua = DirectorManager::instance()->getLuaInstance();

		if (lua == nullptr) {
			creature->sendSystemMessage("[MandoStatus] Lua unavailable. Try again.");
			return GENERALERROR;
		}

		String argStr = arguments.toString().trim();

		if (argStr.isEmpty()) {
			// No argument — show caller's own status
			Reference<LuaFunction*> f = lua->createFunction("mandoFoundlingStatusRun", 0);
			if (f != nullptr) {
				*f << creature;
				f->callFunction();
			} else {
				creature->sendSystemMessage("[MandoStatus] Status system not loaded.");
			}
		} else {
			// Name argument — privileged check of another player
			PlayerObject* ghost = creature->getPlayerObject();
			if (ghost == nullptr || !ghost->isPrivileged()) {
				creature->sendSystemMessage("[MandoStatus] Checking another player's status requires staff access.");
				return GENERALERROR;
			}

			Reference<LuaFunction*> f = lua->createFunction("mandoStatusAdminRun", 0);
			if (f != nullptr) {
				*f << creature;
				*f << argStr;
				f->callFunction();
			} else {
				creature->sendSystemMessage("[MandoStatus] Admin status function not loaded.");
			}
		}

		return SUCCESS;
	}
};

#endif /* MANDOSTATUSCOMMAND_H_ */
