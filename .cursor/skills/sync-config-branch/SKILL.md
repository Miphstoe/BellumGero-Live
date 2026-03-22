---
name: sync-config-branch
description: Syncs dev env (rules, context, skills, .cursor README) to Ender_CursorConfig — run when user asks to push config branch, commit dev env, or avoid forgetting to sync
---

# Sync Config Branch (Ender_CursorConfig)

Use this skill when the user wants to **commit and push dev env changes to the config branch** so they don't get out of sync. Run it when they say things like "sync config branch", "push dev env", "commit Ender_CursorConfig", or "I keep forgetting to push my .cursor changes".

## When to apply

- User asks to sync, push, or commit the config branch or dev env.
- User mentions forgetting to push .cursor / rules / context changes.
- User wants to ensure Ender_CursorConfig is up to date with local dev env changes.

## Instructions

1. **Confirm repo and branch**
   - Run in the workspace root:
     - Shadow PC: `C:\Users\Shadow\code\swg-bg`
     - Main Desktop (WSL): `~/localswgserver`
     - Laptop (WSL): `~/workspace/BellumGero-Live`
   - Config branch name: **Ender_CursorConfig** (from branch-naming.mdc and bellum-gero.mdc).

2. **Check for dev env changes**
   - Dev env = `.cursor/` (rules, context, skills, README), root `README.md` if it's a workspace doc. Respect `.gitignore` (e.g. `.cursor/extensions/`, `.cursor/ai-tracking/`, `.cursor/projects/` are ignored).
   - Run: `git status --short .cursor README.md` (or equivalent) to see if there are modified/untracked dev env files.

3. **If no changes**
   - Tell the user: "No uncommitted dev env changes; Ender_CursorConfig is already in sync."

4. **If there are changes**
   - Save current branch: e.g. `git branch --show-current`.
   - Checkout **Ender_CursorConfig** (create it from current branch if it doesn't exist and user intends to push a new config branch).
   - Add only dev env paths: `git add .cursor/` and optionally `git add README.md` (if project root README is part of workspace docs). Do not add game code (MMOCoreORB, docker, etc.) unless the user explicitly includes it.
   - Commit with a clear message, e.g. "Dev env: rules, context, skills, .cursor README".
   - Push: `git push origin Ender_CursorConfig`.
   - Switch back to the previous branch if the user was on another branch (e.g. Main or a feature branch).

5. **Optional: run the scheduled script**
   - **Windows (Shadow PC):** `.cursor/skills/sync-config-branch/scripts/sync-config-branch.ps1` (from repo root). Schedule via `install-scheduled-task.ps1` (Task Scheduler).
   - **WSL/Linux (dev desktop):** `.cursor/skills/sync-config-branch/scripts/sync-config-branch.sh` (from repo root, e.g. `~/localswgserver`). Schedule via `install-cron.sh` (cron).

## Safeguards

- Only add paths under `.cursor/` and root `README.md`. Do not add `MMOCoreORB/`, `docker/`, etc., unless the user explicitly asks.
- If the user is on a feature branch with uncommitted **code** changes, do not mix them into Ender_CursorConfig; only sync dev env files.
- Remind the user: code should be committed to the code branch first; dev env (Ender_CursorConfig) last (see bellum-gero.mdc).

## Scheduled / automatic runs (outside Cursor)

Cursor does **not** run tasks on a schedule. For automatic sync so both envs stay in sync:

- **Windows (Shadow PC):** Run `.cursor/skills/sync-config-branch/scripts/install-scheduled-task.ps1` once. Task Scheduler runs `sync-config-branch.ps1` daily, at log on, and at log off. See script folder README.
- **Main Desktop (WSL):** Run `.cursor/skills/sync-config-branch/scripts/install-cron.sh` once from `~/localswgserver`.
- **Laptop (WSL):** Run `.cursor/skills/sync-config-branch/scripts/install-cron.sh` once from `~/workspace/BellumGero-Live`.

The skill helps when the user remembers to ask; the scripts + Task Scheduler/cron keep Ender_CursorConfig in sync on both machines.
