#ifndef SEATOOLOBJECTMENUCOMPONENT_H_
#define SEATOOLOBJECTMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class SEAToolObjectMenuComponent : public TangibleObjectMenuComponent {
public:
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* SEATOOLOBJECTMENUCOMPONENT_H_ */
