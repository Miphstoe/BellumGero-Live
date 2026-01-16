/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "engine/engine.h"

#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"
#include "server/zone/objects/tangible/tool/CraftingTool.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/tangible/tool/CraftingToolTemplate.h"
#include "server/zone/objects/manufactureschematic/craftingvalues/CraftingValues.h"
#include "server/zone/packets/scene/AttributeListMessage.h"
#include "server/zone/objects/player/sessions/crafting/CraftingSession.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/objects/tangible/component/lightsaber/LightsaberCrystalComponent.h"

void CraftingToolImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	TangibleObjectImplementation::loadTemplateData(templateData);

	CraftingToolTemplate* craftingToolData = dynamic_cast<CraftingToolTemplate*>(templateData);

	if (craftingToolData == nullptr) {
		throw Exception("invalid template for CraftingTool");
	}

	type = craftingToolData->getToolType();

	complexityLevel = craftingToolData->getComplexityLevel();
	forceCriticalAssembly = craftingToolData->getForceCriticalAssembly();
	forceCriticalExperiment = craftingToolData->getForceCriticalExperiment();

	for (int i = 0; i < craftingToolData->getTabs().size(); ++i)
		enabledTabs.add(craftingToolData->getTabs().get(i));
}

void CraftingToolImplementation::initializeTransientMembers() {
	TangibleObjectImplementation::initializeTransientMembers();

	if (getContainerObjectsSize() > 0) {
		status = TOOL_FINISHED; // "@crafting:tool_status_finished"
	} else {
		status = TOOL_READY; // "@crafting:tool_status_ready"
	}

	setCountdownTimer(0, false);
}

void CraftingToolImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	TangibleObjectImplementation::fillObjectMenuResponse(menuResponse, player);

	if (isFinished()) {
		menuResponse->addRadialMenuItem(RadialOptions::SERVER_ITEM_OPTIONS, 3, "@ui_radial:craft_hopper_output");
	}

	// Add crystal exchange option for Lightsaber Crafting Tool (JEDI type)
	if (type == JEDI) {
		menuResponse->addRadialMenuItem(100, 3, "Crystal Exchange");
	}
}

Reference<TangibleObject*> CraftingToolImplementation::getPrototype() {
	if (getContainerObjectsSize() > 0)
		return getContainerObject(0).castTo<TangibleObject*>();
	else
		return nullptr;
}

int CraftingToolImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (!isASubChildOf(player))
		return 0;

	int toolSize = getContainerObjectsSize();

	// Handle crystal tuning for Lightsaber Crafting Tool
	if (selectedID == 100 && type == JEDI) {
		return tuneCrystals(player);
	}

	// Get Finished Prototype
	if (selectedID == RadialOptions::SERVER_ITEM_OPTIONS) {
		// Tool is not finished
		if (!isFinished())
			return 0;

		ManagedReference<TangibleObject*> prototype = getPrototype();

		// Prototype is null, unable to stranfer
		if (prototype == nullptr) {
			status = TOOL_READY;

			return 1;
		}

		ManagedReference<SceneObject*> inventory = player->getInventory();

		if (inventory == nullptr)
			return 0;

		int totalLimit = inventory->getContainerVolumeLimit();
		int totalObjects = inventory->getCountableObjectsRecursive();

		// Check if the player has made space and attempt to transfer the prototype
		if (totalLimit > totalObjects && inventory->transferObject(prototype, -1, true, true)) {
			player->sendSystemMessage("@system_msg:prototype_transferred");

			status = TOOL_READY;
		} else {
			player->sendSystemMessage("@system_msg:prototype_not_transferred");
		}

		return 1;
	}

	return TangibleObjectImplementation::handleObjectMenuSelect(player, selectedID);
}

void CraftingToolImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* player) {
	TangibleObjectImplementation::fillAttributeList(alm, player);

	alm->insertAttribute("craft_tool_effectiveness", Math::getPrecision(effectiveness, 2));

	String statusString = "@crafting:tool_status_ready";

	if (status == TOOL_FINISHED) {
		statusString = "@crafting:tool_status_finished";
	} else if (status == TOOL_WORKING) {
		statusString = "@crafting:tool_status_working";
	}

	alm->insertAttribute("craft_tool_status", statusString);

	if (forceCriticalAssembly > 0)
		alm->insertAttribute("@crafting:crit_assembly", forceCriticalAssembly);

	if (forceCriticalExperiment > 0)
		alm->insertAttribute("@crafting:crit_experiment", forceCriticalExperiment);
}

void CraftingToolImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	// useModifer is the effectiveness
	effectiveness = values->getCurrentValue("usemodifier");
}

Vector<uint32>* CraftingToolImplementation::getToolTabs() {
	return &enabledTabs;
}

void CraftingToolImplementation::sendToolStartFailure(CreatureObject* player, const String& message) {
	// Start Object Controller **(Failed to start crafting Session************
	ObjectControllerMessage* objMsg = new ObjectControllerMessage(player->getObjectID(), 0x1B, 0x010C);
	objMsg->insertInt(0x10F);
	objMsg->insertInt(0);
	objMsg->insertByte(0);

	player->sendMessage(objMsg);

	player->sendSystemMessage(message);
}

/*
void CraftingToolImplementation::disperseItems() {
	if (!isReady())
		return;

	Locker locker(_this.getReferenceUnsafeStaticCast());

	ManagedReference<SceneObject*> craftedComponents = getSlottedObject("crafted_components");
	ManagedReference<SceneObject*> prototype = nullptr;

	if (getContainerObjectsSize() > 0)
		prototype = getContainerObject(0);

	if (craftedComponents == nullptr) {
		if (prototype == nullptr)
			return;

		craftedComponents = prototype->getSlottedObject("crafted_components");
	}

	if (craftedComponents != nullptr && craftedComponents->getContainerObjectsSize() > 0) {
		ManagedReference<SceneObject*> satchel = craftedComponents->getContainerObject(0);
		ManagedReference<SceneObject*> inventory = getParent().get();

		if (satchel != nullptr && inventory != nullptr) {
			while (satchel->getContainerObjectsSize() > 0) {
				ManagedReference<SceneObject*> object = satchel->getContainerObject(0);

				inventory->transferObject(object, -1, false);
				inventory->broadcastObject(object, true);
			}
		}
	}

	if (craftedComponents != nullptr) {
		Locker clocker(craftedComponents, _this.getReferenceUnsafeStaticCast());
		craftedComponents->destroyObjectFromWorld(true);
	}

	if (prototype != nullptr) {
		Locker clocker(prototype, _this.getReferenceUnsafeStaticCast());
		prototype->destroyObjectFromWorld(true);
	}
}*/

int CraftingToolImplementation::tuneCrystals(CreatureObject* player) {
	if (player == nullptr) {
		return 0;
	}

	// Get player inventory
	ManagedReference<SceneObject*> inventory = player->getInventory();
	if (inventory == nullptr) {
		player->sendSystemMessage("Error: Could not access inventory.");
		return 0;
	}

	// Count tunable items (untuned regular crystals OR untuned Krayt Dragon Pearls)
	// Uses type checking to ensure only real crystals are counted, not bags/containers with "crystal" in name
	// Excludes Named Crystals (color 12-30) as those are the exchange reward
	int tunableCount = 0;
	unsigned long long inventoryId = inventory->getObjectID();
	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> obj = inventory->getContainerObject(i);
		if (obj != nullptr && obj->isLightsaberCrystalObject()) {
			// Cast to LightsaberCrystalComponent to check tuned status and color
			LightsaberCrystalComponent* crystal = cast<LightsaberCrystalComponent*>(obj.get());
			if (crystal != nullptr && crystal->getOwnerID() == 0) {
				// Crystal is untuned (no owner)
				// Check color: 0-11 = regular color crystals, 31 = power crystals/pearls
				// Exclude Named Crystals which have color 12-30
				int color = crystal->getColor();
				if (color <= 11 || color == 31) {
					tunableCount++;
				}
			}
		}
	}

	if (tunableCount < 25) {
		StringBuffer msg;
		msg << "You need 25 untuned crystals and/or Krayt Dragon Pearls to exchange. You have " << tunableCount << ".";
		player->sendSystemMessage(msg.toString());
		return 0;
	}

	// Remove 25 tunable items (any combination of untuned regular crystals and untuned pearls)
	// Only remove items DIRECTLY in the main inventory, not in backpacks/containers
	// Excludes Named Crystals (color 12-30) as those are the exchange reward
	int removed = 0;
	for (int i = inventory->getContainerObjectsSize() - 1; i >= 0 && removed < 25; --i) {
		ManagedReference<SceneObject*> obj = inventory->getContainerObject(i);
		if (obj != nullptr && obj->isLightsaberCrystalObject()) {
			// Only process items directly in the main inventory
			if (obj->getParentID() == inventoryId) {
				// Cast to LightsaberCrystalComponent to check tuned status and color
				LightsaberCrystalComponent* crystal = cast<LightsaberCrystalComponent*>(obj.get());
				if (crystal != nullptr && crystal->getOwnerID() == 0) {
					// Crystal is untuned (no owner)
					// Check color: 0-11 = regular color crystals, 31 = power crystals/pearls
					// Exclude Named Crystals which have color 12-30
					int color = crystal->getColor();
					if (color <= 11 || color == 31) {
						obj->destroyObjectFromWorld(true);
						obj->destroyObjectFromDatabase(true);
						removed++;
					}
				}
			}
		}
	}

	if (removed < 25) {
		player->sendSystemMessage("Error: Could not remove all items. Exchange cancelled.");
		return 0;
	}

	// Create a named color crystal using the LootManager
	Zone* zone = player->getZone();
	if (zone == nullptr) {
		player->sendSystemMessage("Error: Could not access zone.");
		return 0;
	}

	ManagedReference<LootManager*> lootManager = zone->getZoneServer()->getLootManager();
	if (lootManager == nullptr) {
		player->sendSystemMessage("Error: Loot system unavailable.");
		return 0;
	}

	// Create transaction for loot creation
	TransactionLog trx(TrxCode::NPCLOOTCLAIM, player);
	unsigned long long objectId = lootManager->createLoot(trx, inventory, "force_color_crystal_special", player->getLevel(), false);

	if (objectId != 0) {
		trx.commit(true);
		player->sendSystemMessage("Successfully exchanged crystals! 25 crystals and/or pearls converted to 1 named color crystal.");
		return 1;
	} else {
		trx.abort() << "Failed to create force_color_crystal_special";
		player->sendSystemMessage("Error creating tuned crystal. Please contact an administrator.");
		return 0;
	}
}

Reference<ManufactureSchematic*> CraftingToolImplementation::getManufactureSchematic() {
	return getSlottedObject("test_manf_schematic").castTo<ManufactureSchematic*>();
}
