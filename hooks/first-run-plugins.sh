#!/bin/bash
# Check if first run after claudesync setup
# If flag exists, signal to Claude to show plugin recommendations

FLAG_FILE="$HOME/.claude/.claudesync-first-run"

if [[ -f "$FLAG_FILE" ]]; then
    echo "CLAUDESYNC_FIRST_RUN=true"
fi
