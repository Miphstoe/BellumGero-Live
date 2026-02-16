# Start new feature – scripts

Same workflow on both environments: merge Main into Ender_CursorConfig, create the feature branch from Ender_CursorConfig, then add .cursor and dev docs to .gitignore and remove from tracking so they never merge into Main.

## start-new-feature.sh (WSL/Linux)

**Usage (from repo root):**

```bash
cd ~/localswgserver
chmod +x .cursor/skills/start-new-feature/scripts/start-new-feature.sh
.cursor/skills/start-new-feature/scripts/start-new-feature.sh Ender_YourFeatureName
```

Example: `.cursor/skills/start-new-feature/scripts/start-new-feature.sh Ender_MissingResources`

## start-new-feature.ps1 (Shadow PC / Windows)

**Usage (from repo root, e.g. PowerShell):**

```powershell
cd C:\Users\Shadow\code\swg-bg
.\.cursor\skills\start-new-feature\scripts\start-new-feature.ps1 -FeatureBranch Ender_YourFeatureName
```

Or from anywhere:

```powershell
.\.cursor\skills\start-new-feature\scripts\start-new-feature.ps1 -FeatureBranch Ender_MissingResources -RepoPath "C:\Users\Shadow\code\swg-bg"
```

If the merge step has conflicts (e.g. on .gitignore), the script will tell you to resolve them, push Ender_CursorConfig, then re-run the script.

## Skill

See [../SKILL.md](../SKILL.md) for when the agent runs this workflow (e.g. when you say "start new feature" or "create feature branch Ender_X").
