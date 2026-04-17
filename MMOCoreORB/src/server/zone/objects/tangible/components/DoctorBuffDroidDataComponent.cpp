#include "DoctorBuffDroidDataComponent.h"
#include <cstdio>
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/scene/SceneObject.h"

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

	addSerializableVariable("ownerId", &ownerId);
	{
		char name[32];
		for (int i = 0; i < 9; ++i) {
			snprintf(name, sizeof(name), "buffStockAttr%d", i);
			addSerializableVariable(name, &buffStockPerAttr[i]);
			snprintf(name, sizeof(name), "buffPowerAttr%d", i);
			addSerializableVariable(name, &buffPackPowerPerAttr[i]);
			snprintf(name, sizeof(name), "buffDurationAttr%d", i);
			addSerializableVariable(name, &buffPackDurationPerAttr[i]);
		}
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
