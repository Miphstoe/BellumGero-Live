/*
 * WorldResetManager.cpp
 *
 * ============================================================================
 * SCOPE
 * ============================================================================
 * "/worldreset" performs a CONTROLLED administrative reset of exactly two things:
 *
 *   1. DEPLOYED player-owned structures   (houses, factories, harvesters,
 *      generators and other player installations that are currently placed in a
 *      zone, plus playerstructures.db records that lost their zone / owner).
 *   2. PLAYER-CREATED cities              (persistent CityRegion objects in
 *      cityregions.db, including their City Hall and civic structures).
 *
 * It is NOT a galaxy wipe. It never touches:
 *   - accounts / characters / skills / XP / Jedi progression / quests / badges
 *   - inventories / datapads / bank / credits / deeds / vehicles / pets / droids
 *   - PACKED houses (a packed house becomes a StructureDeed item + a
 *     housepacks/d-<deedOID>.bin payload; it is NOT a StructureObject and is not
 *     in playerstructures.db, so it is structurally impossible for this code to
 *     reach it)
 *   - the contents that were packed with a house (those objects live in
 *     sceneobjects.db, which this code never opens or iterates)
 *   - the resource database (resourcespawns.db) -- see note in collectSnapshot()
 *   - guilds, bounties, static/NPC cities, static buildings, static spawns, NPCs
 *
 * ============================================================================
 * WHY THE RESOURCE DATABASE IS SAFE
 * ============================================================================
 * Current + historical resources, spawn state and resource identifiers are all
 * persisted by ResourceSpawner into its own Berkeley DB "resourcespawns.db"
 * (ObjectManager::createObject(..., "resourcespawns")). This manager only ever
 * opens "playerstructures.db" and "cityregions.db", only ever calls
 * StructureManager::destroyStructure() and CityManager::destroyCity(), and never
 * calls any ResourceManager / ResourceSpawner / galaxy-reset entry point. There
 * is no code path from here to resource persistence.
 *
 * ============================================================================
 * WHY sceneobjects.db IS NOT WIPED
 * ============================================================================
 * Deployed player structures are persisted in their OWN database
 * "playerstructures.db" with an associated Berkeley secondary index
 * "playerstructuresindex.db" (StructureManager::createSubIndex ->
 * playerStructuresDatabase->associate(...)). Because the index is a Berkeley
 * associated secondary index, deleting a primary record automatically removes
 * its secondary-index entries -- no manual index surgery is required.
 * destroyObjectFromDatabase(true) removes the structure (and its child cells)
 * from whichever database owns it. sceneobjects.db holds unrelated world/player
 * objects and is never the target here.
 *
 * ============================================================================
 * LOT ACCOUNTING
 * ============================================================================
 * Bellum Gero lot usage is DERIVED, not a stored counter
 * (StructureManager::getAccountLotsUsed iterates the owner's owned-structure list
 * and playerstructures.db). DestroyStructureTask calls
 * PlayerObject::removeOwnedStructure() and destroyObjectFromDatabase(true), so
 * once a structure is gone it stops counting against lots automatically. Running
 * the reset twice cannot over-refund or corrupt lot state.
 *
 * ============================================================================
 * VENDORS
 * ============================================================================
 * A vendor inside a deployed house is a child of a cell. Normal Core3 house
 * destruction (DestroyStructureTask -> destroyObjectFromDatabase(true)) destroys
 * the cell subtree, which includes the vendor and its stock. That is the
 * documented, expected behaviour of destroying a deployed house and it is why
 * players are instructed to PACK UP first. The dry-run counts vendors found in
 * affected structures so an operator can see the exposure before arming.
 *
 * ============================================================================
 * OPERATOR SEQUENCE  (each step also re-checks Admin Level 15)
 * ============================================================================
 *   /worldreset authenticate <secret>
 *   /worldreset dryrun
 *   /worldreset status
 *   /worldreset arm
 *   /worldreset execute RESET-HOUSING-AND-CITIES
 *   /worldreset cancel        (optional: clears armed + dry-run + auth)
 */

#include "server/zone/managers/worldreset/WorldResetManager.h"

#include "engine/engine.h"
#include "engine/core/TaskManager.h"
#include "engine/db/ObjectDatabase.h"
#include "engine/db/ObjectDatabaseManager.h"
#include "engine/db/IndexDatabase.h"
#include "engine/db/berkeley/CursorConfig.h"
#include "system/io/ObjectInputStream.h"

#include "conf/ConfigManager.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneClientSession.h"
#include "server/zone/packets/player/LogoutMessage.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/region/CityRegion.h"

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/managers/structure/tasks/DestroyStructureTask.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/managers/housepackup/HousePackupManager.h"

#include "templates/SharedObjectTemplate.h"
#include "templates/manager/TemplateManager.h"

#include "system/io/Serializable.h"
#include "system/lang/Time.h"
#include "system/thread/Thread.h"
#include "system/util/VectorMap.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>

// The generated Core3 headers each publish their class into the global namespace
// (trailing `using namespace ...` inside the autogen .h), which is why the rest of
// this file can refer to CreatureObject / StructureObject / CityRegion / etc.
// without qualification -- the same convention StructureManager.cpp uses.

const char* const WorldResetManager::CONFIG_SECRET_KEY = "Core3.WorldResetSecret";
const char* const WorldResetManager::EXECUTE_PHRASE = "RESET-HOUSING-AND-CITIES";

// ---------------------------------------------------------------------------
// small helpers
// ---------------------------------------------------------------------------

uint64 WorldResetManager::nowMs() {
	return Time().getMiliTime();
}

String WorldResetManager::getConfiguredSecret() const {
	return ConfigManager::instance()->getString(CONFIG_SECRET_KEY, "");
}

bool WorldResetManager::isSecretConfigured() const {
	return getConfiguredSecret().length() > 0;
}

bool WorldResetManager::constantTimeEquals(const String& a, const String& b) {
	// Compare without early-out. Length difference is folded into the result so a
	// wrong-length guess still costs the same and never matches.
	const int la = a.length();
	const int lb = b.length();
	const int n = Math::max(la, lb);

	uint32 diff = (uint32)(la ^ lb);

	for (int i = 0; i < n; ++i) {
		char ca = (i < la) ? a.charAt(i) : 0;
		char cb = (i < lb) ? b.charAt(i) : 0;
		diff |= (uint32)((uint8)ca ^ (uint8)cb);
	}

	return diff == 0 && la == lb;
}

bool WorldResetManager::isAuthenticatedLocked(uint64 adminOID) const {
	return authAdminOID != 0 && authAdminOID == adminOID && nowMs() < authExpireMs;
}

void WorldResetManager::clearAuthLocked() {
	authAdminOID = 0;
	authExpireMs = 0;
}

void WorldResetManager::clearArmLocked() {
	armed = false;
	armedAtMs = 0;
	armExpireMs = 0;
	armAdminOID = 0;
}

void WorldResetManager::clearDryRunLocked() {
	dryRunComplete = false;
	dryRunSafe = false;
	dryRunTimeMs = 0;
	dryRunAdminOID = 0;
	lastCounts = DryRunCounts();
	lastFingerprint = "";
	snapshotCityOIDs.removeAll();
	snapshotStructureOIDs.removeAll();
	snapshotOrphanOIDs.removeAll();
}

static String describeStructureType(StructureObject* s) {
	if (s == nullptr)
		return "unknown";
	if (s->isCityHall())
		return "city_hall";
	if (s->isCivicStructure())
		return "civic";
	if (s->isGCWBase())
		return "gcw_base";
	if (s->isFactory())
		return "factory";
	if (s->isHarvesterObject())
		return "harvester";
	if (s->isGeneratorObject())
		return "generator";
	if (s->isInstallationObject())
		return "installation";
	if (s->isBuildingObject())
		return "building";
	return "structure";
}

// True if a persisted _className names a class we consider a player-structure
// artifact (building / installation / structure family). Used to decide whether a
// record that will not load is at least *provably* player-structure state.
static bool classNameIsPlayerStructure(const String& className) {
	if (className.isEmpty())
		return false;

	return className.contains("BuildingObject")
		|| className.contains("InstallationObject")
		|| className.contains("HarvesterObject")
		|| className.contains("FactoryObject")
		|| className.contains("GeneratorObject")
		|| className.contains("StructureObject")
		|| className.contains("PlayerStructure");
}

// ---------------------------------------------------------------------------
// fail-closed safety evaluation
// ---------------------------------------------------------------------------

bool WorldResetManager::evaluateSafety(const DryRunCounts& c, Vector<String>& reasons) {
	if (c.dbReadErrors > 0)
		reasons.add(String::valueOf(c.dbReadErrors) + " database read/iteration error(s) affected classification");

	if (c.unreadableStructureRecords > 0)
		reasons.add(String::valueOf(c.unreadableStructureRecords)
			+ " playerstructures.db record(s) could not be classified (template/serialization not resolvable) -- see [WORLDRESET][ORPHAN] log lines");

	if (c.unreadableCityRecords > 0)
		reasons.add(String::valueOf(c.unreadableCityRecords) + " cityregions.db record(s) could not be classified");

	if (c.packedPendingRedeem > 0)
		reasons.add(String::valueOf(c.packedPendingRedeem)
			+ " building(s) have a pending pack payload but the deed has not been redeemed -- players must finish 'Destroy Structure' first");

	if (c.unclassifiedLiveObjects > 0)
		reasons.add(String::valueOf(c.unclassifiedLiveObjects) + " loaded object(s) threw during classification");

	return reasons.isEmpty();
}

// ---------------------------------------------------------------------------
// deterministic candidate-set fingerprint (order independent)
// ---------------------------------------------------------------------------

String WorldResetManager::computeFingerprint(const DryRunCounts& c, const SortedVector<uint64>& cityOIDs,
		const SortedVector<uint64>& structureOIDs, const SortedVector<uint64>& orphanOIDs) {
	// FNV-1a over the sorted OID lists plus the salient counts. Cheap, stable and
	// sensitive to any change in the candidate set.
	uint64 h = 1469598103934665603ULL;

	auto mix = [&h](uint64 v) {
		for (int i = 0; i < 8; ++i) {
			h ^= (v & 0xFF);
			h *= 1099511628211ULL;
			v >>= 8;
		}
	};

	mix(0x0C17133ULL); // city-list tag
	mix((uint64)cityOIDs.size());
	for (int i = 0; i < cityOIDs.size(); ++i)
		mix(cityOIDs.get(i));

	mix(0x05710C7ULL); // structure-list tag
	mix((uint64)structureOIDs.size());
	for (int i = 0; i < structureOIDs.size(); ++i)
		mix(structureOIDs.get(i));

	mix(0x002FA11ULL); // orphan-list tag
	mix((uint64)orphanOIDs.size());
	for (int i = 0; i < orphanOIDs.size(); ++i)
		mix(orphanOIDs.get(i));

	mix((uint64)c.playerCities);
	mix((uint64)c.deployedHouses);
	mix((uint64)c.installations + c.factories + c.harvesters + c.generators + c.otherDeployedStructures);
	mix((uint64)c.unreadableStructureRecords);
	mix((uint64)c.unreadableCityRecords);
	mix((uint64)c.packedPendingRedeem);
	mix((uint64)c.gcwBasesExcluded);
	mix((uint64)c.staticCitiesExcluded);

	return String::hexvalueOf(h);
}

// ---------------------------------------------------------------------------
// persistent interrupted-reset marker
// ---------------------------------------------------------------------------

const char* WorldResetManager::stateFilePath() {
	return "worldreset/state.txt";
}

String WorldResetManager::phaseName(ResetPhase phase) {
	switch (phase) {
		case PHASE_IDLE: return "IDLE";
		case PHASE_PRECHECK: return "PRECHECK";
		case PHASE_CLIENT_DRAIN: return "CLIENT_DRAIN";
		case PHASE_CITIES: return "CITY_PHASE";
		case PHASE_CIVIC: return "CIVIC_PHASE";
		case PHASE_STRUCTURES: return "STRUCTURE_PHASE";
		case PHASE_ORPHANS: return "ORPHAN_PHASE";
		case PHASE_PAYLOADS: return "PAYLOAD_PHASE";
		case PHASE_VALIDATION: return "VALIDATION_PHASE";
		case PHASE_COMPLETE: return "COMPLETE";
		case PHASE_FAILED: return "FAILED";
	}
	return "UNKNOWN";
}

void WorldResetManager::writeStatePhase(ResetPhase phase, const String& note) const {
	::mkdir("worldreset", 0755); // ok if it already exists

	std::FILE* f = std::fopen(stateFilePath(), "w");

	if (f == nullptr) {
		error() << "[WORLDRESET] could not write state marker " << stateFilePath();
		return;
	}

	std::fprintf(f, "phase=%s\nphaseId=%d\ntimeMs=%llu\nnote=%s\n",
		phaseName(phase).toCharArray(), (int)phase,
		(unsigned long long)nowMs(), note.toCharArray());

	std::fclose(f);
}

WorldResetManager::ResetPhase WorldResetManager::readStatePhase(String& note) const {
	note = "";

	std::FILE* f = std::fopen(stateFilePath(), "r");

	if (f == nullptr)
		return PHASE_IDLE;

	char buf[512];
	int phaseId = -1;
	String phaseNameStr;

	while (std::fgets(buf, sizeof(buf), f) != nullptr) {
		if (std::strncmp(buf, "phaseId=", 8) == 0) {
			phaseId = std::atoi(buf + 8);
		} else if (std::strncmp(buf, "phase=", 6) == 0) {
			phaseNameStr = String(buf + 6).trim();
		} else if (std::strncmp(buf, "note=", 5) == 0) {
			note = String(buf + 5).trim();
		}
	}

	std::fclose(f);

	// Resolve by NAME first so enum reordering never corrupts an existing state
	// file; fall back to the numeric id, then IDLE.
	for (int p = (int)PHASE_IDLE; p <= (int)PHASE_FAILED; ++p) {
		if (phaseNameStr == phaseName((ResetPhase)p))
			return (ResetPhase)p;
	}

	if (phaseId >= 0 && phaseId <= (int)PHASE_FAILED)
		return (ResetPhase)phaseId;

	// The file exists but we could not resolve a phase -- fail closed.
	error() << "[WORLDRESET] state.txt present but unparseable (phase=\"" << phaseNameStr
		<< "\" phaseId=" << phaseId << ") -- treating as FAILED";
	return PHASE_FAILED;
}

// ---------------------------------------------------------------------------
// target manifest + per-target progress
// ---------------------------------------------------------------------------

const char* WorldResetManager::manifestFilePath() {
	return "worldreset/manifest.txt";
}

const char* WorldResetManager::progressFilePath() {
	return "worldreset/progress.log";
}

// Escape '|' and newlines so metadata fields stay single-token / single-line.
static String wrSanitize(const String& in) {
	StringBuffer b;
	for (int i = 0; i < in.length(); ++i) {
		char c = in.charAt(i);
		if (c == '|' || c == '\n' || c == '\r')
			c = '_';
		b << c;
	}
	return b.toString();
}

void WorldResetManager::writeManifestV2(ZoneServer* zoneServer, const String& fingerprint, uint64 armedMs,
		const SortedVector<uint64>& cityOIDs, const SortedVector<uint64>& structureOIDs,
		const SortedVector<uint64>& orphanOIDs) const {
	::mkdir("worldreset", 0755);

	std::FILE* f = std::fopen(manifestFilePath(), "w");

	if (f == nullptr) {
		error() << "[WORLDRESET] could not write manifest " << manifestFilePath();
		return;
	}

	std::fprintf(f, "v=2\nfingerprint=%s\narmedMs=%llu\nexecuteMs=%llu\n",
		fingerprint.toCharArray(), (unsigned long long)armedMs, (unsigned long long)nowMs());

	// Cities: identity = mayorID + name (city hall is destroyed via CityManager).
	for (int i = 0; i < cityOIDs.size(); ++i) {
		const uint64 oid = cityOIDs.get(i);
		uint64 mayorID = 0;
		String name;
		try {
			Reference<CityRegion*> c = Core::getObjectBroker()->lookUp(oid).castTo<CityRegion*>();
			if (c != nullptr) { mayorID = c->getMayorID(); name = c->getCityRegionName(); }
		} catch (...) {}
		std::fprintf(f, "C|%llu|city|0|0|%llu|0|%s\n",
			(unsigned long long)oid, (unsigned long long)mayorID, wrSanitize(name).toCharArray());
	}

	// Structures + orphans: identity = serverObjectCRC + gameObjectType + owner + zoneHash + template.
	auto writeStructRec = [&](const char* kind, uint64 oid) {
		String category = "other", tmpl = "<none>";
		uint32 crc = 0;
		int got = -1;
		uint64 owner = 0;
		uint64 zoneHash = 0;
		try {
			ManagedReference<SceneObject*> so = zoneServer->getObject(oid);
			ManagedReference<StructureObject*> s = (so != nullptr) ? so.castTo<StructureObject*>() : nullptr;
			if (s != nullptr) {
				crc = s->getServerObjectCRC();
				got = (int)s->getGameObjectType();
				owner = s->getOwnerObjectID();
				if (s->getObjectTemplate() != nullptr)
					tmpl = s->getObjectTemplate()->getFullTemplateString();
				if (s->getZone() != nullptr)
					zoneHash = s->getZone()->getZoneName().hashCode();
				if (s->isFactory()) category = "factory";
				else if (s->isHarvesterObject()) category = "harvester";
				else if (s->isGeneratorObject()) category = "generator";
				else if (s->isInstallationObject()) category = "installation";
				else if (s->isBuildingObject()) category = "house";
			}
		} catch (...) {}
		std::fprintf(f, "%s|%llu|%s|%u|%d|%llu|%llu|%s\n",
			kind, (unsigned long long)oid, category.toCharArray(), crc, got,
			(unsigned long long)owner, (unsigned long long)zoneHash, wrSanitize(tmpl).toCharArray());
	};

	for (int i = 0; i < structureOIDs.size(); ++i)
		writeStructRec("S", structureOIDs.get(i));
	for (int i = 0; i < orphanOIDs.size(); ++i)
		if (!structureOIDs.contains(orphanOIDs.get(i)))
			writeStructRec("O", orphanOIDs.get(i));

	std::fclose(f);

	std::remove(progressFilePath()); // fresh manifest -> fresh progress

	info(true) << "[WORLDRESET][MANIFEST] v2 written -- " << cityOIDs.size() << " city + "
		<< structureOIDs.size() << " structure + " << orphanOIDs.size()
		<< " orphan targets (identity metadata captured), fingerprint " << fingerprint;
}

bool WorldResetManager::parseTargetMeta(const String& metaLine, String& kind, String& category,
		uint32& crc, int& got, uint64& owner) {
	// "<kind>|<oid>|<category>|<crc>|<got>|<owner>|<zoneHash>|<template>"
	kind = ""; category = ""; crc = 0; got = -1; owner = 0;

	int field = 0, start = 0;
	for (int i = 0; i <= metaLine.length(); ++i) {
		if (i == metaLine.length() || metaLine.charAt(i) == '|') {
			String tok = metaLine.subString(start, i);
			switch (field) {
				case 0: kind = tok; break;
				case 2: category = tok; break;
				case 3: crc = (uint32)::strtoul(tok.toCharArray(), nullptr, 10); break;
				case 4: got = (int)::strtol(tok.toCharArray(), nullptr, 10); break;
				case 5: owner = ::strtoull(tok.toCharArray(), nullptr, 10); break;
				default: break;
			}
			++field;
			start = i + 1;
		}
	}
	return field >= 6;
}

bool WorldResetManager::readManifestV2(String& fingerprint, uint64& armedMs, uint64& executeMs,
		Vector<uint64>& cityOrder, Vector<uint64>& structOrder, VectorMap<uint64, String>& meta) const {
	fingerprint = ""; armedMs = 0; executeMs = 0;
	cityOrder.removeAll();
	structOrder.removeAll();
	meta.removeAll();

	std::FILE* f = std::fopen(manifestFilePath(), "r");
	if (f == nullptr)
		return false;

	char buf[1024];
	while (std::fgets(buf, sizeof(buf), f) != nullptr) {
		String line = String(buf).trim();

		if (line.beginsWith("fingerprint=")) { fingerprint = line.subString(12); continue; }
		if (line.beginsWith("armedMs=")) { armedMs = ::strtoull(line.toCharArray() + 8, nullptr, 10); continue; }
		if (line.beginsWith("executeMs=")) { executeMs = ::strtoull(line.toCharArray() + 10, nullptr, 10); continue; }
		if (line.beginsWith("timeMs=")) { if (executeMs == 0) executeMs = ::strtoull(line.toCharArray() + 7, nullptr, 10); continue; }

		// ----- v1 manifest fallback -----
		// The first real execute test wrote a v1 manifest ("city=<oid>" /
		// "struct=<oid>" / "orphan=<oid>", no identity metadata). An interrupted
		// v1 reset must still be resumable, so translate those lines into targets
		// with EMPTY identity metadata (crc=0, got=-1, owner=0) -> every identity
		// check is skipped and completion is decided purely by object absence,
		// which is always safe (a missing OID is never re-deleted, a present
		// manifest OID is deleted, the set is never broadened).
		if (line.beginsWith("city=")) {
			uint64 oid = ::strtoull(line.toCharArray() + 5, nullptr, 10);
			if (oid != 0) { cityOrder.add(oid); meta.put(oid, String("C|") + String::valueOf(oid) + "|city|0|0|0|0|"); }
			continue;
		}
		if (line.beginsWith("struct=")) {
			uint64 oid = ::strtoull(line.toCharArray() + 7, nullptr, 10);
			if (oid != 0) { structOrder.add(oid); meta.put(oid, String("S|") + String::valueOf(oid) + "|other|0|-1|0|0|<none>"); }
			continue;
		}
		if (line.beginsWith("orphan=")) {
			uint64 oid = ::strtoull(line.toCharArray() + 7, nullptr, 10);
			if (oid != 0 && !structOrder.contains(oid)) { structOrder.add(oid); meta.put(oid, String("O|") + String::valueOf(oid) + "|other|0|-1|0|0|<none>"); }
			continue;
		}

		if (line.length() < 4 || line.charAt(1) != '|') continue;

		const char kind = line.charAt(0);
		int firstBar = line.indexOf("|");
		int secondBar = line.indexOf("|", firstBar + 1);
		if (secondBar < 0) continue;
		uint64 oid = ::strtoull(line.subString(firstBar + 1, secondBar).toCharArray(), nullptr, 10);
		if (oid == 0) continue;

		meta.put(oid, line);

		if (kind == 'C') cityOrder.add(oid);
		else if (kind == 'S' || kind == 'O') structOrder.add(oid);
	}

	std::fclose(f);
	return true;
}

void WorldResetManager::progressMark(uint64 oid, const char* status) const {
	::mkdir("worldreset", 0755);
	std::FILE* f = std::fopen(progressFilePath(), "a");
	if (f == nullptr)
		return;
	std::fprintf(f, "%llu|%llu|%s\n", (unsigned long long)nowMs(), (unsigned long long)oid, status);
	std::fflush(f);
	std::fclose(f);
}

void WorldResetManager::loadProgressStatus(VectorMap<uint64, String>& out) const {
	out.removeAll();

	std::FILE* f = std::fopen(progressFilePath(), "r");
	if (f == nullptr)
		return;

	char buf[128];
	while (std::fgets(buf, sizeof(buf), f) != nullptr) {
		String line = String(buf).trim();
		int b1 = line.indexOf("|");
		int b2 = (b1 >= 0) ? line.indexOf("|", b1 + 1) : -1;
		if (b1 < 0 || b2 < 0) continue;
		uint64 oid = ::strtoull(line.subString(b1 + 1, b2).toCharArray(), nullptr, 10);
		String status = line.subString(b2 + 1);
		if (oid != 0)
			out.put(oid, status); // last line wins
	}
	std::fclose(f);
}

// ---------------------------------------------------------------------------
// non-destructive resume analysis
// ---------------------------------------------------------------------------

WorldResetManager::ResumeReport WorldResetManager::analyzeResume(ZoneServer* zoneServer) const {
	ResumeReport r;

	String note;
	r.phase = readStatePhase(note);

	Vector<uint64> cityOrder, structOrder;
	VectorMap<uint64, String> meta;
	r.haveManifest = readManifestV2(r.fingerprint, r.armedMs, r.executeMs, cityOrder, structOrder, meta);

	if (!r.haveManifest || zoneServer == nullptr)
		return r;

	VectorMap<uint64, String> prog;
	loadProgressStatus(prog);

	r.origCityTargets = cityOrder.size();
	r.origStructTargets = structOrder.size();

	// Any progress.log entry at all means a destructive phase began.
	for (int i = 0; i < prog.size(); ++i) {
		const String& st = prog.get(i);
		if (st == "REMOVED" || st == "IN_PROGRESS" || st == "FAILED" || st == "SKIPPED_VERIFIED") {
			r.destructiveWorkStarted = true;
			break;
		}
	}

	// Sessions still connected right now (lock-free snapshot).
	{
		PlayerManager* pm = zoneServer->getPlayerManager();
		if (pm != nullptr) {
			Vector<uint64> online = pm->getOnlinePlayerList();
			for (int i = 0; i < online.size(); ++i) {
				ManagedReference<SceneObject*> so = zoneServer->getObject(online.get(i));
				if (so != nullptr && so->isPlayerCreature())
					++r.connectedSessionsRemaining;
			}
		}
	}

	for (int i = 0; i < cityOrder.size(); ++i) {
		Reference<CityRegion*> c;
		try { c = Core::getObjectBroker()->lookUp(cityOrder.get(i)).castTo<CityRegion*>(); } catch (...) {}
		if (c == nullptr) ++r.citiesConfirmedGone; else ++r.citiesStillPresent;
	}

	for (int i = 0; i < structOrder.size(); ++i) {
		const uint64 oid = structOrder.get(i);
		const String pst = prog.get(oid); // "" if absent

		ManagedReference<SceneObject*> so;
		try { so = zoneServer->getObject(oid); } catch (...) {}

		if (so == nullptr) {
			if (pst == "REMOVED") ++r.confirmedRemoved;
			else ++r.completedByAbsence;
			continue;
		}

		if (pst == "FAILED") { ++r.failedRecorded; }

		ManagedReference<StructureObject*> s = so.castTo<StructureObject*>();
		if (s == nullptr) {
			// present but not a structure -> event perk (fine) OR genuine mismatch
			if (meta.get(oid).contains("|city|"))
				++r.identityMismatch;
			else
				++r.unreadable;
			continue;
		}

		// identity check against manifest
		String kind, category;
		uint32 xcrc = 0;
		int xgot = -1;
		uint64 xowner = 0;
		bool haveMeta = parseTargetMeta(meta.get(oid), kind, category, xcrc, xgot, xowner);

		const uint32 crc = s->getServerObjectCRC();
		const int got = (int)s->getGameObjectType();
		const uint64 owner = s->getOwnerObjectID();

		const bool identityOk = !haveMeta
			|| ((xcrc == 0 || xcrc == crc) && (xgot < 0 || xgot == got) && (xowner == 0 || xowner == owner));

		if (!identityOk) {
			++r.identityMismatch;
		} else if (pst == "IN_PROGRESS") {
			++r.inProgressAtCrash;
			++r.remaining; // still present -> re-run it (idempotent)
		} else {
			++r.remaining;
		}
	}

	// Also mark it if cities/structures are already gone but no progress.log exists
	// (e.g. a v1 interrupted run).
	if (r.confirmedRemoved + r.completedByAbsence + r.citiesConfirmedGone > 0)
		r.destructiveWorkStarted = true;

	const bool identityClean = (r.identityMismatch == 0 && r.unreadable == 0);

	if (r.phase == PHASE_PRECHECK || r.phase == PHASE_CLIENT_DRAIN) {
		// No destructive phase has run. Resumable iff the manifest is intact, every
		// original target is still present and unchanged, and nothing was removed.
		r.resumeEligible = r.haveManifest
			&& identityClean
			&& !r.destructiveWorkStarted
			&& r.citiesStillPresent == r.origCityTargets
			&& r.remaining == r.origStructTargets;
	} else {
		r.resumeEligible = r.haveManifest
			&& (r.phase == PHASE_CITIES || r.phase == PHASE_STRUCTURES || r.phase == PHASE_VALIDATION)
			&& identityClean;
	}

	return r;
}

// ---------------------------------------------------------------------------
// stall watchdog (logs only -- never force-unlocks, never kills threads)
// ---------------------------------------------------------------------------

void WorldResetManager::hbTouch(uint64 oid, const char* stage) {
	Locker g(&hbMutex);
	hbLastProgressMs = nowMs();
	hbCurrentOID = oid;
	hbCurrentStage = stage;
}

void WorldResetManager::hbBatch(int n) {
	Locker g(&hbMutex);
	hbBatchNo = n;
	hbLastProgressMs = nowMs();
}

void WorldResetManager::hbStop() {
	Locker g(&hbMutex);
	hbActive = false;
	hbCurrentOID = 0;
	hbCurrentStage = "";
}

void WorldResetManager::stallWatchdogTick() {
	uint64 last, startMs, cur;
	String stage;
	int batch;
	bool active;

	{
		Locker g(&hbMutex);
		active = hbActive;
		last = hbLastProgressMs;
		startMs = hbExecuteStartMs;
		cur = hbCurrentOID;
		stage = hbCurrentStage;
		batch = hbBatchNo;
	}

	if (!active)
		return; // reset finished / not running -> stop rescheduling

	const uint64 now = nowMs();
	const int stalledSecs = (last > 0 && now > last) ? (int)((now - last) / 1000) : 0;

	if (stalledSecs >= 30) {
		// Only log on 30s, then every further 30s, to avoid spam.
		Locker g(&hbMutex);
		if (stalledSecs - hbLastReportedStallSecs >= 30 || hbLastReportedStallSecs == 0) {
			hbLastReportedStallSecs = stalledSecs;
			g.release();
			error() << "[WORLDRESET][STALL] no progress for " << stalledSecs << "s"
				<< " currentOID=" << cur
				<< " currentStage=" << (stage.isEmpty() ? String("<none>") : stage)
				<< " batch=" << batch
				<< " elapsedSinceExecute=" << (startMs > 0 ? (int)((now - startMs) / 1000) : -1) << "s"
				<< " -- NOT auto-continuing; capture a gdb backtrace of the WorldReset worker";
		}
	} else {
		Locker g(&hbMutex);
		hbLastReportedStallSecs = 0;
	}

	// reschedule
	auto tm = Core::getTaskManager();
	if (tm != nullptr) {
		WorldResetManager* self = this;
		tm->scheduleTask([self]() { self->stallWatchdogTick(); }, "WorldResetStallWatchdog", 15000);
	}
}

void WorldResetManager::startStallWatchdog() {
	{
		Locker g(&hbMutex);
		hbActive = true;
		hbExecuteStartMs = nowMs();
		hbLastProgressMs = nowMs();
		hbLastReportedStallSecs = 0;
	}

	auto tm = Core::getTaskManager();
	if (tm != nullptr) {
		WorldResetManager* self = this;
		tm->scheduleTask([self]() { self->stallWatchdogTick(); }, "WorldResetStallWatchdog", 15000);
	}
}

// ---------------------------------------------------------------------------
// maintenance-safe structure destroyer -- NARROW LOCK SCOPES ONLY
// ---------------------------------------------------------------------------
//
// This deliberately does NOT use DestroyStructureTask (which assumes interactive
// gameplay: teleport messaging, client deltas, and -- critically -- holds the
// structure lock while blocking-acquiring the owner's player lock, with no
// cross-lock protocol). In a bulk admin wipe that ordering deadlocks against any
// normal path that goes player -> structure.
//
// Ordering here: (1) owner cleanup with ONLY the owner's ghost locked, then
// (2) world + database removal with ONLY the structure locked. The two locks are
// never held at the same time, so no AB/BA is possible in either direction.
// Requires: zero non-admin players online (enforced before PHASE1).
//
// Returns true if the structure record is gone (or was already gone).
// `failStage` is set on failure. `mgr` is used only for the stall heartbeat.
// expectedCrc/expectedGot/expectedOwner come from the manifest (0/-1/0 = "don't
// check"); a mismatch -> failStage="identity" -> caller fails closed.
static bool wrMaintenanceDestroyStructure(WorldResetManager* mgr, ZoneServer* zoneServer, uint64 oid,
		uint32 expectedCrc, int expectedGot, uint64 expectedOwner,
		String& failStage, String& infoOut) {
	failStage = "";
	infoOut = "";

	if (mgr != nullptr) mgr->hbTouch(oid, "resolve");
	ManagedReference<SceneObject*> so = zoneServer->getObject(oid);

	if (so == nullptr) {
		infoOut = "already gone";
		return true; // idempotent: target no longer exists
	}

	ManagedReference<StructureObject*> s = so.castTo<StructureObject*>();

	if (s == nullptr) {
		// Identity changed since the manifest was written -> fail closed.
		failStage = "identity";
		infoOut = String("OID now resolves to a non-structure (gameObjectType ") + String::valueOf(so->getGameObjectType()) + ")";
		return false;
	}

	// snapshot identity + a few fields under the structure lock, then release it
	uint64 ownerID = 0;
	uint64 waypointID = 0;
	uint32 crc = 0;
	int got = -1;
	String templateStr = "<none>";
	String typeStr;
	bool hasZone = false;

	{
		if (mgr != nullptr) mgr->hbTouch(oid, "lock");
		Locker sl(s);
		ownerID = s->getOwnerObjectID();
		waypointID = s->getWaypointID();
		crc = s->getServerObjectCRC();
		got = (int)s->getGameObjectType();
		if (s->getObjectTemplate() != nullptr)
			templateStr = s->getObjectTemplate()->getFullTemplateString();
		typeStr = describeStructureType(s);
		hasZone = (s->getZone() != nullptr);
	}

	infoOut = String("template=") + templateStr + " type=" + typeStr + " ownerID=" + String::valueOf(ownerID)
		+ (hasZone ? " zone=yes" : " zone=none");

	// ---- identity verification against the armed manifest (fail closed) ----
	if ((expectedCrc != 0 && expectedCrc != crc)
			|| (expectedGot >= 0 && expectedGot != got)
			|| (expectedOwner != 0 && expectedOwner != ownerID)) {
		failStage = "identity";
		infoOut = infoOut + String(" MISMATCH expected(crc=") + String::valueOf(expectedCrc)
			+ ",got=" + String::valueOf(expectedGot) + ",owner=" + String::valueOf(expectedOwner)
			+ ") actual(crc=" + String::valueOf(crc) + ",got=" + String::valueOf(got)
			+ ",owner=" + String::valueOf(ownerID) + ")";
		return false;
	}

	// ---- defensive: never tear down a building that still has a player creature
	// in one of its cells. BuildingObjectImplementation::destroyObjectFromDatabase
	// teleports player creatures out of cells WHILE the structure is locked -> a
	// structure->creature lock inversion that hung the previous test (the admin was
	// standing inside the target). All clients are disconnected before PHASE 1, so
	// this should always be empty; if it is not, skip the target instead of risking
	// the hang. ----
	if (mgr != nullptr) mgr->hbTouch(oid, "occupancy_check");
	{
		ManagedReference<BuildingObject*> b = so.castTo<BuildingObject*>();
		if (b != nullptr) {
			int occupants = 0;
			try {
				// cells are 1-indexed (see BuildingObject::getCell)
				for (uint32 ci = 1; ci <= b->getTotalCellNumber(); ++ci) {
					ManagedReference<CellObject*> cell = b->getCell(ci);
					if (cell == nullptr)
						continue;
					for (int oi = 0; oi < cell->getContainerObjectsSize(); ++oi) {
						ManagedReference<SceneObject*> child = cell->getContainerObject(oi);
						if (child != nullptr && child->isPlayerCreature())
							++occupants;
					}
				}
			} catch (...) {
				occupants = -1; // could not verify -> treat as occupied, fail closed
			}

			if (occupants != 0) {
				failStage = "occupied";
				infoOut = infoOut + String(" -- building still has ") + String::valueOf(occupants)
					+ " player creature(s) in its cells (or could not be verified); skipping to avoid a lock inversion";
				return false;
			}
		}
	}

	// ---- (1) owner cleanup -- GHOST lock only, never with the structure locked ----
	if (mgr != nullptr) mgr->hbTouch(oid, "owner_cleanup");
	try {
		if (ownerID != 0) {
			ManagedReference<SceneObject*> ownerObj = zoneServer->getObject(ownerID);

			if (ownerObj != nullptr) {
				ManagedReference<SceneObject*> ghostObj = ownerObj->getSlottedObject("ghost");

				if (ghostObj != nullptr && ghostObj->isPlayerObject()) {
					PlayerObject* g = cast<PlayerObject*>(ghostObj.get());

					if (g != nullptr) {
						Locker gl(g);
						g->removeOwnedStructure(s);          // drops from ownedStructures; clears declaredResidence if it matches
						if (waypointID != 0)
							g->removeWaypoint(waypointID, false, true); // no client delta; destroy the waypoint object
					}
				}
			}
		}
	} catch (const Exception& e) {
		failStage = "owner";
		infoOut = infoOut + " ownerCleanupError=" + e.getMessage();
		return false;
	} catch (...) {
		failStage = "owner";
		infoOut = infoOut + " ownerCleanupError=unknown";
		return false;
	}

	// ---- (2) world + database removal -- STRUCTURE lock only ----
	if (mgr != nullptr) mgr->hbTouch(oid, "world_remove");
	try {
		Locker sl(s);
		// destroyObjectFromWorld cancels the structure maintenance task, removes it
		// from the zone/close-objects, and (async, on its own lock) any nav area.
		s->destroyObjectFromWorld(true);
		if (mgr != nullptr) mgr->hbTouch(oid, "db_remove");
		// destroyObjectFromDatabase(true) recurses into children (cells, hoppers,
		// deed, vendors) each under its own lock -- none are player objects -- and
		// marks the record for deletion; Berkeley auto-maintains the secondary index.
		s->destroyObjectFromDatabase(true);
	} catch (const Exception& e) {
		failStage = "worlddb";
		infoOut = infoOut + " worldDbError=" + e.getMessage();
		return false;
	} catch (...) {
		failStage = "worlddb";
		infoOut = infoOut + " worldDbError=unknown";
		return false;
	}

	return true;
}

// ---------------------------------------------------------------------------
// task-queue drain + checkpoint helpers
// ---------------------------------------------------------------------------

void WorldResetManager::drainTaskQueues(const char* label, int maxSeconds) const {
	auto taskManager = Core::getTaskManager();

	if (taskManager == nullptr)
		return;

	// Best-effort: wait until the worker-queue backlog (which includes the
	// "slowQueue" that DestroyStructureTask uses) stops shrinking and holds low for
	// several consecutive samples. Always bounded by maxSeconds so a permanently
	// busy scheduler cannot wedge the reset.
	const uint64 startMs = nowMs();
	const uint64 deadline = startMs + (uint64)maxSeconds * 1000ULL;
	int lowStreak = 0;
	int lastExecuting = -1;

	while (nowMs() < deadline) {
		const int executing = taskManager->getExecutingTaskSize();

		const bool low = executing <= 2;
		const bool notGrowing = (lastExecuting < 0) || (executing <= lastExecuting);

		if (low && notGrowing) {
			if (++lowStreak >= 6) // ~3s of stable low backlog
				break;
		} else {
			lowStreak = 0;
		}

		lastExecuting = executing;
		Thread::sleep(500);
	}

	info(true) << "[WORLDRESET][DRAIN] " << label
		<< " scheduledBacklog=" << taskManager->getScheduledTaskSize()
		<< " workerQueueBacklog=" << taskManager->getExecutingTaskSize()
		<< " waited=" << (int)((nowMs() - startMs) / 1000) << "s";
}

void WorldResetManager::commitAndCheckpoint(const char* label) const {
	auto dbm = ObjectDatabaseManager::instance();

	if (dbm == nullptr)
		return;

	try {
		dbm->commitLocalTransaction();
		dbm->checkpoint();
		info(true) << "[WORLDRESET][CHECKPOINT] " << label << " committed + checkpointed";
	} catch (const Exception& e) {
		error() << "[WORLDRESET][CHECKPOINT] " << label << " failed: " << e.getMessage();
	} catch (...) {
		error() << "[WORLDRESET][CHECKPOINT] " << label << " failed with an unknown exception";
	}
}

// ---------------------------------------------------------------------------
// authenticate
// ---------------------------------------------------------------------------

void WorldResetManager::authenticate(CreatureObject* admin, const String& suppliedSecret) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	const String adminName = admin->getFirstName();

	Locker guard(&stateMutex);

	const uint64 t = nowMs();

	if (authThrottleUntilMs > t) {
		guard.release();
		admin->sendSystemMessage("[worldreset] Too many failed attempts. Try again later.");
		info(true) << "[WORLDRESET][AUTH] THROTTLED attempt by admin " << adminName << " (" << adminOID << ")";
		return;
	}

	const String secret = getConfiguredSecret();

	if (secret.length() == 0) {
		guard.release();
		admin->sendSystemMessage("[worldreset] The reset secret is not configured on this server (Core3.WorldResetSecret).");
		info(true) << "[WORLDRESET][AUTH] admin " << adminName << " (" << adminOID
			<< ") attempted authentication but Core3.WorldResetSecret is not configured";
		return;
	}

	const bool ok = constantTimeEquals(secret, suppliedSecret);

	if (!ok) {
		++authFailureCount;

		if (authFailureCount >= AUTH_MAX_FAILURES) {
			authThrottleUntilMs = t + AUTH_THROTTLE_MS;
			authFailureCount = 0;
		}

		clearAuthLocked();
		clearDryRunLocked();
		clearArmLocked();

		guard.release();
		admin->sendSystemMessage("[worldreset] Authentication failed.");
		// Never log the supplied value or the configured secret.
		info(true) << "[WORLDRESET][AUTH] FAILED for admin " << adminName << " (" << adminOID
			<< ") -- supplied secret rejected";
		return;
	}

	authFailureCount = 0;
	authThrottleUntilMs = 0;

	authAdminOID = adminOID;
	authExpireMs = t + AUTH_LIFETIME_MS;

	// A fresh authentication starts a fresh cycle.
	clearDryRunLocked();
	clearArmLocked();

	guard.release();
	admin->sendSystemMessage("[worldreset] Authenticated. This window is valid for 10 minutes. Next: /worldreset dryrun");
	info(true) << "[WORLDRESET][AUTH] SUCCESS admin " << adminName << " (" << adminOID << ") -- auth window 10 minutes";
}

// ---------------------------------------------------------------------------
// dry run
// ---------------------------------------------------------------------------

void WorldResetManager::runDryRun(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	const String adminName = admin->getFirstName();

	{
		Locker guard(&stateMutex);

		if (!isAuthenticatedLocked(adminOID)) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated (or window expired). Run /worldreset authenticate <secret> first.");
			info(true) << "[WORLDRESET][DRYRUN] refused -- admin " << adminName << " (" << adminOID << ") is not authenticated";
			return;
		}
	}

	ZoneServer* zoneServer = admin->getZoneServer();

	// An interrupted previous execute blocks everything until an admin clears it.
	{
		String note;
		ResetPhase prev = readStatePhase(note);

		if (prev != PHASE_IDLE && prev != PHASE_COMPLETE) {
			admin->sendSystemMessage(String("[worldreset] BLOCKED -- a previous reset did not finish (state=")
				+ phaseName(prev) + "). Review the [WORLDRESET] log, then run /worldreset clearstate.");
			info(true) << "[WORLDRESET][DRYRUN] refused -- previous reset incomplete (state=" << phaseName(prev) << " note=" << note << ")";
			return;
		}
	}

	info(true) << "[WORLDRESET][DRYRUN] start -- requested by admin " << adminName << " (" << adminOID
		<< ") adminLevel=" << (admin->getPlayerObject() != nullptr ? (int)admin->getPlayerObject()->getAdminLevel() : -1);

	DryRunCounts counts;
	SortedVector<uint64> cityOIDs, structOIDs, orphanOIDs;
	collectSnapshot(zoneServer, admin, counts, true, cityOIDs, structOIDs, orphanOIDs);

	Vector<String> blockReasons;
	const bool safe = evaluateSafety(counts, blockReasons);

	{
		Locker guard(&stateMutex);

		if (!isAuthenticatedLocked(adminOID)) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Authentication expired during the dry run. Re-authenticate and try again.");
			return;
		}

		lastCounts = counts;
		lastFingerprint = counts.fingerprint;
		snapshotCityOIDs = cityOIDs;
		snapshotStructureOIDs = structOIDs;
		snapshotOrphanOIDs = orphanOIDs;
		dryRunComplete = true;
		dryRunAdminOID = adminOID;
		dryRunTimeMs = nowMs();
		dryRunSafe = safe;

		// A new dry run invalidates any previous armed state.
		clearArmLocked();
	}

	info(true) << "[WORLDRESET][DRYRUN] complete -- playerCities=" << counts.playerCities
		<< " cityHalls=" << counts.cityHalls
		<< " civicStructures=" << counts.civicStructures
		<< " deployedHouses=" << counts.deployedHouses
		<< " installations=" << counts.installations
		<< " factories=" << counts.factories
		<< " harvesters=" << counts.harvesters
		<< " generators=" << counts.generators
		<< " otherDeployed=" << counts.otherDeployedStructures
		<< " potentialVendors=" << counts.potentialVendors
		<< " structuresWithUnpackedContents=" << counts.structuresWithUnpackedContents
		<< " orphanStructures=" << counts.orphanStructures
		<< " unreadableStructureRecords=" << counts.unreadableStructureRecords
		<< " nonStructureRecordsExcluded=" << counts.nonStructureRecordsExcluded
		<< " unreadableCityRecords=" << counts.unreadableCityRecords
		<< " packedDeedsExcluded=" << counts.packedDeedsExcluded
		<< " packedPendingRedeem=" << counts.packedPendingRedeem
		<< " orphanPackPayloadFiles=" << counts.orphanPackPayloadFiles
		<< " staticCitiesExcluded=" << counts.staticCitiesExcluded
		<< " gcwBasesExcluded=" << counts.gcwBasesExcluded
		<< " unclassifiedLiveObjects=" << counts.unclassifiedLiveObjects
		<< " dbReadErrors=" << counts.dbReadErrors
		<< " fingerprint=" << counts.fingerprint
		<< " => SAFE=" << (safe ? "YES" : "NO");

	for (int i = 0; i < blockReasons.size(); ++i)
		info(true) << "[WORLDRESET][DRYRUN] BLOCKED: " << blockReasons.get(i);

	StringBuffer msg;
	msg << "[worldreset] Dry run complete (NO changes were made).\n"
		<< "  Player cities: " << counts.playerCities << "  (city halls: " << counts.cityHalls
		<< ", civic structures: " << counts.civicStructures << ", citizens: " << counts.cityCitizens << ")\n"
		<< "  Deployed houses: " << counts.deployedHouses << "\n"
		<< "  Installations: " << counts.installations << "  (factories: " << counts.factories
		<< ", harvesters: " << counts.harvesters << ", generators: " << counts.generators << ")\n"
		<< "  Other deployed structures: " << counts.otherDeployedStructures << "\n"
		<< "  Potential vendors in affected structures: " << counts.potentialVendors << "\n"
		<< "  Orphaned / zoneless structure records (eligible for removal): " << counts.orphanStructures << "\n"
		<< "  Unreadable structure records (cannot load -> BLOCK): " << counts.unreadableStructureRecords << "\n"
		<< "  EXCLUDED non-structure records (event perks / flags / NPC actor perks): " << counts.nonStructureRecordsExcluded << "\n"
		<< "  Unreadable city records: " << counts.unreadableCityRecords << "\n"
		<< "  Database read errors: " << counts.dbReadErrors << "\n"
		<< "  EXCLUDED packed houses (deed form): " << counts.packedDeedsExcluded << "\n"
		<< "  EXCLUDED static / NPC city regions: " << counts.staticCitiesExcluded << "\n"
		<< "  EXCLUDED GCW / faction bases: " << counts.gcwBasesExcluded << "\n"
		<< "  Packed-pending-redeem buildings: " << counts.packedPendingRedeem << "\n"
		<< "  Unclassifiable live objects: " << counts.unclassifiedLiveObjects << "\n"
		<< "  Orphan pack payload files (b-*.bin, informational): " << counts.orphanPackPayloadFiles << "\n"
		<< "  Fingerprint: " << counts.fingerprint << "\n";

	if (counts.structuresWithUnpackedContents > 0) {
		msg << "\n  *** WARNING: " << counts.structuresWithUnpackedContents
			<< " deployed structure(s) still contain unpacked objects.\n"
			<< "  Those contents WILL BE DESTROYED if reset execution proceeds. ***\n";
	}

	msg << "\n  RESULT: " << (safe ? "SAFE TO ARM" : "UNSAFE - EXECUTION BLOCKED");

	if (!safe) {
		for (int i = 0; i < blockReasons.size(); ++i)
			msg << "\n    - " << blockReasons.get(i);

		if (counts.unreadableStructureRecords > 0)
			msg << "\n  Run /worldreset diagnose for a per-category breakdown of the unreadable records.";
	}

	admin->sendSystemMessage(msg.toString());
}

// ---------------------------------------------------------------------------
// status
// ---------------------------------------------------------------------------

void WorldResetManager::showStatus(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	PlayerObject* ghost = admin->getPlayerObject();
	const int adminLevel = (ghost != nullptr) ? (int)ghost->getAdminLevel() : -1;

	Locker guard(&stateMutex);

	const uint64 t = nowMs();
	const bool authed = isAuthenticatedLocked(adminOID);
	const int authRemain = (authed && authExpireMs > t) ? (int)((authExpireMs - t) / 1000) : 0;
	const bool isArmed = armed && armAdminOID == adminOID && t < armExpireMs;
	const int armRemain = (isArmed && armExpireMs > t) ? (int)((armExpireMs - t) / 1000) : 0;

	DryRunCounts c = lastCounts;
	const bool drComplete = dryRunComplete;
	const bool drSafe = dryRunSafe;
	const bool drMine = (dryRunAdminOID == adminOID);
	const int drAgeSec = drComplete ? (int)((t - dryRunTimeMs) / 1000) : 0;
	const bool secretConfigured = isSecretConfigured();
	const String fp = lastFingerprint;

	guard.release();

	String stateNote;
	const ResetPhase statePhase = readStatePhase(stateNote);
	const bool prevIncomplete = (statePhase != PHASE_IDLE && statePhase != PHASE_COMPLETE);

	StringBuffer msg;
	msg << "===== /worldreset status =====\n";

	if (prevIncomplete) {
		msg << "*** PREVIOUS RESET INCOMPLETE -- state=" << phaseName(statePhase)
			<< (stateNote.isEmpty() ? String("") : (String(" (") + stateNote + ")"))
			<< " ***\n*** dryrun/arm/execute are BLOCKED. ***\n";

		ResumeReport r = analyzeResume(admin->getZoneServer());
		if (r.haveManifest) {
			msg << "  Reset state: " << phaseName(statePhase) << "\n"
				<< "  Destructive work started: " << (r.destructiveWorkStarted ? "YES" : "NO") << "\n"
				<< "  Connected sessions remaining: " << r.connectedSessionsRemaining << "\n"
				<< "  Original Phase 3 targets: " << r.origStructTargets << "\n"
				<< "  Completed: " << (r.confirmedRemoved + r.completedByAbsence) << "\n"
				<< "  Remaining: " << r.remaining << "\n"
				<< "  Failed/mismatched: " << (r.failedRecorded + r.identityMismatch + r.unreadable) << "\n"
				<< "  In-progress at crash: " << r.inProgressAtCrash << "\n"
				<< "  Resume eligible: " << (r.resumeEligible ? "YES" : "NO") << "\n"
				<< (r.resumeEligible
					? "  -> /worldreset recoverycheck  then  /worldreset resume RESET-HOUSING-AND-CITIES\n"
					: "  -> /worldreset recoverycheck  (resume blocked -- see report)\n");
		} else {
			msg << "  (no target manifest -- run /worldreset recoverycheck for the world count; resume not possible)\n";
		}
		msg << "\n";
	} else if (statePhase == PHASE_COMPLETE) {
		msg << "Last completed reset: state=COMPLETE"
			<< (stateNote.isEmpty() ? String("") : (String(" (") + stateNote + ")")) << "\n\n";
	}

	msg << "Admin Level: " << adminLevel << "  (required: >= 15)\n"
		<< "Reset secret configured: " << (secretConfigured ? "YES" : "NO") << "\n"
		<< "Authenticated: " << (authed ? "YES" : "NO");

	if (authed)
		msg << "  (expires in " << authRemain << "s)";

	msg << "\nDry run complete: " << (drComplete ? "YES" : "NO");

	if (drComplete)
		msg << (drMine ? "  (this admin, " : "  (another admin, ") << drAgeSec << "s ago)";

	msg << "\nDry run safe: " << (drComplete ? (drSafe ? "YES" : "NO") : "-") << "\n"
		<< "Armed: " << (isArmed ? "YES" : "NO");

	if (isArmed)
		msg << "  (expires in " << armRemain << "s)";

	msg << "\n\nLast dry-run counts:\n"
		<< "  Player Cities: " << c.playerCities << "\n"
		<< "  City Halls: " << c.cityHalls << "\n"
		<< "  Civic Structures: " << c.civicStructures << "\n"
		<< "  City Citizens (membership rows): " << c.cityCitizens << "\n"
		<< "  Deployed Houses: " << c.deployedHouses << "\n"
		<< "  Installations: " << c.installations << "\n"
		<< "  Factories: " << c.factories << "\n"
		<< "  Harvesters: " << c.harvesters << "\n"
		<< "  Generators: " << c.generators << "\n"
		<< "  Other Deployed Structures: " << c.otherDeployedStructures << "\n"
		<< "  Potential Vendors: " << c.potentialVendors << "\n"
		<< "  Structures With Unpacked Contents: " << c.structuresWithUnpackedContents << "\n"
		<< "  Packed Structures Excluded (deed form): " << c.packedDeedsExcluded << "\n"
		<< "  Static / NPC Cities Excluded: " << c.staticCitiesExcluded << "\n"
		<< "  GCW / Faction Bases Excluded: " << c.gcwBasesExcluded << "\n"
		<< "  Orphaned / Zoneless Structures: " << c.orphanStructures << "\n"
		<< "  Unreadable Structure Records (BLOCK): " << c.unreadableStructureRecords << "\n"
		<< "  Excluded Non-Structure Records (event perks etc.): " << c.nonStructureRecordsExcluded << "\n"
		<< "  Unreadable City Records: " << c.unreadableCityRecords << "\n"
		<< "  Orphan Pack Payload Files (b-*.bin): " << c.orphanPackPayloadFiles << "\n"
		<< "  Packed-Pending-Redeem Buildings: " << c.packedPendingRedeem << "\n"
		<< "  Unclassifiable Live Objects: " << c.unclassifiedLiveObjects << "\n"
		<< "  Database Read Errors: " << c.dbReadErrors << "\n"
		<< "  Snapshot fingerprint: " << (fp.isEmpty() ? String("<none>") : fp);

	admin->sendSystemMessage(msg.toString());
}

// ---------------------------------------------------------------------------
// clearState -- clear a stuck "PREVIOUS RESET INCOMPLETE" marker
// ---------------------------------------------------------------------------

void WorldResetManager::clearState(CreatureObject* admin, const String& arg) {
	if (admin == nullptr)
		return;

	{
		Locker guard(&stateMutex);
		if (!isAuthenticatedLocked(admin->getObjectID())) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated. Run /worldreset authenticate <secret> first.");
			return;
		}
	}

	String note;
	const ResetPhase prev = readStatePhase(note);

	// If a committed reset is sitting in STRUCTURE_PHASE with a manifest + progress,
	// clearing it would make a half-reset galaxy look fresh. Block it unless the
	// admin passes the explicit forensic override token.
	ResumeReport r = analyzeResume(admin->getZoneServer());
	// A PRECHECK / CLIENT_DRAIN interruption with no removals is NOT a committed
	// reset -- clearstate is allowed there without the override (though resume is
	// the better path). Only block when destructive work actually happened.
	const bool committedResetExists = r.haveManifest && r.destructiveWorkStarted;

	if (committedResetExists && arg.toLowerCase() != "force-discard-committed-reset") {
		StringBuffer m;
		m << "[worldreset] clearstate REFUSED -- a partially completed reset has ALREADY committed destructive work:\n"
			<< "    state=" << phaseName(prev) << "  fingerprint=" << r.fingerprint << "\n"
			<< "    cities removed: " << r.citiesConfirmedGone << " / " << r.origCityTargets << "\n"
			<< "    structures removed: " << (r.confirmedRemoved + r.completedByAbsence) << " / " << r.origStructTargets
			<< "   (remaining: " << r.remaining << ")\n"
			<< "  Clearing now would make a half-reset galaxy look untouched and DISCARD the target manifest/progress.\n"
			<< "  Correct options:\n"
			<< "    - /worldreset recoverycheck   (inspect)\n"
			<< "    - /worldreset resume RESET-HOUSING-AND-CITIES   (finish it)\n"
			<< "    - restore your pre-execute database backup\n"
			<< "  Only if you have already restored a backup / accept the inconsistency:\n"
			<< "    /worldreset clearstate force-discard-committed-reset";
		admin->sendSystemMessage(m.toString());
		error() << "[WORLDRESET][STATE] clearstate REFUSED for admin " << admin->getFirstName()
			<< " -- committed reset exists (state=" << phaseName(prev) << ")";
		return;
	}

	// Keep the manifest/progress as forensic evidence -- rename, don't delete.
	if (r.haveManifest) {
		std::rename(manifestFilePath(), "worldreset/manifest.cleared.txt");
		std::rename(progressFilePath(), "worldreset/progress.cleared.log");
	}

	writeStatePhase(PHASE_IDLE, String("cleared by admin ") + admin->getFirstName()
		+ " (" + String::valueOf(admin->getObjectID()) + "); previous=" + phaseName(prev)
		+ (committedResetExists ? "; FORCED over committed reset" : ""));

	{
		Locker guard(&stateMutex);
		clearArmLocked();
		clearDryRunLocked();
	}

	admin->sendSystemMessage(String("[worldreset] Execution-state marker cleared (was ") + phaseName(prev)
		+ (committedResetExists ? "; FORCED over a committed reset -- manifest/progress moved to *.cleared.*)" : ").")
		+ " Run /worldreset dryrun to start fresh.");
	info(true) << "[WORLDRESET][STATE] marker cleared by admin " << admin->getFirstName()
		<< " (" << admin->getObjectID() << ") -- previous=" << phaseName(prev)
		<< (committedResetExists ? " [FORCED over committed reset]" : "");
}

// ---------------------------------------------------------------------------
// diagnose -- non-destructive deep classification of playerstructures.db
// ---------------------------------------------------------------------------

static void wrBump(VectorMap<String, int>& buckets, const String& key) {
	buckets.put(key, buckets.get(key) + 1);
}

void WorldResetManager::diagnose(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();

	{
		Locker guard(&stateMutex);
		if (!isAuthenticatedLocked(adminOID)) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated. Run /worldreset authenticate <secret> first.");
			return;
		}
	}

	ZoneServer* zoneServer = admin->getZoneServer();

	if (zoneServer == nullptr) {
		admin->sendSystemMessage("[worldreset] No zone server.");
		return;
	}

	auto objectDBManager = ObjectDatabaseManager::instance();

	ObjectDatabase* structureDB = nullptr;
	uint16 psTableID = 0;

	try {
		structureDB = objectDBManager->loadObjectDatabase("playerstructures", true);
		psTableID = objectDBManager->getDatabaseID("playerstructures");
	} catch (...) {
		structureDB = nullptr;
	}

	if (structureDB == nullptr) {
		admin->sendSystemMessage("[worldreset] Could not open playerstructures.db.");
		return;
	}

	// Authoritative secondary index (the same one StructureManager uses at startup
	// to decide which structures to load per zone). Read-only.
	IndexDatabase* indexDB = nullptr;
	try {
		indexDB = StructureManager::instance()->createSubIndex();
	} catch (...) {
		indexDB = nullptr;
	}

	info(true) << "[WORLDRESET][DIAGNOSE] START -- requested by admin " << admin->getFirstName() << " (" << adminOID << ")";

	// collect keys first, close the cursor, then inspect
	Vector<uint64> keys;
	try {
		ObjectDatabaseIterator it(structureDB);
		ObjectInputStream tmp(500);
		uint64 k = 0;
		while (it.getNextKeyAndValue(k, &tmp)) {
			keys.add(k);
			tmp.reset();
		}
	} catch (const Exception& e) {
		admin->sendSystemMessage(String("[worldreset] diagnose: failed to read playerstructures.db keys: ") + e.getMessage());
		return;
	}

	int total = keys.size();
	int cStructureOk = 0;
	int cNonStructLoaded = 0;
	int cMissingTemplate = 0;
	int cDeserializeFail = 0;
	int cNoRawValue = 0;
	int cIndexMismatch = 0;
	int cWrongDbTable = 0;
	int cOther = 0;

	VectorMap<String, int> missingTemplateByCrc;
	VectorMap<String, int> deserializeFailByClass;
	VectorMap<String, int> nonStructByTemplate;
	missingTemplateByCrc.setNullValue(0);
	deserializeFailByClass.setNullValue(0);
	nonStructByTemplate.setNullValue(0);

	berkeley::CursorConfig cfg;
	cfg.setReadUncommitted(true);

	for (int i = 0; i < keys.size(); ++i) {
		const uint64 oid = keys.get(i);

		String rawClassName, rawZone;
		uint32 rawCRC = 0;
		uint64 rawOwner = 0, rawParent = 0;
		bool rawExists = false;

		try {
			ObjectInputStream raw(1000);
			if (!structureDB->getData(oid, &raw)) {
				rawExists = true;
				Serializable::getVariable<String>(STRING_HASHCODE("_className"), &rawClassName, &raw);
				Serializable::getVariable<uint32>(STRING_HASHCODE("SceneObject.serverObjectCRC"), &rawCRC, &raw);
				Serializable::getVariable<uint64>(STRING_HASHCODE("StructureObject.ownerObjectID"), &rawOwner, &raw);
				Serializable::getVariable<uint64>(STRING_HASHCODE("SceneObject.parentID"), &rawParent, &raw);
				Serializable::getVariable<String>(STRING_HASHCODE("SceneObject.zone"), &rawZone, &raw);
			}
		} catch (...) {
			// leave defaults
		}

		const uint16 oidTable = (uint16)(oid >> 48);
		const bool wrongTable = (psTableID != 0 && oidTable != psTableID);

		String rawTemplate = "<unresolved>";
		int gameObjectType = -1;
		Reference<SharedObjectTemplate*> tmpl;
		if (rawCRC != 0)
			tmpl = TemplateManager::instance()->getTemplate(rawCRC);
		if (tmpl != nullptr) {
			rawTemplate = tmpl->getFullTemplateString();
			gameObjectType = (int)tmpl->getGameObjectType();
		}

		// index membership: only records with a non-empty zone are indexed
		const bool hasZone = !rawZone.isEmpty();
		bool indexed = false;

		if (indexDB != nullptr && hasZone) {
			try {
				IndexDatabaseIterator idxIt(indexDB, cfg);
				uint64 zoneHash = rawZone.hashCode();
				uint64 v = 0;
				if (idxIt.setKeyAndGetValue(zoneHash, v, nullptr)) {
					if (v == oid)
						indexed = true;
					else {
						while (idxIt.getNextKeyAndValue(zoneHash, v, nullptr)) {
							if (v == oid) { indexed = true; break; }
						}
					}
				}
			} catch (...) {
				// leave indexed = false
			}
		}

		// try the same load path the reset uses
		ManagedReference<SceneObject*> so;
		bool loadThrew = false;
		try {
			so = zoneServer->getObject(oid);
		} catch (...) {
			loadThrew = true;
		}

		String category;

		if (wrongTable) {
			++cWrongDbTable;
			category = "WRONG_DB_TABLE";
		} else if (so != nullptr && so.castTo<StructureObject*>() != nullptr) {
			++cStructureOk;
			category = "STRUCTURE_OK";
		} else if (so != nullptr) {
			++cNonStructLoaded;
			category = "NONSTRUCT_LOADED";
			wrBump(nonStructByTemplate, so->getObjectTemplate() != nullptr
				? so->getObjectTemplate()->getFullTemplateString() : rawTemplate);
		} else if (!rawExists) {
			++cNoRawValue;
			category = "LOAD_FAIL_NO_RAW_VALUE";
		} else if (rawCRC != 0 && tmpl == nullptr) {
			++cMissingTemplate;
			category = "LOAD_FAIL_MISSING_TEMPLATE";
			wrBump(missingTemplateByCrc, String("0x") + String::hexvalueOf((int)rawCRC));
		} else if (loadThrew || rawExists) {
			++cDeserializeFail;
			category = "LOAD_FAIL_DESERIALIZE";
			wrBump(deserializeFailByClass, rawClassName.isEmpty() ? String("<no className>") : rawClassName);
		} else {
			++cOther;
			category = "OTHER";
		}

		if (hasZone && !indexed && category != "STRUCTURE_OK" && category != "NONSTRUCT_LOADED")
			++cIndexMismatch;

		const bool resemblesHouse = classNameIsPlayerStructure(rawClassName) || (rawTemplate.contains("/building/player/"));
		const bool resemblesInstallation = rawTemplate.contains("/installation/");
		const bool resemblesCivic = rawTemplate.contains("/building/player/city/") || rawTemplate.contains("cityhall") || rawTemplate.contains("civic");
		const bool resemblesEventPerk = rawTemplate.contains("event_perk") || rawTemplate.contains("eventperk");

		warning() << "[WORLDRESET][DIAGNOSE] OID=" << oid
			<< " table=" << oidTable << (wrongTable ? "(WRONG,expected " + String::valueOf((int)psTableID) + ")" : String(""))
			<< " category=" << category
			<< " rawRecord=" << (rawExists ? "present" : "ABSENT")
			<< " className=\"" << (rawClassName.isEmpty() ? String("<none>") : rawClassName) << "\""
			<< " crc=0x" << String::hexvalueOf((int)rawCRC)
			<< " template=" << rawTemplate
			<< " gameObjectType=" << gameObjectType
			<< " owner=" << rawOwner
			<< " parentID=" << rawParent
			<< " zone=\"" << (rawZone.isEmpty() ? String("<none>") : rawZone) << "\""
			<< " indexed=" << (indexed ? "yes" : "no") << " expectedIndexed=" << (hasZone ? "yes" : "no")
			<< " loaded=" << (so != nullptr ? "yes" : "no")
			<< " resembles:" << (resemblesHouse ? " house" : "") << (resemblesInstallation ? " installation" : "")
			<< (resemblesCivic ? " civic" : "") << (resemblesEventPerk ? " event-perk" : "");
	}

	// ---- grouped log (VectorMap keeps keys sorted; counts are small) ----
	auto logBuckets = [this](const char* title, const VectorMap<String, int>& b) {
		for (int i = 0; i < b.size(); ++i) {
			const VectorMapEntry<String, int>& e = b.elementAt((uint32) i);
			info(true) << "[WORLDRESET][DIAGNOSE] " << title << "  " << e.getKey() << " x" << e.getValue();
		}
	};

	logBuckets("MISSING_TEMPLATE by CRC:", missingTemplateByCrc);
	logBuckets("DESERIALIZE_FAIL by className:", deserializeFailByClass);
	logBuckets("NONSTRUCT_LOADED by template:", nonStructByTemplate);

	info(true) << "[WORLDRESET][DIAGNOSE] COMPLETE -- total=" << total
		<< " structureOk=" << cStructureOk
		<< " nonStructLoaded=" << cNonStructLoaded
		<< " missingTemplate=" << cMissingTemplate
		<< " deserializeFail=" << cDeserializeFail
		<< " noRawValue=" << cNoRawValue
		<< " indexMismatch=" << cIndexMismatch
		<< " wrongDbTable=" << cWrongDbTable
		<< " other=" << cOther;

	StringBuffer m;
	m << "[worldreset] playerstructures.db diagnostic (NO changes made)\n"
		<< "  Total primary records: " << total << "\n"
		<< "  Load as StructureObject (in scope): " << cStructureOk << "\n"
		<< "  Load as NON-structure (event perks / flags / NPC actor perks -- EXCLUDED): " << cNonStructLoaded << "\n"
		<< "  Unresolved records: " << (cMissingTemplate + cDeserializeFail + cNoRawValue + cWrongDbTable + cOther) << "\n"
		<< "  Reason breakdown:\n"
		<< "    Missing template (.iff CRC not loadable): " << cMissingTemplate << "\n"
		<< "    Object load / unsupported serialization: " << cDeserializeFail << "\n"
		<< "    Missing raw record value: " << cNoRawValue << "\n"
		<< "    Wrong DB table id on OID: " << cWrongDbTable << "\n"
		<< "    Other: " << cOther << "\n"
		<< "  Registry/index mismatch (has zone, not in index): " << cIndexMismatch << "\n"
		<< "  Per-record detail + top groups written to the server log ([WORLDRESET][DIAGNOSE]).";

	admin->sendSystemMessage(m.toString());
}

// ---------------------------------------------------------------------------
// recovery -- read-only report on an interrupted reset (changes NOTHING)
// ---------------------------------------------------------------------------

void WorldResetManager::recovery(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	{
		Locker guard(&stateMutex);
		if (!isAuthenticatedLocked(admin->getObjectID())) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated. Run /worldreset authenticate <secret> first.");
			return;
		}
	}

	ZoneServer* zoneServer = admin->getZoneServer();
	if (zoneServer == nullptr) {
		admin->sendSystemMessage("[worldreset] No zone server.");
		return;
	}

	String note;
	const ResetPhase phase = readStatePhase(note);

	info(true) << "[WORLDRESET][RECOVERYCHECK] START -- state=" << phaseName(phase);

	if (phase == PHASE_IDLE || phase == PHASE_COMPLETE) {
		admin->sendSystemMessage(String("[worldreset] No interrupted reset (state=") + phaseName(phase) + "). Nothing to recover.");
		return;
	}

	ResumeReport r = analyzeResume(zoneServer);

	if (!r.haveManifest) {
		// No manifest (e.g. an interrupted run from an older build). Fall back to a
		// plain read-only world count so the operator still knows the damage.
		DryRunCounts c;
		SortedVector<uint64> a, b, d;
		collectSnapshot(zoneServer, admin, c, false, a, b, d);

		info(true) << "[WORLDRESET][RECOVERYCHECK] no manifest -- world count: playerCities=" << c.playerCities
			<< " deployedStructures=" << (c.deployedHouses + c.installations + c.factories + c.harvesters
				+ c.generators + c.otherDeployedStructures)
			<< " orphanStructures=" << c.orphanStructures
			<< " nonStructureRecords=" << c.nonStructureRecordsExcluded
			<< " unreadableStructureRecords=" << c.unreadableStructureRecords;

		StringBuffer mm;
		mm << "[worldreset] RECOVERYCHECK -- state=" << phaseName(phase) << ", NO target manifest (older build?).\n"
			<< "  Current world count (read-only):\n"
			<< "    Player cities still present: " << c.playerCities << "\n"
			<< "    Deployed player structures still present: "
			<< (c.deployedHouses + c.installations + c.factories + c.harvesters + c.generators + c.otherDeployedStructures) << "\n"
			<< "    Orphan/zoneless structure records: " << c.orphanStructures << "\n"
			<< "    Non-structure records (event perks etc., preserved): " << c.nonStructureRecordsExcluded << "\n"
			<< "    Unreadable structure records: " << c.unreadableStructureRecords << "\n"
			<< "  Safe to resume: NO (no manifest -- cannot prove the original target set).\n"
			<< "  Options: restore from your pre-execute backup, OR /worldreset clearstate then a fresh\n"
			<< "  /worldreset dryrun + execute (the new run writes a manifest and uses the safe path).";
		admin->sendSystemMessage(mm.toString());
		return;
	}

	info(true) << "[WORLDRESET][RECOVERYCHECK] COMPLETE -- state=" << phaseName(phase)
		<< " origCities=" << r.origCityTargets << " citiesGone=" << r.citiesConfirmedGone << " citiesPresent=" << r.citiesStillPresent
		<< " origStructTargets=" << r.origStructTargets
		<< " confirmedRemoved=" << r.confirmedRemoved
		<< " completedByAbsence=" << r.completedByAbsence
		<< " remaining=" << r.remaining
		<< " inProgressAtCrash=" << r.inProgressAtCrash
		<< " failedRecorded=" << r.failedRecorded
		<< " identityMismatch=" << r.identityMismatch
		<< " unreadable=" << r.unreadable
		<< " resumeEligible=" << (r.resumeEligible ? "YES" : "NO");

	const bool preDestructive = (phase == PHASE_PRECHECK || phase == PHASE_CLIENT_DRAIN);

	StringBuffer m;
	m << "[worldreset] RECOVERYCHECK (NO changes made)\n"
		<< "  Reset state: " << phaseName(phase) << (note.isEmpty() ? String("") : (String(" (") + note + ")")) << "\n"
		<< "  Manifest fingerprint: " << r.fingerprint << "\n"
		<< "  Destructive work started: " << (r.destructiveWorkStarted ? "YES" : "NO") << "\n"
		<< "  Connected sessions remaining: " << r.connectedSessionsRemaining << "\n"
		<< "  --- Cities ---\n"
		<< "    Original targets: " << r.origCityTargets << "\n"
		<< "    Confirmed removed: " << r.citiesConfirmedGone << "\n"
		<< "    Still present: " << r.citiesStillPresent << "\n"
		<< "  --- Phase 3 structures (deployed + orphan) ---\n"
		<< "    Original Phase 3 targets: " << r.origStructTargets << "\n"
		<< "    Confirmed removed: " << (r.confirmedRemoved + r.completedByAbsence) << "\n"
		<< "    Remaining (identity-verified, resumable): " << r.remaining << "\n"
		<< "    In-progress at crash (still present): " << r.inProgressAtCrash << "\n"
		<< "    Failed (recorded): " << r.failedRecorded << "\n"
		<< "    Identity mismatches: " << r.identityMismatch << "\n"
		<< "    Unreadable / missing progress: " << r.unreadable << "\n"
		<< "    Newly created structures: EXCLUDED (never added to a resume target set)\n"
		<< "  ---\n"
		<< "  Safe to resume: " << (r.resumeEligible ? "YES" : "NO") << "\n";

	if (r.resumeEligible && preDestructive)
		m << "  -> Safe to retry client drain: YES. No cities/structures were touched.\n"
		  << "  -> /worldreset authenticate <secret>  then  /worldreset resume RESET-HOUSING-AND-CITIES\n"
		  << "     (galaxy must be LOCKED; the resume kicks any remaining clients itself). clearstate is NOT needed.";
	else if (r.resumeEligible)
		m << "  -> /worldreset resume RESET-HOUSING-AND-CITIES  (galaxy LOCKED, no other players, re-authenticate first).";
	else if (r.identityMismatch > 0 || r.unreadable > 0)
		m << "  -> BLOCKED: " << (r.identityMismatch + r.unreadable) << " target(s) changed identity / cannot be verified. Restore from backup or investigate.";
	else if (preDestructive && r.destructiveWorkStarted)
		m << "  -> BLOCKED: state is pre-destructive but progress shows removals. Investigate the log before anything else.";
	else
		m << "  -> State is " << phaseName(phase) << "; resume is offered from PRECHECK / CLIENT_DRAIN / CITY_PHASE / STRUCTURE_PHASE / VALIDATION_PHASE only.";

	admin->sendSystemMessage(m.toString());
}

// ---------------------------------------------------------------------------
// resume -- continue an interrupted STRUCTURE_PHASE reset from its manifest
// ---------------------------------------------------------------------------

void WorldResetManager::resume(CreatureObject* admin, const String& confirmationPhrase) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	ZoneServer* zoneServer = admin->getZoneServer();

	{
		Locker guard(&stateMutex);

		if (executionInProgress) {
			guard.release();
			admin->sendSystemMessage("[worldreset] A reset task is already running.");
			return;
		}

		if (!isAuthenticatedLocked(adminOID)) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated. Run /worldreset authenticate <secret> first.");
			return;
		}
	}

	if (confirmationPhrase != EXECUTE_PHRASE) {
		admin->sendSystemMessage("[worldreset] Confirmation phrase required: /worldreset resume RESET-HOUSING-AND-CITIES");
		return;
	}

	String note;
	const ResetPhase phase = readStatePhase(note);

	const bool preDestructivePhase = (phase == PHASE_PRECHECK || phase == PHASE_CLIENT_DRAIN);
	const bool destructivePhase = (phase == PHASE_CITIES || phase == PHASE_STRUCTURES || phase == PHASE_VALIDATION);

	if (!preDestructivePhase && !destructivePhase) {
		admin->sendSystemMessage(String("[worldreset] Resume refused -- persisted state is ") + phaseName(phase)
			+ ", not PRECHECK / CLIENT_DRAIN / CITY_PHASE / STRUCTURE_PHASE / VALIDATION_PHASE. Run /worldreset recoverycheck and investigate the log.");
		info(true) << "[WORLDRESET][RESUME] refused -- state=" << phaseName(phase);
		return;
	}

	ResumeReport r = analyzeResume(zoneServer);

	if (!r.haveManifest) {
		admin->sendSystemMessage("[worldreset] Resume refused -- target manifest missing (cannot prove the original target set). Restore from backup, or /worldreset clearstate + fresh dryrun/execute.");
		return;
	}

	// Galaxy must be LOCKED for either kind of resume. For a DESTRUCTIVE-phase
	// resume also require other players already clear; for a PRE-destructive resume
	// the CLIENT_DRAIN phase will kick everyone, so only the lock matters here.
	if (zoneServer == nullptr || !zoneServer->isServerLocked()) {
		admin->sendSystemMessage("[worldreset] Resume refused: the galaxy is not LOCKED (type 'lock' at the core3 console first).");
		return;
	}
	if (destructivePhase) {
		String reason;
		if (!serverStateSafeForExecute(zoneServer, adminOID, reason, true)) {
			admin->sendSystemMessage("[worldreset] Resume refused: " + reason);
			info(true) << "[WORLDRESET][RESUME] refused -- " << reason;
			return;
		}
	}

	// Fail closed: identity mismatch or an unverifiable target blocks resume.
	if (r.identityMismatch > 0 || r.unreadable > 0) {
		admin->sendSystemMessage(String("[worldreset] Resume REFUSED -- ") + String::valueOf(r.identityMismatch + r.unreadable)
			+ " manifest target(s) changed identity / cannot be verified. Run /worldreset recoverycheck; restore from backup if needed.");
		info(true) << "[WORLDRESET][RESUME] refused -- identityMismatch=" << r.identityMismatch << " unreadable=" << r.unreadable;
		return;
	}

	if (preDestructivePhase && r.destructiveWorkStarted) {
		admin->sendSystemMessage("[worldreset] Resume REFUSED -- state is pre-destructive but progress shows removals already happened. Run /worldreset recoverycheck.");
		info(true) << "[WORLDRESET][RESUME] refused -- pre-destructive phase but destructiveWorkStarted";
		return;
	}

	if (!r.resumeEligible) {
		admin->sendSystemMessage("[worldreset] Resume refused -- analyzeResume says NOT eligible. Run /worldreset recoverycheck.");
		return;
	}

	{
		Locker guard(&stateMutex);
		executionInProgress = true;
	}

	// Do NOT rewrite state.txt here -- the background task takes over and advances it.
	// A pre-destructive resume runs the full flow (client drain -> cities -> structures);
	// a destructive-phase resume continues from where it stopped (PHASE 1 re-confirms
	// idempotently, PHASE 3 skips already-removed targets).
	const bool resumingDestructive = destructivePhase;

	info(true) << "[WORLDRESET][RESUME] authorized by admin " << admin->getFirstName() << " (" << adminOID
		<< ") -- state=" << phaseName(phase) << " launching background task (fingerprint=" << r.fingerprint
		<< " remaining=" << r.remaining << " alreadyDone=" << (r.confirmedRemoved + r.completedByAbsence)
		<< " destructiveWorkStarted=" << (r.destructiveWorkStarted ? "yes" : "no") << ")";

	launchResetTask(zoneServer, adminOID, resumingDestructive);

	admin->sendSystemMessage("[worldreset] Resume LAUNCHED. Clients are being disconnected; watch the [WORLDRESET] log and use /worldreset status / recoverycheck.");
}

// ---------------------------------------------------------------------------
// arm
// ---------------------------------------------------------------------------

void WorldResetManager::arm(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	const String adminName = admin->getFirstName();

	{
		String note;
		ResetPhase prev = readStatePhase(note);

		if (prev != PHASE_IDLE && prev != PHASE_COMPLETE) {
			admin->sendSystemMessage(String("[worldreset] BLOCKED -- a previous reset did not finish (state=")
				+ phaseName(prev) + "). Run /worldreset clearstate after reviewing the log.");
			info(true) << "[WORLDRESET][ARM] refused -- previous reset incomplete (state=" << phaseName(prev) << ")";
			return;
		}
	}

	Locker guard(&stateMutex);

	if (!isAuthenticatedLocked(adminOID)) {
		guard.release();
		admin->sendSystemMessage("[worldreset] Not authenticated (or window expired).");
		info(true) << "[WORLDRESET][ARM] refused -- admin " << adminName << " (" << adminOID << ") not authenticated";
		return;
	}

	if (!dryRunComplete || dryRunAdminOID != adminOID) {
		guard.release();
		admin->sendSystemMessage("[worldreset] You must run /worldreset dryrun (as this admin) before arming.");
		info(true) << "[WORLDRESET][ARM] refused -- no valid dry run for admin " << adminOID;
		return;
	}

	if (nowMs() - dryRunTimeMs > DRYRUN_VALIDITY_MS) {
		clearDryRunLocked();
		guard.release();
		admin->sendSystemMessage("[worldreset] The dry run is stale. Run /worldreset dryrun again.");
		info(true) << "[WORLDRESET][ARM] refused -- stale dry run for admin " << adminOID;
		return;
	}

	if (!dryRunSafe) {
		guard.release();
		admin->sendSystemMessage("[worldreset] The dry run flagged UNSAFE / unclassified items. Cannot arm. See /worldreset status.");
		info(true) << "[WORLDRESET][ARM] refused -- dry run not safe for admin " << adminOID;
		return;
	}

	armed = true;
	armAdminOID = adminOID;
	armedAtMs = nowMs();
	armExpireMs = nowMs() + ARM_LIFETIME_MS;

	guard.release();
	admin->sendSystemMessage("[worldreset] ARMED for 5 minutes. Execute with: /worldreset execute RESET-HOUSING-AND-CITIES");
	info(true) << "[WORLDRESET][ARM] ARMED by admin " << adminName << " (" << adminOID << ") -- 5 minute window";
}

// ---------------------------------------------------------------------------
// cancel
// ---------------------------------------------------------------------------

void WorldResetManager::cancel(CreatureObject* admin) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();

	Locker guard(&stateMutex);

	clearArmLocked();
	clearDryRunLocked();
	clearAuthLocked();

	guard.release();
	admin->sendSystemMessage("[worldreset] Cancelled. Armed state, dry-run authorization and authentication cleared.");
	info(true) << "[WORLDRESET][ARM] CANCELLED by admin " << admin->getFirstName() << " (" << adminOID << ")";
}

// ---------------------------------------------------------------------------
// execute
// ---------------------------------------------------------------------------

void WorldResetManager::execute(CreatureObject* admin, const String& confirmationPhrase) {
	if (admin == nullptr)
		return;

	const uint64 adminOID = admin->getObjectID();
	const String adminName = admin->getFirstName();
	PlayerObject* ghost = admin->getPlayerObject();
	const int adminLevel = (ghost != nullptr) ? (int)ghost->getAdminLevel() : -1;

	ZoneServer* zoneServer = admin->getZoneServer();

	{
		Locker guard(&stateMutex);

		if (executionInProgress) {
			guard.release();
			admin->sendSystemMessage("[worldreset] An execution is already in progress.");
			return;
		}

		if (!isAuthenticatedLocked(adminOID)) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not authenticated (or window expired).");
			info(true) << "[WORLDRESET][EXECUTE] refused -- admin " << adminOID << " not authenticated";
			return;
		}

		if (!dryRunComplete || dryRunAdminOID != adminOID || !dryRunSafe) {
			guard.release();
			admin->sendSystemMessage("[worldreset] A successful, safe dry run by this admin is required.");
			info(true) << "[WORLDRESET][EXECUTE] refused -- no valid safe dry run for admin " << adminOID;
			return;
		}

		if (nowMs() - dryRunTimeMs > DRYRUN_VALIDITY_MS) {
			clearDryRunLocked();
			clearArmLocked();
			guard.release();
			admin->sendSystemMessage("[worldreset] The dry run is stale. Start over.");
			info(true) << "[WORLDRESET][EXECUTE] refused -- stale dry run for admin " << adminOID;
			return;
		}

		if (!armed || armAdminOID != adminOID) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Not armed. Run /worldreset arm first.");
			info(true) << "[WORLDRESET][EXECUTE] refused -- not armed for admin " << adminOID;
			return;
		}

		if (nowMs() >= armExpireMs) {
			clearArmLocked();
			guard.release();
			admin->sendSystemMessage("[worldreset] The armed window expired. Run /worldreset arm again.");
			info(true) << "[WORLDRESET][EXECUTE] refused -- armed window expired for admin " << adminOID;
			return;
		}

		if (confirmationPhrase != EXECUTE_PHRASE) {
			guard.release();
			admin->sendSystemMessage("[worldreset] Confirmation phrase mismatch. Exact phrase required: RESET-HOUSING-AND-CITIES");
			info(true) << "[WORLDRESET][EXECUTE] refused -- wrong confirmation phrase from admin " << adminOID;
			return;
		}

		executionInProgress = true;
	}

	// --- server-state safety (outside the state lock) ---
	String reason;

	if (!serverStateSafeForExecute(zoneServer, adminOID, reason, true)) {
		Locker guard(&stateMutex);
		executionInProgress = false;
		guard.release();
		admin->sendSystemMessage("[worldreset] Refused: " + reason);
		info(true) << "[WORLDRESET][EXECUTE] refused -- " << reason << " (admin " << adminOID << ")";
		return;
	}

	// Interrupted-previous-reset guard (also checked at dryrun).
	{
		String note;
		ResetPhase prev = readStatePhase(note);

		if (prev != PHASE_IDLE && prev != PHASE_COMPLETE) {
			Locker guard(&stateMutex);
			executionInProgress = false;
			guard.release();
			admin->sendSystemMessage(String("[worldreset] REFUSED -- a previous reset did not finish (state=")
				+ phaseName(prev) + ").\n  /worldreset recovery  -- see what completed / remains\n"
				+ "  /worldreset resume RESET-HOUSING-AND-CITIES  -- continue it (STRUCTURE_PHASE only)\n"
				+ "  /worldreset clearstate  -- abandon it (only after review / backup restore)");
			info(true) << "[WORLDRESET][EXECUTE] REFUSED -- previous reset incomplete (state=" << phaseName(prev) << ")";
			return;
		}
	}

	info(true) << "[WORLDRESET][EXECUTE] START -- admin " << adminName << " (" << adminOID
		<< ") adminLevel=" << adminLevel << " galaxyLocked=YES";

	// --- fresh re-scan, re-verify safety AND fingerprint match before mutating ---
	DryRunCounts fresh;
	SortedVector<uint64> freshCityOIDs, freshStructOIDs, freshOrphanOIDs;
	collectSnapshot(zoneServer, admin, fresh, false, freshCityOIDs, freshStructOIDs, freshOrphanOIDs);

	Vector<String> freshReasons;
	const bool freshSafe = evaluateSafety(fresh, freshReasons);

	String expectedFingerprint;
	{
		Locker guard(&stateMutex);
		expectedFingerprint = lastFingerprint;
	}

	if (!freshSafe) {
		Locker guard(&stateMutex);
		executionInProgress = false;
		clearArmLocked();
		guard.release();

		StringBuffer m;
		m << "[worldreset] REFUSED -- a fresh re-scan is UNSAFE. Nothing was changed.";
		for (int i = 0; i < freshReasons.size(); ++i)
			m << "\n    - " << freshReasons.get(i);
		admin->sendSystemMessage(m.toString());
		info(true) << "[WORLDRESET][EXECUTE] REFUSED -- fresh re-scan not safe (admin " << adminOID << ")";
		return;
	}

	if (fresh.fingerprint != expectedFingerprint) {
		Locker guard(&stateMutex);
		executionInProgress = false;
		clearArmLocked();
		clearDryRunLocked();
		guard.release();
		admin->sendSystemMessage(String("[worldreset] [WORLDRESET][EXECUTE] REFUSED\n")
			+ "Dry-run snapshot no longer matches current world state (fingerprint "
			+ expectedFingerprint + " != " + fresh.fingerprint + ").\nRun /worldreset dryrun again.");
		info(true) << "[WORLDRESET][EXECUTE] REFUSED -- snapshot fingerprint mismatch expected=" << expectedFingerprint
			<< " current=" << fresh.fingerprint << " (admin " << adminOID << ")";
		return;
	}

	info(true) << "[WORLDRESET][EXECUTE] snapshot fingerprint verified: " << fresh.fingerprint;

	// Persist the exact target set + per-target identity metadata. From here on this
	// manifest -- NOT the RAM snapshot -- is the only authority for what the reset
	// (or a later resume) may touch. Also resets the per-target progress log.
	uint64 armedAtSnapshot;
	{
		Locker guard(&stateMutex);
		armedAtSnapshot = armedAtMs;
	}
	// Audit metadata -- persisted for logging only. The reset worker NEVER
	// dereferences or locks the initiating player; it keeps only adminOID for
	// best-effort status messages.
	const uint32 adminAccountID = (admin->getPlayerObject() != nullptr) ? admin->getPlayerObject()->getAccountID() : 0;
	info(true) << "[WORLDRESET][PRECHECK] START -- initiatingAdminOID=" << adminOID
		<< " initiatingAccountID=" << adminAccountID << " initiatingCharacterName=" << adminName;
	writeManifestV2(zoneServer, fresh.fingerprint, armedAtSnapshot, freshCityOIDs, freshStructOIDs, freshOrphanOIDs);
	writeStatePhase(PHASE_PRECHECK, String("execute launched fingerprint=") + fresh.fingerprint
		+ " by=" + adminName + "(" + String::valueOf(adminOID) + ",acct" + String::valueOf(adminAccountID) + ")");
	info(true) << "[WORLDRESET][PRECHECK] manifest verified + persisted fingerprint=" << fresh.fingerprint
		<< " cities=" << freshCityOIDs.size() << " structures=" << freshStructOIDs.size()
		<< " orphans=" << freshOrphanOIDs.size();

	// Consume the armed / authenticated state now -- the operation is committed.
	{
		Locker guard(&stateMutex);
		clearArmLocked();
		clearDryRunLocked();
		clearAuthLocked();
		// executionInProgress stays true; the background task clears it when done.
	}

	// Issue the client disconnects from HERE, while we are still in the admin's
	// command context (so this is the one place it is legitimate to touch the
	// admin's own session). This never blocks -- it sets logging-out + sends
	// LogoutMessage under a transient per-player lock and schedules the actual
	// session teardown. The background task then WAITS (lock-free) for the drain.
	int kicked = 0;
	requestClientDisconnects(zoneServer, adminOID, kicked);
	info(true) << "[WORLDRESET][PRECHECK] command context released -- issued " << kicked
		<< " client disconnect request(s); background task will wait for the drain";

	// Hand off to a detached task worker. The destructive work must NOT run here:
	// the ObjectController holds this admin's creature write-lock across
	// doQueueCommand(). The task runs with no external lock held and does not need
	// the admin to stay connected.
	launchResetTask(zoneServer, adminOID, false);

	admin->sendSystemMessage("[worldreset] Reset LAUNCHED. All clients (including yours) are being disconnected now. Watch the [WORLDRESET] server log; use /worldreset status / recoverycheck.");
	info(true) << "[WORLDRESET][EXECUTE] handed off to background task -- admin " << adminName << " (" << adminOID << ")";
}

// ---------------------------------------------------------------------------
// background task launch + wrapper
// ---------------------------------------------------------------------------

void WorldResetManager::launchResetTask(ZoneServer* zoneServer, uint64 adminOID, bool resuming) {
	auto taskManager = Core::getTaskManager();

	if (taskManager == nullptr) {
		error("[WORLDRESET][EXECUTE] no task manager -- cannot launch background reset");
		Locker guard(&stateMutex);
		executionInProgress = false;
		return;
	}

	WorldResetManager* self = this;

	taskManager->executeTask([self, zoneServer, adminOID, resuming]() {
		self->runResetBackground(zoneServer, adminOID, resuming);
	}, "WorldResetExecute");
}

void WorldResetManager::runResetBackground(ZoneServer* zoneServer, uint64 adminOID, bool resuming) {
	try {
		performReset(zoneServer, adminOID, resuming);
	} catch (const Exception& e) {
		writeStatePhase(PHASE_FAILED, String("performReset threw: ") + e.getMessage());
		error() << "[WORLDRESET][EXECUTE] FAILED -- performReset threw: " << e.getMessage();
	} catch (...) {
		writeStatePhase(PHASE_FAILED, "performReset threw an unknown exception");
		error("[WORLDRESET][EXECUTE] FAILED -- performReset threw an unknown exception");
	}

	hbStop(); // stop the stall watchdog rescheduling

	{
		Locker guard(&stateMutex);
		executionInProgress = false;
	}
}

// ---------------------------------------------------------------------------
// server-state safety
// ---------------------------------------------------------------------------

bool WorldResetManager::serverStateSafeForExecute(ZoneServer* zoneServer, uint64 adminOID, String& reason, bool allowAdmin) {
	if (zoneServer == nullptr) {
		reason = "zone server unavailable";
		return false;
	}

	if (!zoneServer->isServerLocked()) {
		reason = "the galaxy is not LOCKED (type 'lock' at the core3 server console first)";
		return false;
	}

	PlayerManager* playerManager = zoneServer->getPlayerManager();

	if (playerManager == nullptr) {
		reason = "player manager unavailable";
		return false;
	}

	// The destructive phases must run with NO gameplay client connected. Even the
	// executing admin is unsafe once destruction starts: if the admin is standing
	// in a targeted building, BuildingObject::destroyObjectFromDatabase() teleports
	// player creatures out of its cells while the structure is locked -> a
	// structure->creature lock inversion that deadlocked the previous test.
	// allowAdmin is true only at the /worldreset execute gate (the admin is still
	// typing); the background task re-checks with allowAdmin=false AFTER kicking
	// every client.
	Vector<uint64> online = playerManager->getOnlinePlayerList();
	int others = 0;

	for (int i = 0; i < online.size(); ++i) {
		const uint64 pid = online.get(i);

		if (allowAdmin && pid == adminOID)
			continue;

		ManagedReference<SceneObject*> so = zoneServer->getObject(pid);

		if (so != nullptr && so->isPlayerCreature())
			++others;
	}

	if (others > 0) {
		reason = String::valueOf(others) + (allowAdmin
			? String(" other player character(s) are still connected -- every non-admin client must be off the galaxy first")
			: String(" player character(s) are still connected"));
		return false;
	}

	return true;
}

// ---------------------------------------------------------------------------
// client drain -- lock-free, timeout, fail closed
// ---------------------------------------------------------------------------
//
// We must NOT use PlayerManager::disconnectAllPlayers() here. That routine holds
// onlineMapMutex for its whole run and, while holding it, takes each player's
// CreatureObject lock and drives ZoneClientSession teardown. Every normal
// gameplay path locks a CreatureObject FIRST and touches onlineMapMutex second
// (decreaseOnlineCharCount, ZoneClientSession::setPlayer, increaseOnlineCharCount,
// /who, chat ...). Calling disconnectAllPlayers() on a live server from a task
// worker therefore inverts that order -> AB/BA deadlock (observed: reset hung in
// the PRECHECK->CITY transition right after the admin was kicked). It is only
// safe inside the shutdown sequence, when nothing else contends those locks.
//
// The disconnect itself runs in a scheduled task holding ONLY the target
// creature's lock (never onlineMapMutex, never the WorldReset mutex, never the
// command stack). It does NOT rely on the initiating player's session lifetime.
//
// Why the naive "session->disconnect(true)" was not enough (proven from source):
// that path drives DisconnectClientEvent -> PlayerObject::disconnect() which, on
// the first pass for an ONLINE player, only calls setLinkDead() (UNSAFE). An
// unsafe link-dead player is then kept in onlineZoneClientMap for
// Core3.PlayerObject.LinkDeadDelay (default 180s) until PlayerObject::doRecovery()
// sees logoutTimeStamp.isPast() and unloads it. That 180s grace is exactly our
// drain timeout -> the session never leaves getOnlinePlayerList() in time.
// PlayerObject::logout() does not help either: PlayerDisconnectEvent skips its
// unload when !isOnline() (true for link-dead).
//
// Fix: force a SAFE logout. setLinkDead(true) sets logoutTimeStamp = now (no
// grace), then the player-recovery tick (already rescheduled every 1s) unloads
// the player on its very next pass -- exactly the code path Core3 uses when the
// link-dead timer expires, just immediately.

// Read-only one-line description of a still-connected session, for CLIENT_DRAIN
// diagnostics. Never dereferences a stale raw pointer -- everything goes through
// managed refs resolved fresh from the zone server.
static String wrDescribeSession(ZoneServer* zoneServer, uint64 oid) {
	StringBuffer b;
	b << "OID=" << oid;

	ManagedReference<SceneObject*> so;
	try { so = zoneServer->getObject(oid); } catch (...) {}

	b << " zoneServerReg=" << (so != nullptr ? "YES" : "NO");

	ManagedReference<CreatureObject*> creature = (so != nullptr) ? so.castTo<CreatureObject*>() : nullptr;
	b << " creatureObj=" << (creature != nullptr ? "YES" : "NO");

	if (creature == nullptr)
		return b.toString();

	b << " name=" << creature->getFirstName();

	ManagedReference<SceneObject*> ghostObj = creature->getSlottedObject("ghost");
	if (ghostObj != nullptr && ghostObj->isPlayerObject()) {
		PlayerObject* ghost = cast<PlayerObject*>(ghostObj.get());
		b << " playerObj=YES account=" << ghost->getAccountID()
			<< " status=" << (ghost->isOnline() ? "ONLINE" : (ghost->isLinkDead() ? "LINKDEAD"
				: (ghost->isLoggingOut() ? "LOGGINGOUT" : (ghost->isOffline() ? "OFFLINE" : "?"))));
	} else {
		b << " playerObj=NO";
	}

	ManagedReference<ZoneClientSession*> session = creature->getClient();
	if (session != nullptr) {
		b << " session=present ip=" << session->getIPAddress();
	} else {
		b << " session=NONE(socket gone; registry entry lingering)";
	}

	PlayerManager* pm = zoneServer->getPlayerManager();
	if (pm != nullptr) {
		ManagedReference<CreatureObject*> byName = pm->getPlayer(creature->getFirstName());
		b << " playerMgrReg=" << (byName != nullptr && byName->getObjectID() == oid ? "YES" : "NO");
	}

	return b.toString();
}

static void wrRequestOneDisconnect(ZoneServer* zoneServer, uint64 playerOID) {
	ManagedReference<SceneObject*> so = zoneServer->getObject(playerOID);

	if (so == nullptr || !so->isPlayerCreature())
		return;

	ManagedReference<CreatureObject*> player = so.castTo<CreatureObject*>();

	if (player == nullptr)
		return;

	// notify the client immediately (best effort, no lock)
	try {
		player->sendMessage(new LogoutMessage());
	} catch (...) {}

	Reference<CreatureObject*> playerRef = player;

	Core::getTaskManager()->scheduleTask([playerRef]() {
		Reference<CreatureObject*> creature = playerRef;
		Reference<SceneObject*> g = creature->getSlottedObject("ghost");
		if (g == nullptr || !g->isPlayerObject())
			return;
		PlayerObject* ghost = cast<PlayerObject*>(g.get());

		// Only this creature's lock -- the same lock PlayerRecoveryEvent::run()
		// holds when it does the identical unload/setOffline/closeConnection.
		Locker lock(creature);

		if (ghost->isOffline())
			return; // already gone

		try {
			// 1) tear the network session down the normal way (idempotent).
			Reference<ZoneClientSession*> session = creature->getClient();
			if (session != nullptr)
				session->disconnect(true);

			// 2) collapse the unsafe link-dead grace to zero. setLinkDead(true)
			//    => isSafeLogout => logoutTimeStamp = now, and it re-arms the
			//    recovery tick.
			ghost->setLinkDead(true);
			ghost->activateRecovery();
		} catch (...) {
			// last resort: run the unload the recovery tick would have run.
			try {
				ghost->unload();
				ghost->setOffline();
				Reference<ZoneClientSession*> s2 = creature->getClient();
				if (s2 != nullptr)
					s2->closeConnection(false, true);
			} catch (...) {}
		}
	}, "WorldResetKickTask", 250);
}

void WorldResetManager::requestClientDisconnects(ZoneServer* zoneServer, uint64 initiatingAdminOID, int& requested) {
	requested = 0;

	if (zoneServer == nullptr)
		return;

	PlayerManager* playerManager = zoneServer->getPlayerManager();
	if (playerManager == nullptr)
		return;

	Vector<uint64> online = playerManager->getOnlinePlayerList();

	for (int i = 0; i < online.size(); ++i) {
		const uint64 oid = online.get(i);
		info(true) << "[WORLDRESET][CLIENT_DRAIN] requesting disconnect player=" << oid
			<< (oid == initiatingAdminOID ? " (initiating admin)" : "");
		wrRequestOneDisconnect(zoneServer, oid);
		++requested;
	}
}

bool WorldResetManager::waitForClientDrain(ZoneServer* zoneServer, int maxWaitSecs, String& reason) {
	reason = "";

	if (zoneServer == nullptr) {
		reason = "zone server unavailable";
		return false;
	}

	PlayerManager* playerManager = zoneServer->getPlayerManager();
	if (playerManager == nullptr) {
		reason = "player manager unavailable";
		return false;
	}

	const uint64 start = nowMs();
	const uint64 deadline = start + (uint64)maxWaitSecs * 1000ULL;
	uint64 lastReNudge = 0;
	uint64 lastChangeMs = start;
	int lastReportedStall = 0;
	int lastRemaining = -1;

	while (nowMs() < deadline) {
		// NO lock held across this -- getOnlinePlayerList() takes onlineMapMutex
		// briefly and returns a snapshot; we do nothing else under any lock.
		Vector<uint64> online = playerManager->getOnlinePlayerList();

		int remaining = 0;
		StringBuffer who;
		for (int i = 0; i < online.size(); ++i) {
			ManagedReference<SceneObject*> so = zoneServer->getObject(online.get(i));
			if (so != nullptr && so->isPlayerCreature()) {
				++remaining;
				if (remaining <= 8)
					who << (remaining == 1 ? "" : ",") << online.get(i);
			}
		}

		if (remaining == 0) {
			info(true) << "[WORLDRESET][CLIENT_DRAIN] COMPLETE -- 0 clients connected after "
				<< (int)((nowMs() - start) / 1000) << "s";
			return true;
		}

		if (remaining != lastRemaining) {
			info(true) << "[WORLDRESET][CLIENT_DRAIN] remaining=" << remaining
				<< " oids=[" << who.toString() << (remaining > 8 ? ",..." : "") << "]"
				<< " elapsed=" << (int)((nowMs() - start) / 1000) << "s";
			// full per-session diagnostic when the set changes
			for (int i = 0; i < online.size(); ++i) {
				ManagedReference<SceneObject*> dso = zoneServer->getObject(online.get(i));
				if (dso != nullptr && dso->isPlayerCreature())
					info(true) << "[WORLDRESET][CLIENT_DRAIN]   " << wrDescribeSession(zoneServer, online.get(i));
			}
			lastRemaining = remaining;
			lastChangeMs = nowMs();
			lastReportedStall = 0;
		} else {
			const int stalledSecs = (int)((nowMs() - lastChangeMs) / 1000);
			if (stalledSecs >= 60 && stalledSecs - lastReportedStall >= 30) {
				lastReportedStall = stalledSecs;
				error() << "[WORLDRESET][STALL] state=CLIENT_DRAIN elapsed=" << (int)((nowMs() - start) / 1000)
					<< "s remainingSessions=" << remaining << " currentOperation=waitForClientDrain"
					<< " -- will fail closed at the " << maxWaitSecs << "s timeout (no destructive work)";
				for (int i = 0; i < online.size(); ++i) {
					ManagedReference<SceneObject*> dso = zoneServer->getObject(online.get(i));
					if (dso != nullptr && dso->isPlayerCreature())
						error() << "[WORLDRESET][STALL]   " << wrDescribeSession(zoneServer, online.get(i));
				}
			}
		}

		// re-issue disconnect requests every 15s for anyone still hanging on
		if (nowMs() - lastReNudge >= 15000ULL) {
			lastReNudge = nowMs();
			for (int i = 0; i < online.size(); ++i)
				wrRequestOneDisconnect(zoneServer, online.get(i));
		}

		Thread::sleep(2000);
	}

	// timeout -- fail closed. Report exactly who is left, with full diagnostics.
	Vector<uint64> online = playerManager->getOnlinePlayerList();
	StringBuffer left;
	int stillOn = 0;
	for (int i = 0; i < online.size(); ++i) {
		ManagedReference<SceneObject*> so = zoneServer->getObject(online.get(i));
		if (so != nullptr && so->isPlayerCreature()) {
			++stillOn;
			left << (stillOn == 1 ? "" : ",") << online.get(i);
			error() << "[WORLDRESET][CLIENT_DRAIN][TIMEOUT]   " << wrDescribeSession(zoneServer, online.get(i));
		}
	}
	reason = String::valueOf(stillOn) + " client session(s) still connected after "
		+ String::valueOf(maxWaitSecs) + "s [" + left.toString() + "]";
	return false;
}

// ---------------------------------------------------------------------------
// pack-payload directory scan (read only)
// ---------------------------------------------------------------------------

static void scanHousePackDir(const char* dir, SortedVector<uint64>& buildingPayloadOIDs, int& deedPayloadCount) {
	DIR* d = ::opendir(dir);

	if (d == nullptr)
		return;

	struct dirent* entry;

	while ((entry = ::readdir(d)) != nullptr) {
		const char* name = entry->d_name;

		// building-stage payload: b-<oid>.bin
		if (name[0] == 'b' && name[1] == '-') {
			uint64 oid = ::strtoull(name + 2, nullptr, 10);
			if (oid != 0)
				buildingPayloadOIDs.put(oid);
		} else if (name[0] == 'd' && name[1] == '-') {
			// deed-stage payload: d-<oid>.bin  (a packed house in deed form)
			++deedPayloadCount;
		}
	}

	::closedir(d);
}

// ---------------------------------------------------------------------------
// snapshot (pure read -- ZERO mutation)
// ---------------------------------------------------------------------------

void WorldResetManager::collectSnapshot(ZoneServer* zoneServer, CreatureObject* admin, DryRunCounts& out, bool logDetails,
		SortedVector<uint64>& cityOIDs, SortedVector<uint64>& structureOIDs, SortedVector<uint64>& orphanOIDs) {
	out = DryRunCounts();

	cityOIDs.removeAll();
	structureOIDs.removeAll();
	orphanOIDs.removeAll();
	cityOIDs.setNoDuplicateInsertPlan();
	structureOIDs.setNoDuplicateInsertPlan();
	orphanOIDs.setNoDuplicateInsertPlan();

	if (zoneServer == nullptr && admin != nullptr)
		zoneServer = admin->getZoneServer();

	if (zoneServer == nullptr) {
		error("[WORLDRESET][DRYRUN] no zone server available for snapshot");
		out.dbReadErrors += 1;
		return;
	}

	auto objectDBManager = ObjectDatabaseManager::instance();

	// ----- pack payload files on disk -----
	SortedVector<uint64> buildingPayloadOIDs;
	buildingPayloadOIDs.setNoDuplicateInsertPlan();
	int deedPayloadCount = 0;

	scanHousePackDir("housepacks", buildingPayloadOIDs, deedPayloadCount);
	scanHousePackDir("bin/housepacks", buildingPayloadOIDs, deedPayloadCount);

	out.packedDeedsExcluded = deedPayloadCount;

	// track which building payload OIDs actually correspond to a live deployed
	// building so we can split "packed pending redeem" from "orphan payload file".
	SortedVector<uint64> matchedBuildingPayloadOIDs;
	matchedBuildingPayloadOIDs.setNoDuplicateInsertPlan();

	// ================= Phase A: player cities (cityregions.db) =================
	int cityRecordsSeen = 0;

	try {
		ObjectDatabase* cityDB = objectDBManager->loadObjectDatabase("cityregions", true);

		if (cityDB == nullptr) {
			error("[WORLDRESET][DRYRUN] cityregions database could not be loaded");
			out.dbReadErrors += 1;
		}

		if (cityDB != nullptr) {
			ObjectDatabaseIterator iterator(cityDB);
			ObjectInputStream objectData(2000);
			uint64 oid = 0;

			while (iterator.getNextKeyAndValue(oid, &objectData)) {
				++cityRecordsSeen;
				try {
					Reference<CityRegion*> city = Core::getObjectBroker()->lookUp(oid).castTo<CityRegion*>();

					if (city == nullptr) {
						++out.unreadableCityRecords;

						if (logDetails)
							warning() << "[WORLDRESET][ORPHAN] cityregions.db OID=" << oid
								<< " will not deserialize to a CityRegion -- will be SKIPPED (not touched)";

						objectData.reset();
						continue;
					}

					if (city->isClientRegion()) {
						++out.staticCitiesExcluded;
						objectData.reset();
						continue;
					}

					++out.playerCities;
					cityOIDs.put(oid);
					out.cityCitizens += city->getCitizenCount();
					out.cityTreasuryTotal += (int64)city->getCityTreasury();

					ManagedReference<StructureObject*> cityHall = city->getCityHall();

					if (cityHall != nullptr)
						++out.cityHalls;

					out.civicStructures += city->getStructuresCount();

					if (logDetails)
						info(true) << "[WORLDRESET][CITY] candidate OID=" << oid
							<< " name=\"" << city->getCityRegionName() << "\""
							<< " rank=" << (int)city->getCityRank()
							<< " mayorID=" << city->getMayorID()
							<< " zone=" << (city->getZone() != nullptr ? city->getZone()->getZoneName() : String("<none>"))
							<< " citizens=" << city->getCitizenCount()
							<< " civicStructures=" << city->getStructuresCount()
							<< " treasury=" << (int64)city->getCityTreasury();
				} catch (const Exception& e) {
					++out.unreadableCityRecords;
					if (logDetails)
						warning() << "[WORLDRESET][ORPHAN] cityregions.db OID=" << oid << " error=" << e.getMessage() << " -- SKIPPED";
				} catch (...) {
					++out.unreadableCityRecords;
					if (logDetails)
						warning() << "[WORLDRESET][ORPHAN] cityregions.db OID=" << oid << " unknown exception -- SKIPPED";
				}

				objectData.reset();
			}
		}
	} catch (const Exception& e) {
		error() << "[WORLDRESET][ERROR] failed iterating cityregions.db: " << e.getMessage();
		// A DB-level failure here means the snapshot is not trustworthy.
		out.dbReadErrors += 1;
	} catch (...) {
		error("[WORLDRESET][ERROR] failed iterating cityregions.db (unknown exception)");
		out.dbReadErrors += 1;
	}

	info(true) << "[WORLDRESET][CITY] phase A complete -- cityregions.db records scanned=" << cityRecordsSeen
		<< " playerCities=" << out.playerCities
		<< " client/NPC regions excluded=" << out.staticCitiesExcluded
		<< " unreadable city records=" << out.unreadableCityRecords;

	// ============== Phase B: deployed structures (playerstructures.db) ==============
	// Collect the keys with the cursor, then close it BEFORE resolving/locking each
	// object. Holding a Berkeley cursor while taking object locks risks a lock-order
	// inversion with the structure save path.
	Vector<uint64> structureKeys;

	try {
		ObjectDatabase* structureDB = objectDBManager->loadObjectDatabase("playerstructures", true);

		if (structureDB != nullptr) {
			ObjectDatabaseIterator iterator(structureDB);
			ObjectInputStream objectData(2000);
			uint64 keyOid = 0;

			while (iterator.getNextKeyAndValue(keyOid, &objectData)) {
				structureKeys.add(keyOid);
				objectData.reset();
			}
		}
	} catch (const Exception& e) {
		error() << "[WORLDRESET][ERROR] failed reading playerstructures.db keys: " << e.getMessage();
		out.dbReadErrors += 1;
	} catch (...) {
		error("[WORLDRESET][ERROR] failed reading playerstructures.db keys (unknown exception)");
		out.dbReadErrors += 1;
	}

	ObjectDatabase* structureDBForRaw = nullptr;
	try {
		structureDBForRaw = objectDBManager->loadObjectDatabase("playerstructures", true);
	} catch (...) {
		structureDBForRaw = nullptr;
	}

	for (int ki = 0; ki < structureKeys.size(); ++ki) {
		const uint64 oid = structureKeys.get(ki);

		try {
			ManagedReference<SceneObject*> so = zoneServer->getObject(oid);

			// playerstructures.db legitimately holds objects that are NOT
			// StructureObjects: EventPerkDeed deployables, FlagGame flags and NPC
			// actor perks are all persisted here as TangibleObjects (see
			// EventPerkDeedImplementation / FlagGameImplementation /
			// NpcActorCreationSessionImplementation, all createObject(..., "playerstructures")).
			// If the object loaded fine but is not a structure, it is positively a
			// non-structure record -> EXCLUDE it; it is NOT unreadable and NOT in scope.
			if (so != nullptr && so.castTo<StructureObject*>() == nullptr) {
				++out.nonStructureRecordsExcluded;

				if (logDetails)
					info(true) << "[WORLDRESET][STRUCTURE] EXCLUDED non-structure record OID=" << oid
						<< " gameObjectType=" << so->getGameObjectType()
						<< " template=" << (so->getObjectTemplate() != nullptr ? so->getObjectTemplate()->getFullTemplateString() : String("<none>"))
						<< " name=\"" << so->getDisplayedName() << "\""
						<< " -- playerstructures.db also tracks event-perk deployables / flags / NPC actor perks as tangibles; not in reset scope";

				continue;
			}

			ManagedReference<StructureObject*> s;

			if (so != nullptr)
				s = so.castTo<StructureObject*>();

			if (s == nullptr) {
				// ObjectManager could not instantiate the object at all.
				++out.unreadableStructureRecords;

				// Pull whatever we can from the raw serialized record so an admin can
				// identify what these are without loading them. Never modifies anything.
				String rawClassName, rawZone;
				uint32 rawCRC = 0;
				uint64 rawOwner = 0;
				bool rawExists = false;

				if (structureDBForRaw != nullptr) {
					try {
						ObjectInputStream rawData(1000);

						if (!structureDBForRaw->getData(oid, &rawData)) {
							rawExists = true;
							Serializable::getVariable<String>(STRING_HASHCODE("_className"), &rawClassName, &rawData);
							Serializable::getVariable<uint32>(STRING_HASHCODE("SceneObject.serverObjectCRC"), &rawCRC, &rawData);
							Serializable::getVariable<uint64>(STRING_HASHCODE("StructureObject.ownerObjectID"), &rawOwner, &rawData);
							Serializable::getVariable<String>(STRING_HASHCODE("SceneObject.zone"), &rawZone, &rawData);
						}
					} catch (...) {
						// leave fields default
					}
				}

				String rawTemplate = "<unresolved>";
				Reference<SharedObjectTemplate*> rawTmpl;
				if (rawCRC != 0)
					rawTmpl = TemplateManager::instance()->getTemplate(rawCRC);
				if (rawTmpl != nullptr)
					rawTemplate = rawTmpl->getFullTemplateString();

				const bool provenPlayerStructure = classNameIsPlayerStructure(rawClassName);

				warning() << "[WORLDRESET][ORPHAN] playerstructures.db OID=" << oid
					<< " UNREADABLE -- rawRecordPresent=" << (rawExists ? "yes" : "no")
					<< " objectManagerLoad=failed sceneResolve=failed"
					<< " className=\"" << (rawClassName.isEmpty() ? String("<none>") : rawClassName) << "\""
					<< " serverObjectCRC=0x" << String::hexvalueOf((int)rawCRC)
					<< " template=" << rawTemplate
					<< " ownerID=" << rawOwner
					<< " zone=\"" << (rawZone.isEmpty() ? String("<none>") : rawZone) << "\""
					<< " provablePlayerStructure=" << (provenPlayerStructure ? "yes" : "no")
					<< " reason=" << (rawCRC != 0 && rawTmpl == nullptr
						? String("template CRC not resolvable on this server (removed/renamed .iff)")
						: (rawExists ? String("object failed to deserialize (version/format or component load)")
									 : String("no raw record found for this key")))
					<< " -- NOT MODIFIED; execution BLOCKED until reviewed";

				continue;
			}

			// Lock the structure before inspecting it. On a live server (dry run)
			// other threads mutate cells / container contents, and an unlocked
			// traversal of building->getCell()/getContainerObject() can crash.
			Locker locker(s);

			if (HousePackupManager::instance()->hasSavedPayloadForBuilding(oid)) {
				++out.packedPendingRedeem;
				matchedBuildingPayloadOIDs.put(oid);

				warning() << "[WORLDRESET][DRYRUN] UNSAFE -- OID=" << oid
					<< " is a DEPLOYED building with a saved pack payload (housepacks/b-" << oid
					<< ".bin) but the deed has NOT been redeemed yet. Destroying it now would strand its"
					<< " packed contents. The owning player must complete 'Destroy Structure' at the"
					<< " terminal (turning the payload into a deed) before this reset can be armed.";

				continue;
			}

			if (s->isGCWBase()) {
				++out.gcwBasesExcluded;

				if (logDetails)
					info(true) << "[WORLDRESET][STRUCTURE] EXCLUDED GCW/faction base OID=" << oid;

				continue;
			}

			if (s->isCivicStructure() || s->isCityHall()) {
				// Counted under the owning city; destroyed by CityManager::destroyCity.
				// A civic structure whose player city record is missing/unreadable is
				// intentionally left for manual cleanup.
				if (logDetails)
					info(true) << "[WORLDRESET][STRUCTURE] civic/city-hall OID=" << oid
						<< " (" << describeStructureType(s) << ") -- handled via its city's disband, or left for manual review if its city is gone";

				continue;
			}

			ManagedReference<Zone*> zone = s->getZone();

			if (zone == nullptr) {
				// Positively a StructureObject (loaded) that is keyed in
				// playerstructures.db but has lost its zone. Provably player-structure
				// state -> eligible for Phase 4 (orphan) removal via object lifecycle.
				++out.orphanStructures;
				orphanOIDs.put(oid);

				if (logDetails)
					warning() << "[WORLDRESET][ORPHAN] OID=" << oid
						<< " template=" << (s->getObjectTemplate() != nullptr ? s->getObjectTemplate()->getFullTemplateString() : String("<none>"))
						<< " ownerID=" << s->getOwnerObjectID()
						<< " type=" << describeStructureType(s)
						<< " has NO zone -- provably player-structure state, eligible for orphan removal";

				continue;
			}

			// vendor exposure + unpacked-content detection for deployed buildings
			if (s->isBuildingObject()) {
				ManagedReference<BuildingObject*> building = s.castTo<BuildingObject*>();

				if (building != nullptr) {
					if (HousePackupManager::instance()->hasVendorsInside(building.get()))
						++out.potentialVendors;

					int contentCount = 0;

					for (uint32 c = 1; c <= building->getTotalCellNumber(); ++c) {
						ManagedReference<CellObject*> cell = building->getCell(c);

						if (cell == nullptr)
							continue;

						for (int k = 0; k < cell->getContainerObjectsSize(); ++k) {
							ManagedReference<SceneObject*> child = cell->getContainerObject(k);

							if (child == nullptr || child->isCreatureObject() || child->isTerminal())
								continue;

							++contentCount;
						}
					}

					if (contentCount > 0)
						++out.structuresWithUnpackedContents;
				}
			}

			// classify a normally-deployed player structure
			structureOIDs.put(oid);

			if (s->isFactory())
				++out.factories;
			else if (s->isHarvesterObject())
				++out.harvesters;
			else if (s->isGeneratorObject())
				++out.generators;
			else if (s->isInstallationObject())
				++out.installations;
			else if (s->isBuildingObject())
				++out.deployedHouses;
			else
				++out.otherDeployedStructures;

			if (logDetails)
				info(true) << "[WORLDRESET][STRUCTURE] candidate OID=" << oid
					<< " template=" << (s->getObjectTemplate() != nullptr ? s->getObjectTemplate()->getFullTemplateString() : String("<none>"))
					<< " type=" << describeStructureType(s)
					<< " ownerID=" << s->getOwnerObjectID()
					<< " zone=" << zone->getZoneName()
					<< " x=" << s->getWorldPositionX()
					<< " y=" << s->getWorldPositionY();
		} catch (const Exception& e) {
			++out.unclassifiedLiveObjects;
			warning() << "[WORLDRESET][DRYRUN] UNSAFE -- OID=" << oid
				<< " threw during classification: " << e.getMessage();
		} catch (...) {
			++out.unclassifiedLiveObjects;
			warning() << "[WORLDRESET][DRYRUN] UNSAFE -- OID=" << oid
				<< " threw an unknown exception during classification";
		}
	}

	// building payload files that do NOT match a live deployed building
	for (int i = 0; i < buildingPayloadOIDs.size(); ++i) {
		if (!matchedBuildingPayloadOIDs.contains(buildingPayloadOIDs.get(i)))
			++out.orphanPackPayloadFiles;
	}

	out.fingerprint = computeFingerprint(out, cityOIDs, structureOIDs, orphanOIDs);
}

// ---------------------------------------------------------------------------
// perform reset (MUTATING -- runs on a DETACHED task worker, no external locks)
// ---------------------------------------------------------------------------

void WorldResetManager::performReset(ZoneServer* zoneServer, uint64 adminOID, bool resuming) {
	if (zoneServer == nullptr) {
		writeStatePhase(PHASE_FAILED, "no zone server");
		error("[WORLDRESET][EXECUTE] no zone server -- aborting");
		return;
	}

	// The admin is optional -- resolve only to send status messages. The reset
	// does NOT depend on the admin staying connected (they may safely log out).
	ManagedReference<CreatureObject*> admin;
	{
		ManagedReference<SceneObject*> so = zoneServer->getObject(adminOID);
		if (so != nullptr && so->isPlayerCreature())
			admin = so.castTo<CreatureObject*>();
	}
	auto notify = [&admin](const String& m) {
		if (admin != nullptr)
			admin->sendSystemMessage(m);
	};

	// (1) Galaxy must still be LOCKED.
	{
		String reason;
		if (zoneServer == nullptr || !zoneServer->isServerLocked()) {
			writeStatePhase(PHASE_FAILED, "galaxy not LOCKED at task start");
			error("[WORLDRESET][EXECUTE] FAILED at task start -- galaxy is not LOCKED");
			notify("[worldreset] Reset ABORTED -- galaxy is not LOCKED. State=FAILED; run /worldreset recoverycheck.");
			return;
		}
	}

	// ==================================================================
	// PHASE: CLIENT_DRAIN
	// Wait -- LOCK-FREE -- for every gameplay client to disconnect. execute()
	// already issued the disconnect requests (Core3 kickUser() pattern: no
	// blocking player/session lock, no disconnectAllPlayers). Here we only poll
	// getOnlinePlayerList() and re-nudge stragglers. NOTHING destructive has
	// happened yet, so a timeout just fails closed and stays resumable.
	// ==================================================================
	writeStatePhase(PHASE_CLIENT_DRAIN, "waiting for gameplay clients to disconnect");
	info(true) << "[WORLDRESET][CLIENT_DRAIN] START" << (resuming ? " (RESUME)" : "");

	{
		int requested = 0;
		requestClientDisconnects(zoneServer, adminOID, requested); // idempotent -- catch anyone execute() missed

		String reason;
		if (!waitForClientDrain(zoneServer, /*maxWaitSecs*/ 180, reason)) {
			// fail closed -- remain in CLIENT_DRAIN (NOT FAILED): no destructive
			// work started, manifest intact, safe to retry with /worldreset resume.
			writeStatePhase(PHASE_CLIENT_DRAIN, String("client drain timed out: ") + reason);
			error() << "[WORLDRESET][CLIENT_DRAIN] TIMEOUT -- " << reason
				<< " -- NO destructive work done; state=CLIENT_DRAIN; retry with /worldreset resume";
			notify(String("[worldreset] Reset paused -- ") + reason
				+ ". No cities/structures were touched. Re-authenticate and run /worldreset resume when clients are clear.");
			return;
		}
	}

	// Let the logout tasks + any active-area exit events settle before PHASE 1
	// disbands the same cities (an in-flight CityRegion::notifyExit racing
	// CityManager::destroyCity() was a prior crash). Bounded, and the queue is
	// empty fast once every client is gone.
	info(true) << "[WORLDRESET][CLIENT_DRAIN] draining logout task backlog";
	drainTaskQueues("after client drain", 90);
	info(true) << "[WORLDRESET][STATE] CLIENT_DRAIN -> CITY_PHASE";

	// The v2 manifest is the ONLY authority for what may be touched. Never re-scan
	// the world for targets -- that could broaden the set or pick up a newly placed
	// structure. It also carries per-target identity metadata (crc/got/owner).
	String manifestFp;
	uint64 armedMs = 0, executeMs = 0;
	Vector<uint64> cityOrder, structOrder;
	VectorMap<uint64, String> meta;

	if (!readManifestV2(manifestFp, armedMs, executeMs, cityOrder, structOrder, meta)) {
		writeStatePhase(PHASE_FAILED, "target manifest missing");
		error("[WORLDRESET][EXECUTE] FAILED -- target manifest missing");
		notify("[worldreset] Reset FAILED -- target manifest missing. Re-run /worldreset dryrun and execute.");
		return;
	}

	VectorMap<uint64, String> prog;
	loadProgressStatus(prog);

	const uint64 t0 = (executeMs > 0) ? executeMs : nowMs();
	auto elapsed = [t0]() -> int { const uint64 n = nowMs(); return (n > t0) ? (int)((n - t0) / 1000) : 0; };

	startStallWatchdog();

	info(true) << "[WORLDRESET][EXECUTE] START" << (resuming ? " (RESUME)" : "")
		<< " fingerprint=" << manifestFp
		<< " manifest: cities=" << cityOrder.size() << " structure+orphan targets=" << structOrder.size()
		<< " progressRecords=" << prog.size();

	int destroyedCities = 0;
	int failedCities = 0;
	int destroyedStructures = 0;
	int failedStructures = 0;
	int verifiedSkipped = 0;
	bool hardAbort = false;
	String abortReason;

	// ==================================================================
	// PHASE 1 - PLAYER CITY DISBAND
	// On resume this normally re-confirms the (already committed) city disband:
	// every city whose OID no longer resolves is logged SKIPPED_VERIFIED, so the
	// pass is idempotent. It also picks up any city the interruption left behind
	// (state was STRUCTURE_PHASE, so PHASE 1 *should* be complete -- this is
	// defence in depth).
	// ==================================================================
	{
		const uint64 p1Start = nowMs();
		writeStatePhase(PHASE_CITIES, resuming ? "city disband (resume re-confirm)" : "city disband");
		info(true) << "[WORLDRESET][PHASE1:CITIES] START" << (resuming ? " (RESUME re-confirm)" : "")
			<< " count=" << cityOrder.size()
			<< " elapsedSinceExecute=" << elapsed() << "s";

		CityManager* cityManager = zoneServer->getCityManager();

		for (int i = 0; i < cityOrder.size() && !hardAbort; ++i) {
			const uint64 oid = cityOrder.get(i);
			hbTouch(oid, "city_disband");

			try {
				Reference<CityRegion*> city = Core::getObjectBroker()->lookUp(oid).castTo<CityRegion*>();

				if (city == nullptr) {
					info(true) << "[WORLDRESET][CITY] OID=" << oid << " already gone -- SKIP";
					progressMark(oid, "SKIPPED_VERIFIED");
					continue;
				}

				if (city->isClientRegion()) {
					hardAbort = true;
					abortReason = String("city OID ") + String::valueOf(oid) + " is now a client region";
					progressMark(oid, "FAILED");
					error() << "[WORLDRESET][CITY] FAILED OID=" << oid << " stage=identity reason=now a client region -- ABORTING";
					break;
				}

				info(true) << "[WORLDRESET][CITY] BEGIN OID=" << oid
					<< " name=\"" << city->getCityRegionName() << "\""
					<< " rank=" << (int)city->getCityRank()
					<< " mayorID=" << city->getMayorID()
					<< " citizens=" << city->getCitizenCount()
					<< " civicStructures=" << city->getStructuresCount()
					<< " treasury=" << (int64)city->getCityTreasury()
					<< " (treasury NOT reimbursed -- staff reimburse manually)";

				cityManager->destroyCity(city);
				progressMark(oid, "REMOVED");
				++destroyedCities;

				// Drain THIS city's async civic-structure / city-hall teardown before
				// disbanding the next one. An exit event still in flight for this
				// city (or a shared worker touching a half-torn region) racing the
				// next destroyCity() is the PHASE 1 crash we keep hitting. Checkpoint
				// so every disband is independently recoverable on resume.
				city = nullptr; // drop our ref before draining
				hbTouch(oid, "city_drain");
				// With every client already gone the scheduler goes quiet in ~3s;
				// this cap is only a ceiling for an unexpectedly busy queue.
				drainTaskQueues("per-city disband", 30);
				hbTouch(oid, "city_checkpoint");
				commitAndCheckpoint("per-city disband");
				writeStatePhase(PHASE_CITIES, String("city disband -- ") + String::valueOf(destroyedCities) + " committed");

				info(true) << "[WORLDRESET][CITY] COMPLETE OID=" << oid;
			} catch (const Exception& e) {
				++failedCities;
				progressMark(oid, "FAILED");
				error() << "[WORLDRESET][CITY] FAILED OID=" << oid << " stage=disband reason=" << e.getMessage();
			} catch (...) {
				++failedCities;
				progressMark(oid, "FAILED");
				error() << "[WORLDRESET][CITY] FAILED OID=" << oid << " stage=disband reason=unknown";
			}
		}

		// destroyCity() dispatches its city-hall / civic-structure destruction onto
		// the task scheduler. With zero non-admin players online those tasks cannot
		// deadlock. Wait for them, then bound the Berkeley transaction.
		hbTouch(0, "drain_after_cities");
		drainTaskQueues("after city disband", 180);
		hbTouch(0, "checkpoint_after_cities");
		commitAndCheckpoint("after PHASE1:CITIES");

		if (hardAbort) {
			writeStatePhase(PHASE_FAILED, abortReason);
			error() << "[WORLDRESET][EXECUTE] FAILED -- " << abortReason << " (state=FAILED; run /worldreset recoverycheck)";
			notify(String("[worldreset] Reset FAILED -- ") + abortReason + ". State=FAILED; run /worldreset recoverycheck.");
			return;
		}

		info(true) << "[WORLDRESET][PHASE1:CITIES] COMPLETE removed=" << destroyedCities << " failed=" << failedCities
			<< " elapsed=" << (int)((nowMs() - p1Start) / 1000) << "s"
			<< " elapsedSinceExecute=" << elapsed() << "s";
	}

	// ==================================================================
	// PHASE 3 - PLAYER STRUCTURES + ORPHANED RECORDS
	// Targets come ONLY from the manifest. Each removal is idempotent and its
	// identity is verified against the manifest metadata (fail closed on change).
	// ==================================================================
	const uint64 p3Start = nowMs();
	writeStatePhase(PHASE_STRUCTURES, resuming ? "structure removal (resume)" : "structure removal");
	info(true) << "[WORLDRESET][PHASE3:STRUCTURES] START targets=" << structOrder.size()
		<< " elapsedSinceExecute=" << elapsed() << "s";

	int sinceCommit = 0;
	int batchNo = 1;
	uint64 batchStart = nowMs();
	uint64 batchFirstOID = structOrder.isEmpty() ? 0 : structOrder.get(0);
	int batchCount = 0;
	hbBatch(batchNo);
	info(true) << "[WORLDRESET][BATCH] BEGIN batch=" << batchNo << " firstOID=" << batchFirstOID;

	for (int i = 0; i < structOrder.size() && !hardAbort; ++i) {
		const uint64 oid = structOrder.get(i);

		// expected identity from the manifest
		String mKind, mCategory;
		uint32 mCrc = 0;
		int mGot = -1;
		uint64 mOwner = 0;
		parseTargetMeta(meta.get(oid), mKind, mCategory, mCrc, mGot, mOwner);

		const String priorStatus = prog.get(oid);

		// Guard: never touch a building that has a pending pack payload.
		if (HousePackupManager::instance()->hasSavedPayloadForBuilding(oid)) {
			hardAbort = true;
			abortReason = String("manifest target ") + String::valueOf(oid) + " now has a pending pack payload";
			progressMark(oid, "FAILED");
			error() << "[WORLDRESET][TARGET] FAILED OID=" << oid << " stage=guard reason=pending pack payload -- ABORTING (fail closed)";
			break;
		}

		info(true) << "[WORLDRESET][TARGET] BEGIN OID=" << oid << " kind=" << (mKind.isEmpty() ? String("S") : mKind)
			<< " category=" << (mCategory.isEmpty() ? String("?") : mCategory)
			<< " expectCrc=" << mCrc << " expectGot=" << mGot << " expectOwner=" << mOwner
			<< (priorStatus.isEmpty() ? String("") : (String(" priorStatus=") + priorStatus));

		if (priorStatus != "REMOVED")
			progressMark(oid, "IN_PROGRESS");

		String failStage, infoOut;
		bool ok = false;

		try {
			ok = wrMaintenanceDestroyStructure(this, zoneServer, oid, mCrc, mGot, mOwner, failStage, infoOut);
		} catch (const Exception& e) {
			failStage = "exception";
			infoOut = e.getMessage();
		} catch (...) {
			failStage = "exception";
			infoOut = "unknown";
		}

		++batchCount;

		if (ok && infoOut == "already gone") {
			++verifiedSkipped;
			progressMark(oid, "SKIPPED_VERIFIED");
			info(true) << "[WORLDRESET][TARGET] COMPLETE OID=" << oid << " -- already absent (idempotent)";
		} else if (ok) {
			++destroyedStructures;
			progressMark(oid, "REMOVED");
			info(true) << "[WORLDRESET][TARGET] COMPLETE OID=" << oid << "  " << infoOut
				<< "  stage=lock->owner_cleanup->world_remove->db_remove all done";
		} else if (failStage == "identity") {
			hardAbort = true;
			abortReason = String("manifest target ") + String::valueOf(oid) + " changed identity: " + infoOut;
			progressMark(oid, "FAILED");
			error() << "[WORLDRESET][TARGET] FAILED OID=" << oid << " stage=identity reason=" << infoOut << " -- ABORTING (fail closed)";
			break;
		} else {
			++failedStructures;
			progressMark(oid, "FAILED");
			error() << "[WORLDRESET][TARGET] FAILED OID=" << oid << " stage=" << failStage << " reason=" << infoOut
				<< " -- skipping this target, continuing";
		}

		if (++sinceCommit >= 50) {
			sinceCommit = 0;
			hbTouch(oid, "batch_commit");
			info(true) << "[WORLDRESET][BATCH] COMMIT batch=" << batchNo << " count=" << batchCount
				<< " (destroyed=" << destroyedStructures << " skippedVerified=" << verifiedSkipped
				<< " failed=" << failedStructures << ")";
			commitAndCheckpoint("structure batch");
			info(true) << "[WORLDRESET][BATCH] CHECKPOINT COMPLETE batch=" << batchNo
				<< " elapsed=" << (int)((nowMs() - batchStart) / 1000) << "s"
				<< " elapsedSinceExecute=" << elapsed() << "s";
			info(true) << "[WORLDRESET][BATCH] END batch=" << batchNo;
			writeStatePhase(PHASE_STRUCTURES, String("structure removal -- batch ") + String::valueOf(batchNo)
				+ " committed, destroyed=" + String::valueOf(destroyedStructures));
			++batchNo;
			batchStart = nowMs();
			batchCount = 0;
			batchFirstOID = (i + 1 < structOrder.size()) ? structOrder.get(i + 1) : 0;
			hbBatch(batchNo);
			info(true) << "[WORLDRESET][BATCH] BEGIN batch=" << batchNo << " firstOID=" << batchFirstOID;
		}
	}

	hbTouch(0, "drain_after_structures");
	drainTaskQueues("after structures", 180);
	hbTouch(0, "checkpoint_after_structures");
	commitAndCheckpoint("after PHASE3:STRUCTURES");
	// flush the final (partial) batch's counters to the state note
	if (batchCount > 0) {
		info(true) << "[WORLDRESET][BATCH] COMMIT batch=" << batchNo << " count=" << batchCount << " (final partial)";
		info(true) << "[WORLDRESET][BATCH] END batch=" << batchNo;
	}

	if (hardAbort) {
		writeStatePhase(PHASE_FAILED, abortReason);
		error() << "[WORLDRESET][EXECUTE] FAILED -- " << abortReason
			<< " (state=FAILED; committed progress is intact; run /worldreset recoverycheck)";
		notify(String("[worldreset] Reset FAILED -- ") + abortReason + ". State=FAILED; run /worldreset recoverycheck.");
		return;
	}

	info(true) << "[WORLDRESET][PHASE3:STRUCTURES] COMPLETE destroyed=" << destroyedStructures
		<< " skippedVerified=" << verifiedSkipped
		<< " failed=" << failedStructures
		<< " elapsed=" << (int)((nowMs() - p3Start) / 1000) << "s"
		<< " elapsedSinceExecute=" << elapsed() << "s";

	// ==================================================================
	// PHASE 7 - FINAL VALIDATION
	// ==================================================================
	writeStatePhase(PHASE_VALIDATION, "post-reset validation");
	info(true) << "[WORLDRESET][PHASE7:VALIDATION] START";

	int failedStructuresFinal = failedStructures;

	DryRunCounts after;
	SortedVector<uint64> afterCity, afterStruct, afterOrphan;
	collectSnapshot(zoneServer, admin, after, false, afterCity, afterStruct, afterOrphan);

	// Read-only audit of playerstructures.db vs its Berkeley secondary index
	// (playerstructuresindex.db). This is the existing Core3 validation routine and
	// mutates nothing; results are written to the server log.
	try {
		const String indexSummary = StructureManager::instance()->validatePlayerStructureZoneIndex(true, true);
		info(true) << "[WORLDRESET][VALIDATION] player-structure index audit:\n" << indexSummary;
	} catch (...) {
		warning("[WORLDRESET][VALIDATION] player-structure index audit threw -- inspect manually");
	}

	info(true) << "[WORLDRESET][VALIDATION] post-reset snapshot -- "
		<< "playerCities=" << after.playerCities
		<< " cityHalls=" << after.cityHalls
		<< " civicStructures=" << after.civicStructures
		<< " deployedHouses=" << after.deployedHouses
		<< " installations=" << after.installations
		<< " factories=" << after.factories
		<< " harvesters=" << after.harvesters
		<< " generators=" << after.generators
		<< " otherDeployed=" << after.otherDeployedStructures
		<< " orphanStructures=" << after.orphanStructures
		<< " unreadableStructureRecords=" << after.unreadableStructureRecords
		<< " unreadableCityRecords=" << after.unreadableCityRecords
		<< " packedDeedsExcluded(preserved)=" << after.packedDeedsExcluded
		<< " packedPendingRedeem=" << after.packedPendingRedeem;

	const int remainingTargets = after.playerCities + after.deployedHouses + after.installations
		+ after.factories + after.harvesters + after.generators + after.otherDeployedStructures
		+ after.orphanStructures;

	const bool phasesOk = (failedCities == 0 && failedStructuresFinal == 0);
	const bool clean = (remainingTargets == 0);

	commitAndCheckpoint("final");

	if (phasesOk && clean) {
		writeStatePhase(PHASE_COMPLETE, resuming ? "clean (resumed)" : "clean");
	} else if (phasesOk) {
		writeStatePhase(PHASE_COMPLETE, "completed with residual records -- review log");
	} else {
		writeStatePhase(PHASE_FAILED, String("phase failures: cities=") + String::valueOf(failedCities)
			+ " structures=" + String::valueOf(failedStructuresFinal) + "; committed progress intact -- run /worldreset recoverycheck");
	}

	if (phasesOk && clean) {
		// nothing left -- the manifest + progress log have served their purpose
		std::remove(manifestFilePath());
		std::remove(progressFilePath());
	}

	info(true) << "[WORLDRESET][PHASE7:VALIDATION] COMPLETE playerCities=" << after.playerCities
		<< " deployedStructures=" << (after.deployedHouses + after.installations + after.factories
			+ after.harvesters + after.generators + after.otherDeployedStructures)
		<< " orphanStructures=" << after.orphanStructures
		<< " unreadableStructureRecords=" << after.unreadableStructureRecords
		<< " unreadableCityRecords=" << after.unreadableCityRecords
		<< " packedDeedsPreserved=" << after.packedDeedsExcluded
		<< " gcwBasesExcluded=" << after.gcwBasesExcluded
		<< " staticCitiesExcluded=" << after.staticCitiesExcluded;

	info(true) << "[WORLDRESET][EXECUTE] "
		<< (phasesOk ? (clean ? "COMPLETE SUCCESS" : "COMPLETE (residual records remain -- review log)") : "FAILED")
		<< " -- citiesDestroyed=" << destroyedCities << " citiesFailed=" << failedCities
		<< " structuresDestroyed=" << destroyedStructures
		<< " structuresSkippedVerified=" << verifiedSkipped
		<< " structuresFailed=" << failedStructuresFinal
		<< " remainingTargets=" << remainingTargets
		<< " totalElapsed=" << elapsed() << "s";

	StringBuffer summary;
	summary << "[worldreset] EXECUTE "
		<< (phasesOk ? (clean ? "COMPLETE SUCCESS" : "COMPLETE (residual records remain -- review log)") : "FAILED") << "\n"
		<< "  Cities destroyed: " << destroyedCities << " (failed: " << failedCities << ")\n"
		<< "  Structures destroyed: " << destroyedStructures << "\n"
		<< "  Structures already absent / verified: " << verifiedSkipped << "\n"
		<< "  Per-target failures (skipped): " << failedStructuresFinal << "\n"
		<< "  Post-reset remaining reset-targets: " << remainingTargets << "\n"
		<< "  Packed houses (deed form) preserved: " << after.packedDeedsExcluded << "\n"
		<< "  Non-structure records preserved (event perks etc.): " << after.nonStructureRecordsExcluded << "\n"
		<< "  Total elapsed: " << elapsed() << "s\n"
		<< (phasesOk && clean ? "  Run /worldreset dryrun to re-verify." : "  Run /worldreset recoverycheck for a per-target report.");

	notify(summary.toString());
}
