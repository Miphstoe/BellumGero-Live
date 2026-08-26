#ifndef MANAGEFACTORYQUEUESUICALLBACK_H_
#define MANAGEFACTORYQUEUESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/installation/factory/FactoryObject.h"

class ManageFactoryQueueSuiCallback : public SuiCallback {
public:
	ManageFactoryQueueSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || args == nullptr || args->size() < 1 || eventIndex == 1)
			return;
		int index = Integer::valueOf(args->get(args->size() - 1).toString());
		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		if (object == nullptr || !object->isFactory())
			return;
		FactoryObject* factory = cast<FactoryObject*>(object.get());
		Locker playerLocker(player);
		Locker factoryLocker(factory, player);
		if (eventIndex == 2)
			factory->removeQueuedSchematic(player, index);
		else
			factory->retryQueuedSchematic(index);
	}
};

#endif
