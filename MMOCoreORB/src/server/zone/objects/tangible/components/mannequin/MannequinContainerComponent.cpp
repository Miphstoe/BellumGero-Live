/*
 * MannequinContainerComponent.cpp
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 */

#include "MannequinContainerComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/SceneObjectType.h"
#include "server/zone/objects/scene/TransferErrorCode.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/mannequin/MannequinObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"

bool MannequinContainerComponent::isAuthorized(SceneObject* mannequin, CreatureObject* player) {
	if (mannequin == nullptr || player == nullptr)
		return false;

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost != nullptr && ghost->isPrivileged())
		return true;

	ManagedReference<MannequinObject*> mann = mannequin->isMannequinObject() ? cast<MannequinObject*>(mannequin) : nullptr;

	if (mann != nullptr && mann->getMannequinOwnerID() == player->getObjectID())
		return true;

	ManagedReference<StructureObject*> structure = cast<StructureObject*>(mannequin->getRootParent());

	if (structure != nullptr && structure->isOnAdminList(player))
		return true;

	return false;
}

bool MannequinContainerComponent::checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const {
	if (sceneObject == nullptr || creature == nullptr)
		return false;

	return isAuthorized(sceneObject, creature);
}

int MannequinContainerComponent::canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {
	if (object == nullptr)
		return TransferErrorCode::CANTADD;

	// Only real wearables and weapons may be displayed, and only into an equipment slot group.
	if (containmentType < 4 || !(object->isWearableObject() || object->isWeaponObject())) {
		errorDescription = "Only wearable clothing, armor or weapons can be displayed on a mannequin.";
		return TransferErrorCode::INVALIDTYPE;
	}

	// Inherit the stock slot-conflict / arrangement validation (fails safe, never destroys).
	return ContainerComponent::canAddObject(sceneObject, object, containmentType, errorDescription);
}
