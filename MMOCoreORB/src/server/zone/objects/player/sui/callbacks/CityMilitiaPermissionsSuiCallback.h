/*
 * CityMilitiaPermissionsSuiCallback.h
 */

#ifndef CITYMILITIAPERMISSIONSSUICALLBACK_H_
#define CITYMILITIAPERMISSIONSSUICALLBACK_H_

#include "engine/engine.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
	class CreatureObject;
}
namespace region {
	class CityRegion;
}
}
}
}

using namespace server::zone::objects::creature;
using namespace server::zone::objects::region;

class CityMilitiaPermissionsSuiCallback : public SuiCallback {
	ManagedWeakReference<CityRegion*> cityRegion;

public:
	CityMilitiaPermissionsSuiCallback(ZoneServer* server, CityRegion* city) : SuiCallback(server) {
		cityRegion = city;
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed || player == nullptr || !suiBox->isListBox() || args->size() <= 0)
			return;

		ManagedReference<CityRegion*> city = cityRegion.get();

		if (city == nullptr)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		int index = Integer::valueOf(args->get(0).toString());

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		uint64 militiaid = listBox->getMenuObjectID(index);

		CityManager* cityManager = server->getCityManager();
		cityManager->handleMilitiaMemberPermission(city, player, militiaid, index, suiBox->getUsingObject().get());
	}
};

#endif /* CITYMILITIAPERMISSIONSSUICALLBACK_H_ */
