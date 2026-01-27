/*
 * HolocronDestinyMenuComponent.h
 *
 *  Created on: 01/23/2026
 *      Author: Miphstoe
 */

#ifndef HOLOCRONDESTINYMENUCOMPONENT_H_
#define HOLOCRONDESTINYMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class HolocronDestinyMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* HOLOCRONDESTINYMENUCOMPONENT_H_ */
