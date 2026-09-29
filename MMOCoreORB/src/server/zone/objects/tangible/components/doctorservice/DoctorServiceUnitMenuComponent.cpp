/*
 * DoctorServiceUnitMenuComponent.cpp
 *
 * Bellum Gero - FMDoctorBot Phase 3.1
 *
 * Customer services:
 *   - Standard Doctor Buffs
 *   - Janta Doctor Buffs
 *   - Read-only Services / Availability status
 *
 * Owner services:
 *   - Persistent Medical Supply Hopper
 *   - Read-only detailed Inventory / Stock
 *   - Separate Standard/Janta pricing
 *   - Independent Standard/Janta enable toggles
 *   - Earnings, Doctor stat refresh, safety status, safe decommission
 *
 * IMPORTANT: this component deliberately does NOT call TangibleObjectMenuComponent's
 * fillObjectMenuResponse for a deployed station. That suppresses generic Pick Up /
 * Secure / Unsecure furniture radials. The station is also secured at the container
 * layer, so a direct transfer packet cannot remove it from the building.
 */

#include "DoctorServiceUnitMenuComponent.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/BuffAttribute.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServicePetServicesSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServiceMedicalServicesSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServiceOwnerConfigSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServiceMainMenuSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServicePetTargetSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServiceRebuffConfirmSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorServiceBackSuiCallback.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "templates/SharedObjectTemplate.h"

namespace {
const String kDoctorSkill = "science_doctor_master";
const String kDeedTemplate = "object/tangible/deed/doctor_service/doctor_service_unit_deed.iff";
const int kLowStockThreshold = 5;

bool isApprovedDoctorServiceBuilding(SceneObject* root) {
	if (root == nullptr || !root->isBuildingObject() || root->getObjectTemplate() == nullptr)
		return false;

	String path = root->getObjectTemplate()->getFullTemplateString();
	return path.contains("object/building/player/city/") &&
		(path.contains("/hospital_") || path.contains("/cantina_"));
}

String formatRemainingTime(int remainingSeconds) {
	if (remainingSeconds < 0)
		remainingSeconds = 0;

	int hours = remainingSeconds / 3600;
	int minutes = (remainingSeconds % 3600) / 60;
	int seconds = remainingSeconds % 60;

	StringBuffer out;
	if (hours > 0)
		out << hours << "h ";
	if (hours > 0 || minutes > 0)
		out << minutes << "m ";
	out << seconds << "s";

	return out.toString();
}

String getServiceStateLabel(bool enabled, int sessions, bool bivoliReady) {
	if (!enabled)
		return "OFFLINE BY OWNER";
	if (sessions <= 0)
		return "OUT OF STOCK";
	if (!bivoliReady)
		return "WAITING FOR BIVOLI";
	return "READY";
}

const byte kStationDoctorAttrs[6] = {
	BuffAttribute::HEALTH,
	BuffAttribute::ACTION,
	BuffAttribute::STRENGTH,
	BuffAttribute::CONSTITUTION,
	BuffAttribute::QUICKNESS,
	BuffAttribute::STAMINA
};

const uint64 kMainActionStandard = 1001;
const uint64 kMainActionJanta = 1002;
const uint64 kMainActionPet = 1003;
const uint64 kMainActionMedical = 1004;
const uint64 kMainActionAvailability = 1005;
const uint64 kMainActionHopper = 1006;
const uint64 kMainActionInventory = 1007;
const uint64 kMainActionOwner = 1008;
const uint64 kMainActionSafety = 1009;

String getStationAttrName(byte attr) {
	switch (attr) {
	case BuffAttribute::HEALTH:
		return "Health";
	case BuffAttribute::ACTION:
		return "Action";
	case BuffAttribute::STRENGTH:
		return "Strength";
	case BuffAttribute::CONSTITUTION:
		return "Constitution";
	case BuffAttribute::QUICKNESS:
		return "Quickness";
	case BuffAttribute::STAMINA:
		return "Stamina";
	default:
		return "Unknown";
	}
}

bool hasExistingDoctorEnhancements(CreatureObject* target) {
	if (target == nullptr)
		return false;

	for (int i = 0; i < 6; ++i) {
		String buffName =
			"medical_enhance_" +
			BuffAttribute::getName(kStationDoctorAttrs[i]);

		if (target->hasBuff(buffName.hashCode()))
			return true;
	}

	return false;
}

String getPriceLine(
	DoctorBuffDroidDataComponent* data,
	DoctorBuffDroidDataComponent::ServiceType service,
	CreatureObject* player) {

	if (data == nullptr || player == nullptr)
		return "Price unavailable";

	int configured = data->getPrice(service);
	int effective = data->getDiscountedPrice(service, player);

	if (data->isOwner(player)) {
		return "Configured: " + String::valueOf(configured) +
			" cr | Owner purchase: " +
			String::valueOf(effective) + " cr";
	}

	if (effective != configured) {
		return "Base: " + String::valueOf(configured) +
			" cr | Your price: " +
			String::valueOf(effective) + " cr";
	}

	return "Price: " + String::valueOf(configured) + " cr";
}

void appendPriceDetails(
	StringBuffer& report,
	DoctorBuffDroidDataComponent* data,
	DoctorBuffDroidDataComponent::ServiceType service,
	CreatureObject* player) {

	if (data == nullptr || player == nullptr)
		return;

	int configured = data->getPrice(service);
	int effective = data->getDiscountedPrice(service, player);

	if (data->isOwner(player)) {
		report << "\nConfigured Price: " << configured << " credits"
			   << "\nOwner Purchase Price: " << effective << " credits";
		return;
	}

	if (effective != configured) {
		report << "\nBase Price: " << configured << " credits"
			   << "\nYour Price: " << effective << " credits"
			   << "\nGuild Discount Applied: "
			   << data->getGuildDiscountPercent() << "%";
		return;
	}

	report << "\nPrice: " << configured << " credits";
}

void appendBuffPoolStock(
	StringBuffer& report, SceneObject* station,
	DoctorBuffDroidDataComponent::ServiceType service) {

	int minUses = -1;
	String limiting;

	for (int i = 0; i < 6; ++i) {
		byte attr = kStationDoctorAttrs[i];
		int uses =
			DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
				station, service, attr);

		report << "\n  " << getStationAttrName(attr)
			   << ": " << uses;

		if (minUses < 0 || uses < minUses) {
			minUses = uses;
			limiting = getStationAttrName(attr);
		} else if (uses == minUses) {
			limiting += ", " + getStationAttrName(attr);
		}
	}

	report << "\nLimiting Supply: " << limiting
		   << " (" << Math::max(0, minUses) << " use(s))";
}

}

bool DoctorServiceUnitMenuComponent::isPlacementValid(SceneObject* station, String* reason) {
	if (reason != nullptr)
		*reason = "";

	if (station == nullptr || !DoctorBuffDroidMenuComponent::isDoctorServiceUnit(station)) {
		if (reason != nullptr)
			*reason = "Object is not an Automated Medical Station.";
		return false;
	}

	ManagedReference<SceneObject*> parent = station->getParent().get();
	if (parent == nullptr || !parent->isCellObject()) {
		if (reason != nullptr)
			*reason = "Station is not directly contained by a structure cell.";
		return false;
	}

	ManagedReference<SceneObject*> root = station->getRootParent();
	if (!isApprovedDoctorServiceBuilding(root)) {
		if (reason != nullptr)
			*reason = "Station is not inside an approved player-city Hospital/Cantina.";
		return false;
	}

	ManagedReference<SceneObject*> hopper = DoctorBuffDroidMenuComponent::getSupplyContainer(station);
	if (hopper == nullptr || hopper == station) {
		if (reason != nullptr)
			*reason = "Persistent Medical Supply Hopper is missing.";
		return false;
	}

	if (hopper->getParentID() != station->getObjectID()) {
		if (reason != nullptr)
			*reason = "Medical Supply Hopper parent relationship is invalid.";
		return false;
	}

	return true;
}

void DoctorServiceUnitMenuComponent::fillObjectMenuResponse(
	SceneObject* sceneObject, ObjectMenuResponse* menuResponse,
	CreatureObject* player) const {

	if (sceneObject == nullptr || menuResponse == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(sceneObject);

	if (data == nullptr)
		return;

	String safetyReason;
	bool valid = isPlacementValid(sceneObject, &safetyReason);

	menuResponse->addRadialMenuItem(
		MENU_ROOT, 3,
		valid ?
			"Automated Medical Station" :
			"Automated Medical Station [SAFETY LOCKED]");

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_STATION_MENU, 3, "Station Menu");

	if (valid) {
		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_BUY_STANDARD, 3,
			"Purchase Standard Doctor Buffs");
		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_BUY_JANTA, 3,
			"Purchase Janta Doctor Buffs");
		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_PET_SERVICES, 3, "Pet Buffs");
		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_MEDICAL_SERVICES, 3,
			"Additional Medical Services");
	}

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_AVAILABILITY, 3,
		"Services / Availability");

	if (!data->isOwner(player))
		return;

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_OPEN_HOPPER, 3,
		"Open Medical Supply Hopper");
	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_INVENTORY, 3,
		"Inventory / Stock");
	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_OWNER_CONFIG, 3,
		"Owner Configuration");
	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_SAFETY_STATUS, 3,
		"Safety / Persistence Status");
	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_DECOMMISSION, 3,
		"Decommission Station");
}

void DoctorServiceUnitMenuComponent::showStationMainMenu(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	String reason;
	bool valid = isPlacementValid(station, &reason);
	bool owner = data->isOwner(player);

	ManagedReference<SuiListBox*> box =
		new SuiListBox(
			player, SuiWindowType::NONE,
			SuiListBox::HANDLETWOBUTTON);

	box->setPromptTitle("Automated Medical Station");
	box->setPromptText(
		valid ?
			"Select a service or information screen." :
			"SAFETY LOCKED: " + reason);
	box->setCancelButton(true, "@close");
	box->setOkButton(true, "@ok");
	box->setCallback(
		new DoctorServiceMainMenuSuiCallback(
			player->getZoneServer(), station));

	if (valid) {
		int standardSessions =
			DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
				station, DoctorBuffDroidDataComponent::SERVICE_BUFFS);
		int jantaSessions =
			DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
				station, DoctorBuffDroidDataComponent::SERVICE_JANTA);
		int bivoliReserve =
			DoctorBuffDroidMenuComponent::getDoctorServiceBivoliReserve(
				station);

		Time now;
		bool bivoliReady =
			data->getActiveBivoliBonus(now.getMiliTime()) > 0 ||
			bivoliReserve > 0;

		String standardState = getServiceStateLabel(
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_BUFFS),
			standardSessions, bivoliReady);
		String jantaState = getServiceStateLabel(
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_JANTA),
			jantaSessions, bivoliReady);

		box->addMenuItem(
			"Standard Doctor Buffs - " + standardState +
			" - " + getPriceLine(
				data,
				DoctorBuffDroidDataComponent::SERVICE_BUFFS,
				player) +
			" - " + String::valueOf(standardSessions) +
			" session(s)",
			kMainActionStandard);

		box->addMenuItem(
			"Janta Doctor Buffs - " + jantaState +
			" - " + getPriceLine(
				data,
				DoctorBuffDroidDataComponent::SERVICE_JANTA,
				player) +
			" - " + String::valueOf(jantaSessions) +
			" session(s)",
			kMainActionJanta);

		box->addMenuItem("Pet Buffs", kMainActionPet);
		box->addMenuItem(
			"Additional Medical Services",
			kMainActionMedical);
	}

	box->addMenuItem(
		"Services / Availability",
		kMainActionAvailability);

	if (owner) {
		box->addMenuItem(
			"Open Medical Supply Hopper",
			kMainActionHopper);
		box->addMenuItem(
			"Inventory / Stock",
			kMainActionInventory);
		box->addMenuItem(
			"Owner Configuration",
			kMainActionOwner);
		box->addMenuItem(
			"Safety / Persistence Status",
			kMainActionSafety);
	}

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::showPetServicesMenu(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	int standardSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station, DoctorBuffDroidDataComponent::SERVICE_BUFFS);
	int jantaSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station, DoctorBuffDroidDataComponent::SERVICE_JANTA);
	int bivoliReserve =
		DoctorBuffDroidMenuComponent::getDoctorServiceBivoliReserve(
			station);

	Time now;
	bool bivoliReady =
		data->getActiveBivoliBonus(now.getMiliTime()) > 0 ||
		bivoliReserve > 0;

	String standardState = getServiceStateLabel(
		data->isServiceEnabled(
			DoctorBuffDroidDataComponent::SERVICE_BUFFS),
		standardSessions, bivoliReady);
	String jantaState = getServiceStateLabel(
		data->isServiceEnabled(
			DoctorBuffDroidDataComponent::SERVICE_JANTA),
		jantaSessions, bivoliReady);

	ManagedReference<SuiListBox*> box =
		new SuiListBox(
			player, SuiWindowType::NONE,
			SuiListBox::HANDLETWOBUTTON);

	box->setPromptTitle(
		"Automated Medical Station - Pet Buffs");
	box->setPromptText(
		"Choose Standard or Janta pet buffs. "
		"If multiple living pets are active, you will choose the exact target next.");
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");

	box->addMenuItem(
		"Standard - " + standardState +
		" - " + getPriceLine(
			data,
			DoctorBuffDroidDataComponent::SERVICE_BUFFS,
			player) +
		" - " + String::valueOf(standardSessions) +
		" session(s)");

	box->addMenuItem(
		"Janta - " + jantaState +
		" - " + getPriceLine(
			data,
			DoctorBuffDroidDataComponent::SERVICE_JANTA,
			player) +
		" - " + String::valueOf(jantaSessions) +
		" session(s)");

	box->setCallback(
		new DoctorServicePetServicesSuiCallback(
			player->getZoneServer(), station));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::showPetTargetMenu(
	SceneObject* station, CreatureObject* player, bool useJanta) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	ManagedReference<PlayerObject*> ghost =
		player->getPlayerObject();

	if (ghost == nullptr)
		return;

	int livingCount = 0;
	uint64 onlyPetId = 0;

	for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
		ManagedReference<AiAgent*> pet =
			ghost->getActivePet(i);

		if (pet == nullptr || pet->isDead())
			continue;

		++livingCount;
		onlyPetId = pet->getObjectID();
	}

	if (livingCount <= 0) {
		player->sendSystemMessage(
			"You do not have an active, living pet to buff. You were not charged.");
		showPetServicesMenu(station, player);
		return;
	}

	if (livingCount == 1) {
		purchasePetBuffs(
			station, player, useJanta,
			onlyPetId, false);
		return;
	}

	ManagedReference<SuiListBox*> box =
		new SuiListBox(
			player, SuiWindowType::NONE,
			SuiListBox::HANDLETWOBUTTON);

	box->setPromptTitle(
		String("Automated Medical Station - Select Pet (") +
		(useJanta ? "Janta" : "Standard") + ")");
	box->setPromptText(
		"Select the exact active pet to receive the buffs.");
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");

	for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
		ManagedReference<AiAgent*> pet =
			ghost->getActivePet(i);

		if (pet == nullptr || pet->isDead())
			continue;

		String label = pet->getDisplayedName();
		if (pet->isInCombat())
			label += " [IN COMBAT]";

		box->addMenuItem(
			label, pet->getObjectID());
	}

	box->setCallback(
		new DoctorServicePetTargetSuiCallback(
			player->getZoneServer(),
			station, useJanta));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::showMedicalServicesMenu(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	int poisonUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_POISON, 0);
	int diseaseUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_DISEASE, 0);

	ManagedReference<SuiListBox*> box =
		new SuiListBox(
			player, SuiWindowType::NONE,
			SuiListBox::HANDLETWOBUTTON);

	box->setPromptTitle(
		"Automated Medical Station - Additional Medical Services");
	box->setPromptText(
		"Select a medical service. Resistance services do not consume a new Bivoli charge.");
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");

	box->addMenuItem(
		String("Wound Healing - ") +
		(data->isServiceEnabled(
			DoctorBuffDroidDataComponent::SERVICE_WOUNDS) ?
			"READY" : "OFFLINE BY OWNER") +
		" - " + getPriceLine(
			data,
			DoctorBuffDroidDataComponent::SERVICE_WOUNDS,
			player));

	box->addMenuItem(
		String("Poison Resistance - ") +
		(!data->isServiceEnabled(
			DoctorBuffDroidDataComponent::SERVICE_POISON) ?
			"OFFLINE BY OWNER" :
			(poisonUses > 0 ? "READY" : "OUT OF STOCK")) +
		" - " + getPriceLine(
			data,
			DoctorBuffDroidDataComponent::SERVICE_POISON,
			player) +
		" - " + String::valueOf(poisonUses) +
		" use(s)");

	box->addMenuItem(
		String("Disease Resistance - ") +
		(!data->isServiceEnabled(
			DoctorBuffDroidDataComponent::SERVICE_DISEASE) ?
			"OFFLINE BY OWNER" :
			(diseaseUses > 0 ? "READY" : "OUT OF STOCK")) +
		" - " + getPriceLine(
			data,
			DoctorBuffDroidDataComponent::SERVICE_DISEASE,
			player) +
		" - " + String::valueOf(diseaseUses) +
		" use(s)");

	box->setCallback(
		new DoctorServiceMedicalServicesSuiCallback(
			player->getZoneServer(), station));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr || !data->isOwner(player))
		return;

	ManagedReference<SuiListBox*> box =
		new SuiListBox(
			player, SuiWindowType::NONE,
			SuiListBox::HANDLETWOBUTTON);

	box->setPromptTitle(
		"Automated Medical Station - Owner Configuration");
	box->setPromptText(
		"Select a station-management option.");
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");

	box->addMenuItem("Configure Service Prices");
	box->addMenuItem("Toggle Services");
	box->addMenuItem("Configure Guild Discount");
	box->addMenuItem("Set / Edit Station Message");
	box->addMenuItem("Clear Station Message");
	box->addMenuItem("View Earnings");
	box->addMenuItem("Withdraw Earnings");
	box->addMenuItem("Refresh Doctor Stats / Guild");

	box->setCallback(
		new DoctorServiceOwnerConfigSuiCallback(
			player->getZoneServer(), station));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::handleMainMenuSelection(
	SceneObject* station, CreatureObject* player,
	uint64 actionId) {

	if (station == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	switch (actionId) {
	case kMainActionStandard:
		purchaseBuffs(station, player, false);
		return;
	case kMainActionJanta:
		purchaseBuffs(station, player, true);
		return;
	case kMainActionPet:
		showPetServicesMenu(station, player);
		return;
	case kMainActionMedical:
		showMedicalServicesMenu(station, player);
		return;
	case kMainActionAvailability:
		showAvailability(station, player);
		return;
	case kMainActionHopper: {
		if (!data->isOwner(player))
			return;

		ManagedReference<SceneObject*> hopper =
			DoctorBuffDroidMenuComponent::getSupplyContainer(station);

		if (hopper == nullptr || hopper == station) {
			player->sendSystemMessage(
				"Safety lock: the Medical Supply Hopper is missing. "
				"No recovery or relocation was attempted.");
			return;
		}

		player->executeObjectControllerAction(
			STRING_HASHCODE("opencontainer"),
			hopper->getObjectID(), "");
		return;
	}
	case kMainActionInventory:
		if (data->isOwner(player))
			showInventory(station, player);
		return;
	case kMainActionOwner:
		if (data->isOwner(player))
			showOwnerConfigMenu(station, player);
		return;
	case kMainActionSafety:
		if (data->isOwner(player))
			sendSafetyStatus(station, player);
		return;
	default:
		return;
	}
}

void DoctorServiceUnitMenuComponent::handlePetServiceSelection(
	SceneObject* station, CreatureObject* player, int index) {

	if (station == nullptr || player == nullptr)
		return;

	if (index == 0)
		showPetTargetMenu(station, player, false);
	else if (index == 1)
		showPetTargetMenu(station, player, true);
}

void DoctorServiceUnitMenuComponent::handlePetTargetSelection(
	SceneObject* station, CreatureObject* player,
	bool useJanta, uint64 petObjectId) {

	purchasePetBuffs(
		station, player, useJanta,
		petObjectId, false);
}

void DoctorServiceUnitMenuComponent::handleMedicalServiceSelection(
	SceneObject* station, CreatureObject* player, int index) {

	if (station == nullptr || player == nullptr)
		return;

	if (index == 0)
		purchaseWoundHealing(station, player);
	else if (index == 1)
		purchaseResistance(station, player, true);
	else if (index == 2)
		purchaseResistance(station, player, false);
}

void DoctorServiceUnitMenuComponent::handleOwnerConfigSelection(
	SceneObject* station, CreatureObject* player, int index) {

	if (station == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr || !data->isOwner(player)) {
		player->sendSystemMessage(
			"Only the station owner can use that configuration option.");
		return;
	}

	switch (index) {
	case 0:
		DoctorBuffDroidMenuComponent::promptPriceSelection(
			station, player);
		return;
	case 1:
		DoctorBuffDroidMenuComponent::promptToggleSelection(
			station, player);
		return;
	case 2:
		DoctorBuffDroidMenuComponent::promptDiscountInput(
			station, player);
		return;
	case 3:
		DoctorBuffDroidMenuComponent::promptAdTextInput(
			station, player);
		return;
	case 4:
		data->setAdBarkText("");
		data->setAdBarkEnabled(false);
		station->updateToDatabase();
		player->sendSystemMessage(
			"Automated Medical Station message cleared.");
		showOwnerConfigMenu(station, player);
		return;
	case 5:
		player->sendSystemMessage(
			"Automated Medical Station unclaimed earnings: " +
			String::valueOf(data->getEarningsBalance()) +
			" credits.");
		showOwnerConfigMenu(station, player);
		return;
	case 6: {
		int amount = data->withdrawEarnings();

		if (amount <= 0) {
			player->sendSystemMessage(
				"Automated Medical Station has no earnings to withdraw.");
		} else {
			player->addCashCredits(amount, true);
			station->updateToDatabase();
			player->sendSystemMessage(
				"Withdrew " + String::valueOf(amount) +
				" credits from the Automated Medical Station.");
		}

		showOwnerConfigMenu(station, player);
		return;
	}
	case 7:
		if (!player->hasSkill(kDoctorSkill)) {
			player->sendSystemMessage(
				"You must currently be a Master Doctor to refresh "
				"the station's Doctor stats.");
			showOwnerConfigMenu(station, player);
			return;
		}

		if (DoctorBuffDroidMenuComponent::refreshOwnerHealingMod(
				station, player, data)) {
			player->sendSystemMessage(
				"Automated Medical Station Doctor stats and guild affiliation "
				"refreshed. Food buffs on your character are excluded from "
				"the cached base Doctor value.");
		}

		showOwnerConfigMenu(station, player);
		return;
	default:
		return;
	}
}

void DoctorServiceUnitMenuComponent::handleRebuffConfirmation(
	SceneObject* station, CreatureObject* player,
	bool useJanta, uint64 petObjectId) {

	if (petObjectId == 0)
		purchaseBuffs(
			station, player, useJanta, true);
	else
		purchasePetBuffs(
			station, player, useJanta,
			petObjectId, true);
}

void DoctorServiceUnitMenuComponent::showRebuffConfirm(
	SceneObject* station, CreatureObject* player,
	bool useJanta, uint64 petObjectId) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	StringBuffer prompt;

	if (petObjectId == 0) {
		prompt
			<< "You already have active Doctor enhancements. "
			<< "Purchasing "
			<< (useJanta ? "Janta" : "Standard")
			<< " Doctor Buffs will replace those enhancements "
			<< "and reset their durations.";
	} else {
		prompt
			<< "The selected pet already has active Doctor enhancements. "
			<< "Purchasing "
			<< (useJanta ? "Janta" : "Standard")
			<< " Doctor Pet Buffs will replace those enhancements "
			<< "and reset their durations.";
	}

	prompt << "\n\nContinue with the purchase?";

	ManagedReference<SuiMessageBox*> box =
		new SuiMessageBox(player, SuiWindowType::NONE);

	box->setPromptTitle(
		"Automated Medical Station - Replace Existing Buffs");
	box->setPromptText(prompt.toString());
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");
	box->setCallback(
		new DoctorServiceRebuffConfirmSuiCallback(
			player->getZoneServer(),
			station, useJanta, petObjectId));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::purchaseBuffs(
	SceneObject* station, CreatureObject* player,
	bool useJanta, bool confirmed) {

	if (station == nullptr || player == nullptr)
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: service is disabled because " +
			reason +
			" The station was not moved or modified.");
		return;
	}

	if (!confirmed && hasExistingDoctorEnhancements(player)) {
		showRebuffConfirm(
			station, player, useJanta, 0);
		return;
	}

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	ManagedReference<SceneObject*> hopper =
		DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	if (data == nullptr || hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: Medical Supply Hopper is unavailable.");
		return;
	}

	Locker hopperLocker(hopper, station);

	DoctorBuffDroidMenuComponent::performMedicalBuff(
		station, player, data, useJanta);
}

void DoctorServiceUnitMenuComponent::purchasePetBuffs(
	SceneObject* station, CreatureObject* player,
	bool useJanta, uint64 petObjectId, bool confirmed) {

	if (station == nullptr || player == nullptr ||
			petObjectId == 0)
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: service is disabled because " +
			reason +
			" The station was not moved or modified.");
		return;
	}

	ManagedReference<PlayerObject*> ghost =
		player->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<AiAgent*> selectedPet;

	for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
		ManagedReference<AiAgent*> pet =
			ghost->getActivePet(i);

		if (pet != nullptr &&
				pet->getObjectID() == petObjectId) {
			selectedPet = pet;
			break;
		}
	}

	if (selectedPet == nullptr || selectedPet->isDead()) {
		player->sendSystemMessage(
			"The selected pet is no longer active and living. You were not charged.");
		showPetServicesMenu(station, player);
		return;
	}

	if (selectedPet->isInCombat()) {
		player->sendSystemMessage(
			"The selected pet is in combat and cannot be buffed right now. You were not charged.");
		showPetServicesMenu(station, player);
		return;
	}

	if (!confirmed &&
			hasExistingDoctorEnhancements(selectedPet.get())) {
		showRebuffConfirm(
			station, player, useJanta,
			selectedPet->getObjectID());
		return;
	}

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	ManagedReference<SceneObject*> hopper =
		DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	if (data == nullptr || hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: Medical Supply Hopper is unavailable.");
		return;
	}

	Locker hopperLocker(hopper, station);

	DoctorBuffDroidMenuComponent::performPetBuffForTarget(
		station, player, data,
		selectedPet.get(), useJanta);
}

void DoctorServiceUnitMenuComponent::purchaseResistance(
	SceneObject* station, CreatureObject* player, bool poison) {

	if (station == nullptr || player == nullptr)
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: service is disabled because " +
			reason +
			" The station was not moved or modified.");
		return;
	}

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	ManagedReference<SceneObject*> hopper =
		DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	if (data == nullptr || hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: Medical Supply Hopper is unavailable.");
		return;
	}

	Locker hopperLocker(hopper, station);

	DoctorBuffDroidMenuComponent::performResistance(
		station, player, data,
		poison ?
			DoctorBuffDroidDataComponent::SERVICE_POISON :
			DoctorBuffDroidDataComponent::SERVICE_DISEASE);
}

void DoctorServiceUnitMenuComponent::purchaseWoundHealing(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: service is disabled because " +
			reason +
			" The station was not moved or modified.");
		return;
	}

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	DoctorBuffDroidMenuComponent::performWoundHealing(
		station, player, data);
}

int DoctorServiceUnitMenuComponent::handleObjectMenuSelect(
	SceneObject* sceneObject, CreatureObject* player,
	byte selectedID) const {

	if (sceneObject == nullptr || player == nullptr)
		return 0;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(sceneObject);

	if (data == nullptr)
		return 0;

	bool owner = data->isOwner(player);

	switch (selectedID) {
	case MENU_ROOT:
		return 0;

	case MENU_STATION_MENU:
		showStationMainMenu(sceneObject, player);
		return 0;

	case MENU_BUY_STANDARD:
		purchaseBuffs(
			sceneObject, player, false);
		return 0;

	case MENU_BUY_JANTA:
		purchaseBuffs(
			sceneObject, player, true);
		return 0;

	case MENU_PET_SERVICES:
		showPetServicesMenu(
			sceneObject, player);
		return 0;

	case MENU_MEDICAL_SERVICES:
		showMedicalServicesMenu(
			sceneObject, player);
		return 0;

	case MENU_AVAILABILITY:
		showAvailability(
			sceneObject, player);
		return 0;

	case MENU_OPEN_HOPPER: {
		if (!owner) {
			player->sendSystemMessage(
				"Only the station owner can access the Medical Supply Hopper.");
			return 0;
		}

		ManagedReference<SceneObject*> hopper =
			DoctorBuffDroidMenuComponent::getSupplyContainer(
				sceneObject);

		if (hopper == nullptr || hopper == sceneObject) {
			player->sendSystemMessage(
				"Safety lock: the Medical Supply Hopper is missing. "
				"No recovery or relocation was attempted.");
			return 0;
		}

		player->executeObjectControllerAction(
			STRING_HASHCODE("opencontainer"),
			hopper->getObjectID(), "");
		return 0;
	}

	case MENU_INVENTORY:
		if (!owner) {
			player->sendSystemMessage(
				"Only the station owner can view the Medical Supply Hopper inventory.");
			return 0;
		}

		showInventory(sceneObject, player);
		return 0;

	case MENU_OWNER_CONFIG:
		if (owner)
			showOwnerConfigMenu(sceneObject, player);
		return 0;

	case MENU_SAFETY_STATUS:
		if (owner)
			sendSafetyStatus(sceneObject, player);
		return 0;

	case MENU_DECOMMISSION:
		if (!owner) {
			player->sendSystemMessage(
				"Only the station owner can decommission it.");
			return 0;
		}

		decommission(sceneObject, player);
		return 0;

	default:
		return 0;
	}
}

void DoctorServiceUnitMenuComponent::showAvailability(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr)
		return;

	String placementReason;
	bool placementValid =
		isPlacementValid(station, &placementReason);

	ManagedReference<SceneObject*> hopper =
		DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	if (hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Automated Medical Station safety lock: inventory status is unavailable.");
		return;
	}

	Locker hopperLocker(hopper, station);

	int standardSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station,
			DoctorBuffDroidDataComponent::SERVICE_BUFFS);
	int jantaSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station,
			DoctorBuffDroidDataComponent::SERVICE_JANTA);
	int poisonUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_POISON, 0);
	int diseaseUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_DISEASE, 0);

	String standardMissing =
		DoctorBuffDroidMenuComponent::getDoctorServiceMissingAttributes(
			station,
			DoctorBuffDroidDataComponent::SERVICE_BUFFS);
	String jantaMissing =
		DoctorBuffDroidMenuComponent::getDoctorServiceMissingAttributes(
			station,
			DoctorBuffDroidDataComponent::SERVICE_JANTA);

	int bivoliReserve =
		DoctorBuffDroidMenuComponent::getDoctorServiceBivoliReserve(
			station);

	Time now;
	uint64 nowMs = now.getMiliTime();
	int activeBivoliBonus =
		data->getActiveBivoliBonus(nowMs);
	bool bivoliReady =
		activeBivoliBonus > 0 || bivoliReserve > 0;

	StringBuffer report;
	report << "AUTOMATED MEDICAL STATION";

	String stationMessage = data->getAdBarkText();

	if (!stationMessage.isEmpty())
		report << "\n\nDoctor's Message:\n"
			   << stationMessage;

	if (!placementValid) {
		report << "\n\nSAFETY LOCKED"
			   << "\nReason: " << placementReason
			   << "\nNo purchases are available.";
	} else {
		bool standardEnabled =
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_BUFFS);
		bool jantaEnabled =
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_JANTA);
		bool woundsEnabled =
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_WOUNDS);
		bool poisonEnabled =
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_POISON);
		bool diseaseEnabled =
			data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_DISEASE);

		report << "\n\nStandard Doctor Buffs"
			   << "\n"
			   << getServiceStateLabel(
					standardEnabled,
					standardSessions,
					bivoliReady);
		appendPriceDetails(
			report, data,
			DoctorBuffDroidDataComponent::SERVICE_BUFFS,
			player);
		report << "\nComplete Sessions Available: "
			   << standardSessions;

		if (standardSessions <= 0)
			report << "\nMissing: " << standardMissing;
		else if (standardSessions <= kLowStockThreshold)
			report << "\nLOW STOCK";

		report << "\n\nJanta Doctor Buffs"
			   << "\n"
			   << getServiceStateLabel(
					jantaEnabled,
					jantaSessions,
					bivoliReady);
		appendPriceDetails(
			report, data,
			DoctorBuffDroidDataComponent::SERVICE_JANTA,
			player);
		report << "\nComplete Sessions Available: "
			   << jantaSessions;

		if (jantaSessions <= 0)
			report << "\nMissing: " << jantaMissing;
		else if (jantaSessions <= kLowStockThreshold)
			report << "\nLOW STOCK";

		report << "\n\nPet Buffs"
			   << "\nStandard and Janta pet buffs use the same stock and price as player buffs."
			   << "\nWhen multiple living pets are active, you can select the exact target."
			   << "\nExisting Doctor buffs require confirmation before replacement.";

		report << "\n\nWound Healing"
			   << "\n"
			   << (woundsEnabled ?
					"READY" : "OFFLINE BY OWNER");
		appendPriceDetails(
			report, data,
			DoctorBuffDroidDataComponent::SERVICE_WOUNDS,
			player);
		report << "\nNo supply item is required.";

		report << "\n\nPoison Resistance"
			   << "\n"
			   << (!poisonEnabled ?
					"OFFLINE BY OWNER" :
					(poisonUses > 0 ?
						"READY" : "OUT OF STOCK"));
		appendPriceDetails(
			report, data,
			DoctorBuffDroidDataComponent::SERVICE_POISON,
			player);
		report << "\nUses Available: " << poisonUses;

		if (poisonUses > 0 &&
				poisonUses <= kLowStockThreshold)
			report << "\nLOW STOCK";

		report << "\n\nDisease Resistance"
			   << "\n"
			   << (!diseaseEnabled ?
					"OFFLINE BY OWNER" :
					(diseaseUses > 0 ?
						"READY" : "OUT OF STOCK"));
		appendPriceDetails(
			report, data,
			DoctorBuffDroidDataComponent::SERVICE_DISEASE,
			player);
		report << "\nUses Available: " << diseaseUses;

		if (diseaseUses > 0 &&
				diseaseUses <= kLowStockThreshold)
			report << "\nLOW STOCK";

		report << "\n\nBivoli Support";

		if (activeBivoliBonus > 0) {
			float remainingFloat =
				data->getActiveBivoliTimeRemaining(nowMs);
			int remainingSeconds =
				(int)remainingFloat;

			if ((float)remainingSeconds <
					remainingFloat)
				++remainingSeconds;

			report << "\nACTIVE: +"
				   << activeBivoliBonus
				   << " wound treatment"
				   << "\nTime Remaining: "
				   << formatRemainingTime(
						remainingSeconds)
				   << "\nReserve Uses: "
				   << bivoliReserve;
		} else if (bivoliReserve > 0) {
			report << "\nAVAILABLE"
				   << "\nReserve Uses: "
				   << bivoliReserve;
		} else {
			report << "\nOUT OF STOCK"
				   << "\nA new Standard/Janta player or pet buff session cannot begin until Bivoli is restocked.";
		}

		report << "\nResistance purchases never consume a new Bivoli charge; "
			   << "an already-active session can still contribute.";

		if (data->getGuildDiscountPercent() > 0)
			report << "\n\nOwner Guild Discount: "
				   << data->getGuildDiscountPercent()
				   << "%";

		report << "\n\nPurchases are preflighted before charging."
			   << "\nIncomplete or unavailable services will not charge the customer.";
	}

	ManagedReference<SuiMessageBox*> box =
		new SuiMessageBox(
			player, SuiWindowType::NONE);

	box->setPromptTitle(
		"Automated Medical Station - Services / Availability");
	box->setPromptText(report.toString());
	box->setUsingObject(station);
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");
	box->setCallback(
		new DoctorServiceBackSuiCallback(
			player->getZoneServer(),
			station, false));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::showInventory(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr ||
			player->getPlayerObject() == nullptr)
		return;

	DoctorBuffDroidDataComponent* data =
		DoctorBuffDroidMenuComponent::getDroidData(station);

	if (data == nullptr || !data->isOwner(player))
		return;

	ManagedReference<SceneObject*> hopper =
		DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	if (hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Safety lock: the Medical Supply Hopper is missing. "
			"No recovery or relocation was attempted.");
		return;
	}

	Locker hopperLocker(hopper, station);

	int standardSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station,
			DoctorBuffDroidDataComponent::SERVICE_BUFFS);
	int jantaSessions =
		DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
			station,
			DoctorBuffDroidDataComponent::SERVICE_JANTA);
	int poisonUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_POISON, 0);
	int diseaseUses =
		DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
			station,
			DoctorBuffDroidDataComponent::SERVICE_DISEASE, 0);
	int bivoliReserve =
		DoctorBuffDroidMenuComponent::getDoctorServiceBivoliReserve(
			station);

	StringBuffer report;
	report << "SERVICE / RESTOCK SUMMARY";

	report << "\n\nStandard Doctor Buffs"
		   << "\nConfigured Price: "
		   << data->getPrice(
				DoctorBuffDroidDataComponent::SERVICE_BUFFS)
		   << " credits"
		   << "\nService: "
		   << (data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_BUFFS) ?
				"ENABLED" : "DISABLED")
		   << "\nComplete Sessions: "
		   << standardSessions;
	appendBuffPoolStock(
		report, station,
		DoctorBuffDroidDataComponent::SERVICE_BUFFS);

	if (standardSessions <= kLowStockThreshold)
		report << "\nLOW STOCK - restock the limiting attribute(s).";

	report << "\n\nJanta Doctor Buffs"
		   << "\nConfigured Price: "
		   << data->getPrice(
				DoctorBuffDroidDataComponent::SERVICE_JANTA)
		   << " credits"
		   << "\nService: "
		   << (data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_JANTA) ?
				"ENABLED" : "DISABLED")
		   << "\nComplete Sessions: "
		   << jantaSessions;
	appendBuffPoolStock(
		report, station,
		DoctorBuffDroidDataComponent::SERVICE_JANTA);

	if (jantaSessions <= kLowStockThreshold)
		report << "\nLOW STOCK - restock the limiting attribute(s).";

	report << "\n\nWound Healing"
		   << "\nConfigured Price: "
		   << data->getPrice(
				DoctorBuffDroidDataComponent::SERVICE_WOUNDS)
		   << " credits"
		   << "\nService: "
		   << (data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_WOUNDS) ?
				"ENABLED" : "DISABLED")
		   << "\nSupply Required: No";

	report << "\n\nPoison Resistance"
		   << "\nConfigured Price: "
		   << data->getPrice(
				DoctorBuffDroidDataComponent::SERVICE_POISON)
		   << " credits"
		   << "\nService: "
		   << (data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_POISON) ?
				"ENABLED" : "DISABLED")
		   << "\nUses Available: "
		   << poisonUses;

	if (poisonUses <= kLowStockThreshold)
		report << "\nLOW STOCK - restock soon.";

	report << "\n\nDisease Resistance"
		   << "\nConfigured Price: "
		   << data->getPrice(
				DoctorBuffDroidDataComponent::SERVICE_DISEASE)
		   << " credits"
		   << "\nService: "
		   << (data->isServiceEnabled(
				DoctorBuffDroidDataComponent::SERVICE_DISEASE) ?
				"ENABLED" : "DISABLED")
		   << "\nUses Available: "
		   << diseaseUses;

	if (diseaseUses <= kLowStockThreshold)
		report << "\nLOW STOCK - restock soon.";

	Time now;
	uint64 nowMs = now.getMiliTime();
	int activeBivoliBonus =
		data->getActiveBivoliBonus(nowMs);

	report << "\n\nBivoli Reserve Uses: "
		   << bivoliReserve;

	if (activeBivoliBonus > 0) {
		float remainingFloat =
			data->getActiveBivoliTimeRemaining(nowMs);
		int remainingSeconds =
			(int)remainingFloat;

		if ((float)remainingSeconds <
				remainingFloat)
			++remainingSeconds;

		report << "\nActive Bivoli Session: +"
			   << activeBivoliBonus
			   << " wound treatment | "
			   << formatRemainingTime(
					remainingSeconds)
			   << " remaining";
	} else {
		report << "\nActive Bivoli Session: INACTIVE";
	}

	report << "\n\nUnclaimed Earnings: "
		   << data->getEarningsBalance()
		   << " credits"
		   << "\nGuild Discount: "
		   << data->getGuildDiscountPercent()
		   << "%"
		   << "\nOwner Guild Cache: "
		   << (data->getOwnerGuildId() != 0 ?
				"SET" : "NOT SET");

	String stationMessage =
		data->getAdBarkText();

	report << "\nStation Message: "
		   << (stationMessage.isEmpty() ?
				String("[none]") :
				stationMessage);

	report << "\n\nDETAILED HOPPER CONTENTS"
		   << "\nHopper objects: "
		   << hopper->getContainerObjectsSize()
		   << " / 100";

	uint64 totalUsableCharges = 0;

	if (hopper->getContainerObjectsSize() == 0) {
		report << "\nThe hopper is empty.";
	} else {
		for (int i = 0;
				i < hopper->getContainerObjectsSize(); ++i) {
			SceneObject* item =
				hopper->getContainerObject(i);

			if (item == nullptr)
				continue;

			if (item->isFactoryCrate()) {
				FactoryCrate* crate =
					cast<FactoryCrate*>(item);

				if (crate == nullptr) {
					report << "\n[Invalid Factory Crate]";
					continue;
				}

				Reference<TangibleObject*> prototype =
					crate->getPrototype();

				String displayName =
					prototype != nullptr ?
						prototype->getDisplayedName() :
						item->getDisplayedName();

				uint32 factoryItems =
					crate->getUseCount();

				int chargesPerItem =
					crate->getPrototypeUseCount();

				if (chargesPerItem < 1)
					chargesPerItem = 1;

				uint64 usableCharges =
					(uint64)factoryItems *
					(uint64)chargesPerItem;

				totalUsableCharges += usableCharges;

				report << "\n"
					   << displayName
					   << " [Factory Crate] - "
					   << factoryItems
					   << " item(s) x "
					   << chargesPerItem
					   << " charge(s) = "
					   << usableCharges
					   << " total use(s)";
				continue;
			}

			if (item->isTangibleObject()) {
				TangibleObject* tangible =
					cast<TangibleObject*>(item);

				if (tangible == nullptr)
					continue;

				uint32 uses =
					tangible->getUseCount();

				if (uses < 1)
					uses = 1;

				totalUsableCharges += uses;

				report << "\n"
					   << item->getDisplayedName()
					   << " - "
					   << uses
					   << " use(s)";
				continue;
			}

			report << "\n"
				   << item->getDisplayedName()
				   << " - [Unsupported object type]";
		}
	}

	report << "\n\nTotal usable charges in hopper: "
		   << totalUsableCharges;

	ManagedReference<SuiMessageBox*> box =
		new SuiMessageBox(
			player, SuiWindowType::NONE);

	box->setPromptTitle(
		"Automated Medical Station - Inventory / Stock");
	box->setPromptText(report.toString());
	box->setUsingObject(station);
	box->setCancelButton(true, "@back");
	box->setOkButton(true, "@ok");
	box->setCallback(
		new DoctorServiceBackSuiCallback(
			player->getZoneServer(),
			station, true));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorServiceUnitMenuComponent::sendSafetyStatus(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	String reason;
	bool valid = isPlacementValid(station, &reason);

	ManagedReference<SceneObject*> parent = station->getParent().get();
	ManagedReference<SceneObject*> root = station->getRootParent();
	ManagedReference<SceneObject*> hopper = DoctorBuffDroidMenuComponent::getSupplyContainer(station);

	StringBuffer msg;
	msg << "FMDoctorBot Safety Status"
		<< " | station=" << station->getObjectID()
		<< " | parent=" << (parent != nullptr ? parent->getObjectID() : 0)
		<< " | building=" << (root != nullptr ? root->getObjectID() : 0)
		<< " | hopper=" << ((hopper != nullptr && hopper != station) ? hopper->getObjectID() : 0)
		<< " | hopperItems=" << ((hopper != nullptr && hopper != station) ? hopper->getContainerObjectsSize() : 0)
		<< " | local=(" << station->getPositionX() << "," << station->getPositionZ() << "," << station->getPositionY() << ")"
		<< " | status=" << (valid ? "VALID" : "SAFETY_LOCKED");

	if (!valid)
		msg << " | reason=" << reason;

	player->sendSystemMessage(msg.toString());
}

void DoctorServiceUnitMenuComponent::decommission(
	SceneObject* station, CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(station);
	if (data == nullptr || !data->isOwner(player))
		return;

	ManagedReference<SceneObject*> hopper = DoctorBuffDroidMenuComponent::getSupplyContainer(station);
	if (hopper == nullptr || hopper == station) {
		player->sendSystemMessage(
			"Decommission blocked: the Medical Supply Hopper relationship is invalid. "
			"No object was destroyed. Contact an administrator for recovery.");
		return;
	}

	Locker hopperLocker(hopper, station);

	if (hopper->getContainerObjectsSize() > 0) {
		player->sendSystemMessage("Empty the Medical Supply Hopper before decommissioning this station.");
		return;
	}

	if (data->hasLegacyStock() || data->getBivoliStock() > 0 || data->getJantaStock() > 0) {
		player->sendSystemMessage(
			"Decommission blocked: legacy/scalar medical stock is still recorded. "
			"No object was destroyed; contact an administrator.");
		return;
	}

	if (data->getEarningsBalance() > 0) {
		player->sendSystemMessage("Withdraw all station earnings before decommissioning.");
		return;
	}

	ManagedReference<SceneObject*> inventory = player->getInventory();
	ZoneServer* zoneServer = player->getZoneServer();

	if (inventory == nullptr || zoneServer == nullptr || inventory->isContainerFullRecursive()) {
		player->sendSystemMessage("You need inventory space for the replacement Automated Medical Station deed.");
		return;
	}

	ManagedReference<SceneObject*> deed = zoneServer->createObject(kDeedTemplate.hashCode(), 1);
	if (deed == nullptr) {
		player->sendSystemMessage("Decommission failed before any station data was changed.");
		return;
	}

	Locker deedLocker(deed, player);

	TransactionLog trx(station, player, deed, TrxCode::PLAYERMISCACTION);
	trx.addState("feature", String("FMDoctorBot"));
	trx.addState("action", String("decommission"));

	// Transactional order: create + successfully deliver replacement deed FIRST.
	// Only after that succeeds is the station destroyed.
	if (!inventory->transferObject(deed, -1, true)) {
		trx.abort() << "FMDoctorBot deed transfer failed; station left intact.";
		deed->destroyObjectFromDatabase(true);
		player->sendSystemMessage(
			"Decommission failed while delivering the replacement deed. The station was left intact.");
		return;
	}

	inventory->broadcastObject(deed, true);
	trx.commit();

	station->info(true)
		<< "FMDoctorBot DECOMMISSION owner=" << player->getObjectID()
		<< " station=" << station->getObjectID()
		<< " hopper=" << hopper->getObjectID();

	hopperLocker.release();

	station->destroyObjectFromWorld(true);
	station->destroyObjectFromDatabase(true);

	player->sendSystemMessage("Automated Medical Station decommissioned and deed returned to your inventory.");
}
