/*
 * HolocronDestinyMenuComponent.h
 *
 *  Created on: 01/23/2026
 *      Author: Miphstoe
 */

#ifndef HOLOCRONDESTINYMENUCOMPONENT_H_
#define HOLOCRONDESTINYMENUCOMPONENT_H_

#include "CityDecorationMenuComponent.h"

class HolocronDestinyMenuComponent : public CityDecorationMenuComponent {
public:
	static const uint8 RADIAL_LOCK_ITEM = 220;
	static const uint8 RADIAL_UNLOCK_ITEM = 221;

	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* HOLOCRONDESTINYMENUCOMPONENT_H_ */
