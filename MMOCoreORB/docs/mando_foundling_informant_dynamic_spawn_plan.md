# Mandalorian Foundling Informant — Dynamic Spawn Redesign Plan

**Date:** 2026-04-04  
**Branch:** Ender_MandalorianWay  
**Author:** BellumGero Dev

---

## Background

The Foundling arc (Chapter 0) places a Mandalorian Informant NPC on each of 10 planets. Players must find the informant, accept a mission quota assignment, complete the quota via mission terminals, then return to the informant to turn in and advance.

The original design used **static NPCs** spawned once at server start via `spawnStaticInformants()`. A global data key (`mando_way:foundling_informant_static:<planet>`) stored the NPC's OID. Per-player state was linked to this shared NPC via `tryLinkStaticFoundlingInformant()`.

---

## Problem

The static approach has multiple points of failure in a live environment:

| Failure Mode | Impact |
|---|---|
| Zone or server restart wipes the NPC from memory | Static key OID goes stale; new NPC has new OID |
| `setConvoTemplate()` is runtime-only | NPC loses its conversation binding after a restart |
| `_MANDO_LOAD_FLAG` guard prevents re-spawn | Once flag is set, zone restarts can never re-spawn that planet's informant |
| Per-player OID mismatch on relog | Conv handler returns `nil` → conversation never opens ("nothing happens") |

The symptom: player right-clicks the informant and nothing happens. No dialog opens. No server log output from the conversation handler. Cause: the NPC has no conversation template bound to it, so `getInitialScreen` is never invoked.

---

## What Was Tried (Static Approach)

1. **Added missing `check_turnin` ConvoScreen** — clicking "I have completed the work." was routing to a non-existent screen, leaving `pConvScreen` nil and stripping all player options.
2. **Already-assigned feedback** — added `sendSystemMessage` showing `X/Y` missions remaining when a player re-opens an active assignment.
3. **Fixed LuaPanicException** — `sendSystemMessage` with `\n` and `—` crashed the Lua layer inside `awardReward()`, aborting before `removeMissionFromPlayer()` ran (missions stayed in the datapad). Fixed by splitting to individual calls and replacing the em-dash.
4. **C++ try-catch** — wrapped `luaTracker->callFunction()` in `MissionObjectiveImplementation.cpp` to prevent tracker exceptions from aborting mission completion.
5. **Hardened OID re-link logic** — conv handler now re-links on `(atStaticHub OR isInformant)` instead of requiring exact OID match, and heals the static key via `writeData`.
6. **Corrected planet coordinates** — Lok moved to `(456, 2, 5434)` near Nym's Stronghold; Rori moved to `(-5199, 80, -2186)` near Narmlex.

**None of these fully resolved the Rori informant** because the root cause is that `setConvoTemplate` is a runtime-only call — zone reboot wipes it — and the static OID key does not survive zone-level restarts.

---

## Solution: Dynamic Per-Player Spawning (Option 4)

Each player gets a **private** `mando_foundling_informant` NPC spawned specifically for them when they advance to a planet. The NPC is destroyed on turn-in. On relog, if the NPC is gone, it is re-spawned. No shared static keys. No `_MANDO_LOAD_FLAG` race. No zone-restart wipe.

Additionally, **Option 1** (re-assert `setConvoTemplate` every time the conversation opens) is embedded as a safety net inside the conversation handler.

---

## Desync Scenarios and Handling

| Scenario | Behavior | Resolution |
|---|---|---|
| Zone / server restart | NPC destroyed; player's stored OID is dead | `onPlayerLoggedIn` → `ensureFoundlingInformant` → `getSceneObject(oid) == nil` → re-spawns fresh NPC |
| Player disconnects mid-quota | NPC stays alive in world | On relog: NPC still valid; `ensureFoundlingInformant` exits immediately |
| NPC killed by another player | NPC destroyed; OID dead | Same as zone restart; re-spawned on next login |
| `spawnMobile` returns nil (bad coords / zone busy) | Spawn fails; `informantId` stays "0"; player gets error message | `ensureFoundlingInformant` retries on next login |
| Two players on same planet at same coords | Two NPCs stacked at same location | **Ownership guard**: `mando_way:informant:<oid>:player` must match clicking player; Player B cannot hijack Player A's NPC |
| Player clicks static / city-spawned NPC | Static NPCs have no ownership record | Ownership guard requires explicit match; static NPCs only re-link via exact `atStaticHub` OID (never written in dynamic mode) |
| Re-spawn during active quota (`counting=1, done=0`) | NPC re-spawned; **no waypoint granted** | Silent re-spawn; system message only: "Your contact has been re-located." |
| Re-spawn when quota met (`counting=1, done=1`) | NPC re-spawned; return-to-informant waypoint re-granted | `grantReturnToInformantWaypoint` called after spawn |
| Re-spawn before assignment accepted (`counting=0`) | NPC re-spawned; find-informant waypoint granted | `grantInformantWaypoint` called by `spawnInformant` |
| `turnInPlanet` called, NPC already gone | `despawnInformant` checks `getSceneObject` — handles nil | No change needed; already safe |
| Double re-spawn race (two quick login events) | Two `ensureFoundlingInformant` calls back to back | Guard: `if (oid ~= 0 and getSceneObject(oid) ~= nil) then return end` — second call sees NPC alive and exits |
| Server crash mid-spawn (NPC created, `writeData` not written) | Orphaned NPC at coords; no ownership record | Ownership guard excludes orphaned NPC from re-linking; player re-spawns clean NPC on next login |

---

## Files Changed

### `bin/scripts/screenplays/bellum/mando_way_of_life.lua`

#### `spawnInformant(pPlayer, index, grantWaypoint)` — full rewrite
- Remove `tryLinkStaticFoundlingInformant` fallback
- `spawnMobile(data.planet, "mando_foundling_informant", 0, data.x, data.z, data.y, 0, 0)`
- Configure NPC: `setConvoTemplate`, `setOptionsBitmask(INVULNERABLE + CONVERSABLE)`, `setCustomObjectName`, `setPvpStatusBitmask(0)`, `addObjectFlag(AI_STATIC)`
- Write ownership key: `writeData("mando_way:informant:<oid>:player", playerOid)`
- Write per-player state: `foundling.informantId = oid`, `foundling.informantStatic = 0`
- Grant waypoint if `grantWaypoint == true`
- Log success and failure with coords

#### `ensureFoundlingInformant(pPlayer)` — change re-link block
- Keep existing guards (arc active, valid index, NPC-alive check)
- Replace `tryLinkStaticFoundlingInformant(...)` with `spawnInformant(pPlayer, idx, (counting ~= 1))`
- If `done == 1` after spawn: also call `grantReturnToInformantWaypoint`
- System message varies by counting/done state

#### `onPlayerLoggedIn(pPlayer)` — simplify mid-arc section
- Replace the three `tryLinkStaticFoundlingInformant` branches with a single `ensureFoundlingInformant(pPlayer)` call
- Keep `createEvent` poll scheduling for active quota below it

#### `spawnStaticInformants()` — remove from `start()`
- Function definition kept intact for Option 5 GM use
- Call removed from `start()`
- Comment added: `-- Not called at startup in dynamic spawn mode. Reserved for GM admin use (Option 5).`

---

### `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`

#### `getInitialScreen` — two additions

**1. Option 1 safety** (first thing after nil checks):
```lua
-- Safety: re-assert conv template each open in case runtime state was wiped (zone restart)
if (pNpc ~= nil) then
    AiAgent(pNpc):setConvoTemplate("mandoFoundlingInformantConvoTemplate")
end
```

**2. Ownership guard** in re-link block:
```lua
-- Prevent player from hijacking another player's dynamically-spawned NPC
local dynOwner = tostring(tonumber(readData("mando_way:informant:" .. npcStr .. ":player")) or 0)
local playerOidStr = tostring(SceneObject(pPlayer):getObjectID())
local isOwnedByPlayer = (dynOwner == playerOidStr)

if (atStaticHub or (isInformant and isOwnedByPlayer)) then
    -- re-link
end
```

---

## What Stays the Same

| Component | Status |
|---|---|
| `despawnInformant` | Unchanged — already handles dynamic (`informantStatic == 0`), deletes ownership key, destroys NPC |
| `turnInPlanet` | Unchanged — calls `despawnInformant` then `advanceToPlanet` |
| `advanceToPlanet` | Unchanged — calls `despawnInformant` then `spawnInformant` |
| `grantInformantWaypoint` | Unchanged |
| `grantReturnToInformantWaypoint` | Unchanged |
| `tryLinkStaticFoundlingInformant` | Kept, not called in main flow — reserved for GM use |
| All conversation template screens | Unchanged |
| C++ `MissionObjectiveImplementation.cpp` try-catch | Already in place — no further change needed |

---

## Future: Option 5 — GM Admin Respawn Command

Once dynamic spawn is stable, add GM utility functions:

```lua
-- Force re-spawn informant for a specific player (GM use)
MandoWayOfLife:gmRespawnInformantForPlayer(pPlayer)

-- Re-spawn static informants on a specific planet (server display / event use)
MandoWayOfLife:gmRespawnAllStaticInformants(planetName)
```

`gmRespawnInformantForPlayer` forces `ensureFoundlingInformant` regardless of whether the NPC is currently alive (bypasses the alive-check guard). Useful for stuck players without needing a full server restart.

---

## Planet Coordinates Reference

| Index | Planet | X | Z (Height) | Y | Notes |
|---|---|---|---|---|---|
| 1 | tatooine | 3491 | 5 | -4782 | citySpawn — Mos Eisley cantina area |
| 2 | corellia | -367 | 28 | -4577 | |
| 3 | naboo | -5468 | 5 | 4382 | |
| 4 | dantooine | -594 | 3 | 2474 | |
| 5 | lok | 456 | 2 | 5434 | Near Nym's Stronghold |
| 6 | rori | -5199 | 80 | -2186 | Near Narmlex |
| 7 | talus | 551 | 5 | -2906 | Verify in-game |
| 8 | endor | -1335 | 5 | -2116 | Verify in-game |
| 9 | dathomir | -3800 | 5 | 1100 | Verify in-game |
| 10 | yavin4 | -6551 | 5 | -4330 | Verify in-game |

---

## No C++ Rebuild Required

All changes are Lua-only (`bin/scripts/`). The C++ try-catch fix in `MissionObjectiveImplementation.cpp` is already in place from a previous session.
