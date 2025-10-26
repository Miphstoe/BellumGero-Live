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

	// For backward compatibility: try to read length of bank data section
	// Old format: no more data (exception on read) -> length = 0 -> bankCredits = 0
	// New format: length prefix indicates bankCredits data follows
	uint32 bankDataLength = 0;
	bankCredits = 0; // Default for old format

	try {
		// Try to read the length prefix for new format bank data
		bankDataLength = stream->readInt();

		// Sanity check: bankDataLength should be sizeof(int) or 0
		if (bankDataLength == (uint32)sizeof(int)) {
			// New format with bankCredits
			bankCredits = stream->readInt();
		} else if (bankDataLength > 0) {
			// Unknown format with unexpected length - skip it safely
			for (uint32 i = 0; i < bankDataLength; ++i) {
				try {
					stream->readByte();
				} catch (...) {
					// Error reading data, but continue
					break;
				}
			}
			// Leave bankCredits at 0
		}
		// If bankDataLength == 0, it's old format end marker or new format with no bank
	} catch (...) {
		// End of stream reached - old format without bankCredits
		// bankCredits stays at 0
	}

	return true;
}


bool GalaxyAccountInfo::toBinaryStream(ObjectOutputStream* stream) {
	if (!chosenVeteranRewards.toBinaryStream(stream))
		return false;

	// Write length prefix for bank data section (for backward compatibility)
	// This allows us to detect and skip unknown format versions
	uint32 bankDataLength = sizeof(int);  // Length of bankCredits field
	stream->writeInt(bankDataLength);

	// Write bank credits to stream
	stream->writeInt(bankCredits);

	return true;
}

void to_json(nlohmann::json& j, const GalaxyAccountInfo& p) {
	j["chosenVeteranRewards"] = p.chosenVeteranRewards.getMapUnsafe();
	j["bankCredits"] = p.bankCredits;
}


