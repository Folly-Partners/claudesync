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
# Component Push Functions
# ============================================================================

# Push a skill to the registry
push_skill() {
    local plugin_dir="$1"
    local skill_name="$2"
    local machine_id="$3"

    local skill_dir="$plugin_dir/skills/$skill_name"
    local dest_dir="$REGISTRY/components/skills"
    local tarball="$dest_dir/${skill_name}.tar.gz"
    local temp_tarball="$tarball.${machine_id}.tmp"

    # Ensure destination directory exists
    mkdir -p "$dest_dir"

    # Create tarball
    if ! create_component_tarball "$skill_dir" "$temp_tarball"; then
        rm -f "$temp_tarball"
        return 1
    fi

    # Atomic rename
    mv "$temp_tarball" "$tarball"

    return 0
}

# Push a server to the registry
push_server() {
    local plugin_dir="$1"
    local server_name="$2"
    local machine_id="$3"

    local server_dir="$plugin_dir/servers/$server_name"
    local dest_dir="$REGISTRY/components/servers"
    local tarball="$dest_dir/${server_name}.tar.gz"
    local temp_tarball="$tarball.${machine_id}.tmp"

    # Ensure destination directory exists
    mkdir -p "$dest_dir"

    # Create tarball (excluding dependencies)
    if ! create_component_tarball "$server_dir" "$temp_tarball"; then
        rm -f "$temp_tarball"
        return 1
    fi

    # Atomic rename
    mv "$temp_tarball" "$tarball"

    return 0
}

# Push commands directory to the registry
push_commands() {
    local plugin_dir="$1"
    local machine_id="$2"

    local commands_dir="$plugin_dir/commands"
    local dest_dir="$REGISTRY/components/commands"

    # Ensure destination exists and is clean
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    # Copy all command files
    if [ -d "$commands_dir" ]; then
        cp -r "$commands_dir"/* "$dest_dir/" 2>/dev/null || true
    fi

    return 0
}

# Push hooks directory to the registry
push_hooks() {
    local plugin_dir="$1"
    local machine_id="$2"

    local hooks_dir="$plugin_dir/hooks"
    local dest_dir="$REGISTRY/components/hooks"

    # Ensure destination exists and is clean
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    # Copy all hook files
    if [ -d "$hooks_dir" ]; then
        cp -r "$hooks_dir"/* "$dest_dir/" 2>/dev/null || true
    fi

    return 0
}

# Push agents directory to the registry
push_agents() {
    local plugin_dir="$1"
    local machine_id="$2"

    local agents_dir="$plugin_dir/agents"
    local dest_dir="$REGISTRY/components/agents"

    # Ensure destination exists and is clean
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    # Copy all agent files
    if [ -d "$agents_dir" ]; then
        cp -r "$agents_dir"/* "$dest_dir/" 2>/dev/null || true
    fi

    return 0
}

# Push MCP config to the registry
push_mcp_config() {
    local plugin_dir="$1"
    local machine_id="$2"

    local mcp_file="$plugin_dir/.mcp.json"
    local dest_file="$REGISTRY/components/mcp-config.json"

    if [ -f "$mcp_file" ]; then
        atomic_copy "$mcp_file" "$dest_file" "$machine_id"
    fi

    return 0
}

# ============================================================================
# Main Push Function
# ============================================================================

# Push a component to the registry
push_component() {
    local plugin_dir="$1"
    local component="$2"
    local machine_id="$3"

    local hash=$(echo "$component" | jq -R -s 'rtrimstr("\n")' 2>/dev/null)
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
}
