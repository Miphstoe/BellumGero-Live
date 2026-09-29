/*
 * DoctorServiceUnitContainerComponent.cpp
 *
 * Bellum Gero - FMDoctorBot
 *
 * The parent station is intentionally not a player-accessible storage container.
 * It owns one persistent child hopper. Players interact with the hopper through the
 * Doctor Service Unit menu, never by moving/removing the hopper itself.
 */

#include "DoctorServiceUnitContainerComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/TransferErrorCode.h"

namespace {
const uint32 kDoctorServiceHopperCRC =
	String("object/tangible/hopper/doctor_service_supply_hopper.iff").hashCode();
}

int DoctorServiceUnitContainerComponent::canAddObject(
	SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {

	if (sceneObject == nullptr || object == nullptr) {
		errorDescription = "Invalid Automated Medical Station containment request.";
		return TransferErrorCode::CANTADD;
	}

	if (object->getServerObjectCRC() != kDoctorServiceHopperCRC) {
		errorDescription = "The Automated Medical Station may only contain its Medical Supply Hopper.";
		return TransferErrorCode::INVALIDTYPE;
	}

	if (sceneObject->getContainerObjectsSize() > 0) {
		errorDescription = "This Automated Medical Station already has a Medical Supply Hopper.";
		return TransferErrorCode::CONTAINERFULL;
	}

	return ContainerComponent::canAddObject(sceneObject, object, containmentType, errorDescription);
}

bool DoctorServiceUnitContainerComponent::checkContainerPermission(
	SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const {

	// Never expose the parent station as a normal container. This also prevents a
	// player-driven transfer from removing the persistent hopper child.
	return false;
}
