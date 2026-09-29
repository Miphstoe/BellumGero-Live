#include "DoctorBuffDroidMenuComponent.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/guild/GuildObject.h"
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

// Bellum Gero FMDoctorBot: exact template identity, never name-based detection.
const uint32 kDoctorServiceUnitCRC =
	String("object/tangible/vendor/doctor_service_unit.iff").hashCode();
const uint32 kDoctorServiceHopperCRC =
	String("object/tangible/hopper/doctor_service_supply_hopper.iff").hashCode();

const byte kDoctorServiceRequiredAttrs[6] = {
	BuffAttribute::HEALTH,
	BuffAttribute::ACTION,
	BuffAttribute::STRENGTH,
	BuffAttribute::CONSTITUTION,
	BuffAttribute::QUICKNESS,
	BuffAttribute::STAMINA
};

bool isDoctorServiceUnitObject(SceneObject* object) {
	return object != nullptr && object->getServerObjectCRC() == kDoctorServiceUnitCRC;
}

SceneObject* resolveMedicalSupplyContainer(SceneObject* serviceObject) {
	if (serviceObject == nullptr)
		return nullptr;

	// Legacy camp-only Doctor Buff Droid keeps its existing direct-container behavior.
	if (!isDoctorServiceUnitObject(serviceObject))
		return serviceObject;

	// Station is fail-closed: no hopper means no supplies/service. Never create, move,
	// or repair a child from a purchase path.
	for (int i = 0; i < serviceObject->getContainerObjectsSize(); ++i) {
		SceneObject* child = serviceObject->getContainerObject(i);
		if (child != nullptr && child->getServerObjectCRC() == kDoctorServiceHopperCRC &&
				child->getParentID() == serviceObject->getObjectID())
			return child;
	}

	return nullptr;
}

// Defined later with the existing real-item stock helpers.
void consumeLoadedAmount(SceneObject* item, int amount);

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

	// FMDoctorBot safety rule: the stationary unattended service never resolves or
	// cross-locks the Doctor character during a customer purchase. Its base healing
	// stat is explicitly refreshed/cached by the owner; station-managed Bivoli is added.
	if (isDoctorServiceUnitObject(droid))
		return Math::max(0, data->getOwnerHealingMod()) + droidFoodBonus;

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

	if (isDoctorServiceUnitObject(droid)) {
		SceneObject* hopper = resolveMedicalSupplyContainer(droid);
		if (hopper == nullptr)
			return false;

		SceneObject* bivoliItem = nullptr;

		// Prefer a loose/partially-used Bivoli stack before opening another
		// factory crate item.
		for (int i = 0; i < hopper->getContainerObjectsSize(); ++i) {
			SceneObject* candidate = hopper->getContainerObject(i);
			if (candidate != nullptr && !candidate->isFactoryCrate() &&
					isBivoliSupply(candidate) &&
					getBivoliStrength(candidate) > 0.0f &&
					getBivoliDuration(candidate) > 0.0f) {
				bivoliItem = candidate;
				break;
			}
		}

		if (bivoliItem == nullptr) {
			for (int i = 0; i < hopper->getContainerObjectsSize(); ++i) {
				SceneObject* candidate = hopper->getContainerObject(i);
				if (candidate != nullptr && candidate->isFactoryCrate() &&
						isBivoliSupply(candidate) &&
						getBivoliStrength(candidate) > 0.0f &&
						getBivoliDuration(candidate) > 0.0f) {
					bivoliItem = candidate;
					break;
				}
			}
		}

		if (bivoliItem == nullptr)
			return false;

		strength = getBivoliStrength(bivoliItem);
		duration = getBivoliDuration(bivoliItem);
		if (strength <= 0.0f || duration <= 0.0f)
			return false;

		// Real physical supply remains authoritative until the moment it is consumed.
		consumeLoadedAmount(bivoliItem, 1);
	} else {
		// Legacy camp-only Doctor Buff Droid behavior is preserved unchanged.
		if (!data->consumeBivoliStock(1, strength, duration))
			return false;
	}

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

// Real loaded packs now sit as actual items inside the droid's own container instead of being
// destroyed and folded into an averaged scalar stat, so different-strength packs for the same
// attribute stay distinct instead of blending. These helpers classify/query those real items.
// Bivoli supplies and legacy Janta food never enter the container — they remain scalar (unchanged).
//
// Classifies a real item already sitting in the droid's container into the (service, attr) pool
// it belongs to. attr is only meaningful for BUFFS/JANTA — POISON/DISEASE are single pools and
// report attr = 0.
bool classifyLoadedItem(SceneObject* item, DoctorBuffDroidDataComponent::ServiceType& outService, byte& outAttr) {
	if (item == nullptr)
		return false;

	if (isBivoliSupply(item) || isJantaSupply(item))
		return false;

	if (isJantaMedicalPack(item)) {
		byte attr = getPackAttribute(item);
		if (attr >= 9)
			return false;
		outService = DoctorBuffDroidDataComponent::SERVICE_JANTA;
		outAttr = attr;
		return true;
	}

	if (!isValidSupply(item))
		return false;

	DoctorBuffDroidDataComponent::ServiceType service = getSupplyType(item);

	if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS) {
		byte attr = getPackAttribute(item);
		if (attr >= 9)
			return false;
		outService = service;
		outAttr = attr;
		return true;
	}

	if (service == DoctorBuffDroidDataComponent::SERVICE_POISON || service == DoctorBuffDroidDataComponent::SERVICE_DISEASE) {
		outService = service;
		outAttr = 0;
		return true;
	}

	return false;
}

bool matchesLoadedSupply(SceneObject* item, DoctorBuffDroidDataComponent::ServiceType service, byte attr) {
	DoctorBuffDroidDataComponent::ServiceType itemService;
	byte itemAttr;
	if (!classifyLoadedItem(item, itemService, itemAttr))
		return false;

	if (itemService != service)
		return false;

	if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS || service == DoctorBuffDroidDataComponent::SERVICE_JANTA)
		return itemAttr == attr;

	// POISON/DISEASE are single pools — attr isn't a discriminator for them.
	return true;
}

// FIFO by container order (transferObject appends), so the oldest-loaded pack is consumed/found first.
SceneObject* findLoadedItem(SceneObject* droid, DoctorBuffDroidDataComponent::ServiceType service, byte attr) {
	SceneObject* supplyContainer = resolveMedicalSupplyContainer(droid);
	if (supplyContainer == nullptr)
		return nullptr;

	// FMDoctorBot Phase 1.1: a factory crate containing a multi-charge crafted
	// medpack is not itself one charge. Once one item is extracted from the crate
	// and partially consumed, always finish that loose item before opening another
	// factory-produced item. Legacy Doctor Buff Droid ordering is unchanged.
	if (isDoctorServiceUnitObject(droid)) {
		for (int i = 0; i < supplyContainer->getContainerObjectsSize(); ++i) {
			SceneObject* item = supplyContainer->getContainerObject(i);
			if (item != nullptr && !item->isFactoryCrate() &&
					matchesLoadedSupply(item, service, attr))
				return item;
		}

		for (int i = 0; i < supplyContainer->getContainerObjectsSize(); ++i) {
			SceneObject* item = supplyContainer->getContainerObject(i);
			if (item != nullptr && item->isFactoryCrate() &&
					matchesLoadedSupply(item, service, attr))
				return item;
		}

		return nullptr;
	}

	for (int i = 0; i < supplyContainer->getContainerObjectsSize(); ++i) {
		SceneObject* item = supplyContainer->getContainerObject(i);
		if (matchesLoadedSupply(item, service, attr))
			return item;
	}

	return nullptr;
}

int sumLoadedAmount(SceneObject* droid, DoctorBuffDroidDataComponent::ServiceType service, byte attr) {
	SceneObject* supplyContainer = resolveMedicalSupplyContainer(droid);
	if (supplyContainer == nullptr)
		return 0;

	int total = 0;
	for (int i = 0; i < supplyContainer->getContainerObjectsSize(); ++i) {
		SceneObject* item = supplyContainer->getContainerObject(i);
		if (matchesLoadedSupply(item, service, attr))
			total += getSupplyAmount(item);
	}

	return total;
}

uint32 loadedAttributeMask(SceneObject* droid, DoctorBuffDroidDataComponent::ServiceType service) {
	uint32 mask = 0;
	for (uint8 attr = 0; attr < 9; ++attr) {
		if (sumLoadedAmount(droid, service, attr) > 0)
			mask |= (1u << attr);
	}
	return mask;
}

// Consumes `amount` charges from a real loaded item.
//
// FMDoctorBot Phase 1.1 charge-aware station consumption:
// - A loose crafted medpack/Bivoli object uses TangibleObject::useCount as its
//   real remaining charge count, so one service decrements one charge.
// - A factory crate's useCount is the number of manufactured ITEMS, while the
//   prototype may itself contain many charges. For the stationary service we
//   extract a real crafted item from the crate, then consume only the requested
//   charge(s) from that extracted item.
// - Legacy Doctor Buff Droid semantics remain unchanged outside the station hopper.
void consumeLoadedAmount(SceneObject* item, int amount) {
	if (item == nullptr || amount <= 0)
		return;

	bool doctorServiceSupply = false;
	ManagedReference<SceneObject*> supplyParent = item->getParent().get();

	if (supplyParent != nullptr &&
			supplyParent->getServerObjectCRC() == kDoctorServiceHopperCRC) {
		ManagedReference<SceneObject*> serviceParent = supplyParent->getParent().get();
		doctorServiceSupply = isDoctorServiceUnitObject(serviceParent);
	}

	if (doctorServiceSupply) {
		if (item->isFactoryCrate()) {
			FactoryCrate* crate = cast<FactoryCrate*>(item);
			if (crate == nullptr || !crate->isValidFactoryCrate())
				return;

			int remaining = amount;
			int factoryItemsAvailable = crate->getUseCount();

			// Work from a snapshot of the original crate item count so we never
			// dereference the crate after its final extraction destroys it.
			for (int i = 0; i < factoryItemsAvailable && remaining > 0; ++i) {
				Reference<TangibleObject*> extracted = crate->extractObject();
				if (extracted == nullptr)
					break;

				uint32 extractedCharges = extracted->getUseCount();
				if (extractedCharges < 1)
					extractedCharges = 1;

				int consumeNow = Math::min(remaining, (int)extractedCharges);
				consumeLoadedAmount(extracted.get(), consumeNow);
				remaining -= consumeNow;
			}

			return;
		}

		if (item->isTangibleObject()) {
			TangibleObject* tangible = cast<TangibleObject*>(item);
			if (tangible == nullptr)
				return;

			Locker itemLocker(tangible, supplyParent.get());

			uint32 currentCharges = tangible->getUseCount();

			if (currentCharges > (uint32)amount) {
				tangible->setUseCount(currentCharges - (uint32)amount, true);
				return;
			}

			destroyLoadedSupply(item);
			return;
		}

		return;
	}

	// Existing legacy Doctor Buff Droid behavior.
	if (item->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(item);
		if (crate != nullptr) {
			int newCount = crate->getUseCount() - amount;
			crate->setUseCount(newCount > 0 ? (uint32)newCount : 0, true);
			return;
		}
	}

	destroyLoadedSupply(item);
}

// Manufactures `quantity` charges (as one or more FactoryCrates, batched at 500) of an EnhancePack
// with the given real power/duration/attr and transfers them into `destination`. Used both for
// withdrawing a specific loaded item back to the owner's inventory, and for one-time migration of
// legacy averaged stock into a real item inside the droid's own container. `lockContext` is the
// already-locked CreatureObject used for lock ordering (the player driving the current action).
// Returns the number of charges actually created/transferred.
int createSupplyCrates(ZoneServer* zoneServer, byte attr, float power, float duration, int quantity,
	SceneObject* destination, CreatureObject* lockContext) {

	if (zoneServer == nullptr || destination == nullptr || lockContext == nullptr || quantity <= 0)
		return 0;

	if (power <= 0.0f)
		power = 500.0f;
	if (duration <= 0.0f)
		duration = 7200.0f;

	uint32 templateCRC = String(getEnhancePackIFF(attr)).hashCode();
	ManagedReference<SceneObject*> protoObj = zoneServer->createObject(templateCRC, 1);

	if (protoObj == nullptr || !protoObj->isPharmaceuticalObject()
		|| !cast<PharmaceuticalObject*>(protoObj.get())->isEnhancePack()) {
		if (protoObj != nullptr)
			protoObj->destroyObjectFromDatabase(true);
		return 0;
	}

	EnhancePack* proto = cast<EnhancePack*>(protoObj.get());
	int totalCreated = 0;

	Locker protoLocker(proto, lockContext);

	EnhancePackImplementation* impl = dynamic_cast<EnhancePackImplementation*>(proto->_getImplementation());
	if (impl == nullptr) {
		proto->destroyObjectFromDatabase(true);
		return 0;
	}

	impl->setPackValues(power, duration, attr);
	proto->setUseCount(1, false);

	static const int MAX_CRATE_SIZE = 500;
	int remaining = quantity;

	while (remaining > 0) {
		int crateQty = Math::min(remaining, MAX_CRATE_SIZE);
		String emptyType = "";

		Reference<FactoryCrate*> crate = proto->createFactoryCrate(crateQty, emptyType, false);
		if (crate == nullptr)
			break;

		{
			Locker crateLocker(crate, lockContext);
			crate->setUseCount((uint32)crateQty, false);
		}

		if (!destination->transferObject(crate, -1, true)) {
			crate->destroyObjectFromDatabase(true);
			break;
		}

		destination->broadcastObject(crate, true);
		remaining -= crateQty;
		totalCreated += crateQty;
	}

	proto->destroyObjectFromDatabase(true);

	return totalCreated;
}
}

bool DoctorBuffDroidMenuComponent::isDoctorServiceUnit(SceneObject* sceneObject) {
	return isDoctorServiceUnitObject(sceneObject);
}

SceneObject* DoctorBuffDroidMenuComponent::getSupplyContainer(SceneObject* sceneObject) {
	return resolveMedicalSupplyContainer(sceneObject);
}

bool DoctorBuffDroidMenuComponent::isDoctorServiceSupply(SceneObject* item) {
	if (item == nullptr)
		return false;

	// API name is retained for compatibility with the Phase 1 hopper component.
	// Phase 3 accepts Bivoli, Standard/Janta six-attribute Doctor Enhance Packs,
	// and Poison/Disease Resistance Enhance Packs. Wound packs remain rejected.
	if (isBivoliSupply(item))
		return true;

	SceneObject* candidate = item;

	if (candidate->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(candidate);
		if (crate == nullptr || !crate->isValidFactoryCrate() || crate->getUseCount() <= 0)
			return false;

		candidate = crate->getPrototype();
		if (candidate == nullptr)
			return false;
	}

	if (!candidate->isPharmaceuticalObject())
		return false;

	PharmaceuticalObject* pharma = cast<PharmaceuticalObject*>(candidate);
	if (pharma == nullptr || !pharma->isEnhancePack())
		return false;

	byte attr = cast<EnhancePack*>(pharma)->getAttribute();

	return attr == BuffAttribute::HEALTH ||
		attr == BuffAttribute::ACTION ||
		attr == BuffAttribute::STRENGTH ||
		attr == BuffAttribute::CONSTITUTION ||
		attr == BuffAttribute::QUICKNESS ||
		attr == BuffAttribute::STAMINA ||
		attr == BuffAttribute::POISON ||
		attr == BuffAttribute::DISEASE;
}

bool DoctorBuffDroidMenuComponent::refreshOwnerHealingMod(
	SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {

	if (sceneObject == nullptr || player == nullptr || data == nullptr ||
			!data->isOwner(player) || !isMasterDoctor(player))
		return false;

	// Cache only the Doctor's base skill contribution. Food is station-managed separately,
	// so logging out, changing food buffs, or another player purchasing never requires an
	// owner-character lock.
	int baseHealing = player->getSkillMod(kWoundTreatmentSkillMod) -
		getManualFoodWoundTreatmentBonus(player);

	data->setOwnerHealingMod(Math::max(0, baseHealing));

	// Cache guild affiliation at the same owner-controlled refresh point so guild discounts
	// continue to work while the Doctor is offline.
	GuildObject* ownerGuild = player->getGuildObject().get();
	data->setOwnerGuildId(ownerGuild != nullptr ? ownerGuild->getObjectID() : 0);

	sceneObject->updateToDatabase();
	return true;
}

int DoctorBuffDroidMenuComponent::getDoctorServiceSupplyAmount(
	SceneObject* sceneObject, DoctorBuffDroidDataComponent::ServiceType service, byte attr) {

	if (!isDoctorServiceUnitObject(sceneObject))
		return 0;

	return sumLoadedAmount(sceneObject, service, attr);
}

int DoctorBuffDroidMenuComponent::getDoctorServiceCompleteSessions(
	SceneObject* sceneObject, DoctorBuffDroidDataComponent::ServiceType service) {

	if (!isDoctorServiceUnitObject(sceneObject) ||
			(service != DoctorBuffDroidDataComponent::SERVICE_BUFFS &&
			 service != DoctorBuffDroidDataComponent::SERVICE_JANTA))
		return 0;

	int completeSessions = std::numeric_limits<int>::max();

	for (int i = 0; i < 6; ++i) {
		int stock = sumLoadedAmount(sceneObject, service, kDoctorServiceRequiredAttrs[i]);
		completeSessions = Math::min(completeSessions, stock);
	}

	if (completeSessions == std::numeric_limits<int>::max())
		return 0;

	return Math::max(0, completeSessions);
}

String DoctorBuffDroidMenuComponent::getDoctorServiceMissingAttributes(
	SceneObject* sceneObject, DoctorBuffDroidDataComponent::ServiceType service) {

	if (!isDoctorServiceUnitObject(sceneObject) ||
			(service != DoctorBuffDroidDataComponent::SERVICE_BUFFS &&
			 service != DoctorBuffDroidDataComponent::SERVICE_JANTA))
		return "Unsupported service";

	StringBuffer missing;
	bool first = true;

	for (int i = 0; i < 6; ++i) {
		byte attr = kDoctorServiceRequiredAttrs[i];

		if (sumLoadedAmount(sceneObject, service, attr) > 0)
			continue;

		if (!first)
			missing << ", ";

		missing << BuffAttribute::getName(attr, true);
		first = false;
	}

	if (first)
		return "None";

	return missing.toString();
}

int DoctorBuffDroidMenuComponent::getDoctorServiceBivoliReserve(SceneObject* sceneObject) {
	if (!isDoctorServiceUnitObject(sceneObject))
		return 0;

	SceneObject* hopper = resolveMedicalSupplyContainer(sceneObject);
	if (hopper == nullptr)
		return 0;

	int total = 0;

	for (int i = 0; i < hopper->getContainerObjectsSize(); ++i) {
		SceneObject* item = hopper->getContainerObject(i);

		if (item != nullptr && isBivoliSupply(item))
			total += getSupplyAmount(item);
	}

	return Math::max(0, total);
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

void DoctorBuffDroidMenuComponent::sendStockSummary(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return;

	Time now;
	uint64 nowMs = now.getMiliTime();

	StringBuffer msg;
	msg << "Doctor Buff Droid stock:";

	uint32 attrMask = loadedAttributeMask(sceneObject, DoctorBuffDroidDataComponent::SERVICE_BUFFS);
	if (attrMask == 0) {
		msg << " Buffs: 0 use(s)";
	} else {
		for (uint8 attr = 0; attr < 9; ++attr) {
			int stock = sumLoadedAmount(sceneObject, DoctorBuffDroidDataComponent::SERVICE_BUFFS, attr);
			if (stock > 0)
				msg << " " << BuffAttribute::getName(attr, true) << ": " << stock << " use(s)";
		}
	}

	uint32 jantaAttrMask = loadedAttributeMask(sceneObject, DoctorBuffDroidDataComponent::SERVICE_JANTA);
	if (jantaAttrMask == 0) {
		msg << " | Janta Buffs: 0 use(s)";
	} else {
		msg << " | Janta Buffs:";
		for (uint8 attr = 0; attr < 9; ++attr) {
			int stock = sumLoadedAmount(sceneObject, DoctorBuffDroidDataComponent::SERVICE_JANTA, attr);
			if (stock > 0)
				msg << " " << BuffAttribute::getName(attr, true) << ": " << stock << " use(s)";
		}
	}

	msg << " | Poison resist: " << sumLoadedAmount(sceneObject, DoctorBuffDroidDataComponent::SERVICE_POISON, 0)
		<< " use(s) | Disease resist: " << sumLoadedAmount(sceneObject, DoctorBuffDroidDataComponent::SERVICE_DISEASE, 0)
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

			// Real item moves into the droid's own container intact — its true power/duration/attr
			// stay with it, so multiple different-strength packs coexist instead of being folded
			// into a single averaged stat.
			if (!sceneObject->transferObject(item, -1, true))
				continue;

			sceneObject->broadcastObject(item, true);
			loaded += amount;
			continue;
		}

		if (!sceneObject->transferObject(item, -1, true))
			continue;

		sceneObject->broadcastObject(item, true);
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
	sendStockSummary(sceneObject, player, data);
	return true;
}

void DoctorBuffDroidMenuComponent::promptPriceSelection(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	bool station = isDoctorServiceUnitObject(sceneObject);

	ManagedReference<SuiListBox*> box = station ?
		new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLETWOBUTTON) :
		new SuiListBox(player, SuiWindowType::NONE);

	box->setPromptTitle(station ?
		"Automated Medical Station - Service Prices" :
		"Doctor Buff Droid Prices");
	box->setPromptText("Select a service to update its price.");
	box->setCallback(new DoctorBuffDroidPriceSuiCallback(
		player->getZoneServer(), sceneObject));

	if (station) {
		box->setCancelButton(true, "@back");
		box->setOkButton(true, "@ok");
	}

	box->addMenuItem(String(station ? "Standard Doctor Buffs (" : "Medical Buffs (") +
		String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_BUFFS)) + ")");
	box->addMenuItem(String(station ? "Janta Doctor Buffs (" : "Janta Buffs (") +
		String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_JANTA)) + ")");
	box->addMenuItem("Wound Healing (" +
		String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)) + ")");
	box->addMenuItem("Poison Resistance (" +
		String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_POISON)) + ")");
	box->addMenuItem("Disease Resistance (" +
		String::valueOf(data->getPrice(DoctorBuffDroidDataComponent::SERVICE_DISEASE)) + ")");

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptPriceInput(
	SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent::ServiceType service) {

	if (sceneObject == nullptr || player == nullptr)
		return;

	bool station = isDoctorServiceUnitObject(sceneObject);

	ManagedReference<SuiInputBox*> box =
		new SuiInputBox(player, SuiWindowType::NONE);

	box->setPromptTitle(station ?
		"Automated Medical Station - Service Price" :
		"Doctor Buff Droid Price");
	box->setPromptText(
		"Enter the new credit price for " + getServiceName(service) + ".");
	box->setMaxInputSize(9);
	box->setCallback(new DoctorBuffDroidPriceInputSuiCallback(
		player->getZoneServer(), sceneObject, service));

	if (station) {
		box->setCancelButton(true, "@back");
		box->setOkButton(true, "@ok");
	}

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptDiscountInput(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	bool station = isDoctorServiceUnitObject(sceneObject);

	ManagedReference<SuiInputBox*> box =
		new SuiInputBox(player, SuiWindowType::NONE);

	box->setPromptTitle(station ?
		"Automated Medical Station - Guild Discount" :
		"Doctor Buff Droid Discount");
	box->setPromptText(
		station ?
			"Enter the guild discount percent (0-90). Your current guild is cached so the discount can work while you are offline." :
			"Enter the guild discount percent for this droid.");
	box->setMaxInputSize(3);
	box->setCallback(new DoctorBuffDroidDiscountSuiCallback(
		player->getZoneServer(), sceneObject));

	if (station) {
		box->setCancelButton(true, "@back");
		box->setOkButton(true, "@ok");
	}

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptToggleSelection(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	bool station = isDoctorServiceUnitObject(sceneObject);

	ManagedReference<SuiListBox*> box = station ?
		new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLETWOBUTTON) :
		new SuiListBox(player, SuiWindowType::NONE);

	box->setPromptTitle(station ?
		"Automated Medical Station - Toggle Services" :
		"Toggle Services");
	box->setPromptText("Select a service to toggle.");
	box->setCallback(new DoctorBuffDroidToggleSuiCallback(
		player->getZoneServer(), sceneObject));

	if (station) {
		box->setCancelButton(true, "@back");
		box->setOkButton(true, "@ok");
	}

	box->addMenuItem(String(station ? "Standard Doctor Buffs (" : "Medical Buffs (") +
		String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_BUFFS) ?
			"Enabled" : "Disabled") + ")");
	box->addMenuItem(String(station ? "Janta Doctor Buffs (" : "Janta Buffs (") +
		String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_JANTA) ?
			"Enabled" : "Disabled") + ")");
	box->addMenuItem("Wound Healing (" +
		String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_WOUNDS) ?
			"Enabled" : "Disabled") + ")");
	box->addMenuItem("Poison Resistance (" +
		String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_POISON) ?
			"Enabled" : "Disabled") + ")");
	box->addMenuItem("Disease Resistance (" +
		String(data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_DISEASE) ?
			"Enabled" : "Disabled") + ")");

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptAdTextInput(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject == nullptr || player == nullptr)
		return;

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	bool station = isDoctorServiceUnitObject(sceneObject);

	ManagedReference<SuiInputBox*> box =
		new SuiInputBox(player, SuiWindowType::NONE);

	box->setPromptTitle(station ?
		"Automated Medical Station - Station Message" :
		"Doctor Buff Droid Ad Message");
	box->setPromptText(
		station ?
			"Enter the message displayed in Services / Availability (max 200 characters). Submit a blank message to clear it. Automatic proximity barking remains disabled for this stationary service." :
			"Enter the advertisement message the droid will bark to nearby players (max 200 characters). Ad barking will be enabled automatically.");
	box->setMaxInputSize(200);

	String currentText = data->getAdBarkText();
	if (!currentText.isEmpty())
		box->setDefaultInput(currentText);

	box->setCallback(new DoctorBuffDroidAdTextSuiCallback(
		player->getZoneServer(), sceneObject));

	if (station) {
		box->setCancelButton(true, "@back");
		box->setOkButton(true, "@ok");
	}

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

int DoctorBuffDroidMenuComponent::getLoadedItemQuantity(SceneObject* sceneObject, uint64 itemObjectId) {
	if (sceneObject == nullptr || itemObjectId == 0)
		return 0;

	for (int i = 0; i < sceneObject->getContainerObjectsSize(); ++i) {
		SceneObject* item = sceneObject->getContainerObject(i);
		if (item != nullptr && item->getObjectID() == itemObjectId)
			return getSupplyAmount(item);
	}

	return 0;
}

void DoctorBuffDroidMenuComponent::openDroidInventory(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return;

	Time now;
	uint64 nowMs = now.getMiliTime();

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Doctor Buff Droid - Current Inventory");

	int rowCount = 0;

	// One row per real loaded item — its true power/duration/quantity are read straight off
	// the item, so different-strength packs for the same attribute show as separate rows
	// instead of a single blended average.
	for (int i = 0; i < sceneObject->getContainerObjectsSize(); ++i) {
		SceneObject* item = sceneObject->getContainerObject(i);

		DoctorBuffDroidDataComponent::ServiceType service;
		byte attr;
		if (!classifyLoadedItem(item, service, attr))
			continue;

		int qty = getSupplyAmount(item);
		if (qty <= 0)
			continue;

		String label;
		if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS)
			label = "Medical Buff [" + BuffAttribute::getName(attr, true) + "]";
		else if (service == DoctorBuffDroidDataComponent::SERVICE_JANTA)
			label = "Janta Buff [" + BuffAttribute::getName(attr, true) + "]";
		else if (service == DoctorBuffDroidDataComponent::SERVICE_POISON)
			label = "Poison Resistance";
		else
			label = "Disease Resistance";

		float power = getMedicalPackEffectiveness(item);
		float duration = (service == DoctorBuffDroidDataComponent::SERVICE_JANTA) ? getJantaDuration(item) : getPackDuration(item);

		box->addMenuItem(label + ": power " + String::valueOf((int)power) + ", duration " + String::valueOf((int)duration)
			+ "s, " + String::valueOf(qty) + " use(s)", item->getObjectID());
		++rowCount;
	}

	// Build prompt text with Bivoli info (not withdrawable as packs).
	StringBuffer prompt;
	prompt << "Select a supply row to withdraw packs into your inventory (owner only)."
	       << "\nSelect \"Remove My Buffs\" to clear your own active buffs.";
	if (rowCount == 0)
		prompt << "\nNo withdrawable supplies are currently loaded.";
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
	box->setPromptText(prompt.toString());

	// Always the last row; carries no object ID (defaults to 0, which is never a real object ID).
	box->addMenuItem("--- Remove My Active Doctor Buffs ---");

	box->setCallback(new DoctorBuffDroidInventorySuiCallback(player->getZoneServer(), sceneObject));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::promptWithdrawQuantity(SceneObject* sceneObject, CreatureObject* player, uint64 itemObjectId, int maxQty) {
	if (sceneObject == nullptr || player == nullptr || maxQty <= 0)
		return;

	String label = "Supply";
	for (int i = 0; i < sceneObject->getContainerObjectsSize(); ++i) {
		SceneObject* item = sceneObject->getContainerObject(i);
		if (item == nullptr || item->getObjectID() != itemObjectId)
			continue;

		DoctorBuffDroidDataComponent::ServiceType service;
		byte attr;
		if (!classifyLoadedItem(item, service, attr))
			break;

		if (service == DoctorBuffDroidDataComponent::SERVICE_BUFFS)
			label = "Medical Buff [" + BuffAttribute::getName(attr, true) + "]";
		else if (service == DoctorBuffDroidDataComponent::SERVICE_JANTA)
			label = "Janta Buff [" + BuffAttribute::getName(attr, true) + "]";
		else if (service == DoctorBuffDroidDataComponent::SERVICE_POISON)
			label = "Poison Resistance";
		else if (service == DoctorBuffDroidDataComponent::SERVICE_DISEASE)
			label = "Disease Resistance";
		break;
	}

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Withdraw Supplies");
	box->setPromptText("Enter the number of [" + label + "] packs to withdraw (max " + String::valueOf(maxQty) + ").\nPacks are created in stacks of up to 28.");
	box->setMaxInputSize(6);
	box->setCallback(new DoctorBuffDroidWithdrawQuantitySuiCallback(player->getZoneServer(), sceneObject, itemObjectId, maxQty));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void DoctorBuffDroidMenuComponent::withdrawBuffStock(SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent* data, uint64 itemObjectId, int quantity) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr || quantity <= 0)
		return;

	ZoneServer* zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return;

	SceneObject* inventory = player->getSlottedObject("inventory");
	if (inventory == nullptr)
		return;

	// Resolve the specific loaded item the owner selected — never a scalar average.
	SceneObject* item = nullptr;
	for (int i = 0; i < sceneObject->getContainerObjectsSize(); ++i) {
		SceneObject* candidate = sceneObject->getContainerObject(i);
		if (candidate != nullptr && candidate->getObjectID() == itemObjectId) {
			item = candidate;
			break;
		}
	}

	DoctorBuffDroidDataComponent::ServiceType service;
	byte attr;
	int stock = (item != nullptr) ? getSupplyAmount(item) : 0;

	if (item == nullptr || stock <= 0 || !classifyLoadedItem(item, service, attr)) {
		player->sendSystemMessage("That supply is no longer loaded in the droid.");
		return;
	}

	if (quantity > stock)
		quantity = stock;

	if (quantity >= stock) {
		// Withdrawing everything — move the real item back intact instead of manufacturing a copy.
		if (!inventory->transferObject(item, -1, true)) {
			player->sendSystemMessage("Failed to withdraw supplies. Your inventory may be full.");
			return;
		}

		inventory->broadcastObject(item, true);
		persistDroidState(sceneObject);
		player->sendSystemMessage("Withdrew " + String::valueOf(quantity) + " supply pack(s) into your inventory.");
		return;
	}

	// Partial withdrawal: manufacture a new crate from the real item's own power/duration/attr,
	// then shrink the original by the withdrawn amount.
	byte packAttr = (service == DoctorBuffDroidDataComponent::SERVICE_POISON) ? (byte)BuffAttribute::POISON
		: (service == DoctorBuffDroidDataComponent::SERVICE_DISEASE) ? (byte)BuffAttribute::DISEASE
		: attr;
	float packPower = getMedicalPackEffectiveness(item);
	float packDuration = (service == DoctorBuffDroidDataComponent::SERVICE_JANTA) ? getJantaDuration(item) : getPackDuration(item);

	int totalCreated = createSupplyCrates(zoneServer, packAttr, packPower, packDuration, quantity, inventory, player);

	if (totalCreated <= 0) {
		player->sendSystemMessage("Failed to create supply crates. Your inventory may be full.");
		return;
	}

	consumeLoadedAmount(item, totalCreated);
	persistDroidState(sceneObject);
	player->sendSystemMessage("Withdrew " + String::valueOf(totalCreated) + " supply pack(s) into your inventory as factory crate(s).");
}

bool DoctorBuffDroidMenuComponent::performMedicalBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, bool useJanta) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	DoctorBuffDroidDataComponent::ServiceType service =
		useJanta ? DoctorBuffDroidDataComponent::SERVICE_JANTA :
			DoctorBuffDroidDataComponent::SERVICE_BUFFS;
	const char* serviceLabel = useJanta ? "Janta buffs" : "medical buffs";
	bool doctorServiceUnit = isDoctorServiceUnitObject(sceneObject);

	if (!data->isServiceEnabled(service)) {
		if (doctorServiceUnit) {
			player->sendSystemMessage(
				String(useJanta ? "Janta" : "Standard") +
				" Doctor Buffs are currently unavailable because this service is disabled by the station owner. You were not charged.");
		} else {
			player->sendSystemMessage("This Doctor Buff Droid currently has that buff service disabled.");
		}
		return false;
	}

	if (doctorServiceUnit) {
		// Phase 2 customer-safety preflight. The station will not sell a partial set.
		int completeSessions = getDoctorServiceCompleteSessions(sceneObject, service);
		if (completeSessions <= 0) {
			String missing = getDoctorServiceMissingAttributes(sceneObject, service);
			player->sendSystemMessage(
				String(useJanta ? "Janta" : "Standard") +
				" Doctor Buffs are unavailable. Missing supplies: " + missing +
				". You were not charged.");
			return false;
		}

		// Resolve all six actual supply objects before anything is charged or consumed.
		// The station caller holds the hopper lock for this entire transaction.
		SceneObject* selectedSupplies[6];

		for (int i = 0; i < 6; ++i) {
			selectedSupplies[i] =
				findLoadedItem(sceneObject, service, kDoctorServiceRequiredAttrs[i]);

			if (selectedSupplies[i] == nullptr) {
				player->sendSystemMessage(
					"Automated Medical Station stock changed before purchase completion. "
					"You were not charged.");
				return false;
			}
		}

		Time now;
		uint64 nowMs = now.getMiliTime();
		int activeBivoliBonus = data->getActiveBivoliBonus(nowMs);

		if (activeBivoliBonus <= 0) {
			SceneObject* hopper = resolveMedicalSupplyContainer(sceneObject);
			bool usableBivoli = false;

			if (hopper != nullptr) {
				for (int i = 0; i < hopper->getContainerObjectsSize(); ++i) {
					SceneObject* candidate = hopper->getContainerObject(i);

					if (candidate == nullptr || !isBivoliSupply(candidate))
						continue;

					float strength = getBivoliStrength(candidate);
					float duration = getBivoliDuration(candidate);

					if (strength >= 0.5f && duration > 0.0f) {
						usableBivoli = true;
						break;
					}
				}
			}

			if (!usableBivoli) {
				player->sendSystemMessage(
					"Automated Medical Station cannot begin a new Doctor buff session because Bivoli Support is out of stock. "
					"You were not charged.");
				return false;
			}
		}

		PlayerManager* playerManager = player->getZoneServer()->getPlayerManager();
		if (playerManager == nullptr) {
			player->sendSystemMessage(
				"Automated Medical Station service is temporarily unavailable. You were not charged.");
			return false;
		}

		int price = data->getDiscountedPrice(service, player);
		if (player->getBankCredits() + player->getCashCredits() < price) {
			player->sendSystemMessage(
				"You do not have enough credits for " +
				String(useJanta ? "Janta" : "Standard") + " Doctor Buffs. You were not charged.");
			return false;
		}

		// Bivoli is activated only after every required buff attribute and the
		// buyer's credits have passed preflight. Because the hopper remains locked,
		// the validated supply cannot be removed between these checks and activation.
		if (!ensureBivoliBuffActive(sceneObject, data)) {
			player->sendSystemMessage(
				"Automated Medical Station cannot begin a new Doctor buff session because the loaded Bivoli Support is invalid or unavailable. "
				"You were not charged.");
			return false;
		}

		if (!deductCredits(player, price)) {
			player->sendSystemMessage(
				"Your credits changed before the purchase could complete. You were not charged.");
			return false;
		}

		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod = getOwnerHealingWoundTreatment(sceneObject, data, player, useJanta);

		for (int i = 0; i < 6; ++i) {
			byte attr = kDoctorServiceRequiredAttrs[i];
			SceneObject* supplyItem = selectedSupplies[i];

			float packPower = getMedicalPackEffectiveness(supplyItem);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration =
				useJanta ? getJantaDuration(supplyItem) : getPackDuration(supplyItem);
			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount = calculateDroidBuffPower(packPower, envMod, healMod);

			removeDoctorBuff(player, attr);
			playerManager->healEnhance(
				player, player, attr, buffAmount, buffDuration, 0);
			consumeLoadedAmount(supplyItem, 1);
		}

		data->addEarnings(price);
		persistDroidState(sceneObject);
		player->playEffect("clienteffect/healing_healenhance.cef", "");
		player->sendSystemMessage(
			"Purchased " + String(useJanta ? "Janta" : "Standard") +
			" Doctor Buffs for " + String::valueOf(price) + " credits. Six enhancements applied.");
		return true;
	}

	// Legacy Doctor Buff Droid behavior remains unchanged.
	uint32 attrMask = loadedAttributeMask(sceneObject, service);
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

			SceneObject* supplyItem = findLoadedItem(sceneObject, service, attr);
			if (supplyItem == nullptr)
				continue;

			float packPower = getMedicalPackEffectiveness(supplyItem);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration = useJanta ? getJantaDuration(supplyItem) : getPackDuration(supplyItem);
			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount = calculateDroidBuffPower(packPower, envMod, healMod);

			removeDoctorBuff(player, attr);
			playerManager->healEnhance(player, player, attr, buffAmount, buffDuration, 0);
			consumeLoadedAmount(supplyItem, 1);
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

	bool station = isDoctorServiceUnitObject(sceneObject);

	if (!data->isServiceEnabled(DoctorBuffDroidDataComponent::SERVICE_WOUNDS)) {
		player->sendSystemMessage(
			station ?
				"Wound Healing is currently disabled by the Automated Medical Station owner. You were not charged." :
				"This Doctor Buff Droid currently has wound healing disabled.");
		return false;
	}

	int totalWounds = 0;
	for (int i = 0; i < 9; ++i)
		totalWounds += player->getWounds(i);

	if (totalWounds <= 0) {
		player->sendSystemMessage(
			station ?
				"You do not have any wounds to heal. You were not charged." :
				"You do not have any wounds to heal.");
		return false;
	}

	int price = data->getDiscountedPrice(DoctorBuffDroidDataComponent::SERVICE_WOUNDS, player);

	if (station && player->getBankCredits() + player->getCashCredits() < price) {
		player->sendSystemMessage("You do not have enough credits for Wound Healing. You were not charged.");
		return false;
	}

	if (!deductCredits(player, price)) {
		player->sendSystemMessage(
			station ?
				"Your credits changed before Wound Healing could complete. You were not charged." :
				"You do not have enough credits to purchase wound healing.");
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

	if (station) {
		player->sendSystemMessage(
			"Purchased Wound Healing for " + String::valueOf(price) +
			" credits. All current wounds were healed.");
	} else {
		player->sendSystemMessage("Doctor Buff Droid wound healing complete.");
	}

	return true;
}

bool DoctorBuffDroidMenuComponent::performResistance(
	SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent* data,
	DoctorBuffDroidDataComponent::ServiceType type) {

	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	bool station = isDoctorServiceUnitObject(sceneObject);
	String serviceLabel =
		type == DoctorBuffDroidDataComponent::SERVICE_POISON ?
			"Poison Resistance" : "Disease Resistance";

	if (!data->isServiceEnabled(type)) {
		player->sendSystemMessage(
			station ?
				serviceLabel +
					" is currently disabled by the Automated Medical Station owner. You were not charged." :
				"That Doctor Buff Droid resistance service is currently disabled.");
		return false;
	}

	SceneObject* supplyItem = findLoadedItem(sceneObject, type, 0);
	if (supplyItem == nullptr) {
		player->sendSystemMessage(
			station ?
				serviceLabel + " is out of stock. You were not charged." :
				"That Doctor Buff Droid is out of resistance supplies.");
		return false;
	}

	ZoneServer* zoneServer = player->getZoneServer();
	PlayerManager* playerManager =
		zoneServer != nullptr ? zoneServer->getPlayerManager() : nullptr;

	if (station && playerManager == nullptr) {
		player->sendSystemMessage(
			"Automated Medical Station service is temporarily unavailable. You were not charged.");
		return false;
	}

	int price = data->getDiscountedPrice(type, player);

	if (station && player->getBankCredits() + player->getCashCredits() < price) {
		player->sendSystemMessage(
			"You do not have enough credits for " + serviceLabel +
			". You were not charged.");
		return false;
	}

	float packPower = getPackEffectiveness(supplyItem);
	float resistDuration = getPackDuration(supplyItem);

	if (!deductCredits(player, price)) {
		player->sendSystemMessage(
			station ?
				"Your credits changed before " + serviceLabel +
					" could complete. You were not charged." :
				"You do not have enough credits for that Doctor Buff Droid service.");
		return false;
	}

	if (playerManager != nullptr) {
		// Station rule: resistance purchases never create a new Bivoli session.
		// If a Bivoli session is already active, getOwnerHealingWoundTreatment()
		// automatically includes it. Legacy Doctor Buff Droids keep their original
		// activation behavior.
		if (!station)
			ensureBivoliBuffActive(sceneObject, data);

		int attribute =
			type == DoctorBuffDroidDataComponent::SERVICE_POISON ?
				BuffAttribute::POISON : BuffAttribute::DISEASE;

		if (packPower <= 0.0f)
			packPower = 60.0f;

		int envMod = getDroidEnvironmentalMedRating(sceneObject);
		int healMod =
			getOwnerHealingWoundTreatment(sceneObject, data, player);
		int resistAmount =
			calculateDroidBuffPower(packPower, envMod, healMod);

		if (resistDuration <= 0.0f)
			resistDuration = 7200.f;

		removeDoctorBuff(player, (uint8)attribute);
		playerManager->healEnhance(
			player, player, attribute, resistAmount, resistDuration, 0);

		consumeLoadedAmount(supplyItem, 1);
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	player->playEffect("clienteffect/healing_healenhance.cef", "");

	if (station) {
		player->sendSystemMessage(
			"Purchased " + serviceLabel + " for " +
			String::valueOf(price) + " credits.");
	} else {
		player->sendSystemMessage(
			"Doctor Buff Droid " +
			getServiceName(type).toLowerCase() + " applied.");
	}

	return true;
}

bool DoctorBuffDroidMenuComponent::performPetBuffForTarget(
	SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent* data, AiAgent* activePet,
	bool useJanta) {

	if (sceneObject == nullptr || player == nullptr ||
			data == nullptr || activePet == nullptr)
		return false;

	DoctorBuffDroidDataComponent::ServiceType service =
		useJanta ? DoctorBuffDroidDataComponent::SERVICE_JANTA :
			DoctorBuffDroidDataComponent::SERVICE_BUFFS;
	const char* serviceLabel = useJanta ? "Janta buffs" : "medical buffs";
	bool station = isDoctorServiceUnitObject(sceneObject);

	if (!data->isServiceEnabled(service)) {
		player->sendSystemMessage(
			station ?
				String(useJanta ? "Janta" : "Standard") +
					" Doctor Pet Buffs are currently disabled by the station owner. You were not charged." :
				"This Doctor Buff Droid currently has that buff service disabled.");
		return false;
	}

	if (activePet->isDead()) {
		player->sendSystemMessage(
			station ?
				"The selected pet is no longer available to buff. You were not charged." :
				"Your pet cannot be buffed right now.");
		return false;
	}

	if (activePet->isInCombat()) {
		player->sendSystemMessage(
			station ?
				"The selected pet is in combat and cannot be buffed right now. You were not charged." :
				"Your pet is in combat and cannot be buffed right now.");
		return false;
	}

	if (station) {
		int completeSessions =
			getDoctorServiceCompleteSessions(sceneObject, service);

		if (completeSessions <= 0) {
			String missing =
				getDoctorServiceMissingAttributes(sceneObject, service);
			player->sendSystemMessage(
				String(useJanta ? "Janta" : "Standard") +
				" Doctor Pet Buffs are unavailable. Missing supplies: " +
				missing + ". You were not charged.");
			return false;
		}

		SceneObject* selectedSupplies[6];

		for (int i = 0; i < 6; ++i) {
			selectedSupplies[i] =
				findLoadedItem(
					sceneObject, service, kDoctorServiceRequiredAttrs[i]);

			if (selectedSupplies[i] == nullptr) {
				player->sendSystemMessage(
					"Automated Medical Station stock changed before the pet-buff purchase completed. "
					"You were not charged.");
				return false;
			}
		}

		Time now;
		uint64 nowMs = now.getMiliTime();
		int activeBivoliBonus = data->getActiveBivoliBonus(nowMs);

		if (activeBivoliBonus <= 0) {
			SceneObject* hopper =
				resolveMedicalSupplyContainer(sceneObject);
			bool usableBivoli = false;

			if (hopper != nullptr) {
				for (int i = 0;
						i < hopper->getContainerObjectsSize(); ++i) {
					SceneObject* candidate =
						hopper->getContainerObject(i);

					if (candidate == nullptr ||
							!isBivoliSupply(candidate))
						continue;

					float strength = getBivoliStrength(candidate);
					float duration = getBivoliDuration(candidate);

					if (strength >= 0.5f && duration > 0.0f) {
						usableBivoli = true;
						break;
					}
				}
			}

			if (!usableBivoli) {
				player->sendSystemMessage(
					"Doctor Pet Buffs are unavailable because Bivoli Support is out of stock. "
					"You were not charged.");
				return false;
			}
		}

		ZoneServer* zoneServer = player->getZoneServer();
		PlayerManager* playerManager =
			zoneServer != nullptr ?
				zoneServer->getPlayerManager() : nullptr;

		if (playerManager == nullptr) {
			player->sendSystemMessage(
				"Automated Medical Station pet-buff service is temporarily unavailable. "
				"You were not charged.");
			return false;
		}

		int price = data->getDiscountedPrice(service, player);

		if (player->getBankCredits() +
				player->getCashCredits() < price) {
			player->sendSystemMessage(
				"You do not have enough credits for " +
				String(useJanta ? "Janta" : "Standard") +
				" Doctor Pet Buffs. You were not charged.");
			return false;
		}

		if (!ensureBivoliBuffActive(sceneObject, data)) {
			player->sendSystemMessage(
				"Doctor Pet Buffs are unavailable because the loaded Bivoli Support is invalid or unavailable. "
				"You were not charged.");
			return false;
		}

		if (!deductCredits(player, price)) {
			player->sendSystemMessage(
				"Your credits changed before the pet-buff purchase could complete. "
				"You were not charged.");
			return false;
		}

		int envMod =
			getDroidEnvironmentalMedRating(sceneObject);
		int healMod =
			getOwnerHealingWoundTreatment(
				sceneObject, data, player, useJanta);

		for (int i = 0; i < 6; ++i) {
			byte attr = kDoctorServiceRequiredAttrs[i];
			SceneObject* supplyItem = selectedSupplies[i];

			float packPower =
				getMedicalPackEffectiveness(supplyItem);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration =
				useJanta ?
					getJantaDuration(supplyItem) :
					getPackDuration(supplyItem);

			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount =
				calculateDroidBuffPower(
					packPower, envMod, healMod);

			removeDoctorBuff(activePet, attr);
			playerManager->healEnhance(
				player, activePet, attr,
				buffAmount, buffDuration, 0);
			consumeLoadedAmount(supplyItem, 1);
		}

		data->addEarnings(price);
		persistDroidState(sceneObject);
		activePet->playEffect(
			"clienteffect/healing_healenhance.cef", "");

		player->sendSystemMessage(
			"Purchased " +
			String(useJanta ? "Janta" : "Standard") +
			" Doctor Buffs for " +
			activePet->getDisplayedName() + " for " +
			String::valueOf(price) +
			" credits. Six enhancements applied.");
		return true;
	}

	// Legacy Doctor Buff Droid behavior remains unchanged.
	uint32 attrMask = loadedAttributeMask(sceneObject, service);

	if (attrMask == 0) {
		if (useJanta)
			player->sendSystemMessage(
				"This Doctor Buff Droid is out of Janta buff pack supplies.");
		else
			player->sendSystemMessage(
				"This Doctor Buff Droid is out of buff pack supplies.");
		return false;
	}

	if (!ensureBivoliBuffActive(sceneObject, data)) {
		player->sendSystemMessage(
			"This Doctor Buff Droid is out of Bivoli supplies.");
		return false;
	}

	int price = data->getDiscountedPrice(service, player);

	if (!deductCredits(player, price)) {
		player->sendSystemMessage(
			"You do not have enough credits to purchase Doctor Buff Droid pet buffs.");
		return false;
	}

	PlayerManager* playerManager =
		player->getZoneServer()->getPlayerManager();

	if (playerManager != nullptr) {
		int envMod =
			getDroidEnvironmentalMedRating(sceneObject);
		int healMod =
			getOwnerHealingWoundTreatment(
				sceneObject, data, player, useJanta);

		for (uint8 attr = 0; attr < 9; ++attr) {
			if (!(attrMask & (1u << attr)))
				continue;

			SceneObject* supplyItem =
				findLoadedItem(sceneObject, service, attr);

			if (supplyItem == nullptr)
				continue;

			float packPower =
				getMedicalPackEffectiveness(supplyItem);
			if (packPower <= 0.0f)
				packPower = 500.0f;

			float buffDuration =
				useJanta ?
					getJantaDuration(supplyItem) :
					getPackDuration(supplyItem);

			if (buffDuration <= 0.0f)
				buffDuration = 7200.f;

			int buffAmount =
				calculateDroidBuffPower(
					packPower, envMod, healMod);

			removeDoctorBuff(activePet, attr);
			playerManager->healEnhance(
				player, activePet, attr,
				buffAmount, buffDuration, 0);
			consumeLoadedAmount(supplyItem, 1);
		}
	}

	data->addEarnings(price);
	persistDroidState(sceneObject);
	activePet->playEffect(
		"clienteffect/healing_healenhance.cef", "");
	player->sendSystemMessage(
		"Doctor Buff Droid " +
		String(serviceLabel) + " applied to your pet.");
	return true;
}

bool DoctorBuffDroidMenuComponent::performPetBuff(
	SceneObject* sceneObject, CreatureObject* player,
	DoctorBuffDroidDataComponent* data, bool useJanta) {

	if (sceneObject == nullptr || player == nullptr || data == nullptr)
		return false;

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr) {
		player->sendSystemMessage(
			isDoctorServiceUnitObject(sceneObject) ?
				"You do not have an active pet to buff. You were not charged." :
				"You do not have an active pet to buff.");
		return false;
	}

	ManagedReference<AiAgent*> activePet;

	for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
		ManagedReference<AiAgent*> pet = ghost->getActivePet(i);

		if (pet != nullptr && !pet->isDead()) {
			activePet = pet;
			break;
		}
	}

	if (activePet == nullptr) {
		player->sendSystemMessage(
			isDoctorServiceUnitObject(sceneObject) ?
				"You do not have an active pet to buff. You were not charged." :
				"You do not have an active pet to buff.");
		return false;
	}

	return performPetBuffForTarget(
		sceneObject, player, data, activePet.get(), useJanta);
}

void DoctorBuffDroidMenuComponent::migrateLegacyStock(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data) {
	if (sceneObject == nullptr || player == nullptr || data == nullptr || !data->hasLegacyStock())
		return;

	ZoneServer* zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return;

	for (byte attr = 0; attr < 9; ++attr) {
		int buffStock = data->getLegacyBuffStock(attr);
		if (buffStock > 0)
			createSupplyCrates(zoneServer, attr, data->getLegacyBuffPower(attr), data->getLegacyBuffDuration(attr), buffStock, sceneObject, player);

		int jantaStock = data->getLegacyJantaBuffStock(attr);
		if (jantaStock > 0)
			createSupplyCrates(zoneServer, attr, data->getLegacyJantaBuffPower(attr), data->getLegacyJantaBuffDuration(attr), jantaStock, sceneObject, player);
	}

	int poisonStock = data->getLegacyPoisonStock();
	if (poisonStock > 0)
		createSupplyCrates(zoneServer, (byte)BuffAttribute::POISON, data->getLegacyPoisonPower(), data->getLegacyPoisonDuration(), poisonStock, sceneObject, player);

	int diseaseStock = data->getLegacyDiseaseStock();
	if (diseaseStock > 0)
		createSupplyCrates(zoneServer, (byte)BuffAttribute::DISEASE, data->getLegacyDiseasePower(), data->getLegacyDiseaseDuration(), diseaseStock, sceneObject, player);

	data->clearLegacyStock();
	persistDroidState(sceneObject);
}

void DoctorBuffDroidMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (sceneObject == nullptr || player == nullptr)
		return;

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	DoctorBuffDroidDataComponent* data = getDroidData(sceneObject);
	if (data == nullptr)
		return;

	migrateLegacyStock(sceneObject, player, data);

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
