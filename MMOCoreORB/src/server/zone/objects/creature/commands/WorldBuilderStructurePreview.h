/*
 * WorldBuilderStructurePreview.h
 *
 * Bellum Gero World Builder V1.8 structure-authoring foundation.
 *
 * Spawns one transient, server-created BuildingObject per developer for
 * structure/cell testing. This diagnostic preview deliberately remains separate from the active .wbp
 * project. V1.8 adds persistent project structures through WorldBuilderManager;
 * this helper is retained as a safe template/cell test command.
 */

#ifndef WORLDBUILDERSTRUCTUREPREVIEW_H_
#define WORLDBUILDERSTRUCTUREPREVIEW_H_

#include "templates/manager/TemplateManager.h"
#include "templates/building/SharedBuildingObjectTemplate.h"
#include "templates/appearance/PortalLayout.h"
#include "templates/appearance/CellProperty.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"

#include <map>
#include <mutex>

class WorldBuilderStructurePreview {
private:
	inline static std::mutex previewMutex;
	inline static std::map<uint64, uint64> previewObjectIDs;

	static String deriveSharedTemplate(const String& serverTemplate) {
		int slash = serverTemplate.lastIndexOf("/");
		if (slash < 0)
			return serverTemplate;

		String directory = serverTemplate.subString(0, slash + 1);
		String filename = serverTemplate.subString(slash + 1);
		if (filename.beginsWith("shared_"))
			return serverTemplate;

		return directory + "shared_" + filename;
	}

	static uint64 getPreviewObjectID(uint64 playerID) {
		std::lock_guard<std::mutex> guard(previewMutex);
		auto it = previewObjectIDs.find(playerID);
		return it == previewObjectIDs.end() ? 0 : it->second;
	}

	static void setPreviewObjectID(uint64 playerID, uint64 objectID) {
		std::lock_guard<std::mutex> guard(previewMutex);
		if (objectID == 0)
			previewObjectIDs.erase(playerID);
		else
			previewObjectIDs[playerID] = objectID;
	}

	static bool clearInternal(CreatureObject* player, bool reportMissing, String& message) {
		if (player == nullptr || player->getZoneServer() == nullptr) {
			message = "World Builder could not resolve the zone server.";
			return false;
		}

		uint64 objectID = getPreviewObjectID(player->getObjectID());
		if (objectID == 0) {
			if (reportMissing)
				message = "No transient structure preview is active for this developer.";
			return true;
		}

		ManagedReference<SceneObject*> object = player->getZoneServer()->getObject(objectID);
		if (object != nullptr) {
			Locker locker(object, player);
			object->destroyObjectFromWorld(true);
			object->destroyObjectFromDatabase(true);
		}

		setPreviewObjectID(player->getObjectID(), 0);
		message = "Transient structure preview cleared.";
		return true;
	}

public:
	static bool spawn(CreatureObject* player, const String& requestedTemplate, float distance, String& message) {
		if (player == nullptr || player->getZone() == nullptr || player->getZoneServer() == nullptr) {
			message = "You must be in a ground zone to create a structure preview.";
			return false;
		}

		String serverTemplate = requestedTemplate.trim();
		if (serverTemplate.isEmpty()) {
			message = "Specify a registered SERVER building/cave template path.";
			return false;
		}

		int slash = serverTemplate.lastIndexOf("/");
		String filename = slash >= 0 ? serverTemplate.subString(slash + 1) : serverTemplate;
		if (filename.beginsWith("shared_")) {
			message = "Structure Preview requires the SERVER template, not the shared/client path. Example: object/building/tatooine/cave_tatooine_style_01.iff";
			return false;
		}

		Reference<SharedObjectTemplate*> templateData = TemplateManager::instance()->getTemplate(serverTemplate.hashCode());
		if (templateData == nullptr) {
			message = "Server structure template is not registered: " + serverTemplate;
			return false;
		}

		if (!templateData->isSharedBuildingObjectTemplate()) {
			message = "Template is registered, but it is not a building/cave template: " + serverTemplate;
			return false;
		}

		SharedBuildingObjectTemplate* buildingTemplate = static_cast<SharedBuildingObjectTemplate*>(templateData.get());
		String registeredPath = buildingTemplate->getFullTemplateString();
		if (!registeredPath.isEmpty() && registeredPath != serverTemplate) {
			message = "Structure template registration mismatch. Requested '" + serverTemplate + "' but Core3 resolved the template metadata as '" + registeredPath + "'. This usually means a renamed/copied structure was not registered as a complete server/client pair. Preview refused for safety.";
			return false;
		}

		String expectedShared = deriveSharedTemplate(serverTemplate);
		String clientTemplate = buildingTemplate->getClientTemplateFileName();
		if (!clientTemplate.isEmpty() && clientTemplate != expectedShared) {
			message = "Structure client-template mismatch. Server template '" + serverTemplate + "' points at '" + clientTemplate + "' instead of expected '" + expectedShared + "'. Preview refused for safety.";
			return false;
		}

		const PortalLayout* portalLayout = buildingTemplate->getPortalLayout();
		if (portalLayout == nullptr || portalLayout->getCellTotalNumber() <= 0) {
			message = "Structure has no usable portal/cell layout. World Builder structural preview requires a POB with interior cells.";
			return false;
		}

		if (distance <= 0.0f)
			distance = 12.0f;
		if (distance > 100.0f)
			distance = 100.0f;

		String ignored;
		clearInternal(player, false, ignored);

		ZoneServer* zoneServer = player->getZoneServer();
		ManagedReference<SceneObject*> object = zoneServer->createObject(serverTemplate.hashCode(), 0);
		if (object == nullptr || !object->isBuildingObject()) {
			if (object != nullptr) {
				Locker locker(object, player);
				object->destroyObjectFromWorld(true);
				object->destroyObjectFromDatabase(true);
			}

			message = "Core3 did not create a BuildingObject from: " + serverTemplate;
			return false;
		}

		BuildingObject* building = object->asBuildingObject();
		if (building == nullptr) {
			message = "Created structure could not be cast to BuildingObject.";
			return false;
		}

		Vector3 playerWorld = player->getWorldPosition();
		float heading = player->getDirectionAngle();
		float facingHeading = heading + 180.0f;
		while (facingHeading > 180.0f)
			facingHeading -= 360.0f;
		while (facingHeading < -180.0f)
			facingHeading += 360.0f;
		float radians = Math::deg2rad(heading);
		float x = playerWorld.getX() + distance * sin(radians);
		float y = playerWorld.getY() + distance * cos(radians);
		float z = playerWorld.getZ();

		{
			Locker locker(building, player);

			// Match the normal Core3 building-spawn order used by PlanetManager:
			// create cells first, initialize the root, insert root into the zone,
			// then create any normal child objects.
			building->createCellObjects();
			building->initializePosition(x, z, y);
			building->rotate(facingHeading);

			if (!player->getZone()->transferObject(building, -1, true)) {
				building->destroyObjectFromWorld(true);
				building->destroyObjectFromDatabase(true);
				message = "Core3 could not transfer the preview BuildingObject into the current zone.";
				return false;
			}

			building->createChildObjects();
		}

		setPreviewObjectID(player->getObjectID(), building->getObjectID());

		StringBuffer result;
		result << "Transient structure preview created. Runtime root " << building->getObjectID()
			<< " | template " << serverTemplate
			<< " | portal cells " << portalLayout->getCellTotalNumber()
			<< " | position " << x << ", " << z << ", " << y
			<< " | initially faced toward the developer. Walk into it with Ctrl+Shift+G visible, then use /wb cellinfo. This preview is NOT saved to the .wbp project and cannot be baked yet.";
		message = result.toString();
		return true;
	}

	static bool clear(CreatureObject* player, String& message) {
		return clearInternal(player, true, message);
	}

	static String getCellContext(CreatureObject* player) {
		if (player == nullptr || player->getZoneServer() == nullptr)
			return "Cell context unavailable.";

		StringBuffer out;
		Vector3 world = player->getWorldPosition();
		out << "World position X/Z/Y: " << world.getX() << " / " << world.getZ() << " / " << world.getY()
			<< "\nServer parent ID: " << player->getParentID();

		ManagedReference<SceneObject*> parent = player->getParent().get();
		if (parent == nullptr && player->getParentID() != 0)
			parent = player->getZoneServer()->getObject(player->getParentID());

		if (parent == nullptr) {
			out << "\nServer cell: NONE (world/exterior)"
				<< "\n\nFor a healthy structure this should change to a CellObject when Ctrl+Shift+G reports an interior room.";
			return out.toString();
		}

		if (!parent->isCellObject()) {
			out << "\nServer parent is not a CellObject. Runtime type: " << parent->getGameObjectType();
			return out.toString();
		}

		CellObject* cell = cast<CellObject*>(parent.get());
		if (cell == nullptr)
			return out.toString();

		out << "\nServer cell object ID: " << cell->getObjectID()
			<< "\nCell number: " << cell->getCellNumber()
			<< "\nCell-local X/Z/Y: " << player->getPositionX() << " / " << player->getPositionZ() << " / " << player->getPositionY();

		ManagedReference<SceneObject*> root = parent->getParent().get();
		if (root == nullptr && parent->getParentID() != 0)
			root = player->getZoneServer()->getObject(parent->getParentID());

		if (root == nullptr) {
			out << "\nStructure root: UNRESOLVED";
			return out.toString();
		}

		out << "\nStructure root ID: " << root->getObjectID();

		SharedObjectTemplate* rootTemplate = root->getObjectTemplate();
		if (rootTemplate != nullptr) {
			out << "\nStructure template: " << rootTemplate->getFullTemplateString();

			const PortalLayout* layout = rootTemplate->getPortalLayout();
			if (layout != nullptr) {
				const CellProperty* property = layout->getCellProperty(cell->getCellNumber());
				if (property != nullptr)
					out << "\nPortal room name: " << property->getName();
			}
		}

		out << "\n\nThe cell number/room and local coordinates above are the values World Builder will use for future ILF placement records.";
		return out.toString();
	}
};

#endif /* WORLDBUILDERSTRUCTUREPREVIEW_H_ */
