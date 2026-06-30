#include "DoctorBuffDroidMenuComponent.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidPriceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidPriceInputSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidDiscountSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidToggleSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidAdTextSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidInventorySuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/DoctorBuffDroidWithdrawQuantitySuiCallback.h"
#include "server/zone/objects/intangible/VehicleControlDevice.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/tangible/consumable/Consumable.h"
#include "server/zone/objects/tangible/pharmaceutical/EnhancePack.h"
#include "server/zone/objects/tangible/pharmaceutical/PharmaceuticalObject.h"
#include "server/zone/objects/tangible/pharmaceutical/WoundPack.h"
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
const String kWoundTreatmentSkillMod = "healing_wound_treatment";

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
		return "Disease Resistance";
	case DoctorBuffDroidDataComponent::SERVICE_JANTA:
		return "Janta Buffs";
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

bool isJantaSupply(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	if (consumable == nullptr || consumable->getBuffCRC() == kBivoliBuffCRC)
		return false;

	String modifierName = kWoundTreatmentSkillMod;
	return consumable->hasModifier(modifierName);
}

float getMedicalPackEffectiveness(SceneObject* item) {
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
	if (pharma == nullptr)
		return 0.0f;

	if (pharma->isEnhancePack())
		return cast<EnhancePack*>(pharma)->getEffectiveness();

	if (pharma->isWoundPack())
		return cast<WoundPack*>(pharma)->getEffectiveness();

	return 0.0f;
}

// Returns true for medical packs we want to route into the separate Janta stock path.
// User requirement: treat packs with crafted power above 1000 as Janta-tier.
bool isJantaMedicalPack(SceneObject* item) {
	if (item == nullptr)
		return false;

	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate == nullptr || !crate->isValidFactoryCrate())
			return false;
		item = crate->getPrototype();
		if (item == nullptr)
			return false;
	}

	if (!item->isPharmaceuticalObject())
		return false;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
	if (pharma == nullptr)
		return false;

	if (pharma->isEnhancePack()) {
		EnhancePack* pack = cast<EnhancePack*>(pharma);
		if (pack == nullptr)
			return false;

		byte attr = pack->getAttribute();
		if (attr == BuffAttribute::POISON || attr == BuffAttribute::DISEASE)
			return false;

		return pack->getAbsorption() > 0.0f || pack->getEffectiveness() >= 1000.0f;
	}

	if (pharma->isWoundPack())
		return true;

	return false;
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

	if (isBivoliSupply(item) || isJantaSupply(item) || isJantaMedicalPack(item))
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

float getJantaStrength(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	if (consumable != nullptr)
		return consumable->getCurrentNutrition();

	float effectiveness = getMedicalPackEffectiveness(item);
	if (effectiveness < 1000.0f)
		return 0.0f;

	return 25.0f + ((effectiveness - 1000.0f) / 100.0f);
}

float getJantaDuration(SceneObject* item) {
	Consumable* consumable = getConsumable(item);
	if (consumable != nullptr)
		return consumable->getDuration();

	if (item != nullptr && item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate != nullptr && crate->isValidFactoryCrate())
			item = crate->getPrototype();
	}

	if (item != nullptr && item->isPharmaceuticalObject()) {
		PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(item);
		if (pharma != nullptr && pharma->isEnhancePack()) {
			float duration = cast<EnhancePack*>(pharma)->getDuration();
			if (duration > 0.0f)
				return duration;
		}
	}

	return 1800.0f;
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
	if (pharma == nullptr)
		return 0;

	if (pharma->isEnhancePack())
		return cast<EnhancePack*>(pharma)->getAttribute();

	if (pharma->isWoundPack())
		return cast<WoundPack*>(pharma)->getAttribute();

	return 0;
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

int getManualFoodWoundTreatmentBonus(CreatureObject* creature) {
	if (creature == nullptr)
		return 0;

	const BuffList* buffList = creature->getBuffList();
	if (buffList == nullptr)
		return 0;

	int total = 0;

	for (int i = 0; i < buffList->getBuffListSize(); ++i) {
		Buff* buff = buffList->getBuffByIndex(i);
		if (buff == nullptr || buff->getBuffType() != BuffType::FOOD)
			continue;

		total += buff->getSkillModifierValue(kWoundTreatmentSkillMod);
	}

	return total;
}

// Reads the owner's current healing_wound_treatment at buff time while replacing manual food
// buffs with the droid-managed consumable bonus selected for this service.
// buyer must already be locked by the calling context.
int getOwnerHealingWoundTreatment(SceneObject* droid, DoctorBuffDroidDataComponent* data, CreatureObject* buyer, bool useJanta = false) {
	if (data == nullptr)
		return 100;

	uint64 ownerId = data->getOwnerId();
	Time now;
	uint64 nowMs = now.getMiliTime();
	int droidFoodBonus = data->getActiveBivoliBonus(nowMs);

	// Owner is the buyer — already locked, read directly
	if (buyer != nullptr && buyer->getObjectID() == ownerId) {
		int healMod = buyer->getSkillMod(kWoundTreatmentSkillMod) - getManualFoodWoundTreatmentBonus(buyer);
		return Math::max(0, healMod) + droidFoodBonus;
	}

	// Owner is someone else — cross-lock to get their current stats
	if (droid != nullptr) {
		ZoneServer* zoneServer = droid->getZoneServer();
		if (zoneServer != nullptr) {
			ManagedReference<SceneObject*> ownerObj = zoneServer->getObject(ownerId);
			if (ownerObj != nullptr && ownerObj->isCreatureObject()) {
				CreatureObject* owner = cast<CreatureObject*>(ownerObj.get());
				Locker ownerLocker(owner, buyer);
				int healMod = owner->getSkillMod(kWoundTreatmentSkillMod) - getManualFoodWoundTreatmentBonus(owner);
				return Math::max(0, healMod) + droidFoodBonus;
			}
		}
	}

	// Owner is offline — use value cached at last supply load
	return Math::max(0, data->getOwnerHealingMod()) + droidFoodBonus;
}

// Final buff power: mirrors EnhancePack::calculatePower using droid-sourced values.
int calculateDroidBuffPower(float packPower, int environmentMod, int healingWoundTreatment) {
	if (packPower <= 0.0f || environmentMod <= 0)
		return 0;

	return Math::max(1, (int)(packPower * (environmentMod / 100.0f) * (100.0f + healingWoundTreatment) / 100.0f));
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

bool ensureJantaBuffActive(SceneObject* droid, DoctorBuffDroidDataComponent* data) {
	if (data == nullptr)
		return false;

	Time now;
	uint64 nowMs = now.getMiliTime();

	if (data->getActiveJantaBonus(nowMs) > 0)
		return true;

	float strength = 0.0f;
	float duration = 0.0f;

	if (!data->consumeJantaStock(1, strength, duration))
		return false;

	data->activateJanta(strength, duration, nowMs);
	return data->getActiveJantaBonus(nowMs) > 0;
}

void persistDroidState(SceneObject* droid) {
	if (droid != nullptr)
		droid->updateToDatabase();
}

// Remove any existing doctor-enhancement buff for this attribute from the patient.
// Called before every healEnhance from the droid so that rebuffing always replaces
// the old buff — resetting the timer and value even when the prior buff was stronger
// (e.g., from a Bivoli-boosted session that has since expired).
void removeDoctorBuff(CreatureObject* patient, uint8 attr) {
	if (patient == nullptr)
		return;
	String buffname = "medical_enhance_" + BuffAttribute::getName(attr);
	uint32 buffcrc = buffname.hashCode();
	if (patient->hasBuff(buffcrc))
		patient->removeBuff(buffcrc);
}

// Returns the _b-tier IFF template path for the given BuffAttribute.
// MIND/FOCUS/WILLPOWER have no dedicated enhance pack template; fall back to health.
const char* getEnhancePackIFF(byte attr) {
	switch (attr) {
	case BuffAttribute::HEALTH:       return "object/tangible/medicine/crafted/medpack_enhance_health_b.iff";
	case BuffAttribute::STRENGTH:     return "object/tangible/medicine/crafted/medpack_enhance_strength_b.iff";
	case BuffAttribute::CONSTITUTION: return "object/tangible/medicine/crafted/medpack_enhance_constitution_b.iff";
	case BuffAttribute::ACTION:       return "object/tangible/medicine/crafted/medpack_enhance_action_b.iff";
	case BuffAttribute::QUICKNESS:    return "object/tangible/medicine/crafted/medpack_enhance_quickness_b.iff";
	case BuffAttribute::STAMINA:      return "object/tangible/medicine/crafted/medpack_enhance_stamina_b.iff";
	case BuffAttribute::POISON:       return "object/tangible/medicine/crafted/medpack_enhance_poison_b.iff";
	case BuffAttribute::DISEASE:      return "object/tangible/medicine/crafted/medpack_enhance_disease_b.iff";
	default:                          return "object/tangible/medicine/crafted/medpack_enhance_health_b.iff";
	}
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
			<< ", Janta Buffs: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_JANTA)
			<< ", Wounds: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)
			<< ", Poison: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_POISON)
			<< ", Disease: " << data->getPrice(DoctorBuffDroidDataComponent::SERVICE_DISEASE)
			<< ". Guild Discount: " << data->getGuildDiscountPercent() << "% (your own price: " << data->getMinimumPriceFloor() << " credits).";
	} else {
		// Show what this player will actually pay
		msg << "Doctor Buff Droid prices - Buffs: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS, player)
			<< ", Janta Buffs: " << data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_JANTA, player)
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

	uint32 jantaAttrMask = data->getLoadedJantaBuffAttributes();
	if (jantaAttrMask == 0) {
		msg << " | Janta Buffs: 0 use(s)";
	} else {
		msg << " | Janta Buffs:";
		for (uint8 attr = 0; attr < 9; ++attr) {
			int stock = data->getJantaBuffStockByAttr(attr);
			if (stock > 0)
				msg << " " << BuffAttribute::getName(attr, true) << ": " << stock << " use(s)";
		}
	}

	msg << " | Poison resist: " << data->getStock(DoctorBuffDroidDataComponent::SERVICE_POISON)
		<< " use(s) | Disease resist: " << data->getStock(DoctorBuffDroidDataComponent::SERVICE_DISEASE)
		<< " use(s) | Bivoli: " << data->getBivoliStock() << " charge(s)";

	if (data->getJantaStock() > 0)
		msg << " | Legacy Janta food: " << data->getJantaStock() << " charge(s)";

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

bool DoctorBuffDroidMenuComponent::loadSupplies(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, LoadMode mode) {
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

		bool bivoliSupply = isBivoliSupply(item);
		bool jantaSupply = isJantaSupply(item);
		bool jantaPack = !bivoliSupply && !jantaSupply && isJantaMedicalPack(item);

		if (mode == LOAD_JANTA_ONLY && !jantaSupply && !jantaPack)
			continue;

		if (mode == LOAD_STANDARD && (jantaSupply || jantaPack))
			continue;

		DoctorBuffDroidDataComponent::ServiceType service = getSupplyType(item);
		int amount = getSupplyAmount(item);

		if (amount <= 0)
			continue;

		if (bivoliSupply) {
			float strength = getBivoliStrength(item);
			float duration = getBivoliDuration(item);

			if (strength <= 0.0f || duration <= 0.0f)
				continue;

			data->addBivoliStock(amount, strength, duration);
			destroyLoadedSupply(item);
			loaded += amount;
			continue;
		}

		if (jantaSupply) {
			float strength = getJantaStrength(item);
			float duration = getJantaDuration(item);

			if (strength <= 0.0f || duration <= 0.0f)
				continue;

			data->addJantaStock(amount, strength, duration);
			destroyLoadedSupply(item);
			loaded += amount;
			continue;
		}

		if (jantaPack) {
			float effectiveness = getMedicalPackEffectiveness(item);
			float duration = getJantaDuration(item);
			byte attr = getPackAttribute(item);

			if (effectiveness <= 0.0f || duration <= 0.0f || attr >= 9)
				continue;

			data->addStock(DoctorBuffDroidDataComponent::SERVICE_JANTA, amount, effectiveness, attr, duration);
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
		if (mode == LOAD_JANTA_ONLY)
			player->sendSystemMessage("No valid Janta Doctor Buff Droid supplies were found in your inventory.");
		else
			player->sendSystemMessage("No valid Doctor Buff Droid supplies were found in your inventory.");
		return false;
	}

	// Cache owner's healing skill mod so buff power calculation doesn't need an owner lock at buff time
	data->setOwnerHealingMod(player->getSkillMod(kWoundTreatmentSkillMod));
	persistDroidState(sceneObject);

	if (mode == LOAD_JANTA_ONLY)
		player->sendSystemMessage("Loaded " + String::valueOf(loaded) + " Janta supply units into the Doctor Buff Droid.");
	else
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
	box->addMenuItem("Janta Buffs (" + String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_JANTA)) + ")");
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
	box->addMenuItem("Janta Buffs (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_JANTA) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Heal Wounds (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_WOUNDS) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Poison Resistance (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_POISON) ? "Enabled" : "Disabled") + ")");
	box->addMenuItem("Disease Resistance (" + String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_DISEASE) ? "Enabled" : "Disabled") + ")");
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptAdTextInput(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid Ad Message");
	box->setPromptText("Enter the advertisement message the droid will bark to nearby players (max 200 characters). Ad barking will be enabled automatically.");
	box->setMaxInputSize(200);
	String currentText = data->getAdBarkText();
	if (!currentText.isEmpty())
		box->setDefaultInput(currentText);
	box->setCallback(new DoctorBuffDroidAdTextSuiCallback(player->getZoneServer(), sceneObject));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::openDroidInventory(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return;

	Time now;
	uint64 nowMs = now.getMiliTime();

	// Parallel vectors: one entry per selectable supply row.
	// The owner can select a row to open the withdraw-quantity dialog.
	// Service type == -1 marks an informational-only row (empty droid notice).
	Vector<int> entryServiceTypes;
	Vector<int> entryAttrs;
	Vector<int> entryMaxQtys;

	// Build prompt text with Bivoli info (not withdrawable as packs).
	StringBuffer prompt;
	prompt << "Select a supply row to withdraw packs into your inventory (owner only)."
	       << "\nSelect \"Remove My Buffs\" to clear your own active buffs.";
	int bivoliStock = data->getBivoliStock();
	if (bivoliStock > 0)
		prompt << "\nBivoli Food: " << bivoliStock << " charge(s)";
	int jantaFoodStock = data->getJantaStock();
	if (jantaFoodStock > 0)
		prompt << "\nLegacy Janta Food: " << jantaFoodStock << " charge(s)";
	int activeBivoliBonus = data->getActiveBivoliBonus(nowMs);
	if (activeBivoliBonus > 0) {
		float secsLeft = data->getActiveBivoliTimeRemaining(nowMs);
		int secsLeftCeil = (int)secsLeft;
		if ((float)secsLeftCeil < secsLeft)
			secsLeftCeil++;
		prompt << "\nActive Bivoli: +" << activeBivoliBonus << " wound treatment (" << secsLeftCeil << "s remaining)";
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid - Current Inventory");
	box->setPromptText(prompt.toString());

	for (uint8 attr = 0; attr < 9; ++attr) {
		int stock = data->getBuffStockByAttr(attr);
		if (stock <= 0)
			continue;
		box->addMenuItem("Medical Buff [" + BuffAttribute::getName(attr, true) + "]: " + String::valueOf(stock) + " use(s)");
		entryServiceTypes.add((int)DoctorBuffDroidDataComponent::SERVICE_BUFFS);
		entryAttrs.add((int)attr);
		entryMaxQtys.add(stock);
	}

	for (uint8 attr = 0; attr < 9; ++attr) {
		int stock = data->getJantaBuffStockByAttr(attr);
		if (stock <= 0)
			continue;
		box->addMenuItem("Janta Buff [" + BuffAttribute::getName(attr, true) + "]: " + String::valueOf(stock) + " use(s)");
		entryServiceTypes.add((int)DoctorBuffDroidDataComponent::SERVICE_JANTA);
		entryAttrs.add((int)attr);
		entryMaxQtys.add(stock);
	}

	int poisonStock = data->getStock(DoctorBuffDroidDataComponent::SERVICE_POISON);
	if (poisonStock > 0) {
		box->addMenuItem("Poison Resistance: " + String::valueOf(poisonStock) + " use(s)");
		entryServiceTypes.add((int)DoctorBuffDroidDataComponent::SERVICE_POISON);
		entryAttrs.add((int)BuffAttribute::POISON);
		entryMaxQtys.add(poisonStock);
	}

	int diseaseStock = data->getStock(DoctorBuffDroidDataComponent::SERVICE_DISEASE);
	if (diseaseStock > 0) {
		box->addMenuItem("Disease Resistance: " + String::valueOf(diseaseStock) + " use(s)");
		entryServiceTypes.add((int)DoctorBuffDroidDataComponent::SERVICE_DISEASE);
		entryAttrs.add((int)BuffAttribute::DISEASE);
		entryMaxQtys.add(diseaseStock);
	}

	if (entryServiceTypes.size() == 0) {
		box->addMenuItem("No withdrawable supplies are currently loaded.");
		entryServiceTypes.add(-1);
		entryAttrs.add(-1);
		entryMaxQtys.add(0);
	}

	int removeBuffsIndex = entryServiceTypes.size();
	box->addMenuItem("--- Remove My Active Doctor Buffs ---");

	box->setCallback(new DoctorBuffDroidInventorySuiCallback(player->getZoneServer(), sceneObject,
		entryServiceTypes, entryAttrs, entryMaxQtys, removeBuffsIndex));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptWithdrawQuantity(SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent::ServiceType service, byte attr, int maxQty) {
	if (sceneObject == nullptr || player == nullptr || maxQty <= 0)
		return;

	String label;
	if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS)
		label = "Medical Buff [" + BuffAttribute::getName(attr, true) + "]";
	else if (service == DoctorBuffDroidDataComponent::SERVICE_JANTA)
		label = "Janta Buff [" + BuffAttribute::getName(attr, true) + "]";
	else if (service == DoctorBuffDroidDataComponent::SERVICE_POISON)
		label = "Poison Resistance";
	else if (service == DoctorBuffDroidDataComponent::SERVICE_DISEASE)
		label = "Disease Resistance";
	else
		label = "Supply";

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Withdraw Supplies");
	box->setPromptText("Enter the number of [" + label + "] packs to withdraw (max " + String::valueOf(maxQty) + ").\nPacks are created in stacks of up to 28.");
	box->setMaxInputSize(6);
	box->setCallback(new DoctorBuffDroidWithdrawQuantitySuiCallback(player->getZoneServer(), sceneObject, service, attr, maxQty));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::withdrawBuffStock(SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent* data, DoctorBuffDroidDataComponent::ServiceType service,
	byte attr, int quantity) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr || quantity <= 0)
		return;

	ZoneServer* zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return;

	SceneObject* inventory = player->getSlottedObject("inventory");
	if (inventory == nullptr)
		return;

	// Resolve pack power/duration and clamp quantity to available stock.
	float packPower = 0.0f;
	float packDuration = 0.0f;
	byte packAttr = attr;

	if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS) {
		int stock = data->getBuffStockByAttr(attr);
		if (stock <= 0) {
			player->sendSystemMessage("No supplies of that type are loaded in the droid.");
			return;
		}
		if (quantity > stock)
			quantity = stock;
		packPower = data->getBuffPackPowerByAttr(attr);
		packDuration = data->getBuffPackDurationByAttr(attr);

	} else if (service == DoctorBuffDroidDataComponent::SERVICE_JANTA) {
		int stock = data->getJantaBuffStockByAttr(attr);
		if (stock <= 0) {
			player->sendSystemMessage("No supplies of that type are loaded in the droid.");
			return;
		}
		if (quantity > stock)
			quantity = stock;
		packPower = data->getJantaBuffPackPowerByAttr(attr);
		packDuration = data->getJantaBuffPackDurationByAttr(attr);

	} else if (service == DoctorBuffDroidDataComponent::SERVICE_POISON) {
		int stock = data->getStock(DoctorBuffDroidDataComponent::SERVICE_POISON);
		if (stock <= 0) {
			player->sendSystemMessage("No supplies of that type are loaded in the droid.");
			return;
		}
		if (quantity > stock)
			quantity = stock;
		packPower = data->getPackPower(DoctorBuffDroidDataComponent::SERVICE_POISON);
		packDuration = data->getPackDuration(DoctorBuffDroidDataComponent::SERVICE_POISON);
		packAttr = (byte)BuffAttribute::POISON;

	} else if (service == DoctorBuffDroidDataComponent::SERVICE_DISEASE) {
		int stock = data->getStock(DoctorBuffDroidDataComponent::SERVICE_DISEASE);
		if (stock <= 0) {
			player->sendSystemMessage("No supplies of that type are loaded in the droid.");
			return;
		}
		if (quantity > stock)
			quantity = stock;
		packPower = data->getPackPower(DoctorBuffDroidDataComponent::SERVICE_DISEASE);
		packDuration = data->getPackDuration(DoctorBuffDroidDataComponent::SERVICE_DISEASE);
		packAttr = (byte)BuffAttribute::DISEASE;

	} else {
		return;
	}

	if (packPower <= 0.0f)
		packPower = 500.0f;
	if (packDuration <= 0.0f)
		packDuration = 7200.0f;

	// Create one EnhancePack prototype — each factory crate will clone it.
	// useCount=1 on the prototype means each extracted pack is a single-use item,
	// matching how player-crafted pharmaceutical packs work.
	uint32 templateCRC = String(getEnhancePackIFF(packAttr)).hashCode();
	ManagedReference<SceneObject*> protoObj = zoneServer->createObject(templateCRC, 1);

	if (protoObj == nullptr || !protoObj->isPharmaceuticalObject()
		|| !cast<PharmaceuticalObject*>(protoObj.get())->isEnhancePack()) {
		if (protoObj != nullptr)
			protoObj->destroyObjectFromDatabase(true);
		player->sendSystemMessage("Failed to create supply crates. Please try again.");
		return;
	}

	EnhancePack* proto = cast<EnhancePack*>(protoObj.get());

	{
		Locker protoLocker(proto, player);

		EnhancePackImplementation* impl = dynamic_cast<EnhancePackImplementation*>(proto->_getImplementation());
		if (impl == nullptr) {
			proto->destroyObjectFromDatabase(true);
			player->sendSystemMessage("Failed to create supply crates. Please try again.");
			return;
		}

		impl->setPackValues(packPower, packDuration, packAttr);
		proto->setUseCount(1, false);

		// Create factory crates in batches of up to 500 (standard max factory output size).
		// createFactoryCrate clones the prototype into each crate — the original is unused
		// after this loop and must be destroyed.
		static const int MAX_CRATE_SIZE = 500;
		int remaining = quantity;
		int totalCreated = 0;

		while (remaining > 0) {
			int crateQty = Math::min(remaining, MAX_CRATE_SIZE);
			String emptyType = "";

			Reference<FactoryCrate*> crate = proto->createFactoryCrate(crateQty, emptyType, false);
			if (crate == nullptr)
				break;

			{
				Locker crateLocker(crate, player);
				crate->setUseCount((uint32)crateQty, false);
			}

			if (!inventory->transferObject(crate, -1, true)) {
				crate->destroyObjectFromDatabase(true);
				break;
			}

			inventory->broadcastObject(crate, true);
			remaining -= crateQty;
			totalCreated += crateQty;
		}

		// Prototype was cloned into each crate — the original is no longer needed.
		proto->destroyObjectFromDatabase(true);

		if (totalCreated <= 0) {
			player->sendSystemMessage("Failed to create supply crates. Your inventory may be full.");
			return;
		}

		// Deduct the amount actually created from the droid's stock.
		if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS)
			data->consumeBuffStock(attr, totalCreated);
		else if (service == DoctorBuffDroidDataComponent::SERVICE_JANTA)
			data->consumeJantaBuffStock(attr, totalCreated);
		else
			data->consumeStock(service, totalCreated);

		persistDroidState(sceneObject);
		player->sendSystemMessage("Withdrew " + String::valueOf(totalCreated) + " supply pack(s) into your inventory as factory crate(s).");
	}
}

bool DoctorBuffDroidMenuComponent::performMedicalBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, bool useJanta) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	DoctorBuffDroidDataComponent::ServiceType service = useJanta ? DoctorBuffDroidDataComponent::SERVICE_JANTA : DoctorBuffDroidDataComponent::SERVICE_BUFFS;
	const char* serviceLabel = useJanta ? "Janta buffs" : "medical buffs";

	if (!data->isServiceEnabled(service)) {
		player->sendSystemMessage("This Doctor Buff Droid currently has that buff service disabled.");
		return false;
	}

	uint32 attrMask = useJanta ? data->getLoadedJantaBuffAttributes() : data->getLoadedBuffAttributes();
	if (attrMask == 0) {
		if (useJanta)
			player->sendSystemMessage("This Doctor Buff Droid is out of Janta buff pack supplies.");
		else
			player->sendSystemMessage("This Doctor Buff Droid is out of buff pack supplies.");
		return false;
	}

	Time now;
	uint64 nowMs = now.getMiliTime();

	if (!ensureBivoliBuffActive(sceneObject, data)) {
		player->sendSystemMessage("This Doctor Buff Droid is out of Bivoli supplies.");
		return false;
	}

	int price = data->getDiscountedPrice(service, player);
	if (!deductCredits(player, price)) {
		player->sendSystemMessage("You do not have enough credits to purchase Doctor Buff Droid buffs.");
		return false;
	}

	PlayerManager* playerManager = player->getZoneServer()->getPlayerManager();
	if (playerManager != nullptr) {
		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod = getOwnerHealingWoundTreatment(sceneObject, data, player, useJanta);

		for (uint8 attr = 0; attr < 9; ++attr) {
			if (!(attrMask & (1u << attr)))
				continue;
			int stock = useJanta ? data->getJantaBuffStockByAttr(attr) : data->getBuffStockByAttr(attr);
			if (stock <= 0)
				continue;

			float packPower = useJanta ? data->getJantaBuffPackPowerByAttr(attr) : data->getBuffPackPowerByAttr(attr);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration = useJanta ? data->getJantaBuffPackDurationByAttr(attr) : data->getBuffPackDurationByAttr(attr);
			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount = calculateDroidBuffPower(packPower, envMod, healMod);

			// Remove any existing doctor buff for this attribute first so the new buff
			// always replaces it — even if the previous one was higher — ensuring the
			// player gets fresh values and a full duration from the current droid session.
			removeDoctorBuff(player, attr);
			playerManager->healEnhance(player, player, attr, buffAmount, buffDuration, 0);
			if (useJanta)
				data->consumeJantaBuffStock(attr);
			else
				data->consumeBuffStock(attr);
		}
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage("Doctor Buff Droid " + String(serviceLabel) + " applied.");
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

		// Remove any existing resistance buff of this type first so rebuffing from the
		// droid always overwrites it with the current values and a full fresh duration.
		removeDoctorBuff(player, (uint8)attribute);
		playerManager->healEnhance(player, player, attribute, resistAmount, resistDuration, 0);
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage("Doctor Buff Droid " + getServiceName(type).toLowerCase() + " applied.");
	return true;
}

bool DoctorBuffDroidMenuComponent::performPetBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, bool useJanta) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	DoctorBuffDroidDataComponent::ServiceType service = useJanta ? DoctorBuffDroidDataComponent::SERVICE_JANTA : DoctorBuffDroidDataComponent::SERVICE_BUFFS;
	const char* serviceLabel = useJanta ? "Janta buffs" : "medical buffs";

	if (!data->isServiceEnabled(service)) {
		player->sendSystemMessage("This Doctor Buff Droid currently has that buff service disabled.");
		return false;
	}

	uint32 attrMask = useJanta ? data->getLoadedJantaBuffAttributes() : data->getLoadedBuffAttributes();
	if (attrMask == 0) {
		if (useJanta)
			player->sendSystemMessage("This Doctor Buff Droid is out of Janta buff pack supplies.");
		else
			player->sendSystemMessage("This Doctor Buff Droid is out of buff pack supplies.");
		return false;
	}

	// Find the player's first active, living, non-combat pet
	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();
	if (ghost == nullptr) {
		player->sendSystemMessage("You do not have an active pet to buff.");
		return false;
	}

	AiAgent* activePet = nullptr;
	for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
		ManagedReference<AiAgent*> pet = ghost->getActivePet(i);
		if (pet != nullptr && !pet->isDead()) {
			activePet = pet.get();
			break;
		}
	}

	if (activePet == nullptr) {
		player->sendSystemMessage("You do not have an active pet to buff.");
		return false;
	}

	if (activePet->isInCombat()) {
		player->sendSystemMessage("Your pet is in combat and cannot be buffed right now.");
		return false;
	}

	Time now;
	uint64 nowMs = now.getMiliTime();

	if (!ensureBivoliBuffActive(sceneObject, data)) {
		player->sendSystemMessage("This Doctor Buff Droid is out of Bivoli supplies.");
		return false;
	}

	int price = data->getDiscountedPrice(service, player);
	if (!deductCredits(player, price)) {
		player->sendSystemMessage("You do not have enough credits to purchase Doctor Buff Droid pet buffs.");
		return false;
	}

	PlayerManager* playerManager = player->getZoneServer()->getPlayerManager();
	if (playerManager != nullptr) {
		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod = getOwnerHealingWoundTreatment(sceneObject, data, player, useJanta);

		for (uint8 attr = 0; attr < 9; ++attr) {
			if (!(attrMask & (1u << attr)))
				continue;
			int stock = useJanta ? data->getJantaBuffStockByAttr(attr) : data->getBuffStockByAttr(attr);
			if (stock <= 0)
				continue;

			float packPower = useJanta ? data->getJantaBuffPackPowerByAttr(attr) : data->getBuffPackPowerByAttr(attr);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration = useJanta ? data->getJantaBuffPackDurationByAttr(attr) : data->getBuffPackDurationByAttr(attr);
			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount = calculateDroidBuffPower(packPower, envMod, healMod);

			// Remove any existing doctor buff for this attribute from the pet first so
			// rebuffing always replaces it — even if the pet's current buff was stronger.
			removeDoctorBuff(activePet, attr);
			playerManager->healEnhance(player, activePet, attr, buffAmount, buffDuration, 0);
			if (useJanta)
				data->consumeJantaBuffStock(attr);
			else
				data->consumeBuffStock(attr);
		}
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	activePet->playEffect("clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage("Doctor Buff Droid " + String(serviceLabel) + " applied to your pet.");
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
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_JANTA_BUFFS, 3, "Get Janta Buffs");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_PET_BUFFS, 3, "Buff My Pet");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_PET_JANTA_BUFFS, 3, "Buff My Pet (Janta)");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_WOUNDS, 3, "Heal Wounds");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_POISON, 3, "Buy Poison Resist");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_DISEASE, 3, "Buy Disease Resist");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_PRICES, 3, "View Prices");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_VIEW_INVENTORY, 3, "View Inventory");

	if (!data->isOwner(player))
		return;

	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_LOAD, 3, "Load Supplies");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_LOAD_JANTA, 3, "Load Janta Supplies");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_STOCK, 3, "View Stock");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_CONFIG_PRICES, 3, "Configure Prices");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_CONFIG_DISCOUNT, 3, "Configure Discounts");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_TOGGLE_SERVICES, 3, "Toggle Services");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_EARNINGS, 3, "View Earnings");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_WITHDRAW, 3, "Withdraw Earnings");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_SET_AD, 3, "Set Ad Message");
	menuResponse->addRadialMenuItemToRadialID(MENU_ROOT, MENU_TOGGLE_AD, 3, String("Ad Barking (") + (data->isAdBarkEnabled() ? "On" : "Off") + ")");
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
	case MENU_JANTA_BUFFS:
		performMedicalBuff(sceneObject, player, data, true);
		return 0;
	case MENU_PET_BUFFS:
		performPetBuff(sceneObject, player, data);
		return 0;
	case MENU_PET_JANTA_BUFFS:
		performPetBuff(sceneObject, player, data, true);
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
	case MENU_VIEW_INVENTORY:
		// Public option: open the droid's container window and show a SUI stock summary.
		// Non-owners can view but cannot remove items — the container permission system
		// prevents unauthorised transfers out of the droid.
		openDroidInventory(sceneObject, player, data);
		return 0;
	case MENU_LOAD:
		if (!data->isOwner(player) || !isMasterDoctor(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		loadSupplies(sceneObject, player, data);
		return 0;
	case MENU_LOAD_JANTA:
		if (!data->isOwner(player) || !isMasterDoctor(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		loadSupplies(sceneObject, player, data, LOAD_JANTA_ONLY);
		return 0;
	case MENU_STOCK:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		openDroidInventory(sceneObject, player, data);
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
	case MENU_SET_AD:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		}
		promptAdTextInput(sceneObject, player);
		return 0;
	case MENU_TOGGLE_AD:
		if (!data->isOwner(player)) {
			sendOwnerOnlyMessage(player);
			return 0;
		} else {
			bool nowEnabled = !data->isAdBarkEnabled();
			data->setAdBarkEnabled(nowEnabled);
			persistDroidState(sceneObject);
			player->sendSystemMessage(String("Doctor Buff Droid ad barking ") + (nowEnabled ? "enabled." : "disabled."));
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
