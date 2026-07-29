/*
 * DpsSessionManager.cpp
 */

#include "DpsSessionManager.h"

#include "server/zone/objects/intangible/PetControlDevice.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"

const uint64 DpsSessionManager::ONE_MINUTE_MILLIS;
const uint64 DpsSessionManager::FIVE_MINUTES_MILLIS;
const uint64 DpsSessionManager::LIVE_UPDATE_INTERVAL_MILLIS;

DpsSessionData::DpsSessionData() {
	active = false;
	liveUpdates = false;
	completedByTimer = false;
	finalReportSent = false;

	sessionID = 0;
	requestedStartTime = 0;
	firstDamageTime = 0;
	lastDamageTime = 0;
	endTime = 0;
	nextUpdateTime = 0;

	targetObjectID = 0;
	fixedDurationMillis = DpsSessionManager::ONE_MINUTE_MILLIS;

	totalDamage = 0;
	directDamage = 0;
	dotDamage = 0;
	playerDamage = 0;
	petDamage = 0;
	droidDamage = 0;
	largestHit = 0;
	damageEvents = 0;
}

void DpsSessionData::resetStatistics(uint64 now, uint64 targetID, uint64 durationMillis) {
	active = true;
	completedByTimer = false;
	finalReportSent = false;

	sessionID++;

	if (sessionID == 0)
		sessionID = 1;

	requestedStartTime = now;
	firstDamageTime = 0;
	lastDamageTime = 0;
	endTime = 0;
	nextUpdateTime = 0;

	targetObjectID = targetID;
	fixedDurationMillis = durationMillis > 0 ? durationMillis : DpsSessionManager::ONE_MINUTE_MILLIS;

	totalDamage = 0;
	directDamage = 0;
	dotDamage = 0;
	playerDamage = 0;
	petDamage = 0;
	droidDamage = 0;
	largestHit = 0;
	damageEvents = 0;

	uniqueTargets.removeAll();
}

DpsSessionManager::DpsSessionManager() {
	sessions.setAllowOverwriteInsertPlan();
	sessions.setNullValue(nullptr);
}

Reference<DpsSessionData*> DpsSessionManager::getOrCreateSessionLocked(uint64 playerID) {
	Reference<DpsSessionData*> session = sessions.get(playerID);

	if (session == nullptr) {
		session = new DpsSessionData();
		sessions.put(playerID, session);
	}

	return session;
}

ManagedReference<CreatureObject*> DpsSessionManager::resolveCreditedPlayer(TangibleObject* attacker, DamageOwner& ownerType) const {
	ownerType = PLAYER_OWNER;

	if (attacker == nullptr || !attacker->isCreatureObject())
		return nullptr;

	CreatureObject* attackingCreature = attacker->asCreatureObject();

	if (attackingCreature == nullptr)
		return nullptr;

	if (attackingCreature->isPlayerCreature()) {
		if (attackingCreature->getPlayerObject() == nullptr)
			return nullptr;

		return attackingCreature;
	}

	if (!attackingCreature->isPet())
		return nullptr;

	ownerType = attackingCreature->isDroidObject() ? DROID_OWNER : CREATURE_PET_OWNER;

	ManagedReference<CreatureObject*> owner = nullptr;
	ManagedReference<PetControlDevice*> controlDevice = attackingCreature->getControlDevice().get().castTo<PetControlDevice*>();

	if (controlDevice != nullptr) {
		ManagedReference<SceneObject*> lastCommander = controlDevice->getLastCommander().get();

		if (lastCommander != nullptr && lastCommander->isCreatureObject()) {
			CreatureObject* commander = lastCommander->asCreatureObject();

			if (commander != nullptr && commander->isPlayerCreature())
				owner = commander;
		}
	}

	if (owner == nullptr)
		owner = attackingCreature->getLinkedCreature().get();

	if (owner == nullptr || !owner->isPlayerCreature() || owner->getPlayerObject() == nullptr)
		return nullptr;

	return owner;
}

uint64 DpsSessionManager::getElapsedMillisLocked(const DpsSessionData* session, uint64 now) const {
	if (session == nullptr || session->firstDamageTime == 0)
		return 0;

	uint64 finishTime = session->active ? now : session->endTime;

	if (finishTime < session->firstDamageTime)
		return 0;

	uint64 elapsedMillis = finishTime - session->firstDamageTime;

	if (session->fixedDurationMillis > 0 && elapsedMillis > session->fixedDurationMillis)
		elapsedMillis = session->fixedDurationMillis;

	return elapsedMillis;
}

String DpsSessionManager::buildReportLocked(const DpsSessionData* session, uint64 now, bool finalReport) const {
	if (session == nullptr)
		return "No DPS session data is available.";

	uint64 elapsedMillis = getElapsedMillisLocked(session, now);
	double elapsedSeconds = elapsedMillis / 1000.0;
	double totalDps = elapsedSeconds > 0.0 ? session->totalDamage / elapsedSeconds : 0.0;
	double playerDps = elapsedSeconds > 0.0 ? session->playerDamage / elapsedSeconds : 0.0;
	double petDps = elapsedSeconds > 0.0 ? session->petDamage / elapsedSeconds : 0.0;
	double droidDps = elapsedSeconds > 0.0 ? session->droidDamage / elapsedSeconds : 0.0;

	StringBuffer report;
	report << (finalReport ? "DPS SESSION RESULTS" : "DPS SESSION STATUS") << "\n\n";

	if (session->active) {
		if (session->firstDamageTime == 0)
			report << "State: Armed - timing begins with your first credited damage event.\n";
		else
			report << "State: Active\n";
	} else if (session->completedByTimer) {
		report << "State: Complete - timed test ended automatically.\n";
	} else if (session->firstDamageTime == 0) {
		report << "State: Cancelled before damage began.\n";
	} else if (session->fixedDurationMillis > 0 && elapsedMillis < session->fixedDurationMillis) {
		report << "State: Stopped early.\n";
	} else {
		report << "State: Complete\n";
	}

	if (session->targetObjectID != 0)
		report << "Target Restriction: " << session->targetObjectID << "\n";
	else
		report << "Mode: Timed freeform outgoing damage\n";

	report << "Configured Duration: " << String::format("%.1f", session->fixedDurationMillis / 1000.0) << " seconds\n";
	report << "Duration: " << String::format("%.1f", elapsedSeconds) << " seconds\n";

	if (session->active && session->firstDamageTime != 0) {
		uint64 remainingMillis = session->fixedDurationMillis > elapsedMillis ?
			session->fixedDurationMillis - elapsedMillis : 0;
		report << "Time Remaining: " << String::format("%.1f", remainingMillis / 1000.0) << " seconds\n";
	}

	report << "Total Damage: " << session->totalDamage << "\n";
	report << "Average DPS: " << String::format("%.1f", totalDps) << "\n";
	report << "Damage Events: " << session->damageEvents << "\n";
	report << "Largest Damage Event: " << session->largestHit << "\n";
	report << "Unique Targets Damaged: " << session->uniqueTargets.size() << "\n\n";

	report << "OWNER BREAKDOWN\n";
	report << "Player: " << session->playerDamage << " damage | " << String::format("%.1f", playerDps) << " DPS\n";
	report << "Creature Pets: " << session->petDamage << " damage | " << String::format("%.1f", petDps) << " DPS\n";
	report << "Combat Droids: " << session->droidDamage << " damage | " << String::format("%.1f", droidDps) << " DPS\n\n";

	report << "DAMAGE SOURCE BREAKDOWN\n";
	report << "Direct Combat: " << session->directDamage << "\n";
	report << "Non-Direct (DOT / Traps): " << session->dotDamage << "\n";

	if (session->totalDamage == 0)
		report << "\nNo successful outgoing damage has been recorded for this session.";

	return report.toString();
}

String DpsSessionManager::buildCompactReportLocked(const DpsSessionData* session, uint64 now) const {
	if (session == nullptr)
		return "[DPS] No active session.";

	uint64 elapsedMillis = getElapsedMillisLocked(session, now);
	double elapsedSeconds = elapsedMillis / 1000.0;
	double totalDps = elapsedSeconds > 0.0 ? session->totalDamage / elapsedSeconds : 0.0;
	double configuredSeconds = session->fixedDurationMillis / 1000.0;

	return String::format("[DPS] %.1fs / %.0fs | %llu damage | %.1f DPS | %u events",
		elapsedSeconds,
		configuredSeconds,
		(unsigned long long)session->totalDamage,
		totalDps,
		session->damageEvents);
}

void DpsSessionManager::scheduleTimedSessionTick(CreatureObject* player, uint64 sessionID, uint64 delayMillis) {
	if (player == nullptr || sessionID == 0)
		return;

	Reference<CreatureObject*> playerRef = player;

	Core::getTaskManager()->scheduleTask([playerRef, sessionID]() {
		if (playerRef == nullptr)
			return;

		DpsSessionManager* manager = DpsSessionManager::instance();

		if (manager != nullptr)
			manager->processTimedSessionTick(playerRef, sessionID);
	}, "DpsTimedSessionTick", delayMillis);
}

void DpsSessionManager::sendFinalReportWindow(CreatureObject* player, const String& report) const {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	Locker playerLocker(player);

	if (player->getPlayerObject() == nullptr)
		return;

	ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
	box->setPromptTitle("DPS Session Complete");
	box->setPromptText(report);
	box->setOkButton(true, "@ok");

	player->getPlayerObject()->addSuiBox(box);
	player->sendSystemMessage("[DPS] Timed test complete. Your final results are now available.");
	player->sendMessage(box->generateMessage());
}

bool DpsSessionManager::startSession(CreatureObject* player, bool forceRestart, uint64 targetObjectID, uint64 fixedDurationMillis) {
	if (player == nullptr || !player->isPlayerCreature() || player->getPlayerObject() == nullptr)
		return false;

	uint64 now = System::getMiliTime();
	Locker locker(&sessionsLock);

	Reference<DpsSessionData*> session = getOrCreateSessionLocked(player->getObjectID());

	if (session->active && !forceRestart)
		return false;

	session->resetStatistics(now, targetObjectID,
		fixedDurationMillis > 0 ? fixedDurationMillis : ONE_MINUTE_MILLIS);
	return true;
}

bool DpsSessionManager::restartSession(CreatureObject* player) {
	if (player == nullptr || !player->isPlayerCreature() || player->getPlayerObject() == nullptr)
		return false;

	uint64 now = System::getMiliTime();
	Locker locker(&sessionsLock);

	Reference<DpsSessionData*> session = getOrCreateSessionLocked(player->getObjectID());
	uint64 targetObjectID = session->targetObjectID;
	uint64 durationMillis = session->fixedDurationMillis > 0 ? session->fixedDurationMillis : ONE_MINUTE_MILLIS;

	session->resetStatistics(now, targetObjectID, durationMillis);
	return true;
}

bool DpsSessionManager::restartSession(CreatureObject* player, uint64 targetObjectID, uint64 fixedDurationMillis) {
	return startSession(player, true, targetObjectID,
		fixedDurationMillis > 0 ? fixedDurationMillis : ONE_MINUTE_MILLIS);
}

bool DpsSessionManager::stopSession(CreatureObject* player, String& report) {
	if (player == nullptr || !player->isPlayerCreature())
		return false;

	uint64 now = System::getMiliTime();
	Locker locker(&sessionsLock);

	Reference<DpsSessionData*> session = sessions.get(player->getObjectID());

	if (session == nullptr || !session->active)
		return false;

	session->active = false;
	session->completedByTimer = false;
	session->finalReportSent = true;
	session->endTime = now;
	report = buildReportLocked(session, now, true);
	return true;
}

bool DpsSessionManager::hasActiveSession(CreatureObject* player) {
	if (player == nullptr)
		return false;

	return hasActiveSession(player->getObjectID());
}

bool DpsSessionManager::hasActiveSession(uint64 playerID) {
	Locker locker(&sessionsLock);
	Reference<DpsSessionData*> session = sessions.get(playerID);
	return session != nullptr && session->active;
}

uint64 DpsSessionManager::getConfiguredDurationMillis(CreatureObject* player) {
	if (player == nullptr)
		return ONE_MINUTE_MILLIS;

	Locker locker(&sessionsLock);
	Reference<DpsSessionData*> session = sessions.get(player->getObjectID());

	if (session == nullptr || session->fixedDurationMillis == 0)
		return ONE_MINUTE_MILLIS;

	return session->fixedDurationMillis;
}

String DpsSessionManager::getStatusReport(CreatureObject* player) {
	if (player == nullptr)
		return "No DPS session data is available.";

	uint64 now = System::getMiliTime();
	Locker locker(&sessionsLock);

	Reference<DpsSessionData*> session = sessions.get(player->getObjectID());

	if (session == nullptr || session->sessionID == 0)
		return "No DPS session data is available. Use /dps start 1 or /dps start 5 to begin a timed test.";

	return buildReportLocked(session, now, !session->active);
}

bool DpsSessionManager::getLiveUpdates(CreatureObject* player) {
	if (player == nullptr)
		return false;

	Locker locker(&sessionsLock);
	Reference<DpsSessionData*> session = sessions.get(player->getObjectID());
	return session != nullptr && session->liveUpdates;
}

void DpsSessionManager::setLiveUpdates(CreatureObject* player, bool enabled) {
	if (player == nullptr || !player->isPlayerCreature())
		return;

	Locker locker(&sessionsLock);
	Reference<DpsSessionData*> session = getOrCreateSessionLocked(player->getObjectID());
	session->liveUpdates = enabled;
}

void DpsSessionManager::recordDamage(TangibleObject* attacker, TangibleObject* defender, int damage, DamageSource source) {
	if (attacker == nullptr || defender == nullptr || damage <= 0)
		return;

	DamageOwner ownerType = PLAYER_OWNER;
	ManagedReference<CreatureObject*> creditedPlayer = resolveCreditedPlayer(attacker, ownerType);

	if (creditedPlayer == nullptr)
		return;

	uint64 now = System::getMiliTime();
	bool sendStartMessage = false;
	bool updatesEnabledAtStart = false;
	bool scheduleFirstTick = false;
	uint64 scheduledSessionID = 0;
	uint64 scheduledDelay = 0;
	uint64 configuredDuration = 0;

	{
		Locker locker(&sessionsLock);
		Reference<DpsSessionData*> session = sessions.get(creditedPlayer->getObjectID());

		if (session == nullptr || !session->active)
			return;

		if (session->targetObjectID != 0 && session->targetObjectID != defender->getObjectID())
			return;

		if (session->firstDamageTime != 0) {
			uint64 naturalEndTime = session->firstDamageTime + session->fixedDurationMillis;

			if (now >= naturalEndTime)
				return;
		}

		if (session->firstDamageTime == 0) {
			session->firstDamageTime = now;
			session->lastDamageTime = now;
			session->nextUpdateTime = now + LIVE_UPDATE_INTERVAL_MILLIS;

			uint64 naturalEndTime = now + session->fixedDurationMillis;

			if (session->nextUpdateTime > naturalEndTime)
				session->nextUpdateTime = naturalEndTime;

			sendStartMessage = true;
			updatesEnabledAtStart = session->liveUpdates;
			scheduleFirstTick = true;
			scheduledSessionID = session->sessionID;
			scheduledDelay = session->nextUpdateTime - now;
			configuredDuration = session->fixedDurationMillis;
		}

		session->lastDamageTime = now;
		session->totalDamage += damage;
		session->damageEvents++;

		if ((uint64)damage > session->largestHit)
			session->largestHit = damage;

		if (!session->uniqueTargets.contains(defender->getObjectID()))
			session->uniqueTargets.add(defender->getObjectID());

		if (source == DAMAGE_OVER_TIME)
			session->dotDamage += damage;
		else
			session->directDamage += damage;

		switch (ownerType) {
		case DROID_OWNER:
			session->droidDamage += damage;
			break;
		case CREATURE_PET_OWNER:
			session->petDamage += damage;
			break;
		case PLAYER_OWNER:
		default:
			session->playerDamage += damage;
			break;
		}
	}

	if (sendStartMessage && creditedPlayer != nullptr) {
		StringBuffer message;
		message << "[DPS] Timed test started with your first credited damage event. Duration: "
			<< (configuredDuration / 1000) << " seconds.";

		if (updatesEnabledAtStart)
			message << " Progress updates will be shown every 10 seconds.";

		creditedPlayer->sendSystemMessage(message.toString());
	}

	if (scheduleFirstTick && creditedPlayer != nullptr)
		scheduleTimedSessionTick(creditedPlayer, scheduledSessionID, scheduledDelay);
}

void DpsSessionManager::processTimedSessionTick(CreatureObject* player, uint64 sessionID) {
	if (player == nullptr || sessionID == 0)
		return;

	uint64 now = System::getMiliTime();
	String liveMessage;
	String finalReport;
	bool sendLiveMessage = false;
	bool sendFinalReport = false;
	bool scheduleNextTick = false;
	uint64 nextDelay = 0;

	{
		Locker locker(&sessionsLock);
		Reference<DpsSessionData*> session = sessions.get(player->getObjectID());

		if (session == nullptr || session->sessionID != sessionID || session->firstDamageTime == 0)
			return;

		if (!session->active)
			return;

		uint64 naturalEndTime = session->firstDamageTime + session->fixedDurationMillis;

		if (now < session->nextUpdateTime) {
			scheduleNextTick = true;
			nextDelay = session->nextUpdateTime - now;
		} else if (now >= naturalEndTime || session->nextUpdateTime >= naturalEndTime) {
			session->active = false;
			session->completedByTimer = true;
			session->endTime = naturalEndTime;
			session->nextUpdateTime = 0;

			if (!session->finalReportSent) {
				session->finalReportSent = true;
				finalReport = buildReportLocked(session, naturalEndTime, true);
				sendFinalReport = true;
			}
		} else {
			if (session->liveUpdates) {
				liveMessage = buildCompactReportLocked(session, now);
				sendLiveMessage = true;
			}

			uint64 nextScheduledTime = session->nextUpdateTime + LIVE_UPDATE_INTERVAL_MILLIS;

			while (nextScheduledTime <= now)
				nextScheduledTime += LIVE_UPDATE_INTERVAL_MILLIS;

			if (nextScheduledTime > naturalEndTime)
				nextScheduledTime = naturalEndTime;

			session->nextUpdateTime = nextScheduledTime;
			scheduleNextTick = true;
			nextDelay = nextScheduledTime > now ? nextScheduledTime - now : 1;
		}
	}

	if (sendLiveMessage) {
		Locker playerLocker(player);
		player->sendSystemMessage(liveMessage);
	}

	if (sendFinalReport)
		sendFinalReportWindow(player, finalReport);

	if (scheduleNextTick)
		scheduleTimedSessionTick(player, sessionID, nextDelay);
}

void DpsSessionManager::removeSession(uint64 playerID) {
	if (playerID == 0)
		return;

	Locker locker(&sessionsLock);

	if (sessions.contains(playerID))
		sessions.drop(playerID);
}
