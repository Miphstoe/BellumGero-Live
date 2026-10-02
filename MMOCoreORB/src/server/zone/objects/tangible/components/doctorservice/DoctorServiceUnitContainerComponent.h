/*
 * DoctorServiceUnitContainerComponent.h
 *
 * Bellum Gero - FMDoctorBot
 * The station may contain exactly one server-created Medical Supply Hopper.
 */

#ifndef DOCTORSERVICEUNITCONTAINERCOMPONENT_H_
#define DOCTORSERVICEUNITCONTAINERCOMPONENT_H_

#include "server/zone/objects/scene/components/ContainerComponent.h"

class DoctorServiceUnitContainerComponent : public ContainerComponent {
public:
	int canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const override;
	bool checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const override;
};

#endif /* DOCTORSERVICEUNITCONTAINERCOMPONENT_H_ */
