#ifndef WORLDBUILDEREXTERIORBUILDINGPREVIEW_H_
#define WORLDBUILDEREXTERIORBUILDINGPREVIEW_H_

#include "templates/manager/TemplateManager.h"
#include "templates/SharedObjectTemplate.h"
#include "templates/building/SharedBuildingObjectTemplate.h"
#include "templates/appearance/PortalLayout.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include <map>
#include <mutex>

class WorldBuilderExteriorBuildingPreview {
private:
	inline static std::map<uint64, uint64> previewObjectIDs;
	inline static std::mutex previewMutex;

	static String deriveSharedTemplate(const String& serverTemplate) {
		int slash = serverTemplate.lastIndexOf("/");
		if (slash < 0) return serverTemplate;
		String directory = serverTemplate.subString(0, slash + 1);
		String filename = serverTemplate.subString(slash + 1);
		return filename.beginsWith("shared_") ? serverTemplate : directory + "shared_" + filename;
	}

	static uint64 getPreviewObjectID(uint64 playerID) {
		std::lock_guard<std::mutex> guard(previewMutex);
		auto it = previewObjectIDs.find(playerID);
		return it == previewObjectIDs.end() ? 0 : it->second;
	}

	static void setPreviewObjectID(uint64 playerID, uint64 objectID) {
		std::lock_guard<std::mutex> guard(previewMutex);
		if (objectID == 0) previewObjectIDs.erase(playerID);
		else previewObjectIDs[playerID] = objectID;
	}

	static bool clearInternal(CreatureObject* player, bool reportMissing, String& message) {
		if (player == nullptr || player->getZoneServer() == nullptr) {
			message = "World Builder could not resolve the zone server."; return false;
		}
		uint64 objectID = getPreviewObjectID(player->getObjectID());
		if (objectID == 0) {
			if (reportMissing) message = "No transient exterior building preview is active.";
			return true;
		}
		ManagedReference<SceneObject*> object = player->getZoneServer()->getObject(objectID);
		if (object != nullptr) {
			Locker locker(object, player);
			// Outdoor template children are separate zone/database objects.
			object->destroyChildObjects();
			object->destroyObjectFromWorld(true);
			object->destroyObjectFromDatabase(true);
		}
		setPreviewObjectID(player->getObjectID(), 0);
		message = "Transient exterior building preview and template childObjects cleared.";
		return true;
	}

public:
	static bool spawn(CreatureObject* player, const String& requestedTemplate, float distance, String& message) {
		if (player == nullptr || player->getZone() == nullptr || player->getZoneServer() == nullptr) {
			message = "You must be in a ground zone to preview an exterior building."; return false;
		}
		String serverTemplate = requestedTemplate.trim();
		int slash = serverTemplate.lastIndexOf("/");
		String filename = slash >= 0 ? serverTemplate.subString(slash + 1) : serverTemplate;
		if (serverTemplate.isEmpty() || filename.beginsWith("shared_") || serverTemplate.beginsWith("object/building/worldbuilder/")) {
			message = "Exterior preview requires a stock registered SERVER building template."; return false;
		}
		Reference<SharedObjectTemplate*> data = TemplateManager::instance()->getTemplate(serverTemplate.hashCode());
		if (data == nullptr || !data->isSharedBuildingObjectTemplate()) {
			message = "Template is not a registered SERVER building: " + serverTemplate; return false;
		}
		SharedBuildingObjectTemplate* buildingTemplate = static_cast<SharedBuildingObjectTemplate*>(data.get());
		if ((!buildingTemplate->getFullTemplateString().isEmpty() && buildingTemplate->getFullTemplateString() != serverTemplate) ||
			(!buildingTemplate->getClientTemplateFileName().isEmpty() && buildingTemplate->getClientTemplateFileName() != deriveSharedTemplate(serverTemplate))) {
			message = "Exterior preview refused because server/shared template identity is inconsistent."; return false;
		}
		const PortalLayout* portal = buildingTemplate->getPortalLayout();
		if (portal != nullptr && portal->getCellTotalNumber() > 0) {
			message = "This building has interior cells; use the normal Structure Preview."; return false;
		}
		if (player->getParentID() != 0) { message = "Stand outdoors before previewing an exterior building."; return false; }
		if (distance <= 0.f) distance = 15.f;
		if (distance > 100.f) distance = 100.f;
		String ignored; clearInternal(player, false, ignored);
		ManagedReference<SceneObject*> object = player->getZoneServer()->createObject(serverTemplate.hashCode(), 0);
		if (object == nullptr || !object->isBuildingObject()) {
			if (object != nullptr) { Locker locker(object, player); object->destroyObjectFromWorld(true); object->destroyObjectFromDatabase(true); }
			message = "Core3 did not create a BuildingObject from: " + serverTemplate; return false;
		}
		BuildingObject* building = object->asBuildingObject();
		Vector3 world = player->getWorldPosition(); float heading = player->getDirectionAngle(); float radians = Math::deg2rad(heading);
		float x = world.getX() + distance * sin(radians); float y = world.getY() + distance * cos(radians); float z = world.getZ();
		float facing = heading + 180.f; while (facing > 180.f) facing -= 360.f; while (facing < -180.f) facing += 360.f;
		{
			Locker locker(building, player);
			building->initializePosition(x, z, y); building->rotate(facing);
			if (!player->getZone()->transferObject(building, -1, true)) {
				building->destroyObjectFromWorld(true); building->destroyObjectFromDatabase(true);
				message = "Core3 could not transfer the exterior preview into the zone."; return false;
			}
			building->createChildObjects();
		}
		setPreviewObjectID(player->getObjectID(), building->getObjectID());
		message = "Transient exterior BuildingObject preview created with its registered template childObjects. It is not part of the WBP, undo history, save, or publication.";
		return true;
	}

	static bool clear(CreatureObject* player, String& message) { return clearInternal(player, true, message); }
	static bool clearQuiet(CreatureObject* player) { String ignored; return clearInternal(player, false, ignored); }
};

#endif
