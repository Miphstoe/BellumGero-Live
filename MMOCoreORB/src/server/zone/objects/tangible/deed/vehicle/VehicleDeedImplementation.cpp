/*
 * DeedImplementation.cpp
 *
 *  Created on: Apr 18, 2010
 *      Author: crush
 */

#include "server/zone/objects/tangible/deed/vehicle/VehicleDeed.h"
#include"server/zone/ZoneServer.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/tangible/VehicleDeedTemplate.h"
#include "server/zone/objects/intangible/VehicleControlDevice.h"
#include "server/zone/objects/creature/VehicleObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"

void VehicleDeedImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	DeedImplementation::loadTemplateData(templateData);

	VehicleDeedTemplate* deedData = dynamic_cast<VehicleDeedTemplate*>(templateData);

	if (deedData == nullptr)
		return;

	controlDeviceObjectTemplate = deedData->getControlDeviceObjectTemplate();
}

void VehicleDeedImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	DeedImplementation::fillAttributeList(alm, object);

	alm->insertAttribute("hit_points", hitPoints);
}

void VehicleDeedImplementation::initializeTransientMembers() {
	DeedImplementation::initializeTransientMembers();

	setLoggingName("VehicleDeed");
}

void VehicleDeedImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	/*
	 * Values available:	Range:
	 *
	 * hitpoints			varies, integrity of vehicle
	 */

	hitPoints = (int) values->getCurrentValue("hit_points");
}

void VehicleDeedImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	DeedImplementation::fillObjectMenuResponse(menuResponse, player);

	if (isASubChildOf(player))
		menuResponse->addRadialMenuItem(20, 3, "@pet/pet_menu:menu_generate");
}

int VehicleDeedImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (selectedID == 20) {
		bool isDoctorBuffDroid = generatedObjectTemplate == "object/tangible/vendor/doctor_buff_droid_vendor.iff";

		if (generated || !isASubChildOf(player))
			return 1;

		if (isDoctorBuffDroid && !player->hasSkill("science_doctor_master")) {
			player->sendSystemMessage("Only Master Doctors may generate a Doctor Buff Droid.");
			return 1;
		}

		if (!isDoctorBuffDroid && (player->isInCombat() || player->getParentRecursively(SceneObjectType::BUILDING) != nullptr)) {
			player->sendSystemMessage("@pet/pet_menu:cant_call_vehicle"); //You can only unpack vehicles while Outside and not in Combat.
			return 1;
		}

		ManagedReference<SceneObject*> datapad = player->getSlottedObject("datapad");

		if (datapad == nullptr) {
			player->sendSystemMessage("Datapad doesn't exist when trying to create vehicle");
			return 1;
		}

		// Check if this will exceed maximum number of vehicles allowed
		ManagedReference<PlayerManager*> playerManager = player->getZoneServer()->getPlayerManager();

		int vehiclesInDatapad = 0;
		int maxStoredVehicles = playerManager->getBaseStoredVehicles();

		for (int i = 0; i < datapad->getContainerObjectsSize(); i++) {
			Reference<SceneObject*> obj =  datapad->getContainerObject(i).castTo<SceneObject*>();

			if (obj != nullptr && obj->isVehicleControlDevice())
				vehiclesInDatapad++;

			if (isDoctorBuffDroid && obj != nullptr && obj->isVehicleControlDevice()) {
				VehicleControlDevice* existing = cast<VehicleControlDevice*>(obj.get());
				if (existing != nullptr) {
					SceneObject* existingControlled = existing->getControlledObject();
					if (existingControlled != nullptr) {
						SharedObjectTemplate* controlledTemplate = existingControlled->getObjectTemplate();
						if (controlledTemplate != nullptr && controlledTemplate->getFullTemplateString() == generatedObjectTemplate) {
							player->sendSystemMessage("You already own a Doctor Buff Droid control device.");
							return 1;
						}
					}
				}
			}

		}

		if (!isDoctorBuffDroid && vehiclesInDatapad >= maxStoredVehicles) {
			player->sendSystemMessage("@pet/pet_menu:has_max_vehicle"); // You already have the maximum number of vehicles that you can own.
			return 1;
		}

		Reference<VehicleControlDevice*> vehicleControlDevice = (server->getZoneServer()->createObject(controlDeviceObjectTemplate.hashCode(), 1)).castTo<VehicleControlDevice*>();

		if (vehicleControlDevice == nullptr) {
			player->sendSystemMessage("wrong vehicle control device object template " + controlDeviceObjectTemplate);
			return 1;
		}

		Locker locker(vehicleControlDevice);

		Reference<TangibleObject*> vehicle = (server->getZoneServer()->createObject(generatedObjectTemplate.hashCode(), 1)).castTo<TangibleObject*>();

		if (vehicle == nullptr) {
			vehicleControlDevice->destroyObjectFromDatabase(true);
			player->sendSystemMessage("wrong generated object template " + generatedObjectTemplate);
			return 1;
		}

		Locker vlocker(vehicle, player);

		vehicle->createChildObjects();

		VehicleObject* vehicleObject = cast<VehicleObject*>(vehicle.get());
		if (vehicleObject != nullptr) {
			vehicleObject->setMaxCondition(hitPoints);
			vehicleObject->setConditionDamage(0);
		}

		if (isDoctorBuffDroid) {
			DataObjectComponentReference* dataRef = vehicle->getDataObjectComponent();
			if (dataRef != nullptr && dataRef->get() != nullptr && dataRef->get()->isDoctorBuffDroidData()) {
				DoctorBuffDroidDataComponent* droidData = cast<DoctorBuffDroidDataComponent*>(dataRef->get());
				if (droidData != nullptr)
					droidData->setOwnerId(player->getObjectID());
			}

			vehicleControlDevice->setCustomObjectName("Doctor Buff Droid", false);
			vehicle->setCustomObjectName("Doctor Buff Droid", false);
		}

		vehicleControlDevice->setControlledObject(vehicle);

		if (datapad->transferObject(vehicleControlDevice, -1)) {
			datapad->broadcastObject(vehicleControlDevice, true);

			if (!isDoctorBuffDroid)
				vehicleControlDevice->generateObject(player);

			generated = true;

			destroyObjectFromWorld(true);
			destroyObjectFromDatabase(true);

			return 0;
		} else {
			vehicleControlDevice->destroyObjectFromDatabase(true);
			return 1;
		}
	}

	return DeedImplementation::handleObjectMenuSelect(player, selectedID);
}
