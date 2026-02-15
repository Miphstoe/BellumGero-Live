<#
.SYNOPSIS
    Commits and pushes dev env (.cursor/, README.md) to branch Ender_CursorConfig.

.DESCRIPTION
    Ensures the config branch stays in sync with local changes to Cursor rules,
    context, skills, and the workspace README. Only .cursor/ and root README.md
    are added; .gitignore is respected (e.g. .cursor/extensions/, .cursor/projects/
    are not committed). Safe to run manually or on a schedule (e.g. Task Scheduler).
    If the repo is on another branch, we stash only the dev-env paths, switch to
    Ender_CursorConfig, commit and push, then switch back so we don't touch game code.

.PARAMETER RepoPath
    Path to the swg-bg repo root. Default: current directory (run from repo root).

.EXAMPLE
    .\sync-config-branch.ps1
    Run from repo root; uses (Get-Location).Path as RepoPath.

.EXAMPLE
    .\sync-config-branch.ps1 -RepoPath "C:\Users\Shadow\code\swg-bg"
    Run from anywhere; specify repo path.

.NOTES
    Dev env commit workflow: see .cursor/rules/bellum-gero.mdc (code branch first,
    Ender_CursorConfig last). This script only pushes dev env; it does not commit
    game code. See .cursor/skills/sync-config-branch/scripts/README.md for scheduling.
#>

param(
    [string]$RepoPath = (Get-Location).Path
)

$ConfigBranch = "Ender_CursorConfig"
Set-Location $RepoPath

# Quick exit if there are no changes under dev-env paths (.gitignore is respected by git add)
$status = git status --short .cursor README.md 2>&1
if (-not $status) {
    Write-Host "No uncommitted dev env changes; $ConfigBranch is already in sync."
    exit 0
}

$currentBranch = git branch --show-current

if ($currentBranch -eq $ConfigBranch) {
    # Already on config branch: stage dev-env paths, commit if there is something to commit, push
    git add .cursor/
    git add README.md
    $changed = git status --short
    if (-not $changed) {
        Write-Host "Nothing to commit (paths already staged or clean)."
        exit 0
    }
    git commit -m "Dev env: rules, context, skills, .cursor README"
    git push origin $ConfigBranch
    exit $LASTEXITCODE
}

# We're on another branch (e.g. Main). Stash only .cursor and README so that
# checkout Ender_CursorConfig doesn't overwrite our working copy; we'll pop on
# the config branch, add/commit/push, then return to the original branch.
git stash push -m "sync-config-branch temp" -- .cursor README.md 2>$null
$stashed = $LASTEXITCODE -eq 0

$branchExists = git rev-parse --verify $ConfigBranch 2>$null
if (-not $branchExists) {
    git checkout -b $ConfigBranch
} else {
    git checkout $ConfigBranch
}
if ($LASTEXITCODE -ne 0) {
    if ($stashed) { git stash pop 2>$null }
    Write-Error "Checkout failed. You may have uncommitted changes outside .cursor/ and README.md; stash or commit them first."
    exit 1
}
if ($stashed) { git stash pop 2>$null }

# Stage, commit, push (only dev-env paths)
git add .cursor/
git add README.md
$staged = git diff --cached --name-only
if (-not $staged) {
    git checkout $currentBranch
    Write-Host "No dev env changes to commit after switching to $ConfigBranch."
    exit 0
}
git commit -m "Dev env: rules, context, skills, .cursor README"
git push origin $ConfigBranch
$pushOk = $LASTEXITCODE
git checkout $currentBranch
exit $pushOk
