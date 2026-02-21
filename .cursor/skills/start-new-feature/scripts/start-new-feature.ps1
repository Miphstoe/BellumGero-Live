<#
.SYNOPSIS
    Start a new feature branch: update Ender_CursorConfig from Main, create branch from Ender_CursorConfig, then add .cursor and dev docs to .gitignore so they never merge into Main.

.DESCRIPTION
    Same workflow as start-new-feature.sh (WSL). Use on Shadow PC. Run from repo root (e.g. C:\Users\Shadow\code\swg-bg).

.PARAMETER FeatureBranch
    Name of the new feature branch (e.g. Ender_MissingResources).

.PARAMETER RepoPath
    Path to the repo root. Default: current directory.

.EXAMPLE
    .\start-new-feature.ps1 -FeatureBranch Ender_MissingResources

.EXAMPLE
    .\start-new-feature.ps1 -FeatureBranch Ender_NewFeature -RepoPath "C:\Users\Shadow\code\swg-bg"

.NOTES
    See .cursor/skills/start-new-feature/SKILL.md and rules/feature-branch-workflow.mdc.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureBranch,
    [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$ConfigBranch = "Ender_CursorConfig"

Set-Location $RepoPath

# --- 1. Update Ender_CursorConfig from Main ---
Write-Host "=== 1. Update $ConfigBranch from Main ===" -ForegroundColor Cyan
git fetch origin Main
git checkout $ConfigBranch
git pull origin $ConfigBranch 2>$null
$mergeResult = git merge origin/Main -m "Merge Main into $ConfigBranch" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Merge had conflicts. Resolve .gitignore (keep version that tracks .cursor), then:" -ForegroundColor Yellow
    Write-Host "  git add .gitignore && git commit -m 'Merge Main into $ConfigBranch (resolve .gitignore)'"
    Write-Host "  git push origin $ConfigBranch"
    Write-Host "Then re-run: .\start-new-feature.ps1 -FeatureBranch $FeatureBranch"
    exit 1
}
git push origin $ConfigBranch

# --- 2. Create feature branch from Ender_CursorConfig ---
Write-Host ""
Write-Host "=== 2. Create feature branch $FeatureBranch from $ConfigBranch ===" -ForegroundColor Cyan
git checkout $ConfigBranch
git pull origin $ConfigBranch 2>$null
git checkout -b $FeatureBranch

# --- 3. Ignore .cursor and dev docs on this branch ---
Write-Host ""
Write-Host "=== 3. Ignore .cursor and dev docs on this branch ===" -ForegroundColor Cyan
$gitignoreBlock = @"
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
"@

$gitignorePath = Join-Path $RepoPath ".gitignore"
$content = Get-Content $gitignorePath -Raw -ErrorAction SilentlyContinue
if ($content -notmatch "\.cursor/") {
    Add-Content -Path $gitignorePath -Value $gitignoreBlock
}

git add .gitignore
git rm -r --cached .cursor 2>$null
git rm --cached .cursorrules CHANGELOG.md LOCAL_DEV_ENV_SETUP.md SWG_ADMIN_COMMANDS_CONTEXT.md SWG_CONTEXT.md SWG_FILE_CODE_STRUCUTRE_CONTEXT.md cursor_cursor_wsl_extension_project_fol.md 2>$null
git commit -m "Feature branch: ignore .cursor and dev docs (do not merge into Main)" 2>$null

Write-Host ""
Write-Host "Done. On branch $FeatureBranch. Start feature work." -ForegroundColor Green
