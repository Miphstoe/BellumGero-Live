// MMOCoreORB/src/server/zone/managers/safezone/SafeZoneManager.h
#ifndef SAFEZONEMANAGER_H_
#define SAFEZONEMANAGER_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/building/BuildingObject.h"

class SafeZoneManager {
public:
    // Is the objects inside a player-city Cantina / Hospital / Medical Center?
    static bool isInSafeBuilding(SceneObject* obj);

    // Convenience wrapper for Tangible/Creature objects
    static bool isInSafeZone(TangibleObject* obj);
};

#endif /* SAFEZONEMANAGER_H_ */
