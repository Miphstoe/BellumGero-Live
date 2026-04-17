#ifndef DOCTORBUFFDROIDDATACOMPONENT_H_
#define DOCTORBUFFDROIDDATACOMPONENT_H_

#include "server/zone/objects/scene/components/DataObjectComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"

class DoctorBuffDroidDataComponent : public DataObjectComponent {
public:
	enum ServiceType {
		SERVICE_BUFFS = 0,
		SERVICE_WOUNDS = 1,
		SERVICE_POISON = 2,
		SERVICE_DISEASE = 3
	};

private:
	uint64 ownerId;

	int buffStock;
	int poisonStock;
	int diseaseStock;
	int earningsBalance;

	int buffPrice;
	int woundPrice;
	int poisonPrice;
	int diseasePrice;

	int guildDiscountPercent;
	int minimumPriceFloor;

	bool buffsEnabled;
	bool woundsEnabled;
	bool poisonEnabled;
	bool diseaseEnabled;

	// Weighted-average pack effectiveness and duration, updated when supplies are loaded
	float buffPackPower;
	float poisonPackPower;
	float diseasePackPower;

	float buffPackDuration;
	float poisonPackDuration;
	float diseasePackDuration;

	// Bitmask of BuffAttribute values (bit N = attribute N loaded), cleared when buffStock hits 0
	uint32 loadedBuffAttributes;

	// Cached owner healing_wound_treatment skill mod, updated when supplies are loaded
	int ownerHealingMod;

	mutable Mutex dataMutex;

public:
	DoctorBuffDroidDataComponent();

	void writeJSON(nlohmann::json& j) const override;
	void initializeTransientMembers() override;

	bool isDoctorBuffDroidData() override {
		return true;
	}

	bool isOwner(CreatureObject* player) const;
	void setOwnerId(uint64 id);
	uint64 getOwnerId() const;

	int getStock(ServiceType type) const;
	// effectiveness/duration from the pack; weighted averages stored for buff calculation
	// attr = BuffAttribute value (0-8 for HAM stats); ignored for non-BUFFS types
	void addStock(ServiceType type, int amount, float effectiveness = 0.0f, byte attr = 0, float duration = 0.0f);
	bool consumeStock(ServiceType type, int amount = 1);

	uint32 getLoadedBuffAttributes() const;
	float getPackDuration(ServiceType type) const;

	// Returns the stored weighted-average pack effectiveness for a service type
	float getPackPower(ServiceType type) const;

	int getOwnerHealingMod() const;
	void setOwnerHealingMod(int mod);

	int getPrice(ServiceType type) const;
	void setPrice(ServiceType type, int value);
	int getDiscountedPrice(ServiceType type, CreatureObject* buyer) const;

	bool isServiceEnabled(ServiceType type) const;
	void setServiceEnabled(ServiceType type, bool enabled);
	void toggleService(ServiceType type);

	int getGuildDiscountPercent() const;
	void setGuildDiscountPercent(int percent);

	int getEarningsBalance() const;
	void addEarnings(int amount);
	int withdrawEarnings();

	int getMinimumPriceFloor() const;
};

#endif
