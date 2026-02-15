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

## WSL dev server

Same idea on Linux: add a cron job or a systemd timer that runs a small script which `cd`s to `~/localswgserver`, then runs the equivalent git steps (checkout Ender_CursorConfig, add .cursor/ and README.md, commit, push, checkout back). You can copy the logic from this PowerShell script into a bash script.
