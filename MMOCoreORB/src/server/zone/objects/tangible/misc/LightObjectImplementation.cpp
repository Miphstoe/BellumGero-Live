/*
*   Copyright (C) 2007-2024 SWGEmu
*   See file COPYING for copying conditions.
*
*   Created By: Hakry
*   Date: 1/30/2024
*
*   Modified: Timer-free lights (no decay / no burnout / "Infinite" lifespan display)
*/

#include "server/zone/objects/tangible/misc/LightObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/object/ObjectManager.h"

// #define DEBUG_LIGHTS

void LightObjectImplementation::initializeMembers() {
    // Initialize for compatibility, but timers are unused now.
    lifespan.updateToCurrentTime();
    creationMili = System::getMiliTime();

    burntOut = false;     // never burnt out
    firstUpdate = false;  // no first-update timer wiring
    lifespanSeconds = 0;  // unused sentinel
}

void LightObjectImplementation::notifyInsertToZone(Zone* zone) {
    // Keep observer registration in case other systems depend on it.
    if (!burntOut && getObservers(ObserverEventType::PARENTCHANGED).size() == 0) {
        ManagedReference<LightObserver*> observer = new LightObserver();
        if (observer != nullptr) {
            registerObserver(ObserverEventType::PARENTCHANGED, observer);
        }
    }

    TangibleObjectImplementation::notifyInsertToZone(zone);
}

void LightObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* player) {
    if (isClientObject())
        return;

    TangibleObjectImplementation::fillAttributeList(alm, player);

    // Always show infinite lifespan; avoid StringIdManager to prevent include issues.
    alm->insertAttribute("@obj_attr_n:lifespan", "Infinite");
}

void LightObjectImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdateIn) {
    // Ignore any lifespan/quality adjustments; lights are always infinite.
#ifdef DEBUG_LIGHTS
    if (values != nullptr)
        info(true) << "updateCraftingValues (timer-free): ignoring lifespan/quality for lights.";
#endif
    TangibleObjectImplementation::updateCraftingValues(values, firstUpdateIn);
}

void LightObjectImplementation::calculateLifespan(int /*lifespanVar*/) {
    // Force infinite behavior; timer fields unused.
    lifespanSeconds = 0;
    burntOut = false;
#ifdef DEBUG_LIGHTS
    info(true) << "calculateLifespan (timer-free): lights are infinite.";
#endif
}

void LightObjectImplementation::updateLifespan() {
    // No-op: no timers to update.
#ifdef DEBUG_LIGHTS
    info(true) << "updateLifespan (timer-free): no action taken.";
#endif
}

void LightObjectImplementation::updateTemplate() {
    // No-op: never swap to burnt-out templates.
#ifdef DEBUG_LIGHTS
    info(true) << "updateTemplate (timer-free): skipping burnt-out replacement.";
#endif
}

bool LightObjectImplementation::lifespanIsPast() {
    // Never expires.
    return false;
}
