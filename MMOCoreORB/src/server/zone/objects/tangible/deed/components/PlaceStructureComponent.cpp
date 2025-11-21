/*
 * PlaceStructureComponent.cpp
 *
 *  Created on: Feb 5, 2012
 *      Author: xyborn
 */
#include "PlaceStructureComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/tangible/deed/structure/StructureDeed.h"
#include "server/zone/Zone.h"
// Added for restore hook
#include "server/zone/managers/housepackup/HousePackupManager.h"
#include "server/zone/objects/building/BuildingObject.h"

int PlaceStructureComponent::placeStructure(StructureDeed* deed, CreatureObject* creature, float x, float y, int angle) const {
    Zone* zone = creature != nullptr ? creature->getZone() : nullptr;
    if (zone != nullptr) {
        // Delegates to StructureManager which actually creates & places the structure,
        // and will invoke notifyStructurePlaced(...) on success.
        StructureManager::instance()->placeStructureFromDeed(creature, deed, x, y, angle);
    }
    return 0;
}

int PlaceStructureComponent::notifyStructurePlaced(StructureDeed* deed, CreatureObject* creature, StructureObject* structureObject) const {
    if (structureObject == nullptr || deed == nullptr)
        return 0;
    
    // Preserve deed-carried resources/settings
    structureObject->setSurplusMaintenance(deed->getSurplusMaintenance());
    structureObject->setSurplusPower(deed->getSurplusPower());
    
    if (structureObject->isInstallationObject()) {
        InstallationObject* installationObject = cast<InstallationObject*>(structureObject);
        if (installationObject != nullptr) {
            installationObject->setExtractionRate(deed->getExtractionRate());
            installationObject->setHopperSizeMax(deed->getHopperSize());
        }
    }
    
    // Restore packed house contents if this is a building (house)
    if (structureObject->isBuildingObject()) {
        BuildingObject* building = cast<BuildingObject*>(structureObject);
        if (building != nullptr) {
            // This will restore any items previously packed into this deed
            HousePackupManager::instance()->restoreFromDeed(building, deed, creature);
        }
    }
    
    return 0;
}