#include "ImageDesignStationDataComponent.h"

ImageDesignStationDataComponent::ImageDesignStationDataComponent()
	: DataObjectComponent(), dataMutex() {

	ownerId = 0;
	ownerGuildId = 0;
	hairSkill = 0;
	faceSkill = 0;
	bodySkill = 0;
	markingsSkill = 0;
	servicePrice = 10000;
	lifetimeSessions = 0;
	lifetimeRevenue = 0;

	addSerializableVariable("ownerId", &ownerId);
	addSerializableVariable("ownerGuildId", &ownerGuildId);
	addSerializableVariable("hairSkill", &hairSkill);
	addSerializableVariable("faceSkill", &faceSkill);
	addSerializableVariable("bodySkill", &bodySkill);
	addSerializableVariable("markingsSkill", &markingsSkill);
	addSerializableVariable("servicePrice", &servicePrice);
	addSerializableVariable("lifetimeSessions", &lifetimeSessions);
	addSerializableVariable("lifetimeRevenue", &lifetimeRevenue);
}

void ImageDesignStationDataComponent::initializeTransientMembers() {
	DataObjectComponent::initializeTransientMembers();
}

void ImageDesignStationDataComponent::writeJSON(nlohmann::json& j) const {
	DataObjectComponent::writeJSON(j);
	SERIALIZE_JSON_MEMBER(ownerId);
	SERIALIZE_JSON_MEMBER(ownerGuildId);
	SERIALIZE_JSON_MEMBER(hairSkill);
	SERIALIZE_JSON_MEMBER(faceSkill);
	SERIALIZE_JSON_MEMBER(bodySkill);
	SERIALIZE_JSON_MEMBER(markingsSkill);
	SERIALIZE_JSON_MEMBER(servicePrice);
	SERIALIZE_JSON_MEMBER(lifetimeSessions);
	SERIALIZE_JSON_MEMBER(lifetimeRevenue);
}

bool ImageDesignStationDataComponent::isOwner(CreatureObject* player) const {
	return player != nullptr && player->getObjectID() == getOwnerId();
}

void ImageDesignStationDataComponent::setOwnerId(uint64 id) {
	Locker locker(&dataMutex);
	ownerId = id;
}

uint64 ImageDesignStationDataComponent::getOwnerId() const {
	Locker locker(&dataMutex);
	return ownerId;
}

void ImageDesignStationDataComponent::setOwnerGuildId(uint64 id) {
	Locker locker(&dataMutex);
	ownerGuildId = id;
}

uint64 ImageDesignStationDataComponent::getOwnerGuildId() const {
	Locker locker(&dataMutex);
	return ownerGuildId;
}

void ImageDesignStationDataComponent::snapshotSkills(CreatureObject* owner) {
	if (owner == nullptr)
		return;

	int newHair = owner->getSkillMod("hair");
	int newFace = owner->getSkillMod("face");
	int newBody = owner->getSkillMod("body");
	int newMarkings = owner->getSkillMod("markings");

	Locker locker(&dataMutex);
	hairSkill = Math::max(0, newHair);
	faceSkill = Math::max(0, newFace);
	bodySkill = Math::max(0, newBody);
	markingsSkill = Math::max(0, newMarkings);
}

int ImageDesignStationDataComponent::getHairSkill() const {
	Locker locker(&dataMutex);
	return hairSkill;
}

int ImageDesignStationDataComponent::getFaceSkill() const {
	Locker locker(&dataMutex);
	return faceSkill;
}

int ImageDesignStationDataComponent::getBodySkill() const {
	Locker locker(&dataMutex);
	return bodySkill;
}

int ImageDesignStationDataComponent::getMarkingsSkill() const {
	Locker locker(&dataMutex);
	return markingsSkill;
}

void ImageDesignStationDataComponent::setServicePrice(int price) {
	Locker locker(&dataMutex);
	servicePrice = Math::max(0, price);
}

int ImageDesignStationDataComponent::getServicePrice() const {
	Locker locker(&dataMutex);
	return servicePrice;
}

void ImageDesignStationDataComponent::recordCompletedSession(int revenue) {
	Locker locker(&dataMutex);
	++lifetimeSessions;
	if (revenue > 0)
		lifetimeRevenue += (uint64)revenue;
}

uint64 ImageDesignStationDataComponent::getLifetimeSessions() const {
	Locker locker(&dataMutex);
	return lifetimeSessions;
}

uint64 ImageDesignStationDataComponent::getLifetimeRevenue() const {
	Locker locker(&dataMutex);
	return lifetimeRevenue;
}
