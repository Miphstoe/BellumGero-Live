#ifndef DOCTORSERVICEBACKSUICALLBACK_H_
#define DOCTORSERVICEBACKSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorServiceBackSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> stationRef;
	bool ownerMenu;

public:
	DoctorServiceBackSuiCallback(
		ZoneServer* server, SceneObject* station,
		bool toOwnerMenu)
		: SuiCallback(server),
		  stationRef(station),
		  ownerMenu(toOwnerMenu) {
	}

	void run(
		CreatureObject* player, SuiBox*,
		uint32 eventIndex, Vector<UnicodeString>*) override {

		if (eventIndex != 1 || player == nullptr)
			return;

		SceneObject* station = stationRef.get();

		if (station == nullptr)
			return;

		if (ownerMenu)
			DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
				station, player);
		else
			DoctorServiceUnitMenuComponent::showStationMainMenu(
				station, player);
	}
};

#endif
