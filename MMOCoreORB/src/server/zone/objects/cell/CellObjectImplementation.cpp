/*
 * CellObjectImplementation.cpp
 *
 *  Created on: 23/07/2009
 *      Author: TheAnswer
 */

#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/packets/cell/CellObjectMessage3.h"
#include "server/zone/packets/cell/CellObjectMessage6.h"
#include "server/zone/packets/cell/UpdateCellPermissionsMessage.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/Zone.h"
#include "server/zone/objects/tangible/tool/CraftingStation.h"
#include "server/zone/objects/ship/PobShipObject.h"
// ADDED:
#include "server/zone/objects/structure/StructureObject.h"

void CellObjectImplementation::initializeTransientMembers() {
	SceneObjectImplementation::initializeTransientMembers();

	setLoggingName("CellObject");

	if (isClientObject()) {
		containerObjects.setNormalLoadOperationMode();
		containerObjects.cancelUnloadTask();
	}
}

void CellObjectImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	SceneObjectImplementation::loadTemplateData(templateData);

	containerObjects.setDelayedLoadOperationMode();
}

void CellObjectImplementation::notifyLoadFromDatabase() {
	SceneObjectImplementation::notifyLoadFromDatabase();

	// Rebuild count to account for transient creos
	// TODO: modify server shutdown to despawn transient mobs before final db save
	if (!isClientObject() && (!containerObjects.hasDelayedLoadOperationMode() || hasForceLoadObject())) {
		containerObjects.setDelayedLoadOperationMode();
		forceLoadObjectCount.set(0);

		for (int j = 0; j < getContainerObjectsSize(); ++j) {
			SceneObject* child = getContainerObject(j);

			if (child->isCreatureObject() || child->isVendor() || child->getPlanetMapCategoryCRC() != 0 || child->getPlanetMapSubCategoryCRC() != 0)
				forceLoadObjectCount.increment();
		}
	}
}

void CellObjectImplementation::onContainerLoaded() {
	SceneObjectImplementation::onContainerLoaded();

	ManagedReference<BuildingObject*> building = parent.get().castTo<BuildingObject*>();

	if (building == nullptr)
		return;

	Locker locker(building);

	for (int j = 0; j < getContainerObjectsSize(); ++j) {
		SceneObject* child = getContainerObject(j);

		building->notifyObjectInsertedToChild(child, asSceneObject(), nullptr);
	}
}

void CellObjectImplementation::onBuildingInsertedToZone(BuildingObject* building) {
	if (!isContainerLoaded())
		return;

	for (int j = 0; j < getContainerObjectsSize(); ++j) {
		SceneObject* child = getContainerObject(j);

		building->notifyObjectInsertedToZone(child);
	}
}

void CellObjectImplementation::onShipInsertedToZone(PobShipObject* pobShip) {
	if (pobShip == nullptr) {
		return;
	}

	for (int j = 0; j < getContainerObjectsSize(); ++j) {
		SceneObject* child = getContainerObject(j);

		if (child == nullptr) {
			continue;
		}

		// info(true) << pobShip->getDisplayedName() << " -- PobShip is broadcasting contained object: " << child->getDisplayedName();

		pobShip->notifyObjectInsertedToZone(child);
	}
}

void CellObjectImplementation::sendContainerObjectsTo(SceneObject* player, bool forceLoad) {
}

void CellObjectImplementation::sendBaselinesTo(SceneObject* player) {
	BaseMessage* cellMsg3 = new CellObjectMessage3(getObjectID(), cellNumber);
	player->sendMessage(cellMsg3);

	BaseMessage* cellMsg6 = new CellObjectMessage6(getObjectID());
	player->sendMessage(cellMsg6);

	bool allowEntry = true;

	ManagedReference<SceneObject*> strongParent = getParent().get();

	if (player->isCreatureObject() && strongParent != nullptr && strongParent->isBuildingObject()) {
		CreatureObject* creature = player->asCreatureObject();

		allowEntry = strongParent->asBuildingObject()->isAllowedEntry(creature);
	}

	BaseMessage* perm = new UpdateCellPermissionsMessage(getObjectID(), allowEntry);
	player->sendMessage(perm);
}

int CellObjectImplementation::canAddObject(SceneObject* object, int containmentType, String& errorDescription) {
	ManagedReference<SceneObject*> strongParent = getParent().get();

	if (strongParent != nullptr && (strongParent->isBuildingObject() || strongParent->isPobShip())) {
		int count = 1;

		if (object->isVendor()) {
			count = 0;
		} else if (object->isContainerObject()) {
			count += object->getCountableObjectsRecursive();
		}

		if ((strongParent->getCurrentNumberOfPlayerItems() + count) > strongParent->getMaximumNumberOfPlayerItems()) {
			errorDescription = "@container_error_message:container13"; // This house has too many items in it

			return TransferErrorCode::TOOMANYITEMSINHOUSE;
		}
	}

	return SceneObjectImplementation::canAddObject(object, containmentType, errorDescription);
}

bool CellObjectImplementation::transferObject(SceneObject* object, int containmentType, bool notifyClient, bool allowOverflow, bool notifyRoot) {
	// Locker locker(_this);

	Zone* zone = getZone();

	Locker* locker = nullptr;

	if (zone != nullptr) {
		// locker = new Locker(zone);
	}

	bool ret = false;

	ManagedReference<SceneObject*> oldParent = object->getParent().get();

	try {
		ret = SceneObjectImplementation::transferObject(object, containmentType, notifyClient, allowOverflow, notifyRoot);

		if (zone != nullptr && object->isTangibleObject()) {
			TangibleObject* tano = cast<TangibleObject*>(object);

			if (tano != nullptr) {
				zone->updateActiveAreas(tano);
			}

			// PobShip Cell Fires from Plasma Conduits
			if (cellFireVariable > 0.f && object->isPlayerCreature()) {
				Reference<CreatureObject*> player = object->asCreatureObject();
				Reference<CellObject*> cellRef = _this.getReferenceUnsafeStaticCast();

				if (player != nullptr) {
					Core::getTaskManager()->executeTask([player, cellRef]() {
						if (player == nullptr || cellRef == nullptr) {
							return;
						}

						Locker locker(player);

						if (cellRef->getCellFireVariable() < 1.f) {
							if (player->hasState(CreatureState::ONFIRE)) {
								player->clearState(CreatureState::ONFIRE, true);
							}
							return;
						}

						if (player->hasState(CreatureState::ONFIRE)) {
							return;
						}

						player->setState(CreatureState::ONFIRE, true);
						player->sendSystemMessage("@space/space_interaction:plasma_leak_begin"); // "This area of the ship has a PLASMA LEAK! It begins to scorch the flesh from your bones!"

					}, "EntryCellFireLambda");
				}
			}
		}

		if (object->isCreatureObject() || object->isVendor() || object->getPlanetMapCategoryCRC() != 0 || object->getPlanetMapSubCategoryCRC() != 0) {
			forceLoadObjectCount.increment();
		}
	} catch (...) {
	}

	// === BEGIN: apply structure skillMods when a creature ENTERS the building ===
	if (object->isCreatureObject()) {
		CreatureObject* creature = object->asCreatureObject();

		// Root of the building we just entered
		SceneObject* currentRoot = getRootParent();
		// Root of where we came from before the transfer (could be null if outside)
		SceneObject* prevRoot = nullptr;
		if (oldParent != nullptr)
			prevRoot = oldParent->getRootParent();

		// Only add on first entry to this building (NOT when swapping between its cells)
		if (currentRoot != nullptr && currentRoot->isStructureObject() && currentRoot != prevRoot) {
			StructureObject* structure = cast<StructureObject*>(currentRoot);

			// Push building template skillMods onto the creature
			structure->addTemplateSkillMods(creature);

			// DEBUG: show all relevant building mods
			int mind = creature->getSkillMod("private_buff_mind");
			int med  = creature->getSkillMod("private_medical_rating");
			int bf   = creature->getSkillMod("private_med_battle_fatigue");

			StringBuffer dbg;
			dbg << "Entered building mods — ";
			bool any = false;
			if (mind > 0) { dbg << "private_buff_mind=" << mind; any = true; }
			if (med  > 0) { if (any) dbg << " | "; dbg << "private_medical_rating=" << med; any = true; }
			if (bf   > 0) { if (any) dbg << " | "; dbg << "private_med_battle_fatigue=" << bf; any = true; }
			if (!any) dbg << "none.";
			creature->sendSystemMessage(dbg.toString());
		}
	}
	// === END: apply structure skillMods on building entry ===

	if (oldParent == nullptr) {
		ManagedReference<SceneObject*> strongParent = parent.get().castTo<SceneObject*>();

		if (strongParent != nullptr) {
			if (strongParent->isBuildingObject()) {
				ManagedReference<BuildingObject*> building = parent.get().castTo<BuildingObject*>();
				CreatureObject* creo = object->asCreatureObject();

				if (building != nullptr && creo != nullptr)
					building->onEnter(creo);
			}
		}
	}

	if (locker != nullptr)
		delete locker;

	return ret;
}

bool CellObjectImplementation::removeObject(SceneObject* object, SceneObject* destination, bool notifyClient, bool nullifyParent) {
	bool ret = SceneObjectImplementation::removeObject(object, destination, notifyClient, nullifyParent);

	if (object->isCreatureObject() || object->isVendor() || object->getPlanetMapCategoryCRC() != 0 || object->getPlanetMapSubCategoryCRC() != 0) {
		forceLoadObjectCount.decrement();
	}

	// PobShip Cell Fires from Plasma Conduits
	if (cellFireVariable > 0.f && object->isPlayerCreature()) {
		Reference<CreatureObject*> player = object->asCreatureObject();

		if (player != nullptr) {
			Core::getTaskManager()->executeTask([player]() {
				if (player == nullptr) {
					return;
				}

				Locker locker(player);

				if (!player->hasState(CreatureState::ONFIRE)) {
					return;
				}

				player->clearState(CreatureState::ONFIRE, true);

				player->sendSystemMessage("@space/space_interaction:plasma_leak_end"); // "You have successfully escaped the scorching flames of the plasma leak."
			}, "RemoveCellFireLambda");
		}
	}

	// === BEGIN: remove structure skillMods when a creature LEAVES the building ===
	if (object->isCreatureObject()) {
		CreatureObject* creature = object->asCreatureObject();

		// Root of the building we are leaving (this cell's root)
		SceneObject* currentRoot = getRootParent();
		// Root of the destination (might be another cell of same building)
		SceneObject* destRoot = nullptr;
		if (destination != nullptr)
			destRoot = destination->getRootParent();

		// Only remove if destination is NOT in the same building (i.e., truly leaving)
		if (currentRoot != nullptr && currentRoot->isStructureObject() && currentRoot != destRoot) {
			StructureObject* structure = cast<StructureObject*>(currentRoot);

			structure->removeTemplateSkillMods(creature);

			// DEBUG: show resulting values after removal
			int mind = creature->getSkillMod("private_buff_mind");
			int med  = creature->getSkillMod("private_medical_rating");
			int bf   = creature->getSkillMod("private_med_battle_fatigue");

			StringBuffer dbg;
			dbg << "Left building mods — ";
			bool any = false;
			if (mind != 0) { dbg << "private_buff_mind=" << mind; any = true; }
			if (med  != 0) { if (any) dbg << " | "; dbg << "private_medical_rating=" << med; any = true; }
			if (bf   != 0) { if (any) dbg << " | "; dbg << "private_med_battle_fatigue=" << bf; any = true; }
			if (!any) dbg << "all cleared.";
			creature->sendSystemMessage(dbg.toString());
		}
	}
	// === END: remove structure skillMods on building exit ===

	return ret;
}

int CellObjectImplementation::getCurrentNumberOfPlayerItems() {
	int count = 0;

	ManagedReference<SceneObject*> strongParent = getParent().get();

	if (strongParent != nullptr) {
		for (int j = 0; j < getContainerObjectsSize(); ++j) {
			ManagedReference<SceneObject*> containerObject = getContainerObject(j);

			if (!strongParent->containsChildObject(containerObject) && !containerObject->isCreatureObject() && !containerObject->isVendor()) {
				if (containerObject->isContainerObject()) {
					count += containerObject->getCountableObjectsRecursive();
				} else if (containerObject->isCraftingStation()) {
					ManagedReference<SceneObject*> hopper = containerObject->getSlottedObject("ingredient_hopper");

					if (hopper != nullptr) {
						count += hopper->getCountableObjectsRecursive();
					}
				}
				++count;
			}
		}
	}

	return count;
}

void CellObjectImplementation::destroyAllPlayerItems() {
	ManagedReference<SceneObject*> strongParent = getParent().get();

	if (strongParent == nullptr)
		return;

	int containerSize = getContainerObjectsSize();

	for (int j = containerSize - 1; j >= 0; --j) {
		ManagedReference<SceneObject*> containerObject = getContainerObject(j);

		if (strongParent->containsChildObject(containerObject))
			continue;

		if (containerObject->isCreatureObject())
			continue;

		Locker locker(containerObject);

		containerObject->destroyObjectFromWorld(true);
		containerObject->destroyObjectFromDatabase(true);
	}
}

void CellObjectImplementation::sendPermissionsTo(CreatureObject* creature, bool allowEntry) {
	if (!containerPermissions.hasInheritPermissionsFromParent() && !checkContainerPermission(creature, ContainerPermissions::WALKIN)) {
		BaseMessage* perm = new UpdateCellPermissionsMessage(getObjectID(), false);
		creature->sendMessage(perm);
	} else {
		BaseMessage* perm = new UpdateCellPermissionsMessage(getObjectID(), allowEntry);
		creature->sendMessage(perm);
	}
}

void CellObjectImplementation::setCellFireVariable(float damageVar) {
	// info(true) << "setting cellFireVar - " << damageVar;

	cellFireVariable += damageVar;

	// info(true) << "New cellFireVariable = " << cellFireVariable;

	if (cellFireVariable < 0.f) {
		cellFireVariable = 0.f;
	}
}
