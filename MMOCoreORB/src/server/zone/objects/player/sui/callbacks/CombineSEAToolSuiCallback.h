#ifndef COMBINESEATOOLSUICALLBACK_H_
#define COMBINESEATOOLSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "templates/SharedObjectTemplate.h"

class CombineSEAToolSuiCallback : public SuiCallback {
	static const int MAX_CHARGES = 50;

	static bool isSEATool(SceneObject* so) {
		if (!so) return false;
		SharedObjectTemplate* tmpl = so->getObjectTemplate();
		if (!tmpl) return false;
		return tmpl->getFullTemplateString().indexOf("sea_removal_tool.iff") != -1;
	}

public:
	CombineSEAToolSuiCallback(ZoneServer* server) : SuiCallback(server) {}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);
		if (cancelPressed || player == nullptr) return;
		if (!suiBox->isListBox()) return;
		if (!args || args->size() < 2) return;

		int index = Integer::valueOf(args->get(1).toString());
		if (index < 0) return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		ManagedReference<SceneObject*> sourceObj = listBox->getUsingObject().get();
		if (!sourceObj || !isSEATool(sourceObj)) {
			player->sendSystemMessage("SEA: Source tool is invalid.");
			return;
		}

		TangibleObject* sourceTano = sourceObj->asTangibleObject();
		if (!sourceTano) return;

		ZoneServer* zoneServer = player->getZoneServer();
		if (!zoneServer) return;

		uint64 targetID = listBox->getMenuObjectID(index);
		ManagedReference<SceneObject*> targetObj = zoneServer->getObject(targetID);
		if (!targetObj || !isSEATool(targetObj)) {
			player->sendSystemMessage("SEA: Target tool is invalid.");
			return;
		}

		TangibleObject* targetTano = targetObj->asTangibleObject();
		if (!targetTano) return;

		ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
		if (!inventory) return;

		if (!sourceTano->isASubChildOf(inventory) || !targetTano->isASubChildOf(inventory)) {
			player->sendSystemMessage("SEA: Both tools must be in your inventory.");
			return;
		}

		int sourceCount = sourceTano->getUseCount() > 0 ? sourceTano->getUseCount() : 1;
		int targetCount = targetTano->getUseCount() > 0 ? targetTano->getUseCount() : 1;

		if (sourceCount + targetCount > MAX_CHARGES) {
			player->sendSystemMessage("SEA: Combined charges would exceed the maximum of 50.");
			return;
		}

		Locker lockerSource(sourceTano, player);
		Locker lockerTarget(targetTano, player);

		sourceTano->setUseCount(sourceCount + targetCount);

		targetTano->destroyObjectFromWorld(true);
		targetTano->destroyObjectFromDatabase(true);

		player->sendSystemMessage("Tools combined. This tool now has "
		                          + String::valueOf(sourceCount + targetCount) + " charges.");
	}
};

#endif /* COMBINESEATOOLSUICALLBACK_H_ */
