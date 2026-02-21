#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="${1:-$PWD}"
cd "$REPO_PATH"

fail=0

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'FAIL: %s\n' "$1"
  fail=1
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  warn "Not inside a git repository."
else
  pass "Git repository detected: $repo_root"
fi

if [[ -n "$repo_root" ]]; then
  if [[ "$repo_root" == *"/localswgserver" ]]; then
    pass "Repo root is localswgserver."
  else
    warn "Repo root is not localswgserver: $repo_root"
  fi
fi

branch="$(git branch --show-current 2>/dev/null || true)"
if [[ -n "$branch" ]]; then
  pass "Current branch: $branch"
else
  warn "Unable to detect current branch."
fi

status_short="$(git status --short 2>/dev/null || true)"
if [[ -z "$status_short" ]]; then
  pass "Working tree is clean."
else
  warn "Working tree is dirty. Commit/stash before merge."
  printf '%s\n' "$status_short"
fi

stash_preview="$(git stash list --max-count=3 2>/dev/null || true)"
if [[ -z "$stash_preview" ]]; then
  pass "No recent stashes."
else
  pass "Recent stashes:"
  printf '%s\n' "$stash_preview"
fi

if git fetch origin --prune >/dev/null 2>&1; then
  pass "Fetched origin --prune successfully."
else
  warn "git fetch origin --prune failed."
fi

if [[ "$fail" -ne 0 ]]; then
  printf '\nBLOCK: Do not merge until all FAIL checks are resolved.\n'
  exit 1
fi

printf '\nREADY: Pre-merge checks passed.\n'
