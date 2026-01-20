#!/bin/bash
# Pull components from iCloud registry
# Includes validation, backup, and safe extraction

# ============================================================================
# iCloud Sync Waiting
# ============================================================================

# Wait for iCloud to finish syncing a file (uses exponential backoff)
wait_for_icloud_sync() {
    local file="$1"
    local max_wait="${2:-30}"
    local delay=0.1
    local max_delay=2
    local total_wait=0

    # Check for iCloud placeholder (file not downloaded yet)
    # iCloud placeholders have .icloud extension
    local icloud_placeholder="${file%/*}/.${file##*/}.icloud"

    # Exponential backoff while waiting for iCloud download
    while [ -f "$icloud_placeholder" ]; do
        # Check timeout using integer comparison (multiply by 10 to avoid bc)
        local total_int=${total_wait%.*}
        [ "${total_int:-0}" -ge "$max_wait" ] && return 1

        # Try to trigger download by reading the placeholder
        cat "$icloud_placeholder" > /dev/null 2>&1 || true
        sleep "$delay"
        total_wait=$(awk "BEGIN {print $total_wait + $delay}")
        delay=$(awk "BEGIN {d=$delay*2; print (d>$max_delay)?$max_delay:d}")
    done

    # Verify file exists and is stable (not being written)
    if [ ! -f "$file" ]; then
        return 1
    fi

    # Quick stability check with shorter initial delay
    local size1=$(stat -f%z "$file" 2>/dev/null || echo 0)
    sleep 0.2
    local size2=$(stat -f%z "$file" 2>/dev/null || echo 0)

    [ "$size1" = "$size2" ] && [ "$size1" -gt 0 ]
}

# ============================================================================
# Validation
# ============================================================================

# Validate a tarball is not corrupt
validate_tarball() {
    local tarball="$1"

    if [ ! -f "$tarball" ]; then
        return 1
    fi

    # Test tarball integrity
    tar -tzf "$tarball" > /dev/null 2>&1
}

# ============================================================================
# Backup Functions
# ============================================================================

# Create backup of a component
backup_component() {
    local target_path="$1"
    local component="$2"

    local backup_path="$BACKUPS_DIR/$component"

    # Remove old backup if exists
    rm -rf "$backup_path"

    # Create backup directory
    mkdir -p "$(dirname "$backup_path")"

    # Copy current state if it exists
    if [ -e "$target_path" ]; then
        cp -r "$target_path" "$backup_path"
    fi
}

# Restore from backup
restore_from_backup() {
    local target_path="$1"
    local component="$2"

    local backup_path="$BACKUPS_DIR/$component"

    if [ -d "$backup_path" ]; then
        rm -rf "$target_path"
        cp -r "$backup_path" "$target_path"
        return 0
    elif [ -f "$backup_path" ]; then
        rm -f "$target_path"
        cp "$backup_path" "$target_path"
        return 0
    fi

    return 1
}

# ============================================================================
# Pull Functions (P1-PAT-002: Consolidated to reduce duplication)
# ============================================================================

# Generic function to pull a tarball-based component (skills, servers)
# Usage: pull_tarball_component <tarball_path> <target_dir> <component_key> <name> [preserve_deps]
pull_tarball_component() {
    local tarball="$1"
    local target_dir="$2"
    local component_key="$3"
    local name="$4"
    local preserve_deps="${5:-false}"

    local temp_dir=$(mktemp -d)

    # Wait for iCloud sync
    if ! wait_for_icloud_sync "$tarball"; then
        log_debug "iCloud sync timeout for $component_key: $name"
        rm -rf "$temp_dir"
        return 1
    fi

    # Validate tarball
    if ! validate_tarball "$tarball"; then
        log_debug "Invalid tarball for $component_key: $name"
        rm -rf "$temp_dir"
        return 1
    fi

    # Backup current state
    backup_component "$target_dir" "$component_key/$name"

    # Extract to temp directory
    if ! tar -xzf "$tarball" -C "$temp_dir" 2>/dev/null; then
        log_debug "Extraction failed for $component_key: $name"
        rm -rf "$temp_dir"
        return 1
    fi

    # Handle dependency preservation for servers
    local old_node_modules=""
    local old_venv=""

    if [ "$preserve_deps" = "true" ]; then
        if [ -d "$target_dir/node_modules" ]; then
            old_node_modules=$(mktemp -d)
            mv "$target_dir/node_modules" "$old_node_modules/"
        fi
        if [ -d "$target_dir/venv" ]; then
            old_venv=$(mktemp -d)
            mv "$target_dir/venv" "$old_venv/"
        fi
    fi

    # Atomic replace
    rm -rf "$target_dir"
    mkdir -p "$(dirname "$target_dir")"
    mv "$temp_dir/$name" "$target_dir"

    # Restore dependencies if preserved
    if [ -n "$old_node_modules" ] && [ -d "$old_node_modules/node_modules" ]; then
        mv "$old_node_modules/node_modules" "$target_dir/"
        rm -rf "$old_node_modules"
    fi
    if [ -n "$old_venv" ] && [ -d "$old_venv/venv" ]; then
        mv "$old_venv/venv" "$target_dir/"
        rm -rf "$old_venv"
    fi

    rm -rf "$temp_dir"
    return 0
}

# Convenience wrappers for backward compatibility
pull_skill() {
    local plugin_dir="$1"
    local skill_name="$2"
    pull_tarball_component \
        "$REGISTRY/components/skills/${skill_name}.tar.gz" \
        "$plugin_dir/skills/$skill_name" \
        "skills" \
        "$skill_name"
}

pull_server() {
    local plugin_dir="$1"
    local server_name="$2"
    pull_tarball_component \
        "$REGISTRY/components/servers/${server_name}.tar.gz" \
        "$plugin_dir/servers/$server_name" \
        "servers" \
        "$server_name" \
        "true"  # Preserve node_modules/venv
}

# Pull commands from the registry
pull_commands() {
    local plugin_dir="$1"

    local source_dir="$REGISTRY/components/commands"
    local target_dir="$plugin_dir/commands"

    if [ ! -d "$source_dir" ]; then
        log_debug "No commands in registry"
        return 1
    fi

    # Backup current state
    backup_component "$target_dir" "commands"

    # Remove old and copy new
    rm -rf "$target_dir"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# Pull hooks from the registry
pull_hooks() {
    local plugin_dir="$1"

    local source_dir="$REGISTRY/components/hooks"
    local target_dir="$plugin_dir/hooks"

    if [ ! -d "$source_dir" ]; then
        log_debug "No hooks in registry"
        return 1
    fi

    # Backup current state
    backup_component "$target_dir" "hooks"

    # Remove old and copy new
    rm -rf "$target_dir"
    cp -r "$source_dir" "$target_dir"

    # Make hook scripts executable
    find "$target_dir" -name "*.sh" -exec chmod +x {} \;

    return 0
}

# Pull agents from the registry
pull_agents() {
    local plugin_dir="$1"

    local source_dir="$REGISTRY/components/agents"
    local target_dir="$plugin_dir/agents"

    if [ ! -d "$source_dir" ]; then
        log_debug "No agents in registry"
        return 1
    fi

    # Backup current state
    backup_component "$target_dir" "agents"

    # Remove old and copy new
    rm -rf "$target_dir"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# Pull MCP config from the registry
pull_mcp_config() {
    local plugin_dir="$1"

    local source_file="$REGISTRY/components/mcp-config.json"
    local target_file="$plugin_dir/.mcp.json"

    if [ ! -f "$source_file" ]; then
        log_debug "No MCP config in registry"
        return 1
    fi

    # Wait for iCloud sync
    if ! wait_for_icloud_sync "$source_file"; then
        log_debug "iCloud sync timeout for MCP config"
        return 1
    fi

    # Backup current state
    backup_component "$target_file" "mcp-config"

    # Copy new
    cp "$source_file" "$target_file"

    return 0
}

# Pull global commands from the registry to ~/.claude/commands
pull_global_commands() {
    local source_dir="$REGISTRY/components/global-commands"
    local target_dir="$HOME/.claude/commands"

    if [ ! -d "$source_dir" ]; then
        log_debug "No global commands in registry"
        return 1
    fi

    # Backup current state
    backup_component "$target_dir" "global-commands"

    # Create target if doesn't exist
    mkdir -p "$target_dir"

    # Remove old and copy new
    rm -rf "$target_dir"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# Pull user CLAUDE.md from the registry to ~/.claude/CLAUDE.md
pull_user_claude_md() {
    local source_file="$REGISTRY/components/user-claude-md.md"
    local target_file="$HOME/.claude/CLAUDE.md"

    if [ ! -f "$source_file" ]; then
        log_debug "No user CLAUDE.md in registry"
        return 1
    fi

    # Wait for iCloud sync
    if ! wait_for_icloud_sync "$source_file"; then
        log_debug "iCloud sync timeout for user CLAUDE.md"
        return 1
    fi

    # Backup current state
    backup_component "$target_file" "user-claude-md"

    # Create parent directory if doesn't exist
    mkdir -p "$(dirname "$target_file")"

    # Copy new
    cp "$source_file" "$target_file"

    return 0
}

# ============================================================================
# Main Pull Function
# ============================================================================

# Pull a component from the registry
pull_component() {
    local plugin_dir="$1"
    local component="$2"

    local result=0

    case "$component" in
        skills/*)
            local skill_name="${component#skills/}"
            if ! pull_skill "$plugin_dir" "$skill_name"; then
                result=1
            fi
            ;;
        servers/*)
            local server_name="${component#servers/}"
            if ! pull_server "$plugin_dir" "$server_name"; then
                result=1
            fi
            ;;
        commands)
            if ! pull_commands "$plugin_dir"; then
                result=1
            fi
            ;;
        hooks)
            if ! pull_hooks "$plugin_dir"; then
                result=1
            fi
            ;;
        agents)
            if ! pull_agents "$plugin_dir"; then
                result=1
            fi
            ;;
        mcp-config)
            if ! pull_mcp_config "$plugin_dir"; then
                result=1
            fi
            ;;
        global-commands)
            if ! pull_global_commands; then
                result=1
            fi
            ;;
        user-claude-md)
            if ! pull_user_claude_md; then
                result=1
            fi
            ;;
        *)
            log_error "Unknown component type: $component"
            result=1
            ;;
    esac

    return $result
}
