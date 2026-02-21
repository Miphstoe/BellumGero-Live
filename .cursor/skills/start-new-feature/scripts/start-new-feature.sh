#!/usr/bin/env bash
#
# Start a new feature branch: update Ender_CursorConfig from Main, create branch
# from Ender_CursorConfig, then add .cursor and dev docs to .gitignore and
# remove from tracking so they never merge into Main.
#
# Usage: ./start-new-feature.sh Ender_FeatureName
# Example: ./start-new-feature.sh Ender_MissingResources
#
# Run from repo root (e.g. ~/localswgserver). See .cursor/skills/start-new-feature/SKILL.md

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 Ender_FeatureName"
  echo "Example: $0 Ender_MissingResources"
  exit 1
fi

FEATURE_BRANCH="$1"
CONFIG_BRANCH="Ender_CursorConfig"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$REPO_ROOT"

echo "=== 1. Update $CONFIG_BRANCH from Main ==="
git fetch origin Main
git checkout "$CONFIG_BRANCH"
git pull origin "$CONFIG_BRANCH" 2>/dev/null || true
if ! git merge origin/Main -m "Merge Main into $CONFIG_BRANCH"; then
  echo "Merge had conflicts. Resolve .gitignore (keep version that tracks .cursor), then:"
  echo "  git add .gitignore && git commit -m 'Merge Main into $CONFIG_BRANCH (resolve .gitignore)'"
  echo "  git push origin $CONFIG_BRANCH"
  echo "Then re-run: $0 $FEATURE_BRANCH"
  exit 1
fi
git push origin "$CONFIG_BRANCH"

echo ""
echo "=== 2. Create feature branch $FEATURE_BRANCH from $CONFIG_BRANCH ==="
git checkout "$CONFIG_BRANCH"
git pull origin "$CONFIG_BRANCH" 2>/dev/null || true
git checkout -b "$FEATURE_BRANCH"

echo ""
echo "=== 3. Ignore .cursor and dev docs on this branch ==="
GITIGNORE_DEV="# Dev env – only tracked on Ender_CursorConfig; do not commit on feature branches or Main
.cursor/
.cursorrules
BELLUM_GERO_WINDCLAW_RAPTOR_DANTOOINE_AVIAN_MEAT.md
CHANGELOG.md
LOCAL_DEV_ENV_SETUP.md
SWG_ADMIN_COMMANDS_CONTEXT.md
SWG_CONTEXT.md
SWG_FILE_CODE_STRUCUTRE_CONTEXT.md
cursor_cursor_wsl_extension_project_fol.md
"

if ! grep -q "^\.cursor/$" .gitignore 2>/dev/null; then
  echo "$GITIGNORE_DEV" >> .gitignore
fi

git add .gitignore
git rm -r --cached .cursor 2>/dev/null || true
git rm --cached .cursorrules CHANGELOG.md LOCAL_DEV_ENV_SETUP.md SWG_ADMIN_COMMANDS_CONTEXT.md SWG_CONTEXT.md SWG_FILE_CODE_STRUCUTRE_CONTEXT.md cursor_cursor_wsl_extension_project_fol.md 2>/dev/null || true
git commit -m "Feature branch: ignore .cursor and dev docs (do not merge into Main)" || true

echo ""
echo "Done. On branch $FEATURE_BRANCH. Start feature work."
