#include "server/login/account/GalaxyAccountInfo.h"

#include "engine/util/json_utils.h"

GalaxyAccountInfo::GalaxyAccountInfo() {
	bankCredits = 0;
}

void GalaxyAccountInfo::updateVetRewardsFromPlayer(const VectorMap<unsigned int, String>& newRewards) {
	if (chosenVeteranRewards.size() == 0) {
		for (const auto& element : newRewards) {
			chosenVeteranRewards.put(element.getKey(), element.getValue());
		}
	}
}
void GalaxyAccountInfo::clearVeteranReward(uint32 milestone) {
	if (chosenVeteranRewards.contains(milestone))
		chosenVeteranRewards.drop( milestone );
}

bool GalaxyAccountInfo::hasChosenVeteranReward(const String& rewardTemplate) const {
	for (int i = 0; i < chosenVeteranRewards.size(); i++) {
		if (rewardTemplate == chosenVeteranRewards.get(i)) {
			return true;
		}
	}

	return false;
}

void GalaxyAccountInfo::addChosenVeteranReward( uint32 milestone, const String& rewardTemplate ) {
	chosenVeteranRewards.put(milestone, rewardTemplate);
}

String GalaxyAccountInfo::getChosenVeteranReward(uint32 milestone) const {
	return chosenVeteranRewards.get(milestone);
}

// Shared bank credits methods
int GalaxyAccountInfo::getBankCredits() const {
	return bankCredits;
}

void GalaxyAccountInfo::setBankCredits(int credits) {
	// Cap at 2 billion (credit limit)
	if (credits > 2000000000)
		credits = 2000000000;

	if (credits < 0)
		credits = 0;

	bankCredits = credits;
}

void GalaxyAccountInfo::addBankCredits(int credits) {
	long long newTotal = (long long)bankCredits + (long long)credits;

	// Cap at 2 billion
	if (newTotal > 2000000000)
		newTotal = 2000000000;

	bankCredits = (int)newTotal;
}

void GalaxyAccountInfo::subtractBankCredits(int credits) {
	bankCredits -= credits;

	if (bankCredits < 0)
		bankCredits = 0;
}

bool GalaxyAccountInfo::verifyBankCredits(int credits) const {
	if (credits < 0)
		return false;

	if (bankCredits < credits)
		return false;

	return true;
}

bool GalaxyAccountInfo::parseFromBinaryStream(ObjectInputStream* stream) {
	if (!chosenVeteranRewards.parseFromBinaryStream(stream))
		return false;

	// Read bank credits from stream
	// For backward compatibility with old serialized data that doesn't have bankCredits,
	// we check if there's data available before reading
	try {
		bankCredits = stream->readInt();
	} catch (...) {
		// Old format without bankCredits - default to 0
		bankCredits = 0;
	}

	return true;
}


bool GalaxyAccountInfo::toBinaryStream(ObjectOutputStream* stream) {
	if (!chosenVeteranRewards.toBinaryStream(stream))
		return false;

	// Write bank credits to stream
	stream->writeInt(bankCredits);

	return true;
}

void to_json(nlohmann::json& j, const GalaxyAccountInfo& p) {
	j["chosenVeteranRewards"] = p.chosenVeteranRewards.getMapUnsafe();
	j["bankCredits"] = p.bankCredits;
}


