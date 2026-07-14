/*
 * AncientCrystalMenuComponent.cpp
 *
 *  Created on: 07/08/2026
 *      Author: Miphstoe
 */

#include "AncientCrystalMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/buffs/Buff.h"
#include "server/zone/objects/creature/buffs/BuffType.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"

static const uint32 ANCIENT_CRYSTAL_BUFF_CRC = STRING_HASHCODE("ancient_crystal_of_the_sith_force_heal");
static const float ANCIENT_CRYSTAL_BUFF_DURATION = 900.f; // 15 minutes
static const int ANCIENT_CRYSTAL_HEAL_BONUS = 25; // percent

void AncientCrystalMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (sceneObject->isASubChildOf(player))
		menuResponse->addRadialMenuItem(RadialOptions::ITEM_USE_SELF, 3, "Consume Crystal");

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);
}

int AncientCrystalMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* creature, byte selectedID) const {
	if (selectedID != RadialOptions::ITEM_USE_SELF)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, creature, selectedID);

	if (!sceneObject->isASubChildOf(creature))
		return 0;

	if (creature->isDead() || creature->isIncapacitated())
		return 0;

	if (creature->hasBuff(ANCIENT_CRYSTAL_BUFF_CRC)) {
		creature->sendSystemMessage("You can still feel the power of the last crystal you consumed. Its effect has not yet faded.");
		return 0;
	}

	ManagedReference<Buff*> buff = new Buff(creature, ANCIENT_CRYSTAL_BUFF_CRC, ANCIENT_CRYSTAL_BUFF_DURATION, BuffType::JEDI);

	Locker blocker(buff);

	buff->setSkillModifier("force_heal_bonus", ANCIENT_CRYSTAL_HEAL_BONUS);

	blocker.release();

	creature->addBuff(buff);

	creature->sendSystemMessage("You consume the Ancient Crystal of the Sith. Its dark power flows through you, enhancing your Force healing for 15 minutes.");

	sceneObject->destroyObjectFromWorld(true);
	sceneObject->destroyObjectFromDatabase(true);

	return 0;
}
