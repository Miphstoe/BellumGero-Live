/*
 * DpsSessionManager.h
 *
 * Standalone, transient combat-damage session tracking. No session data is
 * persisted to the database. The manager is intentionally independent from
 * PlayerObject so the feature can be removed without changing object schemas.
 */

#ifndef DPSSESSIONMANAGER_H_
#define DPSSESSIONMANAGER_H_

#include "engine/engine.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"

class DpsSessionData : public Object {
public:
	bool active;
	bool liveUpdates;
	bool completedByTimer;
	bool finalReportSent;

	uint64 sessionID;
	uint64 requestedStartTime;
	uint64 firstDamageTime;
	uint64 lastDamageTime;
	uint64 endTime;
	uint64 nextUpdateTime;

	uint64 targetObjectID;
	uint64 fixedDurationMillis;

	String targetLabel;
	String targetProfile;

	static const int MAX_TEN_SECOND_BUCKETS = 30;
	uint64 tenSecondDamage[MAX_TEN_SECOND_BUCKETS];

	uint64 totalDamage;
	uint64 directDamage;
	uint64 dotDamage;
	uint64 playerDamage;
	uint64 petDamage;
	uint64 droidDamage;
	uint64 largestHit;
	uint32 damageEvents;

	Vector<uint64> uniqueTargets;

	DpsSessionData();

	void resetStatistics(uint64 now, uint64 targetID, uint64 durationMillis,
		const String& newTargetLabel = "", const String& newTargetProfile = "");
};

class DpsSessionManager : public Singleton<DpsSessionManager>, public Object {
public:
	enum DamageSource {
		DIRECT_DAMAGE = 0,
		DAMAGE_OVER_TIME = 1
	};

	enum DamageOwner {
		PLAYER_OWNER = 0,
		CREATURE_PET_OWNER = 1,
		DROID_OWNER = 2
	};

	static const uint64 ONE_MINUTE_MILLIS = 60000;
	static const uint64 FIVE_MINUTES_MILLIS = 300000;

private:
	VectorMap<uint64, Reference<DpsSessionData*> > sessions;
	Mutex sessionsLock;

	static const uint64 LIVE_UPDATE_INTERVAL_MILLIS = 10000;

	Reference<DpsSessionData*> getOrCreateSessionLocked(uint64 playerID);
	ManagedReference<CreatureObject*> resolveCreditedPlayer(TangibleObject* attacker, DamageOwner& ownerType) const;

	uint64 getElapsedMillisLocked(const DpsSessionData* session, uint64 now) const;
	String buildReportLocked(const DpsSessionData* session, uint64 now, bool finalReport) const;
	String buildCompactReportLocked(const DpsSessionData* session, uint64 now) const;

	void scheduleTimedSessionTick(CreatureObject* player, uint64 sessionID, uint64 delayMillis);
	void sendFinalReportWindow(CreatureObject* player, const String& report) const;

public:
	DpsSessionManager();

	bool startSession(CreatureObject* player, bool forceRestart = false, uint64 targetObjectID = 0,
		uint64 fixedDurationMillis = ONE_MINUTE_MILLIS, const String& targetLabel = "",
		const String& targetProfile = "");
	bool stopSession(CreatureObject* player, String& report);
	bool restartSession(CreatureObject* player);
	bool restartSession(CreatureObject* player, uint64 targetObjectID, uint64 fixedDurationMillis,
		const String& targetLabel = "", const String& targetProfile = "");

	bool getSessionTargetInfo(CreatureObject* player, uint64& targetObjectID,
		String& targetLabel, String& targetProfile);

	bool hasActiveSession(CreatureObject* player);
	bool hasActiveSession(uint64 playerID);
	uint64 getConfiguredDurationMillis(CreatureObject* player);

	String getStatusReport(CreatureObject* player);

	bool getLiveUpdates(CreatureObject* player);
	void setLiveUpdates(CreatureObject* player, bool enabled);

	void recordDamage(TangibleObject* attacker, TangibleObject* defender, int damage, DamageSource source);
	void processTimedSessionTick(CreatureObject* player, uint64 sessionID);

	void removeSession(uint64 playerID);
};

#endif /* DPSSESSIONMANAGER_H_ */
