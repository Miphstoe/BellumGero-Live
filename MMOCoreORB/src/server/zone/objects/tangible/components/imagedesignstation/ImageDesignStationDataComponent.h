#ifndef IMAGEDESIGNSTATIONDATACOMPONENT_H_
#define IMAGEDESIGNSTATIONDATACOMPONENT_H_

#include "server/zone/objects/scene/components/DataObjectComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"

class ImageDesignStationDataComponent : public DataObjectComponent {
private:
	uint64 ownerId;
	uint64 ownerGuildId;
	int hairSkill;
	int faceSkill;
	int bodySkill;
	int markingsSkill;
	int servicePrice;
	uint64 lifetimeSessions;
	uint64 lifetimeRevenue;
	mutable Mutex dataMutex;

public:
	ImageDesignStationDataComponent();

	void writeJSON(nlohmann::json& j) const override;
	void initializeTransientMembers() override;

	bool isOwner(CreatureObject* player) const;

	void setOwnerId(uint64 id);
	uint64 getOwnerId() const;

	void setOwnerGuildId(uint64 id);
	uint64 getOwnerGuildId() const;

	void snapshotSkills(CreatureObject* owner);
	int getHairSkill() const;
	int getFaceSkill() const;
	int getBodySkill() const;
	int getMarkingsSkill() const;

	void setServicePrice(int price);
	int getServicePrice() const;

	void recordCompletedSession(int revenue);
	uint64 getLifetimeSessions() const;
	uint64 getLifetimeRevenue() const;
};

#endif
