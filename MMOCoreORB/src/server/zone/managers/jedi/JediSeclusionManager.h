// MMOCoreORB/src/server/zone/managers/jedi/JediSeclusionManager.h
#ifndef JEDISECLUSIONMANAGER_H_
#define JEDISECLUSIONMANAGER_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"

// Jedi PvE Seclusion: a persistent, Force-Shrine-driven philosophical choice
// for Padawan+ Jedi to withdraw from the Jedi/Bounty-Hunter PvP loop. This is
// the single authoritative interface for the feature -- Force Shrine, Bounty
// Hunter/mission generation, combat validation (isAttackableBy), and duel
// validation all consult these static methods rather than touching the raw
// persistent PlayerObject fields directly.
enum JediConflictState : uint8 {
	JEDI_CONFLICT_OPEN = 0,
	JEDI_CONFLICT_SECLUDED = 1
};

class JediSeclusionManager {
public:
	// Lua only needs success/failure granularity for UI flow -- the specific
	// reason for a failure is always sent to the player as a system message
	// from inside requestToggle(), so the result code doesn't need to carry it.
	enum ToggleResult {
		TOGGLE_SUCCESS_ENTERED_SECLUSION = 0,
		TOGGLE_SUCCESS_RETURNED_TO_OPEN = 1,
		TOGGLE_ERROR_INVALID_SHRINE = 2,
		TOGGLE_ERROR_DENIED = 3
	};

	static constexpr uint64 SECLUSION_COOLDOWN_SECONDS = 72 * 60 * 60;
	static constexpr float SHRINE_INTERACTION_RANGE = 10.0f;

	// Padawan (force_title_jedi_rank_02) or higher.
	static bool isJediSeclusionEligible(CreatureObject* player);

	// Current persistent state, resolved via the player's ghost.
	static bool isSecluded(CreatureObject* player);

	// Seconds remaining on the persistent 72h cooldown, 0 if none/expired.
	static uint64 getCooldownRemaining(CreatureObject* player);

	// Full eligibility check for entering/leaving Seclusion, used both to
	// drive the Force Shrine SUI copy and (again, authoritatively) at
	// confirm-time inside requestToggle(). denyReason is set only on failure.
	static bool canEnterSeclusion(CreatureObject* player, String& denyReason);
	static bool canLeaveSeclusion(CreatureObject* player, String& denyReason);

	// The only state-mutating entry point. Re-validates everything fresh
	// (never trusts SUI-open-time state), verifies shrine proximity/template,
	// mutates + persists state under lock, logs, and messages the player.
	static int requestToggle(CreatureObject* player, SceneObject* shrine);

	// Authoritative combat veto consulted from isAttackableBy() and the duel
	// path. Symmetric: blocks a Secluded Jedi from initiating against any
	// player and blocks any player from attacking a Secluded Jedi, but only
	// between two live player characters -- PvE/NPC combat is untouched. If
	// either party is currently factionally Overt, the veto is skipped so a
	// player can't dodge GCW PvP consequences by having entered Seclusion
	// (which itself requires being non-Overt) and then flipping Overt.
	static bool blocksHostileInteraction(CreatureObject* a, CreatureObject* b);

	// Overt Jedi PvE damage/healing incentive. "Overt" here is precisely
	// isJediSeclusionEligible() && !isSecluded() -- the same binary state
	// already tracked above, NOT the separate GCW FactionStatus::OVERT flag.
	// All four methods below are pure functions of live state (rank, Seclusion
	// state, target ownership, TEF); there is no buff object and no persistent
	// field, so a status change takes effect on the very next hit/heal.
	static bool isJediOvert(CreatureObject* player);

	// 1.0f (no-op) unless the player is an Overt Padawan+/Knight+/Master; then
	// 1.10f/1.15f/1.20f per Core3.CombatManager.OvertJedi<Rank>PveBonusPercent.
	static float getOvertJediPveDamageModifier(CreatureObject* player);
	static float getOvertJediPveHealingModifier(CreatureObject* player);

	// True only for a genuine server-controlled PvE mob: not the attacker
	// itself, not a player, an AiAgent, and not a player-owned pet/vehicle.
	static bool isValidOvertJediPveDamageTarget(CreatureObject* attacker, SceneObject* target);

	// True only when neither the healer nor the heal target (which may be the
	// same character, for self-heals) currently has an active PvP TEF.
	static bool isValidOvertJediPveHealingContext(CreatureObject* healer, CreatureObject* target);

private:
	static bool isValidForceShrine(SceneObject* shrine, CreatureObject* player);
	static bool hasActiveBountyConflict(CreatureObject* player);
	static void logTransition(CreatureObject* player, JediConflictState from, JediConflictState to);

	// Shared Padawan/Knight/Master tier lookup backing both PvE modifier
	// getters above (damage% == heal% per rank in this system). Returns 0 if
	// the player isn't an Overt Jedi (not eligible, or currently Secluded).
	static int getOvertJediPveBonusPercent(CreatureObject* player);
};

#endif // JEDISECLUSIONMANAGER_H_
