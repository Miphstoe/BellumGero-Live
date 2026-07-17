/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef DROIDSPAWNPROTECTIONTASK_H_
#define DROIDSPAWNPROTECTIONTASK_H_

#include "server/zone/objects/mission/BountyMissionObjective.h"

namespace server {
namespace zone {
namespace objects {
namespace mission {
namespace bountyhunter {
namespace events {

class DroidSpawnProtectionTask : public Task, public Logger {
	ManagedWeakReference<BountyMissionObjective*> objective;
	uint64 token;

public:
	DroidSpawnProtectionTask(BountyMissionObjective* objective, uint64 token) : Logger("DroidSpawnProtectionTask") {
		this->objective = objective;
		this->token = token;
	}

	void run() {
		ManagedReference<BountyMissionObjective*> objectiveRef = objective.get();

		if (objectiveRef == nullptr)
			return;

		Locker locker(objectiveRef);
		objectiveRef->endDroidSpawnProtection(token);
	}
};

} // namespace events
} // namespace bountyhunter
} // namespace mission
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::mission::bountyhunter::events;

#endif /* DROIDSPAWNPROTECTIONTASK_H_ */
