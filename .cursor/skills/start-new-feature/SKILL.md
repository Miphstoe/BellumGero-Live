---
name: start-new-feature
description: Start a new feature branch – update Ender_CursorConfig from Main, create branch from Ender_CursorConfig, then add .cursor and dev docs to .gitignore and remove from tracking so they never merge into Main
---

# Start New Feature Branch

Use this skill when the user wants to **start a new feature** or **create a new feature branch**. Ensures (1) Ender_CursorConfig has the latest Main, (2) the new branch is created from Ender_CursorConfig, and (3) .cursor and dev docs are ignored on the new branch so they never get committed or merged into Main.

See [rules/feature-branch-workflow.mdc](../../rules/feature-branch-workflow.mdc) for the rule.

## When to apply

- User says "start new feature", "create feature branch", "new feature", "I need to create a new feature", "branch for [feature name]".
- User asks how to start a new feature and wants the correct workflow.

## Prerequisites

- Repo root: WSL `~/localswgserver` or Shadow `C:\Users\Shadow\code\swg-bg` (or equivalent).
- Get the **feature branch name** from the user (e.g. `Ender_NewFeatureName`). If not given, ask: "What should the feature branch be called? (e.g. Ender_ResourceX)"

## Instructions

### Step 1: Update Ender_CursorConfig from Main

Run in repo root (WSL example; use PowerShell on Shadow with same git commands):

```bash
git fetch origin Main
git checkout Ender_CursorConfig
git pull origin Ender_CursorConfig   # ensure local config branch is up to date
git merge origin/Main -m "Merge Main into Ender_CursorConfig"
```

If there is a **.gitignore conflict** during merge: keep the version that **does not** ignore the whole `.cursor/` directory (so Ender_CursorConfig can keep tracking .cursor). Resolve, then:

```bash
git add .gitignore
git commit -m "Merge Main into Ender_CursorConfig (resolve .gitignore)"
```

Then push:

```bash
git push origin Ender_CursorConfig
```

### Step 2: Create the new feature branch from Ender_CursorConfig

```bash
git checkout Ender_CursorConfig
git pull origin Ender_CursorConfig
git checkout -b Ender_FeatureName
```

(Replace `Ender_FeatureName` with the name the user provided.)

### Step 3: Ignore .cursor and dev docs on this branch (so they never merge into Main)

Add the following block to **.gitignore** (if not already present). Ensure these paths are listed so they are ignored on this branch:

```gitignore
# Dev env – only tracked on Ender_CursorConfig; do not commit on feature branches or Main
.cursor/
.cursorrules
BELLUM_GERO_WINDCLAW_RAPTOR_DANTOOINE_AVIAN_MEAT.md
CHANGELOG.md
LOCAL_DEV_ENV_SETUP.md
SWG_ADMIN_COMMANDS_CONTEXT.md
SWG_CONTEXT.md
SWG_FILE_CODE_STRUCUTRE_CONTEXT.md
cursor_cursor_wsl_extension_project_fol.md
```

Then remove them from Git’s index (so this branch stops tracking them; files stay on disk as untracked/ignored):

```bash
git add .gitignore
git rm -r --cached .cursor 2>/dev/null || true
git rm --cached .cursorrules 2>/dev/null || true
git rm --cached CHANGELOG.md LOCAL_DEV_ENV_SETUP.md SWG_ADMIN_COMMANDS_CONTEXT.md SWG_CONTEXT.md SWG_FILE_CODE_STRUCUTRE_CONTEXT.md cursor_cursor_wsl_extension_project_fol.md 2>/dev/null || true
git status
git commit -m "Feature branch: ignore .cursor and dev docs (do not merge into Main)"
```

(On Windows PowerShell use equivalent `git rm -r --cached .cursor` etc.; omit files that aren’t tracked.)

### Step 4: Confirm

Tell the user:

- "Ender_CursorConfig is updated from Main. New branch **Ender_FeatureName** is created from it. .cursor and dev docs are ignored on this branch so they won’t be merged into Main. You can start feature work."

## Safeguards

- Do not create the feature branch from Main; always from Ender_CursorConfig after updating it from Main.
- If the user is on Shadow PC, use PowerShell and Windows paths; if WSL, use bash and `~/localswgserver`.
- If merge Main → Ender_CursorConfig fails (e.g. conflicts), help resolve; prefer keeping Ender_CursorConfig’s .gitignore so .cursor stays tracked there.

## Scripts (run without agent)

- **WSL:** `.cursor/skills/start-new-feature/scripts/start-new-feature.sh Ender_FeatureName` (from repo root, e.g. `~/localswgserver`).
- **Shadow PC (PowerShell):** `.cursor/skills/start-new-feature/scripts/start-new-feature.ps1 -FeatureBranch Ender_FeatureName` (from repo root, e.g. `C:\Users\Shadow\code\swg-bg`). Optional: `-RepoPath "C:\path\to\repo"`.

See `scripts/README.md` in this skill folder.

## Quick reference (WSL)

```bash
git fetch origin Main
git checkout Ender_CursorConfig && git pull origin Ender_CursorConfig
git merge origin/Main -m "Merge Main into Ender_CursorConfig"
# resolve .gitignore if conflict: keep version that tracks .cursor
git push origin Ender_CursorConfig
git checkout -b Ender_YourFeatureName
# add .cursor/ and dev docs to .gitignore, then:
git add .gitignore && git rm -r --cached .cursor 2>/dev/null || true
git commit -m "Feature branch: ignore .cursor and dev docs (do not merge into Main)"
```
