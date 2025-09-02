/*
 * StructureZoneComponent.cpp
 *
 *  Created on: Apr 15, 2012
 *      Author: TragD
 */

#include "server/zone/objects/structure/components/StructureZoneComponent.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

void StructureZoneComponent::notifyInsertToZone(SceneObject* sceneObject, Zone* zone) const {
    GroundZoneComponent::notifyInsertToZone(sceneObject, zone);

    if (sceneObject->isBuildingObject()) {
        ManagedReference<BuildingObject*> building = cast<BuildingObject*>(sceneObject);
        if (building->hasTemplateChildCreatures())
            building->spawnChildCreaturesFromTemplate();
    }
}

void StructureZoneComponent::notifyRemoveFromZone(SceneObject* sceneObject) const {
    GroundZoneComponent::notifyRemoveFromZone(sceneObject);
    // moved to StructureManager::destroyStructure
}

int StructureZoneComponent::notifyEnter(SceneObject* sceneObject, SceneObject* mover) {
    if (!mover || !mover->isCreatureObject()) return 0;

    auto* creature = cast<CreatureObject*>(mover);
    SceneObject* root = sceneObject ? sceneObject->getRootParent() : nullptr;
    if (!root || !root->isStructureObject()) return 0;

    auto* structure = cast<StructureObject*>(root);

    // Before/after snapshot
    int before = creature->getSkillMod("private_buff_mind");
    structure->addTemplateSkillMods(creature);
    int after  = creature->getSkillMod("private_buff_mind");

    creature->sendSystemMessage("Cantina enter: private_buff_mind " + String::valueOf(before) + " -> " + String::valueOf(after));
    return 0;
}

int StructureZoneComponent::notifyExit(SceneObject* sceneObject, SceneObject* mover) {
    if (!mover || !mover->isCreatureObject()) return 0;

    auto* creature = cast<CreatureObject*>(mover);
    SceneObject* root = sceneObject ? sceneObject->getRootParent() : nullptr;
    if (!root || !root->isStructureObject()) return 0;

    auto* structure = cast<StructureObject*>(root);

    int before = creature->getSkillMod("private_buff_mind");
    structure->removeTemplateSkillMods(creature);
    int after  = creature->getSkillMod("private_buff_mind");

    creature->sendSystemMessage("Cantina exit: private_buff_mind " + String::valueOf(before) + " -> " + String::valueOf(after));
    return 0;
}
