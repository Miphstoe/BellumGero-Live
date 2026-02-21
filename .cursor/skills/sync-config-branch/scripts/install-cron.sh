#!/usr/bin/env bash
#
# Installs a cron job to run sync-config-branch.sh on a schedule (WSL/Linux).
# Same idea as install-scheduled-task.ps1 on Windows: keep Ender_CursorConfig
# in sync so Shadow PC and WSL dev desktop stay aligned.
#
# Usage:
#   ./install-cron.sh              # install: daily 18:00, optional @reboot
#   ./install-cron.sh -u           # uninstall (remove our crontab line)
#   ./install-cron.sh -r           # add @reboot trigger (run once at login)
#
# Options:
#   -u          Uninstall: remove the cron entry.
#   -r          Add @reboot (run once when cron starts, e.g. after WSL/login).
#   -h HOUR     Daily hour (0-23). Default: 18 (6 PM).
#   -m MINUTE   Daily minute. Default: 0.
#   -p PATH     Repo path. Default: inferred from script location (~/localswgserver).
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATH="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-config-branch.sh"
CRON_MARKER="SWG-BG sync Ender_CursorConfig"
DAILY_HOUR=18
DAILY_MINUTE=0
UNINSTALL=false
AT_REBOOT=false

while getopts "urh:m:p:" opt; do
  case $opt in
    u) UNINSTALL=true ;;
    r) AT_REBOOT=true ;;
    h) DAILY_HOUR="$OPTARG" ;;
    m) DAILY_MINUTE="$OPTARG" ;;
    p) REPO_PATH="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

if [ ! -x "$SYNC_SCRIPT" ]; then
  chmod +x "$SYNC_SCRIPT"
fi

# Crontab line we add (comment + entry)
CRON_LINE="# $CRON_MARKER - dev env sync to Ender_CursorConfig
$DAILY_MINUTE $DAILY_HOUR * * * REPO_PATH='$REPO_PATH' '$SYNC_SCRIPT'"

if [ "$UNINSTALL" = true ]; then
  # Remove our comment line and the following schedule line
  (crontab -l 2>/dev/null | awk -v m="$CRON_MARKER" '
    /SWG-BG sync Ender_CursorConfig/ { skip=2; next }
    skip { skip--; next }
    { print }
  ' || true) | crontab -
  echo "Cron entry for '$CRON_MARKER' removed."
  exit 0
fi

# Install: remove any existing line with our marker, then add new one
EXISTING="$(crontab -l 2>/dev/null || true)"
NEW_CRON="$(echo "$EXISTING" | grep -v "$CRON_MARKER" | grep -v "^# SWG-BG sync" || true)"
NEW_CRON="$NEW_CRON
$CRON_LINE"
if [ "$AT_REBOOT" = true ]; then
  NEW_CRON="$NEW_CRON
@reboot REPO_PATH='$REPO_PATH' '$SYNC_SCRIPT'"
fi
echo "$NEW_CRON" | crontab -

echo "Cron installed for $CRON_MARKER"
echo "  Repo:   $REPO_PATH"
echo "  Daily:  $DAILY_HOUR:$(printf '%02d' $DAILY_MINUTE)"
[ "$AT_REBOOT" = true ] && echo "  Also:   @reboot"
echo ""
echo "To edit: crontab -e"
echo "To uninstall: $0 -u"
