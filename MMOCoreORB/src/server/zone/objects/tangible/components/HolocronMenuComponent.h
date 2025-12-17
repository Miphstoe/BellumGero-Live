/*
 * HolocronMenuComponent.h
 *
 *  Created on: 01/23/2012
 *      Author: xyborn
 */

#ifndef HOLOCRONMENUCOMPONENT_H_
#define HOLOCRONMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class HolocronMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;

private:
	static const uint8 RADIAL_LOCK_ITEM = 220;
	static const uint8 RADIAL_UNLOCK_ITEM = 221;
};


#endif /* HOLOCRONMENUCOMPONENT_H_ */
