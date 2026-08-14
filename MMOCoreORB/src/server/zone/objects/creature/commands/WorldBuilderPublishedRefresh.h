/*
 * WorldBuilderPublishedRefresh.h
 *
 * Bellum Gero World Builder V1.9.8
 * Safe structural republish preparation for published WBP V2 structures.
 *
 * This helper deliberately does NOT destroy the live runtime structure. It
 * removes persistence only for the exact World Builder snapshot root/cell OIDs
 * after validating all of the following:
 *   - project path is under object/building/worldbuilder/<project>/
 *   - every root/cell OID is inside the reserved World Builder structural band
 *   - runtime root is the expected BuildingObject/template
 *   - every snapshot cell resolves to the expected runtime CellObject
 *   - every cell is empty (no players, creatures, items, or other contents)
 *
 * After confirmation, the currently running objects remain in memory until the
 * server is shut down. On the next cold start, the newly deployed snapshot/TRE
 * can recreate the same OIDs cleanly from the updated templates/transforms.
 */

#ifndef WORLDBUILDERPUBLISHEDREFRESH_H_
#define WORLDBUILDERPUBLISHEDREFRESH_H_

#include "templates/manager/TemplateManager.h"
#include "templates/SharedObjectTemplate.h"
#include "templates/snapshot/WorldSnapshotIff.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"

class WorldBuilderPublishedRefresh {
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

	static bool containsOID(const Vector<uint64>& objectIDs, uint64 objectID) {
		for (int i = 0; i < objectIDs.size(); ++i) {
			if (objectIDs.get(i) == objectID)
				return true;
		}

		return false;
	}

	// Match bellum_worldbuilder.py project_slug(): lowercase, collapse runs of
	// non [a-z0-9] characters to one underscore, trim, and cap at 48 chars.
	static String projectSlug(const String& projectName) {
		String input = projectName.trim().toLowerCase();
		StringBuffer buffer;
		bool pendingSeparator = false;
		bool hasCharacter = false;

		for (int i = 0; i < input.length(); ++i) {
			char c = input.charAt(i);
			bool valid = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');

			if (valid) {
				if (pendingSeparator && hasCharacter)
					buffer << "_";

				buffer << c;
				hasCharacter = true;
				pendingSeparator = false;
			} else if (hasCharacter) {
				pendingSeparator = true;
			}
		}

		String result = buffer.toString();
		if (result.isEmpty())
			result = "project";

		if (result.length() > 48)
			result = result.subString(0, 48);

		return result;
	}

	static String expectedServerTemplate(const String& sharedTemplate) {
		String serverTemplate = sharedTemplate;
		return serverTemplate.replaceFirst("shared_", "");
	}

	static bool validateRoot(CreatureObject* player,
			WorldSnapshotNode* rootNode,
			WorldSnapshotIff& snapshot,
			const String& projectPrefix,
			StringBuffer& report,
			int& totalCells) {
		if (player == nullptr || rootNode == nullptr || player->getZoneServer() == nullptr)
			return false;

		ZoneServer* zoneServer = player->getZoneServer();
		uint64 rootOID = rootNode->getObjectID();
		String sharedTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());
		String serverTemplate = expectedServerTemplate(sharedTemplate);

		report << "\n\nStructure root OID: " << rootOID
			<< "\n  Shared template: " << sharedTemplate
			<< "\n  Server template: " << serverTemplate
			<< "\n  Snapshot cells: " << rootNode->getNodeCount();

		if (!sharedTemplate.beginsWith(projectPrefix)) {
			report << "\n  FAIL: template is outside the requested World Builder project prefix.";
			return false;
		}

		if (!isReservedOID(rootOID)) {
			report << "\n  FAIL: root OID is outside reserved World Builder range 0x60000000-0x6FFFFFFF.";
			return false;
		}

		ManagedReference<SceneObject*> runtimeRoot = zoneServer->getObject(rootOID);
		if (runtimeRoot == nullptr) {
			report << "\n  FAIL: runtime root is not loaded.";
			return false;
		}

		if (!runtimeRoot->isBuildingObject()) {
			report << "\n  FAIL: runtime root is not a BuildingObject.";
			return false;
		}

		SharedObjectTemplate* runtimeTemplate = runtimeRoot->getObjectTemplate();
		String runtimeTemplatePath = runtimeTemplate != nullptr ? runtimeTemplate->getFullTemplateString() : String("<none>");

		if (runtimeTemplate == nullptr || runtimeTemplatePath != serverTemplate) {
			report << "\n  FAIL: runtime root template is '" << runtimeTemplatePath
				<< "' instead of expected '" << serverTemplate << "'.";
			return false;
		}

		if (runtimeRoot->getServerObjectCRC() != (uint32)serverTemplate.hashCode()) {
			report << "\n  FAIL: runtime root server CRC does not match the snapshot template.";
			return false;
		}

		BuildingObject* building = runtimeRoot->asBuildingObject();
		if (building == nullptr) {
			report << "\n  FAIL: BuildingObject cast failed.";
			return false;
		}

		// Snapshot-published World Builder cells are authoritative by their exact
		// snapshot OIDs. Core3 may load those CellObjects correctly without
		// exposing them through BuildingObject::getCell(), so validate the
		// structural cell count here and validate every runtime cell by snapshot
		// OID below instead of depending on the BuildingObject cell map.
		if (building->getTotalCellNumber() != rootNode->getNodeCount()) {
			report << "\n  FAIL: runtime BuildingObject template cell count "
				<< building->getTotalCellNumber() << " does not match snapshot cell count "
				<< rootNode->getNodeCount() << ".";
			return false;
		}

		Vector<uint64> expectedCellOIDs;
		for (int i = 0; i < rootNode->getNodeCount(); ++i) {
			WorldSnapshotNode* cellNode = rootNode->getNode(i);
			if (cellNode == nullptr) {
				report << "\n  FAIL: snapshot contains a null child node.";
				return false;
			}

			uint64 cellOID = cellNode->getObjectID();
			int cellNumber = cellNode->getCellID();
			String cellTemplate = snapshot.getObjectTemplateName(cellNode->getNameID());

			if (cellNode->getNodeCount() != 0 || cellNode->getParentID() != rootOID ||
				cellNumber <= 0 || cellTemplate != "object/cell/shared_cell.iff") {
				report << "\n  FAIL: child OID " << cellOID << " is not a direct World Builder CellObject node.";
				return false;
			}

			if (!isReservedOID(cellOID)) {
				report << "\n  FAIL: Cell " << cellNumber << " OID " << cellOID
					<< " is outside reserved World Builder range.";
				return false;
			}

			if (containsOID(expectedCellOIDs, cellOID)) {
				report << "\n  FAIL: duplicate CellObject OID " << cellOID << ".";
				return false;
			}
			expectedCellOIDs.add(cellOID);

			ManagedReference<SceneObject*> runtimeCellObject = zoneServer->getObject(cellOID);
			if (runtimeCellObject == nullptr || !runtimeCellObject->isCellObject()) {
				report << "\n  FAIL: Cell " << cellNumber << " runtime object is missing or not a CellObject.";
				return false;
			}

			if (runtimeCellObject->getParentID() != rootOID) {
				report << "\n  FAIL: Cell " << cellNumber << " runtime parent does not match structure root.";
				return false;
			}

			// Do not require BuildingObject::getCell(cellNumber) here. The exact
			// snapshot-authored CellObject OID, runtime type, parent OID, and
			// containment checks are the authoritative published hierarchy.
			int contents = runtimeCellObject->getContainerObjectsSize();
			if (contents != 0) {
				report << "\n  FAIL: Cell " << cellNumber << " (OID " << cellOID << ") contains "
					<< contents << " runtime object(s). Empty the structure before preparing a republish.";
				return false;
			}
		}

		// The root container should contain only its known cells. Refuse to touch
		// persistence if an unexpected contained object has been attached directly.
		for (int i = 0; i < runtimeRoot->getContainerObjectsSize(); ++i) {
			ManagedReference<SceneObject*> contained = runtimeRoot->getContainerObject(i);
			if (contained == nullptr)
				continue;

			if (!contained->isCellObject() || !containsOID(expectedCellOIDs, contained->getObjectID())) {
				report << "\n  FAIL: structure root contains unexpected runtime object OID "
					<< contained->getObjectID() << ".";
				return false;
			}
		}

		totalCells += expectedCellOIDs.size();
		report << "\n  PASS: runtime root/template/cells match and all cells are empty.";
		return true;
	}

public:
	static bool run(CreatureObject* player, const String& requestedProject, bool confirm, String& message) {
		message = "";

		if (player == nullptr || player->getZone() == nullptr || player->getZoneServer() == nullptr) {
			message = "No active planet/zone context is available.";
			return false;
		}

		String slug = projectSlug(requestedProject);
		String sharedPrefix = "object/building/worldbuilder/" + slug + "/shared_structure_";
		String snapshotPath = "snapshot/" + player->getZone()->getZoneName() + ".ws";

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr) {
			message = "TemplateManager is unavailable.";
			return false;
		}

		IffStream* iffStream = templateManager->openIffFile(snapshotPath);
		if (iffStream == nullptr) {
			message = "Could not open " + snapshotPath + ".";
			return false;
		}

		WorldSnapshotIff snapshot;
		try {
			snapshot.readObject(iffStream);
		} catch (Exception& e) {
			delete iffStream;
			message = "Could not parse " + snapshotPath + ": " + e.getMessage();
			return false;
		}
		delete iffStream;

		Vector<WorldSnapshotNode*> roots;
		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			if (rootNode == nullptr)
				continue;

			String sharedTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());
			if (sharedTemplate.beginsWith(sharedPrefix))
				roots.add(rootNode);
		}

		if (roots.size() == 0) {
			message = "No published World Builder structure for project '" + slug + "' was found in " + snapshotPath + ". Travel to the project's planet and try again.";
			return false;
		}

		StringBuffer report;
		report << "World Builder Published Refresh"
			<< "\nProject: " << slug
			<< "\nPlanet: " << player->getZone()->getZoneName()
			<< "\nSnapshot: " << snapshotPath
			<< "\nMatched structure roots: " << roots.size()
			<< "\nReserved OID band: 0x60000000-0x6FFFFFFF";

		int totalCells = 0;
		for (int i = 0; i < roots.size(); ++i) {
			if (!validateRoot(player, roots.get(i), snapshot, sharedPrefix, report, totalCells)) {
				report << "\n\nREFRESH PRECHECK FAILED. No database records were changed.";
				message = report.toString();
				return false;
			}
		}

		if (!confirm) {
			report << "\n\nPRECHECK PASSED. This was a dry run; nothing was changed."
				<< "\n\nTo remove persistence for exactly these World Builder roots/cells, run:"
				<< "\n/wb refreshpublished " << slug << " confirm"
				<< "\n\nThen immediately perform a normal server shutdown, deploy the newly validated TRE + matching generated_templates.lua, and cold-start the server.";
			message = report.toString();
			return true;
		}

		// Make a second, mutation-free pass and hold strong references to every
		// exact object that will be de-persisted. If anything changed after the
		// dry-run validation above, abort before touching the database.
		ZoneServer* zoneServer = player->getZoneServer();
		Vector<ManagedReference<SceneObject*> > cellsToClear;
		Vector<ManagedReference<SceneObject*> > rootsToClear;

		for (int r = 0; r < roots.size(); ++r) {
			WorldSnapshotNode* rootNode = roots.get(r);
			ManagedReference<SceneObject*> runtimeRoot = zoneServer->getObject(rootNode->getObjectID());

			if (runtimeRoot == nullptr || !runtimeRoot->isBuildingObject()) {
				message = "Runtime BuildingObject changed after validation. No database records were changed.";
				return false;
			}

			for (int i = 0; i < rootNode->getNodeCount(); ++i) {
				WorldSnapshotNode* cellNode = rootNode->getNode(i);
				if (cellNode == nullptr) {
					message = "Snapshot CellObject changed after validation. No database records were changed.";
					return false;
				}

				ManagedReference<SceneObject*> runtimeCell = zoneServer->getObject(cellNode->getObjectID());
				if (runtimeCell == nullptr || !runtimeCell->isCellObject() ||
					runtimeCell->getParentID() != rootNode->getObjectID() ||
					runtimeCell->getContainerObjectsSize() != 0) {
					message = "A runtime CellObject changed or became occupied after validation. No database records were changed.";
					return false;
				}

				cellsToClear.add(runtimeCell);
			}

			rootsToClear.add(runtimeRoot);
		}

		// Remove persistence only for the exact snapshot CellObject OIDs and root
		// OIDs. Runtime objects intentionally remain active until shutdown.
		for (int i = 0; i < cellsToClear.size(); ++i) {
			ManagedReference<SceneObject*> runtimeCell = cellsToClear.get(i);
			Locker cellLocker(runtimeCell);
			runtimeCell->destroyObjectFromDatabase(false);
		}

		for (int i = 0; i < rootsToClear.size(); ++i) {
			ManagedReference<SceneObject*> runtimeRoot = rootsToClear.get(i);
			Locker rootLocker(runtimeRoot);
			runtimeRoot->destroyObjectFromDatabase(false);
		}

		int removedCells = cellsToClear.size();
		int removedRoots = rootsToClear.size();

		report << "\n\nPREPARE COMPLETE."
			<< "\nRemoved persistence for " << removedRoots << " World Builder structure root(s) and "
			<< removedCells << " CellObject(s)."
			<< "\nRuntime objects were intentionally left active until shutdown."
			<< "\n\nNEXT STEPS:"
			<< "\n1. Shut the server down normally now."
			<< "\n2. Deploy the newly validated TRE to BOTH server and client."
			<< "\n3. Keep the matching generated_templates.lua from that bake."
			<< "\n4. Cold-start the server."
			<< "\n5. Verify /wb structureinfo and /wb cellinfo before opening the project."
			<< "\n\nIf you restart with the old TRE, it can republish the old snapshot and you must prepare the refresh again.";

		message = report.toString();
		return true;
	}
};

#endif /* WORLDBUILDERPUBLISHEDREFRESH_H_ */
