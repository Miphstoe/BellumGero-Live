#ifndef CITYREMOVEFACTIONTROOPTASK_H_
#define CITYREMOVEFACTIONTROOPTASK_H_

#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/scene/SceneObject.h"

class CityRemoveFactionTroopTask : public Task {
	ManagedReference<SceneObject*> troop;
	ManagedReference<CityRegion*> city;

public:
	CityRemoveFactionTroopTask(SceneObject* sceno, CityRegion* cityRegion) {
		troop = sceno;
		city = cityRegion;
	}

	void run() {
		if (city == nullptr || troop == nullptr)
			return;

		Locker locker(city);
		Locker clocker(troop, city);

		city->removeFactionTroop(troop);

		troop->destroyObjectFromWorld(true);
		troop->destroyObjectFromDatabase(true);
	}
};

#endif /* CITYREMOVEFACTIONTROOPTASK_H_ */