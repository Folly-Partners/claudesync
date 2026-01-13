#!/bin/bash
# Auto-sync plugin to GitHub (runs via LaunchAgent)

PLUGIN_DIR="$HOME/andrews-plugin"
LOG_FILE="$PLUGIN_DIR/sync.log"
LAST_SYNC_FILE="$PLUGIN_DIR/.last_sync_date"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# Skip if already synced today
today=$(date '+%Y-%m-%d')
if [ -f "$LAST_SYNC_FILE" ] && [ "$(cat "$LAST_SYNC_FILE")" = "$today" ]; then
    exit 0
fi

# Skip if no internet
ping -c 1 github.com >/dev/null 2>&1 || exit 0

cd "$PLUGIN_DIR" || exit 1

log "Starting sync..."

# Pull, commit, push
git pull origin main >> "$LOG_FILE" 2>&1
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Auto-sync $(date '+%Y-%m-%d %H:%M')" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
fi

echo "$today" > "$LAST_SYNC_FILE"
log "Sync complete"
