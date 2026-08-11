/*
 * WorldBuilderStructureInspector.h
 *
 * Bellum Gero World Builder V1.6.4 structure/introspection groundwork.
 *
 * Read-only inspector for buildings/caves, portal cells, snapshot hierarchy,
 * and interior-layout metadata.
 *
 * Resolution order:
 *   1. Runtime target/container hierarchy.
 *   2. Runtime hierarchy using stored parent object IDs.
 *   3. Authoritative snapshot/<planet>.ws hierarchy fallback by object ID.
 *   4. Nearest top-level snapshot building fallback by world position.
 *
 * The snapshot fallbacks are important for snapshot-authored structures whose
 * runtime containment chain is incomplete or otherwise differs from a normal
 * server-spawned BuildingObject hierarchy. It also gives World Builder direct
 * visibility into the exact data that its future structural baker will edit.
 */

#ifndef WORLDBUILDERSTRUCTUREINSPECTOR_H_
#define WORLDBUILDERSTRUCTUREINSPECTOR_H_

#include "templates/manager/TemplateManager.h"
#include "templates/building/SharedBuildingObjectTemplate.h"
#include "templates/building/InteriorLayoutTemplate.h"
#include "templates/appearance/PortalLayout.h"
#include "templates/appearance/CellProperty.h"
#include "templates/snapshot/WorldSnapshotIff.h"

#include <map>
#include <string>
#include <cmath>

class WorldBuilderStructureInspectorSuiCallback;

class WorldBuilderStructureInspector {
private:
	struct SnapshotResolution {
		bool found;
		uint64 lookupObjectID;
		uint64 matchedObjectID;
		uint64 matchedParentID;
		uint64 rootObjectID;
		float rootDistance;
		String rootSharedTemplate;
		String rootServerTemplate;

		SnapshotResolution()
			: found(false),
			  lookupObjectID(0),
			  matchedObjectID(0),
			  matchedParentID(0),
			  rootObjectID(0),
			  rootDistance(-1.0f) {
		}
	};

	static bool isStructureLike(SceneObject* object) {
		if (object == nullptr)
			return false;

		if (object->isBuildingObject())
			return true;

		SharedObjectTemplate* objectTemplate = object->getObjectTemplate();
		return objectTemplate != nullptr && objectTemplate->isSharedBuildingObjectTemplate();
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
			if (isStructureLike(current))
				return current;

			current = getRuntimeParent(current, zoneServer);
		}

		return nullptr;
	}

	static ManagedReference<SceneObject*> resolveRuntimeStructure(CreatureObject* player, String& source) {
		source = "";
		if (player == nullptr || player->getZoneServer() == nullptr)
			return nullptr;

		ZoneServer* zoneServer = player->getZoneServer();

		uint64 targetID = player->getTargetID();
		if (targetID != 0) {
			ManagedReference<SceneObject*> target = zoneServer->getObject(targetID);
			ManagedReference<SceneObject*> building = findBuildingAncestor(target, zoneServer);
			if (building != nullptr) {
				source = "Current target / runtime parent hierarchy";
				return building;
			}
		}

		ManagedReference<SceneObject*> playerParent = player->getParent().get();
		if (playerParent == nullptr && player->getParentID() != 0)
			playerParent = zoneServer->getObject(player->getParentID());

		ManagedReference<SceneObject*> currentBuilding = findBuildingAncestor(playerParent, zoneServer);
		if (currentBuilding != nullptr) {
			source = "Developer's current interior / runtime parent hierarchy";
			return currentBuilding;
		}

		return nullptr;
	}

	static WorldSnapshotNode* findSnapshotNodeRecursive(WorldSnapshotNode* node, uint64 objectID) {
		if (node == nullptr)
			return nullptr;

		if (node->getObjectID() == objectID)
			return node;

		for (int i = 0; i < node->getNodeCount(); ++i) {
			WorldSnapshotNode* found = findSnapshotNodeRecursive(node->getNode(i), objectID);
			if (found != nullptr)
				return found;
		}

		return nullptr;
	}

	static bool resolveSnapshotObject(CreatureObject* player, uint64 objectID, SnapshotResolution& result) {
		result = SnapshotResolution();
		result.lookupObjectID = objectID;

		if (player == nullptr || player->getZone() == nullptr || objectID == 0)
			return false;

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr)
			return false;

		String snapshotPath = "snapshot/" + player->getZone()->getZoneName() + ".ws";
		IffStream* iffStream = templateManager->openIffFile(snapshotPath);
		if (iffStream == nullptr)
			return false;

		WorldSnapshotIff snapshot;
		try {
			snapshot.readObject(iffStream);
		} catch (Exception&) {
			delete iffStream;
			return false;
		}

		delete iffStream;

		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			WorldSnapshotNode* matchedNode = findSnapshotNodeRecursive(rootNode, objectID);

			if (matchedNode == nullptr)
				continue;

			result.found = true;
			result.matchedObjectID = matchedNode->getObjectID();
			result.matchedParentID = matchedNode->getParentID();
			result.rootObjectID = rootNode->getObjectID();
			result.rootSharedTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());
			result.rootServerTemplate = result.rootSharedTemplate.replaceFirst("shared_", "");
			return true;
		}

		return false;
	}

	static bool resolveNearestSnapshotStructure(CreatureObject* player, SnapshotResolution& result) {
		result = SnapshotResolution();

		if (player == nullptr || player->getZone() == nullptr)
			return false;

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr)
			return false;

		String snapshotPath = "snapshot/" + player->getZone()->getZoneName() + ".ws";
		IffStream* iffStream = templateManager->openIffFile(snapshotPath);
		if (iffStream == nullptr)
			return false;

		WorldSnapshotIff snapshot;
		try {
			snapshot.readObject(iffStream);
		} catch (Exception&) {
			delete iffStream;
			return false;
		}

		delete iffStream;

		float playerX = player->getPositionX();
		float playerY = player->getPositionY();
		float bestDistanceSquared = 256.0f * 256.0f;
		WorldSnapshotNode* bestRoot = nullptr;
		String bestSharedTemplate;

		for (int i = 0; i < snapshot.getNodeCount(); ++i) {
			WorldSnapshotNode* rootNode = snapshot.getNode(i);
			if (rootNode == nullptr)
				continue;

			String sharedTemplate = snapshot.getObjectTemplateName(rootNode->getNameID());

			// Structural snapshot roots are normally under object/building/.
			// This fallback is intentionally conservative so a nearby rock or
			// decorative static cannot be mistaken for the containing structure.
			if (!sharedTemplate.beginsWith("object/building/"))
				continue;

			Vector3 rootPosition = rootNode->getPosition();
			float dx = rootPosition.getX() - playerX;
			float dy = rootPosition.getY() - playerY;
			float distanceSquared = dx * dx + dy * dy;

			if (distanceSquared < bestDistanceSquared) {
				bestDistanceSquared = distanceSquared;
				bestRoot = rootNode;
				bestSharedTemplate = sharedTemplate;
			}
		}

		if (bestRoot == nullptr)
			return false;

		result.found = true;
		result.lookupObjectID = 0;
		result.matchedObjectID = bestRoot->getObjectID();
		result.matchedParentID = bestRoot->getParentID();
		result.rootObjectID = bestRoot->getObjectID();
		result.rootDistance = std::sqrt(bestDistanceSquared);
		result.rootSharedTemplate = bestSharedTemplate;
		result.rootServerTemplate = bestSharedTemplate.replaceFirst("shared_", "");
		return true;
	}

	static bool resolveSnapshotStructure(CreatureObject* player, SnapshotResolution& result, String& source) {
		source = "";
		if (player == nullptr)
			return false;

		uint64 targetID = player->getTargetID();
		if (targetID != 0 && resolveSnapshotObject(player, targetID, result)) {
			source = "Snapshot hierarchy fallback / current target";
			return true;
		}

		uint64 parentID = player->getParentID();
		if (parentID != 0 && resolveSnapshotObject(player, parentID, result)) {
			source = "Snapshot hierarchy fallback / current interior cell";
			return true;
		}

		if (resolveNearestSnapshotStructure(player, result)) {
			source = "Snapshot spatial fallback / nearest building root";
			return true;
		}

		return false;
	}

	static void showMetadata(CreatureObject* player,
			SharedBuildingObjectTemplate* buildingTemplate,
			SceneObject* runtimeStructure,
			const String& source,
			const String& diagnostics);

public:
	static void show(CreatureObject* player);
};

class WorldBuilderStructureInspectorSuiCallback : public SuiCallback {
public:
	WorldBuilderStructureInspectorSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr)
			return;

		WorldBuilderCommandUi::showMenu(player);
	}
};

inline void WorldBuilderStructureInspector::showMetadata(CreatureObject* player,
			SharedBuildingObjectTemplate* buildingTemplate,
			SceneObject* runtimeStructure,
			const String& source,
			const String& diagnostics) {
		if (player == nullptr || buildingTemplate == nullptr)
			return;

		const PortalLayout* portalLayout = buildingTemplate->getPortalLayout();

		const String& interiorLayoutFile = buildingTemplate->getInteriorLayoutFileName();
		InteriorLayoutTemplate* interiorLayout = nullptr;
		if (!interiorLayoutFile.isEmpty())
			interiorLayout = TemplateManager::instance()->getInteriorLayout(interiorLayoutFile);

		std::map<std::string, int> interiorCounts;
		int interiorNodeCount = 0;
		if (interiorLayout != nullptr) {
			const Vector<Reference<InteriorNode*> >& children = interiorLayout->getChildren();
			interiorNodeCount = children.size();

			for (int i = 0; i < children.size(); ++i) {
				InteriorNode* node = children.get(i);
				if (node == nullptr)
					continue;

				std::string room(node->getCellName().toCharArray());
				interiorCounts[room]++;
			}
		}

		StringBuffer prompt;
		prompt << "Resolved from: " << source;

		if (runtimeStructure != nullptr) {
			prompt << "\nRuntime object ID: " << runtimeStructure->getObjectID()
				<< "\nRuntime building class: " << (runtimeStructure->isBuildingObject() ? "YES" : "NO")
				<< "\nRuntime game object type: " << runtimeStructure->getGameObjectType()
				<< "\nRuntime parent ID: " << runtimeStructure->getParentID();
		} else {
			prompt << "\nRuntime structure object: NOT AVAILABLE";
		}

		prompt << "\nServer template: " << buildingTemplate->getFullTemplateString()
			<< "\nClient template: " << buildingTemplate->getClientTemplateFileName()
			<< "\nAppearance: " << buildingTemplate->getAppearanceFilename()
			<< "\nPortal layout: " << buildingTemplate->getPortalLayoutFilename()
			<< "\nInterior layout: " << (interiorLayoutFile.isEmpty() ? String("<none>") : interiorLayoutFile)
			<< "\nTemplate cell count: " << buildingTemplate->getTotalCellNumber();

		if (portalLayout != nullptr) {
			prompt << "\nPortal interior cells: " << portalLayout->getCellTotalNumber()
				<< "\nPortal cell records (incl. exterior): " << portalLayout->getFloorMeshNumber();
		} else {
			prompt << "\nPortal layout loaded: NO";
		}

		if (interiorLayoutFile.isEmpty()) {
			prompt << "\nInterior layout objects: 0 (no ILF assigned)";
		} else if (interiorLayout == nullptr) {
			prompt << "\nInterior layout loaded: NO (path is assigned but could not be parsed)";
		} else {
			prompt << "\nInterior layout objects: " << interiorNodeCount
				<< " across " << (int)interiorCounts.size() << " room name(s)";
		}

		if (!diagnostics.isEmpty())
			prompt << "\n\n" << diagnostics;

		prompt << "\n\nRows below map portal cell IDs/names to ILF object counts. This is read-only structural groundwork; it does not modify the structure.";

		ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
		box->setPromptTitle("World Builder Structure Inspector");
		box->setPromptText(prompt.toString());
		box->setUsingObject(player);
		box->setCancelButton(true, "@cancel");
		box->setOkButton(true, "@ok");
		box->setCallback(new WorldBuilderStructureInspectorSuiCallback(player->getZoneServer()));

		if (portalLayout != nullptr) {
			const Vector<Reference<CellProperty*> >& cells = portalLayout->getCellProperties();
			for (int i = 0; i < cells.size(); ++i) {
				CellProperty* cell = cells.get(i);
				if (cell == nullptr)
					continue;

				std::string room(cell->getName().toCharArray());
				int ilfCount = 0;
				auto found = interiorCounts.find(room);
				if (found != interiorCounts.end())
					ilfCount = found->second;

				StringBuffer row;
				if (i == 0)
					row << "Exterior/World";
				else
					row << "Cell " << cell->getCellID();

				row << " | " << (cell->getName().isEmpty() ? String("<unnamed>") : cell->getName())
					<< " | ILF " << ilfCount
					<< " | portals " << cell->getNumberOfPortals();

				if (cell->hasWorldPortal())
					row << " | world portal";
				if (cell->getFloorMesh() != nullptr)
					row << " | floor";

				box->addMenuItem(row.toString(), i + 1);
			}
		} else {
			box->addMenuItem("No portal-layout cell data is available for this structure.", 1);
		}

		if (interiorLayout != nullptr && !interiorCounts.empty()) {
			for (auto it = interiorCounts.begin(); it != interiorCounts.end(); ++it) {
				if (portalLayout != nullptr && portalLayout->getCellID(String(it->first.c_str())) >= 0)
					continue;

				StringBuffer row;
				row << "ILF-only room | " << String(it->first.c_str()) << " | objects " << it->second << " | NO portal cell match";
				box->addMenuItem(row.toString(), 10000 + box->getMenuSize());
			}
		}

		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
	}


inline void WorldBuilderStructureInspector::show(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr || player->getZoneServer() == nullptr)
		return;

	String source;
	ManagedReference<SceneObject*> runtimeStructure = resolveRuntimeStructure(player, source);

	if (runtimeStructure != nullptr) {
		SharedObjectTemplate* sharedTemplate = runtimeStructure->getObjectTemplate();
		if (sharedTemplate != nullptr && sharedTemplate->isSharedBuildingObjectTemplate()) {
			SharedBuildingObjectTemplate* buildingTemplate = static_cast<SharedBuildingObjectTemplate*>(sharedTemplate);
			showMetadata(player, buildingTemplate, runtimeStructure, source, "");
			return;
		}
	}

	SnapshotResolution snapshotResolution;
	String snapshotSource;
	if (!resolveSnapshotStructure(player, snapshotResolution, snapshotSource)) {
		StringBuffer diagnostic;
		diagnostic << "No building/cave structure could be resolved."
			<< "\n\nCurrent zone: " << (player->getZone() != nullptr ? player->getZone()->getZoneName() : String("<none>"))
			<< "\nCurrent target ID: " << player->getTargetID()
			<< "\nCurrent container/parent ID: " << player->getParentID()
			<< "\n\nRuntime parent traversal, snapshot-ID lookup, and nearest-building snapshot lookup all failed."
			<< "\nThis indicates no top-level snapshot building was found within 256m of the server-side player world position.";

		WorldBuilderCommandUi::sendMessage(player, "World Builder Structure Inspector", diagnostic.toString());
		return;
	}

	TemplateManager* templateManager = TemplateManager::instance();
	SharedObjectTemplate* serverTemplate = nullptr;
	if (templateManager != nullptr)
		serverTemplate = templateManager->getTemplate(snapshotResolution.rootServerTemplate.hashCode());

	ManagedReference<SceneObject*> runtimeRoot =
		player->getZoneServer()->getObject(snapshotResolution.rootObjectID);

	StringBuffer diagnostics;
	diagnostics << "SNAPSHOT DIAGNOSTICS"
		<< "\nLookup object ID: " << snapshotResolution.lookupObjectID
		<< "\nSpatial distance to root: "
		<< (snapshotResolution.rootDistance >= 0.0f ? String::valueOf(snapshotResolution.rootDistance) + " m" : String("<not spatial>"))
		<< "\nMatched snapshot node ID: " << snapshotResolution.matchedObjectID
		<< "\nMatched node parent ID: " << snapshotResolution.matchedParentID
		<< "\nSnapshot root object ID: " << snapshotResolution.rootObjectID
		<< "\nSnapshot root shared template: " << snapshotResolution.rootSharedTemplate
		<< "\nExpected server template: " << snapshotResolution.rootServerTemplate
		<< "\nServer template registered: " << (serverTemplate != nullptr ? "YES" : "NO")
		<< "\nRuntime snapshot root loaded: " << (runtimeRoot != nullptr ? "YES" : "NO");

	if (runtimeRoot != nullptr) {
		diagnostics << "\nRuntime root is BuildingObject: " << (runtimeRoot->isBuildingObject() ? "YES" : "NO")
			<< "\nRuntime root game object type: " << runtimeRoot->getGameObjectType()
			<< "\nRuntime root parent ID: " << runtimeRoot->getParentID();
	}

	ManagedReference<SceneObject*> currentContainer = nullptr;
	if (player->getParentID() != 0)
		currentContainer = player->getZoneServer()->getObject(player->getParentID());

	diagnostics << "\nCurrent container runtime object: " << (currentContainer != nullptr ? "YES" : "NO");
	if (currentContainer != nullptr) {
		diagnostics << "\nCurrent container is CellObject: " << (currentContainer->isCellObject() ? "YES" : "NO")
			<< "\nCurrent container runtime parent ID: " << currentContainer->getParentID();
	}

	if (serverTemplate == nullptr || !serverTemplate->isSharedBuildingObjectTemplate()) {
		diagnostics << "\n\nThe snapshot hierarchy was found, but its expected server template is "
			<< (serverTemplate == nullptr ? "not registered." : "registered as a non-building template.");

		WorldBuilderCommandUi::sendMessage(player, "World Builder Structure Inspector", diagnostics.toString());
		return;
	}

	SharedBuildingObjectTemplate* buildingTemplate = static_cast<SharedBuildingObjectTemplate*>(serverTemplate);
	showMetadata(player, buildingTemplate, runtimeRoot, snapshotSource, diagnostics.toString());
}

#endif /* WORLDBUILDERSTRUCTUREINSPECTOR_H_ */
