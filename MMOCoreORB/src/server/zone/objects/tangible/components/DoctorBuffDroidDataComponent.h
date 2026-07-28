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

	// Legacy pooled/averaged buff storage — index is BuffAttribute value (0=Health … 8=Willpower).
	// Superseded by real items sitting in the droid's own container (see DoctorBuffDroidMenuComponent),
	// which store each loaded pack's true power/duration instead of blending them into an average.
	// These fields are kept only so any pre-upgrade stock on a live droid can be migrated once
	// (materialized into a real item, then zeroed via clearLegacyStock()) — see getLegacy*/hasLegacyStock.
	int legacyBuffStockPerAttr[9];
	float legacyBuffPowerPerAttr[9];
	float legacyBuffDurationPerAttr[9];
	int legacyJantaBuffStockPerAttr[9];
	float legacyJantaBuffPowerPerAttr[9];
	float legacyJantaBuffDurationPerAttr[9];

	// Legacy weighted-average pack effectiveness/duration for poison/disease
	int legacyPoisonStock;
	int legacyDiseaseStock;
	float legacyPoisonPackPower;
	float legacyDiseasePackPower;
	float legacyPoisonPackDuration;
	float legacyDiseasePackDuration;

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

	// Legacy pre-upgrade stock migration only. Real stock now lives as actual items in the
	// droid's own container (see DoctorBuffDroidMenuComponent); these accessors exist solely so
	// migrateLegacyStock() can read any pre-upgrade averaged stock once, materialize it into a
	// real item, and zero it out via clearLegacyStock().
	int getLegacyBuffStock(byte attr) const;
	float getLegacyBuffPower(byte attr) const;
	float getLegacyBuffDuration(byte attr) const;
	int getLegacyJantaBuffStock(byte attr) const;
	float getLegacyJantaBuffPower(byte attr) const;
	float getLegacyJantaBuffDuration(byte attr) const;
	int getLegacyPoisonStock() const;
	float getLegacyPoisonPower() const;
	float getLegacyPoisonDuration() const;
	int getLegacyDiseaseStock() const;
	float getLegacyDiseasePower() const;
	float getLegacyDiseaseDuration() const;
	bool hasLegacyStock() const;
	void clearLegacyStock();

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
