#include "server/zone/objects/mission/PlayerBounty.h"

void PlayerBountyImplementation::recalculatePlayerPlacedRewardFromExistingPlacers() {
	int total = 0;

	for (int i = 0; i < bountyPlacers.size(); ++i) {
		total += bountyPlacers.elementAt(i).getValue();
	}

	playerPlacedReward = total;

	if (total > 0) {
		playerPlacedBountyActive = true;
		playerPlacedBountyConsumed = false;
	}
}

bool PlayerBountyImplementation::canTakeMission(uint64 enemyID, uint64 cooldownTime) {
	if (missionCooldownList.size() == 0)
		return true;

	if (!missionCooldownList.contains(enemyID))
		return true;

	uint64 enemyCooldown = missionCooldownList.get(enemyID);

	if (enemyCooldown + cooldownTime <= System::getMiliTime()) {
		missionCooldownList.drop(enemyID);
		return true;
	}

	return false;
}
