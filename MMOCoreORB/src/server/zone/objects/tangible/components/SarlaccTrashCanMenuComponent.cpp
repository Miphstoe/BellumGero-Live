/*
 * SarlaccTrashCanMenuComponent.cpp
 *
 *  Created on: 06/15/2026
 *      Author: Miphstoe
 */

#include "SarlaccTrashCanMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/SceneObjectType.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"

static const uint8 RADIAL_CONSUME = RadialOptions::SERVER_MENU1;

static void giveReward(CreatureObject* creature, SceneObject* inventory, LootManager* lootManager) {
	// Equally weighted: 0=Holocron of Destiny, 1=Bellum Gero Token, 2=Vet Hologram
	int choice = static_cast<int>(System::random(2));

	TransactionLog trx(TrxCode::NPCLOOTCLAIM, creature);

	if (choice == 0) {
		if (lootManager->createLoot(trx, inventory, "crafting_rewards", 1) > 0)
			trx.commit(true);
		else
			trx.abort() << "sarlacc: createLoot crafting_rewards failed";
	} else if (choice == 1) {
		if (lootManager->createLoot(trx, inventory, "bg_token_group", 1) > 0)
			trx.commit(true);
		else
			trx.abort() << "sarlacc: createLoot bg_token_group failed";
	} else {
		if (lootManager->createLoot(trx, inventory, "vet_holo_group", 1) > 0)
			trx.commit(true);
		else
			trx.abort() << "sarlacc: createLoot vet_holo_group failed";
	}
}

static bool isAccessible(SceneObject* sceneObject, CreatureObject* creature) {
	if (sceneObject->isASubChildOf(creature))
		return true;

	auto parent = sceneObject->getParent().get();
	return parent != nullptr && parent->isCellObject();
}

void SarlaccTrashCanMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (isAccessible(sceneObject, player))
		menuResponse->addRadialMenuItem(RADIAL_CONSUME, 3, "Consume Garbage");
}

int SarlaccTrashCanMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* creature, byte selectedID) const {
	if (selectedID != RADIAL_CONSUME)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, creature, selectedID);

	if (!isAccessible(sceneObject, creature))
		return 0;

	if (sceneObject->getContainerObjectsSize() == 0) {
		creature->sendSystemMessage("The Sarlacc sniffs at the empty can and looks disappointed.");
		return 0;
	}

	// Collect all items first — cannot modify the container while iterating it.
	Vector<ManagedReference<SceneObject*>> toConsume;
	Vector<ManagedReference<SceneObject*>> excluded;

	for (int i = 0; i < sceneObject->getContainerObjectsSize(); ++i) {
		SceneObject* child = sceneObject->getContainerObject(i);
		if (child == nullptr)
			continue;

		bool skip = false;

		if (child->getGameObjectType() == SceneObjectType::TRAVELTICKET)
			skip = true;

		if (!skip && child->isFactoryCrate())
			skip = true;

		if (!skip) {
			TangibleObject* tano = dynamic_cast<TangibleObject*>(child);
			if (tano != nullptr && tano->getCraftersID() != 0)
				skip = true;
		}

		if (skip)
			excluded.add(child);
		else
			toConsume.add(child);
	}

	if (toConsume.isEmpty()) {
		creature->sendSystemMessage("The Sarlacc refuses — it will not consume travel tickets, crafted items, or factory crates.");
		return 0;
	}

	ZoneServer* zoneServer = creature->getZoneServer();
	if (zoneServer == nullptr)
		return 0;

	ManagedReference<LootManager*> lootManager = zoneServer->getLootManager();
	ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");
	if (inventory == nullptr || lootManager == nullptr)
		return 0;

	int rewardsGiven = 0;

	for (auto& item : toConsume) {
		item->destroyObjectFromWorld(true);
		item->destroyObjectFromDatabase(true);

		if (System::random(999) == 0) {
			giveReward(creature, inventory, lootManager);
			rewardsGiven++;
		}
	}

	StringBuffer msg;
	msg << "You feed " << toConsume.size() << " item" << (toConsume.size() != 1 ? "s" : "") << " to the Sarlacc.";
	creature->sendSystemMessage(msg.toString());

	if (!excluded.isEmpty()) {
		StringBuffer skipMsg;
		skipMsg << excluded.size() << " item" << (excluded.size() != 1 ? "s were" : " was")
		        << " skipped (travel tickets, player-crafted items, and factory crates are not accepted).";
		creature->sendSystemMessage(skipMsg.toString());
	}

	if (rewardsGiven > 0)
		creature->sendSystemMessage("The Sarlacc belches with pleasure and drops a reward at your feet!");
	else
		creature->sendSystemMessage("The Sarlacc consumes your offerings in silence...");

	return 0;
}


