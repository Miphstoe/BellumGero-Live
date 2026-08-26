/*
 * LootSchematicMenuComponent.cpp
 *
 *  Created on: 10/30/2011
 *      Author: kyle
 */

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "LootSchematicMenuComponent.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

#include "templates/tangible/LootSchematicTemplate.h"
#include "server/zone/managers/crafting/schematicmap/SchematicMap.h"

namespace {
String getFoundryCompanionChassisSchematic(const String& targetDraftSchematic) {
	if (targetDraftSchematic == "object/draft_schematic/droid/droid_battle_droid_foundry.iff")
		return "object/draft_schematic/droid/component/chassis_droid_battle_droid_foundry.iff";
	if (targetDraftSchematic == "object/draft_schematic/droid/droid_super_battle_droid_foundry.iff")
		return "object/draft_schematic/droid/component/chassis_droid_super_battle_droid_foundry.iff";
	if (targetDraftSchematic == "object/draft_schematic/droid/droid_droideka_foundry.iff")
		return "object/draft_schematic/droid/component/chassis_droid_droideka_foundry.iff";
	return "";
}
}

void LootSchematicMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {

	if (!sceneObject->isTangibleObject())
		return;

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	uint32 gameObjectType = sceneObject->getGameObjectType();

	LootSchematicTemplate* schematicData = cast<LootSchematicTemplate*>(sceneObject->getObjectTemplate());

	if (schematicData == nullptr) {
		error("No LootSchematicTemplate for: " + String::valueOf(sceneObject->getServerObjectCRC()));
		return;
	}

	String skillNeeded = schematicData->getRequiredSkill();

	if((skillNeeded.isEmpty() || player->hasSkill(skillNeeded))) {
		menuResponse->addRadialMenuItem(50, 3, "@loot_schematic:use_schematic"); //Learn Schematic
	}



}

int LootSchematicMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject->isTangibleObject())
		return 0;

	if (!player->isPlayerCreature())
		return 0;

	if(selectedID == 50) {
		if (!sceneObject->isASubChildOf(player)) {
			player->sendSystemMessage("@loot_schematic:must_be_holding"); // You must be holding that in order to use it.
			return 0;
		}

		Reference<PlayerObject*> ghost = player->getSlottedObject("ghost").castTo<PlayerObject*>();

		LootSchematicTemplate* schematicData = cast<LootSchematicTemplate*>(sceneObject->getObjectTemplate());

		if (schematicData == nullptr) {
			error("No LootSchematicTemplate for: " + String::valueOf(sceneObject->getServerObjectCRC()));
			return 0;
		}

		String skillNeeded = schematicData->getRequiredSkill();

		if((!skillNeeded.isEmpty() && !player->hasSkill(skillNeeded))) {
			StringIdChatParameter noSkill("@loot_schematic:not_enough_skill"); // You must have %TO skill in order to understand this.
			noSkill.setTO(skillNeeded);
			player->sendSystemMessage(noSkill);
			return 0;
		}

		ManagedReference<DraftSchematic* > schematic = SchematicMap::instance()->get(schematicData->getTargetDraftSchematic().hashCode());

		if (schematic == nullptr) {
			player->sendSystemMessage("Error learning schematic, try again later");
			error("Unable to create schematic: " + schematicData->getTargetDraftSchematic());
			return 0;
		}

		String companionPath = getFoundryCompanionChassisSchematic(schematicData->getTargetDraftSchematic());
		ManagedReference<DraftSchematic*> companionSchematic = nullptr;
		if (!companionPath.isEmpty()) {
			companionSchematic = SchematicMap::instance()->get(companionPath.hashCode());
			if (companionSchematic == nullptr) {
				player->sendSystemMessage("Error learning Foundry chassis schematic, try again later");
				error("Unable to create companion Foundry chassis schematic: " + companionPath);
				return 0;
			}
		}

		if(ghost->addRewardedSchematic(schematic, SchematicList::LOOT, schematicData->getTargetUseCount(), true)) {
			if (companionSchematic != nullptr &&
					ghost->addRewardedSchematic(companionSchematic, SchematicList::LOOT, 0, true)) {
				player->sendSystemMessage("You permanently learn the matching Foundry droid chassis schematic.");
			}

			TangibleObject* tano = cast<TangibleObject*>(sceneObject);
			if(tano != nullptr)
				tano->decreaseUseCount();
			player->sendSystemMessage("@loot_schematic:schematic_learned"); // You acquire a new crafting schematic!
		}

		return 0;
	} else
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	return 0;
}

