# Cursor workspace – Bellum Gero / Shadow PC

Index for rules, skills, and related docs used in this Cursor workspace.

## Commit workflow reminder

**Where things go:** Game/code changes → **code branch** (Main or `Ender_FeatureName`). Dev env (rules, skills, **.cursor/context/**, this README, workspace docs) → **Ender_CursorConfig** only.

**Order:** Commit and push **code first**, then **dev env last**. Before prod: test on WSL dev server; dev env updates support both Shadow dev box and WSL build/test. See [rules/bellum-gero.mdc](rules/bellum-gero.mdc) → "COMMIT & PUSH WORKFLOW".

## Rules (always or contextually applied)

| File | Purpose |
|------|--------|
| [rules/bellum-gero.mdc](rules/bellum-gero.mdc) | SWG Bellum Gero context: Shadow PC vs WSL, Lua-first, paths, **commit workflow (code first, dev env last)**. Always applied. |
| [rules/branch-naming.mdc](rules/branch-naming.mdc) | Branch naming `[Dev]_[Feature]`, protected branches, work order. Always applied. |
| [rules/context-files.mdc](rules/context-files.mdc) | Where context files go: **`.cursor/context/`** (same on Shadow PC and WSL). Always applied. |
| [rules/documentation.mdc](rules/documentation.mdc) | **Document code and scripts thoroughly** (headers, intent, parameters) so others can follow and review. Always applied. |

## Skills (agent skills)

| Skill | Purpose |
|-------|--------|
| [skills-cursor/create-rule/](skills-cursor/create-rule/) | Create Cursor rules (`.cursor/rules/*.mdc`) |
| [skills-cursor/create-skill/](skills-cursor/create-skill/) | Create Agent Skills (SKILL.md) |
| [skills-cursor/create-subagent/](skills-cursor/create-subagent/) | Create custom subagents |
| [skills-cursor/migrate-to-skills/](skills-cursor/migrate-to-skills/) | Migrate rules/commands to skills |
| [skills-cursor/update-cursor-settings/](skills-cursor/update-cursor-settings/) | Modify Cursor/VSCode settings.json |
| [skills/sync-config-branch/](skills/sync-config-branch/) | Sync dev env to **Ender_CursorConfig** (so you don't forget). Run script on a schedule via Task Scheduler for automatic sync. |

*(Note: `skills-cursor` is Cursor’s built-in skills directory.)*

## Context (workspace structure)

**All context files** (workspace structure, repo layout, AI/contributor context) live in **`.cursor/context/`**. Same path on **Shadow PC** and **WSL build/test dev box** (repo is shared).

| Doc | Path | Purpose |
|-----|------|--------|
| **WORKSPACE_STRUCTURE.md** | [context/WORKSPACE_STRUCTURE.md](context/WORKSPACE_STRUCTURE.md) | Folder and file layout of the swg-bg repo (root, .cursor, docker, MMOCoreORB, etc.). |

See [rules/context-files.mdc](rules/context-files.mdc) for the rule that enforces this location.

## Related docs (Bellum Gero / Shadow PC)

These may live in your user folder or project; paths below are typical on Shadow PC:

| Doc | Typical path | Purpose |
|-----|--------------|--------|
| **SWG_EXPLORER_SETUP.md** | `C:\Users\Shadow\SWG_EXPLORER_SETUP.md` | Swg.Explorer install, build, TRE viewer setup |
| **SHADOW_PC_SETUP_PLAN.md** | `C:\Users\Shadow\SHADOW_PC_SETUP_PLAN.md` or project root | Shadow PC dev environment plan |
| **BELLUM_GERO_PROMPT.md** | `C:\Users\Shadow\BELLUM_GERO_PROMPT.md` or project root | Bellum Gero AI prompt / context |
| **README.md** (project) | e.g. `C:\Users\Shadow\code\swg-bg\README.md` | Project index (when in a repo) |

## Swg.Explorer (TRE viewer)

- **Setup (build + run):** See **SWG_EXPLORER_SETUP.md** (path above).
- **Install location:** `C:\Users\Shadow\Tools\Swg.Explorer`
- **Build from source:** DirectX DLLs go in `C:\Users\Shadow\Tools\Swg.Explorer\lib` — see that folder’s `README.txt`.

## WSL dev server

For build/run/test and server config, use the WSL dev server; see **bellum-gero.mdc** for paths (`~/localswgserver`, config, TREs).
