/*
 * DoctorServiceUnitDeedMenuComponent.h
 *
 * Bellum Gero - FMDoctorBot
 */

#ifndef DOCTORSERVICEUNITDEEDMENUCOMPONENT_H_
#define DOCTORSERVICEUNITDEEDMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class DoctorServiceUnitDeedMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const override;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const override;
};

#endif /* DOCTORSERVICEUNITDEEDMENUCOMPONENT_H_ */
