#include "DoctorBuffDroidDataComponent.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/scene/SceneObject.h"

namespace {
// Field names are kept identical to the pre-upgrade schema so existing live droid rows
// deserialize into these (now legacy-only) fields for one-time migration.
const char* const kBuffStockAttrNames[9] = {
	"buffStockAttr0", "buffStockAttr1", "buffStockAttr2",
	"buffStockAttr3", "buffStockAttr4", "buffStockAttr5",
	"buffStockAttr6", "buffStockAttr7", "buffStockAttr8"
};

const char* const kBuffPowerAttrNames[9] = {
	"buffPowerAttr0", "buffPowerAttr1", "buffPowerAttr2",
	"buffPowerAttr3", "buffPowerAttr4", "buffPowerAttr5",
	"buffPowerAttr6", "buffPowerAttr7", "buffPowerAttr8"
};

const char* const kBuffDurationAttrNames[9] = {
	"buffDurationAttr0", "buffDurationAttr1", "buffDurationAttr2",
	"buffDurationAttr3", "buffDurationAttr4", "buffDurationAttr5",
	"buffDurationAttr6", "buffDurationAttr7", "buffDurationAttr8"
};

const char* const kJantaBuffStockAttrNames[9] = {
	"jantaBuffStockAttr0", "jantaBuffStockAttr1", "jantaBuffStockAttr2",
	"jantaBuffStockAttr3", "jantaBuffStockAttr4", "jantaBuffStockAttr5",
	"jantaBuffStockAttr6", "jantaBuffStockAttr7", "jantaBuffStockAttr8"
};

const char* const kJantaBuffPowerAttrNames[9] = {
	"jantaBuffPowerAttr0", "jantaBuffPowerAttr1", "jantaBuffPowerAttr2",
	"jantaBuffPowerAttr3", "jantaBuffPowerAttr4", "jantaBuffPowerAttr5",
	"jantaBuffPowerAttr6", "jantaBuffPowerAttr7", "jantaBuffPowerAttr8"
};

const char* const kJantaBuffDurationAttrNames[9] = {
	"jantaBuffDurationAttr0", "jantaBuffDurationAttr1", "jantaBuffDurationAttr2",
	"jantaBuffDurationAttr3", "jantaBuffDurationAttr4", "jantaBuffDurationAttr5",
	"jantaBuffDurationAttr6", "jantaBuffDurationAttr7", "jantaBuffDurationAttr8"
};
}

DoctorBuffDroidDataComponent::DoctorBuffDroidDataComponent() : DataObjectComponent(), dataMutex() {
	ownerId = 0;

	for (int i = 0; i < 9; ++i) {
		legacyBuffStockPerAttr[i] = 0;
		legacyBuffPowerPerAttr[i] = 0.0f;
		legacyBuffDurationPerAttr[i] = 0.0f;
		legacyJantaBuffStockPerAttr[i] = 0;
		legacyJantaBuffPowerPerAttr[i] = 0.0f;
		legacyJantaBuffDurationPerAttr[i] = 0.0f;
	}

	legacyPoisonStock = 0;
	legacyDiseaseStock = 0;
	earningsBalance = 0;

	buffPrice = 10000;
	woundPrice = 1000;
	poisonPrice = 2500;
	diseasePrice = 2500;
	jantaPrice = 25000;

	guildDiscountPercent = 0;
	minimumPriceFloor = 100;

	buffsEnabled = true;
	woundsEnabled = true;
	poisonEnabled = true;
	diseaseEnabled = true;
	jantaEnabled = true;

	legacyPoisonPackPower = 0.0f;
	legacyDiseasePackPower = 0.0f;
	legacyPoisonPackDuration = 0.0f;
	legacyDiseasePackDuration = 0.0f;
	ownerHealingMod = 100;
	bivoliStock = 0;
	bivoliStrength = 0.0f;
	bivoliDuration = 0.0f;
	activeBivoliBonus = 0;
	activeBivoliExpiresAt = 0;
	jantaStock = 0;
	jantaStrength = 0.0f;
	jantaDuration = 0.0f;
	activeJantaBonus = 0;
	activeJantaExpiresAt = 0;

	adBarkText = "";
	adBarkEnabled = false;

	addSerializableVariable("ownerId", &ownerId);
	for (int i = 0; i < 9; ++i) {
		addSerializableVariable(kBuffStockAttrNames[i], &legacyBuffStockPerAttr[i]);
		addSerializableVariable(kBuffPowerAttrNames[i], &legacyBuffPowerPerAttr[i]);
		addSerializableVariable(kBuffDurationAttrNames[i], &legacyBuffDurationPerAttr[i]);
		addSerializableVariable(kJantaBuffStockAttrNames[i], &legacyJantaBuffStockPerAttr[i]);
		addSerializableVariable(kJantaBuffPowerAttrNames[i], &legacyJantaBuffPowerPerAttr[i]);
		addSerializableVariable(kJantaBuffDurationAttrNames[i], &legacyJantaBuffDurationPerAttr[i]);
	}
	addSerializableVariable("poisonStock", &legacyPoisonStock);
	addSerializableVariable("diseaseStock", &legacyDiseaseStock);
	addSerializableVariable("earningsBalance", &earningsBalance);
	addSerializableVariable("buffPrice", &buffPrice);
	addSerializableVariable("woundPrice", &woundPrice);
	addSerializableVariable("poisonPrice", &poisonPrice);
	addSerializableVariable("diseasePrice", &diseasePrice);
	addSerializableVariable("jantaPrice", &jantaPrice);
	addSerializableVariable("guildDiscountPercent", &guildDiscountPercent);
	addSerializableVariable("minimumPriceFloor", &minimumPriceFloor);
	addSerializableVariable("buffsEnabled", &buffsEnabled);
	addSerializableVariable("woundsEnabled", &woundsEnabled);
	addSerializableVariable("poisonEnabled", &poisonEnabled);
	addSerializableVariable("diseaseEnabled", &diseaseEnabled);
	addSerializableVariable("jantaEnabled", &jantaEnabled);
	addSerializableVariable("poisonPackPower", &legacyPoisonPackPower);
	addSerializableVariable("diseasePackPower", &legacyDiseasePackPower);
	addSerializableVariable("poisonPackDuration", &legacyPoisonPackDuration);
	addSerializableVariable("diseasePackDuration", &legacyDiseasePackDuration);
	addSerializableVariable("ownerHealingMod", &ownerHealingMod);
	addSerializableVariable("bivoliStock", &bivoliStock);
	addSerializableVariable("bivoliStrength", &bivoliStrength);
	addSerializableVariable("bivoliDuration", &bivoliDuration);
	addSerializableVariable("activeBivoliBonus", &activeBivoliBonus);
	addSerializableVariable("activeBivoliExpiresAt", &activeBivoliExpiresAt);
	addSerializableVariable("jantaStock", &jantaStock);
	addSerializableVariable("jantaStrength", &jantaStrength);
	addSerializableVariable("jantaDuration", &jantaDuration);
	addSerializableVariable("activeJantaBonus", &activeJantaBonus);
	addSerializableVariable("activeJantaExpiresAt", &activeJantaExpiresAt);
	addSerializableVariable("adBarkText", &adBarkText);
	addSerializableVariable("adBarkEnabled", &adBarkEnabled);
}

void DoctorBuffDroidDataComponent::writeJSON(nlohmann::json& j) const {
	DataObjectComponent::writeJSON(j);

	SERIALIZE_JSON_MEMBER(ownerId);
	for (int i = 0; i < 9; ++i) {
		j["buffStockAttr" + std::to_string(i)] = legacyBuffStockPerAttr[i];
		j["buffPowerAttr" + std::to_string(i)] = legacyBuffPowerPerAttr[i];
		j["buffDurationAttr" + std::to_string(i)] = legacyBuffDurationPerAttr[i];
		j["jantaBuffStockAttr" + std::to_string(i)] = legacyJantaBuffStockPerAttr[i];
		j["jantaBuffPowerAttr" + std::to_string(i)] = legacyJantaBuffPowerPerAttr[i];
		j["jantaBuffDurationAttr" + std::to_string(i)] = legacyJantaBuffDurationPerAttr[i];
	}
	j["poisonStock"] = legacyPoisonStock;
	j["diseaseStock"] = legacyDiseaseStock;
	SERIALIZE_JSON_MEMBER(earningsBalance);
	SERIALIZE_JSON_MEMBER(buffPrice);
	SERIALIZE_JSON_MEMBER(woundPrice);
	SERIALIZE_JSON_MEMBER(poisonPrice);
	SERIALIZE_JSON_MEMBER(diseasePrice);
	SERIALIZE_JSON_MEMBER(jantaPrice);
	SERIALIZE_JSON_MEMBER(guildDiscountPercent);
	SERIALIZE_JSON_MEMBER(minimumPriceFloor);
	SERIALIZE_JSON_MEMBER(buffsEnabled);
	SERIALIZE_JSON_MEMBER(woundsEnabled);
	SERIALIZE_JSON_MEMBER(poisonEnabled);
	SERIALIZE_JSON_MEMBER(diseaseEnabled);
	SERIALIZE_JSON_MEMBER(jantaEnabled);
	j["poisonPackPower"] = legacyPoisonPackPower;
	j["diseasePackPower"] = legacyDiseasePackPower;
	j["poisonPackDuration"] = legacyPoisonPackDuration;
	j["diseasePackDuration"] = legacyDiseasePackDuration;
	SERIALIZE_JSON_MEMBER(ownerHealingMod);
	SERIALIZE_JSON_MEMBER(bivoliStock);
	SERIALIZE_JSON_MEMBER(bivoliStrength);
	SERIALIZE_JSON_MEMBER(bivoliDuration);
	SERIALIZE_JSON_MEMBER(activeBivoliBonus);
	SERIALIZE_JSON_MEMBER(activeBivoliExpiresAt);
	SERIALIZE_JSON_MEMBER(jantaStock);
	SERIALIZE_JSON_MEMBER(jantaStrength);
	SERIALIZE_JSON_MEMBER(jantaDuration);
	SERIALIZE_JSON_MEMBER(activeJantaBonus);
	SERIALIZE_JSON_MEMBER(activeJantaExpiresAt);
	SERIALIZE_JSON_MEMBER(adBarkText);
	SERIALIZE_JSON_MEMBER(adBarkEnabled);
}

void DoctorBuffDroidDataComponent::initializeTransientMembers() {
	DataObjectComponent::initializeTransientMembers();
}

bool DoctorBuffDroidDataComponent::isOwner(CreatureObject* player) const {
	return player != nullptr && player->getObjectID() == getOwnerId();
}

void DoctorBuffDroidDataComponent::setOwnerId(uint64 id) {
	Locker locker(&dataMutex);
	ownerId = id;
}

uint64 DoctorBuffDroidDataComponent::getOwnerId() const {
	Locker locker(&dataMutex);
	return ownerId;
}

int DoctorBuffDroidDataComponent::getLegacyBuffStock(byte attr) const {
	if (attr >= 9)
		return 0;
	Locker locker(&dataMutex);
	return legacyBuffStockPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getLegacyBuffPower(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return legacyBuffPowerPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getLegacyBuffDuration(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return legacyBuffDurationPerAttr[attr];
}

int DoctorBuffDroidDataComponent::getLegacyJantaBuffStock(byte attr) const {
	if (attr >= 9)
		return 0;
	Locker locker(&dataMutex);
	return legacyJantaBuffStockPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getLegacyJantaBuffPower(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return legacyJantaBuffPowerPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getLegacyJantaBuffDuration(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return legacyJantaBuffDurationPerAttr[attr];
}

int DoctorBuffDroidDataComponent::getLegacyPoisonStock() const {
	Locker locker(&dataMutex);
	return legacyPoisonStock;
}

float DoctorBuffDroidDataComponent::getLegacyPoisonPower() const {
	Locker locker(&dataMutex);
	return legacyPoisonPackPower;
}

float DoctorBuffDroidDataComponent::getLegacyPoisonDuration() const {
	Locker locker(&dataMutex);
	return legacyPoisonPackDuration;
}

int DoctorBuffDroidDataComponent::getLegacyDiseaseStock() const {
	Locker locker(&dataMutex);
	return legacyDiseaseStock;
}

float DoctorBuffDroidDataComponent::getLegacyDiseasePower() const {
	Locker locker(&dataMutex);
	return legacyDiseasePackPower;
}

float DoctorBuffDroidDataComponent::getLegacyDiseaseDuration() const {
	Locker locker(&dataMutex);
	return legacyDiseasePackDuration;
}

bool DoctorBuffDroidDataComponent::hasLegacyStock() const {
	Locker locker(&dataMutex);

	if (legacyPoisonStock > 0 || legacyDiseaseStock > 0)
		return true;

	for (int i = 0; i < 9; ++i) {
		if (legacyBuffStockPerAttr[i] > 0 || legacyJantaBuffStockPerAttr[i] > 0)
			return true;
	}

	return false;
}

void DoctorBuffDroidDataComponent::clearLegacyStock() {
	Locker locker(&dataMutex);

	for (int i = 0; i < 9; ++i) {
		legacyBuffStockPerAttr[i] = 0;
		legacyBuffPowerPerAttr[i] = 0.0f;
		legacyBuffDurationPerAttr[i] = 0.0f;
		legacyJantaBuffStockPerAttr[i] = 0;
		legacyJantaBuffPowerPerAttr[i] = 0.0f;
		legacyJantaBuffDurationPerAttr[i] = 0.0f;
	}

	legacyPoisonStock = 0;
	legacyDiseaseStock = 0;
	legacyPoisonPackPower = 0.0f;
	legacyDiseasePackPower = 0.0f;
	legacyPoisonPackDuration = 0.0f;
	legacyDiseasePackDuration = 0.0f;
}

int DoctorBuffDroidDataComponent::getOwnerHealingMod() const {
	Locker locker(&dataMutex);
	return ownerHealingMod;
}

void DoctorBuffDroidDataComponent::setOwnerHealingMod(int mod) {
	Locker locker(&dataMutex);
	ownerHealingMod = mod;
}

int DoctorBuffDroidDataComponent::getBivoliStock() const {
	Locker locker(&dataMutex);
	return bivoliStock;
}

void DoctorBuffDroidDataComponent::addBivoliStock(int amount, float strength, float duration) {
	if (amount <= 0)
		return;

	Locker locker(&dataMutex);

	if (strength > 0.0f) {
		if (bivoliStock == 0 || bivoliStrength == 0.0f)
			bivoliStrength = strength;
		else
			bivoliStrength = ((bivoliStock * bivoliStrength) + (amount * strength)) / (bivoliStock + amount);
	}

	if (duration > 0.0f) {
		if (bivoliStock == 0 || bivoliDuration == 0.0f)
			bivoliDuration = duration;
		else
			bivoliDuration = ((bivoliStock * bivoliDuration) + (amount * duration)) / (bivoliStock + amount);
	}

	bivoliStock += amount;
}

bool DoctorBuffDroidDataComponent::consumeBivoliStock(int amount, float& strength, float& duration) {
	strength = 0.0f;
	duration = 0.0f;

	if (amount <= 0)
		return true;

	Locker locker(&dataMutex);

	if (bivoliStock < amount)
		return false;

	strength = bivoliStrength;
	duration = bivoliDuration;
	bivoliStock -= amount;

	if (bivoliStock <= 0) {
		bivoliStock = 0;
		bivoliStrength = 0.0f;
		bivoliDuration = 0.0f;
	}

	return true;
}

void DoctorBuffDroidDataComponent::activateBivoli(float strength, float duration, uint64 nowMs) {
	Locker locker(&dataMutex);

	activeBivoliBonus = Math::max(0, (int) (strength + 0.5f));
	activeBivoliExpiresAt = (duration > 0.0f && nowMs > 0) ? nowMs + (uint64) (duration * 1000.0f + 0.5f) : 0;

	if (activeBivoliExpiresAt == 0)
		activeBivoliBonus = 0;
}

int DoctorBuffDroidDataComponent::getActiveBivoliBonus(uint64 nowMs) const {
	Locker locker(&dataMutex);

	if (activeBivoliBonus <= 0 || activeBivoliExpiresAt == 0)
		return 0;

	if (nowMs > 0 && nowMs >= activeBivoliExpiresAt)
		return 0;

	return activeBivoliBonus;
}

uint64 DoctorBuffDroidDataComponent::getActiveBivoliExpiresAt() const {
	Locker locker(&dataMutex);
	return activeBivoliExpiresAt;
}

float DoctorBuffDroidDataComponent::getActiveBivoliTimeRemaining(uint64 nowMs) const {
	Locker locker(&dataMutex);

	if (activeBivoliBonus <= 0 || activeBivoliExpiresAt == 0 || nowMs >= activeBivoliExpiresAt)
		return 0.0f;

	return (activeBivoliExpiresAt - nowMs) / 1000.0f;
}

int DoctorBuffDroidDataComponent::getJantaStock() const {
	Locker locker(&dataMutex);
	return jantaStock;
}

void DoctorBuffDroidDataComponent::addJantaStock(int amount, float strength, float duration) {
	if (amount <= 0)
		return;

	Locker locker(&dataMutex);

	if (strength > 0.0f) {
		if (jantaStock == 0 || jantaStrength == 0.0f)
			jantaStrength = strength;
		else
			jantaStrength = ((jantaStock * jantaStrength) + (amount * strength)) / (jantaStock + amount);
	}

	if (duration > 0.0f) {
		if (jantaStock == 0 || jantaDuration == 0.0f)
			jantaDuration = duration;
		else
			jantaDuration = ((jantaStock * jantaDuration) + (amount * duration)) / (jantaStock + amount);
	}

	jantaStock += amount;
}

bool DoctorBuffDroidDataComponent::consumeJantaStock(int amount, float& strength, float& duration) {
	strength = 0.0f;
	duration = 0.0f;

	if (amount <= 0)
		return true;

	Locker locker(&dataMutex);

	if (jantaStock < amount)
		return false;

	strength = jantaStrength;
	duration = jantaDuration;
	jantaStock -= amount;

	if (jantaStock <= 0) {
		jantaStock = 0;
		jantaStrength = 0.0f;
		jantaDuration = 0.0f;
	}

	return true;
}

void DoctorBuffDroidDataComponent::activateJanta(float strength, float duration, uint64 nowMs) {
	Locker locker(&dataMutex);

	activeJantaBonus = Math::max(0, (int) (strength + 0.5f));
	activeJantaExpiresAt = (duration > 0.0f && nowMs > 0) ? nowMs + (uint64) (duration * 1000.0f + 0.5f) : 0;

	if (activeJantaExpiresAt == 0)
		activeJantaBonus = 0;
}

int DoctorBuffDroidDataComponent::getActiveJantaBonus(uint64 nowMs) const {
	Locker locker(&dataMutex);

	if (activeJantaBonus <= 0 || activeJantaExpiresAt == 0)
		return 0;

	if (nowMs > 0 && nowMs >= activeJantaExpiresAt)
		return 0;

	return activeJantaBonus;
}

uint64 DoctorBuffDroidDataComponent::getActiveJantaExpiresAt() const {
	Locker locker(&dataMutex);
	return activeJantaExpiresAt;
}

float DoctorBuffDroidDataComponent::getActiveJantaTimeRemaining(uint64 nowMs) const {
	Locker locker(&dataMutex);

	if (activeJantaBonus <= 0 || activeJantaExpiresAt == 0 || nowMs >= activeJantaExpiresAt)
		return 0.0f;

	return (activeJantaExpiresAt - nowMs) / 1000.0f;
}

int DoctorBuffDroidDataComponent::getPrice(ServiceType type) const {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_BUFFS:
		return buffPrice;
	case SERVICE_WOUNDS:
		return woundPrice;
	case SERVICE_POISON:
		return poisonPrice;
	case SERVICE_DISEASE:
		return diseasePrice;
	case SERVICE_JANTA:
		return jantaPrice;
	default:
		return diseasePrice;
	}
}

void DoctorBuffDroidDataComponent::setPrice(ServiceType type, int value) {
	Locker locker(&dataMutex);
	value = Math::max(minimumPriceFloor, value);

	switch (type) {
	case SERVICE_BUFFS:
		buffPrice = value;
		break;
	case SERVICE_WOUNDS:
		woundPrice = value;
		break;
	case SERVICE_POISON:
		poisonPrice = value;
		break;
	case SERVICE_DISEASE:
		diseasePrice = value;
		break;
	case SERVICE_JANTA:
		jantaPrice = value;
		break;
	}
}

int DoctorBuffDroidDataComponent::getDiscountedPrice(ServiceType type, CreatureObject* buyer) const {
	int price = getPrice(type);

	if (buyer == nullptr)
		return price;

	Locker locker(&dataMutex);

	if (guildDiscountPercent <= 0 || ownerId == 0)
		return price;

	if (buyer->getObjectID() == ownerId)
		return minimumPriceFloor;

	GuildObject* buyerGuild = buyer->getGuildObject().get();
	if (buyerGuild == nullptr)
		return price;

	SceneObject* strongParent = const_cast<DoctorBuffDroidDataComponent*>(this)->getParent();
	if (strongParent == nullptr || strongParent->getZoneServer() == nullptr)
		return price;

	CreatureObject* owner = strongParent->getZoneServer()->getObject(ownerId).castTo<CreatureObject*>();
	if (owner == nullptr)
		return price;

	GuildObject* ownerGuild = owner->getGuildObject().get();
	if (ownerGuild == nullptr || ownerGuild->getObjectID() != buyerGuild->getObjectID())
		return price;

	int discounted = price - ((price * guildDiscountPercent) / 100);
	return Math::max(minimumPriceFloor, discounted);
}

bool DoctorBuffDroidDataComponent::isServiceEnabled(ServiceType type) const {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_BUFFS:
		return buffsEnabled;
	case SERVICE_WOUNDS:
		return woundsEnabled;
	case SERVICE_POISON:
		return poisonEnabled;
	case SERVICE_DISEASE:
		return diseaseEnabled;
	case SERVICE_JANTA:
		return jantaEnabled;
	default:
		return diseaseEnabled;
	}
}

void DoctorBuffDroidDataComponent::setServiceEnabled(ServiceType type, bool enabled) {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_BUFFS:
		buffsEnabled = enabled;
		break;
	case SERVICE_WOUNDS:
		woundsEnabled = enabled;
		break;
	case SERVICE_POISON:
		poisonEnabled = enabled;
		break;
	case SERVICE_DISEASE:
		diseaseEnabled = enabled;
		break;
	case SERVICE_JANTA:
		jantaEnabled = enabled;
		break;
	}
}

void DoctorBuffDroidDataComponent::toggleService(ServiceType type) {
	setServiceEnabled(type, !isServiceEnabled(type));
}

int DoctorBuffDroidDataComponent::getGuildDiscountPercent() const {
	Locker locker(&dataMutex);
	return guildDiscountPercent;
}

void DoctorBuffDroidDataComponent::setGuildDiscountPercent(int percent) {
	Locker locker(&dataMutex);
	guildDiscountPercent = Math::max(0, Math::min(90, percent));
}

int DoctorBuffDroidDataComponent::getEarningsBalance() const {
	Locker locker(&dataMutex);
	return earningsBalance;
}

void DoctorBuffDroidDataComponent::addEarnings(int amount) {
	if (amount <= 0)
		return;

	Locker locker(&dataMutex);
	earningsBalance += amount;
}

int DoctorBuffDroidDataComponent::withdrawEarnings() {
	Locker locker(&dataMutex);
	int value = earningsBalance;
	earningsBalance = 0;
	return value;
}

int DoctorBuffDroidDataComponent::getMinimumPriceFloor() const {
	Locker locker(&dataMutex);
	return minimumPriceFloor;
}

String DoctorBuffDroidDataComponent::getAdBarkText() const {
	Locker locker(&dataMutex);
	return adBarkText;
}

void DoctorBuffDroidDataComponent::setAdBarkText(const String& text) {
	Locker locker(&dataMutex);
	adBarkText = text;
}

bool DoctorBuffDroidDataComponent::isAdBarkEnabled() const {
	Locker locker(&dataMutex);
	return adBarkEnabled;
}

void DoctorBuffDroidDataComponent::setAdBarkEnabled(bool enabled) {
	Locker locker(&dataMutex);
	adBarkEnabled = enabled;
}

bool DoctorBuffDroidDataComponent::canBarkAtPlayer(uint64 playerOid, uint64 nowMs) const {
	Locker locker(&dataMutex);
	if (!barkCooldowns.contains(playerOid))
		return true;
	uint64 lastTime = barkCooldowns.get(playerOid);
	return (nowMs - lastTime) >= BARK_COOLDOWN_MS;
}

void DoctorBuffDroidDataComponent::recordBark(uint64 playerOid, uint64 nowMs) {
	Locker locker(&dataMutex);
	barkCooldowns.put(playerOid, nowMs);
}
