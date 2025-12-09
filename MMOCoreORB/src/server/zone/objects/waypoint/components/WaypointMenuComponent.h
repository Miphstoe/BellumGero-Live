/*
 * WaypointMenuComponent.h
 *
 * Handles radial menu options for waypoint objects, including color selection
 */

#ifndef WAYPOINTMENUCOMPONENT_H_
#define WAYPOINTMENUCOMPONENT_H_

#include "server/zone/objects/scene/components/ObjectMenuComponent.h"

class WaypointMenuComponent : public ObjectMenuComponent {
public:
	/**
	 * Fills the radial options for waypoint objects
	 * @pre { this object is locked }
	 * @post { this object is locked, menuResponse is complete}
	 * @param sceneObject the waypoint object
	 * @param menuResponse ObjectMenuResponse that will be sent to the client
	 * @param player the player using the object
	 */
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	/**
	 * Handles the radial selection sent by the client
	 * @pre { this object is locked, player is locked }
	 * @post { this object is locked, player is locked }
	 * @param sceneObject the waypoint object
	 * @param player PlayerCreature that selected the option
	 * @param selectedID selected menu id
	 * @returns 0 if successful
	 */
	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* WAYPOINTMENUCOMPONENT_H_ */
