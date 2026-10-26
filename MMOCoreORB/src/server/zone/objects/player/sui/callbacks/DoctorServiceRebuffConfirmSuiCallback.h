#ifndef DOCTORSERVICEREBUFFCONFIRMSUICALLBACK_H_
#define DOCTORSERVICEREBUFFCONFIRMSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorServiceRebuffConfirmSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> stationRef;
	bool useJanta;
	uint64 petObjectId;

public:
	DoctorServiceRebuffConfirmSuiCallback(
		ZoneServer* server, SceneObject* station,
		bool janta, uint64 petId)
		: SuiCallback(server),
		  stationRef(station),
		  useJanta(janta),
		  petObjectId(petId) {
	}

	void run(
		CreatureObject* player, SuiBox*,
		uint32 eventIndex, Vector<UnicodeString>*) override {

		SceneObject* station = stationRef.get();

		if (station == nullptr || player == nullptr)
			return;

		if (!DoctorServiceUnitMenuComponent::isPlayerWithinUseRange(
				station, player))
			return;

		if (eventIndex == 1) {
			if (petObjectId == 0)
				DoctorServiceUnitMenuComponent::showStationMainMenu(
					station, player);
			else
				DoctorServiceUnitMenuComponent::showPetServicesMenu(
					station, player);

			return;
		}

		DoctorServiceUnitMenuComponent::handleRebuffConfirmation(
			station, player,
			useJanta, petObjectId);
	}
};

#endif
