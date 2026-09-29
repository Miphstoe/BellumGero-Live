/*
 * DoctorServiceHopperContainerComponent.cpp
 *
 * Bellum Gero - FMDoctorBot
 *
 * Persistent owner-only medical supply hopper.
 * Phase 3 accepts Standard/Janta Doctor Enhance Packs, Poison/Disease Resistance
 * Enhance Packs, and Bivoli Tempari. Wound packs and arbitrary items are rejected.
 */

#include "DoctorServiceHopperContainerComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/TransferErrorCode.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"

namespace {
const uint32 kDoctorServiceUnitCRC = String("object/tangible/vendor/doctor_service_unit.iff").hashCode();
}

bool DoctorServiceHopperContainerComponent::checkContainerPermission(
	SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const {
	if (sceneObject == nullptr || creature == nullptr)
		return false;
	PlayerObject* ghost = creature->getPlayerObject();
	if (ghost != nullptr && ghost->isPrivileged())
		return true;
	ManagedReference<SceneObject*> station = sceneObject->getParent().get();
	if (station == nullptr || station->getServerObjectCRC() != kDoctorServiceUnitCRC)
		return false;
	DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(station);
	if (data == nullptr || !data->isOwner(creature)) {
		creature->sendSystemMessage("Only the owning Doctor can access this Medical Supply Hopper.");
		return false;
	}
	return true;
}

int DoctorServiceHopperContainerComponent::canAddObject(
	SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {
	if (sceneObject == nullptr || object == nullptr)
		return TransferErrorCode::CANTADD;
	if (!DoctorBuffDroidMenuComponent::isDoctorServiceSupply(object)) {
		errorDescription =
			"Medical Supply Hoppers accept Standard/Janta Doctor Enhance Packs "
			"(Health, Action, Strength, Constitution, Quickness, Stamina), "
			"Poison/Disease Resistance Enhance Packs, and Bivoli Tempari.";
		return TransferErrorCode::INVALIDTYPE;
	}
	return ContainerComponent::canAddObject(sceneObject, object, containmentType, errorDescription);
}
