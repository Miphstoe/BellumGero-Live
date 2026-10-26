/*
 * DoctorServiceHopperContainerComponent.h
 *
 * Bellum Gero - FMDoctorBot
 */

#ifndef DOCTORSERVICEHOPPERCONTAINERCOMPONENT_H_
#define DOCTORSERVICEHOPPERCONTAINERCOMPONENT_H_

#include "server/zone/objects/scene/components/ContainerComponent.h"

class DoctorServiceHopperContainerComponent : public ContainerComponent {
public:
	int canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const override;
	bool checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const override;
};

#endif /* DOCTORSERVICEHOPPERCONTAINERCOMPONENT_H_ */
