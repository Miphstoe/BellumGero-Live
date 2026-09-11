/*
 * MannequinSuiCallback.h
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 *
 * Handles the equip (clothing/armor + weapon) and remove list-box selections.
 * Every callback re-validates permission, object existence, ownership/containment and
 * type on the server - the client-supplied object id is never trusted.
 */

#ifndef MANNEQUINSUICALLBACK_H_
#define MANNEQUINSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/objects/creature/ai/mannequin/MannequinObject.h"
#include "server/zone/objects/tangible/components/mannequin/MannequinContainerComponent.h"
#include "server/zone/objects/scene/TransferErrorCode.h"
#include "server/zone/objects/transaction/TransactionLog.h"

class MannequinSuiCallback : public SuiCallback {
public:
	MannequinSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || sui == nullptr)
			return;

		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed || args == nullptr || args->size() < 1)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);

		if (listBox == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		uint64 objectID = listBox->getMenuObjectID(index);

		if (objectID == 0)
			return;

		ManagedReference<SceneObject*> mannequinScene = sui->getUsingObject().get();

		if (mannequinScene == nullptr || !mannequinScene->isMannequinObject()) {
			player->sendSystemMessage("The mannequin is no longer available.");
			return;
		}

		if (!MannequinContainerComponent::isAuthorized(mannequinScene, player)) {
			player->sendSystemMessage("You are not allowed to manage this mannequin.");
			return;
		}

		ManagedReference<MannequinObject*> mannequin = cast<MannequinObject*>(mannequinScene.get());

		int windowType = sui->getWindowType();

		if (windowType == SuiWindowType::MANNEQUIN_REMOVE) {
			handleRemove(player, mannequin, objectID);
		} else {
			handleEquip(player, mannequin, objectID, windowType == SuiWindowType::MANNEQUIN_EQUIP_WEAPON);
		}
	}

private:
	void handleEquip(CreatureObject* player, MannequinObject* mannequin, uint64 objectID, bool weaponMode) {
		auto zoneServer = player->getZoneServer();

		if (zoneServer == nullptr)
			return;

		ManagedReference<SceneObject*> itemScene = zoneServer->getObject(objectID).get();

		if (itemScene == nullptr || !itemScene->isTangibleObject()) {
			player->sendSystemMessage("That item no longer exists.");
			return;
		}

		// Must still be in the acting player's own inventory.
		ManagedReference<SceneObject*> inventory = player->getInventory();

		if (inventory == nullptr || itemScene->getParent().get() != inventory) {
			player->sendSystemMessage("That item is no longer in your inventory.");
			return;
		}

		bool isWeapon = itemScene->isWeaponObject();
		bool isWearable = itemScene->isWearableObject();

		if (weaponMode && !isWeapon) {
			player->sendSystemMessage("That is not a weapon.");
			return;
		}

		if (!weaponMode && !isWearable) {
			player->sendSystemMessage("That item cannot be worn.");
			return;
		}

		// One displayed weapon at a time (stock client limitation).
		if (weaponMode) {
			ManagedReference<WeaponObject*> defaultWeapon = mannequin->getDefaultWeapon();
			uint64 defaultWeaponID = defaultWeapon != nullptr ? defaultWeapon->getObjectID() : 0;

			for (int i = 0; i < mannequin->getSlottedObjectsSize(); ++i) {
				ManagedReference<SceneObject*> child = mannequin->getSlottedObject(i);

				if (child != nullptr && child->isWeaponObject() && child->getObjectID() != defaultWeaponID) {
					player->sendSystemMessage("This mannequin is already displaying a weapon. Remove it first.");
					return;
				}
			}
		}

		ManagedReference<TangibleObject*> item = itemScene.castTo<TangibleObject*>();

		Locker plocker(player);
		Locker mlocker(mannequin, player);
		Locker ilocker(item, player);

		TransactionLog trx(player, mannequin, item, TrxCode::PLAYERMISCACTION);

		String errorDescription;
		int result = mannequin->canAddObject(item, 4, errorDescription);

		if (result != 0) {
			trx.abort() << "canAddObject failed: " << result;

			if (result == TransferErrorCode::SLOTOCCUPIED)
				player->sendSystemMessage("That item conflicts with equipment already displayed on this mannequin.");
			else
				player->sendSystemMessage(errorDescription.isEmpty() ? "That item cannot be displayed on this mannequin." : errorDescription);

			return;
		}

		if (!mannequin->transferObject(item, 4, true)) {
			trx.abort() << "transferObject failed";
			player->sendSystemMessage("The item could not be placed on the mannequin.");
			return;
		}

		mannequin->broadcastObject(item, true);

		trx.commit();

		mannequin->info(true) << "EQUIP" << (weaponMode ? "_WEAPON" : "") << " player=" << player->getObjectID()
			<< " mannequin=" << mannequin->getObjectID() << " item=" << item->getObjectID()
			<< " template=" << item->getObjectTemplate()->getFullTemplateString() << " result=OK";

		player->sendSystemMessage("Item placed on the mannequin.");
	}

	void handleRemove(CreatureObject* player, MannequinObject* mannequin, uint64 objectID) {
		ManagedReference<SceneObject*> childScene = mannequin->getContainerObject(objectID);

		// Slotted equipment is not in the "container objects" map; look it up in the slots.
		if (childScene == nullptr) {
			for (int i = 0; i < mannequin->getSlottedObjectsSize(); ++i) {
				ManagedReference<SceneObject*> c = mannequin->getSlottedObject(i);

				if (c != nullptr && c->getObjectID() == objectID) {
					childScene = c;
					break;
				}
			}
		}

		if (childScene == nullptr || !childScene->isTangibleObject()) {
			player->sendSystemMessage("That item is no longer on the mannequin.");
			return;
		}

		ManagedReference<SceneObject*> inventory = player->getInventory();

		if (inventory == nullptr || inventory->isContainerFullRecursive()) {
			player->sendSystemMessage("You do not have enough inventory space to remove that item.");
			return;
		}

		ManagedReference<TangibleObject*> item = childScene.castTo<TangibleObject*>();

		Locker plocker(player);
		Locker mlocker(mannequin, player);
		Locker ilocker(item, player);

		TransactionLog trx(mannequin, player, item, TrxCode::PLAYERMISCACTION);

		if (!inventory->transferObject(item, -1, true)) {
			// Leave the item safely on the mannequin on any failure.
			trx.abort() << "transferObject to inventory failed";
			player->sendSystemMessage("The item could not be returned to your inventory. It remains on the mannequin.");
			return;
		}

		inventory->broadcastObject(item, true);

		trx.commit();

		mannequin->info(true) << "UNEQUIP player=" << player->getObjectID() << " mannequin=" << mannequin->getObjectID()
			<< " item=" << item->getObjectID() << " template=" << item->getObjectTemplate()->getFullTemplateString() << " result=OK";

		player->sendSystemMessage("Item returned to your inventory.");
	}
};

#endif /* MANNEQUINSUICALLBACK_H_ */
