/*
 * 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "DroidItemStorageModuleDataComponent.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/creature/ai/DroidObject.h"

DroidItemStorageModuleDataComponent::DroidItemStorageModuleDataComponent() {
	setLoggingName("DroidItemStorageModule");
	rating = 0;
}

DroidItemStorageModuleDataComponent::~DroidItemStorageModuleDataComponent() {

}

String DroidItemStorageModuleDataComponent::getModuleName() const {
	return String("item_storage_module");
}

void DroidItemStorageModuleDataComponent::initializeTransientMembers() {
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent == nullptr) {
		info("droidComponent was null");
		return;
	}

	if(droidComponent->hasKey("storage_module")) {
		rating = droidComponent->getAttributeValue("storage_module");
	}
}

void DroidItemStorageModuleDataComponent::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	rating = values->getCurrentValue("storage_module");
}

int DroidItemStorageModuleDataComponent::getStorageRating() {
    // cap raw rating at 100
    const int r = rating > 100 ? 100 : rating;

    if      (r <= 10)  return 1;  //  1–10 → Module_1
    else if (r <= 20)  return 2;  // 11–20 → Module_2
    else if (r <= 40)  return 3;  // 21–40 → Module_3
    else if (r <= 60)  return 4;  // 41–60 → Module_4
    else if (r <= 80)  return 5;  // 61–80 → Module_5
    else               return 6;  // 81–100 → Module_6
}

void DroidItemStorageModuleDataComponent::fillAttributeList(AttributeListMessage* alm, CreatureObject* droid) {
	// convert module rating to actual rating
	alm->insertAttribute( "storage_module", rating > 100 ? 100 : rating );
}

String DroidItemStorageModuleDataComponent::toString() const {
	return BaseDroidModuleComponent::toString();
}

void DroidItemStorageModuleDataComponent::addToStack(BaseDroidModuleComponent* other) {
	DroidItemStorageModuleDataComponent* otherModule = cast<DroidItemStorageModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	rating = rating + otherModule->rating;

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent != nullptr)
		droidComponent->changeAttributeValue("storage_module", (float)rating);
}

void DroidItemStorageModuleDataComponent::copy(BaseDroidModuleComponent* other) {
	DroidItemStorageModuleDataComponent* otherModule = cast<DroidItemStorageModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	rating = otherModule->rating;

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent != nullptr)
		droidComponent->addProperty("storage_module", (float)rating, 0, "exp_effectiveness");
}

void DroidItemStorageModuleDataComponent::onCall() {
	// no op
}

void DroidItemStorageModuleDataComponent::onStore() {
	// no op on store
}

void DroidItemStorageModuleDataComponent::fillObjectMenuResponse(SceneObject* droidObject, ObjectMenuResponse* menuResponse, CreatureObject* player) {
	// Add to Droid Options subradial from PetMenuComponent
	menuResponse->addRadialMenuItemToRadialID(132, ITEM_STORAGE_MODULE_OPEN, 3, "@pet/pet_menu:menu_command_open");
}

void DroidItemStorageModuleDataComponent::initialize(DroidObject* droid) {
	StringBuffer path;
	path.append("object/tangible/inventory/creature_inventory_");
	path.append(getStorageRating());
	path.append(".iff");

	ManagedReference<SceneObject*> inventory = droid->getZoneServer()->createObject(path.toString().hashCode(), 1);
	if (inventory == nullptr) {
		return;
	}

	ManagedReference<SceneObject*> droidInvorty = droid->getSlottedObject("inventory");
	if (droidInvorty) {
		droid->removeObject(droidInvorty, nullptr, true);
		droidInvorty->destroyObjectFromDatabase(true);
	}

	if (!droid->transferObject(inventory, 4, true)) {
		inventory->destroyObjectFromDatabase(true);
	}
}

int DroidItemStorageModuleDataComponent::handleObjectMenuSelect(CreatureObject* player, byte selectedID, PetControlDevice* controller) {
	// Handle open droid storage
	if (selectedID == ITEM_STORAGE_MODULE_OPEN) {

		ManagedReference<DroidObject*> droid = getDroidObject();
		if (droid == nullptr) {
			info("Droid is null");
			return 0;
		}

		Locker dlock(droid, player);

		// open the inventory slot of the droid
		ManagedReference<SceneObject*> inventory = droid->getSlottedObject("inventory");

		if (inventory != nullptr) {
			inventory->openContainerTo(player);
		}
	}

	return 0;
}
