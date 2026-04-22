#include "DoctorBuffDroidDataComponent.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/scene/SceneObject.h"

namespace {
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
}

DoctorBuffDroidDataComponent::DoctorBuffDroidDataComponent() : DataObjectComponent(), dataMutex() {
	ownerId = 0;

	for (int i = 0; i < 9; ++i) {
		buffStockPerAttr[i] = 0;
		buffPackPowerPerAttr[i] = 0.0f;
		buffPackDurationPerAttr[i] = 0.0f;
	}

	poisonStock = 0;
	diseaseStock = 0;
	earningsBalance = 0;

	buffPrice = 5000;
	woundPrice = 1000;
	poisonPrice = 2500;
	diseasePrice = 2500;

	guildDiscountPercent = 0;
	minimumPriceFloor = 100;

	buffsEnabled = true;
	woundsEnabled = true;
	poisonEnabled = true;
	diseaseEnabled = true;

	poisonPackPower = 0.0f;
	diseasePackPower = 0.0f;
	poisonPackDuration = 0.0f;
	diseasePackDuration = 0.0f;
	ownerHealingMod = 100;
	bivoliStock = 0;
	bivoliStrength = 0.0f;
	bivoliDuration = 0.0f;
	activeBivoliBonus = 0;
	activeBivoliExpiresAt = 0;

	addSerializableVariable("ownerId", &ownerId);
	for (int i = 0; i < 9; ++i) {
		addSerializableVariable(kBuffStockAttrNames[i], &buffStockPerAttr[i]);
		addSerializableVariable(kBuffPowerAttrNames[i], &buffPackPowerPerAttr[i]);
		addSerializableVariable(kBuffDurationAttrNames[i], &buffPackDurationPerAttr[i]);
	}
	addSerializableVariable("poisonStock", &poisonStock);
	addSerializableVariable("diseaseStock", &diseaseStock);
	addSerializableVariable("earningsBalance", &earningsBalance);
	addSerializableVariable("buffPrice", &buffPrice);
	addSerializableVariable("woundPrice", &woundPrice);
	addSerializableVariable("poisonPrice", &poisonPrice);
	addSerializableVariable("diseasePrice", &diseasePrice);
	addSerializableVariable("guildDiscountPercent", &guildDiscountPercent);
	addSerializableVariable("minimumPriceFloor", &minimumPriceFloor);
	addSerializableVariable("buffsEnabled", &buffsEnabled);
	addSerializableVariable("woundsEnabled", &woundsEnabled);
	addSerializableVariable("poisonEnabled", &poisonEnabled);
	addSerializableVariable("diseaseEnabled", &diseaseEnabled);
	addSerializableVariable("poisonPackPower", &poisonPackPower);
	addSerializableVariable("diseasePackPower", &diseasePackPower);
	addSerializableVariable("poisonPackDuration", &poisonPackDuration);
	addSerializableVariable("diseasePackDuration", &diseasePackDuration);
	addSerializableVariable("ownerHealingMod", &ownerHealingMod);
	addSerializableVariable("bivoliStock", &bivoliStock);
	addSerializableVariable("bivoliStrength", &bivoliStrength);
	addSerializableVariable("bivoliDuration", &bivoliDuration);
	addSerializableVariable("activeBivoliBonus", &activeBivoliBonus);
	addSerializableVariable("activeBivoliExpiresAt", &activeBivoliExpiresAt);
}

void DoctorBuffDroidDataComponent::writeJSON(nlohmann::json& j) const {
	DataObjectComponent::writeJSON(j);

	SERIALIZE_JSON_MEMBER(ownerId);
	for (int i = 0; i < 9; ++i) {
		j["buffStockAttr" + std::to_string(i)] = buffStockPerAttr[i];
		j["buffPowerAttr" + std::to_string(i)] = buffPackPowerPerAttr[i];
		j["buffDurationAttr" + std::to_string(i)] = buffPackDurationPerAttr[i];
	}
	SERIALIZE_JSON_MEMBER(poisonStock);
	SERIALIZE_JSON_MEMBER(diseaseStock);
	SERIALIZE_JSON_MEMBER(earningsBalance);
	SERIALIZE_JSON_MEMBER(buffPrice);
	SERIALIZE_JSON_MEMBER(woundPrice);
	SERIALIZE_JSON_MEMBER(poisonPrice);
	SERIALIZE_JSON_MEMBER(diseasePrice);
	SERIALIZE_JSON_MEMBER(guildDiscountPercent);
	SERIALIZE_JSON_MEMBER(minimumPriceFloor);
	SERIALIZE_JSON_MEMBER(buffsEnabled);
	SERIALIZE_JSON_MEMBER(woundsEnabled);
	SERIALIZE_JSON_MEMBER(poisonEnabled);
	SERIALIZE_JSON_MEMBER(diseaseEnabled);
	SERIALIZE_JSON_MEMBER(poisonPackPower);
	SERIALIZE_JSON_MEMBER(diseasePackPower);
	SERIALIZE_JSON_MEMBER(poisonPackDuration);
	SERIALIZE_JSON_MEMBER(diseasePackDuration);
	SERIALIZE_JSON_MEMBER(ownerHealingMod);
	SERIALIZE_JSON_MEMBER(bivoliStock);
	SERIALIZE_JSON_MEMBER(bivoliStrength);
	SERIALIZE_JSON_MEMBER(bivoliDuration);
	SERIALIZE_JSON_MEMBER(activeBivoliBonus);
	SERIALIZE_JSON_MEMBER(activeBivoliExpiresAt);
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

int DoctorBuffDroidDataComponent::getStock(ServiceType type) const {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_BUFFS: {
		int total = 0;
		for (int i = 0; i < 9; ++i)
			total += buffStockPerAttr[i];
		return total;
	}
	case SERVICE_POISON:
		return poisonStock;
	case SERVICE_DISEASE:
		return diseaseStock;
	case SERVICE_WOUNDS:
	default:
		return 0;
	}
}

float DoctorBuffDroidDataComponent::getPackDuration(ServiceType type) const {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_POISON:
		return poisonPackDuration;
	case SERVICE_DISEASE:
		return diseasePackDuration;
	default:
		return 0.0f;
	}
}

uint32 DoctorBuffDroidDataComponent::getLoadedBuffAttributes() const {
	Locker locker(&dataMutex);
	uint32 mask = 0;
	for (uint8 i = 0; i < 9; ++i) {
		if (buffStockPerAttr[i] > 0)
			mask |= (1u << i);
	}
	return mask;
}

int DoctorBuffDroidDataComponent::getBuffStockByAttr(byte attr) const {
	if (attr >= 9)
		return 0;
	Locker locker(&dataMutex);
	return buffStockPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getBuffPackPowerByAttr(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return buffPackPowerPerAttr[attr];
}

float DoctorBuffDroidDataComponent::getBuffPackDurationByAttr(byte attr) const {
	if (attr >= 9)
		return 0.0f;
	Locker locker(&dataMutex);
	return buffPackDurationPerAttr[attr];
}

bool DoctorBuffDroidDataComponent::consumeBuffStock(byte attr, int amount) {
	if (attr >= 9 || amount <= 0)
		return true;
	Locker locker(&dataMutex);
	if (buffStockPerAttr[attr] < amount)
		return false;
	buffStockPerAttr[attr] -= amount;
	return true;
}

void DoctorBuffDroidDataComponent::addStock(ServiceType type, int amount, float effectiveness, byte attr, float duration) {
	if (amount <= 0)
		return;

	Locker locker(&dataMutex);

	if (type == SERVICE_BUFFS) {
		if (attr >= 9)
			return;

		int& stock   = buffStockPerAttr[attr];
		float& power = buffPackPowerPerAttr[attr];
		float& dur   = buffPackDurationPerAttr[attr];

		if (effectiveness > 0.0f) {
			if (stock == 0 || power == 0.0f)
				power = effectiveness;
			else
				power = ((stock * power) + (amount * effectiveness)) / (stock + amount);
		}

		if (duration > 0.0f) {
			if (stock == 0 || dur == 0.0f)
				dur = duration;
			else
				dur = ((stock * dur) + (amount * duration)) / (stock + amount);
		}

		stock += amount;
		return;
	}

	int* stock = nullptr;
	float* power = nullptr;
	float* dur = nullptr;

	switch (type) {
	case SERVICE_POISON:
		stock = &poisonStock;
		power = &poisonPackPower;
		dur   = &poisonPackDuration;
		break;
	case SERVICE_DISEASE:
		stock = &diseaseStock;
		power = &diseasePackPower;
		dur   = &diseasePackDuration;
		break;
	default:
		return;
	}

	if (effectiveness > 0.0f) {
		if (*stock == 0 || *power == 0.0f)
			*power = effectiveness;
		else
			*power = ((*stock * *power) + (amount * effectiveness)) / (*stock + amount);
	}

	if (duration > 0.0f) {
		if (*stock == 0 || *dur == 0.0f)
			*dur = duration;
		else
			*dur = ((*stock * *dur) + (amount * duration)) / (*stock + amount);
	}

	*stock += amount;
}

float DoctorBuffDroidDataComponent::getPackPower(ServiceType type) const {
	Locker locker(&dataMutex);

	switch (type) {
	case SERVICE_POISON:
		return poisonPackPower;
	case SERVICE_DISEASE:
		return diseasePackPower;
	default:
		return 0.0f;
	}
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

bool DoctorBuffDroidDataComponent::consumeStock(ServiceType type, int amount) {
	if (amount <= 0)
		return true;

	Locker locker(&dataMutex);
	int* stock = nullptr;

	switch (type) {
	case SERVICE_POISON:
		stock = &poisonStock;
		break;
	case SERVICE_DISEASE:
		stock = &diseaseStock;
		break;
	default:
		return true;
	}

	if (*stock < amount)
		return false;

	*stock -= amount;
	return true;
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
