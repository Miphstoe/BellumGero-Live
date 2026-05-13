/*
 *              Copyright <SWGEmu>
 *      See file COPYING for copying conditions. */

#ifndef DROIDMILKSCANTASK_H_
#define DROIDMILKSCANTASK_H_

#include "server/zone/objects/creature/ai/DroidObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/Creature.h"
#include "server/zone/objects/tangible/components/droid/DroidHarvestModuleDataComponent.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include <server/zone/CloseObjectsVector.h>

namespace server {
namespace zone {
namespace objects {
namespace creature {
namespace events {

class DroidMilkScanTask : public Task {
	Reference<DroidHarvestModuleDataComponent*> module;

public:
	DroidMilkScanTask(DroidHarvestModuleDataComponent* mod) : Task() {
		module = mod;
	}

	void run() {
		if (module == nullptr)
			return;

		if (!module->isActive() || module->getHarvestInterest() != DroidHarvestModuleDataComponent::INTEREST_MILK)
			return;

		Reference<DroidObject*> droid = module->getDroidObject();

		if (droid == nullptr)
			return;

		Locker droidLock(droid);

		if (droid->isDead() || droid->isIncapacitated() || !droid->hasPower())
			return;

		ManagedReference<CreatureObject*> owner = droid->getLinkedCreature().get();

		if (owner == nullptr)
			return;

		Zone* zone = droid->getZone();

		if (zone == nullptr) {
			if (module->isActive() && module->getHarvestInterest() == DroidHarvestModuleDataComponent::INTEREST_MILK)
				reschedule(10000);
			return;
		}

		ManagedReference<CreatureManager*> creatureManager = zone->getCreatureManager();

		if (creatureManager == nullptr) {
			if (module->isActive() && module->getHarvestInterest() == DroidHarvestModuleDataComponent::INTEREST_MILK)
				reschedule(10000);
			return;
		}

		int bonus = (int)module->getHarvestPower();

		Vector<server::zone::TreeEntry*> closeObjects;
		CloseObjectsVector* cov = (CloseObjectsVector*)droid->getCloseObjects();

		if (cov != nullptr)
			cov->safeCopyTo(closeObjects);

		for (int i = 0; i < closeObjects.size(); i++) {
			SceneObject* scno = static_cast<SceneObject*>(closeObjects.get(i));

			if (scno == nullptr || !scno->isCreature())
				continue;

			if (!scno->isInRange(droid, 32.0f))
				continue;

			Creature* cr = cast<Creature*>(scno->asTangibleObject());

			if (cr == nullptr)
				continue;

			Locker crLock(cr, droid);

			if (!cr->canDroidMilkMe(owner, droid))
				continue;

			creatureManager->droidMilk(cr, droid, bonus);
		}

		// Re-check active state under the droid lock before rescheduling
		if (module->isActive() && module->getHarvestInterest() == DroidHarvestModuleDataComponent::INTEREST_MILK)
			reschedule(10000);
	}
};

} // namespace events
} // namespace creature
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::creature::events;

#endif /* DROIDMILKSCANTASK_H_ */
