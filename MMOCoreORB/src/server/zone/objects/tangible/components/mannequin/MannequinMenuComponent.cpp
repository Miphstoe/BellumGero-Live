/*
 * MannequinMenuComponent.cpp
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 */

#include "MannequinMenuComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/mannequin/MannequinObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/objects/tangible/components/mannequin/MannequinContainerComponent.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/callbacks/mannequin/MannequinSuiCallback.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/transaction/TransactionLog.h"

void MannequinMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (sceneObject == nullptr || player == nullptr || !player->isPlayerCreature())
		return;

	if (!MannequinContainerComponent::isAuthorized(sceneObject, player))
		return;

	menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU1, 3, "Manage Equipment");
	menuResponse->addRadialMenuItemToRadialID(RadialOptions::SERVER_MENU1, RadialOptions::SERVER_MENU2, 3, "Equip Clothing / Armor");
	menuResponse->addRadialMenuItemToRadialID(RadialOptions::SERVER_MENU1, RadialOptions::SERVER_MENU3, 3, "Equip Weapon");
	menuResponse->addRadialMenuItemToRadialID(RadialOptions::SERVER_MENU1, RadialOptions::SERVER_MENU4, 3, "Remove Equipment");
	menuResponse->addRadialMenuItemToRadialID(RadialOptions::SERVER_MENU1, RadialOptions::SERVER_MENU5, 3, "Remove All Equipment");

	menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU6, 3, "Pick Up Mannequin");
}

int MannequinMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (sceneObject == nullptr || player == nullptr || !sceneObject->isMannequinObject())
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	// Every management action re-checks authorization server-side.
	if (selectedID >= RadialOptions::SERVER_MENU1 && selectedID <= RadialOptions::SERVER_MENU6) {
		if (!MannequinContainerComponent::isAuthorized(sceneObject, player)) {
			player->sendSystemMessage("You are not allowed to manage this mannequin.");
			return 0;
		}
	}

	switch (selectedID) {
	case RadialOptions::SERVER_MENU1:
		return 0;
	case RadialOptions::SERVER_MENU2:
		sendEquipList(sceneObject, player, false);
		return 0;
	case RadialOptions::SERVER_MENU3:
		sendEquipList(sceneObject, player, true);
		return 0;
	case RadialOptions::SERVER_MENU4:
		sendRemoveList(sceneObject, player);
		return 0;
	case RadialOptions::SERVER_MENU5:
		removeAll(sceneObject, player);
		return 0;
	case RadialOptions::SERVER_MENU6:
		pickUp(sceneObject, player);
		return 0;
	default:
		break;
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}

void MannequinMenuComponent::sendEquipList(SceneObject* mannequin, CreatureObject* player, bool weaponMode) const {
	auto ghost = player->getPlayerObject();
	auto zoneServer = player->getZoneServer();

	if (ghost == nullptr || zoneServer == nullptr)
		return;

	ManagedReference<SceneObject*> inventory = player->getInventory();

	if (inventory == nullptr)
		return;

	int windowType = weaponMode ? SuiWindowType::MANNEQUIN_EQUIP_WEAPON : SuiWindowType::MANNEQUIN_EQUIP;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, windowType);
	box->setUsingObject(mannequin);
	box->setForceCloseDistance(8.f);
	box->setCallback(new MannequinSuiCallback(zoneServer));
	box->setCancelButton(true, "@cancel");
	box->setPromptTitle(weaponMode ? "Equip Weapon" : "Equip Clothing / Armor");
	box->setPromptText(weaponMode
		? "Select a weapon from your inventory to display on this mannequin."
		: "Select a clothing or armor item from your inventory to display on this mannequin.");

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> item = inventory->getContainerObject(i);

		if (item == nullptr)
			continue;

		bool eligible = weaponMode ? item->isWeaponObject() : item->isWearableObject();

		if (!eligible)
			continue;

		box->addMenuItem(item->getDisplayedName(), item->getObjectID());
	}

	if (box->getMenuSize() == 0) {
		player->sendSystemMessage(weaponMode
			? "You have no weapons in your inventory to display."
			: "You have no clothing or armor in your inventory to display.");
		return;
	}

	ghost->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void MannequinMenuComponent::sendRemoveList(SceneObject* mannequin, CreatureObject* player) const {
	auto ghost = player->getPlayerObject();
	auto zoneServer = player->getZoneServer();

	if (ghost == nullptr || zoneServer == nullptr)
		return;

	ManagedReference<MannequinObject*> mann = cast<MannequinObject*>(mannequin);

	if (mann == nullptr)
		return;

	ManagedReference<WeaponObject*> defaultWeapon = mann->getDefaultWeapon();
	uint64 defaultWeaponID = defaultWeapon != nullptr ? defaultWeapon->getObjectID() : 0;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::MANNEQUIN_REMOVE);
	box->setUsingObject(mannequin);
	box->setForceCloseDistance(8.f);
	box->setCallback(new MannequinSuiCallback(zoneServer));
	box->setCancelButton(true, "@cancel");
	box->setPromptTitle("Remove Equipment");
	box->setPromptText("Select an item to return to your inventory.");

	for (int i = 0; i < mann->getSlottedObjectsSize(); ++i) {
		ManagedReference<SceneObject*> child = mann->getSlottedObject(i);

		if (child == nullptr || child->getObjectID() == defaultWeaponID)
			continue;

		if (child->isWearableObject() || child->isWeaponObject())
			box->addMenuItem(child->getDisplayedName(), child->getObjectID());
	}

	if (box->getMenuSize() == 0) {
		player->sendSystemMessage("This mannequin is not displaying any equipment.");
		return;
	}

	ghost->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void MannequinMenuComponent::removeAll(SceneObject* mannequin, CreatureObject* player) const {
	ManagedReference<MannequinObject*> mann = cast<MannequinObject*>(mannequin);

	if (mann == nullptr)
		return;

	ManagedReference<SceneObject*> inventory = player->getInventory();

	if (inventory == nullptr)
		return;

	ManagedReference<WeaponObject*> defaultWeapon = mann->getDefaultWeapon();
	uint64 defaultWeaponID = defaultWeapon != nullptr ? defaultWeapon->getObjectID() : 0;

	// Collect the items to move.
	Vector<ManagedReference<TangibleObject*> > items;

	for (int i = 0; i < mann->getSlottedObjectsSize(); ++i) {
		ManagedReference<SceneObject*> child = mann->getSlottedObject(i);

		if (child == nullptr || child->getObjectID() == defaultWeaponID)
			continue;

		if (child->isWearableObject() || child->isWeaponObject())
			items.add(child.castTo<TangibleObject*>());
	}

	if (items.size() == 0) {
		player->sendSystemMessage("This mannequin is not displaying any equipment.");
		return;
	}

	// Pre-flight: make sure everything can be returned before moving anything.
	int freeSlots = (int) inventory->getContainerVolumeLimit() - inventory->getContainerObjectsSize();

	if (inventory->isContainerFullRecursive() || freeSlots < items.size()) {
		player->sendSystemMessage("You do not have enough inventory space to remove all equipment from this mannequin.");
		return;
	}

	int moved = 0;

	for (int i = 0; i < items.size(); ++i) {
		ManagedReference<TangibleObject*> item = items.get(i);

		Locker plocker(player);
		Locker mlocker(mann, player);
		Locker ilocker(item, player);

		TransactionLog trx(mann, player, item, TrxCode::PLAYERMISCACTION);

		if (!inventory->transferObject(item, -1, true)) {
			trx.abort() << "transferObject failed during REMOVE_ALL";
			break;
		}

		inventory->broadcastObject(item, true);
		trx.commit();
		++moved;
	}

	mann->info(true) << "REMOVE_ALL player=" << player->getObjectID() << " mannequin=" << mann->getObjectID()
		<< " moved=" << moved << " of=" << items.size();

	if (moved == items.size())
		player->sendSystemMessage("All equipment returned to your inventory.");
	else
		player->sendSystemMessage("Some equipment could not be returned and remains on the mannequin.");
}

void MannequinMenuComponent::pickUp(SceneObject* mannequin, CreatureObject* player) const {
	ManagedReference<MannequinObject*> mann = cast<MannequinObject*>(mannequin);
	auto zoneServer = player->getZoneServer();

	if (mann == nullptr || zoneServer == nullptr)
		return;

	if (!mann->isMannequinEmpty()) {
		player->sendSystemMessage("This mannequin is currently displaying equipment. Remove all equipment before picking it up.");
		return;
	}

	ManagedReference<SceneObject*> inventory = player->getInventory();

	if (inventory == nullptr || inventory->isContainerFullRecursive()) {
		player->sendSystemMessage("You do not have enough inventory space to pick up this mannequin.");
		return;
	}

	// Mannequin object templates and their deeds are parallel by name:
	//   object/mobile/bellum/mannequin_<species>_<gender>.iff
	//   object/tangible/deed/mannequin/mannequin_<species>_<gender>_deed.iff
	String templ = mann->getObjectTemplate()->getFullTemplateString();
	String deedTemplate;

	int slash = templ.lastIndexOf('/');
	int dot = templ.lastIndexOf(".iff");

	if (slash != -1 && dot != -1 && dot > slash) {
		String key = templ.subString(slash + 1, dot); // e.g. "mannequin_wookiee_female"
		deedTemplate = "object/tangible/deed/mannequin/" + key + "_deed.iff";
	} else {
		// Fallback for any unexpected template name.
		deedTemplate = templ.contains("female")
			? "object/tangible/deed/mannequin/mannequin_human_female_deed.iff"
			: "object/tangible/deed/mannequin/mannequin_human_male_deed.iff";
	}

	Locker plocker(player);
	Locker mlocker(mann, player);

	ManagedReference<SceneObject*> deed = zoneServer->createObject(deedTemplate.hashCode(), 1);

	if (deed == nullptr) {
		player->sendSystemMessage("The mannequin could not be picked up.");
		return;
	}

	Locker dlocker(deed, player);

	TransactionLog trx(mann, player, deed, TrxCode::PLAYERMISCACTION);

	if (!inventory->transferObject(deed, -1, true)) {
		trx.abort() << "deed transfer failed";
		deed->destroyObjectFromDatabase(true);
		player->sendSystemMessage("The mannequin could not be picked up.");
		return;
	}

	inventory->broadcastObject(deed, true);
	trx.commit();

	mann->info(true) << "PICKUP player=" << player->getObjectID() << " mannequin=" << mann->getObjectID();

	mann->destroyObjectFromWorld(true);
	mann->destroyObjectFromDatabase(true);

	player->sendSystemMessage("Mannequin picked up.");
}
