/*
 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef CREATEOBJECTTASK_H_
#define CREATEOBJECTTASK_H_

#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/managers/loot/LootManager.h"

class CreateObjectTask : public Task {

	ManagedReference<CraftingTool*> craftingTool;
	ManagedReference<CreatureObject*> crafter;
	bool practice;

public:
	CreateObjectTask(CreatureObject* player, CraftingTool* tool, bool pract) : Task() {

		craftingTool = tool;
		crafter = player;
		practice = pract;
	}

	void run() {
		Locker locker(crafter);
		Locker clocker(craftingTool, crafter);

		craftingTool->setCountdownTimer(0, true);

		auto prototype = craftingTool->getPrototype();

		if (prototype == nullptr || practice) {
			craftingTool->removeAllContainerObjects();
			craftingTool->setReady();

			if (practice && prototype != nullptr) {
				crafter->notifyObservers(ObserverEventType::PROTOTYPECREATED, prototype, 1);

				// Practice mode crafting reward system
				// 1% chance for level 500 clothing attachment
				// 15% chance for level 1-100 clothing attachment
				int randRoll = System::random(10000); // Roll 0-9999 for precise percentages

				if (randRoll < 100) { // 1% chance (0-99 out of 10000)
					// Rare reward: Level 500 clothing attachment
					ManagedReference<SceneObject*> inventory = crafter->getInventory();
					if (inventory != nullptr) {
						LootManager* lootManager = crafter->getZoneServer()->getLootManager();
						if (lootManager != nullptr) {
							TransactionLog trx(TrxCode::CRAFTINGSESSION, crafter, inventory);
							trx.addState("practiceCraftingReward", true);
							trx.addState("lootGroup", "attachment_clothing");
							trx.addState("lootLevel", 500);

							if (lootManager->createLoot(trx, inventory, "attachment_clothing", 500, true) > 0) {
								crafter->sendSystemMessage("You received a RARE Level 500 Clothing Attachment for practicing your craft!");
							}
						}
					}
				} else if (randRoll < 1600) { // 15% chance (100-1599 out of 10000)
					// Common reward: Level 1-100 clothing attachment
					ManagedReference<SceneObject*> inventory = crafter->getInventory();
					if (inventory != nullptr) {
						LootManager* lootManager = crafter->getZoneServer()->getLootManager();
						if (lootManager != nullptr) {
							int rewardLevel = System::random(100) + 1; // Random level 1-100
							TransactionLog trx(TrxCode::CRAFTINGSESSION, crafter, inventory);
							trx.addState("practiceCraftingReward", true);
							trx.addState("lootGroup", "attachment_clothing");
							trx.addState("lootLevel", rewardLevel);

							if (lootManager->createLoot(trx, inventory, "attachment_clothing", rewardLevel, true) > 0) {
								crafter->sendSystemMessage("You received a Level " + String::valueOf(rewardLevel) + " Clothing Attachment for practicing your craft!");
							}
						}
					}
				}
			}

			return;
		}

		ObjectManager* objectManager = crafter->getZoneServer()->getObjectManager();
		objectManager->persistSceneObjectsRecursively(prototype, 1);

		ManagedReference<SceneObject*> inventory = crafter->getInventory();

		// The check for space in the players inventory has to be done here instead of in isContainerFullRecursive due to the object being in the crafting tool already.
		if (inventory != nullptr && craftingTool->isASubChildOf(crafter) && !(inventory->getContainerVolumeLimit() <= (inventory->getCountableObjectsRecursive()))) {
			TransactionLog trx(crafter, inventory, prototype, TrxCode::CRAFTINGSESSION);

			if (inventory->transferObject(prototype, -1, true)) {
				crafter->sendSystemMessage("@system_msg:prototype_transferred");

				crafter->notifyObservers(ObserverEventType::PROTOTYPECREATED, prototype, 0);
				craftingTool->setReady();

				return;
			}
		}

		crafter->sendSystemMessage("@system_msg:prototype_not_transferred");
		craftingTool->setFinished();
	}
};

#endif /*CREATEOBJECTTASK_H_*/
