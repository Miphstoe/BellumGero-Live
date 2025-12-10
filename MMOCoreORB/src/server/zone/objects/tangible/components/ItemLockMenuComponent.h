/*
 * ItemLockMenuComponent.h
 * Adds "Lock Item" and "Unlock Item" radial menu options to all tangible objects
 */

#ifndef ITEMLOCKMENUCOMPONENT_H_
#define ITEMLOCKMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class ItemLockMenuComponent : public TangibleObjectMenuComponent {
public:
	/**
	 * Fills the radial options
	 * @pre { this object is locked }
	 * @post { this object is locked, menuResponse is complete}
	 * @param sceneObject reference to SceneObject
	 * @param menuResponse ObjectMenuResponse that will be sent to client
	 * @param player CreatureObject player who is accessing the radial menu
	 */
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	/**
	 * Handles the radial selection
	 * @pre { this object is locked, player is locked }
	 * @post { this object is locked, player is locked }
	 * @param sceneObject reference to SceneObject
	 * @param player CreatureObject that selected the option
	 * @param selectedID the selected menu id
	 * @returns 0 if passed, 1 if action failed
	 */
	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;

private:
	static const uint8 RADIAL_LOCK_ITEM = 220;
	static const uint8 RADIAL_UNLOCK_ITEM = 221;
};

#endif /* ITEMLOCKMENUCOMPONENT_H_ */
