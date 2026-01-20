// HousePackupManager.h
#pragma once

#include "engine/engine.h"           // String, Logger, Object, etc.
#include "server/zone/ZoneServer.h"  // ZoneServer

// Forward declarations to avoid polluting headers with 'using namespace'
namespace server { namespace zone {
    class ZoneServer;
    namespace objects {
        namespace building { class BuildingObject; }
        namespace creature { class CreatureObject; }
        namespace tangible { class TangibleObject; }
    }
}}

// Convenience aliases (only for this header’s scope)
namespace sz   = server::zone;
namespace bld  = server::zone::objects::building;
namespace crt  = server::zone::objects::creature;
namespace tang = server::zone::objects::tangible;

class HousePackupManager : public Logger, public Object, public Singleton<HousePackupManager> {
public:
    HousePackupManager() { setLoggingName("HousePackupManager"); }
    inline void initialize(sz::ZoneServer* zs) { zoneServer = zs; }

    // Main entry points
    bool packUpHouse(bld::BuildingObject* building, crt::CreatureObject* requester);
    bool restoreFromDeed(bld::BuildingObject* building, tang::TangibleObject* deed, crt::CreatureObject* placer);
    bool hasVendorsInside(bld::BuildingObject* building) const;
    // Add to HousePackupManager.h
    bool hasLotPlaceholder(uint64 deedOID) const;

    // Payload wiring
    void attachPayloadToDeedFromBuilding(uint64 buildingOID, uint64 deedOID);
    void rememberPayloadForDeed(uint64 deedOID, const Vector<uint8>& blob);
    void rememberPayloadForBuilding(uint64 buildingOID, const Vector<uint8>& blob);
    bool takePayloadForBuilding(uint64 buildingOID, Vector<uint8>& out);

    // Optional player-pending cache
    void rememberPendingForPlayer(uint64 playerOID, const Vector<uint8>& blob);
    bool takePendingForPlayer(uint64 playerOID, Vector<uint8>& out);
    void clearPendingForPlayer(uint64 playerOID);

    // Safety checks
    bool hasSavedPayloadForBuilding(uint64 buildingOID) const;
    bool autoPackIfNeeded(bld::BuildingObject* building, crt::CreatureObject* requester);
    bool hasSavedPayloadForDeed(uint64 deedOID) const;

  // Lot-hold mapping (deed → placeholder structure OID)
void recordLotHold(uint64 deedOID, uint64 holdStructureOID);
uint64 takeLotHold(uint64 deedOID); // returns 0 if none

// Create a temporary "placeholder" structure to hold lots during pack-up.
uint64 createLotsPlaceholderFor(
    server::zone::objects::creature::CreatureObject* owner,
    int lotSize,
    uint64 deedOID,
    const String& structureTemplatePath);

// Remove & destroy a previously created lots placeholder (if present).
void releaseLotsPlaceholder(uint64 deedOID,
    server::zone::objects::creature::CreatureObject* owner = nullptr);

// Clean up any dangling placeholders on this player
void sweepDanglingLotHolds(crt::CreatureObject* player);

private:
    sz::ZoneServer* zoneServer = nullptr;
};
