/*
 * LytusFamilyArtefactMenuComponent.h
 */

#ifndef LYTUSFAMILYARTEFACTMENUCOMPONENT_H_
#define LYTUSFAMILYARTEFACTMENUCOMPONENT_H_

#include "SkillBuffObjectMenuComponent.h"

/**
 * Radial "use" handler for the Lytus Family Artifact consumable.
 * Grants a temporary +5% outgoing damage buff to non-Jedi players.
 *
 * The lightsaber exclusion is NOT enforced here -- it is enforced at
 * damage-calculation time in CombatManager::applyDamageModifiers, so the
 * bonus never applies to lightsaber damage regardless of what weapon is
 * equipped when the buff is used or later swapped to.
 *
 * This item's appearance (shared_lytus_family_artefact.iff) is baked
 * client-side as GOT FURNITURE, which the client does not treat as
 * "usable" by default, so unlike SkillBuffObjectMenuComponent this class
 * must explicitly add the "Use" radial option itself (fillObjectMenuResponse)
 * rather than relying on the client to propose it.
 */
class LytusFamilyArtefactMenuComponent : public SkillBuffObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* LYTUSFAMILYARTEFACTMENUCOMPONENT_H_ */
