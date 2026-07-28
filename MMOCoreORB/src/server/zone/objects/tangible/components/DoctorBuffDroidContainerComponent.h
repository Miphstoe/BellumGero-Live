#ifndef DOCTORBUFFDROIDCONTAINERCOMPONENT_H_
#define DOCTORBUFFDROIDCONTAINERCOMPONENT_H_

#include "server/zone/objects/scene/components/ContainerComponent.h"

class DoctorBuffDroidContainerComponent : public ContainerComponent {
public:
	bool checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const;
};

#endif /* DOCTORBUFFDROIDCONTAINERCOMPONENT_H_ */
