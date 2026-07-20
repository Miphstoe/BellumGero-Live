/*
 * RemoteStructureAddPowerSuiCallback.h
 */

#ifndef REMOTESTRUCTUREADDPOWERSUICALLBACK_H_
#define REMOTESTRUCTUREADDPOWERSUICALLBACK_H_

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"

class RemoteStructureAddPowerSuiCallback : public SuiCallback {
public:
	RemoteStructureAddPowerSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (creature == nullptr || sui == nullptr || !sui->isTransferBox())
			return;

		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed) {
			creature->enqueueCommand(STRING_HASHCODE("managepower"), 0, 0, "");
			return;
		}

		if (args == nullptr || args->size() < 2)
			return;

		int64 requestedAmount = Long::valueOf(args->get(1).toString());
		if (requestedAmount <= 0 || requestedAmount > 0xFFFFFFFFLL) {
			creature->sendSystemMessage("Please enter a valid power amount greater than zero.");
			creature->enqueueCommand(STRING_HASHCODE("managepower"), 0, 0, "");
			return;
		}

		ManagedReference<StructureObject*> structure = sui->getStructureObject().get();
		if (structure == nullptr || !structure->isInstallationObject()) {
			creature->sendSystemMessage("That installation is no longer available.");
			return;
		}

		InstallationObject* installation = cast<InstallationObject*>(structure.get());
		if (installation == nullptr)
			return;

		{
			Locker installationLocker(installation, creature);
			StructureManager::instance()->addRemotePower(installation, creature, (uint32)requestedAmount);
		}

		// Rebuild the list from live installation and inventory values after the
		// transfer, regardless of whether validation accepted the requested amount.
		creature->enqueueCommand(STRING_HASHCODE("managepower"), 0, 0, "");
	}
};

#endif // REMOTESTRUCTUREADDPOWERSUICALLBACK_H_
