/*
 * HolocronMenuComponent.cpp
 *
 *  Created on: 01/23/2012
 *      Author: xyborn
 */

#include "HolocronMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/managers/jedi/JediManager.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "engine/util/u3d/Vector3.h"
#include "system/lang/Integer.h"
#include "system/lang/String.h"

void HolocronMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Call parent implementation first
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Add the two Holocron-specific menu options
	menuResponse->addRadialMenuItem(20, 3, "Refill Forcebar");
	menuResponse->addRadialMenuItem(21, 3, "Gain Exp");

	// Add item lock/unlock menu options
	TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
	if (tangible != nullptr) {
		String lockValue = tangible->getLuaStringData("item_locked");
		bool isLocked = !lockValue.isEmpty() && Integer::valueOf(lockValue) == 1;

		if (isLocked) {
			menuResponse->addRadialMenuItem(RADIAL_UNLOCK_ITEM, 3, "Unlock Item");
		} else {
			menuResponse->addRadialMenuItem(RADIAL_LOCK_ITEM, 3, "Lock Item");
		}
	}
}

int HolocronMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* creature, byte selectedID) const {
	if (!sceneObject->isASubChildOf(creature))
		return 0;

	// Handle item lock/unlock
	if (selectedID == RADIAL_LOCK_ITEM) {
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		tangible->setLuaStringData("item_locked", "1");
		tangible->addMagicBit(true);

		String itemName = sceneObject->getDisplayedName();
		if (itemName.isEmpty())
			itemName = sceneObject->getObjectNameStringIdName();

		creature->sendSystemMessage("Item locked: " + itemName + " - This item cannot be deleted or traded.");
		return 0;
	}
	else if (selectedID == RADIAL_UNLOCK_ITEM) {
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		tangible->deleteLuaStringData("item_locked");
		tangible->removeMagicBit(true);

		String itemName = sceneObject->getDisplayedName();
		if (itemName.isEmpty())
			itemName = sceneObject->getObjectNameStringIdName();

		creature->sendSystemMessage("Item unlocked: " + itemName + " - This item can now be deleted or traded normally.");
		return 0;
	}

	// Handle holocron-specific options
	if (selectedID != 20 && selectedID != 21)
		return 0;

	// Option 20: Use Holocron to fill Force Bar (with 3-hour cooldown)
	if (selectedID == 20) {
		JediManager::instance()->useItem(sceneObject, JediManager::ITEMHOLOCRON, creature);
		return 0;
	}

	// Option 21: Gain 25000 Jedi General Experience (no cooldown)
	if (selectedID == 21) {
		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost != nullptr) {
			TransactionLog trx(TrxCode::EXPERIENCE, creature);
			ghost->addExperience(trx, "jedi_general", 25000, true);
			creature->sendSystemMessage("You have gained 25000 Jedi General experience points.");
		}
		sceneObject->destroyObjectFromWorld(true);
		return 0;
	}

	return 0;
}

