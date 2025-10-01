/*
 * HousePackupManager.cpp
 *
 * Packs interior items into a versioned binary blob and restores them later.
 * - Persists blobs to ./housepacks/ so server restarts don’t lose data.
 * - Uses an in-memory table too (fast path within same uptime).
 * - Supports hierarchical items (children inside containers).
 */

#include "server/zone/managers/housepackup/HousePackupManager.h"

#include "engine/engine.h"

#include "server/zone/Zone.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/managers/object/ObjectManager.h"

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sessions/DestroyStructureSession.h"

#include "templates/SharedObjectTemplate.h"
// Add these two lines:
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/structure/StructureObject.h"

// std file helpers
#include <cstdio>      // std::FILE, std::fopen, std::fwrite, std::fread, std::fclose, std::remove, std::rename
#include <sys/stat.h>  // ::stat
#include <sys/types.h>
#ifdef _WIN32
  #include <direct.h>  // _mkdir
#endif

using namespace server::zone;
using namespace server::zone::objects::scene;
using namespace server::zone::objects::cell;
using namespace server::zone::objects::building;
using namespace server::zone::objects::tangible;
using namespace server::zone::objects::creature;

// -----------------------------
// Persistent storage locations
// -----------------------------

// The server binary runs from /.../bin, so make this relative to that directory
static const char* PACK_DIR = "housepacks";

// Legacy location some forks used earlier. We only READ from here (fallback).
static const char* LEGACY_PACK_DIR = "bin/housepacks";

// deedOID -> blob (used by restore)
static HashTable<uint64, Vector<uint8> > gDeedPayloads;

// buildingOID -> blob (used during redeed window; then moved to deed)
static HashTable<uint64, Vector<uint8> > gBuildingPayloads;

// deedOID -> placeholder StructureObject OID
static HashTable<uint64, uint64> gLotHoldByDeed;

// -----------------------------
// Small filesystem helpers
// -----------------------------

// Forward declarations for helpers used later in autoPackIfNeeded(...)
static void listCells(BuildingObject* building, Vector< ManagedReference<CellObject*> >& cellsOut);
static void listCellContents(CellObject* cell, Vector< ManagedReference<SceneObject*> >& out);

static bool pathIsDir(const char* p) {
    struct stat st;
    if (::stat(p, &st) != 0) return false;
#ifdef _WIN32
    return (st.st_mode & _S_IFDIR) != 0;
#else
    return (st.st_mode & S_IFDIR) != 0;
#endif
}

static bool ensurePackDir() {
    if (pathIsDir(PACK_DIR)) return true;
#ifdef _WIN32
    int rc = ::_mkdir(PACK_DIR);
#else
    int rc = ::mkdir(PACK_DIR, 0755);
#endif
    // If it already exists, treat as success; otherwise rc==0 means created ok.
    return rc == 0 || pathIsDir(PACK_DIR);
}

static String pathForBuilding(uint64 oid) {
    String s(PACK_DIR); s += "/b-"; s += String::valueOf((int64)oid); s += ".bin";
    return s;
}
static String pathForBuildingLegacy(uint64 oid) {
    String s(LEGACY_PACK_DIR); s += "/b-"; s += String::valueOf((int64)oid); s += ".bin";
    return s;
}
static String pathForDeed(uint64 oid) {
    String s(PACK_DIR); s += "/d-"; s += String::valueOf((int64)oid); s += ".bin";
    return s;
}
static String pathForDeedLegacy(uint64 oid) {
    String s(LEGACY_PACK_DIR); s += "/d-"; s += String::valueOf((int64)oid); s += ".bin";
    return s;
}

static bool writeBlobToFile(const String& path, const Vector<uint8>& blob) {
    if (!ensurePackDir()) return false;

    std::FILE* f = std::fopen(path.toCharArray(), "wb");
    if (f == nullptr) return false;

    // Write byte-by-byte because Vector<uint8> exposes .get() and .size() only.
    size_t wrote = 0;
    for (int i = 0; i < blob.size(); ++i) {
        unsigned char c = blob.get(i);
        wrote += std::fwrite(&c, 1, 1, f);
    }

    std::fclose(f);
    return wrote == (size_t)blob.size();
}

static bool readBlobFromFile(const String& path, Vector<uint8>& out) {
    std::FILE* f = std::fopen(path.toCharArray(), "rb");
    if (f == nullptr) return false;

    std::fseek(f, 0, SEEK_END);
    long n = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    if (n <= 0) { std::fclose(f); return false; }

    out.removeAll();
    for (long i = 0; i < n; ++i) {
        unsigned char c = 0;
        size_t rd = std::fread(&c, 1, 1, f);
        if (rd != 1) { std::fclose(f); return false; }
        out.add((uint8)c);
    }

    std::fclose(f);
    return true;
}

// Tiny helpers
static bool fileExists(const String& p) {
    struct stat st;
    return ::stat(p.toCharArray(), &st) == 0 && (st.st_mode & S_IFREG);
}
static void removeFileIfExists(const String& p) {
    // std::remove returns 0 on success, non-zero on failure; ignore result.
    std::remove(p.toCharArray());
}
void HousePackupManager::sweepDanglingLotHolds(CreatureObject* player) {
    if (!player) return;

    ManagedReference<PlayerObject*> ghost = player->getPlayerObject();
    if (ghost == nullptr) return;

    const int n = ghost->getTotalOwnedStructureCount(); // your fork’s method
    for (int i = 0; i < n; ++i) {
        const uint64 oid = ghost->getOwnedStructure(i);
        if (oid == 0) continue;

        ManagedReference<SceneObject*> so = player->getZoneServer()->getObject(oid);
        StructureObject* s = so.castTo<StructureObject*>();
        if (!s) continue;

        // We only destroy placeholders we created (tagged with our ObjVar).
            // Destroying with refundLots=true returns the lots
            StructureManager::instance()->destroyStructure(s, /*playEffect*/false, /*refundLots*/true);
        }
    }

// -----------------------------
// Presence checks / auto-pack guard
// -----------------------------

bool HousePackupManager::hasSavedPayloadForBuilding(uint64 buildingOID) const {
    // RAM check
    if (gBuildingPayloads.containsKey(buildingOID))
        return true;

    // Disk check (restart-safe file created by rememberPayloadForBuilding/packUpHouse)
    const String bpath = pathForBuilding(buildingOID);
    if (fileExists(bpath))
        return true;

    // (Optional) DB check — enable if you wired DB persistence too
    // if (HousePackDB::hasBuilding(buildingOID)) return true;

    return false;
}
// Add to HousePackupManager.cpp
    bool HousePackupManager::hasLotPlaceholder(uint64 deedOID) const {
        return gLotHoldByDeed.containsKey(deedOID);
}

bool HousePackupManager::autoPackIfNeeded(BuildingObject* building, CreatureObject* requester) {
    if (building == nullptr || requester == nullptr) return false;

    // If we already have a saved payload OR a lot placeholder, we're good.
    if (hasSavedPayloadForBuilding(building->getObjectID()) || 
        gLotHoldByDeed.containsKey(building->getDeedObjectID())) {
        return true;
    }
    

    // Scan interior for *any* items (excluding players/terminals).
    Vector< ManagedReference<CellObject*> > cells;
    listCells(building, cells);

    bool hasItems = false;
    for (int ci = 0; ci < cells.size() && !hasItems; ++ci) {
        ManagedReference<CellObject*> cell = cells.get(ci);
        if (cell == nullptr) continue;

        Vector< ManagedReference<SceneObject*> > children;
        listCellContents(cell, children);

        for (int i = 0; i < children.size(); ++i) {
            SceneObject* o = children.get(i);
            if (o == nullptr) continue;
            if (o->isCreatureObject() || o->isTerminal()) continue;
            hasItems = true;
            break;
        }
    }

    if (!hasItems) {
        // Empty house — safe to proceed
        return true;
    }

    // There ARE items, but no saved payload; stop and warn clearly.
    requester->sendSystemMessage(
        "This structure still contains items. Use 'House Pack Up' at the terminal first, "
        "then destroy/redeed. (Nothing was destroyed.)"
    );
    return false;
}
bool HousePackupManager::hasSavedPayloadForDeed(uint64 deedOID) const {
    // Check RAM first
    if (gDeedPayloads.containsKey(deedOID))
        return true;
        
    // Check disk file
    const String dpath = pathForDeed(deedOID);
    if (fileExists(dpath))
        return true;
        
    // Check legacy location
    const String dpathLegacy = pathForDeedLegacy(deedOID);
    if (fileExists(dpathLegacy))
        return true;
        
    return false;
}
// Delete a file; OK if it doesn't exist.
static void removeFile(const String& path) {
    std::remove(path.toCharArray());
}


// -----------------------------
// Container traversal helpers
// -----------------------------

static void listCells(BuildingObject* building, Vector< ManagedReference<CellObject*> >& cellsOut) {
    cellsOut.removeAll();
    if (!building) return;

    Locker _lock(building);

    const VectorMap<unsigned long long, ManagedReference<SceneObject*> >* cont = building->getContainerObjects();
    if (!cont) return;

    for (int i = 0; i < cont->size(); ++i) {
        ManagedReference<SceneObject*> child = cont->elementAt(i).getValue();
        if (child != nullptr && child->isCellObject()) {
            ManagedReference<CellObject*> cell = cast<CellObject*>(child.get());
            if (cell != nullptr) cellsOut.add(cell);
        }
    }
}

static void listCellContents(CellObject* cell, Vector< ManagedReference<SceneObject*> >& out) {
    out.removeAll();
    if (!cell) return;

    Locker _lock(cell);

    const VectorMap<unsigned long long, ManagedReference<SceneObject*> >* cont = cell->getContainerObjects();
    if (!cont) return;

    for (int i = 0; i < cont->size(); ++i) {
        ManagedReference<SceneObject*> child = cont->elementAt(i).getValue();
        if (child != nullptr) out.add(child);
    }
}


// -----------------------------
// Binary readers (big-endian)
// -----------------------------

static inline uint32 rU32(const Vector<uint8>& b, int& off) {
    if ((int)b.size() - off < 4) return 0;
    uint32 v = ((uint32)b.get(off) << 24) |
               ((uint32)b.get(off + 1) << 16) |
               ((uint32)b.get(off + 2) << 8) |
               ((uint32)b.get(off + 3));
    off += 4;
    return v;
}

static inline uint16 rU16(const Vector<uint8>& b, int& off) {
    if ((int)b.size() - off < 2) return 0;
    uint16 v = ((uint16)b.get(off) << 8) | ((uint16)b.get(off + 1));
    off += 2;
    return v;
}

static inline float rF32(const Vector<uint8>& b, int& off) {
    if ((int)b.size() - off < 4) return 0.0f;
    uint32 u = rU32(b, off);
    union { uint32 u; float f; } cvt;
    cvt.u = u;
    return cvt.f;
}


// -----------------------------
// Exposed helpers (header API)
// -----------------------------

void HousePackupManager::rememberPayloadForBuilding(uint64 buildingOID, const Vector<uint8>& blob) {
	// Keep it in RAM for same-process flow.
	gBuildingPayloads.put(buildingOID, blob);

	// Also persist so we can survive server restarts.
	const String path = pathForBuilding(buildingOID);
	if (!writeBlobToFile(path, blob)) {
		// 'warning' comes from Logger base; this class derives from Logger.
		warning("HousePackup: failed to write building payload to " + path);
	}
}

void HousePackupManager::attachPayloadToDeedFromBuilding(uint64 buildingOID, uint64 deedOID) {
    Vector<uint8> blob;

    // Prefer in-memory copy first
    if (gBuildingPayloads.containsKey(buildingOID)) {
        blob = gBuildingPayloads.get(buildingOID);
        gBuildingPayloads.remove(buildingOID);
    } else {
        // Fallback: read from disk file created at pack time
        const String bpath = pathForBuilding(buildingOID);
        if (!readBlobFromFile(bpath, blob)) {
            warning("HousePackup: no payload found for building OID " + String::valueOf((int64)buildingOID) +
                    " (neither memory nor " + bpath + ")");
            return;
        }
        // Clean up the building file once we’ve loaded it
        removeFile(bpath);
    }

    // Put in memory under deed OID for immediate restore
    gDeedPayloads.put(deedOID, blob);

    // Persist under deed OID so it survives restarts (until placement restores it)
    const String dpath = pathForDeed(deedOID);
    bool wrote = writeBlobToFile(dpath, blob);

    // Optional: if you have the placer CreatureObject around, send them a message here.
    // (If you don't, this is still fine; the restore step will also log.)
    info("HousePackup: moved payload to deed OID " + String::valueOf((int64)deedOID) +
         " and wrote " + String::valueOf((int)blob.size()) + " bytes to " + dpath +
         (wrote ? " [OK]" : " [FAILED]"));
}
// ====== Top of HousePackupManager.cpp (near your other statics) ======
static HashTable<uint64, uint64> gDeedByHold;    // holdOID -> deedOID  (reverse)

// --- mapping helpers (definitions) ---
void HousePackupManager::recordLotHold(uint64 deedOID, uint64 holdStructureOID) {
    gLotHoldByDeed.put(deedOID, holdStructureOID);
}

uint64 HousePackupManager::takeLotHold(uint64 deedOID) {
    if (!gLotHoldByDeed.containsKey(deedOID))
        return 0;
    uint64 hold = gLotHoldByDeed.get(deedOID);
    gLotHoldByDeed.remove(deedOID);
    return hold;
}

uint64 HousePackupManager::createLotsPlaceholderFor(
    CreatureObject* owner,
    int lotSize,
    uint64 deedOID,
    const String& structureTemplatePath
) {
    // COMMENTED OUT - letting Core3 handle lots normally
    /*
    if (!owner || deedOID == 0) return 0;
    // Don't create a physical structure - just record that this deed "holds" lots
    // The lots are already consumed by the existing building being packed
    recordLotHold(deedOID, deedOID); // Use deed OID as the "placeholder" ID
   
    if (owner) {
        owner->sendSystemMessage("Lot hold recorded for packed house (no additional lot consumption).");
    }
   
    return deedOID;
    */
    
    // Do nothing - let Core3's normal lot system handle refunding/consuming lots
    return 0;
}

void HousePackupManager::releaseLotsPlaceholder(uint64 deedOID, CreatureObject* owner) {
    uint64 holdOID = takeLotHold(deedOID);
    if (holdOID == 0) return; // No placeholder was recorded
    
    // Since we didn't create a physical structure, just remove the mapping
    if (owner) {
        owner->sendSystemMessage("Released lot hold for packed deed - lots now available for new structure.");
    }
    
    // No structure to destroy since we only recorded the mapping
}
// -----------------------------
// Recursive collector
// -----------------------------

static void collectDeep(
    SceneObject* obj,
    uint16 cellIdx,
    uint16 parentIdx,
    Vector< ManagedReference<SceneObject*> >& ordered,
    Vector<uint16>& orderedCellIndex,
    Vector<uint16>& orderedParentIndex
) {
    if (!obj) return;
    if (obj->isCreatureObject() || obj->isTerminal()) return; // skip players/terminals

    uint16 myIndex = (uint16)ordered.size();
    ordered.add(obj);
    orderedCellIndex.add(cellIdx);
    orderedParentIndex.add(parentIdx);

    const VectorMap<unsigned long long, ManagedReference<SceneObject*> >* cmap = obj->getContainerObjects();
    if (cmap != nullptr) {
        for (int i = 0; i < cmap->size(); ++i) {
            ManagedReference<SceneObject*> child = cmap->elementAt(i).getValue();
            if (child == nullptr) continue;
            collectDeep(child, cellIdx, myIndex, ordered, orderedCellIndex, orderedParentIndex);
        }
    }
}


// -----------------------------
// Pack (called from terminal)
// -----------------------------

bool HousePackupManager::packUpHouse(BuildingObject* building, CreatureObject* requester) {
    if (building == nullptr || requester == nullptr)
        return false;

    // Collect all cells
    Vector< ManagedReference<CellObject*> > cells;
    listCells(building, cells);

    // Build payload blob v2: [u8 ver=2][u32 count][per-item...]
    // Per item v2: u32 tpl, u16 cellIndex, u16 parentIndex(0xFFFF=no parent),
    //              f32 px,py,pz, f32 qw,qx,qy,qz
    Vector<uint8> blob;
    blob.add((uint8)2); // version 2

    // Pre-order list so we know parent indices
    Vector< ManagedReference<SceneObject*> > ordered;
    Vector<uint16> orderedCellIndex;
    Vector<uint16> orderedParentIndex;

    // Seed with top-level objects in each cell
    for (int ci = 0; ci < cells.size(); ++ci) {
        ManagedReference<CellObject*> cell = cells.get(ci);
        if (!cell) continue;

        Vector< ManagedReference<SceneObject*> > contents;
        listCellContents(cell, contents);

        for (int i = 0; i < contents.size(); ++i) {
            collectDeep(contents.get(i), (uint16)ci, (uint16)0xFFFF,
                        ordered, orderedCellIndex, orderedParentIndex);
        }
    }

    uint32 count = (uint32)ordered.size();

    requester->sendSystemMessage(
        "Pack scan: " + String::valueOf((int)cells.size()) + " cells, " +
        String::valueOf((int)count) + " candidate items."
    );

    // write count (big-endian u32)
    blob.add((uint8)((count >> 24) & 0xFF));
    blob.add((uint8)((count >> 16) & 0xFF));
    blob.add((uint8)((count >>  8) & 0xFF));
    blob.add((uint8)((count      ) & 0xFF));

    // helper: write f32 as big-endian
    auto wf32 = [&](float f) {
        union { float f; uint32 u; } u; u.f = f;
        blob.add((uint8)((u.u >> 24) & 0xFF));
        blob.add((uint8)((u.u >> 16) & 0xFF));
        blob.add((uint8)((u.u >>  8) & 0xFF));
        blob.add((uint8)((u.u      ) & 0xFF));
    };

    // write per-item
    for (uint32 idx = 0; idx < count; ++idx) {
        SceneObject* obj = ordered.get(idx);
        uint16 cellIdx   = orderedCellIndex.get(idx);
        uint16 parentIdx = orderedParentIndex.get(idx);
        uint32 tpl       = obj->getServerObjectCRC();

        // tpl u32
        blob.add((uint8)((tpl >> 24) & 0xFF));
        blob.add((uint8)((tpl >> 16) & 0xFF));
        blob.add((uint8)((tpl >>  8) & 0xFF));
        blob.add((uint8)((tpl      ) & 0xFF));

        // cellIndex u16
        blob.add((uint8)((cellIdx >> 8) & 0xFF));
        blob.add((uint8)((cellIdx     ) & 0xFF));

        // parentIndex u16 (0xFFFF = top-level)
        blob.add((uint8)((parentIdx >> 8) & 0xFF));
        blob.add((uint8)((parentIdx     ) & 0xFF));

        // positions/orientations: only meaningful for top-level items
        if (parentIdx == (uint16)0xFFFF) {
            // Store current object transform. In this fork Z is up.
            wf32(obj->getPositionX());
            wf32(obj->getPositionY());
            wf32(obj->getPositionZ());
            wf32(obj->getDirectionW());
            wf32(obj->getDirectionX());
            wf32(obj->getDirectionY());
            wf32(obj->getDirectionZ());
        } else {
            // Children will be inserted into their parent's container; no transform needed.
            wf32(0.f); wf32(0.f); wf32(0.f);
            wf32(1.f); wf32(0.f); wf32(0.f); wf32(0.f);
        }
    }

    // Remember payload (RAM) and also persist to disk so it survives restarts.
    rememberPayloadForBuilding(building->getObjectID(), blob);

    const String p = pathForBuilding(building->getObjectID());
    bool wrote = writeBlobToFile(p, blob);

    // Tell the player exactly what happened so we can verify paths/sizes easily.
    requester->sendSystemMessage(
        String("Pack: wrote ") + String::valueOf((int)blob.size()) + " bytes to " + p +
        (wrote ? String(" [OK]") : String(" [FAILED]"))
    );

// Now empty the interior so the core will allow redeed/destruction.
if (building && building->getZone() != nullptr) {
    Vector< ManagedReference<CellObject*> > cellsToDelete;
    listCells(building, cellsToDelete);
    for (int ci = 0; ci < cellsToDelete.size(); ++ci) {
        ManagedReference<CellObject*> cell = cellsToDelete.get(ci);
        if (cell == nullptr) continue;
        Vector< ManagedReference<SceneObject*> > children;
        listCellContents(cell, children);
        for (int i = 0; i < children.size(); ++i) {
            ManagedReference<SceneObject*> obj = children.get(i);
            if (obj == nullptr) continue;
            // DO NOT delete players or terminals (e.g., the structure terminal)
            if (obj->isCreatureObject() || obj->isTerminal())
                continue;
            // Delete everything else we packed
            obj->destroyObjectFromWorld(true);
            obj->destroyObjectFromDatabase(true);
        }
    }
}
requester->sendSystemMessage(
    "Packed " + String::valueOf(count) +
    " items. Use 'Destroy Structure' to reclaim the deed. "
    "When the deed is granted, contents will be attached automatically."
);
return true;
}

bool HousePackupManager::restoreFromDeed(BuildingObject* newBuilding, TangibleObject* deed, CreatureObject* placer) {
    if (!newBuilding || !deed) return false;

    const uint64 deedOID = deed->getObjectID();
    Vector<uint8> blob;

    // -------- STEP 1: Try RAM by deed OID --------
    if (gDeedPayloads.containsKey(deedOID)) {
        blob = gDeedPayloads.get(deedOID);

    } else {
        // -------- STEP 2: Try deed files (current, then legacy) --------
        const String dpath = pathForDeed(deedOID);
        const String dpathLegacy = pathForDeedLegacy(deedOID);

        if (!readBlobFromFile(dpath, blob)) {
            (void)readBlobFromFile(dpathLegacy, blob); // try legacy; ignore return here
        }

        // -------- STEP 3: If still not found, try building OID (RAM/disk/legacy) and MIGRATE --------
        if (blob.isEmpty()) {
            const uint64 bOID = newBuilding->getObjectID();

            // 3a) RAM by building
            if (gBuildingPayloads.containsKey(bOID)) {
                blob = gBuildingPayloads.get(bOID);
                gBuildingPayloads.remove(bOID);

            } else {
                // 3b) Disk by building (current, then legacy)
                const String bpath = pathForBuilding(bOID);
                const String bpathLegacy = pathForBuildingLegacy(bOID);

                if (!readBlobFromFile(bpath, blob)) {
                    (void)readBlobFromFile(bpathLegacy, blob);
                    if (!blob.isEmpty()) removeFile(bpathLegacy);
                }
                if (!blob.isEmpty()) removeFile(bpath);
            }

            // If we recovered from a building payload, migrate it into deed RAM+disk for future
            if (!blob.isEmpty()) {
                gDeedPayloads.put(deedOID, blob);
                (void)writeBlobToFile(pathForDeed(deedOID), blob);
            }
        }
    }

    // Nothing found anywhere
    if (blob.isEmpty()) {
        if (placer) placer->sendSystemMessage("No packed contents found for this deed.");
        return false;
    }

    // -------- Readers (big-endian) --------
    auto rU8   = [&](int& o)->uint8  { return blob.get(o++); };
    auto rU16B = [&](int& o)->uint16 { uint16 v = ((uint16)blob.get(o)<<8) | ((uint16)blob.get(o+1)); o+=2; return v; };
    auto rU32B = [&](int& o)->uint32 { uint32 v = ((uint32)blob.get(o)<<24)|((uint32)blob.get(o+1)<<16)|((uint32)blob.get(o+2)<<8)|((uint32)blob.get(o+3)); o+=4; return v; };
    auto rF32B = [&](int& o)->float  { union { uint32 u; float f; } u; u.u = rU32B(o); return u.f; };

    int off = 0;
    if ((int)blob.size() < 5) {
        if (placer) placer->sendSystemMessage("Packed data is corrupted.");
        gDeedPayloads.remove(deedOID);
        removeFile(pathForDeed(deedOID));
        removeFile(pathForDeedLegacy(deedOID));
        return false;
    }

    uint8  ver   = rU8(off);            // 1 = flat, 2 = hierarchical
    uint32 count = rU32B(off);

    // -------- Collect new building cells --------
    Vector< ManagedReference<CellObject*> > cells;
    listCells(newBuilding, cells);
    if (cells.isEmpty()) {
        gDeedPayloads.remove(deedOID);
        removeFile(pathForDeed(deedOID));
        removeFile(pathForDeedLegacy(deedOID));
        if (placer) placer->sendSystemMessage("Restore aborted: building has no cells.");
        return false;
    }

    // Keep created objects so children can attach to parents
    Vector< ManagedReference<SceneObject*> > created;
    Vector<uint16> parentIndex;  // 0xFFFF = no parent (top-level)
    Vector<uint16> cellIndex;

    uint32 restored = 0, failedCreate = 0, failedTransfer = 0;

    // -------- First pass: create objects; place top-level only --------
    for (uint32 k = 0; k < count; ++k) {
        // v1: u32 tpl, u16 cell, 7*f32; v2 adds u16 parent -> 34 vs 36 bytes
        int need = (ver >= 2 ? 4+2+2 + 7*4 : 4+2 + 7*4);
        if (((int)blob.size() - off) < need) break;

        uint32 tpl   = rU32B(off);
        uint16 cIdx  = rU16B(off);
        uint16 pIdx  = (ver >= 2) ? rU16B(off) : (uint16)0xFFFF;

        float px = rF32B(off), py = rF32B(off), pz = rF32B(off);
        float qw = rF32B(off), qx = rF32B(off), qy = rF32B(off), qz = rF32B(off);

        ManagedReference<CellObject*> cell =
            (cIdx < (uint16)cells.size()) ? cells.get((int)cIdx) : cells.get(0);

        // Use persistence=1 so restored items survive restarts
        SceneObject* raw = ObjectManager::instance()->createObject(tpl, /*persistenceLevel*/1, /*db*/"sceneobjects");
        if (!raw) raw = ObjectManager::instance()->createObject(tpl, 1, "objects");
        if (!raw) raw = ObjectManager::instance()->createObject(tpl, 1, "object");

        created.add(raw);
        parentIndex.add(pIdx);
        cellIndex.add(cIdx);

        if (!raw || !cell) { failedCreate += (!raw); failedTransfer += (!!raw && !cell); continue; }

        if (pIdx == (uint16)0xFFFF) {
            // Top-level placement: positions were stored with Z up — place as-is.
            float z = pz;

            // Gentle clamp above floor to prevent sinking on some shells.
            float floorZ = cell->getPositionZ();
            if (z < floorZ + 0.01f) z = floorZ + 0.02f;

            raw->setPosition(px, /*world Y*/ py, /*world Z*/ z);
            raw->setDirection(qw, qx, qy, qz);

            bool ok = cell->transferObject(raw, /*containmentType*/-1, /*notifyClient*/false, /*allowOverflow*/false, /*notifyRoot*/true);
            if (!ok) ok = cell->transferObject(raw, 0, false, false, true);
            if (!ok) {
                failedTransfer++;
                raw->destroyObjectFromWorld(true);
                raw->destroyObjectFromDatabase(true);
                created.set(k, nullptr);
            } else {
                // tiny lift to avoid z-fighting
                raw->setPosition(raw->getPositionX(), raw->getPositionY(), raw->getPositionZ() + 0.02f);
                restored++;
            }
        }
        // Children attached in second pass.
    }

    // -------- Second pass: attach children into their parent containers --------
    if (ver >= 2) {
        for (uint32 k = 0; k < count; ++k) {
            uint16 pIdx = parentIndex.get(k);
            if (pIdx == (uint16)0xFFFF) continue;

            SceneObject* child  = created.get(k);
            SceneObject* parent = (pIdx < created.size()) ? created.get(pIdx) : nullptr;
            if (!child || !parent) continue;

            bool ok = parent->transferObject(child, /*containmentType*/-1, /*notifyClient*/false, /*allowOverflow*/false, /*notifyRoot*/true);
            if (!ok) ok = parent->transferObject(child, 0, false, false, true);
            if (!ok) {
                failedTransfer++;
                child->destroyObjectFromWorld(true);
                child->destroyObjectFromDatabase(true);
                created.set(k, nullptr);
            } else {
                restored++;
            }
        }
    }

    // -------- Cleanup: don’t double-restore --------
    gDeedPayloads.remove(deedOID);
    removeFile(pathForDeed(deedOID));
    removeFile(pathForDeedLegacy(deedOID));

    if (placer) {
        placer->sendSystemMessage(
            "Restore complete: " +
            String::valueOf(restored) + " restored, " +
            String::valueOf(failedCreate) + " create fails, " +
            String::valueOf(failedTransfer) + " transfer fails."
        );
    }
    // Free the lot placeholder now that the house has been placed and contents restored.
    releaseLotsPlaceholder(deedOID);


    return restored > 0;
}
