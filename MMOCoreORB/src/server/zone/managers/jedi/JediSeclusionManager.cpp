// MMOCoreORB/src/server/zone/managers/jedi/JediSeclusionManager.cpp
#include "server/zone/managers/jedi/JediSeclusionManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "templates/SharedObjectTemplate.h"

bool JediSeclusionManager::isJediSeclusionEligible(CreatureObject* player) {
	return player != nullptr && player->hasSkill("force_title_jedi_rank_02");
}

bool JediSeclusionManager::isSecluded(CreatureObject* player) {
	if (player == nullptr)
		return false;

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return false;

	return ghost->getJediSeclusionState() == JEDI_CONFLICT_SECLUDED;
}

uint64 JediSeclusionManager::getCooldownRemaining(CreatureObject* player) {
	if (player == nullptr)
		return 0;

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return 0;

	uint64 currentTime = System::getTime();
	uint64 cooldownEnd = ghost->getJediSeclusionCooldownEndTime();

	if (currentTime >= cooldownEnd)
		return 0;

	return cooldownEnd - currentTime;
}

bool JediSeclusionManager::hasActiveBountyConflict(CreatureObject* player) {
	if (player == nullptr)
		return false;

	ZoneServer* zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return false;

	MissionManager* missionManager = zoneServer->getMissionManager();

	if (missionManager == nullptr)
		return false;

	uint64 playerId = player->getObjectID();

	// hasPlayerBountyTargetInList() is deliberately NOT used here: it only
	// reflects whether a PlayerBounty tracking record exists at all, and that
	// record is created the moment a character reaches Padawan and persists
	// for as long as they hold the skill -- true for virtually every eligible
	// Jedi at all times, not "has an active hunt right now". The only
	// meaningful "conflict" signal is whether a hunter currently holds an
	// accepted mission against this target.
	Vector<uint64> hunters = missionManager->getHuntersHuntingTarget(playerId);

	return hunters.size() > 0;
}

static String formatCooldownRemaining(uint64 secondsRemaining) {
	uint64 totalMinutes = (secondsRemaining + 59) / 60;
	uint64 days = totalMinutes / (24 * 60);
	uint64 hours = (totalMinutes / 60) % 24;
	uint64 minutes = totalMinutes % 60;

	String message = "You must remain committed to your current path for another ";

	if (days > 0)
		message += String::valueOf(days) + (days == 1 ? " day, " : " days, ");

	message += String::valueOf(hours) + (hours == 1 ? " hour, and " : " hours, and ");
	message += String::valueOf(minutes) + (minutes == 1 ? " minute." : " minutes.");

	return message;
}

bool JediSeclusionManager::canEnterSeclusion(CreatureObject* player, String& denyReason) {
	if (player == nullptr) {
		denyReason = "You cannot do that right now.";
		return false;
	}

	if (!isJediSeclusionEligible(player)) {
		denyReason = "This choice is available only after becoming a Padawan.";
		return false;
	}

	if (isSecluded(player)) {
		denyReason = "You have already withdrawn into Seclusion.";
		return false;
	}

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr) {
		denyReason = "You cannot do that right now.";
		return false;
	}

	uint64 cooldownRemaining = getCooldownRemaining(player);

	if (cooldownRemaining > 0 && !ghost->isPrivileged()) {
		denyReason = formatCooldownRemaining(cooldownRemaining);
		return false;
	}

	if (player->isIncapacitated() || player->isDead()) {
		denyReason = "You cannot change your Jedi philosophy while incapacitated.";
		return false;
	}

	if (player->isInCombat() || !ghost->isDuelListEmpty()) {
		denyReason = "You cannot change your Jedi philosophy while in combat or an active duel.";
		return false;
	}

	if (ghost->hasTef()) {
		denyReason = "You cannot change your Jedi philosophy while flagged for PvP combat. Wait for your combat flag to clear and try again.";
		return false;
	}

	if (player->getFactionStatus() == FactionStatus::OVERT) {
		denyReason = "You must resolve your Overt faction status before entering Seclusion.";
		return false;
	}

	if (hasActiveBountyConflict(player)) {
		denyReason = "You cannot enter Seclusion while you are involved in an active Jedi conflict or bounty. Resolve the conflict and try again later.";
		return false;
	}

	return true;
}

bool JediSeclusionManager::canLeaveSeclusion(CreatureObject* player, String& denyReason) {
	if (player == nullptr) {
		denyReason = "You cannot do that right now.";
		return false;
	}

	if (!isSecluded(player)) {
		denyReason = "You are not currently in Seclusion.";
		return false;
	}

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr) {
		denyReason = "You cannot do that right now.";
		return false;
	}

	uint64 cooldownRemaining = getCooldownRemaining(player);

	if (cooldownRemaining > 0 && !ghost->isPrivileged()) {
		denyReason = formatCooldownRemaining(cooldownRemaining);
		return false;
	}

	if (player->isIncapacitated() || player->isDead()) {
		denyReason = "You cannot change your Jedi philosophy while incapacitated.";
		return false;
	}

	if (player->isInCombat() || !ghost->isDuelListEmpty()) {
		denyReason = "You cannot change your Jedi philosophy while in combat or an active duel.";
		return false;
	}

	if (ghost->hasTef()) {
		denyReason = "You cannot change your Jedi philosophy while flagged for PvP combat. Wait for your combat flag to clear and try again.";
		return false;
	}

	return true;
}

bool JediSeclusionManager::isValidForceShrine(SceneObject* shrine, CreatureObject* player) {
	if (shrine == nullptr || player == nullptr)
		return false;

	if (!player->isInRange(shrine, SHRINE_INTERACTION_RANGE))
		return false;

	const SharedObjectTemplate* shrineTemplate = shrine->getObjectTemplate();

	if (shrineTemplate == nullptr)
		return false;

	String path = shrineTemplate->getFullTemplateString().toLowerCase();

	return path.contains("force_shrine");
}

void JediSeclusionManager::logTransition(CreatureObject* player, JediConflictState from, JediConflictState to) {
	if (player == nullptr)
		return;

	const char* fromLabel = (from == JEDI_CONFLICT_SECLUDED) ? "SECLUDED" : "OPEN";
	const char* toLabel = (to == JEDI_CONFLICT_SECLUDED) ? "SECLUDED" : "OPEN";

	player->info(true) << "[JediSeclusion] Character " << player->getDisplayedName()
		<< " (OID " << player->getObjectID() << ") changed " << fromLabel << " -> " << toLabel;
}

int JediSeclusionManager::requestToggle(CreatureObject* player, SceneObject* shrine) {
	if (player == nullptr)
		return TOGGLE_ERROR_DENIED;

	if (!isValidForceShrine(shrine, player)) {
		player->sendSystemMessage("You must be at a Force Shrine to do that.");
		return TOGGLE_ERROR_INVALID_SHRINE;
	}

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return TOGGLE_ERROR_DENIED;

	bool enteringSeclusion = !isSecluded(player);
	String denyReason;

	bool allowed = enteringSeclusion ? canEnterSeclusion(player, denyReason) : canLeaveSeclusion(player, denyReason);

	if (!allowed) {
		player->sendSystemMessage(denyReason);
		return TOGGLE_ERROR_DENIED;
	}

	// player (and by extension its slotted ghost) is already locked by the
	// Lua binding wrapper before this native method is invoked, matching the
	// convention used throughout LuaCreatureObject.cpp / FindMyTrainerCommand.
	JediConflictState fromState = enteringSeclusion ? JEDI_CONFLICT_OPEN : JEDI_CONFLICT_SECLUDED;
	JediConflictState toState = enteringSeclusion ? JEDI_CONFLICT_SECLUDED : JEDI_CONFLICT_OPEN;

	bool wasCooldownBypassed = getCooldownRemaining(player) > 0 && ghost->isPrivileged();

	ghost->setJediSeclusionState(toState);
	ghost->setJediSeclusionCooldownEndTime(System::getTime() + SECLUSION_COOLDOWN_SECONDS);

	logTransition(player, fromState, toState);

	if (wasCooldownBypassed) {
		player->info(true) << "[JediSeclusion] Administrator bypass: character " << player->getDisplayedName()
			<< " (OID " << player->getObjectID() << ") changed philosophy while cooldown was still active.";
	}

	if (enteringSeclusion) {
		player->sendSystemMessage("You have withdrawn from the conflicts of the galaxy and entered the Path of Seclusion. Your Jedi combat and healing abilities operate at their normal effectiveness, and you are protected from player Jedi Bounty Hunter missions while Secluded.");
		return TOGGLE_SUCCESS_ENTERED_SECLUSION;
	}

	// Computed after the state mutation above so it reflects the new Overt status.
	int overtBonusPercent = getOvertJediPveBonusPercent(player);

	StringBuffer overtMessage;
	overtMessage << "You have chosen to return to the galaxy. You may once again participate in Jedi PvP and become eligible for Jedi bounty systems.\n\n"
		<< "Your Overt Jedi PvE bonuses are currently:\n"
		<< "Jedi Special Damage: +" << overtBonusPercent << "%\n"
		<< "Jedi Healing Effectiveness: +" << overtBonusPercent << "%\n\n"
		<< "These bonuses do not apply in PvP.";

	player->sendSystemMessage(overtMessage.toString());
	return TOGGLE_SUCCESS_RETURNED_TO_OPEN;
}

bool JediSeclusionManager::blocksHostileInteraction(CreatureObject* a, CreatureObject* b) {
	if (a == nullptr || b == nullptr)
		return false;

	if (!a->isPlayerCreature() || !b->isPlayerCreature())
		return false;

	if (!isSecluded(a) && !isSecluded(b))
		return false;

	// Once either party is factionally Overt, defer entirely to normal GCW
	// attackability rules rather than granting Seclusion protection -- closes
	// the loophole of entering Seclusion (which requires being non-Overt) and
	// then flipping Overt to bait/fight while still shielded from players.
	if (a->getFactionStatus() == FactionStatus::OVERT || b->getFactionStatus() == FactionStatus::OVERT)
		return false;

	return true;
}

bool JediSeclusionManager::isJediOvert(CreatureObject* player) {
	return isJediSeclusionEligible(player) && !isSecluded(player);
}

int JediSeclusionManager::getOvertJediPveBonusPercent(CreatureObject* player) {
	if (!isJediOvert(player))
		return 0;

	if (player->hasSkill("force_title_jedi_rank_04"))
		return ConfigManager::instance()->getInt("Core3.CombatManager.OvertJediMasterPveBonusPercent", 20);

	if (player->hasSkill("force_title_jedi_rank_03"))
		return ConfigManager::instance()->getInt("Core3.CombatManager.OvertJediKnightPveBonusPercent", 15);

	// isJediOvert() already confirmed at least Padawan (force_title_jedi_rank_02).
	return ConfigManager::instance()->getInt("Core3.CombatManager.OvertJediPadawanPveBonusPercent", 10);
}

float JediSeclusionManager::getOvertJediPveDamageModifier(CreatureObject* player) {
	return 1.0f + (getOvertJediPveBonusPercent(player) / 100.0f);
}

float JediSeclusionManager::getOvertJediPveHealingModifier(CreatureObject* player) {
	return 1.0f + (getOvertJediPveBonusPercent(player) / 100.0f);
}

bool JediSeclusionManager::isValidOvertJediPveDamageTarget(CreatureObject* attacker, SceneObject* target) {
	if (attacker == nullptr || target == nullptr || target == attacker)
		return false;

	if (target->isPlayerCreature())
		return false;

	// Real server-controlled mob only -- excludes tamed/faction pets, combat
	// droids, and vehicle/mount gunner seats, all of which are AiAgents but
	// are effectively player-controlled combat entities.
	if (!target->isAiAgent())
		return false;

	if (target->isPet() || target->isVehicleObject())
		return false;

	return true;
}

bool JediSeclusionManager::isValidOvertJediPveHealingContext(CreatureObject* healer, CreatureObject* target) {
	if (healer == nullptr || target == nullptr)
		return false;

	PlayerObject* healerGhost = healer->getPlayerObject();

	if (healerGhost == nullptr || healerGhost->hasTef())
		return false;

	// Self-heal: healer and target are the same object, one check suffices.
	// Heal-other: the target's own PvP TEF also suppresses the bonus, so a
	// Jedi can't route around the check by healing a PvP-flagged ally instead
	// of themselves.
	if (target != healer) {
		PlayerObject* targetGhost = target->getPlayerObject();

		if (targetGhost == nullptr || targetGhost->hasTef())
			return false;
	}

	return true;
}
