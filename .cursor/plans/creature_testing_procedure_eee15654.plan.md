---
name: Creature testing procedure
overview: "Document the creature testing workflow for code changes: server start/reload, admin god mode, teleport admin then teleport target the combat toon, spawn creature, then combat/inspect/harvest/cleanup—and decide where this lives (update existing docs vs new doc)."
todos: []
isProject: false
---

# Creature Testing Procedure for Code Changes

## Goal

Capture the normal creature-test flow you use: **reload/start server → teleport admin (god mode) → teleport target combat toon → createCreature → test (combat, harvest, cleanup)** so it’s the standard, repeatable way to test code changes.

## Current state

- **[CREATURE_TEST_RUNNER.md](.cursor/context/CREATURE_TEST_RUNNER.md)** – Single-admin flow: god mode, teleport self, createCreature, kill, harvest; Rori/Talus/Lok examples; no “combat toon” or `teleportTarget`.
- **[SOP_TESTING_NEW_CREATURES.md](.cursor/context/SOP_TESTING_NEW_CREATURES.md)** – Full SOP (god mode, teleport, createCreature syntax, inspect, cleanup); mentions `/teleportTarget` for “another player” but does not describe the two-client (admin + combat toon) workflow.
- **Admin commands** – Syntax is in [SWG_ADMIN_COMMANDS_CONTEXT.md](.cursor/context/SWG_ADMIN_COMMANDS_CONTEXT.md): `/teleport <planet> <x> <y>`, `/teleportTarget <targetName> [planet x y]`, `/createCreature {script} [x z y] [planet] [cellid]`, `/setGodMode self on`, `/invuln`, `/kill`, `/destroy`, `/dumpTargetInformation`.

## Intended workflow (from your description)

```mermaid
sequenceDiagram
  participant Dev
  participant Server
  participant AdminClient
  participant CombatClient

  Dev->>Server: Reload/start (e.g. shutdown 0 fast then ./core3)
  Dev->>AdminClient: Log in admin, /setGodMode self on, /invuln
  Dev->>AdminClient: /teleport &lt;planet&gt; &lt;x&gt; &lt;y&gt;
  Dev->>AdminClient: /teleportTarget &lt;combatToonName&gt; &lt;planet&gt; &lt;x&gt; &lt;y&gt;
  Dev->>AdminClient: /createCreature &lt;creatureScript&gt;
  Dev->>CombatClient: Fight, harvest, inspect
  Dev->>AdminClient: /kill or /destroy (cleanup)
```



1. **Server** – Reload if Lua changed: in server console `shutdown 0 fast`, then from `~/localswgserver/MMOCoreORB/bin` run `./core3`. Otherwise just start `./core3`.
2. **Admin (god mode)** – On admin character: `/setGodMode self on`, `/invuln` (and optional `/gmrevive buff`).
3. **Teleport admin** – `/teleport <planet> <x> <y>` to the planet (and coords) the creature is for.
4. **Teleport target combat toon** – `/teleportTarget <combatToonName> <planet> <x> <y>` so the combat test character is at the same spot.
5. **Spawn** – `/createCreature <creatureScript>` (or with coords/planet if needed).
6. **Test** – On combat toon: engage creature (name/level, health, damage), optionally `/dumpTargetInformation` from admin, harvest, then admin `/kill` or `/destroy` for cleanup.

## Recommended approach

**Option A – Extend CREATURE_TEST_RUNNER (recommended)**  
Keep one place for “how we run creature tests after code changes” and add the two-client flow at the top.

- Add a **“Standard flow (admin + combat toon)”** section: server reload/start → admin god mode → teleport admin → teleport target combat toon → createCreature → test (combat / harvest) → cleanup, with exact commands and placeholders (`<planet>`, `<x>`, `<y>`, `<combatToonName>`, `<creatureScript>`).
- Keep existing “Quick spawn test” (Rori/Talus/Lok) as a single-admin shortcut; add a one-line note that for real combat testing you use the two-client flow above.
- Reference SOP for full command syntax and variable summary; reference SWG_ADMIN_COMMANDS_CONTEXT for raw command list.

**Option B – New doc only**  
Create a single doc (e.g. `CREATURE_TEST_WORKFLOW.md` in `.cursor/context/`) that is only the step-by-step for “testing code changes” (server, admin, teleport, teleportTarget, createCreature, test, cleanup) and link it from CREATURE_TEST_RUNNER and SOP so both point to “canonical workflow.”

**Option C – Extend SOP only**  
Add a “Two-client test (admin + combat toon)” subsection to SOP Section 3 (Testing Workflow), and add a short “After code changes, run this first” pointer in CREATURE_TEST_RUNNER that links to that SOP section.

## Suggested content to add (for Option A or B)

- **When to reload:** After changing Lua (creature scripts, spawn/lair scripts): `shutdown 0 fast` in server console, then `./core3` from `MMOCoreORB/bin`. No reload needed for C++-only changes until you restart.
- **Order of operations:** God mode on admin → teleport admin → teleport target combat toon (same planet/coords) → createCreature at that location.
- **Placeholders table:** `<planet>`, `<x> <y>`, `<combatToonName>`, `<creatureScript>` with one example row (e.g. rori, 0 0, MyCombatToon, monstrous_dark_graul).
- **Post-spawn:** Combat toon engages; admin can target and use `/dumpTargetInformation`; harvest on combat toon; admin `/kill` or `/destroy` for cleanup.
- **Cross-links:** To SOP for createCreature optional args and variable summary; to SWG_ADMIN_COMMANDS_CONTEXT for command reference.

## Files to touch


| Option | Files                                                                                                                                                                                                                                                                         |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A**  | [.cursor/context/CREATURE_TEST_RUNNER.md](.cursor/context/CREATURE_TEST_RUNNER.md) – add “Standard flow (admin + combat toon)” section and placeholder table; optional one-line pointer in SOP.                                                                               |
| **B**  | New `.cursor/context/CREATURE_TEST_WORKFLOW.md`; [CREATURE_TEST_RUNNER.md](.cursor/context/CREATURE_TEST_RUNNER.md) and [SOP_TESTING_NEW_CREATURES.md](.cursor/context/SOP_TESTING_NEW_CREATURES.md) – add “See CREATURE_TEST_WORKFLOW for code-change testing” near the top. |
| **C**  | [.cursor/context/SOP_TESTING_NEW_CREATURES.md](.cursor/context/SOP_TESTING_NEW_CREATURES.md) – new subsection in Section 3; [CREATURE_TEST_RUNNER.md](.cursor/context/CREATURE_TEST_RUNNER.md) – one short “First run this workflow” pointer.                                 |


## Summary

- Your flow is: **server (reload if Lua) → admin god mode → teleport admin → teleport target combat toon → createCreature → combat/harvest/inspect → cleanup.**
- Recommended: **Option A** – add this as the “Standard flow” in CREATURE_TEST_RUNNER so “run in order” includes the two-client steps, and keep the rest of the doc as-is with a small note that full combat testing uses that flow.

If you tell me which option you want (A, B, or C), the next step is to add the exact section text and placeholders to the chosen file(s) without changing any code or run behavior.