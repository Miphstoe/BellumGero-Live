/*
 * ManageMaintenanceSuiCallback.h
 */

#ifndef MANAGEMAINTENANCESUICALLBACK_H_
#define MANAGEMAINTENANCESUICALLBACK_H_

#include "server/zone/ZoneServer.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageMaintenanceSuiCallback : public SuiCallback {
public:
	ManageMaintenanceSuiCallback(ZoneServer* server) : SuiCallback(server) {
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

		ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();
		if (structure == nullptr) {
			creature->sendSystemMessage("That structure could not be found. It may have been destroyed or transferred.");
			return;
		}

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		Locker structureLocker(structure, creature);

		if (!structureManager->hasRemoteMaintenanceAdminRights(structure, creature)) {
			creature->sendSystemMessage("You are no longer an administrator for that structure.");
			return;
		}

		if (structure->isCivicStructure() || structure->isGCWBase()) {
			creature->sendSystemMessage("That structure cannot be funded through remote maintenance management.");
			return;
		}

		StructureManager::instance()->promptRemotePayMaintenance(structure, creature);
	}
};

#endif // MANAGEMAINTENANCESUICALLBACK_H_
