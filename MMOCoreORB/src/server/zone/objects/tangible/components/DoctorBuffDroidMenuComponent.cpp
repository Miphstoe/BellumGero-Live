#include "DoctorBuffDroidMenuComponent.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidPriceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidPriceInputSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidDiscountSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidToggleSuiCallback.h"
#include "server/zone/objects/intangible/VehicleControlDevice.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/tangible/consumable/Consumable.h"
#include "server/zone/objects/tangible/pharmaceutical/EnhancePack.h"
#include "server/zone/objects/tangible/pharmaceutical/PharmaceuticalObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/city/CitySpecialization.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/creature/buffs/BuffType.h"
#include "server/zone/objects/creature/BuffAttribute.h"
#include "server/zone/objects/creature/buffs/BuffList.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/SharedTangibleObjectTemplate.h"
#include <limits>

namespace {
const String kDoctorSkill = "science_doctor_master";
const uint32 kBivoliBuffCRC = 0x2114D76D;
const String kBivoliSkillMod = "healing_wound_treatment";

bool isMasterDoctor(CreatureObject* player) {
	return player != nullptr && player->hasSkill(kDoctorSkill);
}

String getServiceName(DoctorBuffDroidDataComponent::ServiceType type) {
	switch (type) {
	case DoctorBuffDroidDataComponent::SERVICE_BUFFS:
		return "Medical Buffs";
	case DoctorBuffDroidDataComponent::SERVICE_WOUNDS:
		return "Heal Wounds";
	case DoctorBuffDroidDataComponent::SERVICE_POISON:
		return "Poison Resistance";
	case DoctorBuffDroidDataComponent::SERVICE_DISEASE:
	default:
		return "Disease Resistance";
	}
}

bool deductCredits(CreatureObject* player, int amount) {
	if (player == nullptr || amount < 0)
		return false;

	int bank = player->getBankCredits();
	int cash = player->getCashCredits();

	if (bank + cash < amount)
		return false;

	if (bank >= amount) {
		player->subtractBankCredits(amount);
	} else {
		if (bank > 0)
			player->subtractBankCredits(bank);

		player->subtractCashCredits(amount - bank);
	}

	return true;
}

Consumable* getConsumable(SceneObject* item) {
	if (item == nullptr)
		return nullptr;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate())
			return nullptr;

		item = crate->getPrototype();
		if (item == nullptr)
			return nullptr;
	}

	if (!item->isTangibleObject())
		return nullptr;

	TangibleObject* tangible = cast<TangibleObject*>(item);
	if (tangible == nullptr || !tangible->isConsumable())
		return nullptr;

	return cast<Consumable*>(tangible);
}

bool isBivoliSupply(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	return consumable != nullptr && consumable->getBuffCRC() == kBivoliBuffCRC;
}

DoctorBuffDroidDataComponent::ServiceType getSupplyType(SceneObject* item) {
	if (item == nullptr)
		return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate())
			return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

		TangibleObject* prototype = crate->getPrototype();
		if (prototype == nullptr)
			return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

		item = prototype;
	}

	if (!item->isPharmaceuticalObject())
		return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	if (pharma == nullptr || !pharma->isEnhancePack())
		return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

	EnhancePack* pack = cast<EnhancePack*>(pharma);
	if (pack == nullptr)
		return DoctorBuffDroidDataComponent::SERVICE_WOUNDS;

	if (pack->getAttribute() == BuffAttribute::POISON)
		return DoctorBuffDroidDataComponent::SERVICE_POISON;

	if (pack->getAttribute() == BuffAttribute::DISEASE)
		return DoctorBuffDroidDataComponent::SERVICE_DISEASE;

	return DoctorBuffDroidDataComponent::SERVICE_BUFFS;
}

bool isValidSupply(SceneObject* item) {
	if (item == nullptr)
		return false;

	if (isBivoliSupply(item))
		return true;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate() || crate->getUseCount() <= 0)
			return false;

		TangibleObject* prototype = crate->getPrototype();
		if (prototype == nullptr)
			return false;

		item = prototype;
	}

	if (!item->isPharmaceuticalObject())
		return false;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	return pharma != nullptr && pharma->isEnhancePack();
}

int getSupplyAmount(SceneObject* item) {
	if (item == nullptr)
		return 0;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr)
			return 0;

		int crateQty = crate->getUseCount(); // number of items remaining in the crate
		TangibleObject* proto = crate->getPrototype();
		int chargesPerItem = (proto != nullptr) ? Math::max(1, proto->getUseCount()) : 1;
		return crateQty * chargesPerItem;
	}

	if (!item->isTangibleObject())
		return 0;

	return Math::max(1, cast<TangibleObject*>(item)->getUseCount());
}

float getBivoliStrength(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	if (consumable == nullptr)
		return 0.0f;

	return consumable->getCurrentNutrition();
}

float getBivoliDuration(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	if (consumable == nullptr)
		return 0.0f;

	float duration = consumable->getDuration();

	if (duration > 0.0f && consumable->getSpeciesRestriction().isEmpty())
		return duration;

	return duration;
}

// Returns the BuffAttribute byte for a buff pack (or its crate prototype).
// For poison/disease this would be 9/10, but those are handled by getSupplyType already.
byte getPackAttribute(SceneObject* item) {
	if (item == nullptr)
		return 0;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr)
			return 0;
		item = crate->getPrototype();
		if (item == nullptr)
			return 0;
	}

	if (!item->isPharmaceuticalObject())
		return 0;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	if (pharma == nullptr || !pharma->isEnhancePack())
		return 0;

	return cast<EnhancePack*>(pharma)->getAttribute();
}

void destroyLoadedSupply(SceneObject* item) {
	if (item == nullptr)
		return;

	item->destroyObjectFromWorld(true);
	item->destroyObjectFromDatabase(true);
}

float getPackEffectiveness(SceneObject* item) {
	if (item == nullptr)
		return 0.0f;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate())
			return 0.0f;

		item = crate->getPrototype();
		if (item == nullptr)
			return 0.0f;
	}

	if (!item->isPharmaceuticalObject())
		return 0.0f;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	if (pharma == nullptr || !pharma->isEnhancePack())
		return 0.0f;

	return cast<EnhancePack*>(pharma)->getEffectiveness();
}

float getPackDuration(SceneObject* item) {
	if (item == nullptr)
		return 0.0f;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate())
			return 0.0f;

		item = crate->getPrototype();
		if (item == nullptr)
			return 0.0f;
	}

	if (!item->isPharmaceuticalObject())
		return 0.0f;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	if (pharma == nullptr || !pharma->isEnhancePack())
		return 0.0f;

	return cast<EnhancePack*>(pharma)->getDuration();
}

// Calculates the environmental medical rating for the droid's location.
// Mirrors EnhancePack::calculatePower: building rating overrides the droid's own base;
// city specialization bonus is always added on top.
int getDroidEnvironmentalMedRating(SceneObject* droid) {
	static const int DROID_BASE_MEDICAL_RATING = 100;

	if (droid == nullptr)
		return DROID_BASE_MEDICAL_RATING;

	int cityMed = 0;
	int buildingMed = 0;

	// City specialization medical bonus
	ManagedReference<CityRegion*> city = droid->getCityRegion().get();
	if (city != nullptr) {
		auto zoneServer = droid->getZoneServer();
		if (zoneServer != nullptr) {
			CityManager* cityManager = zoneServer->getCityManager();
			if (cityManager != nullptr) {
				const CitySpecialization* spec = cityManager->getCitySpecialization(city->getCitySpecialization());
				if (spec != nullptr)
					cityMed = spec->getSkillMods()->get("private_medical_rating");
			}
		}
	}

	// Building template medical bonus (NPC med center, player med center, etc.)
	ManagedReference<SceneObject*> root = droid->getRootParent();
	if (root != nullptr) {
		SharedObjectTemplate* tpl = root->getObjectTemplate();
		if (tpl != nullptr) {
			SharedTangibleObjectTemplate* tanoTpl = dynamic_cast<SharedTangibleObjectTemplate*>(tpl);
			if (tanoTpl != nullptr)
				buildingMed = tanoTpl->getSkillMod("private_medical_rating");
		}
	}

	// Building overrides droid base; city bonus always stacks
	int structureMod = buildingMed > 0 ? buildingMed : DROID_BASE_MEDICAL_RATING;
	return cityMed + structureMod;
}

// Reads the owner's current healing_wound_treatment at buff time so food buffs (e.g. Bivoli)
// are always reflected. Falls back to the cached value only if the owner is offline.
// buyer must already be locked by the calling context.
int getOwnerHealingWoundTreatment(SceneObject* droid, DoctorBuffDroidDataComponent* data, CreatureObject* buyer) {
	if (data == nullptr)
		return 100;

	uint64 ownerId = data->getOwnerId();
	Time now;
	uint64 nowMs = now.getMiliTime();
	int droidBivoliBonus = data->getActiveBivoliBonus(nowMs);

	// Owner is the buyer — already locked, read directly
	if (buyer != nullptr && buyer->getObjectID() == ownerId) {
		int healMod = buyer->getSkillMod(kBivoliSkillMod);
		Buff* manualBivoli = buyer->getBuff(kBivoliBuffCRC);
		if (manualBivoli != nullptr)
			healMod -= manualBivoli->getSkillModifierValue(kBivoliSkillMod);

		return Math::max(0, healMod) + droidBivoliBonus;
	}

	// Owner is someone else — cross-lock to get their current stats
	if (droid != nullptr) {
		ZoneServer* zoneServer = droid->getZoneServer();
		if (zoneServer != nullptr) {
			ManagedReference<SceneObject*> ownerObj = zoneServer->getObject(ownerId);
			if (ownerObj != nullptr && ownerObj->isCreatureObject()) {
				CreatureObject* owner = cast<CreatureObject*>(ownerObj.get());
				Locker ownerLocker(owner, buyer);
				int healMod = owner->getSkillMod(kBivoliSkillMod);
				Buff* manualBivoli = owner->getBuff(kBivoliBuffCRC);
				if (manualBivoli != nullptr)
					healMod -= manualBivoli->getSkillModifierValue(kBivoliSkillMod);

				return Math::max(0, healMod) + droidBivoliBonus;
			}
		}
	}

	// Owner is offline — use value cached at last supply load
	return Math::max(0, data->getOwnerHealingMod()) + droidBivoliBonus;
}

// Final buff power: mirrors EnhancePack::calculatePower using droid-sourced values.
int calculateDroidBuffPower(float packPower, int environmentMod, int healingWoundTreatment) {
	if (packPower <= 0.0f || environmentMod <= 0)
		return 0;

	return Math::max(1, (int)(packPower * (environmentMod / 100.0f) * (100.0f + healingWoundTreatment) / 100.0f));
}

void sendFoodWarnings(CreatureObject* player) {
	if (player == nullptr)
		return;

	const BuffList* buffList = player->getBuffList();
	if (buffList == nullptr)
		return;

	int foodBuffCount = 0;
	float shortestDuration = std::numeric_limits<float>::max();

	for (int i = 0; i < buffList->getBuffListSize(); ++i) {
		Buff* buff = buffList->getBuffByIndex(i);
		if (buff == nullptr || buff->getBuffType() != BuffType::FOOD)
			continue;

		foodBuffCount++;
		shortestDuration = Math::min(shortestDuration, buff->getTimeLeft());
	}

	if (foodBuffCount == 0) {
		player->sendSystemMessage("Doctor Buff Droid notice: no active food or drink buffs detected.");
	} else if (shortestDuration <= 300.f) {
		player->sendSystemMessage("Doctor Buff Droid notice: one or more food or drink buffs are close to expiring.");
	}
}

bool ensureBivoliBuffActive(SceneObject* droid, DoctorBuffDroidDataComponent* data) {
	if (data == nullptr)
		return false;

	Time now;
	uint64 nowMs = now.getMiliTime();

	if (data->getActiveBivoliBonus(nowMs) > 0)
		return true;

	float strength = 0.0f;
	float duration = 0.0f;

	if (!data->consumeBivoliStock(1, strength, duration))
		return false;

	data->activateBivoli(strength, duration, nowMs);
	return data->getActiveBivoliBonus(nowMs) > 0;
}

void persistDroidState(SceneObject* droid) {
	if (droid != nullptr)
		droid->updateToDatabase();
}
}

DoctorBuffDroidDataComponent* DoctorBuffDroidMenuComponent::getDroidData(SceneObject* sceneObject) {
	if (sceneObject == nullptr)
		return nullptr;

	DataObjectComponentReference* dataRef = sceneObject->getDataObjectComponent();
	if (dataRef == nullptr || dataRef->get() == nullptr || !dataRef->get()->isDoctorBuffDroidData())
		return nullptr;

	return cast<DoctorBuffDroidDataComponent*>(dataRef->get());
}

void DoctorBuffDroidMenuComponent::sendOwnerOnlyMessage(CreatureObject* player) {
	if (player != nullptr)
		player->sendSystemMessage("Only the owning Master Doctor can use that Doctor Buff Droid admin function.");
}

void DoctorBuffDroidMenuComponent::sendPriceSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (player == nullptr || data == nullptr)
		return;

	StringBuffer msg;

	if (data->isOwner(player)) {
		// Show configured prices so the owner can verify what they actually set
		msg << "Doctor Buff Droid prices (configured) - Buffs: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS)
			<< ", Wounds: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)
			<< ", Poison: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_POISON)
			<< ", Disease: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_DISEASE)
			<< ". Guild Discount: " << data->getGuildDiscountPercent() << "% (your own price: " << data->getMinimumPriceFloor() << " credits).";
	} else {
		// Show what this player will actually pay
		msg << "Doctor Buff Droid prices - Buffs: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS, player)
			<< ", Wounds: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS, player)
			<< ", Poison: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_POISON, player)
			<< ", Disease: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_DISEASE, player)
			<< ". Guild Discount: " << data->getGuildDiscountPercent() << "%.";
	}

	player->sendSystemMessage(msg.toString());
}

void DoctorBuffDroidMenuComponent::sendStockSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (player == nullptr || data == nullptr)
		return;

	Time now;
	uint64 nowMs = now.getMiliTime();

	StringBuffer msg;
	msg << "Doctor Buff Droid stock:";

	uint32 attrMask = data->getLoadedBuffAttributes();
	if (attrMask == 0) {
		msg << " Buffs: 0 use(s)";
	} else {
		for (uint8 attr = 0; attr < 9; ++attr) {
			int stock = data->getBuffStockByAttr(attr);
			if (stock > 0)
				msg << " " << BuffAttribute::getName(attr, true) << ": " << stock << " use(s)";
		}
	}

	msg << " | Poison resist: " << data->getStock(DoctorBuffDroidDataComponent::SERVICE_POISON)
		<< " use(s) | Disease resist: " << data->getStock(DoctorBuffDroidDataComponent::SERVICE_DISEASE)
		<< " use(s) | Bivoli: " << data->getBivoliStock() << " charge(s)";

	int activeBivoliBonus = data->getActiveBivoliBonus(nowMs);
	if (activeBivoliBonus > 0) {
		float secondsRemainingFloat = data->getActiveBivoliTimeRemaining(nowMs);
		int secondsRemaining = (int) secondsRemainingFloat;
		if ((float) secondsRemaining < secondsRemainingFloat)
			secondsRemaining++;

		msg << " | Active Bivoli: +" << activeBivoliBonus << " wound treatment for " << secondsRemaining << "s";
	}

	msg << ".";

	player->sendSystemMessage(msg.toString());
}

void DoctorBuffDroidMenuComponent::sendEarningsSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (player == nullptr || data == nullptr)
		return;

	player->sendSystemMessage("Doctor Buff Droid earnings balance: " + String::valueOf(data->getEarningsBalance()) + " credits.");
}

bool DoctorBuffDroidMenuComponent::storeDroid(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return false;

	SceneObject* datapad = player->getSlottedObject("datapad");
	if (datapad == nullptr)
		return false;

	for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
		SceneObject* obj = datapad->getContainerObject(i);
		if (obj == nullptr || !obj->isVehicleControlDevice())
			continue;

		VehicleControlDevice* device = cast<VehicleControlDevice*>(obj);
		if (device == nullptr)
			continue;

		SceneObject* controlled = device->getControlledObject();
		if (controlled != nullptr && controlled->getObjectID() == sceneObject->getObjectID()) {
			Locker locker(device, player);
			device->storeObject(player);
			player->sendSystemMessage("Doctor Buff Droid stored in datapad.");
			return true;
		}
	}

	player->sendSystemMessage("Unable to locate the Doctor Buff Droid control device.");
	return false;
}

bool DoctorBuffDroidMenuComponent::loadSupplies(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	SceneObject* inventory = player->getSlottedObject("inventory");
	if (inventory == nullptr)
		return false;

	int loaded = 0;

	for (int i = inventory->getContainerObjectsSize() - 1; i >= 0; --i) {
		SceneObject* item = inventory->getContainerObject(i);
		if (!isValidSupply(item))
			continue;

		DoctorBuffDroidDataComponent::ServiceType service = getSupplyType(item);
		int amount = getSupplyAmount(item);

		if (amount <= 0)
			continue;

		if (isBivoliSupply(item)) {
			float strength = getBivoliStrength(item);
			float duration = getBivoliDuration(item);

			if (strength <= 0.0f || duration <= 0.0f)
				continue;

			data->addBivoliStock(amount, strength, duration);
			destroyLoadedSupply(item);
			loaded += amount;
			continue;
		}

		float effectiveness = getPackEffectiveness(item);
		float duration = getPackDuration(item);
		byte attr = getPackAttribute(item);
		data->addStock(service, amount, effectiveness, attr, duration);
		destroyLoadedSupply(item);
		loaded += amount;
	}

	if (loaded <= 0) {
		player->sendSystemMessage("No valid Doctor Buff Droid supplies were found in your inventory.");
		return false;
	}

	// Cache owner's healing skill mod so buff power calculation doesn't need an owner lock at buff time
	data->setOwnerHealingMod(player->getSkillMod("healing_wound_treatment"));
	persistDroidState(sceneObject);

	player->sendSystemMessage("Loaded " + String::valueOf(loaded) + " valid supply units into the Doctor Buff Droid.");
	sendStockSummary(player, data);
	return true;
}

void DoctorBuffDroidMenuComponent::promptPriceSelection(SceneObject* sceneObject, CreatureObject* player) {
	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (player == nullptr || data == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid Prices");
	box->setPromptText("Select a service to update its price.");
	box->setCallback(new DoctorBuffDroidPriceSuiCallback(player->getZoneServer(), sceneObject));
	box->addMenuItem("Medical Buffs (" + String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS)) + ")");
	box->addMenuItem("Heal Wounds (" + String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)) + ")");
	box->addMenuItem("Poison Resistance (" + String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_POISON)) + ")");
	box->addMenuItem("Disease Resistance (" + String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_DISEASE)) + ")");
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptPriceInput(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent::ServiceType service) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid Price");
	box->setPromptText("Enter the new credit price for " + getServiceName(service) + ".");
	box->setMaxInputSize(9);
	box->setCallback(new DoctorBuffDroidPriceInputSuiCallback(player->getZoneServer(), sceneObject, service));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptDiscountInput(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid Discount");
	box->setPromptText("Enter the guild discount percent for this droid.");
	box->setMaxInputSize(3);
	box->setCallback(new DoctorBuffDroidDiscountSuiCallback(player->getZoneServer(), sceneObject));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptToggleSelection(SceneObject* sceneObject, CreatureObject* player) {
	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (player == nullptr || data == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Toggle Services");
	box->setPromptText("Select a service to toggle.");
	box->setCallback(new DoctorBuffDroidToggleSuiCallback(player->getZoneServer(), sceneObject));
	box->addMenuItem("Medical Buffs (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_BUFFS) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Heal Wounds (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_WOUNDS) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Poison Resistance (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_POISON) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Disease Resistance (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_DISEASE) ? "Enabled" : "Disabled") + ")");
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

bool DoctorBuffDroidMenuComponent::performMedicalBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	if (!data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_BUFFS)) {
		player->sendSystemMessage("This Doctor Buff Droid currently has medical buffs disabled.");
		return false;
	}

	uint32 attrMask = data->getLoadedBuffAttributes();
	if (attrMask == 0) {
		player->sendSystemMessage("This Doctor Buff Droid is out of buff supplies.");
		return false;
	}

	int price = data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS, player);
	if (!deductCredits(player, price)) {
		player->sendSystemMessage("You do not have enough credits to purchase Doctor Buff Droid buffs.");
		return false;
	}

	sendFoodWarnings(player);

	PlayerManager* playerManager = player->getZoneServer()->getPlayerManager();
	if (playerManager != nullptr) {
		ensureBivoliBuffActive(sceneObject, data);

		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod = getOwnerHealingWoundTreatment(sceneObject, data, player);

		for (uint8 attr = 0; attr < 9; ++attr) {
			if (!(attrMask & (1u << attr)))
				continue;
			if (data->getBuffStockByAttr(attr) <= 0)
				continue;

			float packPower = data->getBuffPackPowerByAttr(attr);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration = data->getBuffPackDurationByAttr(attr);
			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount = calculateDroidBuffPower(packPower, envMod, healMod);

			playerManager->healEnhance(player, player, attr, buffAmount, buffDuration, 0);
			data->consumeBuffStock(attr);
		}
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage("Doctor Buff Droid medical buffs applied.");
	return true;
}

bool DoctorBuffDroidMenuComponent::performWoundHealing(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	if (!data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)) {
		player->sendSystemMessage("This Doctor Buff Droid currently has wound healing disabled.");
		return false;
	}

	int totalWounds = 0;
	for (int i = 0; i < 9; ++i)
		totalWounds += player->getWounds(i);

	if (totalWounds <= 0) {
		player->sendSystemMessage("You do not have any wounds to heal.");
		return false;
	}

	int price = data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS, player);
	if (!deductCredits(player, price)) {
		player->sendSystemMessage("You do not have enough credits to purchase wound healing.");
		return false;
	}

	for (int i = 0; i < 9; ++i) {
		int wounds = player->getWounds(i);
		if (wounds > 0)
			player->healWound(cast<TangibleObject*>(sceneObject), i, wounds, true, true);
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healwound.cef", "");
	player->sendSystemMessage("Doctor Buff Droid wound healing complete.");
	return true;
}

bool DoctorBuffDroidMenuComponent::performResistance(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, DoctorBuffDroidDataComponent::ServiceType type) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	if (!data->isServiceEnabled(type)) {
		player->sendSystemMessage("That Doctor Buff Droid resistance service is currently disabled.");
		return false;
	}

	if (data->getStock(type) <= 0) {
		player->sendSystemMessage("That Doctor Buff Droid is out of resistance supplies.");
		return false;
	}

	int price = data->getDiscountedPrice(type, player);
	if (!deductCredits(player, price)) {
		player->sendSystemMessage("You do not have enough credits for that Doctor Buff Droid service.");
		return false;
	}

	if (!data->consumeStock(type)) {
		player->sendSystemMessage("That Doctor Buff Droid ran out of supplies.");
		return false;
	}

	PlayerManager* playerManager = player->getZoneServer()->getPlayerManager();
	if (playerManager != nullptr) {
		ensureBivoliBuffActive(sceneObject, data);

		int attribute = type == DoctorBuffDroidDataComponent::SERVICE_POISON ? BuffAttribute::POISON : BuffAttribute::DISEASE;

		// Resistance pack power falls back to 60 for droids loaded before this update
		float packPower = data->getPackPower(type);
		if (packPower <= 0.0f)
			packPower = 60.0f;

		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod = getOwnerHealingWoundTreatment(sceneObject, data, player);
		int resistAmount = calculateDroidBuffPower(packPower, envMod, healMod);

		float resistDuration = data->getPackDuration(type);
		if (resistDuration <= 0.0f)
			resistDuration = 7200.f;

		playerManager->healEnhance(player, player, attribute, resistAmount, resistDuration, 0);
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage("Doctor Buff Droid " + getServiceName(type).toLowerCase() + " applied.");
	return true;
}

void DoctorBuffDroidMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (sceneObject == nullptr || player == nullptr)
		return;

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	menuResponse->addRadialMenuItem(MENU_ROOT, 3, "Doctor Buff Droid");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_BUFFS, 3, "Get Buffs");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_WOUNDS, 3, "Heal Wounds");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_POISON, 3, "Buy Poison Resist");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_DISEASE, 3, "Buy Disease Resist");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_PRICES, 3, "View Prices");

	if (!data->isOwner(player))
		return;

	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_LOAD, 3, "Load Supplies");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_STOCK, 3, "View Stock");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_CONFIG_PRICES, 3, "Configure Prices");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_CONFIG_DISCOUNT, 3, "Configure Discounts");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_TOGGLE_SERVICES, 3, "Toggle Services");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_EARNINGS, 3, "View Earnings");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_WITHDRAW, 3, "Withdraw Earnings");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_STORE, 3, "Store Droid");
}

int DoctorBuffDroidMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (sceneObject == nullptr || player == nullptr)
		return 0;

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return 0;

	switch (selectedID) {
	case MENU_BUFFS:
		performMedicalBuff(sceneObject, player, data);
		return 0;
	case MENU_WOUNDS:
		performWoundHealing(sceneObject, player, data);
		return 0;
	case MENU_POISON:
		performResistance(sceneObject, player, data, DoctorBuffDroidDataComponent::SERVICE_POISON);
		return 0;
	case MENU_DISEASE:
		performResistance(sceneObject, player, data, DoctorBuffDroidDataComponent::SERVICE_DISEASE);
		return 0;
	case MENU_PRICES:
		sendPriceSummary(player, data);
		return 0;
	case MENU_LOAD:
		if (!data->isOwner(player) || !isMasterDoctor(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		loadSupplies(sceneObject, player, data);
		return 0;
	case MENU_STOCK:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		sendStockSummary(player, data);
		return 0;
	case MENU_CONFIG_PRICES:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		promptPriceSelection(sceneObject, player);
		return 0;
	case MENU_CONFIG_DISCOUNT:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		promptDiscountInput(sceneObject, player);
		return 0;
	case MENU_TOGGLE_SERVICES:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		promptToggleSelection(sceneObject, player);
		return 0;
	case MENU_EARNINGS:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		sendEarningsSummary(player, data);
		return 0;
	case MENU_WITHDRAW:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		} else {
			int amount = data->withdrawEarnings();
			if (amount <= 0) {
				player->sendSystemMessage("Doctor Buff Droid has no earnings to withdraw.");
			} else {
				player->addCashCredits(amount, true);
				player->sendSystemMessage("Withdrew " + String::valueOf(amount) + " credits from the Doctor Buff Droid.");
			}
		}
		return 0;
	case MENU_STORE:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		storeDroid(sceneObject, player);
		return 0;
	default:
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
	}
}
