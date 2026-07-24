/*
 * ManagePowerSuiCallback.h
 */

#ifndef MANAGEPOWERSUICALLBACK_H_
#define MANAGEPOWERSUICALLBACK_H_

#include "server/zone/ZoneServer.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"

class ManagePowerSuiCallback : public SuiCallback {
public:
	ManagePowerSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (creature == nullptr || sui == nullptr || !sui->isListBox() || cancelPressed || args == nullptr || args->size() == 0)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);
		if (listBox == nullptr)
			return;

		int selectedIndex = Integer::valueOf(args->get(0).toString());
		if (selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		uint64 structureID = listBox->getMenuObjectID(selectedIndex);
		if (structureID == 0 || server == nullptr)
			return;

		ManagedReference<InstallationObject*> installation = server->getObject(structureID).castTo<InstallationObject*>();
		if (installation == nullptr) {
			creature->sendSystemMessage("That installation could not be found. It may have been destroyed or transferred.");
			return;
		}

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		Locker installationLocker(installation, creature);

		if (!structureManager->hasRemotePowerAdminRights(installation, creature)) {
			creature->sendSystemMessage("You are no longer an administrator for that installation.");
			return;
		}

		if (installation->isGeneratorObject() ||
				(!installation->isHarvesterObject() && !installation->isFactory()) ||
				installation->getBasePowerRate() <= 0) {
			creature->sendSystemMessage("That installation cannot receive power through remote power management.");
			return;
		}

		structureManager->promptRemoteAddPower(installation, creature);
	}
};

#endif // MANAGEPOWERSUICALLBACK_H_
