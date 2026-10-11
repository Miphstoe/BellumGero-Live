#include "server/zone/objects/player/sessions/ImageDesignStationObserver.h"
#include "server/zone/objects/player/sessions/ImageDesignStationSession.h"
#include "templates/params/ObserverEventType.h"

int ImageDesignStationObserverImplementation::notifyObserverEvent(
	uint32 eventType,
	Observable* observable,
	ManagedObject* arg1,
	int64 arg2) {

	ManagedReference<ImageDesignStationSession*> strongSession =
		session.get();

	if (strongSession == nullptr)
		return 1;

	if (eventType == ObserverEventType::POSITIONCHANGED) {
		if (!strongSession->isStationSessionValid(false)) {
			strongSession->forceCloseStationSession(true);
			return 1;
		}

		return 0;
	}

	if (eventType == ObserverEventType::LOGGEDOUT) {
		strongSession->forceCloseStationSession(false);
		return 1;
	}

	return 0;
}
