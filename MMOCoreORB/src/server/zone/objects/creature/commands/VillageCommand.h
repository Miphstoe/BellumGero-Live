/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef VILLAGECOMMAND_H_
#define VILLAGECOMMAND_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/managers/jedi/JediManager.h"

class VillageCommand : public QueueCommand {
public:

	VillageCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (JediManager::instance()->getJediProgressionType() != JediManager::VILLAGEJEDIPROGRESSION)
			return GENERALERROR;

		// CHANGE: No privilege check - any player can use this command
		// CHANGE: Calls VillagePlayerSui instead of VillageGmSui
		Lua* lua = DirectorManager::instance()->getLuaInstance();

		Reference<LuaFunction*> luaVillageCmd = lua->createFunction("VillagePlayerSui", "showMainPage", 0);
		*luaVillageCmd << creature;

		luaVillageCmd->callFunction();

		return SUCCESS;
	}

};

#endif //VILLAGECOMMAND_H_