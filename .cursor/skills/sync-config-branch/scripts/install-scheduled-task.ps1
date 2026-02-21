<#
.SYNOPSIS
    Registers a Windows Task Scheduler task to run sync-config-branch.ps1 on a schedule.

.DESCRIPTION
    Creates (or updates) a single scheduled task that commits and pushes dev env
    (.cursor/, README.md) to branch Ender_CursorConfig. Triggers: daily at a set time,
    at log on, optionally at startup, and at log off (session disconnect).
    Run once from repo root to install; use -Uninstall to remove the task.
    No admin required for default triggers; -AtStartup may require "Run as administrator".

.PARAMETER RepoPath
    Path to the swg-bg repo root. Default: inferred from this script's location
    (script lives under .cursor/skills/sync-config-branch/scripts/, so repo is four levels up).

.PARAMETER TaskName
    Name of the scheduled task. Default: "SWG-BG sync Ender_CursorConfig".

.PARAMETER DailyHour, DailyMinute
    Time for the daily run (24-hour). Default: 18:00 (6 PM).

.PARAMETER AtLogOn
    If $true, add a trigger to run when the current user logs on. Default: $true.

.PARAMETER AtStartup
    If $true, add a trigger to run at system startup. May require elevation to register.
    Default: $false so normal users can install without admin.

.PARAMETER Uninstall
    Remove the scheduled task instead of creating/updating it.

.EXAMPLE
    .\install-scheduled-task.ps1
    Install with defaults: daily 18:00, at log on, at log off.

.EXAMPLE
    .\install-scheduled-task.ps1 -AtStartup -DailyHour 20
    Install with startup trigger and daily run at 8 PM (may need Run as administrator).

.EXAMPLE
    .\install-scheduled-task.ps1 -Uninstall
    Remove the task.

.NOTES
    At log off is implemented via Task Scheduler's SessionStateChangeTrigger
    (StateChange = 2 = TASK_CONSOLE_DISCONNECT). schtasks.exe has no ONLOGOFF
    schedule type, so we use the CIM class MSFT_TaskSessionStateChangeTrigger.
    See: .cursor/skills/sync-config-branch/scripts/README.md
#>

param(
    [string]$RepoPath = "",
    [string]$TaskName = "SWG-BG sync Ender_CursorConfig",
    [int]$DailyHour = 18,
    [int]$DailyMinute = 0,
    [bool]$AtLogOn = $true,
    [bool]$AtStartup = $false,   # $true can require "Run as administrator"
    [switch]$Uninstall
)

# Resolve repo root and path to the sync script (must exist)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RepoPath) {
    $RepoPath = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
}
$syncScript = Join-Path $scriptDir "sync-config-branch.ps1"
if (-not (Test-Path $syncScript)) {
    Write-Error "Sync script not found: $syncScript"
    exit 1
}

# Single argument string for powershell.exe so the task runs: sync-config-branch.ps1 -RepoPath "<repo>"
$syncScriptArg = "-NoProfile -ExecutionPolicy Bypass -File `"$syncScript`" -RepoPath `"$RepoPath`""

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Task '$TaskName' unregistered."
    exit 0
}

# --- Build trigger set for the task ---
# Daily at the requested time
$triggers = @(
    New-ScheduledTaskTrigger -Daily -At "$($DailyHour):$($DailyMinute.ToString('00'))"
)
# Run when current user logs on (so Git/SSH credentials are available)
if ($AtLogOn) {
    $triggers += New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
}
# Run at system startup (can require admin to register)
if ($AtStartup) {
    $triggers += New-ScheduledTaskTrigger -AtStartup
}

# Run when user session disconnects (log off). schtasks has no ONLOGOFF; use CIM.
# StateChange 2 = TASK_CONSOLE_DISCONNECT (see taskschd.h / SessionStateChangeTrigger).
try {
    $logOffClass = Get-CimClass -Namespace ROOT\Microsoft\Windows\TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger -ErrorAction Stop
    $logOffTrigger = New-CimInstance -CimClass $logOffClass -Property @{ StateChange = 2; Enabled = $true } -ClientOnly
    $triggers += $logOffTrigger
} catch {
    # CIM class or trigger type may be missing on some SKUs; user can add "On disconnect" manually in Task Scheduler
}

# Register the task (overwrite if exists)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $syncScriptArg
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers -Settings $settings `
    -Description "Commits and pushes .cursor/ and README.md to branch Ender_CursorConfig so dev env stays in sync." -Force

Write-Host "Task '$TaskName' registered."
Write-Host "  Repo:    $RepoPath"
Write-Host "  Daily:   ${DailyHour}:$($DailyMinute.ToString('00'))"
if ($AtLogOn)  { Write-Host "  Trigger: At log on" }
if ($AtStartup) { Write-Host "  Trigger: At startup" }
Write-Host "  Trigger: At log off (on disconnect from user session)"
Write-Host ""
Write-Host "To change or remove: Task Scheduler (taskschd.msc) -> Task Scheduler Library"
Write-Host "To uninstall: .\install-scheduled-task.ps1 -Uninstall"
