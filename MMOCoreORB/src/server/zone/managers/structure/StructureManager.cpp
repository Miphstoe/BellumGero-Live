/*
 * StructureManager.cpp
 *
 *  Created on: 01/08/2012
 *      Author: swgemu
 */

#include "StructureManager.h"
#include "engine/db/IndexDatabase.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "conf/ConfigManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "server/zone/managers/gcw/GCWManager.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "templates/tangible/SharedStructureObjectTemplate.h"
#include "templates/building/SharedBuildingObjectTemplate.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/area/ActiveArea.h"
#include "server/zone/objects/tangible/deed/structure/StructureDeed.h"
#include "server/zone/objects/region/Region.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/player/sessions/PlaceStructureSession.h"
#include "server/zone/objects/player/sessions/DestroyStructureSession.h"
#include "terrain/manager/TerrainManager.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/transferbox/SuiTransferBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/sui/callbacks/StructurePayUncondemnMaintenanceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/FindLostItemsSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DeleteAllItemsSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/StructureStatusSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/StructureAssignDroidSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/NameStructureSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/StructurePayMaintenanceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/RemoteStructurePayMaintenanceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/RemoteStructureAddPowerSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/StructureWithdrawMaintenanceSuiCallback.h"
#include "server/login/account/AccountManager.h"
#include "server/login/account/Account.h"
#include "server/zone/objects/player/sui/callbacks/ViewHouseStorageSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/StructureSelectSignSuiCallback.h"
#include "server/zone/managers/stringid/StringIdManager.h"
#include "terrain/layer/boundaries/BoundaryRectangle.h"
#include "tasks/DestroyStructureTask.h"
#include "server/zone/objects/intangible/PetControlDevice.h"
#include "server/zone/managers/creature/PetManager.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/installation/harvester/HarvesterObject.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/login/account/AccountManager.h"
#include "server/login/account/Account.h"
#include "templates/faction/Factions.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "templates/building/CampStructureTemplate.h"
#include "templates/customization/CustomizationIdManager.h"
#include "server/zone/managers/housepackup/HousePackupManager.h" // add at top of StructureManager.cpp
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/callbacks/ArchitectRetrofitSuiCallback.h"

#include "system/io/ObjectInputStream.h"
#include "system/io/ObjectOutputStream.h"

#include <cstdio>
#include <sys/stat.h>

#include <mutex>
#include <unordered_set>

namespace StorageManagerNamespace {
constexpr int MAX_ZONE_INDEX_DETAIL_LOGS = 50;

uint64 getPrimaryOIDFromKey(const DBT* key) {
	if (key == nullptr || key->data == nullptr || key->size != sizeof(uint64))
		return 0;

	return *reinterpret_cast<const uint64*>(key->data);
}

void logZoneIndexWarning(const String& message, AtomicInteger& counter) {
	int count = counter.increment();

	if (count <= MAX_ZONE_INDEX_DETAIL_LOGS) {
		Logger::console.warning(message);
	} else if (count == MAX_ZONE_INDEX_DETAIL_LOGS + 1) {
		Logger::console.warning("PLAYERSTRUCTURE-ZONE-MISSING: additional malformed player structure index records suppressed");
	}
}

int indexCallback(DB* secondary, const DBT* key, const DBT* data, DBT* result) {
	memset(result, 0, sizeof(DBT));

	ObjectInputStream objectData;

	LocalDatabase::uncompress(data->data, data->size, &objectData);

	String zoneReference;

	if (!Serializable::getVariable<String>(STRING_HASHCODE("SceneObject.zone"), &zoneReference, &objectData)) {
		static AtomicInteger missingZoneLogCount;
		uint64 objectID = getPrimaryOIDFromKey(key);
		StringBuffer message;

		message << "PLAYERSTRUCTURE-ZONE-MISSING: OID ";
		message << (objectID != 0 ? String::valueOf(objectID) : String("<unknown>"));
		message << " has no persisted SceneObject.zone; excluding from secondary planet index";

		logZoneIndexWarning(message.toString(), missingZoneLogCount);

		return DB_DONOTINDEX;
	} else if (zoneReference.isEmpty()) {
		static AtomicInteger emptyZoneLogCount;
		uint64 objectID = getPrimaryOIDFromKey(key);
		StringBuffer message;

		message << "PLAYERSTRUCTURE-ZONE-MISSING: OID ";
		message << (objectID != 0 ? String::valueOf(objectID) : String("<unknown>"));
		message << " has an empty persisted SceneObject.zone; excluding from secondary planet index";

		logZoneIndexWarning(message.toString(), emptyZoneLogCount);

		return DB_DONOTINDEX;
	} else {
		auto data = (uint64*)malloc(sizeof(uint64)); // same size as an oid
		*data = zoneReference.hashCode();

		result->data = data;
		result->size = sizeof(uint64);

		result->flags = DB_DBT_APPMALLOC;

		// Logger::console.info("setting new key " + String::valueOf(*data) + " in associate callback", true);
	}

	return 0;
}



// BELLUM_GERO_STRUCTURE_RECOVERY_BUILD1
constexpr const char* STRUCTURE_RECOVERY_ROOT_DIR =
	"structure_integrity";
constexpr const char* STRUCTURE_RECOVERY_PENDING_HIGH_PLAN =
	"structure_integrity/pending_high_confidence_recovery_v1.txt";
constexpr const char* STRUCTURE_RECOVERY_PENDING_HIGH_PLAN_TMP =
	"structure_integrity/pending_high_confidence_recovery_v1.txt.tmp";

int getSerializedVariableDataOffsetForStructureRecovery(
		const uint32& variableHashCode, ObjectInputStream* stream) {
	if (stream == nullptr)
		return -1;

	stream->reset();
	uint16 variableCount = stream->readShort();

	for (int i = 0; i < variableCount; ++i) {
		uint32 nameHashCode = stream->readInt();
		uint32 variableSize = stream->readInt();
		int dataOffset = stream->getOffset();

		if (nameHashCode == variableHashCode) {
			stream->reset();
			return dataOffset;
		}

		stream->shiftOffset(variableSize);
	}

	stream->reset();
	return -1;
}

ObjectOutputStream* replaceSerializedVariableDataForStructureRecovery(
		const uint32& variableHashCode,
		ObjectInputStream* objectData,
		Stream* replacementData) {
	if (objectData == nullptr || replacementData == nullptr)
		return nullptr;

	int offset =
		getSerializedVariableDataOffsetForStructureRecovery(
			variableHashCode, objectData);

	if (offset == -1)
		return nullptr;

	ObjectOutputStream* newData =
		new ObjectOutputStream(objectData->size());

	objectData->copy(newData);

	objectData->reset();
	newData->reset();

	objectData->shiftOffset(offset - 4);
	uint32 oldDataSize = objectData->readInt();

	newData->shiftOffset(offset);

	if (oldDataSize > 0)
		newData->removeRange(offset, offset + oldDataSize);

	newData->writeInt(offset - 4, replacementData->size());
	newData->insertStream(replacementData, replacementData->size(), offset);

	objectData->reset();
	newData->reset();

	return newData;
}

ObjectOutputStream* addSerializedVariableDataForStructureRecovery(
		const String& variableName,
		ObjectInputStream* objectData,
		Stream* variableData) {
	if (objectData == nullptr || variableData == nullptr)
		return nullptr;

	objectData->reset();

	uint16 oldVariableCount = objectData->readShort();

	ObjectOutputStream* newData =
		new ObjectOutputStream(
			objectData->size() + variableData->size() + 16);

	objectData->reset();
	objectData->copy(newData, 0);

	newData->writeShort(0, oldVariableCount + 1);
	newData->setOffset(newData->size());

	uint32 variableHashCode = variableName.hashCode();
	TypeInfo<uint32>::toBinaryStream(&variableHashCode, newData);
	newData->writeInt(variableData->size());
	newData->writeStream(variableData);

	newData->reset();
	objectData->reset();

	return newData;
}


// BELLUM_GERO_STRUCTURE_RECOVERY_FOOTPRINT_GUARD_BUILD2_PRECISE_RECT
// Recovery safety gate for historical structure recovery.
//
// Automatic recovery is allowed only when the damaged structure's original
// footprint is clear of every other persistent player structure on the same
// planet.
//
// Unlike BUILD1, this uses each structure's persisted SceneObject.direction
// quaternion and the existing StructureManager::getStructureFootprint() math.
// SceneObject::getDirectionAngle() itself returns direction.getDegrees(), so
// this reproduces the same angle convention used by normal structure placement.
//
// This helper is read-only. It never changes playerstructures.db.
enum RecoveryFootprintStatus {
	RECOVERY_FOOTPRINT_CLEAR = 0,
	RECOVERY_FOOTPRINT_OCCUPIED = 1,
	RECOVERY_FOOTPRINT_INDETERMINATE = 2
};

struct RecoveryFootprintCheckResult {
	int status = RECOVERY_FOOTPRINT_INDETERMINATE;
	String reason = "FOOTPRINT_CHECK_NOT_RUN";
	uint64 conflictingObjectID = 0;
	String conflictingTemplate = "";
	float conflictingX = 0.0f;
	float conflictingY = 0.0f;
};

String resolveGroundZoneFromRecoveryWaypoint(
		ZoneServer* server,
		WaypointObject* waypoint) {
	if (server == nullptr || waypoint == nullptr)
		return "";

	const uint32 planetCRC = waypoint->getPlanetCRC();

	for (int i = 0; i < server->getZoneCount(); ++i) {
		Zone* candidateZone = server->getZone(i);

		if (candidateZone != nullptr &&
				!candidateZone->isSpaceZone() &&
				candidateZone->getZoneCRC() == planetCRC) {
			return candidateZone->getZoneName();
		}
	}

	return "";
}

int recoveryDirectionToPlacementAngle(const Quaternion& direction) {
	// Match normal Core3 placement semantics exactly. SceneObject's
	// getDirectionAngle() returns a float, while getStructureFootprint()
	// accepts an int, so the normal call path truncates toward zero.
	int angle = (int)direction.getDegrees();

	angle %= 360;

	if (angle < 0)
		angle += 360;

	return angle;
}

bool buildRecoveryFootprintRectangle(
		StructureManager* structureManager,
		SharedStructureObjectTemplate* structureTemplate,
		const Quaternion& direction,
		float centerX,
		float centerY,
		float& x0,
		float& y0,
		float& x1,
		float& y1) {
	if (structureManager == nullptr || structureTemplate == nullptr)
		return false;

	float l0 = 0.0f;
	float w0 = 0.0f;
	float l1 = 0.0f;
	float w1 = 0.0f;

	const int angle = recoveryDirectionToPlacementAngle(direction);

	if (structureManager->getStructureFootprint(
			structureTemplate, angle, l0, w0, l1, w1) != 0) {
		return false;
	}

	x0 = centerX + w0;
	y0 = centerY + l0;
	x1 = centerX + w1;
	y1 = centerY + l1;

	if (x0 > x1) {
		float temp = x0;
		x0 = x1;
		x1 = temp;
	}

	if (y0 > y1) {
		float temp = y0;
		y0 = y1;
		y1 = temp;
	}

	return x1 > x0 && y1 > y0;
}

bool recoveryFootprintRectanglesOverlap(
		float ax0,
		float ay0,
		float ax1,
		float ay1,
		float bx0,
		float by0,
		float bx1,
		float by1) {
	// Match normal placement's edge tolerance: merely touching edges should
	// not count as an occupied footprint. Require a small positive overlap.
	const float overlapEpsilon = 0.1f;

	const float overlapX =
		Math::min(ax1, bx1) - Math::max(ax0, bx0);
	const float overlapY =
		Math::min(ay1, by1) - Math::max(ay0, by0);

	return overlapX > overlapEpsilon && overlapY > overlapEpsilon;
}

RecoveryFootprintCheckResult checkRecoveryFootprintAvailability(
		StructureManager* structureManager,
		ZoneServer* server,
		TemplateManager* templateManager,
		ObjectDatabase* structureDatabase,
		uint64 targetObjectID,
		SharedStructureObjectTemplate* targetTemplate,
		const String& expectedZone,
		WaypointObject* targetWaypoint) {
	RecoveryFootprintCheckResult result;

	if (structureManager == nullptr ||
			server == nullptr ||
			templateManager == nullptr ||
			structureDatabase == nullptr ||
			targetObjectID == 0 ||
			targetTemplate == nullptr ||
			expectedZone.isEmpty() ||
			targetWaypoint == nullptr) {
		result.reason = "RECOVERY_LOCATION_EVIDENCE_INCOMPLETE";
		return result;
	}

	const String targetWaypointZone =
		resolveGroundZoneFromRecoveryWaypoint(server, targetWaypoint);

	if (targetWaypointZone.isEmpty() || targetWaypointZone != expectedZone) {
		result.reason = "TARGET_WAYPOINT_ZONE_MISMATCH";
		return result;
	}

	ObjectInputStream targetData(2000);

	if (structureDatabase->getData(targetObjectID, &targetData)) {
		result.reason = "TARGET_PERSISTENT_RECORD_UNAVAILABLE";
		return result;
	}

	Quaternion targetDirection;

	try {
		if (!Serializable::getVariable<Quaternion>(
				STRING_HASHCODE("SceneObject.direction"),
				&targetDirection,
				&targetData)) {
			result.reason = "TARGET_DIRECTION_UNAVAILABLE";
			return result;
		}
	} catch (...) {
		result.reason = "TARGET_DIRECTION_UNREADABLE";
		return result;
	}

	const float targetX = targetWaypoint->getPositionX();
	const float targetY = targetWaypoint->getPositionY();

	float targetX0 = 0.0f;
	float targetY0 = 0.0f;
	float targetX1 = 0.0f;
	float targetY1 = 0.0f;

	if (!buildRecoveryFootprintRectangle(
			structureManager,
			targetTemplate,
			targetDirection,
			targetX,
			targetY,
			targetX0,
			targetY0,
			targetX1,
			targetY1)) {
		result.reason = "TARGET_FOOTPRINT_UNAVAILABLE";
		return result;
	}

	berkeley::CursorConfig config;
	config.setReadUncommitted(true);

	ObjectDatabaseIterator iterator(structureDatabase, config);
	ObjectInputStream otherData(2000);
	uint64 otherObjectID = 0;

	while (iterator.getNextKeyAndValue(otherObjectID, &otherData)) {
		if (otherObjectID == targetObjectID) {
			otherData.reset();
			continue;
		}

		String otherPersistedZone;
		uint32 otherCRC = 0;
		uint64 otherWaypointID = 0;
		Quaternion otherDirection;
		bool hasOtherZone = false;
		bool hasOtherDirection = false;

		try {
			Serializable::getVariable<uint32>(
				STRING_HASHCODE("SceneObject.serverObjectCRC"),
				&otherCRC, &otherData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.waypointID"),
				&otherWaypointID, &otherData);
			hasOtherZone = Serializable::getVariable<String>(
				STRING_HASHCODE("SceneObject.zone"),
				&otherPersistedZone, &otherData);
			hasOtherDirection = Serializable::getVariable<Quaternion>(
				STRING_HASHCODE("SceneObject.direction"),
				&otherDirection, &otherData);
		} catch (...) {
			result.reason = "OTHER_PERSISTENT_STRUCTURE_UNREADABLE";
			result.conflictingObjectID = otherObjectID;
			otherData.reset();
			return result;
		}

		ManagedReference<WaypointObject*> otherWaypoint = nullptr;
		String otherResolvedZone;

		if (hasOtherZone && !otherPersistedZone.isEmpty()) {
			Zone* persistedZoneObject = server->getZone(otherPersistedZone);

			if (persistedZoneObject != nullptr &&
					!persistedZoneObject->isSpaceZone()) {
				otherResolvedZone = otherPersistedZone;
			}
		}

		if (otherResolvedZone.isEmpty() && otherWaypointID != 0) {
			otherWaypoint =
				server->getObject(otherWaypointID).castTo<WaypointObject*>();

			if (otherWaypoint != nullptr) {
				otherResolvedZone =
					resolveGroundZoneFromRecoveryWaypoint(
						server, otherWaypoint);
			}
		}

		if (otherResolvedZone.isEmpty()) {
			result.reason = "OTHER_PERSISTENT_STRUCTURE_ZONE_UNRESOLVED";
			result.conflictingObjectID = otherObjectID;
			otherData.reset();
			return result;
		}

		if (otherResolvedZone != expectedZone) {
			otherData.reset();
			continue;
		}

		if (otherWaypoint == nullptr && otherWaypointID != 0) {
			otherWaypoint =
				server->getObject(otherWaypointID).castTo<WaypointObject*>();
		}

		if (otherWaypoint == nullptr) {
			result.reason = "SAME_PLANET_STRUCTURE_WAYPOINT_UNAVAILABLE";
			result.conflictingObjectID = otherObjectID;
			otherData.reset();
			return result;
		}

		Reference<SharedStructureObjectTemplate*> otherTemplate =
			dynamic_cast<SharedStructureObjectTemplate*>(
				templateManager->getTemplate(otherCRC));

		// BELLUM_GERO_STRUCTURE_RECOVERY_FOOTPRINT_GUARD_BUILD21_SKIP_NONCOLLIDING_STALE
		//
		// Match normal Core3 placement collision semantics. Nearby objects that
		// cannot resolve to SharedStructureObjectTemplate / StructureFootprint
		// are ignored by the normal structure placement collision loop.
		//
		// A stale/unloadable playerstructures record must therefore not poison an
		// otherwise safe recovery candidate simply because it cannot participate
		// in normal structure-footprint collision checks.
		if (otherTemplate == nullptr ||
				otherTemplate->getStructureFootprint() == nullptr) {
			otherData.reset();
			continue;
		}

		// Once the record is confirmed to be a real footprint-bearing structure,
		// fail closed if its persisted orientation cannot be reconstructed.
		if (!hasOtherDirection) {
			result.reason = "SAME_PLANET_STRUCTURE_DIRECTION_UNAVAILABLE";
			result.conflictingObjectID = otherObjectID;
			result.conflictingTemplate =
				otherTemplate->getFullTemplateString();
			result.conflictingX = otherWaypoint->getPositionX();
			result.conflictingY = otherWaypoint->getPositionY();
			otherData.reset();
			return result;
		}

		const float otherX = otherWaypoint->getPositionX();
		const float otherY = otherWaypoint->getPositionY();

		float otherX0 = 0.0f;
		float otherY0 = 0.0f;
		float otherX1 = 0.0f;
		float otherY1 = 0.0f;

		if (!buildRecoveryFootprintRectangle(
				structureManager,
				otherTemplate,
				otherDirection,
				otherX,
				otherY,
				otherX0,
				otherY0,
				otherX1,
				otherY1)) {
			result.reason = "SAME_PLANET_STRUCTURE_FOOTPRINT_UNAVAILABLE";
			result.conflictingObjectID = otherObjectID;
			result.conflictingTemplate =
				otherTemplate->getFullTemplateString();
			result.conflictingX = otherX;
			result.conflictingY = otherY;
			otherData.reset();
			return result;
		}

		if (recoveryFootprintRectanglesOverlap(
				targetX0,
				targetY0,
				targetX1,
				targetY1,
				otherX0,
				otherY0,
				otherX1,
				otherY1)) {
			result.status = RECOVERY_FOOTPRINT_OCCUPIED;
			result.reason = "RECOVERY_FOOTPRINT_OCCUPIED";
			result.conflictingObjectID = otherObjectID;
			result.conflictingTemplate =
				otherTemplate->getFullTemplateString();
			result.conflictingX = otherX;
			result.conflictingY = otherY;
			otherData.reset();
			return result;
		}

		otherData.reset();
	}

	result.status = RECOVERY_FOOTPRINT_CLEAR;
	result.reason = "RECOVERY_FOOTPRINT_CLEAR";
	return result;
}

} // namespace StorageManagerNamespace

namespace StructureWorldRemovalGuardNamespace {
std::mutex authorizationMutex;
std::unordered_set<uint64> authorizedObjectIDs;
} // namespace StructureWorldRemovalGuardNamespace

StructureManager::StructureManager() : Logger("StructureManager") {
	server = nullptr;
	templateManager = TemplateManager::instance();

	setGlobalLogging(true);
	setLogging(false);
}

// BELLUM_GERO_STRUCTURE_WORLD_REMOVAL_GUARD_BUILD32A_EXTERNAL_AUTH
// Process-local authorization only. No generated/serialized object layout changes.
void StructureManager::authorizePersistentStructureWorldRemoval(StructureObject* structureObject) {
	if (structureObject == nullptr)
		return;

	std::lock_guard<std::mutex> guard(StructureWorldRemovalGuardNamespace::authorizationMutex);
	StructureWorldRemovalGuardNamespace::authorizedObjectIDs.insert(structureObject->getObjectID());
}

bool StructureManager::isPersistentStructureWorldRemovalAuthorized(StructureObject* structureObject) const {
	if (structureObject == nullptr)
		return false;

	std::lock_guard<std::mutex> guard(StructureWorldRemovalGuardNamespace::authorizationMutex);
	return StructureWorldRemovalGuardNamespace::authorizedObjectIDs.find(structureObject->getObjectID()) !=
		StructureWorldRemovalGuardNamespace::authorizedObjectIDs.end();
}

bool StructureManager::consumePersistentStructureWorldRemovalAuthorization(StructureObject* structureObject) {
	if (structureObject == nullptr)
		return false;

	std::lock_guard<std::mutex> guard(StructureWorldRemovalGuardNamespace::authorizationMutex);
	auto it = StructureWorldRemovalGuardNamespace::authorizedObjectIDs.find(structureObject->getObjectID());

	if (it == StructureWorldRemovalGuardNamespace::authorizedObjectIDs.end())
		return false;

	StructureWorldRemovalGuardNamespace::authorizedObjectIDs.erase(it);
	return true;
}

void StructureManager::clearPersistentStructureWorldRemovalAuthorization(StructureObject* structureObject) {
	if (structureObject == nullptr)
		return;

	std::lock_guard<std::mutex> guard(StructureWorldRemovalGuardNamespace::authorizationMutex);
	StructureWorldRemovalGuardNamespace::authorizedObjectIDs.erase(structureObject->getObjectID());
}

int StructureManager::getAccountLotCap() const {
	// Central account-wide lot cap. Keep this here so later config changes are localized.
	return 100;
}

int StructureManager::getAccountLotCap(CreatureObject* creature) const {
	if (creature == nullptr)
		return getAccountLotCap();

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return getAccountLotCap();

	return getAccountLotCap(ghost->getAccountID());
}

int StructureManager::getAccountLotCap(uint32 accountID) const {
	int lotCap = getAccountLotCap();

	if (accountID == 0 || server == nullptr)
		return lotCap;

	ManagedReference<Account*> account = AccountManager::getAccount(accountID);

	if (account == nullptr)
		return lotCap;

	GalaxyAccountInfo* galaxyInfo = account->getGalaxyAccountInfo(server->getGalaxyName());

	if (galaxyInfo != nullptr) {
		lotCap += galaxyInfo->getExtraCharacterSlots() * 10;
	}

	return lotCap;
}

int StructureManager::getAccountLotsUsed(CreatureObject* creature) const {
	if (creature == nullptr)
		return 0;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return 0;

	return getAccountLotsUsed(ghost->getAccountID());
}

int StructureManager::getAccountLotsUsed(uint32 accountID) const {
	if (server == nullptr || accountID == 0)
		return 0;

	ManagedReference<Account*> account = AccountManager::getAccount(accountID);

	if (account == nullptr)
		return 0;

	Reference<CharacterList*> characters = account->getCharacterList();

	if (characters == nullptr)
		return 0;

	SortedVector<uint64> accountCharacterIDs;
	accountCharacterIDs.setNoDuplicateInsertPlan();
	SortedVector<uint64> onlineCharacterIDs;
	onlineCharacterIDs.setNoDuplicateInsertPlan();

	const uint32 galaxyID = server->getGalaxyID();
	int totalLotsUsed = 0;

	for (int i = 0; i < characters->size(); ++i) {
		const CharacterListEntry& entry = characters->get(i);

		if (entry.getGalaxyID() != galaxyID)
			continue;

		const uint64 characterID = entry.getObjectID();
		accountCharacterIDs.put(characterID);

		ManagedReference<CreatureObject*> creature = server->getObject(characterID).castTo<CreatureObject*>();

		if (creature == nullptr || !creature->isPlayerCreature())
			continue;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr || !ghost->isOnline())
			continue;

		onlineCharacterIDs.put(characterID);

		for (int j = 0; j < ghost->getTotalOwnedStructureCount(); ++j) {
			ManagedReference<StructureObject*> structure = server->getObject(ghost->getOwnedStructure(j)).castTo<StructureObject*>();

			if (structure != nullptr)
				totalLotsUsed += structure->getLotSize();
		}
	}

	if (accountCharacterIDs.isEmpty())
		return 0;

	if (onlineCharacterIDs.size() == accountCharacterIDs.size())
		return totalLotsUsed;

	ObjectDatabase* structureDatabase = ObjectDatabaseManager::instance()->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr)
		return totalLotsUsed;

	ObjectDatabaseIterator iterator(structureDatabase);
	ObjectInputStream objectData(2000);
	uint64 structureID = 0;

	while (iterator.getNextKeyAndValue(structureID, &objectData)) {
		uint64 ownerID = 0;
		uint32 serverObjectCRC = 0;

		try {
			if (!Serializable::getVariable<uint64>(STRING_HASHCODE("StructureObject.ownerObjectID"), &ownerID, &objectData) ||
			    !Serializable::getVariable<uint32>(STRING_HASHCODE("SceneObject.serverObjectCRC"), &serverObjectCRC, &objectData)) {
				objectData.reset();
				continue;
			}
		} catch (...) {
			objectData.reset();
			continue;
		}

		if (!accountCharacterIDs.contains(ownerID) || onlineCharacterIDs.contains(ownerID)) {
			objectData.reset();
			continue;
		}

		Reference<SharedStructureObjectTemplate*> structureTemplate =
			dynamic_cast<SharedStructureObjectTemplate*>(templateManager->getTemplate(serverObjectCRC));

		if (structureTemplate != nullptr)
			totalLotsUsed += structureTemplate->getLotSize();

		objectData.reset();
	}

	return totalLotsUsed;
}

int StructureManager::getAccountLotsRemaining(CreatureObject* creature) const {
	return getAccountLotCap(creature) - getAccountLotsUsed(creature);
}

IndexDatabase* StructureManager::createSubIndex() {
	static auto initialized = [this]() -> IndexDatabase* { // this needs to run only once
		auto dbManager = ObjectDatabaseManager::instance();

		auto playerStructuresDatabase = dbManager->loadObjectDatabase("playerstructures", true);
		auto playerStructuresDatabaseIndex = dbManager->loadIndexDatabase("playerstructuresindex", true);

		fatal(playerStructuresDatabase && playerStructuresDatabaseIndex) << "Could not load the player structures databases.";

		info(true) << "creating player structures index association";

		playerStructuresDatabase->associate(playerStructuresDatabaseIndex, StorageManagerNamespace::indexCallback);

		return playerStructuresDatabaseIndex;
	}();

	fatal(initialized) << "Could not initialize player structures sub index.";

	initialized->reloadParentAssociation(); // makes sure the thread local db handle reloads the association if needed

	return initialized;
}

String StructureManager::validatePlayerStructureZoneIndex(bool logDetails, bool validateSecondaryIndex) {
	struct ValidationStats {
		int totalRecords = 0;
		int validZones = 0;
		int missingZones = 0;
		int emptyZones = 0;
		int zeroHashZones = 0;
		int invalidZones = 0;
		int indexMismatches = 0;
		int unreadableRecords = 0;
	};

	constexpr int maxDetailLogs = 100;
	int detailLogs = 0;

	auto logDetail = [this, logDetails, &detailLogs](const String& message) {
		if (!logDetails)
			return;

		if (detailLogs < maxDetailLogs) {
			warning(message);
		} else if (detailLogs == maxDetailLogs) {
			warning("PLAYERSTRUCTURE-ZONE-VALIDATION: additional malformed player structure records suppressed");
		}

		++detailLogs;
	};

	auto dbManager = ObjectDatabaseManager::instance();
	auto structureDatabase = dbManager->loadObjectDatabase("playerstructures", true);
	IndexDatabase* playerStructuresDatabaseIndex = nullptr;

	if (validateSecondaryIndex)
		playerStructuresDatabaseIndex = createSubIndex();

	if (structureDatabase == nullptr) {
		return "PlayerStructure Zone Validation: playerstructures database unavailable";
	}

	berkeley::CursorConfig config;
	config.setReadUncommitted(true);

	ObjectDatabaseIterator iterator(structureDatabase, config);
	ObjectInputStream objectData(2000);
	uint64 objectID = 0;
	ValidationStats stats;

	while (iterator.getNextKeyAndValue(objectID, &objectData)) {
		++stats.totalRecords;

		String className;
		String zoneReference;
		uint32 serverObjectCRC = 0;
		uint64 ownerObjectID = 0;

		try {
			Serializable::getVariable<String>(STRING_HASHCODE("_className"), &className, &objectData);
			Serializable::getVariable<uint32>(STRING_HASHCODE("SceneObject.serverObjectCRC"), &serverObjectCRC, &objectData);
			Serializable::getVariable<uint64>(STRING_HASHCODE("StructureObject.ownerObjectID"), &ownerObjectID, &objectData);

			if (!Serializable::getVariable<String>(STRING_HASHCODE("SceneObject.zone"), &zoneReference, &objectData)) {
				++stats.missingZones;

				StringBuffer detail;
				detail << "PLAYERSTRUCTURE-ZONE-MISSING: OID=" << objectID
					<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
					<< " serverObjectCRC=" << serverObjectCRC
					<< " ownerObjectID=" << ownerObjectID
					<< " has no persisted SceneObject.zone";
				logDetail(detail.toString());

				objectData.reset();
				continue;
			}
		} catch (const Exception& e) {
			++stats.unreadableRecords;

			StringBuffer detail;
			detail << "PLAYERSTRUCTURE-ZONE-UNREADABLE: OID=" << objectID << " error=" << e.getMessage();
			logDetail(detail.toString());

			objectData.reset();
			continue;
		} catch (...) {
			++stats.unreadableRecords;

			StringBuffer detail;
			detail << "PLAYERSTRUCTURE-ZONE-UNREADABLE: OID=" << objectID << " error=<unknown>";
			logDetail(detail.toString());

			objectData.reset();
			continue;
		}

		if (zoneReference.isEmpty()) {
			++stats.emptyZones;

			StringBuffer detail;
			detail << "PLAYERSTRUCTURE-ZONE-MISSING: OID=" << objectID
				<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
				<< " serverObjectCRC=" << serverObjectCRC
				<< " ownerObjectID=" << ownerObjectID
				<< " has an empty persisted SceneObject.zone";
			logDetail(detail.toString());

			objectData.reset();
			continue;
		}

		uint64 expectedHash = zoneReference.hashCode();

		if (expectedHash == 0) {
			++stats.zeroHashZones;

			StringBuffer detail;
			detail << "PLAYERSTRUCTURE-ZONE-ZERO-HASH: OID=" << objectID
				<< " zone=" << zoneReference
				<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
				<< " serverObjectCRC=" << serverObjectCRC
				<< " ownerObjectID=" << ownerObjectID;
			logDetail(detail.toString());

			objectData.reset();
			continue;
		}

		++stats.validZones;

		if (server != nullptr && server->getZone(zoneReference) == nullptr) {
			++stats.invalidZones;

			StringBuffer detail;
			detail << "PLAYERSTRUCTURE-ZONE-INVALID: OID=" << objectID
				<< " zone=" << zoneReference
				<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
				<< " serverObjectCRC=" << serverObjectCRC
				<< " ownerObjectID=" << ownerObjectID;
			logDetail(detail.toString());
		}

		if (validateSecondaryIndex && playerStructuresDatabaseIndex != nullptr) {
			IndexDatabaseIterator indexIterator(playerStructuresDatabaseIndex, config);
			uint64 indexedObjectID = 0;
			bool foundExpectedIndexEntry = false;

			if (indexIterator.setKeyAndGetValue(expectedHash, indexedObjectID, nullptr)) {
				if (indexedObjectID == objectID) {
					foundExpectedIndexEntry = true;
				} else {
					while (indexIterator.getNextKeyAndValue(expectedHash, indexedObjectID, nullptr)) {
						if (indexedObjectID == objectID) {
							foundExpectedIndexEntry = true;
							break;
						}
					}
				}
			}

			if (!foundExpectedIndexEntry) {
				++stats.indexMismatches;

				StringBuffer detail;
				detail << "PLAYERSTRUCTURE-INDEX-MISMATCH: OID=" << objectID
					<< " zone=" << zoneReference
					<< " expectedHash=" << expectedHash
					<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
					<< " serverObjectCRC=" << serverObjectCRC
					<< " ownerObjectID=" << ownerObjectID;

				Reference<SharedObjectTemplate*> objectTemplate = templateManager->getTemplate(serverObjectCRC);
				if (objectTemplate != nullptr)
					detail << " template=" << objectTemplate->getFullTemplateString();

				logDetail(detail.toString());
			}
		}

		objectData.reset();
	}

	StringBuffer summary;
	summary << "PlayerStructure Zone Validation:" << endl
		<< "  Total records: " << stats.totalRecords << endl
		<< "  Valid zones: " << stats.validZones << endl
		<< "  Missing/empty zones: " << (stats.missingZones + stats.emptyZones) << endl
		<< "  Missing zone variables: " << stats.missingZones << endl
		<< "  Empty zones: " << stats.emptyZones << endl
		<< "  Zone hashes equal to zero: " << stats.zeroHashZones << endl
		<< "  Invalid zones: " << stats.invalidZones << endl
		<< "  Secondary index mismatches: " << stats.indexMismatches << endl
		<< "  Unreadable records: " << stats.unreadableRecords;

	info(true) << endl << summary.toString();

	return summary.toString();
}


void StructureManager::loadPlayerStructures(const String& zoneName) {
	info("Loading player structures for zone: " + zoneName);

	auto playerStructuresDatabaseIndex = createSubIndex();

	static AtomicBoolean validatedPlayerStructureZoneIndex;

	if (validatedPlayerStructureZoneIndex.compareAndSet(false, true)) {
		validatePlayerStructureZoneIndex(true, true);
	}

	berkeley::CursorConfig config;
	config.setReadUncommitted(true);
	uint64 zoneHash = zoneName.hashCode();

	IndexDatabaseIterator iterator(playerStructuresDatabaseIndex, config);

	Time nextReport;
	nextReport.addMiliTime(5000);
	int countLoaded = 0;

	uint64 objectID;

	auto loadFunction = [this, &nextReport, zoneName](int& countLoaded, uint64 objectID, uint64 planet) {
		// debug("loading 0x" + String::hexvalueOf(objectID) + " for planet 0x" + String::hexvalueOf(planet), true);

		try {
			auto object = server->getObject(objectID);

			if (object == nullptr) {
				error("Failed to deserialize structure with objectID: " + String::valueOf(objectID));

				return;
			}

			++countLoaded;

			if (!nextReport.isFuture()) {
				nextReport.updateToCurrentTime();
				nextReport.addMiliTime(5000);
				info(true) << "Loaded " << commas << countLoaded << " structures for zone: " << zoneName;
			}

			if (object->isGCWBase()) {
				Zone* zone = object->getZone();

				if (zone != nullptr) {
					GCWManager* gcwMan = zone->getGCWManager();

					if (gcwMan != nullptr) {
						gcwMan->registerGCWBase(cast<BuildingObject*>(object.get()), false);
					}
				}
			}

			if (ConfigManager::instance()->isProgressMonitorActivated())
				printf("\r\tLoading player structures [%d] / [?]\t", countLoaded);
		} catch (Exception& e) {
			error("Database exception in StructureManager::loadPlayerStructures(): " + e.getMessage());
		}
	};

	Timer loadTimer;
	loadTimer.start();

	Timer initialQueryPerf;
	initialQueryPerf.start();

	Timer iteratorPerf;

	if (iterator.setKeyAndGetValue(zoneHash, objectID, nullptr)) {
		initialQueryPerf.stop();

		loadFunction(countLoaded, objectID, zoneHash);

		iteratorPerf.start();

		while (iterator.getNextKeyAndValue(zoneHash, objectID, nullptr)) {
			iteratorPerf.stop();

			loadFunction(countLoaded, objectID, zoneHash);

			iteratorPerf.start();
		}

		iteratorPerf.stop();
	}

	auto elapsedMs = loadTimer.stopMs();

	info(countLoaded > 0) << commas << countLoaded << " player structures loaded for " << zoneName << " in " << msToString(elapsedMs) << " where the initial query took " << msToString(initialQueryPerf.getTotalTimeMs()) << " and iterator took " << msToString(iteratorPerf.getTotalTimeMs());
}

int StructureManager::getStructureFootprint(SharedStructureObjectTemplate* objectTemplate, int angle, float& l0, float& w0, float& l1, float& w1) {
	if (objectTemplate == nullptr)
		return 1;

	const StructureFootprint* structureFootprint = objectTemplate->getStructureFootprint();

	if (structureFootprint == nullptr)
		return 1;

	// float l = 5; //Along the x axis.
	// float w = 5; //Along the y axis.

	// if (structureFootprint->getRowSize() > structureFootprint->getColSize())
	//	angle = angle + 180;

	float centerX = (structureFootprint->getCenterX() * 8) + 4;
	float centerY = (structureFootprint->getCenterY() * 8) + 4;

	debug() << "getStructureFootprint centerX:" << centerX << " centerY:" << centerY;

	float topLeftX = -centerX;
	float topLeftY = (structureFootprint->getRowSize() * 8) - centerY;

	float bottomRightX = (8 * structureFootprint->getColSize() - centerX);
	float bottomRightY = -centerY;

	w0 = Math::min(topLeftX, bottomRightX);
	l0 = Math::min(topLeftY, bottomRightY);

	w1 = Math::max(topLeftX, bottomRightX);
	l1 = Math::max(topLeftY, bottomRightY);

	Matrix4 translationMatrix;
	translationMatrix.setTranslation(0, 0, 0);

	float rad = (float)(angle)*Math::DEG2RAD;

	float cosRad = cos(rad);
	float sinRad = sin(rad);

	Matrix3 rot;
	rot[0][0] = cosRad;
	rot[0][2] = -sinRad;
	rot[1][1] = 1;
	rot[2][0] = sinRad;
	rot[2][2] = cosRad;

	Matrix4 rotateMatrix;
	rotateMatrix.setRotationMatrix(rot);

	Matrix4 moveAndRotate = (translationMatrix * rotateMatrix);

	Vector3 pointBottom(w0, 0, l0);
	Vector3 pointTop(w1, 0, l1);

	Vector3 resultBottom = pointBottom * moveAndRotate;
	Vector3 resultTop = pointTop * moveAndRotate;

	w0 = Math::min(resultBottom.getX(), resultTop.getX());
	l0 = Math::min(resultBottom.getZ(), resultTop.getZ());

	w1 = Math::max(resultTop.getX(), resultBottom.getX());
	l1 = Math::max(resultTop.getZ(), resultBottom.getZ());

	debug() << "objectTemplate:" << objectTemplate->getFullTemplateString() << " :" << *structureFootprint << "angle:" << angle << " w0:" << w0 << " l0:" << l0 << " w1:" << w1 << " l1:" << l1;

	return 0;
}
  int StructureManager::placeStructureFromDeed(CreatureObject* creature, StructureDeed* deed, float x, float y, int angle) {
    ManagedReference<Zone*> zone = creature->getZone();

    // Already placing a structure?
    if (zone == nullptr || creature->containsActiveSession(SessionFacadeType::PLACESTRUCTURE)) {
        return 1;
    }

    String serverTemplatePath = deed->getGeneratedObjectTemplate();

    // Check deed faction, player faction and status to make sure they are allowed to place faction deeds (bases)
    if (deed->getFaction() != Factions::FACTIONNEUTRAL) {
        if (creature->getFaction() == Factions::FACTIONNEUTRAL || creature->getFactionStatus() == FactionStatus::ONLEAVE) {
            StringIdChatParameter message("@faction_perk:prose_not_neutral");
            message.setTT(deed->getDisplayedName());
            creature->sendSystemMessage(message);
            return 1;
        }

        if (deed->getFaction() != creature->getFaction()) {
            UnicodeString deedFaction = "";
            if (deed->isRebel()) deedFaction = "Rebel";
            else if (deed->isImperial()) deedFaction = "Imperial";

            StringIdChatParameter message("@faction_perk:prose_wrong_faction");
            message.setTT(deed->getDisplayedName());
            message.setTO(deedFaction);
            creature->sendSystemMessage(message);
            return 1;
        }
    }

    ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();

    Reference<SharedStructureObjectTemplate*> serverTemplate =
        dynamic_cast<SharedStructureObjectTemplate*>(templateManager->getTemplate(serverTemplatePath.hashCode()));

    // Check to see if this zone allows this structure.
    if (serverTemplate == nullptr || !serverTemplate->isAllowedZone(zone->getZoneName())) {
        creature->sendSystemMessage("@player_structure:wrong_planet");
        return 1;
    }

    if (!planetManager->isBuildingPermittedAt(x, y, creature)) {
        creature->sendSystemMessage("@player_structure:not_permitted");
        return 1;
    }

    SortedVector<ManagedReference<ActiveArea*>> objects;
    zone->getInRangeActiveAreas(x, 0, y, &objects, true);

    ManagedReference<CityRegion*> city;
    for (int i = 0; i < objects.size(); ++i) {
        ActiveArea* area = objects.get(i).get();
        if (!area->isRegion()) continue;
        city = dynamic_cast<Region*>(area)->getCityRegion().get();
        if (city != nullptr) break;
    }

    if (city != nullptr && city->isClientRegion()) {
        creature->sendSystemMessage("@player_structure:not_permitted");
        return 1;
    }

    SortedVector<ManagedReference<TreeEntry*> > inRangeObjects;
    zone->getInRangeObjects(x, 0, y, 128, &inRangeObjects, true, false);

    float placingFootprintLength0 = 0, placingFootprintWidth0 = 0, placingFootprintLength1 = 0, placingFootprintWidth1 = 0;

    if (!getStructureFootprint(serverTemplate, angle, placingFootprintLength0, placingFootprintWidth0, placingFootprintLength1, placingFootprintWidth1)) {
        float x0 = x + placingFootprintWidth0;
        float y0 = y + placingFootprintLength0;
        float x1 = x + placingFootprintWidth1;
        float y1 = y + placingFootprintLength1;

        BoundaryRectangle placingFootprint(x0, y0, x1, y1);

        debug() << "placing center x:" << x << " y:" << y << "placingFootprint x0:" << x0 << " y0:" << y0 << " x1:" << x1 << " y1:" << y1;

        for (int i = 0; i < inRangeObjects.size(); ++i) {
            SceneObject* scene = inRangeObjects.get(i).castTo<SceneObject*>();
            if (scene == nullptr) continue;

            float l0 = -5, w0 = -5, l1 = 5, w1 = 5;

            if (getStructureFootprint(dynamic_cast<SharedStructureObjectTemplate*>(scene->getObjectTemplate()),
                                      scene->getDirectionAngle(), l0, w0, l1, w1))
                continue;

            float xx0 = scene->getPositionX() + (w0 + 0.1f);
            float yy0 = scene->getPositionY() + (l0 + 0.1f);
            float xx1 = scene->getPositionX() + (w1 - 0.1f);
            float yy1 = scene->getPositionY() + (l1 - 0.1f);

            BoundaryRectangle rect(xx0, yy0, xx1, yy1);
            debug() << "existing footprint xx0:" << xx0 << " yy0:" << yy0 << " xx1:" << xx1 << " yy1:" << yy1;

            if (rect.containsPoint(x0, y0) || rect.containsPoint(x0, y1) || rect.containsPoint(x1, y0) || rect.containsPoint(x1, y1)) {
                debug() << "existing footprint contains placing point";
                creature->sendSystemMessage("@player_structure:no_room");
                return 1;
            }

            if (placingFootprint.containsPoint(xx0, yy0) || placingFootprint.containsPoint(xx0, yy1) ||
                placingFootprint.containsPoint(xx1, yy0) || placingFootprint.containsPoint(xx1, yy1) ||
                (xx0 == x0 && yy0 == y0 && xx1 == x1 && yy1 == y1)) {
                debug() << "placing footprint contains existing point";
                creature->sendSystemMessage("@player_structure:no_room");
                return 1;
            }
        }
    }

    int rankRequired = serverTemplate->getCityRankRequired();

    if (city == nullptr && rankRequired > 0) {
        creature->sendSystemMessage("@city/city:build_no_city");
        return 1;
    }

    if (city != nullptr) {
        // Check if the city's rank meets the structure's rank requirement
        if (rankRequired > 0 && city->getCityRank() < rankRequired) {
            creature->sendSystemMessage("@player_structure:not_permitted");
            return 1;
        }

        if (city->isZoningEnabled() && !city->hasZoningRights(creature->getObjectID())) {
            creature->sendSystemMessage("@player_structure:no_rights");
            return 1;
        }


        if (serverTemplate->isUniqueStructure() && city->hasUniqueStructure(serverTemplate->getServerObjectCRC())) {
            creature->sendSystemMessage("@player_structure:cant_place_unique");
            return 1;
        }
    }

    Locker _lock(deed, creature);
    if (!deed->isASubChildOf(creature)) {
        creature->sendSystemMessage("@player_structure:no_possession");
        return 1;
    }
    ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
if (ghost != nullptr) {
    String abilityRequired = serverTemplate->getAbilityRequired();
    if (!abilityRequired.isEmpty() && !ghost->hasAbility(abilityRequired)) {
        creature->sendSystemMessage("@player_structure:" + abilityRequired);
        return 1;
    }

    const int lots = serverTemplate->getLotSize();
    const int accountLotsUsed = getAccountLotsUsed(creature);
    const int accountLotCap = getAccountLotCap(creature);

    if (accountLotsUsed + lots > accountLotCap) {
        StringIdChatParameter param("@player_structure:not_enough_lots");
        param.setDI(lots);
        creature->sendSystemMessage(param);
        return 1;
    }
}
    // For packed deeds, skip the lot check entirely since the deed already consumes the lots
    ManagedReference<PlaceStructureSession*> session = new PlaceStructureSession(creature, deed);
    creature->addActiveSession(SessionFacadeType::PLACESTRUCTURE, session);
    session->constructStructure(x, y, angle);
    deed->destroyObjectFromWorld(true);
    return 0;
}

StructureObject* StructureManager::placeStructure(CreatureObject* creature, const String& structureTemplatePath, float x, float y, int angle, int persistenceLevel) {
    ManagedReference<Zone*> zone = creature->getZone();

    if (zone == nullptr)
        return nullptr;

    TerrainManager* terrainManager = zone->getPlanetManager()->getTerrainManager();
    SharedStructureObjectTemplate* serverTemplate = dynamic_cast<SharedStructureObjectTemplate*>(templateManager->getTemplate(structureTemplatePath.hashCode()));
    if (serverTemplate == nullptr) {
        info("server template is null");
        return nullptr;
    }

    float z = zone->getHeight(x, y);
    float floraRadius = serverTemplate->getClearFloraRadius();
    bool snapToTerrain = serverTemplate->getSnapToTerrain();
    Reference<const StructureFootprint*> structureFootprint = serverTemplate->getStructureFootprint();

    float w0 = -5; // Along the x axis.
    float l0 = -5; // Along the y axis.
    float l1 = 5;
    float w1 = 5;
    float zIncreaseWhenNoAvailableFootprint = 0.f;

    if (structureFootprint != nullptr) {
        getStructureFootprint(serverTemplate, angle, l0, w0, l1, w1);
    } else {
        if (!serverTemplate->isCampStructureTemplate())
            warning("Structure with template '" + structureTemplatePath + "' has no structure footprint.");
        zIncreaseWhenNoAvailableFootprint = 5.f;
    }

    if (floraRadius > 0 && !snapToTerrain)
        z = terrainManager->getHighestHeight(x + w0, y + l0, x + w1, y + l1, 1) + zIncreaseWhenNoAvailableFootprint;

    String strDatabase = "playerstructures";
    bool bIsFactionBuilding = (serverTemplate->getGameObjectType() == SceneObjectType::FACTIONBUILDING);

    if (bIsFactionBuilding || serverTemplate->getGameObjectType() == SceneObjectType::DESTRUCTIBLE) {
        strDatabase = "playerstructures";
    }

    ManagedReference<SceneObject*> obj = ObjectManager::instance()->createObject(structureTemplatePath.hashCode(), persistenceLevel, strDatabase);

    if (obj == nullptr || !obj->isStructureObject()) {
        if (obj != nullptr) {
            Locker locker(obj);
            obj->destroyObjectFromDatabase(true);
        }
        error("Failed to create structure with template: " + structureTemplatePath);
        return nullptr;
    }

  StructureObject* structureObject = cast<StructureObject*>(obj.get());
Locker sLocker(structureObject);

structureObject->grantPermission("ADMIN", creature->getObjectID());
structureObject->setOwner(creature->getObjectID());

ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
if (ghost != nullptr) {
    ghost->addOwnedStructure(structureObject);
}

if (structureObject->isTurret() || structureObject->isMinefield() || structureObject->isScanner()) {
    structureObject->setFaction(creature->getFaction());
}

BuildingObject* buildingObject = nullptr;
if (structureObject->isBuildingObject()) {
    buildingObject = cast<BuildingObject*>(structureObject);
    if (buildingObject != nullptr)
        buildingObject->createCellObjects();
}

structureObject->setPublicStructure(serverTemplate->isPublicStructure());
structureObject->initializePosition(x, z, y);
structureObject->rotate(angle);

TransactionLog trx(TrxCode::STRUCTUREDEED, creature, structureObject);
zone->transferObject(structureObject, -1, true);
structureObject->createChildObjects();
structureObject->notifyStructurePlaced(creature);

return structureObject;
}

StructureObject* StructureManager::placeCamp(CreatureObject* player, CustomizationVariables* customVars, const String& campTemplatePath, float x, float y, int angle, int persistenceLevel) {
	if (player == nullptr)
		return nullptr;

	auto zone = player->getZone();

	if (zone == nullptr)
		return nullptr;

	auto ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return nullptr;

	CampStructureTemplate* campTemplate = dynamic_cast<CampStructureTemplate*>(templateManager->getTemplate(campTemplatePath.hashCode()));

	if (campTemplate == nullptr) {
		error() << "StructureManager::placeCamp -  campTemplate is null: " << campTemplatePath;
		return nullptr;
	}

	ManagedReference<StructureObject*> campObject = dynamic_cast<StructureObject*>(ObjectManager::instance()->createObject(campTemplatePath.hashCode(), persistenceLevel, "playerstructures"));

	if (campObject == nullptr) {
		error() << "Failed to create camp with template: " << campTemplatePath;
		return nullptr;
	}

	Locker sLocker(campObject);

	// Add on customization options
	// These variables will not apply properly until we modify the object placed to not include the tent itself as part of its CDF and add it as a child
	/*
	if (customVars != nullptr) {
		for (int i = 0; i < customVars->size(); ++i) {
			uint8 id = customVars->elementAt(i).getKey();
			String name = CustomizationIdManager::instance()->getCustomizationVariable(id);

			if (!name.contains("index_color"))
				continue;

			int16 val = customVars->elementAt(i).getValue();

			// info(true) << "Setting camp custom varible: " << name << " Value: " << val;

			campObject->setCustomizationVariable(name, val, false);
		}
	}
	*/

	campObject->grantPermission("ADMIN", player->getObjectID());
	campObject->setOwner(player->getObjectID());

	ghost->addOwnedStructure(campObject);

	if (player->getFactionStatus() == FactionStatus::OVERT) {
		campObject->setFaction(player->getFaction());
	}

	campObject->initializePosition(x, zone->getHeight(x, y), y);
	campObject->rotate(angle);

	TransactionLog trx(TrxCode::CAMPPLACED, player, campObject);

	zone->transferObject(campObject, -1, true);

	campObject->createChildObjects();

	campObject->notifyStructurePlaced(player);

	return campObject;
}

int StructureManager::destroyStructure(StructureObject* structureObject,
                                       bool playEffect /*=false*/,
                                       bool refundLots /*=true*/) {
    Reference<DestroyStructureTask*> task =
        new DestroyStructureTask(structureObject,
                                 /*doEffect*/ playEffect,
                                 /*killStuff*/ false,
                                 /*refundLotsFlag*/ refundLots);
    task->execute();
    return 0;
}

String StructureManager::getTimeString(uint32 timestamp) {
	if (timestamp == 0) {
		return "";
	}

	static const String abbrvs[3] = {"minutes", "hours", "days"};

	static const int intervals[3] = {60, 3600, 86400};
	int values[3] = {0, 0, 0};

	StringBuffer str;

	for (int i = 2; i > -1; --i) {
		values[i] = floor((float)timestamp / intervals[i]);
		timestamp -= values[i] * intervals[i];

		if (values[i] > 0) {
			if (str.length() > 0) {
				str << ", ";
			}

			str << values[i] << " " << abbrvs[i];
		}
	}

	return "(" + str.toString() + ")";
}

int StructureManager::declareResidence(CreatureObject* player, StructureObject* structureObject, bool isCityHall) {
	if (!structureObject->isBuildingObject()) {
		player->sendSystemMessage("@player_structure:residence_must_be_building"); // Your declared residence must be a building.
		return 1;
	}

	PlayerObject* ghost = player->getPlayerObject();

	if (!isCityHall && !player->checkCooldownRecovery("declare_residence") && !ghost->isPrivileged()) {
		const Time* timeremaining = player->getCooldownTime("declare_residence");
		StringIdChatParameter params("player_structure", "change_residence_time"); // You cannot change residence for %NO hours.
		params.setTO(String::valueOf(ceil(timeremaining->miliDifference() / -3600000.f)));

		player->sendSystemMessage(params);
		return 1;
	}

	ManagedReference<BuildingObject*> buildingObject = cast<BuildingObject*>(structureObject);

	if (!buildingObject->isOwnerOf(player)) {
		player->sendSystemMessage("@player_structure:declare_must_be_owner"); // You must be the owner of the building to declare residence.
		return 1;
	}

	uint64 objectid = player->getObjectID();

	uint64 declaredOidResidence = ghost->getDeclaredResidence();

	ManagedReference<BuildingObject*> declaredResidence = server->getObject(declaredOidResidence).castTo<BuildingObject*>();
	ManagedReference<CityRegion*> cityRegion = buildingObject->getCityRegion().get();

	CityManager* cityManager = server->getCityManager();

	if (declaredResidence != nullptr) {
		if (declaredResidence == buildingObject) {
			player->sendSystemMessage("@player_structure:already_residence"); // This building is already your residence.
			return 1;
		}

		ManagedReference<CityRegion*> residentCity = declaredResidence->getCityRegion().get();

		if (residentCity != nullptr) {
			Locker lock(residentCity, player);

			if (residentCity->isMayor(objectid)) {
				player->sendSystemMessage("@city/city:mayor_residence_change"); // As a city Mayor, your residence is always the city hall of the city in which you are mayor.  You cannot declare a new residence.
				return 1;
			}

			cityManager->unregisterCitizen(residentCity, player);
		}

		player->sendSystemMessage("@player_structure:change_residence"); // You change your residence to this building.
	} else {
		player->sendSystemMessage("@player_structure:declared_residency"); // You have declared your residency here.
	}

	if (cityRegion != nullptr) {
		Locker lock(cityRegion, player);

		if (cityRegion->isMayor(objectid) && structureObject != cityRegion->getCityHall()) {
			player->sendSystemMessage("@city/city:mayor_residence_change"); // As a city Mayor, your residence is always the city hall of the city in which you are mayor.  You cannot declare a new residence.
			return 1;
		}

		cityManager->registerCitizen(cityRegion, player);
	}

	// Set the characters home location to this structure.
	ghost->setDeclaredResidence(buildingObject);

	if (declaredResidence != nullptr) {
		Locker oldLock(declaredResidence, player);
		declaredResidence->setResidence(false);
	}

	Locker newLock(buildingObject, player);
	buildingObject->setResidence(true);

	player->addCooldown("declare_residence", 24 * 3600 * 1000); // 1 day

	return 0;
}

Reference<SceneObject*> StructureManager::getInRangeParkingGarage(SceneObject* obj, int range) {
	ManagedReference<Zone*> zone = obj->getZone();

	if (zone == nullptr)
		return nullptr;

	SortedVector<TreeEntry*> closeSceneObjects;
	CloseObjectsVector* closeObjectsVector = (CloseObjectsVector*) obj->getCloseObjects();

	if (closeObjectsVector == nullptr) {
		zone->getInRangeObjects(obj->getPositionX(), obj->getPositionZ(), obj->getPositionY(), 128, &closeSceneObjects, true, false);
	} else {
		closeObjectsVector->safeCopyTo(closeSceneObjects);
	}

	for (int i = 0; i < closeSceneObjects.size(); ++i) {
		SceneObject* scno = cast<SceneObject*>(closeSceneObjects.get(i));

		if (scno == nullptr || scno == obj)
			continue;

		if (scno->isGarage() && scno->isInRange(obj, range))
			return scno;
	}

	return nullptr;
}

bool StructureManager::canRedeedStructure(CreatureObject* creature, StructureObject* structureObject) {
    if (creature == nullptr || structureObject == nullptr || !structureObject->isRedeedable())
        return false;

    ManagedReference<StructureDeed*> deed =
        server->getObject(structureObject->getDeedObjectID()).castTo<StructureDeed*>();
    if (deed == nullptr)
        return false;

    ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");
    if (inventory == nullptr)
        return false;

    HarvesterObject* harvester = structureObject->isHarvesterObject() ?
        cast<HarvesterObject*>(structureObject) : nullptr;
    int requiredInventorySlots =
        (harvester != nullptr && harvester->isSelfPowered()) ? 2 : 1;

    return inventory->getCountableObjectsRecursive() <=
        (inventory->getContainerVolumeLimit() - requiredInventorySlots);
}

int StructureManager::redeedStructure(CreatureObject* creature, bool requireRedeed) {
    ManagedReference<DestroyStructureSession*> session =
        creature->getActiveSession(SessionFacadeType::DESTROYSTRUCTURE)
            .castTo<DestroyStructureSession*>();
    if (session == nullptr)
        return 0;

    ManagedReference<StructureObject*> structureObject = session->getStructureObject();
    if (structureObject == nullptr)
        return 0;

    Locker _locker(structureObject);

    if (requireRedeed && !canRedeedStructure(creature, structureObject))
        return 1;

    uint64 deedObjectID = structureObject->getDeedObjectID();
    info(true) << "Attempting to redeed structure. Deed Object ID: " << deedObjectID;

    ManagedReference<StructureDeed*> deed = nullptr;

    // Check if we have a valid deed object ID
    if (deedObjectID == 0) {
        info(true) << "ERROR: Deed Object ID is 0 - structure has no deed reference";
        creature->sendSystemMessage("ERROR: Structure has no deed reference. Please contact an administrator.");
    } else {
        deed = server->getObject(deedObjectID).castTo<StructureDeed*>();

        if (deed == nullptr) {
            info(true) << "ERROR: Failed to retrieve deed object ID " << deedObjectID << " from database";
            creature->sendSystemMessage("ERROR: Could not retrieve deed from database. Deed ID: " + String::valueOf((int64)deedObjectID));
        } else {
            info(true) << "Successfully retrieved deed object. Deed name: " << deed->getDisplayedName();
        }
    }

    int maint = structureObject->getSurplusMaintenance();
    int redeedCost = structureObject->getRedeedCost();

    bool isRedeedable = structureObject->isRedeedable();
    info(true) << "Structure redeedable check: " << (isRedeedable ? "YES" : "NO")
               << " (maintenance: " << maint << ", redeed cost: " << redeedCost << ")";

    TransactionLog trx(creature, TrxCode::STRUCTUREDEED, structureObject);
    trx.addState("subjectIsRedeedable", isRedeedable);
    trx.addState("subjectDeedObjectID", deed != nullptr ? deed->getObjectID() : 0);

    if (deed != nullptr && isRedeedable) {
        Locker _lock(deed, structureObject);

        ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

        bool isSelfPoweredHarvester = false;
        HarvesterObject* harvester = structureObject.castTo<HarvesterObject*>();
        if (harvester != nullptr)
            isSelfPoweredHarvester = harvester->isSelfPowered();

        // capacity check
        if (!canRedeedStructure(creature, structureObject)) {

            if (isSelfPoweredHarvester) {
                creature->sendSystemMessage("@player_structure:inventory_full_selfpowered");
                trx.abort() << "@player_structure:inventory_full_selfpowered";
            } else {
                creature->sendSystemMessage("@player_structure:inventory_full");
                trx.abort() << "@player_structure:inventory_full";
            }

            creature->sendSystemMessage("@player_structure:deed_reclaimed_failed");
            return session->cancelSession();
        } else {
            // self-powered harvester reward
            if (isSelfPoweredHarvester) {
                Reference<SceneObject*> rewardSceno =
                    server->createObject(STRING_HASHCODE("object/tangible/veteran_reward/harvester.iff"), 1);

                if (rewardSceno == nullptr) {
                    creature->sendSystemMessage("@player_structure:deed_reclaimed_failed");
                    trx.abort() << "failed to createObject veteran_reward/harvester";
                    return session->cancelSession();
                }

                TransactionLog trxReward(structureObject, creature, rewardSceno, TrxCode::STRUCTUREDEED, false);
                trxReward.addState("srcIsSelfPoweredHarvester", isSelfPoweredHarvester);
                trxReward.groupWith(trx);

                if (!inventory->transferObject(rewardSceno, -1, false, true)) { // allow overflow
                    trxReward.abort() << "Failed to reclaim deed";
                    creature->sendSystemMessage("@player_structure:deed_reclaimed_failed");
                    rewardSceno->destroyObjectFromDatabase(true);
                    return session->cancelSession();
                }

                harvester->setSelfPowered(false);
                inventory->broadcastObject(rewardSceno, true);
                creature->sendSystemMessage("@player_structure:selfpowered");
            }

            // deed bookkeeping
            TransactionLog trxDeed(structureObject, creature, deed, TrxCode::STRUCTUREDEED);
            trxDeed.addState("structureOriginalObjectID", structureObject->getObjectID());
            trxDeed.groupWith(trx);

            deed->setSurplusMaintenance(maint - redeedCost);
            deed->setSurplusPower(structureObject->getSurplusPower());

            // move packed payload from building -> deed BEFORE destroying the structure
            // move packed payload from building -> deed BEFORE destroying the structure
info(true) << "Attaching payload: building ID=" << structureObject->getObjectID() << " deed ID=" << deed->getObjectID();
HousePackupManager::instance()->attachPayloadToDeedFromBuilding(
    structureObject->getObjectID(), deed->getObjectID());
info(true) << "Payload attached successfully";

            // make sure the deed itself won't be deleted with the structure
            structureObject->setDeedObjectID(0);

            // Destroy structure — let normal Core3 behavior refund lots here.
            // If your destroyStructure signature is (StructureObject*, bool),
            // call: destroyStructure(structureObject, /*playEffect*/false);
            // If it's (StructureObject*, bool, bool refundLots), pass true:
            destroyStructure(structureObject, /*playEffect*/false, /*refundLots*/true);

            // hand deed back to player
            info(true) << "Transferring deed to player inventory...";
            if (!inventory->transferObject(deed, -1, true)) {
                trx.abort() << "failed to transfer deed to player inventory";
                info(true) << "ERROR: Failed to transfer deed to player inventory!";
                creature->sendSystemMessage("ERROR: Failed to transfer deed to inventory. Please contact an administrator.");
            } else {
                info(true) << "Deed successfully transferred to player inventory";
            }

            inventory->broadcastObject(deed, true);
            creature->sendSystemMessage("@player_structure:deed_reclaimed");
        }
    } else {
        // not redeedable: normal destroy (refund lots)
        info(true) << "Structure NOT redeeded. Reason: "
                   << (deed == nullptr ? "deed is NULL" : "structure not redeedable")
                   << " (maintenance: " << maint << ", redeed cost: " << redeedCost << ")";

        if (deed == nullptr) {
            creature->sendSystemMessage("ERROR: Could not return deed - deed object not found in database.");
            creature->sendSystemMessage("Structure will be destroyed. Please contact an administrator.");
            info(true) << "CRITICAL: Deed was NULL for structure OID " << structureObject->getObjectID()
                       << ", stored deed ID was " << deedObjectID;
        } else if (!isRedeedable) {
            creature->sendSystemMessage("Structure does not have enough maintenance to be redeeded.");
            creature->sendSystemMessage("Required: " + String::valueOf(redeedCost) +
                                       " credits, Available: " + String::valueOf(maint) + " credits.");
        }

        destroyStructure(structureObject, /*playEffect*/false, /*refundLots*/true);
        creature->sendSystemMessage("@player_structure:structure_destroyed");
    }

    return session->cancelSession();
}

void StructureManager::promptDeleteAllItems(CreatureObject* creature, StructureObject* structure) {
	ManagedReference<SuiMessageBox*> sui = new SuiMessageBox(creature, 0x00);
	sui->setUsingObject(structure);
	sui->setPromptTitle("@player_structure:delete_all_items");	// Delete All Items
	sui->setPromptText("@player_structure:delete_all_items_d"); // This command will delete every object in your house.  Are you ABSOLUTELY sure you want to destroy every object in your house?
	sui->setCancelButton(true, "@cancel");
	sui->setCallback(new DeleteAllItemsSuiCallback(server));

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

}
void StructureManager::promptFindLostItems(CreatureObject* creature, StructureObject* structure) {
	ManagedReference<SuiMessageBox*> sui = new SuiMessageBox(creature, 0x00);
	sui->setUsingObject(structure);
	sui->setPromptTitle("@player_structure:move_first_item");  // Find Lost Items
	sui->setPromptText("@player_structure:move_first_item_d"); // This command will move the first item in your house to your location...
	sui->setCallback(new FindLostItemsSuiCallback(server));

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost != nullptr) {
		ghost->addSuiBox(sui);
		creature->sendMessage(sui->generateMessage());
	}
}

void StructureManager::moveFirstItemTo(CreatureObject* creature, StructureObject* structure) {
	if (!structure->isBuildingObject())
		return;

	ManagedReference<BuildingObject*> building = cast<BuildingObject*>(structure);

	Locker _lock(building, creature);

	for (uint32 i = 1; i <= building->getTotalCellNumber(); ++i) {
		ManagedReference<CellObject*> cell = building->getCell(i);

		for (int j = 0; j < cell->getContainerObjectsSize(); ++j) {
			ManagedReference<SceneObject*> childObject = cell->getContainerObject(j);

			if (childObject->isVendor())
				continue;

			// if (!building->containsChildObject(childObject) && !childObject->isCreatureObject()) {
			if (creature->getParent() != nullptr && !building->containsChildObject(childObject) && !childObject->isCreatureObject()) {
				if (creature->getParent().get()->getParent().get() == childObject->getParent().get()->getParent().get()) {
					childObject->teleport(creature->getPositionX(), creature->getPositionZ(), creature->getPositionY(), creature->getParentID());
					creature->sendSystemMessage("@player_structure:moved_first_item"); // The first item in your house has been moved to your location.
				}

				return;
			}
		}
	}
}

void StructureManager::promptViewHouseStorage(CreatureObject* creature, StructureObject* structure) {
	if (creature == nullptr || structure == nullptr)
		return;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	if (!structure->isBuildingObject())
		return;

	BuildingObject* building = cast<BuildingObject*>(structure);
	if (building == nullptr)
		return;

	// Collect all placeable items from the building as a flat list so the SUI index maps
	// directly to the selected object. This makes the terminal reliable for recovering
	// house items whose client appearance is hard to target.
	Vector<ManagedReference<SceneObject*>> storedItems;

	// Create the SUI ListBox up front so entries can be appended as items are discovered.
	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_STATUS);

	// Lock the building to safely access its contents
	Locker buildingLocker(building);

	// Iterate through all container objects in the building (cells and items)
	for (int i = 0; i < building->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> containerObj = building->getContainerObject(i);
		if (containerObj == nullptr || !containerObj->isCellObject())
			continue;

		CellObject* cell = cast<CellObject*>(containerObj.get());
		if (cell == nullptr)
			continue;

		// Get all items in this cell
		for (int j = 0; j < cell->getContainerObjectsSize(); ++j) {
			ManagedReference<SceneObject*> childObject = cell->getContainerObject(j);
			if (childObject == nullptr)
				continue;

			// Skip non-items (vendors, terminals, creatures, cells, etc.)
			if (childObject->isVendor() || childObject->isTerminal() || childObject->isCreatureObject() || childObject->isCellObject())
				continue;

			// Get item name
			String itemName = childObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = "Unknown Item";

			StringBuffer displayString;
			displayString << itemName << " [Cell " << cell->getCellNumber() << "]";

			if (childObject->isContainerObject()) {
				displayString << " (container, " << childObject->getContainerObjectsSize() << " items)";
			}

			box->addMenuItem(displayString.toString());
			storedItems.add(childObject);
		}
	}

	box->setPromptTitle("@player_structure:structure_status_t - House Storage");

	StringBuffer promptText;
	promptText << "Stored Items: " << storedItems.size() << "\n\n";
	promptText << "Select an item to move it to your inventory or datapad.\n";
	promptText << "This can be used to recover house items that cannot be targeted directly.";
	box->setPromptText(promptText.toString());

	box->setUsingObject(structure);
	box->setForceCloseDisabled();

	// Set callback to handle item selection
	ViewHouseStorageSuiCallback* callback = new ViewHouseStorageSuiCallback(server, building);
	callback->setStoredItems(storedItems);

	box->setCallback(callback);

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

void StructureManager::reportStructureStatus(CreatureObject* creature, StructureObject* structure, SceneObject* terminal) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	// Close the window if it is already open.
	if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_STATUS)) {
		ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_STATUS);
	}

	ManagedReference<SuiListBox*> status = new SuiListBox(creature, SuiWindowType::STRUCTURE_STATUS);
	status->setPromptTitle("@player_structure:structure_status_t"); // Structure Status

	String displayedName = structure->getDisplayedName();

	if (displayedName != "") {
		status->setPromptText("@player_structure:structure_name_prompt " + structure->getDisplayedName()); // Structure Name:
	}

	if (terminal != nullptr) {
		status->setUsingObject(terminal);
	} else {
		status->setUsingObject(structure);
	}

	status->setStructureObject(structure);
	status->setOkButton(true, "@refresh");
	status->setCancelButton(true, "@cancel");
	status->setCallback(new StructureStatusSuiCallback(server));

	ManagedReference<SceneObject*> ownerObject = server->getObject(structure->getOwnerObjectID());

	if (ownerObject != nullptr && ownerObject->isCreatureObject()) {
		CreatureObject* owner = cast<CreatureObject*>(ownerObject.get());
		status->addMenuItem("@player_structure:owner_prompt " + owner->getFirstName());
	}

	uint64 declaredOidResidence = ghost->getDeclaredResidence();

	ManagedReference<BuildingObject*> declaredResidence = server->getObject(declaredOidResidence).castTo<BuildingObject*>();

	if (declaredResidence == structure) {
		status->addMenuItem("@player_structure:declared_residency"); // You have declared your residency here.
	}

	if (structure->isPrivateStructure() && !structure->isCivicStructure()) {
		status->addMenuItem("@player_structure:structure_private"); // This structure is private
	} else {
		status->addMenuItem("@player_structure:structure_public"); // This structure is public
	}

	status->addMenuItem("@player_structure:condition_prompt " + String::valueOf(structure->getDecayPercentage()) + "%");

	if (!structure->isCivicStructure() && !structure->isGCWBase()) {
		// property tax
		float propertytax = 0.f;
		ManagedReference<CityRegion*> city = structure->getCityRegion().get();
		if (city != nullptr) {
			propertytax = city->getPropertyTax() / 100.f * structure->getMaintenanceRate();
			status->addMenuItem("@city/city:property_tax_prompt : " + String::valueOf(ceil(propertytax)) + " cr/hr");
		}

		// maintenance
		float secsRemainingMaint = 0.f;
		if (structure->getSurplusMaintenance() > 0) {
			float totalrate = (float)structure->getMaintenanceRate() + propertytax;
			secsRemainingMaint = ((float)structure->getSurplusMaintenance() / totalrate) * 3600;
		}

		status->addMenuItem("@player_structure:maintenance_pool_prompt " + String::valueOf((int)floor((float)structure->getSurplusMaintenance())) + " " + getTimeString((uint32)secsRemainingMaint));

		status->addMenuItem("@player_structure:maintenance_rate_prompt " + String::valueOf(structure->getMaintenanceRate()) + " cr/hr");

		status->addMenuItem("@player_structure:maintenance_mods_prompt " + structure->getMaintenanceMods());
	}

	if (structure->isInstallationObject() && !structure->isGeneratorObject() && !structure->isCivicStructure()) {
		InstallationObject* installation = cast<InstallationObject*>(structure);

		float secsRemainingPower = 0.f;
		float basePowerRate = installation->getBasePowerRate();
		if ((installation->getSurplusPower() > 0) && (basePowerRate != 0)) {
			secsRemainingPower = ((float)installation->getSurplusPower() / (float)basePowerRate) * 3600;
		}

		status->addMenuItem("@player_structure:power_reserve_prompt " + String::valueOf((int)installation->getSurplusPower()) + " " + getTimeString((uint32)secsRemainingPower));

		status->addMenuItem("@player_structure:power_consumption_prompt " + String::valueOf((int)installation->getBasePowerRate()) + " @player_structure:units_per_hour");
	}

	if (ghost->isPrivileged())
		status->addMenuItem(structure->getDebugStructureStatus());

	if (structure->isBuildingObject()) {
		BuildingObject* building = cast<BuildingObject*>(structure);

		if (building->isGCWBase()) {
			Zone* zone = creature->getZone();

			if (zone != nullptr) {
				GCWManager* gcwMan = zone->getGCWManager();

				if (gcwMan != nullptr)
					status->addMenuItem(gcwMan->getVulnerableStatus(building, creature));
			}
		}

		status->addMenuItem("@player_structure:items_in_building_prompt " + String::valueOf(building->getCurrentNumberOfPlayerItems()) + " / " + String::valueOf(building->getMaximumNumberOfPlayerItems())); // Number of Items in Building:

#if ENABLE_STRUCTURE_JSON_EXPORT
		if (creature->hasSkill("admin_base")) {
			String exportNote = "Exported: " + building->exportJSON("reportStructureStatus");
			building->info(exportNote, true);
			status->addMenuItem(exportNote);
		}
#endif
	}

	ghost->addSuiBox(status);
	creature->sendMessage(status->generateMessage());
}

void StructureManager::promptNameStructure(CreatureObject* creature, StructureObject* structure, TangibleObject* object) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiInputBox*> inputBox = new SuiInputBox(creature, SuiWindowType::OBJECT_NAME);
	if (object == nullptr) {
		inputBox->setUsingObject(structure);
	} else {
		inputBox->setUsingObject(object);
	}
	inputBox->setPromptTitle("@base_player:set_name");					// Set Name
	inputBox->setPromptText("@player_structure:structure_name_prompt"); // Structure Name:
	inputBox->setDefaultInput(structure->getCustomObjectName().toString());
	inputBox->setMaxInputSize(128);
	inputBox->setCallback(new NameStructureSuiCallback(server));
	inputBox->setForceCloseDistance(32);

	ghost->addSuiBox(inputBox);
	creature->sendMessage(inputBox->generateMessage());
}

void StructureManager::promptMaintenanceDroid(StructureObject* structure, CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	Vector<DroidObject*> droids;
	ManagedReference<SceneObject*> datapad = creature->getSlottedObject("datapad");
	if (datapad == nullptr) {
		return;
	}
	for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> object = datapad->getContainerObject(i);

		if (object != nullptr && object->isPetControlDevice()) {
			PetControlDevice* device = cast<PetControlDevice*>(object.get());

			if (device->getPetType() == PetManager::DROIDPET) {
				DroidObject* pet = cast<DroidObject*>(device->getControlledObject());
				if (pet != nullptr && pet->isMaintenanceDroid()) {
					droids.add(pet);
				}
			}
		}
	}
	if (droids.size() == 0) {
		creature->sendSystemMessage("@player_structure:no_droids");
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_ASSIGN_DROID);
	box->setCallback(new StructureAssignDroidSuiCallback(creature->getZoneServer()));

	box->setPromptText("@sui:assign_droid_prompt");
	box->setPromptTitle("@sui:assign_droid_title"); // Configure Effects
	box->setOkButton(true, "@ok");

	// Check if player has a droid called with a maintenance module installed
	for (int i = 0; i < droids.size(); ++i) {
		DroidObject* droidObject = droids.elementAt(i);
		box->addMenuItem(droidObject->getDisplayedName(), droidObject->getObjectID());
	}
	box->setUsingObject(structure);
	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

void StructureManager::promptPayUncondemnMaintenance(CreatureObject* creature, StructureObject* structure) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr) {
		return;
	}

	int uncondemnCost = -structure->getSurplusMaintenance();

	ManagedReference<SuiMessageBox*> sui = nullptr;
	String text;

	if (creature->getBankCredits() >= uncondemnCost) {
		// Owner can un-condemn the structure.
		sui = new SuiMessageBox(creature, SuiWindowType::STRUCTURE_UNCONDEMN_CONFIRM);
		if (sui == nullptr) {
			return;
		}

		// TODO: investigate sui packets to see if it is possible to send StringIdChatParameter directly.
		String textStringId = "@player_structure:structure_condemned_owner_has_credits"; // "This structure has been condemned by the order of the Empire. You are not permitted to enter unless you pay %DI in maintenance costs. This will be automatically deducted from your bank account. Click Okay to confirm this transfer and regain access to this structure."
		text = StringIdManager::instance()->getStringId(textStringId.hashCode()).toString();
		text = text.replaceFirst("%DI", String::valueOf(uncondemnCost));

		sui->setCancelButton(true, "@cancel");
		sui->setCallback(new StructurePayUncondemnMaintenanceSuiCallback(server));
	} else {
		// Owner cannot un-condemn the structure.
		sui = new SuiMessageBox(creature, SuiWindowType::NONE);
		if (sui == nullptr) {
			return;
		}

		// TODO: investigate sui packets to see if it is possible to send StringIdChatParameter directly.
		String textStringId = "@player_structure:structure_condemned_owner_no_credits"; // "This structure has been condemned by the order of the Empire. It currently requires %DI credits to uncondemn this structure. You do not have sufficient funds in your bank account. Add sufficient funds to your account and return to regain access to this structure."
		text = StringIdManager::instance()->getStringId(textStringId.hashCode()).toString();
		text = text.replaceFirst("%DI", String::valueOf(uncondemnCost));

		sui->setCancelButton(false, "@cancel");
	}

	sui->setPromptText(text);
	sui->setOkButton(true, "@ok");
	sui->setPromptTitle("@player_structure:fix_condemned_title"); // *******CONDEMNED STRUCTURE*******
	sui->setUsingObject(structure);

	ghost->addSuiBox(sui);
	creature->sendMessage(sui->generateMessage());
}

void StructureManager::promptPayMaintenance(StructureObject* structure, CreatureObject* creature, SceneObject* terminal) {
	int cash = creature->getCashCredits();
	int bank = creature->getBankCredits();
	int availableCredits = cash + bank;

	if (availableCredits <= 0) {
		creature->sendSystemMessage("@player_structure:no_money");
		return;
	}

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	structure->updateStructureStatus();

	int surplusMaintenance = (int)floor((float)structure->getSurplusMaintenance());

	ManagedReference<SuiTransferBox*> sui = new SuiTransferBox(creature, SuiWindowType::STRUCTURE_MANAGE_MAINTENANCE);
	sui->setCallback(new StructurePayMaintenanceSuiCallback(server));
	sui->setPromptTitle("@player_structure:select_amount");
	sui->setUsingObject(structure);
	sui->setPromptText("@player_structure:select_maint_amount \n@player_structure:current_maint_pool " + String::valueOf(surplusMaintenance));
	sui->addFrom("@player_structure:total_funds", String::valueOf(availableCredits), String::valueOf(availableCredits), "1");
	sui->addTo("@player_structure:to_pay", "0", "0", "1");

	ghost->addSuiBox(sui);
	creature->sendMessage(sui->generateMessage());
}

bool StructureManager::hasRemoteMaintenanceAdminRights(StructureObject* structure, CreatureObject* creature) const {
	if (structure == nullptr || creature == nullptr)
		return false;

	uint64 creatureID = creature->getObjectID();

	// Ownership always qualifies, even if a legacy or damaged permission list
	// does not currently contain the owner entry.
	if (structure->getOwnerObjectID() == creatureID)
		return true;

	// Check the character's explicit ADMIN permission.
	if (structure->isOnAdminList(creatureID))
		return true;

	// Structure permission lists may also contain a guild object ID. Preserve
	// the same guild-admin behavior used by the normal structure systems.
	ManagedReference<GuildObject*> guild = creature->getGuildObject().get();

	return guild != nullptr && structure->isOnAdminList(guild->getObjectID());
}

void StructureManager::getRemoteMaintenanceStructureIDs(CreatureObject* creature, Vector<uint64>* structureIDs) {
	if (creature == nullptr || structureIDs == nullptr || server == nullptr)
		return;

	structureIDs->removeAll();

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	// Add the character's owned structures first. This keeps newly placed or
	// not-yet-flushed structures available even before the database scan below.
	for (int i = 0; i < ghost->getTotalOwnedStructureCount(); ++i) {
		uint64 structureID = ghost->getOwnedStructure(i);
		ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();

		if (structure == nullptr || structure->isCivicStructure() || structure->isGCWBase())
			continue;

		if (hasRemoteMaintenanceAdminRights(structure, creature) && !structureIDs->contains(structureID))
			structureIDs->add(structureID);
	}

	// PlayerObject tracks ownership only; it does not maintain a reverse list of
	// structures where a character or guild has ADMIN permission. The existing
	// playerstructures database is therefore scanned to discover those entries.
	// No structure data or permissions are modified by this scan.
	ObjectDatabase* structureDatabase = ObjectDatabaseManager::instance()->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr)
		return;

	ObjectDatabaseIterator iterator(structureDatabase);
	ObjectInputStream objectData(2000);
	uint64 structureID = 0;

	try {
		while (iterator.getNextKeyAndValue(structureID, &objectData)) {
			if (!structureIDs->contains(structureID)) {
				ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();

				if (structure != nullptr && !structure->isCivicStructure() && !structure->isGCWBase() &&
						structure->getBaseMaintenanceRate() > 0 &&
						hasRemoteMaintenanceAdminRights(structure, creature)) {
					structureIDs->add(structureID);
				}
			}

			objectData.reset();
		}
	} catch (Exception& e) {
		error("Unable to discover administered structures for remote maintenance: " + e.getMessage());
	}
}

bool StructureManager::hasRemotePowerAdminRights(StructureObject* structure, CreatureObject* creature) const {
	if (structure == nullptr || creature == nullptr)
		return false;

	uint64 creatureID = creature->getObjectID();

	if (structure->getOwnerObjectID() == creatureID)
		return true;

	if (structure->isOnAdminList(creatureID))
		return true;

	ManagedReference<GuildObject*> guild = creature->getGuildObject().get();

	return guild != nullptr && structure->isOnAdminList(guild->getObjectID());
}

void StructureManager::getRemotePowerStructureIDs(CreatureObject* creature, Vector<uint64>* structureIDs) {
	if (creature == nullptr || structureIDs == nullptr || server == nullptr)
		return;

	structureIDs->removeAll();

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	// Add owned installations first so newly placed objects are available even
	// before their latest state has been flushed to the playerstructures DB.
	for (int i = 0; i < ghost->getTotalOwnedStructureCount(); ++i) {
		uint64 structureID = ghost->getOwnedStructure(i);
		ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();

		if (structure == nullptr || !structure->isInstallationObject() || structure->isGeneratorObject() ||
				(!structure->isHarvesterObject() && !structure->isFactory()) ||
				structure->getBasePowerRate() <= 0)
			continue;

		if (hasRemotePowerAdminRights(structure, creature) && !structureIDs->contains(structureID))
			structureIDs->add(structureID);
	}

	// PlayerObject only tracks ownership. Scan the existing playerstructures
	// database to discover installations where the character or guild has ADMIN.
	// This scan is read-only and does not alter permissions or installation data.
	ObjectDatabase* structureDatabase = ObjectDatabaseManager::instance()->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr)
		return;

	ObjectDatabaseIterator iterator(structureDatabase);
	ObjectInputStream objectData(2000);
	uint64 structureID = 0;

	try {
		while (iterator.getNextKeyAndValue(structureID, &objectData)) {
			if (!structureIDs->contains(structureID)) {
				ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();

				if (structure != nullptr && structure->isInstallationObject() && !structure->isGeneratorObject() &&
						(structure->isHarvesterObject() || structure->isFactory()) &&
						structure->getBasePowerRate() > 0 &&
						hasRemotePowerAdminRights(structure, creature)) {
					structureIDs->add(structureID);
				}
			}

			objectData.reset();
		}
	} catch (Exception& e) {
		error("Unable to discover administered installations for remote power management: " + e.getMessage());
	}
}

void StructureManager::promptRemotePayMaintenance(StructureObject* structure, CreatureObject* creature) {
	if (structure == nullptr || creature == nullptr)
		return;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	// This check is specific to the remote command and does not alter any of the
	// existing local structure permission or maintenance systems.
	if (!hasRemoteMaintenanceAdminRights(structure, creature)) {
		creature->sendSystemMessage("You are not an administrator for that structure.");
		return;
	}

	if (structure->isCivicStructure() || structure->isGCWBase()) {
		creature->sendSystemMessage("That structure cannot be funded through remote maintenance management.");
		return;
	}

	int cash = creature->getCashCredits();
	int bank = creature->getBankCredits();
	int availableCredits = cash + bank;

	if (availableCredits <= 0) {
		creature->sendSystemMessage("@player_structure:no_money");
		return;
	}

	structure->updateStructureStatus();

	String structureName = structure->getDisplayedName();
	if (structureName.isEmpty())
		structureName = "Unnamed Structure";

	String planet = "Unknown";
	if (structure->getZone() != nullptr)
		planet = structure->getZone()->getZoneName();

	int surplusMaintenance = (int)floor((float)structure->getSurplusMaintenance());
	float totalMaintenanceRate = structure->getMaintenanceRate();

	ManagedReference<CityRegion*> city = structure->getCityRegion().get();
	if (structure->isBuildingObject() && city != nullptr &&
			!city->isClientRegion() && city->getPropertyTax() > 0) {
		totalMaintenanceRate += totalMaintenanceRate * city->getPropertyTax() / 100.0f;
	}

	String maintenanceRemaining = "No maintenance required";
	if (totalMaintenanceRate > 0.0f) {
		if (surplusMaintenance > 0) {
			uint64 secondsRemaining =
				(uint64)(((double)surplusMaintenance / (double)totalMaintenanceRate) * 3600.0);

			maintenanceRemaining = getTimeString((uint32)secondsRemaining);
		} else {
			maintenanceRemaining = "Expired";
		}
	}

	if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_PAY))
		ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_PAY);

	ManagedReference<SuiTransferBox*> sui = new SuiTransferBox(creature, SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_PAY);
	sui->setCallback(new RemoteStructurePayMaintenanceSuiCallback(server));
	sui->setPromptTitle("Manage Maintenance");

	// Do not bind the remote structure as the SUI target. A distant or
	// off-planet object causes the client to close the interface before the
	// response reaches the server. Keep the character as the valid client-side
	// target and store the selected structure separately for the callback.
	sui->setUsingObject(creature);
	sui->setStructureObject(structure);
	sui->setForceCloseDisabled();

	StringBuffer prompt;
	prompt << "Add maintenance to " << structureName << " [" << planet << "].\n\n";
	prompt << "Maintenance Pool: " << surplusMaintenance << " credits\n";
	prompt << "Maintenance Rate: " << (int)ceil(totalMaintenanceRate) << " credits per hour\n";
	prompt << "Maintenance Remaining: " << maintenanceRemaining;

	if (structure->isInstallationObject() && !structure->isGeneratorObject()) {
		InstallationObject* installation = cast<InstallationObject*>(structure);

		if (installation != nullptr) {
			int powerPool = installation->getSurplusPower();
			float powerRate = installation->getBasePowerRate();
			String powerRemaining = "No power required";

			if (powerRate > 0.0f) {
				if (powerPool > 0) {
					uint64 powerSecondsRemaining =
						(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

					powerRemaining = getTimeString((uint32)powerSecondsRemaining);
				} else {
					powerRemaining = "Depleted";
				}
			}

			prompt << "\n\nPower Reserve: " << powerPool << " units\n";
			prompt << "Power Consumption: " << (int)ceil(powerRate) << " units per hour\n";
			prompt << "Power Remaining: " << powerRemaining << "\n";
			prompt << "Installation Status: " << (installation->isActive() ? "Active" : "Inactive");
		}
	} else if (structure->isGeneratorObject()) {
		prompt << "\n\nPower Deposit: Not required for generators";
	}

	prompt << "\n\nEnter the amount of maintenance to add below.";
	sui->setPromptText(prompt.toString());

	// Match the existing local maintenance flow: cash is used first, and any
	// remaining amount is taken from the bank account.
	sui->addFrom("@player_structure:total_funds", String::valueOf(availableCredits), String::valueOf(availableCredits), "1");
	sui->addTo("@player_structure:to_pay", "0", "0", "1");

	ghost->addSuiBox(sui);
	creature->sendMessage(sui->generateMessage());
}

void StructureManager::promptRemoteAddPower(StructureObject* structure, CreatureObject* creature) {
	if (structure == nullptr || creature == nullptr)
		return;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	if (!hasRemotePowerAdminRights(structure, creature)) {
		creature->sendSystemMessage("You are not an administrator for that installation.");
		return;
	}

	if (!structure->isInstallationObject() || structure->isGeneratorObject() ||
			(!structure->isHarvesterObject() && !structure->isFactory()) ||
			structure->getBasePowerRate() <= 0) {
		creature->sendSystemMessage("That installation cannot receive power through remote power management.");
		return;
	}

	ManagedReference<ResourceManager*> resourceManager = creature->getZoneServer()->getResourceManager();
	if (resourceManager == nullptr)
		return;

	uint32 availablePower = resourceManager->getAvailablePowerFromPlayer(creature);
	if (availablePower == 0) {
		creature->sendSystemMessage("You do not have any usable energy resources in your inventory.");
		creature->enqueueCommand(STRING_HASHCODE("managepower"), 0, 0, "");
		return;
	}

	InstallationObject* installation = cast<InstallationObject*>(structure);
	if (installation == nullptr)
		return;

	installation->updateStructureStatus();

	String structureName = installation->getDisplayedName();
	if (structureName.isEmpty())
		structureName = "Unnamed Installation";

	String planet = "Unknown";
	if (installation->getZone() != nullptr)
		planet = installation->getZone()->getZoneName();

	int powerPool = (int)floor((float)installation->getSurplusPower());
	float powerRate = installation->getBasePowerRate();
	String powerRemaining = "Depleted";

	if (powerPool > 0 && powerRate > 0.0f) {
		uint64 secondsRemaining =
			(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

		powerRemaining = getTimeString((uint32)secondsRemaining);
	}

	if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_POWER_DEPOSIT))
		ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_POWER_DEPOSIT);

	ManagedReference<SuiTransferBox*> sui = new SuiTransferBox(creature, SuiWindowType::STRUCTURE_REMOTE_POWER_DEPOSIT);
	sui->setCallback(new RemoteStructureAddPowerSuiCallback(server));
	sui->setPromptTitle("Manage Power");

	// A distant/off-planet installation cannot be the client-side SUI target.
	// Bind the interface to the character and retain the selected installation
	// separately for the server callback, matching remote maintenance behavior.
	sui->setUsingObject(creature);
	sui->setStructureObject(installation);
	sui->setForceCloseDisabled();

	StringBuffer prompt;
	prompt << "Add inventory power to " << structureName << " [" << planet << "].\n\n";
	prompt << "Power Reserve: " << powerPool << " units\n";
	prompt << "Power Consumption: " << (int)ceil(powerRate) << " units per hour\n";
	prompt << "Power Remaining: " << powerRemaining << "\n";
	prompt << "Installation Status: " << (installation->isActive() ? "Active" : "Inactive") << "\n\n";
	prompt << "Available Inventory Power: " << availablePower << " units\n\n";
	prompt << "Enter the amount of power to add below.";
	sui->setPromptText(prompt.toString());

	sui->addFrom("@player_structure:total_energy", String::valueOf(availablePower), String::valueOf(availablePower), "1");
	sui->addTo("@player_structure:to_deposit", "0", "0", "1");

	ghost->addSuiBox(sui);
	creature->sendMessage(sui->generateMessage());
}

void StructureManager::promptWithdrawMaintenance(StructureObject* structure, CreatureObject* creature) {
    // NEW: allow guild halls, non-civic buildings (houses), and any installations
    if (!(structure->isGuildHall()
          || (structure->isBuildingObject() && !structure->isCivicStructure())
          || structure->isInstallationObject())) {
        return;
    }

    if (!structure->isOnAdminList(creature)) {
        creature->sendSystemMessage("@player_structure:withdraw_admin_only"); // You must be an administrator to remove credits from the treasury.
        return;
    }

    // Get the most up to date maintenance count.
    structure->updateStructureStatus();

    int surplusMaintenance = structure->getSurplusMaintenance();
    if (surplusMaintenance <= 0) {
        creature->sendSystemMessage("@player_structure:insufficient_funds_withdrawal"); // Insufficient funds for withdrawal.
        return;
    }

    ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
    if (ghost == nullptr)
        return;

    ManagedReference<SuiInputBox*> sui = new SuiInputBox(creature, SuiWindowType::STRUCTURE_MANAGE_MAINTENANCE);
    sui->setCallback(new StructureWithdrawMaintenanceSuiCallback(server));
    sui->setPromptTitle("@player_structure:withdraw_maintenance"); // Withdraw From Treasury
    sui->setUsingObject(structure);
    sui->setPromptText("@player_structure:treasury_prompt " + String::valueOf(surplusMaintenance)); // Treasury:

    ghost->addSuiBox(sui);
    creature->sendMessage(sui->generateMessage());
}

void StructureManager::promptSelectSign(StructureObject* structure, CreatureObject* player) {
	if (!structure->isBuildingObject())
		return;

	// Check building template has signs configured
	Reference<SharedBuildingObjectTemplate*> buildingTemplate = dynamic_cast<SharedBuildingObjectTemplate*>(structure->getObjectTemplate());
	if (buildingTemplate == nullptr) {
		player->sendSystemMessage("ERROR: Unable to get structure template");
		return;
	}

	if (buildingTemplate->getShopSignsSize() == 0) {
		player->sendSystemMessage("This building does not have any additional signs configured");
		return;
	}

	SuiListBox* signBox = new SuiListBox(player, SuiWindowType::STRUCTURE_SELECT_SIGN);
	signBox->setCallback(new StructureSelectSignSuiCallback(player->getZoneServer()));
	signBox->setPromptTitle("@player_structure:changesign_title"); // "Sign Selection"
	signBox->setPromptText("@player_structure:changesign_prompt"); // "Select the sign type that you would like to display"
	signBox->setUsingObject(structure);
	signBox->setCancelButton(true, "@cancel");

	// Loop over all configured signs and add them to the list
	for (int i = 0; i < buildingTemplate->getShopSignsSize(); i++) {
		const SignTemplate* signTemplate = buildingTemplate->getShopSign(i);

		// suiItem string can't be empty
		if (signTemplate->getSuiItem().isEmpty()) {
			continue;
		}

		// Check required skill (if any)
		if (signTemplate->getRequiredSkill().isEmpty()) {
			signBox->addMenuItem(signTemplate->getSuiItem());
		} else {
			if (player->hasSkill(signTemplate->getRequiredSkill())) {
				signBox->addMenuItem(signTemplate->getSuiItem());
			}
		}
	}

	player->sendMessage(signBox->generateMessage());
	player->getPlayerObject()->addSuiBox(signBox);
}

void StructureManager::setSign(StructureObject* structure, CreatureObject* player, String signSuiItem) {
	if (!structure->isBuildingObject())
		return;

	// Check building template has shop signs configured
	Reference<SharedBuildingObjectTemplate*> buildingTemplate = dynamic_cast<SharedBuildingObjectTemplate*>(structure->getObjectTemplate());
	if (buildingTemplate == nullptr) {
		player->sendSystemMessage("ERROR: Unable to get structure template");
		return;
	}

	if (buildingTemplate->getShopSignsSize() == 0) {
		player->sendSystemMessage("This building does not have any signs configured");
		return;
	}

	BuildingObject* building = cast<BuildingObject*>(structure);
	if (building == nullptr)
		return;

	// Find matching sign in the template and change sign
	for (int i = 0; i < buildingTemplate->getShopSignsSize(); i++) {
		const SignTemplate* signTemplate = buildingTemplate->getShopSign(i);

		if (signTemplate->getSuiItem() == signSuiItem) {
			building->changeSign(signTemplate);
			return;
		}
	}
}

void StructureManager::payMaintenance(StructureObject* structure, CreatureObject* creature, int amount) {
	if (amount < 0)
		return;

	int currentMaint = structure->getSurplusMaintenance();

	if (currentMaint + amount > 100000000 || currentMaint + amount < currentMaint) {
		creature->sendSystemMessage("The maximum maintenance a house can hold is 100.000.000");
		return;
	}

	if (creature->getRootParent() != structure && !creature->isInRange(structure, 30.f)) {
		creature->sendSystemMessage("@player_structure:pay_out_of_range");
		return;
	}

	int bank = creature->getBankCredits();
	int cash = creature->getCashCredits();

	StringIdChatParameter params("base_player", "prose_pay_success");
	params.setTT(structure->getDisplayedName());
	params.setDI(amount);

	if (cash < amount) {
		int diff = amount - cash;
		if (diff > bank) {
			creature->sendSystemMessage("@player_structure:insufficient_funds");
			return;
		}
		{
			TransactionLog trx(creature, structure, TrxCode::STRUCTUREMAINTANENCE, amount, true);
			creature->subtractCashCredits(cash);
			creature->subtractBankCredits(diff);
		}
	} else {
		TransactionLog trx(creature, structure, TrxCode::STRUCTUREMAINTANENCE, amount, true);
		creature->subtractCashCredits(amount);
	}

	structure->addMaintenance(amount);
	creature->sendSystemMessage(params);

	if (!ConfigManager::instance()->getBool("Core3.StructureMaintenanceTask.AllowBankPayments", true)) {
		creature->sendSystemMessage("Maintenance will not be pulled from your bank if it runs out.");
	}

	PlayerObject* ghost = creature->getPlayerObject();

	bool hasMerchantFees = ghost->hasAbility("maintenance_fees_1");
	if (hasMerchantFees) {
		structure->setMaintenanceReduced(true);
	} else {
		structure->setMaintenanceReduced(false);
	}

	// Debug: show combined maintenance modifier breakdown
	float merchantMod = hasMerchantFees ? 20.0f : 0.0f;
	float architectMod = structure->getMaintenanceReductionBonus();
	if (architectMod > 25.0f) architectMod = 25.0f;
	float combined = merchantMod + architectMod;
	if (combined > 50.0f) combined = 50.0f;
	float effectiveRate = structure->getMaintenanceRate();
	info(true) << "[Maintenance Debug] structure=" << structure->getObjectID()
	           << " baseMaintDeposit=" << amount
	           << " merchantMod=" << merchantMod << "%"
	           << " architectMod=" << architectMod << "%"
	           << " combinedReduction=" << combined << "%"
	           << " effectiveRate=" << effectiveRate << "cr/hr";
}

void StructureManager::payRemoteMaintenance(StructureObject* structure, CreatureObject* creature, int amount) {
	if (structure == nullptr || creature == nullptr || amount < 0)
		return;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	// Remote administration is rechecked when the transfer is submitted so a
	// stale SUI cannot be used after the character or guild loses ADMIN access.
	if (!hasRemoteMaintenanceAdminRights(structure, creature)) {
		creature->sendSystemMessage("You are no longer an administrator for that structure.");
		return;
	}

	if (structure->isCivicStructure() || structure->isGCWBase()) {
		creature->sendSystemMessage("That structure cannot be funded through remote maintenance management.");
		return;
	}

	structure->updateStructureStatus();

	int currentMaint = structure->getSurplusMaintenance();

	if (currentMaint + amount > 100000000 || currentMaint + amount < currentMaint) {
		creature->sendSystemMessage("The maximum maintenance a house can hold is 100.000.000");
		return;
	}

	int bank = creature->getBankCredits();
	int cash = creature->getCashCredits();

	StringIdChatParameter params("base_player", "prose_pay_success");
	params.setTT(structure->getDisplayedName());
	params.setDI(amount);

	// Deliberately mirrors payMaintenance(): use carried cash first, then bank.
	if (cash < amount) {
		int diff = amount - cash;
		if (diff > bank) {
			creature->sendSystemMessage("@player_structure:insufficient_funds");
			return;
		}
		{
			TransactionLog trx(creature, structure, TrxCode::STRUCTUREMAINTANENCE, amount, true);
			creature->subtractCashCredits(cash);
			creature->subtractBankCredits(diff);
		}
	} else {
		TransactionLog trx(creature, structure, TrxCode::STRUCTUREMAINTANENCE, amount, true);
		creature->subtractCashCredits(amount);
	}

	structure->addMaintenance(amount);
	creature->sendSystemMessage(params);

	if (!ConfigManager::instance()->getBool("Core3.StructureMaintenanceTask.AllowBankPayments", true)) {
		creature->sendSystemMessage("Maintenance will not be pulled from your bank if it runs out.");
	}

	bool hasMerchantFees = ghost->hasAbility("maintenance_fees_1");
	if (hasMerchantFees) {
		structure->setMaintenanceReduced(true);
	} else {
		structure->setMaintenanceReduced(false);
	}

	// Preserve the same maintenance-modifier logging used by local deposits.
	float merchantMod = hasMerchantFees ? 20.0f : 0.0f;
	float architectMod = structure->getMaintenanceReductionBonus();
	if (architectMod > 25.0f) architectMod = 25.0f;
	float combined = merchantMod + architectMod;
	if (combined > 50.0f) combined = 50.0f;
	float effectiveRate = structure->getMaintenanceRate();
	info(true) << "[Maintenance Debug] structure=" << structure->getObjectID()
	           << " baseMaintDeposit=" << amount
	           << " merchantMod=" << merchantMod << "%"
	           << " architectMod=" << architectMod << "%"
	           << " combinedReduction=" << combined << "%"
	           << " effectiveRate=" << effectiveRate << "cr/hr";
}

void StructureManager::addRemotePower(StructureObject* structure, CreatureObject* creature, uint32 amount) {
	if (structure == nullptr || creature == nullptr || amount == 0)
		return;

	// Revalidate every condition when the transfer is submitted so a stale SUI
	// cannot fund a transferred installation or one that no longer needs power.
	if (!hasRemotePowerAdminRights(structure, creature)) {
		creature->sendSystemMessage("You are no longer an administrator for that installation.");
		return;
	}

	if (!structure->isInstallationObject() || structure->isGeneratorObject() ||
			(!structure->isHarvesterObject() && !structure->isFactory()) ||
			structure->getBasePowerRate() <= 0) {
		creature->sendSystemMessage("That installation cannot receive power through remote power management.");
		return;
	}

	ManagedReference<ResourceManager*> resourceManager = creature->getZoneServer()->getResourceManager();
	if (resourceManager == nullptr)
		return;

	uint32 availablePower = resourceManager->getAvailablePowerFromPlayer(creature);
	if (amount > availablePower) {
		StringIdChatParameter params("@player_structure:not_enough_energy");
		params.setDI(amount);
		creature->sendSystemMessage(params);
		return;
	}

	// Use the same conversion and resource-consumption methods as the existing
	// nearby radial menu and /addPower command. No inventory power rules change.
	structure->updateStructureStatus();
	structure->addPower(amount);
	resourceManager->removePowerFromPlayer(creature, amount);

	StringIdChatParameter params("player_structure", "deposit_successful");
	params.setDI(amount);
	creature->sendSystemMessage(params);

	params.setStringId("player_structure", "reserve_report");
	params.setDI((int)structure->getSurplusPower());
	creature->sendSystemMessage(params);

	structure->updateToDatabase();
}

void StructureManager::withdrawMaintenance(StructureObject* structure, CreatureObject* creature, int amount) {
    // NEW: allow guild halls, non-civic buildings (houses), and any installations
    if (!(structure->isGuildHall()
          || (structure->isBuildingObject() && !structure->isCivicStructure())
          || structure->isInstallationObject())) {
        return;
    }

    if (!structure->isOnAdminList(creature)) {
        creature->sendSystemMessage("@player_structure:withdraw_admin_only"); // You must be an administrator to remove credits from the treasury.
        return;
    }

    if (amount < 0)
        return;

    int currentMaint = structure->getSurplusMaintenance();
    if (currentMaint - amount < 0 || currentMaint - amount > currentMaint) {
        creature->sendSystemMessage("@player_structure:insufficient_funds_withdrawal");
        return;
    }

    StringIdChatParameter params("player_structure", "withdraw_credits"); // You withdraw %DI credits from the treasury.
    params.setDI(amount);
    creature->sendSystemMessage(params);

    {
        TransactionLog trx(structure, creature, TrxCode::STRUCTUREMAINTANENCE, amount, true);
        creature->addCashCredits(amount);          // pays to CASH (matches vendor/city pattern)
        structure->subtractMaintenance(amount);    // reduces surplusMaintenance
    }
}

bool StructureManager::isInStructureFootprint(StructureObject* structure, float positionX, float positionY, int extraFootprintMargin) {
	if (structure == nullptr)
		return false;

	if (structure->getObjectTemplate() == nullptr)
		return false;

	Reference<SharedStructureObjectTemplate*> serverTemplate = dynamic_cast<SharedStructureObjectTemplate*>(structure->getObjectTemplate());

	float placingFootprintLength0 = 0, placingFootprintWidth0 = 0, placingFootprintLength1 = 0, placingFootprintWidth1 = 0;

	if (getStructureFootprint(serverTemplate, structure->getDirectionAngle(), placingFootprintLength0, placingFootprintWidth0, placingFootprintLength1, placingFootprintWidth1) != 0)
		return false;

	float x0 = structure->getPositionX() + placingFootprintWidth0 + (placingFootprintWidth0 >= 0 ? extraFootprintMargin : (extraFootprintMargin * -1));
	float y0 = structure->getPositionY() + placingFootprintLength0 + (placingFootprintLength0 >= 0 ? extraFootprintMargin : (extraFootprintMargin * -1));
	float x1 = structure->getPositionX() + placingFootprintWidth1 + (placingFootprintWidth1 >= 0 ? extraFootprintMargin : (extraFootprintMargin * -1));
	float y1 = structure->getPositionY() + placingFootprintLength1 + (placingFootprintLength1 >= 0 ? extraFootprintMargin : (extraFootprintMargin * -1));

	BoundaryRectangle structureFootprint(x0, y0, x1, y1);

	return structureFootprint.containsPoint(positionX, positionY);
}

void StructureManager::promptArchitectRetrofit(CreatureObject* creature, StructureObject* structure) {
	if (creature == nullptr || structure == nullptr)
		return;

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	if (ghost == nullptr)
		return;

	if (!structure->isBuildingObject()) {
		creature->sendSystemMessage("Retrofit failed: target is not a valid building structure.");
		return;
	}

	BuildingObject* building = cast<BuildingObject*>(structure);
	if (building == nullptr)
		return;

	if (!creature->hasSkill("crafting_architect_master")) {
		creature->sendSystemMessage("You must be a Master Architect to offer the retrofit service.");
		return;
	}

	if (ArchitectRetrofitSuiCallback::isRetrofitApplied(building->getObjectID())) {
		creature->sendSystemMessage("This structure has already received its one-time Architect retrofit.");
		return;
	}

	int lots = building->getLotSize();
	if (lots < 1) lots = 1;
	int storagePreview = lots * 50;

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_ARCHITECT_RETROFIT);
	box->setPromptTitle("Architect Retrofit Service");

	StringBuffer promptText;
	promptText << "Choose one retrofit type to permanently upgrade this structure.\n\n"
	           << "This is a one-time service — the selection cannot be undone or changed.\n\n"
	           << "Structure size: " << lots << " lot" << (lots == 1 ? "" : "s") << "\n"
	           << "Storage Expansion: +" << storagePreview << " item capacity\n"
	           << "Maintenance Efficiency: 25% reduction (stacks with Merchant discount, combined cap 50%)";
	box->setPromptText(promptText.toString());

	StringBuffer storageLabel;
	storageLabel << "Storage Expansion Retrofit  (+" << storagePreview << " item capacity)";
	box->addMenuItem(storageLabel.toString());
	box->addMenuItem("Maintenance Efficiency Retrofit  (25% reduction, stacks with Merchant discount)");
	box->setUsingObject(structure);
	box->setForceCloseDisabled();

	ArchitectRetrofitSuiCallback* callback = new ArchitectRetrofitSuiCallback(server, building);
	box->setCallback(callback);

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}


// BELLUM_GERO_STRUCTURE_RECOVERY_AUDIT_BUILD1
// READ ONLY: scans playerstructures.db and reports recovery candidates.
// This function does not write, repair, remove, or re-index any object.
String StructureManager::auditPlayerStructuresForRecovery(bool logDetails) {
	struct AuditStats {
		int totalRecords = 0;
		int healthyZones = 0;
		int missingZones = 0;
		int emptyZones = 0;
		int invalidZones = 0;
		int unreadableRecords = 0;
		int highConfidenceRecovery = 0;
		int manualReview = 0;
		int waypointUnavailable = 0;
		int waypointResolved = 0;
		int footprintConflicts = 0;
		int footprintIndeterminate = 0;
	};

	constexpr int maxSummaryOIDs = 25;

	StringBuffer highConfidenceOIDs;
	StringBuffer manualReviewOIDs;
	int highConfidenceOIDCount = 0;
	int manualReviewOIDCount = 0;

	auto appendSummaryOID = [maxSummaryOIDs](StringBuffer& buffer, int& count, uint64 objectID) {
		if (count < maxSummaryOIDs) {
			if (count > 0)
				buffer << ", ";
			buffer << objectID;
		}
		++count;
	};

	auto dbManager = ObjectDatabaseManager::instance();
	auto structureDatabase = dbManager->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr)
		return "Structure Recovery Audit: playerstructures database unavailable";

	berkeley::CursorConfig config;
	config.setReadUncommitted(true);

	ObjectDatabaseIterator iterator(structureDatabase, config);
	ObjectInputStream objectData(2000);
	uint64 objectID = 0;
	AuditStats stats;

	while (iterator.getNextKeyAndValue(objectID, &objectData)) {
		++stats.totalRecords;

		String className;
		String zoneReference;
		uint32 serverObjectCRC = 0;
		uint64 ownerObjectID = 0;
		uint64 waypointID = 0;
		bool hasZoneVariable = false;

		try {
			Serializable::getVariable<String>(
				STRING_HASHCODE("_className"), &className, &objectData);
			Serializable::getVariable<uint32>(
				STRING_HASHCODE("SceneObject.serverObjectCRC"),
				&serverObjectCRC, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.ownerObjectID"),
				&ownerObjectID, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.waypointID"),
				&waypointID, &objectData);
			hasZoneVariable = Serializable::getVariable<String>(
				STRING_HASHCODE("SceneObject.zone"),
				&zoneReference, &objectData);
		} catch (const Exception& e) {
			++stats.unreadableRecords;
			++stats.manualReview;
			appendSummaryOID(manualReviewOIDs, manualReviewOIDCount, objectID);

			if (logDetails) {
				warning() << "STRUCTURE-RECOVERY-AUDIT: OID=" << objectID
					<< " issue=UNREADABLE_RECORD recovery=MANUAL"
					<< " error=\"" << e.getMessage() << "\"";
			}

			objectData.reset();
			continue;
		} catch (...) {
			++stats.unreadableRecords;
			++stats.manualReview;
			appendSummaryOID(manualReviewOIDs, manualReviewOIDCount, objectID);

			if (logDetails) {
				warning() << "STRUCTURE-RECOVERY-AUDIT: OID=" << objectID
					<< " issue=UNREADABLE_RECORD recovery=MANUAL";
			}

			objectData.reset();
			continue;
		}

		Zone* persistedZone = nullptr;
		bool zoneHealthy = false;
		String issue;

		if (!hasZoneVariable) {
			++stats.missingZones;
			issue = "MISSING_ZONE";
		} else if (zoneReference.isEmpty()) {
			++stats.emptyZones;
			issue = "EMPTY_ZONE";
		} else {
			persistedZone = server != nullptr ? server->getZone(zoneReference) : nullptr;

			if (persistedZone == nullptr || persistedZone->isSpaceZone()) {
				++stats.invalidZones;
				issue = "INVALID_ZONE";
			} else {
				zoneHealthy = true;
				++stats.healthyZones;
			}
		}

		if (zoneHealthy) {
			objectData.reset();
			continue;
		}

		Reference<SharedStructureObjectTemplate*> structureTemplate =
			dynamic_cast<SharedStructureObjectTemplate*>(
				templateManager->getTemplate(serverObjectCRC));

		String templatePath = structureTemplate != nullptr ?
			structureTemplate->getFullTemplateString() : String("<unresolved>");

		ManagedReference<WaypointObject*> waypoint = nullptr;
		String waypointZone;
		float waypointX = 0.0f;
		float waypointY = 0.0f;
		float waypointZ = 0.0f;

		if (server != nullptr && waypointID != 0)
			waypoint = server->getObject(waypointID).castTo<WaypointObject*>();

		if (waypoint != nullptr) {
			const uint32 planetCRC = waypoint->getPlanetCRC();

			for (int i = 0; i < server->getZoneCount(); ++i) {
				Zone* candidateZone = server->getZone(i);

				if (candidateZone != nullptr &&
					!candidateZone->isSpaceZone() &&
					candidateZone->getZoneCRC() == planetCRC) {
					waypointZone = candidateZone->getZoneName();
					break;
				}
			}

			waypointX = waypoint->getPositionX();
			waypointY = waypoint->getPositionY();
			waypointZ = waypoint->getPositionZ();

			if (!waypointZone.isEmpty())
				++stats.waypointResolved;
			else
				++stats.waypointUnavailable;
		} else {
			++stats.waypointUnavailable;
		}

		const bool missingOrEmptyZone =
			!hasZoneVariable || zoneReference.isEmpty();

		const bool identityHighConfidence =
			missingOrEmptyZone &&
			structureTemplate != nullptr &&
			ownerObjectID != 0 &&
			waypointID != 0 &&
			waypoint != nullptr &&
			!waypointZone.isEmpty();

		StorageManagerNamespace::RecoveryFootprintCheckResult footprintCheck;
		bool recoveryLocationClear = false;

		if (identityHighConfidence) {
			footprintCheck =
				StorageManagerNamespace::checkRecoveryFootprintAvailability(
					this,
					server,
					templateManager,
					structureDatabase,
					objectID,
					structureTemplate,
					waypointZone,
					waypoint);

			recoveryLocationClear =
				footprintCheck.status ==
				StorageManagerNamespace::RECOVERY_FOOTPRINT_CLEAR;

			if (footprintCheck.status ==
					StorageManagerNamespace::RECOVERY_FOOTPRINT_OCCUPIED) {
				++stats.footprintConflicts;
			} else if (!recoveryLocationClear) {
				++stats.footprintIndeterminate;
			}
		}

		const bool highConfidence =
			identityHighConfidence && recoveryLocationClear;

		if (highConfidence) {
			++stats.highConfidenceRecovery;
			appendSummaryOID(highConfidenceOIDs, highConfidenceOIDCount, objectID);
		} else {
			++stats.manualReview;
			appendSummaryOID(manualReviewOIDs, manualReviewOIDCount, objectID);
		}

		if (logDetails) {
			String persistedZoneText;

			if (!hasZoneVariable)
				persistedZoneText = "<missing>";
			else if (zoneReference.isEmpty())
				persistedZoneText = "<empty>";
			else
				persistedZoneText = zoneReference;

			String waypointZoneText =
				waypointZone.isEmpty() ? String("<unresolved>") : waypointZone;

			auto detail = warning();
			detail << "STRUCTURE-RECOVERY-AUDIT:"
				<< " OID=" << objectID
				<< " issue=" << issue
				<< " recovery=" << (highConfidence ? "HIGH" : "MANUAL")
				<< " class=" << (className.isEmpty() ? String("<unknown>") : className)
				<< " template=" << templatePath
				<< " ownerOID=" << ownerObjectID
				<< " waypointOID=" << waypointID
				<< " persistedZone=" << persistedZoneText
				<< " waypointZone=" << waypointZoneText;

			if (waypoint != nullptr) {
				detail << " waypointPos=("
					<< waypointX << "," << waypointY << "," << waypointZ << ")";
			}

			if (identityHighConfidence && !recoveryLocationClear) {
				detail << " recoveryBlock=" << footprintCheck.reason;

				if (footprintCheck.conflictingObjectID != 0)
					detail << " conflictingOID="
						<< footprintCheck.conflictingObjectID;

				if (!footprintCheck.conflictingTemplate.isEmpty())
					detail << " conflictingTemplate="
						<< footprintCheck.conflictingTemplate;

				if (footprintCheck.conflictingObjectID != 0) {
					detail << " conflictingPos=("
						<< footprintCheck.conflictingX << ","
						<< footprintCheck.conflictingY << ")";
				}
			}
		}

		objectData.reset();
	}

	StringBuffer summary;
	summary << "Structure Recovery Audit (READ ONLY)" << endl
		<< "  Total playerstructure records: " << stats.totalRecords << endl
		<< "  Healthy root zones: " << stats.healthyZones << endl
		<< "  Missing SceneObject.zone: " << stats.missingZones << endl
		<< "  Empty SceneObject.zone: " << stats.emptyZones << endl
		<< "  Invalid/non-ground zone: " << stats.invalidZones << endl
		<< "  Unreadable records: " << stats.unreadableRecords << endl
		<< "  Waypoints resolved for damaged roots: " << stats.waypointResolved << endl
		<< "  Waypoints unavailable/unresolved: " << stats.waypointUnavailable << endl
		<< "  Recovery footprint conflicts: " << stats.footprintConflicts << endl
		<< "  Recovery footprint indeterminate: " << stats.footprintIndeterminate << endl
		<< "  HIGH-confidence recovery candidates: " << stats.highConfidenceRecovery << endl
		<< "  Manual review required: " << stats.manualReview << endl;

	if (highConfidenceOIDCount > 0) {
		summary << "  HIGH candidate OIDs: " << highConfidenceOIDs.toString();

		if (highConfidenceOIDCount > maxSummaryOIDs)
			summary << " ... (" << (highConfidenceOIDCount - maxSummaryOIDs)
				<< " additional; see server log)";

		summary << endl;
	}

	if (manualReviewOIDCount > 0) {
		summary << "  Manual-review OIDs: " << manualReviewOIDs.toString();

		if (manualReviewOIDCount > maxSummaryOIDs)
			summary << " ... (" << (manualReviewOIDCount - maxSummaryOIDs)
				<< " additional; see server log)";

		summary << endl;
	}

	summary << "  No database records were modified." << endl
		<< "  Full damaged-structure details were written to the server log.";

	info(true) << endl << summary.toString();

	return summary.toString();
}


// BELLUM_GERO_STRUCTURE_RECOVERY_BUILD1
// Scans the full primary playerstructures database and queues ONLY the same
// HIGH-confidence missing/empty-zone candidates used by structureaudit.
// No playerstructures.db record is changed by this command.
bool StructureManager::queueHighConfidencePlayerStructureRecovery(String& result) {
	if (server == nullptr) {
		result = "ZoneServer is unavailable.";
		return false;
	}

	std::FILE* existing =
		std::fopen(
			StorageManagerNamespace::STRUCTURE_RECOVERY_PENDING_HIGH_PLAN,
			"r");

	if (existing != nullptr) {
		std::fclose(existing);
		result =
			"A HIGH-confidence structure recovery plan is already pending. "
			"Restart/verify that plan before queueing another.";
		return false;
	}

	auto dbManager = ObjectDatabaseManager::instance();
	auto structureDatabase =
		dbManager->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr) {
		result = "playerstructures database unavailable.";
		return false;
	}

	::mkdir(
		StorageManagerNamespace::STRUCTURE_RECOVERY_ROOT_DIR,
		0755);

	std::FILE* plan =
		std::fopen(
			StorageManagerNamespace::STRUCTURE_RECOVERY_PENDING_HIGH_PLAN_TMP,
			"w");

	if (plan == nullptr) {
		result =
			"Could not create temporary HIGH-confidence recovery plan.";
		return false;
	}

	std::fprintf(plan, "BELLUM_GERO_STRUCTURE_RECOVERY_PLAN_V1\n");

	berkeley::CursorConfig config;
	config.setReadUncommitted(true);

	ObjectDatabaseIterator iterator(structureDatabase, config);
	ObjectInputStream objectData(2000);
	uint64 objectID = 0;

	int totalRecords = 0;
	int highCandidates = 0;
	int damagedManual = 0;

	constexpr int maxSummaryOIDs = 25;
	int summaryOIDCount = 0;
	StringBuffer summaryOIDs;

	while (iterator.getNextKeyAndValue(objectID, &objectData)) {
		++totalRecords;

		String zoneReference;
		uint32 serverObjectCRC = 0;
		uint64 ownerObjectID = 0;
		uint64 waypointID = 0;
		bool hasZoneVariable = false;

		try {
			Serializable::getVariable<uint32>(
				STRING_HASHCODE("SceneObject.serverObjectCRC"),
				&serverObjectCRC, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.ownerObjectID"),
				&ownerObjectID, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.waypointID"),
				&waypointID, &objectData);
			hasZoneVariable = Serializable::getVariable<String>(
				STRING_HASHCODE("SceneObject.zone"),
				&zoneReference, &objectData);
		} catch (...) {
			++damagedManual;
			objectData.reset();
			continue;
		}

		if (hasZoneVariable && !zoneReference.isEmpty()) {
			objectData.reset();
			continue;
		}

		Reference<SharedStructureObjectTemplate*> structureTemplate =
			dynamic_cast<SharedStructureObjectTemplate*>(
				templateManager->getTemplate(serverObjectCRC));

		ManagedReference<WaypointObject*> waypoint = nullptr;
		String waypointZone;

		if (server != nullptr && waypointID != 0)
			waypoint =
				server->getObject(waypointID).castTo<WaypointObject*>();

		if (waypoint != nullptr) {
			const uint32 planetCRC = waypoint->getPlanetCRC();

			for (int i = 0; i < server->getZoneCount(); ++i) {
				Zone* candidateZone = server->getZone(i);

				if (candidateZone != nullptr &&
						!candidateZone->isSpaceZone() &&
						candidateZone->getZoneCRC() == planetCRC) {
					waypointZone = candidateZone->getZoneName();
					break;
				}
			}
		}

		const bool identityHighConfidence =
			structureTemplate != nullptr &&
			ownerObjectID != 0 &&
			waypointID != 0 &&
			waypoint != nullptr &&
			!waypointZone.isEmpty();

		if (!identityHighConfidence) {
			++damagedManual;
			objectData.reset();
			continue;
		}

		auto footprintCheck =
			StorageManagerNamespace::checkRecoveryFootprintAvailability(
				this,
				server,
				templateManager,
				structureDatabase,
				objectID,
				structureTemplate,
				waypointZone,
				waypoint);

		if (footprintCheck.status !=
				StorageManagerNamespace::RECOVERY_FOOTPRINT_CLEAR) {
			++damagedManual;

			warning() << "STRUCTURE-RECOVERY-EXCLUDED:"
				<< " OID=" << objectID
				<< " reason=" << footprintCheck.reason
				<< " recoveredZone=" << waypointZone
				<< " conflictingOID="
				<< footprintCheck.conflictingObjectID
				<< " conflictingTemplate="
				<< (footprintCheck.conflictingTemplate.isEmpty() ?
					String("<unknown>") :
					footprintCheck.conflictingTemplate)
				<< " conflictingPos=("
				<< footprintCheck.conflictingX << ","
				<< footprintCheck.conflictingY << ")";

			objectData.reset();
			continue;
		}

		std::fprintf(
			plan,
			"%llu|%s|%llu|%llu|%u\n",
			(unsigned long long)objectID,
			waypointZone.toCharArray(),
			(unsigned long long)ownerObjectID,
			(unsigned long long)waypointID,
			serverObjectCRC);

		++highCandidates;

		if (summaryOIDCount < maxSummaryOIDs) {
			if (summaryOIDCount > 0)
				summaryOIDs << ", ";

			summaryOIDs << objectID;
		}

		++summaryOIDCount;

		warning() << "STRUCTURE-RECOVERY-QUEUED:"
			<< " OID=" << objectID
			<< " recoveredZone=" << waypointZone
			<< " ownerOID=" << ownerObjectID
			<< " waypointOID=" << waypointID
			<< " serverObjectCRC=" << serverObjectCRC;

		objectData.reset();
	}

	std::fclose(plan);

	if (highCandidates == 0) {
		std::remove(
			StorageManagerNamespace::
				STRUCTURE_RECOVERY_PENDING_HIGH_PLAN_TMP);

		StringBuffer none;
		none << "HIGH-Confidence Structure Recovery" << endl
			<< "  Total playerstructure records scanned: "
			<< totalRecords << endl
			<< "  HIGH-confidence candidates: 0" << endl
			<< "  Damaged/manual-review records: "
			<< damagedManual << endl
			<< "  No recovery plan was created." << endl
			<< "  No database records were modified.";

		result = none.toString();
		return true;
	}

	if (std::rename(
			StorageManagerNamespace::
				STRUCTURE_RECOVERY_PENDING_HIGH_PLAN_TMP,
			StorageManagerNamespace::
				STRUCTURE_RECOVERY_PENDING_HIGH_PLAN) != 0) {
		std::remove(
			StorageManagerNamespace::
				STRUCTURE_RECOVERY_PENDING_HIGH_PLAN_TMP);

		result =
			"Could not atomically publish the HIGH-confidence recovery plan. "
			"No database records were modified.";
		return false;
	}

	StringBuffer queued;
	queued << "HIGH-Confidence Structure Recovery Plan QUEUED" << endl
		<< "  Total playerstructure records scanned: "
		<< totalRecords << endl
		<< "  HIGH-confidence candidates queued: "
		<< highCandidates << endl
		<< "  Damaged/manual-review records excluded: "
		<< damagedManual << endl
		<< "  Candidate OIDs: " << summaryOIDs.toString();

	if (summaryOIDCount > maxSummaryOIDs)
		queued << " ... ("
			<< (summaryOIDCount - maxSummaryOIDs)
			<< " additional; see server log)";

	queued << endl
		<< "  No playerstructures.db record was changed live." << endl
		<< "  Restart Core3 to apply the queued root-zone repairs." << endl
		<< "  The plan remains until a later startup verifies all repairs.";

	result = queued.toString();

	return true;
}

// BELLUM_GERO_STRUCTURE_RECOVERY_BUILD1
// Startup-only recovery/verification pass.
// Returns the number of playerstructures DB records staged for repair.
// Caller commits before concurrent ground-zone manager startup when > 0.
int StructureManager::applyPendingHighConfidencePlayerStructureRecovery() {
	std::FILE* plan =
		std::fopen(
			StorageManagerNamespace::STRUCTURE_RECOVERY_PENDING_HIGH_PLAN,
			"r");

	if (plan == nullptr)
		return 0;

	char header[128] = {0};

	if (std::fgets(header, sizeof(header), plan) == nullptr ||
			String(header).trim() !=
				"BELLUM_GERO_STRUCTURE_RECOVERY_PLAN_V1") {
		std::fclose(plan);
		warning(
			"STRUCTURE-RECOVERY: pending recovery plan has an invalid header; "
			"marker retained and no DB changes made.");
		return 0;
	}

	auto dbManager = ObjectDatabaseManager::instance();
	auto structureDatabase =
		dbManager->loadObjectDatabase("playerstructures", true);

	if (structureDatabase == nullptr) {
		std::fclose(plan);
		warning(
			"STRUCTURE-RECOVERY: playerstructures DB unavailable; "
			"plan retained.");
		return 0;
	}

        // BELLUM_GERO_STRUCTURE_RECOVERY_SECONDARY_INDEX_BUILD2
        // Recovery writes must occur while the Berkeley secondary association is
        // active. Otherwise SceneObject.zone can be repaired in playerstructures.db
        // without recreating the planet -> OID entry in playerstructuresindex.db.
        IndexDatabase* playerStructuresDatabaseIndex = createSubIndex();

        auto hasExpectedRecoverySecondaryIndexEntry =
                [playerStructuresDatabaseIndex](
                        uint64 expectedHash, uint64 objectID) -> bool {
                        if (playerStructuresDatabaseIndex == nullptr ||
                                        expectedHash == 0 ||
                                        objectID == 0) {
                                return false;
                        }

                        berkeley::CursorConfig indexConfig;
                        indexConfig.setReadUncommitted(true);

                        IndexDatabaseIterator indexIterator(
                                playerStructuresDatabaseIndex,
                                indexConfig);

                        uint64 indexedObjectID = 0;

                        if (!indexIterator.setKeyAndGetValue(
                                        expectedHash,
                                        indexedObjectID,
                                        nullptr)) {
                                return false;
                        }

                        if (indexedObjectID == objectID)
                                return true;

                        while (indexIterator.getNextKeyAndValue(
                                        expectedHash,
                                        indexedObjectID,
                                        nullptr)) {
                                if (indexedObjectID == objectID)
                                        return true;
                        }

                        return false;
                };



	int totalPlanEntries = 0;
	int stagedRepairs = 0;
	int verifiedRepairs = 0;
	int refusedEntries = 0;

	char line[1024] = {0};

	while (std::fgets(line, sizeof(line), plan) != nullptr) {
		unsigned long long rawOID = 0;
		unsigned long long rawOwner = 0;
		unsigned long long rawWaypoint = 0;
		unsigned int rawCRC = 0;
		char zoneBuffer[128] = {0};

		int parsed =
			std::sscanf(
				line,
				"%llu|%127[^|]|%llu|%llu|%u",
				&rawOID,
				zoneBuffer,
				&rawOwner,
				&rawWaypoint,
				&rawCRC);

		if (parsed != 5 ||
				rawOID == 0 ||
				rawOwner == 0 ||
				rawWaypoint == 0 ||
				rawCRC == 0 ||
				zoneBuffer[0] == '\0') {
			++refusedEntries;
			warning(
				"STRUCTURE-RECOVERY: malformed recovery-plan entry; "
				"plan retained.");
			continue;
		}

		++totalPlanEntries;

		uint64 objectID = (uint64)rawOID;
		uint64 expectedOwner = (uint64)rawOwner;
		uint64 expectedWaypoint = (uint64)rawWaypoint;
		uint32 expectedCRC = (uint32)rawCRC;
		String expectedZone = zoneBuffer;

		Zone* expectedZoneObject =
			server != nullptr ? server->getZone(expectedZone) : nullptr;

		if (expectedZoneObject == nullptr ||
				expectedZoneObject->isSpaceZone()) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=EXPECTED_ZONE_NOT_VALID_GROUND"
				<< " expectedZone=" << expectedZone;
			continue;
		}

		ObjectInputStream objectData(2000);

		if (structureDatabase->getData(objectID, &objectData)) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=OID_NOT_FOUND";
			continue;
		}

		String currentZone;
		uint32 currentCRC = 0;
		uint64 currentOwner = 0;
		uint64 currentWaypoint = 0;
		bool hasZoneVariable = false;

		try {
			Serializable::getVariable<uint32>(
				STRING_HASHCODE("SceneObject.serverObjectCRC"),
				&currentCRC, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.ownerObjectID"),
				&currentOwner, &objectData);
			Serializable::getVariable<uint64>(
				STRING_HASHCODE("StructureObject.waypointID"),
				&currentWaypoint, &objectData);
			hasZoneVariable = Serializable::getVariable<String>(
				STRING_HASHCODE("SceneObject.zone"),
				&currentZone, &objectData);
		} catch (...) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=DESERIALIZE_FAILED";
			continue;
		}

		Reference<SharedStructureObjectTemplate*> structureTemplate =
			dynamic_cast<SharedStructureObjectTemplate*>(
				templateManager->getTemplate(currentCRC));

		if (structureTemplate == nullptr ||
				currentCRC != expectedCRC ||
				currentOwner != expectedOwner ||
				currentWaypoint != expectedWaypoint) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=PERSISTED_EVIDENCE_CHANGED"
				<< " currentCRC=" << currentCRC
				<< " expectedCRC=" << expectedCRC
				<< " currentOwner=" << currentOwner
				<< " expectedOwner=" << expectedOwner
				<< " currentWaypoint=" << currentWaypoint
				<< " expectedWaypoint=" << expectedWaypoint;
			continue;
		}

		ManagedReference<WaypointObject*> waypoint =
			server != nullptr && currentWaypoint != 0 ?
				server->getObject(currentWaypoint).castTo<WaypointObject*>() :
				nullptr;

		String waypointZone;

		if (waypoint != nullptr) {
			const uint32 waypointPlanetCRC = waypoint->getPlanetCRC();

			for (int i = 0; i < server->getZoneCount(); ++i) {
				Zone* candidateZone = server->getZone(i);

				if (candidateZone != nullptr &&
						!candidateZone->isSpaceZone() &&
						candidateZone->getZoneCRC() ==
							waypointPlanetCRC) {
					waypointZone = candidateZone->getZoneName();
					break;
				}
			}
		}

		if (waypoint == nullptr ||
				waypointZone.isEmpty() ||
				waypointZone != expectedZone) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=WAYPOINT_EVIDENCE_NO_LONGER_MATCHES"
				<< " expectedZone=" << expectedZone
				<< " waypointZone="
				<< (waypointZone.isEmpty() ?
					String("<unresolved>") : waypointZone);
			continue;
		}

				if (hasZoneVariable && !currentZone.isEmpty()) {
		        if (currentZone != expectedZone) {
		                ++refusedEntries;
		                warning() << "STRUCTURE-RECOVERY-REFUSED:"
		                        << " OID=" << objectID
		                        << " reason=CONFLICTING_NONEMPTY_ZONE"
		                        << " currentZone=" << currentZone
		                        << " expectedZone=" << expectedZone;
		                continue;
		        }

		        const uint64 expectedZoneHash = expectedZone.hashCode();

		        if (hasExpectedRecoverySecondaryIndexEntry(
		                        expectedZoneHash,
		                        objectID)) {
		                ++verifiedRepairs;
		                warning() << "STRUCTURE-RECOVERY-VERIFIED:"
		                        << " OID=" << objectID
		                        << " zone=" << expectedZone
		                        << " secondaryIndex=present";
		                continue;
		        }

		        // BELLUM_GERO_STRUCTURE_RECOVERY_SECONDARY_INDEX_BUILD2
		        // Root zone is correct but the secondary entry is missing.
		        // Re-put an unchanged copy of the primary record while the
		        // association is active so indexCallback recreates the
		        // expected zoneHash -> OID mapping.
		        ObjectOutputStream* refreshedRecord =
		                new ObjectOutputStream(objectData.size());
		        objectData.reset();
		        objectData.copy(refreshedRecord);
		        refreshedRecord->reset();
		        objectData.reset();


			// Recheck the original footprint immediately before rebuilding the
			// secondary index. The root zone may already have been repaired on a
			// prior startup while the structure remained invisible because its
			// index entry was missing. A replacement could have been placed in
			// that footprint since then, so index refresh must fail closed too.
			auto indexRefreshFootprintCheck =
				StorageManagerNamespace::checkRecoveryFootprintAvailability(
					this,
					server,
					templateManager,
					structureDatabase,
					objectID,
					structureTemplate,
					expectedZone,
					waypoint);

			if (indexRefreshFootprintCheck.status !=
					StorageManagerNamespace::RECOVERY_FOOTPRINT_CLEAR) {
				++refusedEntries;

				warning() << "STRUCTURE-RECOVERY-REFUSED:"
					<< " OID=" << objectID
					<< " reason=" << indexRefreshFootprintCheck.reason
					<< " phase=SECONDARY_INDEX_REFRESH"
					<< " expectedZone=" << expectedZone
					<< " conflictingOID="
					<< indexRefreshFootprintCheck.conflictingObjectID
					<< " conflictingTemplate="
					<< (indexRefreshFootprintCheck.conflictingTemplate.isEmpty() ?
						String("<unknown>") :
						indexRefreshFootprintCheck.conflictingTemplate)
					<< " conflictingPos=("
					<< indexRefreshFootprintCheck.conflictingX << ","
					<< indexRefreshFootprintCheck.conflictingY << ")";

				continue;
			}

structureDatabase->putData(
		                objectID,
		                refreshedRecord,
		                nullptr);

		        ++stagedRepairs;

		        warning() << "STRUCTURE-RECOVERY-INDEX-REFRESH-STAGED:"
		                << " OID=" << objectID
		                << " zone=" << expectedZone
		                << " expectedHash=" << expectedZoneHash
		                << " plan retained for next-start verification.";

		        continue;
		}

		// BELLUM_GERO_STRUCTURE_RECOVERY_FOOTPRINT_GUARD_BUILD1
		// Recheck the original footprint immediately before the startup DB
		// mutation. This closes the audit/queue -> replacement -> restart race.
		auto footprintCheck =
			StorageManagerNamespace::checkRecoveryFootprintAvailability(
				this,
				server,
				templateManager,
				structureDatabase,
				objectID,
				structureTemplate,
				expectedZone,
				waypoint);

		if (footprintCheck.status !=
				StorageManagerNamespace::RECOVERY_FOOTPRINT_CLEAR) {
			++refusedEntries;

			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=" << footprintCheck.reason
				<< " expectedZone=" << expectedZone
				<< " conflictingOID="
				<< footprintCheck.conflictingObjectID
				<< " conflictingTemplate="
				<< (footprintCheck.conflictingTemplate.isEmpty() ?
					String("<unknown>") :
					footprintCheck.conflictingTemplate)
				<< " conflictingPos=("
				<< footprintCheck.conflictingX << ","
				<< footprintCheck.conflictingY << ")";

			continue;
		}

		String zoneValue = expectedZone;
		ObjectOutputStream zoneData;
		TypeInfo<String>::toBinaryStream(&zoneValue, &zoneData);

		ObjectOutputStream* modifiedRecord =
			hasZoneVariable ?
				StorageManagerNamespace::
					replaceSerializedVariableDataForStructureRecovery(
						STRING_HASHCODE("SceneObject.zone"),
						&objectData,
						&zoneData) :
				StorageManagerNamespace::
					addSerializedVariableDataForStructureRecovery(
						"SceneObject.zone",
						&objectData,
						&zoneData);

		if (modifiedRecord == nullptr) {
			++refusedEntries;
			warning() << "STRUCTURE-RECOVERY-REFUSED:"
				<< " OID=" << objectID
				<< " reason=COULD_NOT_BUILD_REPAIRED_RECORD";
			continue;
		}

		modifiedRecord->reset();

		structureDatabase->putData(
			objectID,
			modifiedRecord,
			nullptr);

		++stagedRepairs;

		warning() << "STRUCTURE-RECOVERY-STAGED:"
			<< " OID=" << objectID
			<< " recoveredZone=" << expectedZone
			<< " ownerOID=" << expectedOwner
			<< " waypointOID=" << expectedWaypoint
			<< " plan retained for next-start verification.";
	}

	std::fclose(plan);

	if (totalPlanEntries == 0) {
		warning(
			"STRUCTURE-RECOVERY: recovery plan contained no valid entries; "
			"plan retained.");
		return 0;
	}

	if (stagedRepairs == 0 &&
			refusedEntries == 0 &&
			verifiedRepairs == totalPlanEntries) {
		if (std::remove(
				StorageManagerNamespace::
					STRUCTURE_RECOVERY_PENDING_HIGH_PLAN) == 0) {
			warning() << "STRUCTURE-RECOVERY-PLAN-VERIFIED:"
				<< " entries=" << verifiedRepairs
				<< " root zones and secondary index entries verified; plan consumed.";
		} else {
			warning(
				"STRUCTURE-RECOVERY-PLAN-VERIFIED: all entries verified but "
				"plan file could not be removed; it will verify again.");
		}
	} else {
		warning() << "STRUCTURE-RECOVERY-PLAN-STATUS:"
			<< " entries=" << totalPlanEntries
			<< " staged=" << stagedRepairs
			<< " verified=" << verifiedRepairs
			<< " refused=" << refusedEntries
			<< " plan retained.";
	}

	return stagedRepairs;
}
