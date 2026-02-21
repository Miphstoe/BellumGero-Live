# Sync config branch – scripts

## sync-config-branch.ps1

Commits and pushes **dev env** (`.cursor/`, root `README.md`) to branch **Ender_CursorConfig**. Use when you don't want to forget to sync.

- **Run from repo root** (e.g. `C:\Users\Shadow\code\swg-bg`).
- **Optional:** `-RepoPath "C:\Users\Shadow\code\swg-bg"` if you run from another directory.

```powershell
cd C:\Users\Shadow\code\swg-bg
.\.cursor\skills\sync-config-branch\scripts\sync-config-branch.ps1
```

Or from anywhere:

```powershell
.\.cursor\skills\sync-config-branch\scripts\sync-config-branch.ps1 -RepoPath "C:\Users\Shadow\code\swg-bg"
```

## Run on a schedule (Windows Task Scheduler)

**Quick install (recommended):** From repo root, run once. Creates a task that runs **daily at 6 PM**, **at log on**, and **at log off** (on disconnect from user session):

```powershell
cd C:\Users\Shadow\code\swg-bg
.\.cursor\skills\sync-config-branch\scripts\install-scheduled-task.ps1
```

**Also run at startup:** Add `-AtStartup` (may require "Run as administrator" once).

**Options:** `-DailyHour 20`, `-DailyMinute 0`, `-RepoPath "C:\path\to\swg-bg"`, `-Uninstall`. Disable a trigger: `-AtLogOn:$false` or `-AtStartup:$false`.

**Task name:** `SWG-BG sync Ender_CursorConfig`. To edit or delete: Task Scheduler (taskschd.msc) → Task Scheduler Library → select the task.

**Manual setup:** Create a task that runs `powershell.exe` with arguments: `-NoProfile -ExecutionPolicy Bypass -File "<repo>\.cursor\skills\sync-config-branch\scripts\sync-config-branch.ps1" -RepoPath "<repo>"`. Run only when user is logged on so Git/SSH credentials are available.

## WSL / Linux (sync-config-branch.sh + cron)

On the WSL dev desktop (e.g. `~/localswgserver`), the same sync is available so both envs stay in sync when switching between Shadow PC and WSL.

### Run manually

```bash
cd ~/localswgserver
.cursor/skills/sync-config-branch/scripts/sync-config-branch.sh
```

Or from anywhere:

```bash
.cursor/skills/sync-config-branch/scripts/sync-config-branch.sh ~/localswgserver
# or
REPO_PATH=~/localswgserver .cursor/skills/sync-config-branch/scripts/sync-config-branch.sh
```

### Run on a schedule (cron)

**Install (daily at 6 PM, same as Windows default):**

```bash
cd ~/localswgserver
.cursor/skills/sync-config-branch/scripts/install-cron.sh
```

**Optional: also run once at login (when cron starts):**

```bash
.cursor/skills/sync-config-branch/scripts/install-cron.sh -r
```

**Options:** `-h 20` (8 PM), `-m 30`, `-p /path/to/repo`, `-u` to uninstall.

**Uninstall:**

```bash
.cursor/skills/sync-config-branch/scripts/install-cron.sh -u
```

Ensure the script is executable: `chmod +x .cursor/skills/sync-config-branch/scripts/sync-config-branch.sh` (install-cron.sh does this if needed). Git/SSH must work in cron (e.g. SSH agent or credential helper); run from your user crontab so keys are available.
