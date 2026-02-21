param(
    [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$fail = $false

function PassMsg([string]$Message) {
    Write-Host "PASS: $Message"
}

function FailMsg([string]$Message) {
    Write-Host "FAIL: $Message"
    $script:fail = $true
}

Set-Location $RepoPath

$repoRoot = ""
try {
    $repoRoot = (git rev-parse --show-toplevel).Trim()
    PassMsg "Git repository detected: $repoRoot"
} catch {
    FailMsg "Not inside a git repository."
}

if ($repoRoot) {
    if ($repoRoot -match 'localswgserver$') {
        PassMsg "Repo root is localswgserver."
    } else {
        FailMsg "Repo root is not localswgserver: $repoRoot"
    }
}

$branch = ""
try {
    $branch = (git branch --show-current).Trim()
} catch {
}

if ($branch) {
    PassMsg "Current branch: $branch"
} else {
    FailMsg "Unable to detect current branch."
}

$statusShort = (git status --short)
if ([string]::IsNullOrWhiteSpace($statusShort)) {
    PassMsg "Working tree is clean."
} else {
    FailMsg "Working tree is dirty. Commit/stash before merge."
    Write-Host $statusShort
}

$stashPreview = (git stash list --max-count=3)
if ([string]::IsNullOrWhiteSpace($stashPreview)) {
    PassMsg "No recent stashes."
} else {
    PassMsg "Recent stashes:"
    Write-Host $stashPreview
}

try {
    git fetch origin --prune | Out-Null
    PassMsg "Fetched origin --prune successfully."
} catch {
    FailMsg "git fetch origin --prune failed."
}

if ($fail) {
    Write-Host ""
    Write-Host "BLOCK: Do not merge until all FAIL checks are resolved."
    exit 1
}

Write-Host ""
Write-Host "READY: Pre-merge checks passed."
