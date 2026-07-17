/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef DROIDSCANCOMPLETIONTASK_H_
#define DROIDSCANCOMPLETIONTASK_H_

#include "server/zone/objects/mission/BountyMissionObjective.h"

namespace server {
namespace zone {
namespace objects {
namespace mission {
namespace bountyhunter {
namespace events {

class DroidScanCompletionTask : public Task, public Logger {
	ManagedWeakReference<BountyMissionObjective*> objective;
	uint64 token;

public:
	DroidScanCompletionTask(BountyMissionObjective* objective, uint64 token) : Logger("DroidScanCompletionTask") {
		this->objective = objective;
		this->token = token;
	}

	void run() {
		ManagedReference<BountyMissionObjective*> objectiveRef = objective.get();

		if (objectiveRef == nullptr)
			return;

		Locker locker(objectiveRef);
		objectiveRef->completeDroidScan(token);
	}
};

} // namespace events
} // namespace bountyhunter
} // namespace mission
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::mission::bountyhunter::events;

#endif /* DROIDSCANCOMPLETIONTASK_H_ */
