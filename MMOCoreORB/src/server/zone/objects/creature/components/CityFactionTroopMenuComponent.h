/*
 * CityFactionTroopMenuComponent.h
 */

#ifndef CITYFACTIONTROOPMENUCOMPONENT_H_
#define CITYFACTIONTROOPMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class CityFactionTroopMenuComponent : public TangibleObjectMenuComponent {
public:
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* CITYFACTIONTROOPMENUCOMPONENT_H_ */