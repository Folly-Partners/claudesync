#!/bin/bash

# Check if andrews-plugin setup has been completed
# Runs on SessionStart - only triggers setup if needed

PLUGIN_DIR="$(dirname "$(dirname "$0")")"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.claude.config-sync.plist"
SETUP_MARKER="$HOME/.claude/.setup-complete"

# Check if setup is already complete
if [ -f "$SETUP_MARKER" ] && [ -f "$LAUNCHD_PLIST" ]; then
    exit 0  # Already set up
fi

# Check if deep-env is installed
if ! command -v deep-env &> /dev/null && [ ! -f "$HOME/.local/bin/deep-env" ]; then
    echo "⚠️  andrews-plugin: deep-env not installed"
    echo "   Run: ~/.claude/setup-new-computer.sh"
    exit 0  # Don't block, just warn
fi

# Check if launchd agent exists
if [ ! -f "$LAUNCHD_PLIST" ]; then
    echo "⚠️  andrews-plugin: Sync agent not installed"
    echo "   Run: ~/.claude/setup-new-computer.sh"
    exit 0  # Don't block, just warn
fi

# Mark as complete if all checks pass
touch "$SETUP_MARKER"
exit 0
