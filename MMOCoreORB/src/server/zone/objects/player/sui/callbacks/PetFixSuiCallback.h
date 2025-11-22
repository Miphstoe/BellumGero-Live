
#ifndef PETFIXSUICALLBACK_H_
#define PETFIXSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/intangible/PetControlDevice.h"
#include "server/zone/objects/tangible/deed/pet/PetDeed.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
	class CreatureObject;
}
}
}
}

using namespace server::zone::objects::creature;

class PetFixSuiCallback : public SuiCallback {
	ManagedWeakReference<PetControlDevice*> controlDevice;

public:
	PetFixSuiCallback(ZoneServer* server, PetControlDevice* device)
		: SuiCallback(server) {
		controlDevice = device;
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		ManagedReference<PetControlDevice*> device = controlDevice.get();

		if (device == nullptr || cancelPressed)
			return;

		if (args->size() < 1)
			return;

		bool otherPressed = Bool::valueOf(args->get(0).toString());

		ManagedReference<TangibleObject*> controlledObject = device->getControlledObject();

		if (controlledObject == nullptr || !controlledObject->isCreature())
			return;

		ManagedReference<Creature*> pet = cast<Creature*>(controlledObject.get());
		ManagedReference<PetDeed*> deed = pet->getPetDeed();

		Locker lock(pet, player);

		if (otherPressed) {
			// "Adjust Pet Level" button was pressed (Other button)
			if (deed != nullptr) {
				int newLevel = deed->calculatePetLevel();
				if (newLevel < 1 || newLevel > 75) {
					player->sendSystemMessage("@bio_engineer:pet_sui_fix_error");
					return;
				}
				deed->setLevel(newLevel);
				player->sendSystemMessage("@bio_engineer:pet_sui_level_fixed");
			}
		}
		else {
			// "Adjust Pet Stats" button was pressed (OK button)
			if (deed != nullptr) {
				if (deed->adjustPetStats(player, pet)) {
					// Stats were adjusted successfully
					player->sendSystemMessage("Your pet is ready to be called!");
				}
			}
		}
	}
};

#endif /* PETFIXSUICALLBACK_H_ */
