#!/usr/bin/env bash
#
# Commits and pushes dev env (.cursor/, README.md) to branch Ender_CursorConfig.
# Use on WSL/Linux to keep this env in sync with Shadow PC. Same behavior as
# sync-config-branch.ps1. Respects .gitignore (e.g. .cursor/extensions/ not committed).
# Run manually or via cron (see install-cron.sh).
#
# Usage:
#   ./sync-config-branch.sh              # run from repo root
#   ./sync-config-branch.sh /path/to/repo
#   REPO_PATH=/path/to/repo ./sync-config-branch.sh
#
# See .cursor/rules/bellum-gero.mdc (code branch first, Ender_CursorConfig last).

set -e

CONFIG_BRANCH="Ender_CursorConfig"

# Repo root: first arg, or REPO_PATH env, or 4 levels up from this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$1" ]; then
  REPO_PATH="$1"
elif [ -n "$REPO_PATH" ]; then
  :
else
  REPO_PATH="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi

cd "$REPO_PATH"

# No changes under dev-env paths? Exit clean.
if ! git status --short .cursor README.md 2>/dev/null | grep -q .; then
  echo "No uncommitted dev env changes; $CONFIG_BRANCH is already in sync."
  exit 0
fi

CURRENT_BRANCH="$(git branch --show-current)"

if [ "$CURRENT_BRANCH" = "$CONFIG_BRANCH" ]; then
  git add .cursor/
  git add README.md 2>/dev/null || true
  if ! git diff --cached --name-only | grep -q .; then
    echo "Nothing to commit (paths already staged or clean)."
    exit 0
  fi
  git commit -m "Dev env: rules, context, skills, .cursor README"
  git push origin "$CONFIG_BRANCH"
  exit $?
fi

# On another branch: stash dev-env paths, switch to config, pop, commit, push, switch back.
git stash push -m "sync-config-branch temp" -- .cursor README.md 2>/dev/null || true
STASHED=$?

if git rev-parse --verify "$CONFIG_BRANCH" &>/dev/null; then
  git checkout "$CONFIG_BRANCH"
else
  git checkout -b "$CONFIG_BRANCH"
fi

if [ $STASHED -eq 0 ]; then
  git stash pop 2>/dev/null || true
fi

git add .cursor/
git add README.md 2>/dev/null || true
if ! git diff --cached --name-only | grep -q .; then
  git checkout "$CURRENT_BRANCH"
  echo "No dev env changes to commit after switching to $CONFIG_BRANCH."
  exit 0
fi

git commit -m "Dev env: rules, context, skills, .cursor README"
PUSH_EXIT=0
git push origin "$CONFIG_BRANCH" || PUSH_EXIT=$?
git checkout "$CURRENT_BRANCH"
exit $PUSH_EXIT
