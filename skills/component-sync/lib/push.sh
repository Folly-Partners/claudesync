#!/bin/bash
# Push local components to iCloud registry
# Uses atomic writes and handles iCloud sync markers

# ============================================================================
# Tarball Creation
# ============================================================================

# Create a tarball of a directory, excluding build artifacts
create_component_tarball() {
    local source_dir="$1"
    local output_file="$2"

    # Create tarball with exclusions
    tar -czf "$output_file" \
        --exclude='node_modules' \
        --exclude='venv' \
        --exclude='dist' \
        --exclude='__pycache__' \
        --exclude='.git' \
        --exclude='*.pyc' \
        --exclude='*.pyo' \
        --exclude='.DS_Store' \
        -C "$(dirname "$source_dir")" \
        "$(basename "$source_dir")" 2>/dev/null

    return $?
}

# ============================================================================
# Atomic Write
# ============================================================================

# Write file atomically (write to temp, then rename)
atomic_write() {
    local content="$1"
    local dest="$2"
    local machine_id="${3:-$(hostname -s)}"

    local temp_file="${dest}.${machine_id}.tmp"

    # Write to temp file
    echo "$content" > "$temp_file"

    # Atomic rename
    mv "$temp_file" "$dest"

    return $?
}

# Copy file atomically
atomic_copy() {
    local source="$1"
    local dest="$2"
    local machine_id="${3:-$(hostname -s)}"

    local temp_file="${dest}.${machine_id}.tmp"

    # Copy to temp
    cp "$source" "$temp_file"

    # Atomic rename
    mv "$temp_file" "$dest"

    return $?
}

# ============================================================================
# Component Push Functions (P1-PAT-002: Consolidated to reduce duplication)
# ============================================================================

# Generic function to push a tarball-based component (skills, servers)
# Usage: push_tarball_component <source_dir> <dest_subdir> <name> <machine_id>
push_tarball_component() {
    local source_dir="$1"
    local dest_subdir="$2"
    local name="$3"
    local machine_id="$4"

    local dest_dir="$REGISTRY/components/$dest_subdir"
    local tarball="$dest_dir/${name}.tar.gz"
    local temp_tarball="$tarball.${machine_id}.tmp"

    mkdir -p "$dest_dir"

    if ! create_component_tarball "$source_dir" "$temp_tarball"; then
        rm -f "$temp_tarball"
        return 1
    fi

    mv "$temp_tarball" "$tarball"
    return 0
}

# Generic function to push a directory (commands, hooks, agents, global-commands)
# Usage: push_directory_component <source_dir> <dest_subdir>
push_directory_component() {
    local source_dir="$1"
    local dest_subdir="$2"

    local dest_dir="$REGISTRY/components/$dest_subdir"

    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    if [ -d "$source_dir" ]; then
        cp -r "$source_dir"/* "$dest_dir/" 2>/dev/null || true
    fi

    return 0
}

# Generic function to push a single file (mcp-config, user-claude-md)
# Usage: push_file_component <source_file> <dest_file> <machine_id>
push_file_component() {
    local source_file="$1"
    local dest_file="$2"
    local machine_id="$3"

    if [ -f "$source_file" ]; then
        atomic_copy "$source_file" "$dest_file" "$machine_id"
    fi

    return 0
}

# Convenience wrappers for backward compatibility
push_skill() {
    local plugin_dir="$1"
    local skill_name="$2"
    local machine_id="$3"
    push_tarball_component "$plugin_dir/skills/$skill_name" "skills" "$skill_name" "$machine_id"
}

push_server() {
    local plugin_dir="$1"
    local server_name="$2"
    local machine_id="$3"
    push_tarball_component "$plugin_dir/servers/$server_name" "servers" "$server_name" "$machine_id"
}

push_commands() {
    local plugin_dir="$1"
    push_directory_component "$plugin_dir/commands" "commands"
}

push_hooks() {
    local plugin_dir="$1"
    push_directory_component "$plugin_dir/hooks" "hooks"
}

push_agents() {
    local plugin_dir="$1"
    push_directory_component "$plugin_dir/agents" "agents"
}

push_mcp_config() {
    local plugin_dir="$1"
    local machine_id="$2"
    push_file_component "$plugin_dir/.mcp.json" "$REGISTRY/components/mcp-config.json" "$machine_id"
}

push_global_commands() {
    push_directory_component "$HOME/.claude/commands" "global-commands"
}

push_user_claude_md() {
    local machine_id="$1"
    push_file_component "$HOME/.claude/CLAUDE.md" "$REGISTRY/components/user-claude-md.md" "$machine_id"
}

# ============================================================================
# Main Push Function
# ============================================================================

# Push a component to the registry
push_component() {
    local plugin_dir="$1"
    local component="$2"
    local machine_id="$3"

    local now=$(date +%s)
    local result=0

    case "$component" in
        skills/*)
            local skill_name="${component#skills/}"
            if push_skill "$plugin_dir" "$skill_name" "$machine_id"; then
                # Update manifest
                update_manifest_component "skills" "$skill_name" "$machine_id" "$now" "$plugin_dir/skills/$skill_name"
            else
                result=1
            fi
            ;;
        servers/*)
            local server_name="${component#servers/}"
            if push_server "$plugin_dir" "$server_name" "$machine_id"; then
                # Update manifest with build info
                update_manifest_server "$server_name" "$machine_id" "$now" "$plugin_dir/servers/$server_name"
            else
                result=1
            fi
            ;;
        commands)
            if push_commands "$plugin_dir" "$machine_id"; then
                update_manifest_simple "commands" "$machine_id" "$now" "$plugin_dir/commands"
            else
                result=1
            fi
            ;;
        hooks)
            if push_hooks "$plugin_dir" "$machine_id"; then
                update_manifest_simple "hooks" "$machine_id" "$now" "$plugin_dir/hooks"
            else
                result=1
            fi
            ;;
        agents)
            if push_agents "$plugin_dir" "$machine_id"; then
                update_manifest_simple "agents" "$machine_id" "$now" "$plugin_dir/agents"
            else
                result=1
            fi
            ;;
        mcp-config)
            if push_mcp_config "$plugin_dir" "$machine_id"; then
                update_manifest_mcp_config "$machine_id" "$now" "$plugin_dir/.mcp.json"
            else
                result=1
            fi
            ;;
        global-commands)
            if push_global_commands "$machine_id"; then
                update_manifest_simple "global-commands" "$machine_id" "$now" "$HOME/.claude/commands"
            else
                result=1
            fi
            ;;
        user-claude-md)
            if push_user_claude_md "$machine_id"; then
                update_manifest_file "user-claude-md" "$machine_id" "$now" "$HOME/.claude/CLAUDE.md"
            else
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

# Push all components (used for initial registry setup)
push_all_components() {
    local plugin_dir="$1"
    local machine_id="$2"

    # Push skills
    if [ -d "$plugin_dir/skills" ]; then
        for skill_path in "$plugin_dir/skills"/*; do
            if [ -d "$skill_path" ]; then
                local skill_name=$(basename "$skill_path")
                push_component "$plugin_dir" "skills/$skill_name" "$machine_id"
            fi
        done
    fi

    # Push servers
    if [ -d "$plugin_dir/servers" ]; then
        for server_path in "$plugin_dir/servers"/*; do
            if [ -d "$server_path" ]; then
                local server_name=$(basename "$server_path")
                push_component "$plugin_dir" "servers/$server_name" "$machine_id"
            fi
        done
    fi

    # Push simple components
    push_component "$plugin_dir" "commands" "$machine_id"
    push_component "$plugin_dir" "hooks" "$machine_id"
    push_component "$plugin_dir" "agents" "$machine_id"
    push_component "$plugin_dir" "mcp-config" "$machine_id"
    push_component "$plugin_dir" "global-commands" "$machine_id"
    push_component "$plugin_dir" "user-claude-md" "$machine_id"
}
