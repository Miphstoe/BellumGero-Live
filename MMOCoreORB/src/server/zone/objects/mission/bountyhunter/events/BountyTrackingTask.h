/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef BOUNTYTRACKINGTASK_H_
#define BOUNTYTRACKINGTASK_H_

#include "server/zone/objects/mission/BountyMissionObjective.h"

namespace server {
namespace zone {
namespace objects {
namespace mission {
namespace bountyhunter {
namespace events {

class BountyTrackingTask : public Task, public Logger {
	ManagedWeakReference<BountyMissionObjective*> objective;
	uint64 token;

public:
	BountyTrackingTask(BountyMissionObjective* objective, uint64 token) : Logger("BountyTrackingTask") {
		this->objective = objective;
		this->token = token;
	}

	void run() {
		ManagedReference<BountyMissionObjective*> objectiveRef = objective.get();

		if (objectiveRef == nullptr)
			return;

		Locker locker(objectiveRef);
		objectiveRef->validateTrackingLock(token);
	}
};

} // namespace events
} // namespace bountyhunter
} // namespace mission
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::mission::bountyhunter::events;

#endif /* BOUNTYTRACKINGTASK_H_ */
