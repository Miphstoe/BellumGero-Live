/*
 * PlayerContainerComponent.cpp
 *
 *  Created on: 26/05/2011
 *      Author: victor
 */

#include "PlayerContainerComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "server/zone/objects/player/Races.h"
#include "server/zone/objects/tangible/wearables/ArmorObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/visibility/VisibilityManager.h"

int PlayerContainerComponent::canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return TransferErrorCode::PLAYERUSEMASKERROR;
	}

	// An arrangement type of 4 or greater places an object in a character slot;
	// some wearables have alternate arrangements beyond the first one.
	if (object->isTangibleObject() && containmentType >= 4 &&
			(object->isWearableObject() || object->isWearableContainerObject() ||
			object->isInstrument() || object->isFishingPoleObject())) {
		String race = creo->getObjectTemplate()->getFullTemplateString();
		String species = Races::getSpecies(Races::getRaceID(race));

		// Use the template race rather than the numeric species ID: Geonosians
		// share that ID with Wookiees.
		if (species == "ewok" || species == "hutt" || species == "ortolan" ||
				species == "geonosian" || species == "chadra_fan") {
			errorDescription = "This species can only equip weapons";
			return TransferErrorCode::PLAYERUSEMASKERROR;
		}
	}

	if (object->isTangibleObject() && containmentType == 4) {
		TangibleObject* wearable = cast<TangibleObject*>(object);

		SharedTangibleObjectTemplate* tanoData = dynamic_cast<SharedTangibleObjectTemplate*>(wearable->getObjectTemplate());
		String race = creo->getObjectTemplate()->getFullTemplateString();
		int raceId = Races::getRaceID(race);
		String species = Races::getSpecies(raceId);

		// BG: ignore playerRaces for wearables allowed by the species check above.
		if (tanoData != nullptr) {
			if (!object->isWearableObject()) {
				const auto races = tanoData->getPlayerRaces();

				if (!races->contains(race.hashCode())) {
					// Vanilla playerRaces lists only include the original 10 species.
					// Custom species can equip weapons and, except for Hutts,
					// other non-wearable objects when allowed above.
					bool isCustomSpecies = raceId >= 20 && raceId <= 66;
					bool isHutt = species == "hutt";
					bool bypassForCustomSpecies = isCustomSpecies && (object->isWeaponObject() || !isHutt);

					if (!bypassForCustomSpecies) {
						errorDescription = "You lack the necessary requirements to wear this object";
						return TransferErrorCode::PLAYERUSEMASKERROR;
					}
				}
			}
		}

		if (creo->isPlayerCreature()) {
			if (!wearable->isNeutral()) {
				if (wearable->isImperial() && (creo->getFactionStatus() == FactionStatus::ONLEAVE || !creo->isImperial())) {
					errorDescription = "You lack the necessary requirements to wear this object";

					return TransferErrorCode::PLAYERUSEMASKERROR;
				}

				if (wearable->isRebel() && (creo->getFactionStatus() == FactionStatus::ONLEAVE || !creo->isRebel())) {
					errorDescription = "You lack the necessary requirements to wear this object";

					return TransferErrorCode::PLAYERUSEMASKERROR;
				}
			}
		}

		if (object->isArmorObject()) {
			ArmorObject* armor = cast<ArmorObject*>(object);

			if (armor != nullptr && !armor->isCosmeticArmor()) {
				PlayerManager* playerManager = sceneObject->getZoneServer()->getPlayerManager();

				if (!playerManager->checkEncumbrancies(creo, armor)) {
					errorDescription = "You lack the necessary secondary stats to equip this item";

					return TransferErrorCode::NOTENOUGHENCUMBRANCE;
				}
			}
		}

		if (object->isWearableObject()) {
			if (tanoData != nullptr) {
				const Vector<String>& skillsRequired = tanoData->getCertificationsRequired();

				if (skillsRequired.size() > 0) {
					bool hasSkill = false;

					for (int i = 0; i < skillsRequired.size(); i++) {
						const String& skill = skillsRequired.get(i);

						if (!skill.isEmpty() && creo->hasSkill(skill)) {
							hasSkill = true;
							break;
						}
					}

					if (!hasSkill) {
						errorDescription = "@error_message:insufficient_skill"; // You lack the skill to use this item.

						return TransferErrorCode::PLAYERUSEMASKERROR;
					}
				}
			}
		}

		if (object->isWeaponObject()) {
			WeaponObject* weapon = cast<WeaponObject*>(object);
			int bladeColor = weapon->getBladeColor();
			PlayerObject* ghost = creo->getPlayerObject();

			if (weapon->isJediWeapon()) {
				if (bladeColor == 31) {
					errorDescription = "@jedi_spam:lightsaber_no_color";
					return TransferErrorCode::PLAYERUSEMASKERROR;
				}

				if (weapon->getCraftersID() != creo->getObjectID() && !ghost->isPrivileged()) {
					errorDescription = "@jedi_spam:not_your_lightsaber";
					return TransferErrorCode::PLAYERUSEMASKERROR;
				}
			}
		}
	}

	return ContainerComponent::canAddObject(sceneObject, object, containmentType, errorDescription);
}

/**
 * Is called when this object has been inserted with an object
 * @param object object that has been inserted
 */
int PlayerContainerComponent::notifyObjectInserted(SceneObject* sceneObject, SceneObject* object) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return 0;
	}

	bool cosmeticArmor = false;

	if (object->isArmorObject()) {
		ArmorObject* armor = cast<ArmorObject*>(object);
		cosmeticArmor = armor != nullptr && armor->isCosmeticArmor();

		if (!cosmeticArmor) {
			PlayerManager* playerManager = sceneObject->getZoneServer()->getPlayerManager();
			playerManager->applyEncumbrancies(creo, armor);
		}
	}

	if (object->isTangibleObject()) {
		ManagedReference<TangibleObject*> tano = object->asTangibleObject();

		if (tano != nullptr) {
			// creo->info(true) << "Adding template & wearable skill mods from: " << tano->getDisplayedName();

			tano->addTemplateSkillMods(creo);
			tano->applySkillModsTo(creo);
		}
	}

	if (object->isInstrument() && creo->isEntertaining()) {
		creo->stopEntertaining();
	}

	// Update wearables vector
	if (object->isTangibleObject() && object->getArrangementDescriptorSize() != 0 && object->getArrangementDescriptor(0)->size() != 0) {
		const String& arrangement = object->getArrangementDescriptor(0)->get(0);

		if (arrangement != "mission_bag" && arrangement != "ghost" && arrangement != "bank") {
			creo->addWearableObject(object->asTangibleObject(), true);
		}
	}

	// Jedi stuff below.
	auto ghost = creo->getPlayerObject();

	if (ghost != nullptr && ghost->isJedi()) {
		if (object->isRobeObject()) {
			ghost->recalculateForcePower();
		} else if (object->isWeaponObject()) {
			WeaponObject* weaponObject = cast<WeaponObject*>(object);

			if (weaponObject->isJediWeapon()) {
				VisibilityManager::instance()->increaseVisibility(creo, VisibilityManager::SABERVISMOD);
			}
		}
	}

	return ContainerComponent::notifyObjectInserted(sceneObject, object);
}

/**
 * Is called when an object was removed
 * @param object object that has been inserted
 */
int PlayerContainerComponent::notifyObjectRemoved(SceneObject* sceneObject, SceneObject* object, SceneObject* destination) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return 0;
	}

	bool cosmeticArmor = false;

	if (object->isArmorObject()) {
		ArmorObject* armor = cast<ArmorObject*>(object);
		cosmeticArmor = armor != nullptr && armor->isCosmeticArmor();

		if (!cosmeticArmor) {
			PlayerManager* playerManager = creo->getZoneServer()->getPlayerManager();
			playerManager->removeEncumbrancies(creo, armor);
		}
	}

	if (object->isTangibleObject()) {
		ManagedReference<TangibleObject*> tano = object->asTangibleObject();

		if (tano != nullptr) {
			// creo->info(true) << "Removing template & wearable skill mods from: " << tano->getDisplayedName();

			tano->removeTemplateSkillMods(creo);
			tano->removeSkillModsFrom(creo);
		}
	}

	if (object->isInstrument() && creo->isPlayingMusic()) {
		creo->stopEntertaining();
	}

	// Update wearables vector
	if (object->isTangibleObject() && object->getArrangementDescriptorSize() != 0 && object->getArrangementDescriptor(0)->size() != 0) {
		const String& arrangement = object->getArrangementDescriptor(0)->get(0); //CHK

		if (arrangement != "mission_bag" && arrangement != "ghost" && arrangement != "bank") {
			creo->removeWearableObject(object->asTangibleObject(), true);
		}
	}

	// Jedi stuff below.
	PlayerObject* ghost = creo->getPlayerObject();

	if (ghost != nullptr && ghost->isJedi()) {
		if (object->isRobeObject()) {
			ghost->recalculateForcePower();
		}
	}

	return ContainerComponent::notifyObjectRemoved(sceneObject, object, destination);
}
