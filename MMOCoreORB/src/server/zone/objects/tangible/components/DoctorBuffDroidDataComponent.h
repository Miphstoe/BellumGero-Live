#ifndef DOCTORBUFFDROIDDATACOMPONENT_H_
#define DOCTORBUFFDROIDDATACOMPONENT_H_

#include "server/zone/objects/scene/components/DataObjectComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "system/util/VectorMap.h"

class DoctorBuffDroidDataComponent : public DataObjectComponent {
public:
	enum ServiceType {
		SERVICE_BUFFS = 0,
		SERVICE_WOUNDS = 1,
		SERVICE_POISON = 2,
		SERVICE_DISEASE = 3,
		SERVICE_JANTA = 4
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
	int jantaPrice;

	int guildDiscountPercent;
	int minimumPriceFloor;

	bool buffsEnabled;
	bool woundsEnabled;
	bool poisonEnabled;
	bool diseaseEnabled;
	bool jantaEnabled;

	// Per-stat buff storage — index is BuffAttribute value (0=Health … 8=Willpower)
	int buffStockPerAttr[9];
	float buffPackPowerPerAttr[9];
	float buffPackDurationPerAttr[9];
	int jantaBuffStockPerAttr[9];
	float jantaBuffPackPowerPerAttr[9];
	float jantaBuffPackDurationPerAttr[9];

	// Weighted-average pack effectiveness and duration for poison/disease
	float poisonPackPower;
	float diseasePackPower;

	float poisonPackDuration;
	float diseasePackDuration;

	// Cached owner healing_wound_treatment skill mod, updated when supplies are loaded
	int ownerHealingMod;

	// Loaded Bivoli Tempari charges are stored separately from medpacks.
	int bivoliStock;
	float bivoliStrength;
	float bivoliDuration;
	int activeBivoliBonus;
	uint64 activeBivoliExpiresAt;

	int jantaStock;
	float jantaStrength;
	float jantaDuration;
	int activeJantaBonus;
	uint64 activeJantaExpiresAt;

	// Ad barking
	SerializableString adBarkText;
	bool adBarkEnabled;
	VectorMap<uint64, uint64> barkCooldowns; // transient: playerOid -> last bark time (ms)

	mutable Mutex dataMutex;

public:
	static constexpr float BARK_RANGE = 20.0f;
	static constexpr uint64 BARK_COOLDOWN_MS = 60000ULL;
	DoctorBuffDroidDataComponent();

	void writeJSON(nlohmann::json& j) const override;
	void initializeTransientMembers() override;

	bool isDoctorBuffDroidData() override {
		return true;
	}

	bool isOwner(CreatureObject* player) const;
	void setOwnerId(uint64 id);
	uint64 getOwnerId() const;

	// Returns total charges for BUFFS (sum across all attrs), or stock for POISON/DISEASE
	int getStock(ServiceType type) const;
	// attr = BuffAttribute value (0-8); used for SERVICE_BUFFS to track per-stat stock
	void addStock(ServiceType type, int amount, float effectiveness = 0.0f, byte attr = 0, float duration = 0.0f);

	// Per-stat buff queries (attr = BuffAttribute value 0-8)
	int getBuffStockByAttr(byte attr) const;
	float getBuffPackPowerByAttr(byte attr) const;
	float getBuffPackDurationByAttr(byte attr) const;
	bool consumeBuffStock(byte attr, int amount = 1);
	int getJantaBuffStockByAttr(byte attr) const;
	float getJantaBuffPackPowerByAttr(byte attr) const;
	float getJantaBuffPackDurationByAttr(byte attr) const;
	bool consumeJantaBuffStock(byte attr, int amount = 1);

	// Bitmask of which attrs have stock > 0; bit N set ↔ buffStockPerAttr[N] > 0
	uint32 getLoadedBuffAttributes() const;
	uint32 getLoadedJantaBuffAttributes() const;

	// Poison/disease only — returns the stored weighted-average pack effectiveness
	float getPackPower(ServiceType type) const;
	float getPackDuration(ServiceType type) const;

	// Consume stock for POISON or DISEASE (not BUFFS — use consumeBuffStock for those)
	bool consumeStock(ServiceType type, int amount = 1);

	int getOwnerHealingMod() const;
	void setOwnerHealingMod(int mod);

	int getBivoliStock() const;
	void addBivoliStock(int amount, float strength, float duration);
	bool consumeBivoliStock(int amount, float& strength, float& duration);
	void activateBivoli(float strength, float duration, uint64 nowMs);
	int getActiveBivoliBonus(uint64 nowMs) const;
	uint64 getActiveBivoliExpiresAt() const;
	float getActiveBivoliTimeRemaining(uint64 nowMs) const;

	int getJantaStock() const;
	void addJantaStock(int amount, float strength, float duration);
	bool consumeJantaStock(int amount, float& strength, float& duration);
	void activateJanta(float strength, float duration, uint64 nowMs);
	int getActiveJantaBonus(uint64 nowMs) const;
	uint64 getActiveJantaExpiresAt() const;
	float getActiveJantaTimeRemaining(uint64 nowMs) const;

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

	String getAdBarkText() const;
	void setAdBarkText(const String& text);
	bool isAdBarkEnabled() const;
	void setAdBarkEnabled(bool enabled);
	bool canBarkAtPlayer(uint64 playerOid, uint64 nowMs) const;
	void recordBark(uint64 playerOid, uint64 nowMs);
};

#endif
