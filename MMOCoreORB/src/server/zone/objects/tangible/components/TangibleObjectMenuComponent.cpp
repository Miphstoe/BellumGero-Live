/*
 * TangibleObjectMenuComponent.cpp
 *
 *  Created on: 26/05/2011
 *      Author: victor
 */

#include "TangibleObjectMenuComponent.h"
#include "server/zone/objects/player/sessions/SlicingSession.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/callbacks/RenameDecorativeObjectCallback.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/building/BuildingObject.h"

void TangibleObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	ObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	uint32 gameObjectType = sceneObject->getGameObjectType();

	if (!sceneObject->isTangibleObject())
		return;

	TangibleObject* tano = cast<TangibleObject*>( sceneObject);

	// Figure out what the object is and if its able to be Sliced.
	if(tano->isSliceable() && !tano->isSecurityTerminal()) { // Check to see if the player has the correct skill level

		bool hasSkill = true;
		ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

		if ((gameObjectType == SceneObjectType::PLAYERLOOTCRATE) && !player->hasSkill("combat_smuggler_novice"))
			hasSkill = false;
		else if (sceneObject->isContainerObject())
			hasSkill = false; // Let the container handle our slice menu
		else if (sceneObject->isMissionTerminal() && !player->hasSkill("combat_smuggler_slicing_01"))
			hasSkill = false;
		else if (sceneObject->isWeaponObject() && (!inventory->hasObjectInContainer(sceneObject->getObjectID()) || !player->hasSkill("combat_smuggler_slicing_02")))
			hasSkill = false;
		else if (sceneObject->isArmorObject() && (!inventory->hasObjectInContainer(sceneObject->getObjectID()) || !player->hasSkill("combat_smuggler_slicing_03")))
			hasSkill = false;

		if(hasSkill)
			menuResponse->addRadialMenuItem(69, 3, "@slicing/slicing:slice"); // Slice
	}

	if (player->getPlayerObject() != nullptr && player->getPlayerObject()->isPrivileged()) {
		/// Viewing components used to craft item, for admins
		ManagedReference<SceneObject*> container = tano->getSlottedObject("crafted_components");

		if (container != nullptr && container->getContainerObjectsSize() > 0) {
			SceneObject* satchel = container->getContainerObject(0);

			if (satchel != nullptr && satchel->getContainerObjectsSize() > 0) {
				menuResponse->addRadialMenuItem(79, 3, "@ui_radial:ship_manage_components"); // View Components
			}
		}
	}

	ManagedReference<SceneObject*> parent = tano->getParent().get();
	if (parent != nullptr && parent->getGameObjectType() == SceneObjectType::STATICLOOTCONTAINER) {
		menuResponse->addRadialMenuItem(10, 3, "@ui_radial:item_pickup"); //Pick up
	}

	// Add rename option for decorative objects
	if (tano->isDecorativeObject() && hasRenamePermission(player, tano)) {
		menuResponse->addRadialMenuItem(50, 3, "@base_player:set_name"); // Set Name
	}

	// Add secure/unsecure option for items in buildings (owner only)
	if (!sceneObject->isASubChildOf(player)) {
		ManagedReference<SceneObject*> rootParent = sceneObject->getRootParent();
		if (rootParent != nullptr && rootParent->isBuildingObject()) {
			BuildingObject* building = cast<BuildingObject*>(rootParent.get());
			if (building != nullptr && building->isOwnerOf(player)) {
				String securedValue = tano->getLuaStringData("item_secured");
				bool isSecured = !securedValue.isEmpty();

				if (isSecured) {
					menuResponse->addRadialMenuItem(223, 3, "Unsecure from House");
				} else {
					menuResponse->addRadialMenuItem(222, 3, "Secure to House");
				}
			}
		}
	}

	// Add unstack option for stackable items (only if in player's inventory and count > 1)
	if (sceneObject->isASubChildOf(player) && tano->getUseCount() > 1) {
		menuResponse->addRadialMenuItem(48, 3, "Unstack Items"); // Using SPLIT (48) from RadialOptions
	}
}

int TangibleObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject->isTangibleObject())
		return 0;

	TangibleObject* tano = cast<TangibleObject*>( sceneObject);


	if (selectedID == 69 && player->hasSkill("combat_smuggler_novice") ) { // Slice [PlayerLootCrate]
		if (player->containsActiveSession(SessionFacadeType::SLICING)) {
			player->sendSystemMessage("@slicing/slicing:already_slicing");
			return 0;
		}

		//Create Session
		ManagedReference<SlicingSession*> session = new SlicingSession(player);
		session->initalizeSlicingMenu(player, tano);

		return 0;
	} else if (selectedID == 79) { // See components (admin)
		if(player->getPlayerObject() != nullptr && player->getPlayerObject()->isPrivileged()) {

			SceneObject* container = tano->getSlottedObject("crafted_components");
			if(container != nullptr) {

				if(container->getContainerObjectsSize() > 0) {

					SceneObject* satchel = container->getContainerObject(0);

					if(satchel != nullptr) {

						satchel->sendWithoutContainerObjectsTo(player);
						satchel->openContainerTo(player);

					} else {
						player->sendSystemMessage("There is no satchel this container");
					}
				} else {
					player->sendSystemMessage("There are no items in this container");
				}
			} else {
				player->sendSystemMessage("There is no component container in this object");
			}
		}

		return 0;
	} else if (selectedID == 50 && tano->isDecorativeObject()) { // Rename decorative object
		if (hasRenamePermission(player, tano)) {
			promptRenameObject(player, tano);
			return 0;
		}
	} else if (selectedID == 222 || selectedID == 223) { // Secure/Unsecure to House
		// Verify item is in a building (not in player inventory)
		if (!sceneObject->isASubChildOf(player)) {
			ManagedReference<SceneObject*> rootParent = sceneObject->getRootParent();
			if (rootParent != nullptr && rootParent->isBuildingObject()) {
				BuildingObject* building = cast<BuildingObject*>(rootParent.get());
				if (building != nullptr && building->isOwnerOf(player)) {
					if (selectedID == 222) { // Secure
						uint64 buildingOID = building->getObjectID();
						tano->setLuaStringData("item_secured", String::valueOf(buildingOID));
						tano->addMagicBit(true);

						String itemName = sceneObject->getDisplayedName();
						if (itemName.isEmpty())
							itemName = sceneObject->getObjectNameStringIdName();

						player->sendSystemMessage("Item secured to house: " + itemName + " - Players cannot leave with this item.");
						return 0;
					} else if (selectedID == 223) { // Unsecure
						tano->deleteLuaStringData("item_secured");
						tano->removeMagicBit(true);

						String itemName = sceneObject->getDisplayedName();
						if (itemName.isEmpty())
							itemName = sceneObject->getObjectNameStringIdName();

						player->sendSystemMessage("Item unsecured from house: " + itemName + " - Players may now take this item.");
						return 0;
					}
				}
			}
		}
	} else if (selectedID == 48) { // Unstack Items (using SPLIT radial option)
		// Only unstack if item is in player's inventory and has count > 1
		if (sceneObject->isASubChildOf(player) && tano->getUseCount() > 1) {
			unstackItems(sceneObject, player, tano);
			return 0;
		}
	}

	return ObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}

bool TangibleObjectMenuComponent::hasRenamePermission(CreatureObject* player, TangibleObject* object) {
	if (player == nullptr || object == nullptr)
		return false;

	// Case 1: Object in player's inventory (or equipped)
	ManagedReference<SceneObject*> playerParent = object->getParentRecursively(SceneObjectType::PLAYERCREATURE);

	if (playerParent != nullptr && playerParent == player)
		return true; // Object is owned by player

	// Case 2: Object placed in a structure where player has admin rights
	ManagedReference<SceneObject*> rootParent = object->getRootParent();

	if (rootParent != nullptr && rootParent->isStructureObject()) {
		StructureObject* structure = cast<StructureObject*>(rootParent.get());

		if (structure == nullptr)
			return false;

		// Check if player is owner
		if (structure->isOwnerOf(player))
			return true;

		// Check if player has ADMIN permission
		uint64 playerID = player->getObjectID();
		if (structure->isOnAdminList(playerID))
			return true;

		// Check if player's guild has ADMIN permission
		ManagedReference<GuildObject*> guild = player->getGuildObject().get();
		if (guild != nullptr && structure->isOnAdminList(guild->getObjectID()))
			return true;
	}

	return false;
}

void TangibleObjectMenuComponent::promptRenameObject(CreatureObject* player, TangibleObject* object) {
	if (player == nullptr || object == nullptr)
		return;

	auto ghost = player->getPlayerObject();
	if (ghost == nullptr)
		return;

	ManagedReference<SuiInputBox*> inputBox = new SuiInputBox(player, SuiWindowType::OBJECT_NAME);

	inputBox->setPromptTitle("@sui:set_name_title");
	inputBox->setPromptText("@sui:set_name_prompt");
	inputBox->setUsingObject(object);
	inputBox->setMaxInputSize(255);
	inputBox->setDefaultInput(object->getCustomObjectName().toString());
	inputBox->setCallback(new RenameDecorativeObjectCallback(player->getZoneServer()));

	ghost->addSuiBox(inputBox);
	player->sendMessage(inputBox->generateMessage());
}

void TangibleObjectMenuComponent::unstackItems(SceneObject* sceneObject, CreatureObject* player, TangibleObject* tano) const {
	if (player == nullptr || tano == nullptr || sceneObject == nullptr)
		return;

	int currentCount = tano->getUseCount();

	if (currentCount <= 1) {
		player->sendSystemMessage("This item cannot be unstacked.");
		return;
	}

	// Get the container (inventory)
	ManagedReference<SceneObject*> container = sceneObject->getParent().get();
	if (container == nullptr) {
		player->sendSystemMessage("Unable to unstack items - no valid container.");
		return;
	}

	// Get the template path to create new items
	String templatePath = sceneObject->getObjectTemplate()->getFullTemplateString();
	if (templatePath.isEmpty()) {
		player->sendSystemMessage("Unable to unstack items - invalid template.");
		return;
	}

	String itemName = sceneObject->getDisplayedName();
	if (itemName.isEmpty())
		itemName = sceneObject->getObjectNameStringIdName();

	auto zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return;

	int splitCount = currentCount / 2;
	int remainingCount = currentCount - splitCount;

	if (splitCount < 1 || remainingCount < 1) {
		player->sendSystemMessage("This item cannot be unstacked.");
		return;
	}

	ManagedReference<SceneObject*> newItem = zoneServer->createObject(templatePath.hashCode(), 1);
	if (newItem == nullptr || !newItem->isTangibleObject()) {
		player->sendSystemMessage("Unable to unstack items - failed to create new item.");
		return;
	}

	TangibleObject* newTano = cast<TangibleObject*>(newItem.get());
	newTano->setUseCount(splitCount, true);

	// Reduce the original stack before transfer
	tano->setUseCount(remainingCount, true);

	// Prevent junk auto-stacking during transfer
	tano->setLuaStringData("skip_junk_stack", "1");
	newTano->setLuaStringData("skip_junk_stack", "1");
	if (container->isTangibleObject()) {
		TangibleObject* containerTano = container->asTangibleObject();
		if (containerTano != nullptr) {
			containerTano->setLuaStringData("skip_junk_stack", "1");
		}
	}

	if (!container->transferObject(newItem, -1, true)) {
		// Revert original count and cleanup on failure
		tano->setUseCount(currentCount, true);
		tano->deleteLuaStringData("skip_junk_stack");
		if (container->isTangibleObject()) {
			TangibleObject* containerTano = container->asTangibleObject();
			if (containerTano != nullptr) {
				containerTano->deleteLuaStringData("skip_junk_stack");
			}
		}
		newItem->destroyObjectFromDatabase(true);
		player->sendSystemMessage("Unable to unstack items - inventory full.");
		return;
	}

	// Ensure client receives the new object baselines
	newItem->sendTo(player, true);

	tano->deleteLuaStringData("skip_junk_stack");
	newTano->deleteLuaStringData("skip_junk_stack");
	if (container->isTangibleObject()) {
		TangibleObject* containerTano = container->asTangibleObject();
		if (containerTano != nullptr) {
			containerTano->deleteLuaStringData("skip_junk_stack");
		}
	}

	player->sendSystemMessage("Unstacked " + String::valueOf(currentCount) + " " + itemName + " into stacks of " + String::valueOf(remainingCount) + " and " + String::valueOf(splitCount) + ".");
}
