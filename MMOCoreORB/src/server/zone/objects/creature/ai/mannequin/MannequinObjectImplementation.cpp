/*
 * MannequinObjectImplementation.cpp
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 */

#include "server/zone/objects/creature/ai/mannequin/MannequinObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/packets/scene/AttributeListMessage.h"
#include "templates/params/OptionBitmask.h"

void MannequinObjectImplementation::initializeTransientMembers() {
	AiAgentImplementation::initializeTransientMembers();

	setLoggingName("MannequinObject");

	// Belt-and-braces: a mannequin must never run the AI FSM even if a template
	// accidentally sets AIENABLED. activateAiBehavior() early-outs without this bit.
	clearOptionBit(OptionBitmask::AIENABLED, false);

	// Re-assert the stored idle pose after (re)load.
	refreshDisplay();
}

void MannequinObjectImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	AiAgentImplementation::loadTemplateData(templateData);

	// Force the mannequin to be inert regardless of template contents.
	clearOptionBit(OptionBitmask::AIENABLED, false);
	pvpStatusBitmask = 0;
}

void MannequinObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	AiAgentImplementation::fillAttributeList(alm, object);

	if (!poseString.isEmpty())
		alm->insertAttribute("mannequin_pose", poseString);
}

bool MannequinObjectImplementation::isMannequinEmpty() {
	ManagedReference<WeaponObject*> defaultWeapon = getDefaultWeapon();
	uint64 defaultWeaponID = defaultWeapon != nullptr ? defaultWeapon->getObjectID() : 0;

	for (int i = 0; i < getSlottedObjectsSize(); ++i) {
		ManagedReference<SceneObject*> child = getSlottedObject(i);

		if (child == nullptr)
			continue;

		if (child->getObjectID() == defaultWeaponID)
			continue;

		if (child->isWearableObject() || child->isWeaponObject())
			return false;
	}

	return true;
}

void MannequinObjectImplementation::refreshDisplay() {
	// Slotted children are re-sent automatically whenever the creature is sent to a
	// client; this only re-applies the persistent idle pose.
	if (!poseString.isEmpty())
		doAnimation(poseString);
}
