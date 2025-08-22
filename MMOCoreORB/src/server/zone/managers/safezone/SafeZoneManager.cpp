// MMOCoreORB/src/server/zone/managers/safezone/SafeZoneManager.cpp
#include "server/zone/managers/safezone/SafeZoneManager.h"
#include "templates/SharedObjectTemplate.h"  // for getFullTemplateString()

bool SafeZoneManager::isInSafeBuilding(SceneObject* obj) {
    if (obj == nullptr)
        return false;

    SceneObject* parent = obj->getParent().get();
    while (parent != nullptr) {
        // We walk up the parent chain until we hit a BuildingObject (or run out)
        BuildingObject* building = parent->asBuildingObject();
        if (building != nullptr) {
            const SharedObjectTemplate* tmplObj = building->getObjectTemplate();
            String path = (tmplObj != nullptr) ? tmplObj->getFullTemplateString().toLowerCase() : String();

            // Restrict to **player city** buildings only, and then match the types we care about
            const bool isPlayerCityBuilding =
                (path.contains("/player/") && (path.contains("/city/") || path.contains("player_city")));

            const bool isProtectedType =
                (path.contains("cantina") || path.contains("hospital") || path.contains("medical_center"));

            if (isPlayerCityBuilding && isProtectedType)
                return true;
        }

        parent = parent->getParent().get();
    }

    return false;
}

bool SafeZoneManager::isInSafeZone(TangibleObject* obj) {
    // TangibleObject derives from SceneObject; use the same structural check
    return isInSafeBuilding(obj);
}
