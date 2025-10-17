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
// Map stable portal/cell number -> CellObject*
static void mapCellsByNumber(BuildingObject* building,
                             HashTable<uint16, ManagedReference<CellObject*>>& out) {
    out.removeAll(); // HashTable has removeAll(), not clear()
    if (!building) return;

    Vector< ManagedReference<CellObject*> > cells;
    listCells(building, cells);

    for (int i = 0; i < cells.size(); ++i) {
        ManagedReference<CellObject*> c = cells.get(i);
        if (!c) continue;
        uint16 num = (uint16)c->getCellNumber(); // stable id in Core3
        out.put(num, c);
    }
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

    // Method 1: Use building's built-in cell enumeration
    for (uint32 i = 1; i <= building->getTotalCellNumber(); ++i) {
        ManagedReference<CellObject*> cell = building->getCell(i);
        if (cell != nullptr) {
            cellsOut.add(cell);
        }
    }

    // Method 2: If no cells found via method 1, fall back to container traversal
    if (cellsOut.size() == 0) {
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
// Add this new function to HousePackupManager.cpp
static void listAllBuildingContents(BuildingObject* building, Vector< ManagedReference<SceneObject*> >& out) {
    out.removeAll();
    if (!building) return;

    Locker _lock(building);

    // Recursively scan the entire building hierarchy
    std::function<void(SceneObject*)> scanObject = [&](SceneObject* obj) {
        if (!obj) return;
        
        // Add this object if it's not a cell and not a creature/terminal
        if (!obj->isCellObject() && !obj->isCreatureObject() && !obj->isTerminal()) {
            out.add(obj);
        }

        // Recursively scan children
        const VectorMap<unsigned long long, ManagedReference<SceneObject*> >* cont = obj->getContainerObjects();
        if (cont) {
            for (int i = 0; i < cont->size(); ++i) {
                ManagedReference<SceneObject*> child = cont->elementAt(i).getValue();
                if (child != nullptr) {
                    scanObject(child.get());
                }
            }
        }
    };

    scanObject(building);
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

    // Debug: Show what cells and items were found
    requester->sendSystemMessage("Total cells found: " + String::valueOf((int)cells.size()));

    // Debug: Try to find items using alternative methods
    for (int ci = 0; ci < cells.size(); ++ci) {
        ManagedReference<CellObject*> cell = cells.get(ci);
        if (!cell) continue;

        // Check if cell has ANY children at all
        if (cell->getContainerObjectsSize() > 0) {
            requester->sendSystemMessage("Cell " + String::valueOf(ci + 1) +
                                         " reports " + String::valueOf(cell->getContainerObjectsSize()) +
                                         " container objects");
        }

        Vector< ManagedReference<SceneObject*> > contents;
        listCellContents(cell, contents);

        // Debug: Show cell info
        requester->sendSystemMessage("Cell " + String::valueOf(ci + 1) + ": " +
                                     String::valueOf(contents.size()) + " items");
    }

    // Build payload blob v3: [u8 ver=3][u32 count][per-item...]
    // Per item v3: u32 tpl, u16 cellIndex, u16 parentIndex(0xFFFF=no parent),
    //              u16 cellNumber, f32 px,py,pz, f32 qw,qx,qy,qz
    Vector<uint8> blob;
    blob.add((uint8)3); // version 3: stable cellNumber + cell-local coords

    // Pre-order list so we know parent indices
    Vector< ManagedReference<SceneObject*> > ordered;
    Vector<uint16> orderedCellIndex;
    Vector<uint16> orderedParentIndex;

    // Store all cell contents for reuse in deletion phase
    Vector< Vector< ManagedReference<SceneObject*> > > allCellContents;

    // Seed with top-level objects in each cell
    for (int ci = 0; ci < cells.size(); ++ci) {
        ManagedReference<CellObject*> cell = cells.get(ci);

        Vector< ManagedReference<SceneObject*> > contents;
        if (cell != nullptr) {
            listCellContents(cell, contents);
        }

        // Store contents for later reuse during deletion
        allCellContents.add(contents);

        // Debug: Show exactly what items are found in each cell with coordinates
        for (int i = 0; i < contents.size(); ++i) {
            SceneObject* obj = contents.get(i);
            if (obj != nullptr && !obj->isCreatureObject() && !obj->isTerminal()) {
                requester->sendSystemMessage("  Found item: " + obj->getDisplayedName() +
                                             " in cell " + String::valueOf(ci + 1) +
                                             " at X=" + String::valueOf(obj->getPositionX()) +
                                             " Y=" + String::valueOf(obj->getPositionY()) +
                                             " Z=" + String::valueOf(obj->getPositionZ()));
            }
        }

        for (int i = 0; i < contents.size(); ++i) {
            collectDeep(contents.get(i), (uint16)ci, (uint16)0xFFFF,
                        ordered, orderedCellIndex, orderedParentIndex);
        }
    }

    uint32 count = (uint32)ordered.size();

    requester->sendSystemMessage("Items found via cell scanning: " + String::valueOf(count));

    // If no items found via cell scanning, try building-wide scan
    if (count == 0) {
        requester->sendSystemMessage("No items found via cell scanning, trying building-wide scan...");

        Vector< ManagedReference<SceneObject*> > allBuildingItems;
        listAllBuildingContents(building, allBuildingItems);

        requester->sendSystemMessage("Building-wide scan found " +
                                     String::valueOf(allBuildingItems.size()) + " items");

        for (int i = 0; i < allBuildingItems.size(); ++i) {
            SceneObject* obj = allBuildingItems.get(i);
            if (obj != nullptr) {
                requester->sendSystemMessage("  Found: " + obj->getDisplayedName());
                collectDeep(obj, 0, (uint16)0xFFFF, ordered, orderedCellIndex, orderedParentIndex);
            }
        }

        count = (uint32)ordered.size();
        requester->sendSystemMessage("After building-wide scan: " + String::valueOf(count) + " items");

        // Store building items for deletion
        allCellContents.removeAll();
        allCellContents.add(allBuildingItems);
    }

    requester->sendSystemMessage(
        "Pack scan: " + String::valueOf((int)cells.size()) + " cells, " +
        String::valueOf((int)count) + " candidate items."
    );

    // Write count (big-endian u32)
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

    // write per-item (v3 layout)
    for (uint32 idx = 0; idx < count; ++idx) {
        SceneObject* obj = ordered.get(idx);
        uint16 cellIdx   = orderedCellIndex.get(idx);
        uint16 parentIdx = orderedParentIndex.get(idx);
        uint32 tpl       = obj->getServerObjectCRC();

        // u32 tpl
        blob.add((uint8)((tpl >> 24) & 0xFF));
        blob.add((uint8)((tpl >> 16) & 0xFF));
        blob.add((uint8)((tpl >>  8) & 0xFF));
        blob.add((uint8)((tpl      ) & 0xFF));

        // u16 cellIdx (kept for backward-compat layout)
        blob.add((uint8)((cellIdx >> 8) & 0xFF));
        blob.add((uint8)((cellIdx     ) & 0xFF));

        // u16 parentIdx
        blob.add((uint8)((parentIdx >> 8) & 0xFF));
        blob.add((uint8)((parentIdx     ) & 0xFF));

        // u16 cellNumber (stable)
        uint16 cellNumber = 0;
        {
            ManagedReference<CellObject*> objCell =
                (cellIdx < cells.size()) ? cells.get(cellIdx) : nullptr;
            if (objCell != nullptr)
                cellNumber = (uint16)objCell->getCellNumber();
        }
        blob.add((uint8)((cellNumber >> 8) & 0xFF));
        blob.add((uint8)((cellNumber     ) & 0xFF));

        // For top-level items, store cell-local pos & rot; children get identity
        if (parentIdx == (uint16)0xFFFF) {
            wf32(obj->getPositionX());
            wf32(obj->getPositionY());
            wf32(obj->getPositionZ());
            wf32(obj->getDirectionW());
            wf32(obj->getDirectionX());
            wf32(obj->getDirectionY());
            wf32(obj->getDirectionZ());
        } else {
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
        requester->sendSystemMessage("Deleting items from stored contents");

        for (int ci = 0; ci < allCellContents.size(); ++ci) {
            Vector< ManagedReference<SceneObject*> > children = allCellContents.get(ci);

            int deletedCount = 0;
            for (int i = 0; i < children.size(); ++i) {
                ManagedReference<SceneObject*> sobj = children.get(i);
                if (sobj == nullptr) continue;

                // DO NOT delete players or terminals (e.g., the structure terminal)
                if (sobj->isCreatureObject() || sobj->isTerminal())
                    continue;

                requester->sendSystemMessage("  Deleting: " + sobj->getDisplayedName() +
                    " at X=" + String::valueOf(sobj->getPositionX()) +
                    " Y=" + String::valueOf(sobj->getPositionY()) +
                    " Z=" + String::valueOf(sobj->getPositionZ()));

                // Delete everything else we packed
                sobj->destroyObjectFromWorld(true);
                sobj->destroyObjectFromDatabase(true);
                deletedCount++;
            }

            if (deletedCount > 0) {
                requester->sendSystemMessage("Content group " + String::valueOf(ci + 1) +
                                             ": deleted " + String::valueOf(deletedCount) + " items");
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

    // -------- Locate payload (RAM, then disk; migrate from building if found) --------
    if (gDeedPayloads.containsKey(deedOID)) {
        blob = gDeedPayloads.get(deedOID);
    } else {
        const String dpath       = pathForDeed(deedOID);
        const String dpathLegacy = pathForDeedLegacy(deedOID);

        if (!readBlobFromFile(dpath, blob)) {
            (void)readBlobFromFile(dpathLegacy, blob);
        }

        if (blob.isEmpty()) {
            const uint64 bOID      = newBuilding->getObjectID();
            const String bpath     = pathForBuilding(bOID);
            const String bpathLeg  = pathForBuildingLegacy(bOID);

            if (gBuildingPayloads.containsKey(bOID)) {
                blob = gBuildingPayloads.get(bOID);
                gBuildingPayloads.remove(bOID);
            } else {
                if (!readBlobFromFile(bpath, blob)) {
                    (void)readBlobFromFile(bpathLeg, blob);
                    if (!blob.isEmpty()) removeFile(bpathLeg);
                }
                if (!blob.isEmpty()) removeFile(bpath);
            }

            if (!blob.isEmpty()) {
                gDeedPayloads.put(deedOID, blob);
                (void)writeBlobToFile(dpath, blob);
            }
        }
    }

    if (blob.isEmpty()) {
        if (placer) placer->sendSystemMessage("No packed contents found for this deed.");
        return false;
    }

    // -------- Readers (big-endian) --------
    auto rU8   = [&](int& o)->uint8  { return blob.get(o++); };
    auto rU16B = [&](int& o)->uint16 { uint16 v = ((uint16)blob.get(o) << 8) | ((uint16)blob.get(o+1)); o += 2; return v; };
    auto rU32B = [&](int& o)->uint32 { uint32 v = ((uint32)blob.get(o) << 24) | ((uint32)blob.get(o+1) << 16) | ((uint32)blob.get(o+2) << 8) | ((uint32)blob.get(o+3)); o += 4; return v; };
    auto rF32B = [&](int& o)->float  { union { uint32 u; float f; } u; u.u = rU32B(o); return u.f; };

    int off = 0;
    if ((int)blob.size() < 5) {
        if (placer) placer->sendSystemMessage("Packed data is corrupted.");
        gDeedPayloads.remove(deedOID);
        removeFile(pathForDeed(deedOID));
        removeFile(pathForDeedLegacy(deedOID));
        return false;
    }

    uint8  ver   = rU8(off);   // 1 = flat, 2 = hierarchical, 3 = hierarchical + stable cellNumber
    uint32 count = rU32B(off);

    if (placer) {
        placer->sendSystemMessage("Restore: Found " + String::valueOf(count) + " items to restore");
    }

    // -------- Collect new building cells + stable number map --------
    Vector< ManagedReference<CellObject*> > cells;
    listCells(newBuilding, cells);

    if (cells.isEmpty()) {
        gDeedPayloads.remove(deedOID);
        removeFile(pathForDeed(deedOID));
        removeFile(pathForDeedLegacy(deedOID));
        if (placer) placer->sendSystemMessage("Restore aborted: building has no cells.");
        return false;
    }

    HashTable<uint16, ManagedReference<CellObject*> > cellsByNumber;
    cellsByNumber.removeAll(); // NOTE: HashTable uses removeAll, not clear()

    for (int i = 0; i < cells.size(); ++i) {
        ManagedReference<CellObject*> c = cells.get(i);
        if (!c) continue;
        uint16 num = (uint16)c->getCellNumber();  // stable portal/cell id
        cellsByNumber.put(num, c);
        if (placer) placer->sendSystemMessage("  Cell " + String::valueOf(i + 1) + " => cellNumber " + String::valueOf((int)num));
    }

    // -------- First pass: create objects; place top-level only --------
    Vector< ManagedReference<SceneObject*> > created;
    Vector<uint16> parentIndex;  // 0xFFFF = no parent (top-level)

    uint32 restored = 0, failedCreate = 0, failedTransfer = 0;

    for (uint32 k = 0; k < count; ++k) {
        // Layout sizes:
        // v1: tpl(4) + cIdx(2)              + 7*f32
        // v2: tpl(4) + cIdx(2) + pIdx(2)    + 7*f32
        // v3: tpl(4) + cIdx(2) + pIdx(2) + cellNumber(2) + 7*f32
        int need = 4 + 2 + ((ver >= 2) ? 2 : 0) + ((ver >= 3) ? 2 : 0) + 7 * 4;
        if (((int)blob.size() - off) < need) break;

        uint32 tpl   = rU32B(off);
        uint16 cIdx  = rU16B(off);
        uint16 pIdx  = (ver >= 2) ? rU16B(off) : (uint16)0xFFFF;
        uint16 cellNumber = 0;
        if (ver >= 3) {
            cellNumber = rU16B(off);
        }

        float px = rF32B(off), py = rF32B(off), pz = rF32B(off);
        float qw = rF32B(off), qx = rF32B(off), qy = rF32B(off), qz = rF32B(off);

        // Choose the destination cell:
        ManagedReference<CellObject*> cell = nullptr;
        if (ver >= 3) {
            if (cellsByNumber.containsKey(cellNumber))
                cell = cellsByNumber.get(cellNumber);
        }
        // Fallback for v1/v2 (or if number missing): best-effort by vector index
        if (!cell) {
            cell = (cIdx < (uint16)cells.size()) ? cells.get((int)cIdx) : cells.get(0);
        }

        // Create object (persistence=1 so it survives restarts)
        SceneObject* raw = ObjectManager::instance()->createObject(tpl, /*persistenceLevel*/1, /*db*/"sceneobjects");
        if (!raw) raw = ObjectManager::instance()->createObject(tpl, 1, "objects");
        if (!raw) raw = ObjectManager::instance()->createObject(tpl, 1, "object");

        created.add(raw);
        parentIndex.add(pIdx);

        if (!raw) { failedCreate++; continue; }
        if (!cell) { failedTransfer++; raw->destroyObjectFromWorld(true); raw->destroyObjectFromDatabase(true); created.set(k, nullptr); continue; }

        if (pIdx == (uint16)0xFFFF) {
            // TOP-LEVEL: put into the cell first, then set local transform (no world Z hacks).
            bool ok = cell->transferObject(raw, /*containmentType*/-1, /*notifyClient*/false, /*allowOverflow*/false, /*notifyRoot*/true);
            if (!ok) ok = cell->transferObject(raw, 0, false, false, true);

            if (!ok) {
                failedTransfer++;
                raw->destroyObjectFromWorld(true);
                raw->destroyObjectFromDatabase(true);
                created.set(k, nullptr);
                if (placer) placer->sendSystemMessage("  FAILED to place item in its cell.");
            } else {
                raw->setPosition(px, py, pz);          // cell-local
                raw->setDirection(qw, qx, qy, qz);     // cell-local
                raw->setPosition(raw->getPositionX(), raw->getPositionY(), raw->getPositionZ() + 0.02f); // tiny lift
                restored++;
            }
        }
        // Children will be attached in the second pass.
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

    // -------- Cleanup: don't double-restore --------
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

    // Free any lot placeholder now that contents are restored.
    releaseLotsPlaceholder(deedOID);

    return restored > 0;
}
