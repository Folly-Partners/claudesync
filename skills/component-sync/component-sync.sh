#!/bin/bash
# ClaudeSync Component Sync
# Automatically syncs skills, servers, commands, hooks, agents across Macs via iCloud
# Runs at SessionStart, completely invisible unless action needed

# P2-PAT-002: Standardized error handling
set -eo pipefail  # Exit on error, pipe failures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
LAST_RUN_FILE="$CLAUDE_DIR/.component-sync-last-run"
LOCK_FILE="$CLAUDE_DIR/.component-sync.lock"
IN_PROGRESS_FILE="$CLAUDE_DIR/.component-sync-in-progress"
MACHINE_ID_FILE="$CLAUDE_DIR/.component-sync-machine-id"
STATE_FILE="$CLAUDE_DIR/.component-sync-state.json"
CONFLICTS_LOG="$CLAUDE_DIR/.claudesync-conflicts.log"
BUILD_LOG="$CLAUDE_DIR/.component-sync-build.log"
BACKUPS_DIR="$CLAUDE_DIR/.component-sync-backups"

REGISTRY="$HOME/Library/Mobile Documents/com~apple~CloudDocs/.claudesync"
PLUGIN_DIR="$HOME/.claude/plugins/marketplaces/Folly"

COOLDOWN_SECONDS=86400  # 24 hours
CONFLICT_WINDOW=300     # 5 minutes

# Track if we need to notify about restart
NEEDS_RESTART=false
SYNCED_COMPONENTS=()
DRY_RUN=0  # P3-ARCH-004: Preview mode

# Source library functions
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/push.sh"
source "$SCRIPT_DIR/lib/pull.sh"
source "$SCRIPT_DIR/lib/build.sh"
source "$SCRIPT_DIR/lib/manifest.sh"

# ============================================================================
# Utility Functions
# ============================================================================

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

log_info() {
    echo "$*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# P2-PAT-002: Helper for fatal errors
die() {
    log_error "$1"
    exit "${2:-1}"
}

get_machine_id() {
    if [ ! -f "$MACHINE_ID_FILE" ]; then
        hostname -s > "$MACHINE_ID_FILE"
    fi
    cat "$MACHINE_ID_FILE"
}

# P2-ARCH-002: Check required dependencies before running
check_dependencies() {
    local missing=()
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v tar >/dev/null 2>&1 || missing+=("tar")
    command -v rsync >/dev/null 2>&1 || missing+=("rsync")
    command -v shasum >/dev/null 2>&1 || missing+=("shasum")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_error "Install with: brew install ${missing[*]}"
        return 1
    fi
    return 0
}

# ============================================================================
# Lock Management (P2-SEC-002: Use flock for atomic locking)
# ============================================================================

acquire_lock() {
    # Use flock for atomic lock acquisition (avoids TOCTOU race condition)
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        log_debug "Another sync is running"
        return 1
    fi
    # Lock acquired - write PID for debugging purposes
    echo $$ >&200
    trap 'rm -f "$LOCK_FILE" "$IN_PROGRESS_FILE"' EXIT
    return 0
}

# ============================================================================
# Rate Limiting
# ============================================================================

check_cooldown() {
    local force="$1"

    if [ "$force" = "true" ]; then
        log_debug "Cooldown bypassed (--force)"
        return 0
    fi

    if [ ! -f "$LAST_RUN_FILE" ]; then
        log_debug "No previous run recorded"
        return 0
    fi

    local last_run=$(cat "$LAST_RUN_FILE")
    local now=$(date +%s)
    local elapsed=$((now - last_run))

    if [ $elapsed -lt $COOLDOWN_SECONDS ]; then
        local remaining=$(( (COOLDOWN_SECONDS - elapsed) / 3600 ))
        log_debug "Cooldown active: ${remaining}h remaining"
        return 1
    fi

    return 0
}

update_last_run() {
    date +%s > "$LAST_RUN_FILE"
}

# ============================================================================
# Interrupted Sync Detection
# ============================================================================

check_interrupted_sync() {
    if [ -f "$IN_PROGRESS_FILE" ]; then
        local started=$(cat "$IN_PROGRESS_FILE")
        local now=$(date +%s)
        local age=$((now - started))

        if [ $age -gt 300 ]; then  # More than 5 minutes old
            log_info "Warning: Previous sync may have been interrupted"
            rm -f "$IN_PROGRESS_FILE"
        fi
    fi
}

mark_sync_start() {
    date +%s > "$IN_PROGRESS_FILE"
}

mark_sync_complete() {
    rm -f "$IN_PROGRESS_FILE"
}

# ============================================================================
# Status Command
# ============================================================================

show_status() {
    echo "ClaudeSync Component Status"
    echo "============================"
    echo ""

    # Machine info
    echo "Machine: $(get_machine_id)"

    # Last sync time
    if [ -f "$LAST_RUN_FILE" ]; then
        local last_run=$(cat "$LAST_RUN_FILE")
        local last_run_date=$(date -r "$last_run" "+%Y-%m-%d %H:%M:%S")
        echo "Last sync: $last_run_date"
    else
        echo "Last sync: Never"
    fi

    # Registry status
    if [ -d "$REGISTRY" ]; then
        echo "Registry: OK"
        if [ -f "$REGISTRY/manifest.json" ]; then
            local component_count=$(jq -r '.components | keys | length' "$REGISTRY/manifest.json" 2>/dev/null || echo "?")
            echo "Components tracked: $component_count"
        fi
    else
        echo "Registry: Not initialized"
    fi

    # Plugin status
    if [ -d "$PLUGIN_DIR" ]; then
        echo "Plugin: Installed"
    else
        echo "Plugin: Not installed"
    fi

    # Conflicts
    if [ -f "$CONFLICTS_LOG" ]; then
        local conflict_count=$(wc -l < "$CONFLICTS_LOG" | tr -d ' ')
        echo "Conflicts logged: $conflict_count"
    else
        echo "Conflicts logged: 0"
    fi

    echo ""

    # Show component hashes if available
    if [ -f "$STATE_FILE" ]; then
        echo "Local component hashes:"
        jq -r 'to_entries[] | "  \(.key): \(.value)"' "$STATE_FILE" 2>/dev/null || echo "  (unable to read state)"
    fi
}

# ============================================================================
# Rollback Command
# ============================================================================

do_rollback() {
    local component="$1"

    if [ -z "$component" ]; then
        echo "Usage: component-sync.sh --rollback <component>"
        echo "Example: component-sync.sh --rollback skills/my-skill"
        exit 1
    fi

    # P2-SEC-003: Validate component name to prevent path traversal
    if [[ "$component" == *".."* ]] || [[ "$component" == /* ]]; then
        log_error "Invalid component name: path traversal not allowed"
        exit 1
    fi

    # Validate component follows expected pattern (type/name)
    if ! [[ "$component" =~ ^(skills|servers|commands|hooks|agents)/[a-zA-Z0-9_-]+$ ]] && \
       ! [[ "$component" =~ ^(mcp-config|global-commands|user-claude-md)$ ]]; then
        log_error "Invalid component format. Expected: skills/name, servers/name, etc."
        exit 1
    fi

    local backup_path="$BACKUPS_DIR/$component"
    local target_path="$PLUGIN_DIR/$component"

    # Additional safety: verify resolved paths are within expected directories
    local resolved_backup
    local resolved_target
    resolved_backup=$(cd "$(dirname "$backup_path")" 2>/dev/null && pwd)/$(basename "$backup_path") || {
        log_error "Invalid backup path"
        exit 1
    }
    resolved_target=$(cd "$(dirname "$target_path")" 2>/dev/null && pwd)/$(basename "$target_path") || {
        log_error "Invalid target path"
        exit 1
    }

    if [[ "$resolved_backup" != "$BACKUPS_DIR"/* ]]; then
        log_error "Backup path escapes backup directory"
        exit 1
    fi

    if [[ "$resolved_target" != "$PLUGIN_DIR"/* ]]; then
        log_error "Target path escapes plugin directory"
        exit 1
    fi

    if [ ! -d "$backup_path" ] && [ ! -f "$backup_path" ]; then
        log_error "No backup found for: $component"
        echo "Available backups:"
        find "$BACKUPS_DIR" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sed "s|$BACKUPS_DIR/||" | sort
        exit 1
    fi

    # Perform rollback
    rm -rf "$target_path"
    cp -r "$backup_path" "$target_path"

    log_info "Rolled back: $component"
}

# ============================================================================
# Main Sync Logic
# ============================================================================

do_sync() {
    local force="$1"

    # Check prerequisites
    if [ ! -d "$PLUGIN_DIR" ]; then
        log_debug "Plugin not installed, skipping sync"
        return 0
    fi

    # Initialize registry if needed
    init_registry_if_needed

    # Check for interrupted sync
    check_interrupted_sync

    # Mark sync in progress
    mark_sync_start

    # Compute local hashes (use secure temp file)
    log_debug "Computing local hashes..."
    local temp_hashes
    temp_hashes=$(mktemp) || { log_error "Failed to create temp file"; return 1; }
    trap "rm -f '$temp_hashes'" EXIT
    compute_all_local_hashes "$PLUGIN_DIR" > "$temp_hashes"

    # Load remote manifest
    local remote_manifest="$REGISTRY/manifest.json"

    # Compare and sync
    local machine_id=$(get_machine_id)
    local now=$(date +%s)

    # Get lists of what needs pushing and pulling (uses global arrays)
    diff_components "$temp_hashes" "$remote_manifest"

    # Push local changes (from global DIFF_TO_PUSH array)
    for component in "${DIFF_TO_PUSH[@]}"; do
        if [ "$DRY_RUN" = "1" ]; then
            log_info "[DRY-RUN] Would push: $component"
        else
            log_debug "Pushing: $component"
            if push_component "$PLUGIN_DIR" "$component" "$machine_id"; then
                log_debug "Pushed: $component"
            fi
        fi
    done

    # Pull remote changes (from global DIFF_TO_PULL array)
    for component in "${DIFF_TO_PULL[@]}"; do
        if [ "$DRY_RUN" = "1" ]; then
            log_info "[DRY-RUN] Would pull: $component"
        else
            log_debug "Pulling: $component"
            if pull_component "$PLUGIN_DIR" "$component"; then
                SYNCED_COMPONENTS+=("$component")

                # Check if this component needs restart
                case "$component" in
                    mcp-config|hooks)
                        NEEDS_RESTART=true
                        ;;
                esac

                # Rebuild if it's a server
                if [[ "$component" == servers/* ]]; then
                    local server_name="${component#servers/}"
                    if build_server_safe "$server_name"; then
                        log_debug "Built: $server_name"
                    else
                        log_error "Build failed: $server_name (check $BUILD_LOG)"
                    fi
                fi
            fi
        fi
    done

    # Update local state (skip in dry-run mode)
    if [ "$DRY_RUN" != "1" ]; then
        mv "$temp_hashes" "$STATE_FILE"
        trap - EXIT  # Remove trap since we moved the file

        # Update machine state in registry
        update_machine_state "$machine_id" "$now"

        # Mark sync complete
        mark_sync_complete
        update_last_run
    else
        rm -f "$temp_hashes"
        trap - EXIT
        log_info "[DRY-RUN] Skipped state updates"
    fi

    # Output summary if anything changed
    if [ ${#SYNCED_COMPONENTS[@]} -gt 0 ]; then
        echo ""
        for component in "${SYNCED_COMPONENTS[@]}"; do
            echo "  Synced: $component"
        done
    fi

    if [ "$NEEDS_RESTART" = true ]; then
        echo ""
        echo "  Claude Code restart required for changes to take effect"
    fi

    # Cleanup handled by mv above (temp_hashes moved to STATE_FILE)
}

# ============================================================================
# Entry Point
# ============================================================================

main() {
    local force=false
    local action="sync"
    local rollback_target=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --force|-f)
                force=true
                shift
                ;;
            --status|-s)
                action="status"
                shift
                ;;
            --rollback|-r)
                action="rollback"
                rollback_target="$2"
                shift 2
                ;;
            --dry-run|-n)
                # P3-ARCH-004: Preview mode
                DRY_RUN=1
                shift
                ;;
            --debug|-d)
                DEBUG=1
                shift
                ;;
            --help|-h)
                echo "Usage: component-sync.sh [options]"
                echo ""
                echo "Options:"
                echo "  --force, -f           Force sync (ignore 24h cooldown)"
                echo "  --status, -s          Show sync status"
                echo "  --rollback, -r <comp> Rollback a component"
                echo "  --dry-run, -n         Preview changes without applying"
                echo "  --debug, -d           Enable debug output"
                echo "  --help, -h            Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Ensure .claude directory exists
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$BACKUPS_DIR"

    # Check dependencies (except for help which already exited)
    if ! check_dependencies; then
        exit 1
    fi

    # Execute action
    case "$action" in
        status)
            show_status
            ;;
        rollback)
            do_rollback "$rollback_target"
            ;;
        sync)
            # Check cooldown
            if ! check_cooldown "$force"; then
                exit 0
            fi

            # Acquire lock
            if ! acquire_lock; then
                exit 0
            fi

            do_sync "$force"
            ;;
    esac
}

main "$@"
