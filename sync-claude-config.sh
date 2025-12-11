#!/bin/bash

# Claude Code Configuration Auto-Sync Script
# Syncs Claude Code settings to GitHub repository

LOG_FILE="$HOME/.claude/sync.log"
CONFIG_DIR="$HOME/.claude"
LAST_SYNC_FILE="$HOME/.claude/.last_sync_date"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if we're connected to the internet
check_internet() {
    if ping -c 1 github.com >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if we've already synced today
already_synced_today() {
    local today=$(date '+%Y-%m-%d')
    if [ -f "$LAST_SYNC_FILE" ]; then
        local last_sync=$(cat "$LAST_SYNC_FILE" 2>/dev/null || echo "")
        if [ "$last_sync" = "$today" ]; then
            return 0  # Already synced today
        fi
    fi
    return 1  # Not synced today
}

# Function to mark today as synced
mark_synced_today() {
    local today=$(date '+%Y-%m-%d')
    echo "$today" > "$LAST_SYNC_FILE"
}

# Function to sync config
sync_config() {
    log "Starting Claude Code config sync..."

    cd "$CONFIG_DIR" || {
        log "ERROR: Could not change to $CONFIG_DIR"
        exit 1
    }

    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet; then
        # Check for untracked files
        if [ -z "$(git ls-files --others --exclude-standard)" ]; then
            log "No changes to sync"
            return 0
        fi
    fi

    # Pull any remote changes first
    log "Pulling remote changes..."
    if ! git pull origin main; then
        log "ERROR: Failed to pull remote changes"
        return 1
    fi

    # Add all changes (respects .gitignore)
    git add .

    # Check if there's anything to commit
    if git diff --cached --quiet; then
        log "No changes to commit after adding files"
        return 0
    fi

    # Commit changes
    local commit_msg="Auto-sync Claude Code config - $(date '+%Y-%m-%d %H:%M:%S')

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

    if git commit -m "$commit_msg"; then
        log "Successfully committed changes"
    else
        log "ERROR: Failed to commit changes"
        return 1
    fi

    # Push to remote
    if git push origin main; then
        log "Successfully pushed to remote"
        mark_synced_today
        return 0
    else
        log "ERROR: Failed to push to remote"
        return 1
    fi
}

# Main execution
main() {
    log "Claude Code sync script started"

    # Check if already synced today
    if already_synced_today; then
        log "Already synced today - skipping"
        exit 0
    fi

    # Check internet connectivity
    if ! check_internet; then
        log "No internet connection - skipping sync"
        exit 0
    fi

    # Perform sync
    if sync_config; then
        log "Sync completed successfully"
    else
        log "Sync failed"
        exit 1
    fi
}

# Run main function
main "$@"