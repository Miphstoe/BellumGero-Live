/*
 * WorldBuilderPublishedStructureResolver.h
 *
 * Bellum Gero World Builder V1.9.8
 * Durable identity resolver for already-published World Builder structures.
 *
 * Saved WBP V3 extension relationships use only:
 *   publish ID + parent Structure local ID + Cell number/room.
 *
 * Runtime BuildingObject/CellObject IDs are resolved from the active snapshot
 * and are never written to the WBP project file.
 */

#ifndef WORLDBUILDERPUBLISHEDSTRUCTURERESOLVER_H_
#define WORLDBUILDERPUBLISHEDSTRUCTURERESOLVER_H_

#include "templates/manager/TemplateManager.h"
#include "templates/SharedObjectTemplate.h"
#include "templates/snapshot/WorldSnapshotIff.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include <string>

struct WorldBuilderPublishedStructureIdentity {
	String publishID;
	uint32 structureLocalID;
	uint64 rootObjectID;
	String serverTemplate;
	String sharedTemplate;

	WorldBuilderPublishedStructureIdentity() : structureLocalID(0), rootObjectID(0) {
	}
};

class WorldBuilderPublishedStructureResolver {
private:
	static uint64 reservedMin() {
		return 0x60000000ULL;
	}

	static uint64 reservedMax() {
		return 0x6FFFFFFFULL;
	}

	static bool isReservedOID(uint64 objectID) {
		return objectID >= reservedMin() && objectID <= reservedMax();
	}

	static bool parsePositiveUInt(const std::string& text, uint32& value) {
		if (text.empty())
			return false;

		uint64 result = 0;
		for (size_t i = 0; i < text.size(); ++i) {
			char c = text[i];
			if (c < '0' || c > '9')
				return false;
			result = result * 10ULL + static_cast<uint64>(c - '0');
			if (result > 0xFFFFFFFFULL)
				return false;
		}

		if (result == 0)
			return false;
		value = static_cast<uint32>(result);
		return true;
	}

	static ManagedReference<SceneObject*> getRuntimeParent(SceneObject* object, ZoneServer* zoneServer) {
		if (object == nullptr || zoneServer == nullptr)
			return nullptr;

		ManagedReference<SceneObject*> parent = object->getParent().get();
		if (parent != nullptr)
			return parent;

		uint64 parentID = object->getParentID();
		if (parentID != 0)
			return zoneServer->getObject(parentID);

		return nullptr;
	}

	static ManagedReference<SceneObject*> findBuildingAncestor(SceneObject* object, ZoneServer* zoneServer) {
		if (object == nullptr || zoneServer == nullptr)
			return nullptr;

		ManagedReference<SceneObject*> current = object;
		for (int depth = 0; depth < 12 && current != nullptr; ++depth) {
			if (current->isBuildingObject())
				return current;
			current = getRuntimeParent(current, zoneServer);
		}

		return nullptr;
	}

	static bool loadSnapshot(CreatureObject* player, WorldSnapshotIff& snapshot, String& errorMessage) {
		if (player == nullptr || player->getZone() == nullptr) {
			errorMessage = "No active ground-zone snapshot context is available.";
			return false;
		}

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr) {
			errorMessage = "TemplateManager is unavailable.";
			return false;
		}

		String snapshotPath = "snapshot/" + player->getZone()->getZoneName() + ".ws";
		IffStream* iffStream = templateManager->openIffFile(snapshotPath);
		if (iffStream == nullptr) {
			errorMessage = "Could not open active snapshot " + snapshotPath + ".";
			return false;
		}

		try {
			snapshot.readObject(iffStream);
		} catch (Exception& e) {
			delete iffStream;
			errorMessage = "Could not parse active snapshot " + snapshotPath + ": " + e.getMessage();
			return false;
		}

		delete iffStream;
		return true;
	}

	static bool validateSnapshotRoot(WorldSnapshotNode* rootNode, WorldSnapshotIff& snapshot,
			const WorldBuilderPublishedStructureIdentity& identity, String& errorMessage) {
		if (rootNode == nullptr) {
			errorMessage = "Published World Builder snapshot root is null.";
			return false;
		}

		if (rootNode->getObjectID() != identity.rootObjectID || rootNode->getParentID() != 0) {
			errorMessage = "Published World Builder root hierarchy does not match the expected top-level snapshot root.";
			return false;
		}

		String snapshotTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());
		if (snapshotTemplate != identity.sharedTemplate) {
			errorMessage = "Published World Builder snapshot template mismatch. Expected '" + identity.sharedTemplate + "' but found '" + snapshotTemplate + "'.";
			return false;
		}

		if (!isReservedOID(rootNode->getObjectID())) {
			errorMessage = "Published structure root OID is outside the reserved World Builder range 0x60000000-0x6FFFFFFF.";
			return false;
		}

		if (rootNode->getNodeCount() <= 0) {
			errorMessage = "Published World Builder structure has no snapshot CellObject hierarchy.";
			return false;
		}

		for (int i = 0; i < rootNode->getNodeCount(); ++i) {
			WorldSnapshotNode* cellNode = rootNode->getNode(i);
			if (cellNode == nullptr || cellNode->getNodeCount() != 0 ||
				cellNode->getParentID() != rootNode->getObjectID() || cellNode->getCellID() <= 0) {
				errorMessage = "Published World Builder snapshot contains an invalid direct CellObject child.";
				return false;
			}

			if (!isReservedOID(cellNode->getObjectID())) {
				errorMessage = "Published World Builder CellObject OID is outside the reserved structural range.";
				return false;
			}

			String cellTemplate = snapshot.getObjectTemplateName(cellNode->getNameID());
			if (cellTemplate != "object/cell/shared_cell.iff") {
				errorMessage = "Published World Builder snapshot child is not object/cell/shared_cell.iff.";
				return false;
			}
		}

		return true;
	}

	static bool validateRuntimeRoot(CreatureObject* player, SceneObject* runtimeRoot,
			WorldBuilderPublishedStructureIdentity& identity, String& errorMessage) {
		if (player == nullptr || runtimeRoot == nullptr || player->getZoneServer() == nullptr) {
			errorMessage = "Published structure runtime context is unavailable.";
			return false;
		}

		if (!runtimeRoot->isBuildingObject()) {
			errorMessage = "Resolved object is not a BuildingObject.";
			return false;
		}

		if (!isReservedOID(runtimeRoot->getObjectID())) {
			errorMessage = "Structure is not using a reserved World Builder structural OID.";
			return false;
		}

		SharedObjectTemplate* runtimeTemplate = runtimeRoot->getObjectTemplate();
		String runtimePath = runtimeTemplate != nullptr ? runtimeTemplate->getFullTemplateString() : String("");
		if (runtimePath != identity.serverTemplate) {
			errorMessage = "Runtime structure template does not match the expected generated World Builder template.";
			return false;
		}

		identity.rootObjectID = runtimeRoot->getObjectID();

		WorldSnapshotIff snapshot;
		if (!loadSnapshot(player, snapshot, errorMessage))
			return false;

		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			if (rootNode == nullptr || rootNode->getObjectID() != identity.rootObjectID)
				continue;

			if (!validateSnapshotRoot(rootNode, snapshot, identity, errorMessage))
				return false;

			for (int n = 0; n < rootNode->getNodeCount(); ++n) {
				WorldSnapshotNode* cellNode = rootNode->getNode(n);
				if (cellNode == nullptr) {
					errorMessage = "Published snapshot contains a null CellObject child.";
					return false;
				}

				ManagedReference<SceneObject*> runtimeCellObject =
					player->getZoneServer()->getObject(cellNode->getObjectID());
				if (runtimeCellObject == nullptr || !runtimeCellObject->isCellObject()) {
					errorMessage = "Published World Builder runtime Cell #" +
						String::valueOf(cellNode->getCellID()) + " (OID " +
						String::valueOf(cellNode->getObjectID()) +
						") is not loaded as the expected CellObject.";
					return false;
				}

				ManagedReference<SceneObject*> runtimeCellParent =
					getRuntimeParent(runtimeCellObject.get(), player->getZoneServer());
				if (runtimeCellParent == nullptr || runtimeCellParent->getObjectID() != identity.rootObjectID) {
					String actualParent = runtimeCellParent != nullptr
						? String::valueOf(runtimeCellParent->getObjectID())
						: String("<none>");
					errorMessage = "Published World Builder runtime Cell #" +
						String::valueOf(cellNode->getCellID()) + " (OID " +
						String::valueOf(cellNode->getObjectID()) +
						") parent mismatch. Expected root=" +
						String::valueOf(identity.rootObjectID) +
						", runtime parent=" + actualParent + ".";
					return false;
				}
			}

			return true;
		}

		errorMessage = "Runtime generated World Builder structure is not present as the expected root in the active planet snapshot.";
		return false;
	}

public:
	static String expectedServerTemplate(const String& publishID, uint32 structureLocalID) {
		return "object/building/worldbuilder/" + publishID + "/structure_" + String::valueOf(structureLocalID) + ".iff";
	}

	static String expectedSharedTemplate(const String& publishID, uint32 structureLocalID) {
		return "object/building/worldbuilder/" + publishID + "/shared_structure_" + String::valueOf(structureLocalID) + ".iff";
	}

	static bool parseGeneratedServerTemplate(const String& serverTemplate,
			WorldBuilderPublishedStructureIdentity& identity) {
		identity = WorldBuilderPublishedStructureIdentity();

		std::string path(serverTemplate.toCharArray());
		const std::string prefix = "object/building/worldbuilder/";
		if (path.compare(0, prefix.size(), prefix) != 0)
			return false;

		size_t publishStart = prefix.size();
		size_t slash = path.find('/', publishStart);
		if (slash == std::string::npos || slash <= publishStart)
			return false;

		std::string publish = path.substr(publishStart, slash - publishStart);
		std::string file = path.substr(slash + 1);
		const std::string structurePrefix = "structure_";
		const std::string suffix = ".iff";
		if (file.compare(0, structurePrefix.size(), structurePrefix) != 0 ||
			file.size() <= structurePrefix.size() + suffix.size() ||
			file.compare(file.size() - suffix.size(), suffix.size(), suffix) != 0)
			return false;

		std::string number = file.substr(
			structurePrefix.size(),
			file.size() - structurePrefix.size() - suffix.size());
		uint32 structureID = 0;
		if (!parsePositiveUInt(number, structureID))
			return false;

		identity.publishID = String(publish.c_str());
		identity.structureLocalID = structureID;
		identity.serverTemplate = expectedServerTemplate(identity.publishID, structureID);
		identity.sharedTemplate = expectedSharedTemplate(identity.publishID, structureID);
		return identity.serverTemplate == serverTemplate;
	}

	static bool identifyRuntimeRoot(CreatureObject* player, SceneObject* object,
			WorldBuilderPublishedStructureIdentity& identity, String& errorMessage) {
		if (player == nullptr || player->getZoneServer() == nullptr || object == nullptr) {
			errorMessage = "No runtime structure candidate is available.";
			return false;
		}

		ManagedReference<SceneObject*> root = findBuildingAncestor(object, player->getZoneServer());
		if (root == nullptr) {
			errorMessage = "No BuildingObject ancestor was found.";
			return false;
		}

		SharedObjectTemplate* runtimeTemplate = root->getObjectTemplate();
		String runtimePath = runtimeTemplate != nullptr ? runtimeTemplate->getFullTemplateString() : String("");
		if (!parseGeneratedServerTemplate(runtimePath, identity)) {
			errorMessage = "Structure is not a generated object/building/worldbuilder/<publish>/structure_<id>.iff template.";
			return false;
		}

		return validateRuntimeRoot(player, root, identity, errorMessage);
	}

	static bool identifyCurrentInterior(CreatureObject* player,
			WorldBuilderPublishedStructureIdentity& identity, String& errorMessage) {
		if (player == nullptr || player->getZoneServer() == nullptr) {
			errorMessage = "No player/zone context is available.";
			return false;
		}

		ManagedReference<SceneObject*> parent = player->getParent().get();
		if (parent == nullptr && player->getParentID() != 0)
			parent = player->getZoneServer()->getObject(player->getParentID());

		if (parent == nullptr || !parent->isCellObject()) {
			errorMessage = "You are not currently inside a structure CellObject.";
			return false;
		}

		return identifyRuntimeRoot(player, parent, identity, errorMessage);
	}

	static bool identifyTargetOrCurrent(CreatureObject* player,
			WorldBuilderPublishedStructureIdentity& identity, String& errorMessage) {
		if (player == nullptr || player->getZoneServer() == nullptr) {
			errorMessage = "No player/zone context is available.";
			return false;
		}

		if (player->getTargetID() != 0) {
			ManagedReference<SceneObject*> target = player->getZoneServer()->getObject(player->getTargetID());
			String targetError;
			if (target != nullptr && identifyRuntimeRoot(player, target, identity, targetError))
				return true;
		}

		return identifyCurrentInterior(player, identity, errorMessage);
	}

	static ManagedReference<CellObject*> resolveCellByIdentity(CreatureObject* player,
			const String& publishID, uint32 structureLocalID, uint32 cellNumber, String& errorMessage) {
		if (cellNumber == 0) {
			errorMessage = "Published World Builder Cell number must be greater than zero.";
			return nullptr;
		}

		ManagedReference<SceneObject*> runtimeRoot =
			resolveByIdentity(player, publishID, structureLocalID, errorMessage);
		if (runtimeRoot == nullptr)
			return nullptr;

		WorldSnapshotIff snapshot;
		if (!loadSnapshot(player, snapshot, errorMessage))
			return nullptr;

		WorldSnapshotNode* matchedRoot = nullptr;
		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			if (rootNode != nullptr && rootNode->getObjectID() == runtimeRoot->getObjectID()) {
				matchedRoot = rootNode;
				break;
			}
		}

		if (matchedRoot == nullptr) {
			errorMessage = "Published World Builder root disappeared from the active snapshot while resolving Cell " +
				String::valueOf(cellNumber) + ".";
			return nullptr;
		}

		WorldSnapshotNode* matchedCell = nullptr;
		for (int i = 0; i < matchedRoot->getNodeCount(); ++i) {
			WorldSnapshotNode* cellNode = matchedRoot->getNode(i);
			if (cellNode != nullptr && cellNode->getCellID() == cellNumber) {
				if (matchedCell != nullptr) {
					errorMessage = "Published World Builder snapshot contains duplicate Cell " +
						String::valueOf(cellNumber) + " records.";
					return nullptr;
				}
				matchedCell = cellNode;
			}
		}

		if (matchedCell == nullptr) {
			errorMessage = publishID + " / Structure #" + String::valueOf(structureLocalID) +
				" does not have Cell " + String::valueOf(cellNumber) + " in the active snapshot.";
			return nullptr;
		}

		ManagedReference<SceneObject*> runtimeCellObject =
			player->getZoneServer()->getObject(matchedCell->getObjectID());
		if (runtimeCellObject == nullptr || !runtimeCellObject->isCellObject()) {
			errorMessage = "Published World Builder Cell " + String::valueOf(cellNumber) +
				" snapshot OID " + String::valueOf(matchedCell->getObjectID()) +
				" is not loaded as a runtime CellObject.";
			return nullptr;
		}

		ManagedReference<SceneObject*> runtimeParent =
			getRuntimeParent(runtimeCellObject.get(), player->getZoneServer());
		if (runtimeParent == nullptr || runtimeParent->getObjectID() != runtimeRoot->getObjectID()) {
			errorMessage = "Published World Builder Cell " + String::valueOf(cellNumber) +
				" is not contained by the expected runtime parent root.";
			return nullptr;
		}

		return cast<CellObject*>(runtimeCellObject.get());
	}

	static ManagedReference<SceneObject*> resolveByIdentity(CreatureObject* player,
			const String& publishID, uint32 structureLocalID, String& errorMessage) {
		if (player == nullptr || player->getZoneServer() == nullptr || player->getZone() == nullptr) {
			errorMessage = "No active ground-zone context is available.";
			return nullptr;
		}

		WorldBuilderPublishedStructureIdentity identity;
		identity.publishID = publishID;
		identity.structureLocalID = structureLocalID;
		identity.serverTemplate = expectedServerTemplate(publishID, structureLocalID);
		identity.sharedTemplate = expectedSharedTemplate(publishID, structureLocalID);

		WorldSnapshotIff snapshot;
		if (!loadSnapshot(player, snapshot, errorMessage))
			return nullptr;

		WorldSnapshotNode* matchedRoot = nullptr;
		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			if (rootNode == nullptr)
				continue;
			String sharedTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());
			if (sharedTemplate != identity.sharedTemplate)
				continue;
			if (matchedRoot != nullptr) {
				errorMessage = "Active snapshot contains more than one root for generated World Builder identity '" + identity.sharedTemplate + "'.";
				return nullptr;
			}
			matchedRoot = rootNode;
		}

		if (matchedRoot == nullptr) {
			errorMessage = "Published parent " + publishID + " / Structure #" + String::valueOf(structureLocalID) + " was not found in the active " + player->getZone()->getZoneName() + " snapshot.";
			return nullptr;
		}

		identity.rootObjectID = matchedRoot->getObjectID();
		if (!validateSnapshotRoot(matchedRoot, snapshot, identity, errorMessage))
			return nullptr;

		ManagedReference<SceneObject*> runtimeRoot = player->getZoneServer()->getObject(identity.rootObjectID);
		if (runtimeRoot == nullptr) {
			errorMessage = "Published parent snapshot root exists, but its runtime BuildingObject is not loaded.";
			return nullptr;
		}

		if (!validateRuntimeRoot(player, runtimeRoot, identity, errorMessage))
			return nullptr;

		return runtimeRoot;
	}
};

#endif /* WORLDBUILDERPUBLISHEDSTRUCTURERESOLVER_H_ */
