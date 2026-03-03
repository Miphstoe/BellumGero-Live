/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.
*/

#include "server/zone/managers/city/CityFactionTroopObserver.h"
#include "templates/params/ObserverEventType.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/region/CityRegion.h"

int CityFactionTroopObserverImplementation::notifyObserverEvent(unsigned int eventType, Observable* observable, ManagedObject* arg1, int64 arg2) {
	if (eventType != ObserverEventType::OBJECTDESTRUCTION)
		return 0;

	ManagedReference<SceneObject*> obj = cast<SceneObject*>(observable);

	if (obj == nullptr)
		return 1;

	ManagedReference<CityRegion*> city = obj->getCityRegion().get();

	if (city != nullptr) {
		Locker locker(city);
		city->removeFactionTroop(obj);
	}

	return 1;
}