/*
 * WorldResetManager.h
 *
 * Bellum Gero controlled administrative reset of DEPLOYED player structures and
 * PLAYER-CREATED cities. See doc block in WorldResetManager.cpp for scope, safety
 * analysis and the exact operator sequence.
 *
 * This manager holds ONLY in-memory, non-persistent state (authentication window,
 * dry-run snapshot, armed window). Nothing here is written to any database, so all
 * of it is cleared by a server restart.
 */

#ifndef WORLDRESETMANAGER_H_
#define WORLDRESETMANAGER_H_

#include "engine/engine.h"
#include "system/thread/Mutex.h"
#include "system/thread/Locker.h"

namespace server {
namespace zone {
	class ZoneServer;
namespace objects {
namespace creature {
	class CreatureObject;
}
}
}
}

namespace wr_sz  = server::zone;
namespace wr_crt = server::zone::objects::creature;

class WorldResetManager : public Logger, public Object, public Singleton<WorldResetManager> {
public:
	// Security-window lifetimes (milliseconds).
	static constexpr uint64 AUTH_LIFETIME_MS = 10ULL * 60ULL * 1000ULL;   // 10 minutes
	static constexpr uint64 ARM_LIFETIME_MS = 5ULL * 60ULL * 1000ULL;     // 5 minutes
	static constexpr uint64 DRYRUN_VALIDITY_MS = 15ULL * 60ULL * 1000ULL; // dry-run must be this fresh to arm

	// Authentication throttle.
	static constexpr int AUTH_MAX_FAILURES = 5;
	static constexpr uint64 AUTH_THROTTLE_MS = 300ULL * 1000ULL; // 5 minutes lockout after too many failures

	static constexpr int REQUIRED_ADMIN_LEVEL = 15;

	static const char* const CONFIG_SECRET_KEY;   // "Core3.WorldResetSecret"
	static const char* const EXECUTE_PHRASE;      // "RESET-HOUSING-AND-CITIES"

	struct DryRunCounts {
		int playerCities = 0;
		int cityHalls = 0;
		int civicStructures = 0;
		int cityCitizens = 0;
		int64 cityTreasuryTotal = 0;

		int deployedHouses = 0;
		int installations = 0;
		int factories = 0;
		int harvesters = 0;
		int generators = 0;
		int otherDeployedStructures = 0;

		int potentialVendors = 0;
		int structuresWithUnpackedContents = 0;

		int orphanStructures = 0;        // valid StructureObject, no zone -> removable
		int unreadableStructureRecords = 0; // playerstructures.db rows ObjectManager cannot load at all -> BLOCK
		int nonStructureRecordsExcluded = 0; // playerstructures.db rows that load fine but are NOT StructureObjects
		                                     // (event-perk deployables, flags, NPC actor perks) -> EXCLUDED, not blocking
		int unreadableCityRecords = 0;      // cityregions.db rows that will not deserialize

		int packedDeedsExcluded = 0;     // housepacks/d-*.bin  (packed houses in deed form)
		int packedPendingRedeem = 0;     // housepacks/b-*.bin for a still-deployed building (UNSAFE)
		int orphanPackPayloadFiles = 0;  // housepacks/b-*.bin with no matching deployed building

		int staticCitiesExcluded = 0;    // client / NPC city regions encountered (should be 0 here)
		int gcwBasesExcluded = 0;

		int unclassifiedLiveObjects = 0; // a loaded object we could not positively classify -> BLOCK
		int dbReadErrors = 0;            // a database iteration/read failed -> BLOCK

		// Deterministic fingerprint of the exact candidate set (see computeFingerprint).
		String fingerprint;
	};

	// Persistent execution-state marker (survives restart). Written to
	// bin/worldreset/state.txt so an interrupted execute is detectable.
	//
	// NOTE: readStatePhase() resolves the persisted phase by its NAME first
	// (phase=<NAME> in state.txt) and only falls back to the numeric phaseId, so
	// inserting a value here does not corrupt an existing state.txt.
	//
	enum ResetPhase {
		PHASE_IDLE = 0,
		PHASE_PRECHECK,
		PHASE_CLIENT_DRAIN,   // manifest persisted; disconnecting gameplay clients. NO destructive work yet.
		PHASE_CITIES,
		PHASE_CIVIC,
		PHASE_STRUCTURES,
		PHASE_ORPHANS,
		PHASE_PAYLOADS,
		PHASE_VALIDATION,
		PHASE_COMPLETE,
		PHASE_FAILED
	};

	WorldResetManager() {
		setLoggingName("WorldReset");
	}

	// --- subcommand entry points (all assume caller already passed Admin Level 15) ---
	void authenticate(wr_crt::CreatureObject* admin, const String& suppliedSecret);
	void runDryRun(wr_crt::CreatureObject* admin);
	void showStatus(wr_crt::CreatureObject* admin);
	void arm(wr_crt::CreatureObject* admin);
	void execute(wr_crt::CreatureObject* admin, const String& confirmationPhrase);
	void cancel(wr_crt::CreatureObject* admin);
	void clearState(wr_crt::CreatureObject* admin, const String& arg); // clear the reset marker (blocked if committed work exists, unless forced)
	void diagnose(wr_crt::CreatureObject* admin);   // non-destructive deep classification of playerstructures.db
	void recovery(wr_crt::CreatureObject* admin);   // read-only report on an interrupted reset (alias: recoverycheck)
	void resume(wr_crt::CreatureObject* admin, const String& confirmationPhrase); // continue an interrupted STRUCTURE_PHASE reset

	// Self-rescheduling stall watchdog tick (logs, never force-unlocks). Public so a
	// scheduler lambda can call it.
	void stallWatchdogTick();

	// Stall-watchdog heartbeat, pumped by the reset worker (and by the free
	// function wrMaintenanceDestroyStructure). Public for that reason; they only
	// touch hbMutex-guarded fields and never force-unlock anything.
	void hbTouch(uint64 oid, const char* stage);
	void hbBatch(int n);
	void hbStop();

	// Runs the actual reset. Detached: invoked from a task worker with NO external
	// lock held (never under the executing admin's creature lock). adminOID may
	// resolve to nullptr (admin logged out) -- the reset does not depend on it.
	void runResetBackground(wr_sz::ZoneServer* zoneServer, uint64 adminOID, bool resuming);

	// True only if the config secret is present AND supplied value matches (constant time).
	bool isSecretConfigured() const;

private:
	mutable Mutex stateMutex;

	// Authentication window.
	uint64 authAdminOID = 0;
	uint64 authExpireMs = 0;
	int authFailureCount = 0;
	uint64 authThrottleUntilMs = 0;

	// Dry-run snapshot.
	bool dryRunComplete = false;
	bool dryRunSafe = false;
	uint64 dryRunTimeMs = 0;
	uint64 dryRunAdminOID = 0;
	DryRunCounts lastCounts;
	String lastFingerprint;                  // fingerprint of the last dry run's candidate set
	SortedVector<uint64> snapshotCityOIDs;    // exact player-city OIDs the dry run would disband
	SortedVector<uint64> snapshotStructureOIDs; // exact deployed player-structure OIDs
	SortedVector<uint64> snapshotOrphanOIDs;  // exact zoneless-but-loadable structure record OIDs

	// Armed window.
	bool armed = false;
	uint64 armedAtMs = 0;
	uint64 armExpireMs = 0;
	uint64 armAdminOID = 0;

	// Guard to reject re-entrant execution.
	bool executionInProgress = false;

	// Stall watchdog heartbeat (updated by the reset worker; read by the watchdog).
	mutable Mutex hbMutex;
	uint64 hbExecuteStartMs = 0;
	uint64 hbLastProgressMs = 0;
	uint64 hbCurrentOID = 0;
	String hbCurrentStage;
	int hbBatchNo = 0;
	bool hbActive = false;
	int hbLastReportedStallSecs = 0;

	// helpers
	static uint64 nowMs();
	bool isAuthenticatedLocked(uint64 adminOID) const;
	void clearAuthLocked();
	void clearArmLocked();
	void clearDryRunLocked();
	String getConfiguredSecret() const;
	static bool constantTimeEquals(const String& a, const String& b);

	// Snapshot / destruction core. zoneServer may be null -> resolved from admin.
	// The three out-vectors receive the exact candidate OIDs (sorted).
	void collectSnapshot(wr_sz::ZoneServer* zoneServer, wr_crt::CreatureObject* admin, DryRunCounts& out, bool logDetails,
		SortedVector<uint64>& cityOIDs, SortedVector<uint64>& structureOIDs, SortedVector<uint64>& orphanOIDs);
	// allowAdmin=true: the executing admin may be connected (execute() gate).
	// allowAdmin=false: ZERO players connected (re-checked inside the task after
	// every client -- including the admin -- has been disconnected).
	bool serverStateSafeForExecute(wr_sz::ZoneServer* zoneServer, uint64 adminOID, String& reason, bool allowAdmin);

	// Client drain -- NEVER takes a blocking player/session lock across the wait,
	// NEVER calls PlayerManager::disconnectAllPlayers (whose onlineMapMutex->creature
	// lock order deadlocks a live server). Mirrors Core3's own kickUser(): set the
	// logging-out flag + LogoutMessage under a transient per-player lock, then let a
	// scheduled task do session->disconnect(true). requestClientDisconnects() issues
	// those requests; waitForClientDrain() polls getOnlinePlayerList() lock-free with
	// a hard timeout and re-nudges stragglers. Returns false (fail closed) on timeout.
	void requestClientDisconnects(wr_sz::ZoneServer* zoneServer, uint64 initiatingAdminOID, int& requested);
	bool waitForClientDrain(wr_sz::ZoneServer* zoneServer, int maxWaitSecs, String& reason);
	void performReset(wr_sz::ZoneServer* zoneServer, uint64 adminOID, bool resuming);
	void launchResetTask(wr_sz::ZoneServer* zoneServer, uint64 adminOID, bool resuming);

	// Fail-closed rule: every reason execution is blocked, appended to `reasons`.
	// Returns true only if the reset is safe to arm/execute.
	static bool evaluateSafety(const DryRunCounts& c, Vector<String>& reasons);

	// Deterministic fingerprint of the candidate set (order-independent).
	static String computeFingerprint(const DryRunCounts& c, const SortedVector<uint64>& cityOIDs,
		const SortedVector<uint64>& structureOIDs, const SortedVector<uint64>& orphanOIDs);

	// Persistent interrupted-reset marker (bin/worldreset/state.txt).
	static const char* stateFilePath();
	void writeStatePhase(ResetPhase phase, const String& note) const;
	ResetPhase readStatePhase(String& note) const;
	static String phaseName(ResetPhase phase);

	// Persistent target manifest + per-target progress (bin/worldreset/).
	// The manifest is written ONCE at execute start (v2 format: one record per
	// target with identity metadata) and is the ONLY authority for what an
	// interrupted reset may still touch -- resume never broadens it.
	static const char* manifestFilePath();
	static const char* progressFilePath();

	// Write the v2 manifest. Resolves each target and records
	//   S|<oid>|<category>|<crc>|<got>|<owner>|<zoneHash>|<template>
	// so resume can prove identity. `armedMs` is the arm timestamp.
	void writeManifestV2(wr_sz::ZoneServer* zoneServer, const String& fingerprint, uint64 armedMs,
		const SortedVector<uint64>& cityOIDs, const SortedVector<uint64>& structureOIDs,
		const SortedVector<uint64>& orphanOIDs) const;

	// Read the v2 manifest. `structOrder` preserves target order (structs then
	// orphans, deduped); `meta` maps every target OID (incl. cities) to its raw
	// metadata string "<kind>|<category>|<crc>|<got>|<owner>|<zoneHash>|<template>".
	bool readManifestV2(String& fingerprint, uint64& armedMs, uint64& executeMs,
		Vector<uint64>& cityOrder, Vector<uint64>& structOrder,
		VectorMap<uint64, String>& meta) const;

	static bool parseTargetMeta(const String& metaLine, String& kind, String& category,
		uint32& crc, int& got, uint64& owner);

	// Append-only per-target status transitions: "<ms>|<oid>|<status>".
	// status in {IN_PROGRESS, REMOVED, FAILED, SKIPPED_VERIFIED}. Last line wins.
	void progressMark(uint64 oid, const char* status) const;
	void loadProgressStatus(VectorMap<uint64, String>& out) const;

	struct ResumeReport {
		bool haveManifest = false;
		uint64 armedMs = 0;
		uint64 executeMs = 0;
		String fingerprint;
		ResetPhase phase = PHASE_IDLE;
		int origCityTargets = 0;
		int origStructTargets = 0;
		int citiesConfirmedGone = 0;
		int citiesStillPresent = 0;
		int confirmedRemoved = 0;       // manifest target absent AND progress=REMOVED
		int completedByAbsence = 0;     // manifest target absent, progress not REMOVED
		int remaining = 0;              // present, identity matches -> resumable
		int failedRecorded = 0;         // progress=FAILED
		int identityMismatch = 0;       // present, template/type/owner != manifest -> BLOCK
		int inProgressAtCrash = 0;      // progress last = IN_PROGRESS, still present
		int unreadable = 0;             // present but won't resolve to a StructureObject and not event-perk
		bool destructiveWorkStarted = false; // any city/structure actually removed (progress.log or absence)
		int connectedSessionsRemaining = 0;  // players still in getOnlinePlayerList() right now
		bool resumeEligible = false;
	};

	// Non-destructive analysis of the persisted interrupted reset.
	ResumeReport analyzeResume(wr_sz::ZoneServer* zoneServer) const;

	// Watchdog wiring (heartbeat helpers hbTouch/hbBatch/hbStop are public above).
	void startStallWatchdog();

	// Bounded wait for the task scheduler to drain outstanding destruction work.
	void drainTaskQueues(const char* label, int maxSeconds) const;

	// Commit + force a Berkeley checkpoint so each phase is independently recoverable.
	void commitAndCheckpoint(const char* label) const;
};

#endif /* WORLDRESETMANAGER_H_ */
