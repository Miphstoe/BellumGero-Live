#include "server/zone/objects/player/sessions/VendorImageDesignObserver.h"
#include "server/zone/objects/player/sessions/VendorImageDesignSession.h"
#include "templates/params/ObserverEventType.h"

int VendorImageDesignObserverImplementation::notifyObserverEvent(
	uint32 eventType,
	Observable* observable,
	ManagedObject* arg1,
	int64 arg2) {

	ManagedReference<VendorImageDesignSession*> strongSession =
		session.get();

	if (strongSession == nullptr)
		return 1;

	if (eventType == ObserverEventType::POSITIONCHANGED) {
		if (!strongSession->isVendorSessionValid(false)) {
			strongSession->forceCloseVendorSession(
				"Vendor design session cancelled because you moved "
				"away from the vendor or it is no longer available.");
			return 1;
		}

		return 0;
	}

	if (eventType == ObserverEventType::LOGGEDOUT) {
		strongSession->forceCloseVendorSession("");
		return 1;
	}

	return 0;
}
