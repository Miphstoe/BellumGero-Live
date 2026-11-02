/*
 * DecorFogMenuComponent.h
 * Adds a "Toggle Fog" radial option to fogged decorations (Hoth icicles, Jedi shrines)
 */

#ifndef DECORFOGMENUCOMPONENT_H_
#define DECORFOGMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class DecorFogMenuComponent : public TangibleObjectMenuComponent {
public:
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;

private:
	// The fog is the client data file's ONOF children, which the client shows while the
	// tangible's on/off condition (OptionBitmask::ACTIVATED) is set.
	static bool canToggleFog(SceneObject* sceneObject, CreatureObject* player);

	static const uint8 RADIAL_TOGGLE_FOG = 225;
};

#endif /* DECORFOGMENUCOMPONENT_H_ */
